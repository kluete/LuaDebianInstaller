#!/usr/bin/env lua

--[[
	apt-get install lua5.1 dialog
	./debinstall.lua
	
	TO DO:
	
	groups
	- confirm get set, use
	  'id -G'	# ids
	  'id -nG'	# names
	  
# diff packages between machines

 dpkg-query -W -f='${Package}\n' | sort > baselist8900.txt
 comm -1 -3 <(ssh debdev cat /media/blek/baselist8900.txt) <(dpkg-query -W -f='${Package}\n' | sort)

]]

package.path = package.path .. ";../?.lua;../DebLua/?.lua"

require "lua_shell"

---- Debian functions ----------------------------------------------------------

-- (must be global to be seen by requires - which we no longer do!)
Debian = {Release = "", Architecture = 0, HOME = "", USER = "", AUTH = ""}

require "packages"

---- Debian Init ---------------------------------------------------------------

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
	
	-- get user name
	self.USER = pshell.id("-nu", 1000)
	Log.f("user NAME is %S", self.USER)
	
	-- get user home dir by cutting 6th field of admin database
	self.HOME = pshell.getent("passwd", 1000, "| cut -d ':' -f6")
	Log.f("user HOME is %S", self.HOME)
	
	self.RootFlag = ("root" == os.getenv("USER"))
	if (self.RootFlag) then
		self.AUTH = "root"
	else
		self.AUTH = "<NON-ROOT>"
	end
end
	
local gPackStatusTab = nil

---- Refresh (avail) Packages Status Tab ---------------------------------------

function Debian.RefreshPackageStatus()

	Log.f("Debian.RefreshPackageStatus()")
	
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

	Log.f("GetDupePackages()")
	
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

	Log.f("Debian.PackageStatus(%S)", tostring(pkg_name))
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

	Log.f("Debian.Update()")
	
	shell["apt-get"]("update")
	
	-- flush (will fill on next query)
	gPackStatusTab = nil
end

---- apt-get install -----------------------------------------------------------

function Debian.Install(args)

	Log.f("Debian.Install(%S)", tostring(args))
	assertf(type(args) == "string", "Debian.Install() illegal args type")
	
	shell["apt-get"]("install", "--no-install-recommends", "--no-install-suggests", args)
	
	-- flush (will fill on next query)
	gPackStatusTab = nil
end

---- Add To Group --------------------------------------------------------------

