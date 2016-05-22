#!/usr/bin/env lua

--[[
	apt-get install lua5.1 dialog
	./debinstall.lua
	
	TO DO:
	
	groups
	- confirm get set, use
	  'id -G'	# ids
	  'id -nG'	# names
	
	#get real & effective user & group Ids
	id <USERNAME>
]]

local SIMUL_PREFIX = "$P4_WORKSPACE/DebLua/LuaDebian_installer/simul"
local SIMUL_DEST = "simul_dest"

package.path = package.path .. ";../?.lua;../DebLua/?.lua"

require "lua_shell"

---- Debian functions ----------------------------------------------------------

-- (must be global to be seen by requires - which we no longer do!)
Debian = {simulate = true, Release = "", Architecture = 0, HOME = "", USER = "", AUTH = ""}

require "packages"

-- Debian Init

function Debian:Init()

	-- get release name (Wheezy|Jessie)
	local releaseLUT = {wheezy = "wheezy", jessie = "jessie", testing = "jessie"}
	
	self.Release = pshell.lsb_release("-a", "2>&1 | grep -Eo '(wheezy|jessie|testing)'")
	self.Release = releaseLUT[self.Release]
	assertf(self.Release, "unknown Debian release!")
	printf('Debian release %S', tostring(self.Release))                           -- FIXME for ARM
	
	-- get 32/64-bit architecture
	local archLUT = {i686 = 32, x86_64 = 64, armv61 = 61}
	self.Architecture = archLUT[pshell.arch()]
	assertf(self.Architecture, "unknown Debian architecture!")
	Log.f("architecture is %d-bits", self.Architecture)
	
	-- get user home dir by cutting 6th field of admin database
	self.HOME = pshell.getent("passwd", 1000, "| cut -d ':' -f6")
	Log.f("user HOME is %S", self.HOME)
	
	-- get user name
	-- OR use 'id -u' / 'id -nu'
	self.USER = pshell.getent("passwd", 1000, "| cut -d ':' -f1")
	Log.f("user NAME is %S", self.USER)
	
	self.RootFlag = ("root" == os.getenv("USER"))
	if (self.RootFlag) then
		self.AUTH = "root"
	else
		self.AUTH = "<NON-ROOT>"
	end
	
	if (self.simulate or (not self.RootFlag)) then
		self.simulate_str = "SIMUL"
	else
		self.simulate_str = "REAL"
	end
end
	
-- Debian:Init()

---- Toggle Simulation ---------------------------------------------------------

function Debian.ToggleSimulation()

	if (not Debian.RootFlag) then
		Log.f("forced SIMUL as non-root!")
		return
	end

	Debian.simulate = not Debian.simulate
	
	if (Debian.simulate) then
		Debian.simulate_str = "SIMUL"
	else
		Debian.simulate_str = "REAL"
	end
	
	return "nopause"
end

local gPackStatusTab = nil

---- Refresh (avail) Packages Status Tab ---------------------------------------

function Debian.RefreshPackageStatus()

	gPackStatusTab = {}
	
-- get available packages	
	local t = tshell["apt-cache"]("dumpavail | grep -E '^Package:'")
	
	for _, ln in ipairs(t) do
		
		local pack_s = string.match(ln, "^Package: ([a-z0-9][a-z0-9%+%.%-]+)")
		assertf("string" == type(pack_s), "couldn't match dpkg on line %S", ln)
		assertf("" ~= pack_s, "empty avail package name on line %S", ln)
		
		gPackStatusTab[pack_s] = "available"
	end
	
-- get installed packages (overwrites available)
	t = tshell.dpkg("-l")
	
	-- pop first 5 lines
	table.remove(t, 1)
	table.remove(t, 1)
	table.remove(t, 1)
	table.remove(t, 1)
	table.remove(t, 1)

	for _, ln in ipairs(t) do
		
		local stat_s, pack_s = string.match(ln, "(%w+)%s+([a-z0-9][a-z0-9%+%.%-]+)")
		assertf(pack_s, "couldn't match dpkg on line %s", ln)

		if ("ii" == stat_s) then
			gPackStatusTab[pack_s] = "installed"
		elseif ("rc" == stat_s) then
			-- is (r)emoved package with left-over (c)onfig -- should be purged?
		elseif ("it" == stat_s) then
			printf("unknown status %S for package %S (use dpkg -s <pack> for status)", stat_s, pack_s)
		else
			-- ERROR: unknown status
			errorf("unknown package %S status %S on line %S", tostring(pack_s), tostring(stat_s), ln)
		end
	end
	
	return gPackStatusTab