function Debian.AddToGroup(group)

	Log.f("Debian.AddToGroup(%S)", tostring(group))
	
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

	Log.f("Debian.EditFile(%S)", tostring(fn))
	
	-- for read-only use "--textbox"
	local res_t = tshell.dialog("--stdout", "--title", title or "", "--editbox", fn, 0, 0)
	if ((not res_t) or (#res_t == 0)) then
		return false
	end
	
	Log.f("  edited %d lines", #res_t)
	
	if (write_f) then
		local s = table.concat(res_t, "\n")
	
		Util.WriteFile(fn, s)
	end
	
	return true
end

---- Edit Text String ----------------------------------------------------------

function Debian.EditTextString(s, title)

	Log.f("Debian.EditTextString(len = %d)", #s)
	assertf(type(s) == "string", "illegal string type")
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

function Debian.AppendLines(fn, lines_t, nmatch)

	Log.f("Debian.AppendLines(fn %S)", tostring(fn))
	assertf(type(fn) == "string", "illegal source path in Debian.AppendLines()")
	assertf(type(lines_t) == "table", "illegal lines_t in Debian.AppendLines()")
	assertf(type(nmatch) == "string", "illegal nmatch string in Debian.AppendLines()")
	
	local f_s = ""
	
	if (Util.FileExists(fn)) then
		f_s = Util.LoadFile(fn)
		-- pre-write LF if doesn't have one?
		
		if (f_s:match(nmatch)) then
			Log.f("  found nmatch %S, aborting...", nmatch)
			return "canceled"					-- canceled -- should apply nmatch EARLIER and hide from menu???
		end
	else
		shell.touch(fn)
	end
	
	local append_s = table.concat(lines_t, "\n")
	
	f_s = f_s .. append_s .. "\n"
	
	local ok = Debian.EditTextString(f_s, '"' .. fn .. ' (preview)"')	-- ESCAPES title
	if (ok) then
		Util.WriteFile(fn, f_s)
		return "ok"
	else
		return "canceled"
	end
end

---- Gsub Lines ----------------------------------------------------------------

function Debian.GsubLines(fn, gsub_list)

	Log.f("Debian.GsubLines(fn %S)", tostring(fn))
	
	-- FUCKED, operates on WHOLE STRING instead of LINES (FIXME)
	-- ^$ anchors only apply to start/end of WHOLE STRING
	assertf(type(fn) == "string", "illegal source path in Debian.AppendLines()")
	
	if (not Util.FileExists(fn)) then
		Log.f(" error - file %S doesn't exist", fn)
		return "warning"
	end
	
	local f_s = Util.LoadFile(fn)
	local nsubs
	
	for _, gsub_def in ipairs(gsub_list) do
		assertf(type(gsub_def) == "table", "illegal gsub_def %S (expected table)", tostring(gsub_def))
		assertf((#gsub_def >= 2), "illegal gsub_def sz")
		
		local src, dst = gsub_def[1], gsub_def[2]
		
		f_s, nsubs = f_s:gsub(src, dst)
		
		-- do NOT log regex patterns
		-- Log.f("gsub_def(org: %S, dst: %S) = %d subs", src, dst, nsubs)
	end
	
	local ok = Debian.EditTextString(f_s, '"' .. fn .. ' (preview)"')
	if (ok) then
		Util.WriteFile(fn, f_s)
		return "ok"
	else
		return "canceled"
	end
end

---- Exec ----------------------------------------------------------------------

function Debian.Exec(fn, cmd_list)

	Log.f("Debian.Exec(fn = %S, cmd_list = %S)", tostring(fn), tostring(cmd_list))
	
	assertf(type(cmd_list) == "table", "cmd_list is not table (is %s)", type(cmd_list))
	assert(type(fn) == "string")
	
	table.insert(cmd_list, 1, sprintf("cd '%s'", fn))
	
	local all_cmds = table.concat(cmd_list, " && ")
	Log.f("all_cmds = %S", all_cmds)
	
	os.execute(all_cmds)
	
	Log.f("Debian.Exec() done")
end

---- PACKAGES ------------------------------------------------------------------

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

	Log.f("ClearPackagesCheckList()")
	
	ckecklist_entries = {}
	apt_keys = {}
	apt_sources = {}
	downloads = {}
end

---- Add to Check List ---------------------------------------------------------

local
function AddToCheckList(menu_name, menu_entry, dupes_t, avail_t)

	Log.f("AddToCheckList(%S)", tostring(menu_name))
	
	assert("table" == type(ckecklist_entries))
	assert("table" == type(dupes_t))
	assert("table" == type(avail_t))

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
	
	-- --buildlist text height width list-height 
	
	
	table.insert(ckecklist_entries, ('"---- %s ----" "" 0'):format(menu_name))
	
	-- entry is off by default
	local flag_s = "0"

	for k, entry in ipairs(menu_entry) do
		
		local pkg = entry
			
		if (type(pkg) ~= "boolean" and not avail_t[pkg]) then
			Log.f("error: UNAVAILABLE package %S", tostring(pkg))
			return nil	-- error
		end	
			
		if (dupes_t[entry]) then
		
			-- already have it
			-- backslash doesn't work when 1st char
			-- table.insert(ckecklist_entries, ('%s %s on'):format(pkg, pkg))			-- tag already-installed with underscores
			
		else
		
			if (type(entry) == "boolean") then
				-- change entry on/off for subsequent items
				if (entry) then
					flag_s = "on"
				else
					flag_s = "0"
				end
			else
				table.insert(ckecklist_entries, ('%s %s %s'):format(pkg, pkg, flag_s))
			end
		end
	end
end

---- Add Packages Checklist ----------------------------------------------------

local
function AddPackagesCheckList(pkgs_def)

	Log.f("AddPackagesCheckList()")
	assertf(type(pkgs_def) == "table", "illegal AddPackagesCheckList() def arg")
	
	local dupes = GetDupePackages()
	
	local all_t = tshell['apt-cache']("pkgnames")
	if (not all_t) then
		return nil
	end
	
	table.sort(all_t)
	
	local all_set = {}
	
	for k, pkg in ipairs(all_t) do
		all_set[pkg] = true
	end
	
-- build packages checklist
	for _, menu_entry in ipairs(pkgs_def) do
	
		assert("table" == type(menu_entry))
		
		for title, entry in pairs(menu_entry) do
		
			AddToCheckList(title, entry, dupes, all_set)
		
		end
	end
end

---- Validate Packages ---------------------------------------------------------

local
function ValidatePackages(pack_list)

	Log.f("ValidatePackages()")
	
	local filtered_tab = {}
	
	for k, pkg in ipairs(pack_list) do
		
		local res = Debian.PackageStatus(pkg)
		assert(res)
		
		if ("installed" == res) then
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

	Log.f("PromptInstallPackages()")
	
-- prompt checklist
	-- "--colors" don't work
	local pack_t = tshell.dialog("--separate-output", "--stdout", "--visit-items", "--buildlist", "'Packages'", 0, 0, 0, table.concat(ckecklist_entries, " "))
	if (not pack_t or {} == pack_t) then
		return "canceled"
	end
	
-- confirm packages
	res_s = shell.dialog("--yesno", '"confirm:\n\n' .. table.concat(pack_t, '\n') .. '"', 0, 0)
	if (not res_s) then
		Log.f("install not confirmed")
		return "warning"
	end

-- validate packages
	local filtered_t = ValidatePackages(pack_t)
	if (not filtered_t) then
		Log.f("warning: some packages missing, canceling")
	
		return "warning"
	end
	
	-- install
	Debian.Install(table.concat(filtered_t, " "))
		
	return "ok"
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

---- Prompt Main Menu ----------------------------------------------------------

local
function PromptMainMenu()

	Log.f("PromptMainMenu() start")
	
	local main_menu_def =
	{	
		{ title = "Patches", fn = Patches.ApplyMenu},
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
	
	for k, entry in ipairs(main_menu_def) do
	
		assertf("table" == type(entry), "illegal entry")
		assertf("string" == type(entry.title), "illegal entry.title")
		assertf(nil == entryLUT[entry.title], ('duplicate main_menu_def[%d].title["%s"]'):format(k, entry.title))
		assertf("function" == type(entry.fn), ('illegal entry["%s"].fn'):format(entry.title))
		
		table.insert(main_menu_entries, ('"%s" ""'):format(entry.title))
		
		entryLUT[entry.title] = entry

	end
	
	local menu_title = sprintf("'Main %s'", tostring(Debian.AUTH))
	assert(type(menu_title) == "string")
	
	--[[	dialog --stdout --menu "mytitle" 0 0 0 "item1" "" "item2" ""	]]
	local res_s = pshell.dialog("--stdout --cancel-label 'Exit' --menu", menu_title, 0, 0, 0, table.concat(main_menu_entries, " "))
	if (not res_s) then
		Log.f("exited installer")
		return "exit"
	end
	
	Log.f("selected menu entry %S (type %s)", res_s, type(res_s))
	
	-- lookup menu function
	local fn = entryLUT[res_s].fn
	assertf("function" == type(fn), "PromptMainMenu - didn't look up function")
	
	-- optional
	local fn_arg = entryLUT[res_s].fn_arg

	shell.clear()
	
	Log.f("PromptMainMenu() almost done")

	-- call function
	return fn(fn_arg)
end

---- Main ----------------------------------------------------------------------

function main()

	Log.Init("installer.log")
	Log.SetTimestamp("%H:%M:%S > ")
	
	Debian:Init()
	
	local pwd = os.getenv("PWD")
	
	Patches.ParseAllPatches()
	
	Debian.Install("dialog", "force")
	
	-- menu loop
	while (true) do

		-- shell.clear()
	
		local res = PromptMainMenu()
		
		Log.f("PromptMainMenu() returned %S", tostring(res))
		
		if ("exit" == res) then
			break
		elseif ("canceled" == res) then
			-- io.write("\nwas canceled, press Return...");io.read()
		elseif ("warning" == res) then
			io.write("\nhad warning, press Return...");io.read()
		else	-- ok
			io.write("\npress Return...");io.read()
		end
	end
	
	-- shell.clear()
	
	pshell.chown("1000:1000", pwd .. "/installer.log")
end

main()