end

---- Get Already Installed & illegal Packages --------------------------------------------

function GetDupePackages()

	local dupes = {}
	
	local t = tshell["dpkg-query"]('--show', "--showformat='${db:Status-Abbrev}\t${Package}\n'")	-- add "*" to also get 'un'
	
	for _, ln in ipairs(t) do
		
		local stat_s, pack_s = string.match(ln, "(%l%l)%s+(.+)$")
		
		assertf(pack_s, "couldn't match dpkg on line %s", ln)
		
		if (stat_s == 'ii') then
			dupes[pack_s] = true
		end
	end
	
	return dupes
end

---- Get Package Status (installed|available|unavailable) ----------------------

function Debian.PackageStatus(pkg_name, must_exist_f)

	assertf(type(pkg_name) == "string", "illegal Debian.PackageStatus() pkg_name")
	
	local t = gPackStatusTab
	if (not t) then
		t = Debian.RefreshPackageStatus()
	end
	
	assertf(type(t) == "table", "empty gPackStatusTab")
	
	local stat_s = t[pkg_name]
	
	if (stat_s) then
		-- available or installed
		return stat_s
	else
		-- not available
		if (must_exist_f) then
			assertf(false, "Debian.PackageStatus(%S) is unavailable", pkg_name)
		else
			return "unavailable"
		end
	end
end

---- apt-get update ------------------------------------------------------------

function Debian.Update()

	printf("apt-get update")
	
	if (Debian.simulate) then
		print("SIMUL")
	else
		shell["apt-get"]("update")
	end
	
	-- flush (will fill on next query)
	gPackStatusTab = nil
end

---- apt-get install -----------------------------------------------------------

function Debian.Install(args)
	printf("apt-get install %S", tostring(args))
	
	assertf(type(args) == "string", "Debian.Install() illegal args")
	
	if (Debian.simulate) then
		print("  SIMUL")
	else
		shell["apt-get"]("install", args)
	end
	
	-- flush (will fill on next query)
	gPackStatusTab = nil
end

---- apt-key adv ---------------------------------------------------------------

function Debian.AptKey(key_url)
	
	Log.f("apt-key adv --fetch-keys %S", tostring(key_url))
	
	assertf(type(key_url) == "string", "illegal Debian.AptKey() URL")
	
	if (Debian.simulate) then
		print("  SIMUL")
	else
		shell["apt-key"]("adv", "--fetch-keys", key_url)
		
		Debian.Update()
	end
end

---- Add APT source ------------------------------------------------------------

function Debian.AddSource(url)
	
	assertf(type(url) == "string", "illegal Debian.AddSource() URL")
	
	printf("Debian.AddSource(%S)", url)
	
	if (Debian.simulate) then
		print("  SIMUL")
	else
		local f = io.open("/etc/apt/sources.list", "a+")
		assertf(f, "couldn't append-open sources.list")
		
		f:write(url .. "\n")
		
		f:close()
	end
	
	-- flush (will fill on next query)
	gPackStatusTab = nil
end

---- Add To Group --------------------------------------------------------------

function Debian.AddToGroup(group)

	Log.f("Debian.AddToGroup(%S)", tostring(group))
	
	-- assertf(type(group) == "string", "Debian.AddToGroup() illegal group")
	
	if (Debian.simulate) then
		Log.f("  SIMUL")
		return
	end
	
	if (type(group) == "string") then
		shell.adduser(Debian.USER, group)
	elseif (type(group) == "table") then
		for k, v in ipairs(group) do
			assertf(type(v) == "string", "Debian.AddToGroup() illegal group")
			shell.adduser(Debian.USER, v)
		end
	else
			assertf(false, "Debian.AddToGroup() illegal group")
	end
end

---- Edit File -----------------------------------------------------------------

function Debian.EditFile(fn, write_f, title)

	-- for read-only use "--textbox"
	local res_t = tshell.dialog("--stdout", "--title", title or "", "--editbox", fn, 0, 0)
	if ((not res_t) or (#res_t == 0)) then
		return false
	end
	
	Log.f("EditFile() returned %d lines", #res_t)
	
	if (write_f) then
		local s = table.concat(res_t, "\n")
	
		Util.WriteFile(fn, s)
	end
	
	return true
end

---- Edit Text String ----------------------------------------------------------

function Debian.EditTextString(s, title)

	assert(s ~= "")
	
	local tmp_fn = os.tmpname()
	Log.f("tmp_fn = %S", tmp_fn)
	
	-- write string to temp file
	local f = io.open(tmp_fn, "w")
	assert(f)
	
	f:write(s)
	f:close()
	
	local res = Debian.EditFile(tmp_fn, false, title)		-- don't write
	-- delete temp file?
	
	return res
end

---- Append Lines --------------------------------------------------------------

function Debian.AppendLines(fn, lines_t, dest_fn)

	printf("Debian.AppendLines(%S, %S)", tostring(fn), tostring(dest_fn))
	assertf(type(fn) == "string", "illegal source path in Debian.AppendLines()")
	assertf(type(dest_fn) == "string", "illegal dest path in Debian.AppendLines()")
	assertf(type(lines_t) == "table", "illegal lines_t in Debian.AppendLines()")
	
	-- resolve any env vars
	fn = Util.NormalizePath(fn)
	
	local f_s = ""
	
	if (Util.FileExists(fn)) then
		f_s = Util.LoadFile(fn)
		-- pre-write LF if doesn't have one?
	end
	
	local append_s = table.concat(lines_t, "\n")
	
	f_s = f_s .. append_s .. "\n"
	
	local ok = Debian.EditTextString(f_s, '"' .. fn .. ' (preview)"')	-- ESCAPES title
	if (ok) then
		Util.WriteFile(dest_fn, f_s)
		return "nopause"
	else
		-- canceled
	end
end

---- Gsub Lines ----------------------------------------------------------------

function Debian.GsubLines(fn, gsub_list, dest_fn)

	Log.f("Debian.GsubLines(file %S)", fn)
	
	-- FUCKED, operates on WHOLE STRING instead of LINES (FIXME)
	-- ^$ anchors only apply to start/end of WHOLE STRING
	printf("Debian.GsubLines(%S, %S)", tostring(fn), tostring(dest_fn))
	assertf(type(fn) == "string", "illegal source path in Debian.AppendLines()")
	assertf(type(dest_fn) == "string", "illegal dest path in Debian.AppendLines()")
	
	-- error if doesn't exist
	Util.FileExists(fn, "fail_missing")
	
	-- resolve any env vars
	fn = Util.NormalizePath(fn)
	
	local f_s = Util.LoadFile(fn)
	local nsubs
	
	for _, gsub_def in ipairs(gsub_list) do
		assertf(type(gsub_def) == "table", "illegal gsub_def %S (expected table)", tostring(gsub_def))
		assertf((#gsub_def >= 2), "illegal gsub_def sz")
		
		local src, dst = gsub_def[1], gsub_def[2]
		
		f_s, nsubs = f_s:gsub(src, dst)
		
		-- do NOT log regex patterns
		-- printf("gsub_def(org: %S, dst: %S) = %d subs", src, dst, nsubs)
	end
	
	local ok = Debian.EditTextString(f_s, '"' .. fn .. ' (preview)"')
	if (ok) then
		Util.WriteFile(dest_fn, f_s)
		return "nopause"
	else
		-- canceled
	end
end

---- Exec ----------------------------------------------------------------------

function Debian.Exec(fn, cmd_list, dest_fn)

	Log.f("Debian.Exec() *** UNINPLEMENTED ***")
end

---- PACKAGES ------------------------------------------------------------------

local distro_packages = wheezy_packages

local ckecklist_entries = {}
local apt_keys = {}
local apt_sources = {}
local downloads = {}

require "patch"

require "patches"

local Patches = GetPatches()

---- Clear Packages Checklist --------------------------------------------------

local
function ClearPackagesCheckList()

	ckecklist_entries = {}
	apt_keys = {}
	apt_sources = {}
	downloads = {}
end

---- Add to Check List ---------------------------------------------------------

local
function AddToCheckList(menu_name, menu_entry, dupes_t)

	assert("table" == type(ckecklist_entries))
	assert("table" == type(dupes_t))

	--[[
		# each entry is triplet
		dialog --stdout --checklist "mytitle" 0 0 0 "item1" "" off "item2" "" on
		
		--column-separator '|'
	
		# show between "OK" and "Cancel" buttons
		--extra-button
		--extra-label "string"
		# returns 3 if pressed
		
		#write output to file descriptor?
		--output-fd
	]]
	
	table.insert(ckecklist_entries, ('"---- %s ----" "" 0'):format(menu_name))
	
	-- entry is off by default
	local flag_s = "0"

	for k, entry in ipairs(menu_entry) do
		
		if (dupes_t[entry]) then
		
			-- backslash doesn't work when 1st char
			table.insert(ckecklist_entries, ('^%s^ "^" 0'):format(entry))			-- tag already-installed with underscores
			
		else
		
			if (type(entry) == "boolean") then
				-- change entry on/off for subsequent items
				if (entry) then
					flag_s = "on"
				else
					flag_s = "0"
				end
			else
				table.insert(ckecklist_entries, ('%s "" %s'):format(entry, flag_s))
			end
		end
	end
end

---- Add Packages Checklist ----------------------------------------------------

local
function AddPackagesCheckList(pkgs_def)

	assertf(type(pkgs_def) == "table", "illegal AddPackagesCheckList() def arg")
	
	local dupes = GetDupePackages()
	
-- build packages checklist
	for _, menu_entry in ipairs(pkgs_def) do
	
		assert("table" == type(menu_entry))
		
		for title, entry in pairs(menu_entry) do
		
			AddToCheckList(title, entry, dupes)
		end
	end
end
	
---- Validate Packages ---------------------------------------------------------

local
function ValidatePackages(pack_list, group_list)

	local filtered_tab = {}
	
	for k, pkg in ipairs(pack_list) do
		
		local res = Debian.PackageStatus(pkg)
		assert(res)
		
		if ("unavailable" == res) then
			Log.f("errorL UNAVAILABLE package %S", pkg)
			return nil		-- error
		elseif ("installed" == res) then
			-- printf("skipping installed package %S", pkg)
		else
			table.insert(filtered_tab, pkg)
		end
		
		Log.f("%d: %S, status: %s", k, pkg, tostring(res))
	end
	
	return filtered_tab
end

---- Prompt Install Packages ---------------------------------------------------

local
function PromptInstallPackages()

-- prompt checklist
	-- "--colors" don't work
	local res_s = pshell.dialog("--stdout", "--checklist", "'Packages'", 0, 0, 0, table.concat(ckecklist_entries, " "))
	-- os.exit()
	
	if (not res_s) then
		return "nopause"
	end
	
-- decode checklist reply
	local pack_t = {}
	res_s:gsub("([%w_%.%-%+%^]+)",	function(s)
						if (not s:find("%^")) then
							table.insert(pack_t, s)
						end
					end)
-- confirm packages
	res_s = shell.dialog("--yesno", '"confirm:\n\n' .. table.concat(pack_t, '\n') .. '"', 0, 0)
	if (not res_s) then
		Log.f("install not confirmed")
		return
	end

-- validate packages
	local togroups = {}

	local filtered_t = ValidatePackages(pack_t, togroups)
	if (not filtered_t) then
		Log.f("warning: some packages missing, canceling")
	
		return
	else
		-- install
		Debian.Install(table.concat(filtered_t, " "))
	end
end

---- Install Packages Checklist ------------------------------------------------

local
function InstallPackagesCheckList(pkgs_def)

	assertf(type(pkgs_def) == "table", "illegal InstallPackagesCheckList() def arg")
	
	ClearPackagesCheckList()

	AddPackagesCheckList(pkgs_def)
	
	return PromptInstallPackages()
end

---- Install Multiple Packages Checklist ---------------------------------------

local
function InstallMultiPackagesCheckList(pkgs_def_list)

	assertf(type(pkgs_def_list) == "table", "illegal InstallMultiPackagesCheckList() def arg")
	
	ClearPackagesCheckList()

	for _, pkgs_def in ipairs(pkgs_def_list) do
		AddPackagesCheckList(pkgs_def)
	end
	
	return PromptInstallPackages()
end

---- Convert Xfce Val to string cmd --------------------------------------------

local xftype_LUT = {	["string"] =	function(v)
						local u_v = string.match(v, "^(%d+)u$")
						if (u_v) then
							return " -t uint -s "..u_v
						else
							return " -t string -s '"..v.."'"
						end
					end,
			number =	function(v) return " -t int -s "..tostring(v) end,
			boolean =	function(v) return " -t bool -s "..tostring(v) end,
			["table"] =	function(tab, lut)
						local ln = ""
						for _, v in ipairs(tab) do
							ln = ln .. lut[type(v)](v)
						end
						return ln
					end,
		}
		
local
function ConvXfceVal(cmd)

	assert(type(cmd) == "table")
	
	local lua_typ = type(cmd.val)
			
	local xf_fn = xftype_LUT[lua_typ]
	assertf("function" == type(xf_fn), "illegal xftype_LUT for native type %S", lua_typ)
	
	local res_s = xf_fn(cmd.val, xftype_LUT)
	assertf("string" == type(res_s), "illegal ConvXfceVal res for native type %S", lua_typ)
	
	return res_s
end

---- Xfce4 Config --------------------------------------------------------------

local
function xfce4config(def_list)

	assertf(type(def_list) == "table", "illegal xfce def list")
	
	local xfpref_menulist = {}
	local entryLUT = {}
	
	for title, entries_t in pairs(def_list) do
	
		assertf(type(title) == "string", "illegal xfce4 title")
		assertf(type(entries_t) == "table", "illegal xfce4 entries list for title %S", title)
		
		table.insert(xfpref_menulist, ('"%s" ""'):format(title))
		
		local cmd_list = {}
		
		for _, entry in ipairs(entries_t) do
		
			assertf(type(entry) == "table", "illegal xfce4 entry for title %S", title)
			assertf(#entry == 3, "illegal xfce4 entry table len for title %S", title)
		
			local chan = entry[1]
			assertf(type(chan) == "string", "illegal non-string xfce4 entry.chan for title %S", title)
			local k = entry[2]
			assertf(type(k) == "string", "illegal non-string xfce4 entry.prop for title %S", title)
			local v = entry[3]
			
			local cmd = {}
			
			cmd.chan = chan
			cmd.prop = k
			cmd.prop_quoted = "'"..k.."'"
			cmd.val = v
			
			table.insert(cmd_list, cmd)
		end
		
		entryLUT[title] = cmd_list
	end
	
	-- loop
	while (true) do

		shell.clear()
		
		local menu_title = sprintf("'Xfce4 prefs - %s'", Debian.simulate_str)
		local menu_w = #menu_title + 8
		
		local res_s = pshell.dialog("--stdout --ok-label 'Apply' --cancel-label 'Back' --menu", menu_title, 0, menu_w, 0, table.concat(xfpref_menulist, " "))
		if (not res_s) then
			return "nopause"
		end
		
		Log.f("selected xfce4 pref %S", res_s)
		
		-- lookup menu function
		local cmd_list = entryLUT[res_s]
		assertf("table" == type(cmd_list), "bad xfce4 menu entry")

		for _, cmd in ipairs(cmd_list) do	
		
			-- query current value
			local cur_v = pshell["xfconf-query"]("-c", cmd.chan, "-p", cmd.prop_quoted, "2>/dev/null")
			if (cur_v == cmd.val) then
				Log.f("  chan %S: prop %S, cur & new: %s (NO CHANGE)", cmd.chan, cmd.prop, tostring(cur_v))
			else
				Log.f("  chan %S: prop %S, val: %s -> %s", cmd.chan, cmd.prop, tostring(cur_v), tostring(cmd.val))
				
				DumpTable('cmd', cmd)
				
				local v_s = ConvXfceVal(cmd)
				assert(v_s)
				
				local s = table.concat({"xfconf-query", "-c", cmd.chan, "-p", cmd.prop_quoted, "-n", v_s}, " ")
				Log.f("  cmd:\n%s\n", s)
				
				pshell["xfconf-query"]("-c", cmd.chan, "-p", cmd.prop_quoted, "-n", v_s)
				
			end
		end
		
		-- getkey("press key to reloop")
	end
end

---- Prompt Main Menu ----------------------------------------------------------

local
function PromptMainMenu()

	local main_menu_def =
	{	
		{ title = "Toggle Simulation", fn = Debian.ToggleSimulation},
		{ title = "Patches", fn = Patches.ApplyMenu},
		{ title = "UI Prefs", fn = xfce4config, fn_arg = xfce4_def},
		{ title = "Xfce", fn = InstallMultiPackagesCheckList, fn_arg = {distro_packages, common_packages}},
		{ title = "office", fn = InstallPackagesCheckList, fn_arg = office_packages},
		{ title = "programming", fn = InstallPackagesCheckList, fn_arg = programming_packages},
		{ title = "Qemu", fn = InstallPackagesCheckList, fn_arg = qemu_packages},
		{ title = "mount packages", fn = InstallPackagesCheckList, fn_arg = mount_packages},
		{ title = "print and scan", fn = InstallPackagesCheckList, fn_arg = printing_packages},
		{ title = "multimedia", fn = InstallPackagesCheckList, fn_arg = multimedia_packages},
		{ title = "tools", fn = InstallPackagesCheckList, fn_arg = tools_packages},
	}

	local main_menu_entries = {}
	local entryLUT = {}
	
	if (not Debian.RootFlag) then
		-- if not root, remove simulation toggle
		table.remove(main_menu_def, 1)
	end

	for k, entry in ipairs(main_menu_def) do
	
		assertf("table" == type(entry), "illegal entry")
		assertf("string" == type(entry.title), "illegal entry.title")
		assertf(nil == entryLUT[entry.title], ('duplicate main_menu_def[%d].title["%s"]'):format(k, entry.title))
		assertf("function" == type(entry.fn), ('illegal entry["%s"].fn'):format(entry.title))
		
		table.insert(main_menu_entries, ('"%s" ""'):format(entry.title))
		
		entryLUT[entry.title] = entry
	end
	
	local menu_title = sprintf("'Main %s (%s) - %s'", tostring(Debian.AUTH), tostring(Debian.Release), tostring(Debian.simulate_str))
	
	local menu_w = #menu_title + 8
	
	--[[	dialog --stdout --menu "mytitle" 0 0 0 "item1" "" "item2" ""	]]
	local res_s = pshell.dialog("--stdout --cancel-label 'Exit' --menu", menu_title, 0, menu_w, 0, table.concat(main_menu_entries, " "))
	if (not res_s) then
		Log.f("exited installer")
		return "exit"
	end
	
	Log.f("selected menu entry %S", res_s)
	
	-- lookup menu function
	local fn = entryLUT[res_s].fn
	assertf("function" == type(fn), "PromptMainMenu - didn't look up function")
	
	-- optional
	local fn_arg = entryLUT[res_s].fn_arg

	shell.clear()

	-- call function
	return fn(fn_arg)
end

---- Main ----------------------------------------------------------------------

function main()

	Log.Init("installer.log")
	Log.SetTimestamp("%H:%M:%S > ")
	
	local pwd = os.getenv("PWD")
	
	if (not Debian.simulate_str) then
		Debian:Init()
	end
	
	local simul_prefix = nil
	
	if (Debian.simulate) then
		simul_prefix = Util.NormalizePath(SIMUL_PREFIX)
	end
	
	local simul_dir = Patches.ParseAllPatches(simul_prefix, SIMUL_DEST)
	
	Debian.Install("dialog", "force")
	
	-- menu loop
	while (true) do

		-- shell.clear()
	
		local res = PromptMainMenu()
		if ("exit" == res) then
			break
		elseif ("nopause" ~= res) then
			-- pause by default
			io.write("\nPress Return...");io.read()
		end
	end
	
	shell.clear()
	
	pshell.chown("1000:1000", pwd .. "/installer.log")
	-- pshell.touch(pwd .. "/installer.log")
end

main()


