-- lua dialog utils for Linux

-- apt-get install dialog

require "lua_shell"

local full_sz = {w = 0, h = 0}
local best_sz = {w = 0, h = 0}

---- Get Terminal Size ---------------------------------------------------------

local
function GetTermSize()
	
	local res = pshell.dialog("--stdout", "--print-maxsize")
	-- may contain terminal color escape sequences (print with "%q")
	assertt(res, "string")
	
	-- MaxSize: 48, 146
	local h, w = res:match("MaxSize: (%d+), (%d+)")
	assertf(h and w, "couldn't retrieve terminal size")
	
	return w, h
end

---- Initialize ----------------------------------------------------------------

local
function Init()

	local w, h = GetTermSize()
	full_sz = {w = w, h = h}
	best_sz = {w = math.floor(w * 0.75), h = math.floor(h * 0.75)}
end

---- Prompt Yes/No -------------------------------------------------------------

local
function PromptYesNo(title, msg)

	assertt(title, "string")
	assertt(msg, "string")
	
	local cod = shell.dialog("--stdout", "--no-shadow", "--title '"..title.."'", "--yesno", msg, best_sz.h, best_sz.w)
	printf("yesno returned cod %S", tostring(cod))
	
	if (not cod) then
		return "no"
	end
	
	local lut = {[true] = "yes", [0] = "yes", [1] = "no", [2] = "extra"}
	local res = lut[cod]
	assertf(res, "illegal yes/no return code %S", tostring(cod))
	
	return res
end

---- Select File/Directory -----------------------------------------------------

local
function SelectFileDir(title, default_path)

	assertt(title, "string")
	assertt(default_path, "string")
	
	local res = pshell.dialog("--stdout", "--no-shadow", "--title '"..title.."'", "--dselect", Util.EscapePath(default_path), best_sz.h, best_sz.w)
	-- is nil on cancel
	
	return res
end

---- Menu ----------------------------------------------------------------------

local
function SelectMenu(title, def_t)

	assertt(title, "string")
	assertt(def_t, "table")
	
	local menu_entries_t = {}
	
	for _, name in ipairs(def_t) do
		table.insert(menu_entries_t, ('"%s" ""'):format(name))
	end
	
	--[[	dialog --stdout --menu "mytitle" 0 0 0 "item1" "" "item2" ""	]]
	local res = pshell.dialog("--stdout", "--no-shadow", "--cancel-label 'cancel' --menu", "'"..title.."'", best_sz.h, best_sz.w, 0, table.concat(menu_entries_t, " "))
	-- is nil on cancel
	
	return res
end

---- Get Checklist -------------------------------------------------------------

local
function Checklist(title, t_avail, t_enabled)

	assertt(title, "string")
	assertt(t_avail, "table")
	
	local enabled_set = {}
	if (t_enabled) then
		assertt(t_enabled, "table")
		
		for _, name in ipairs(t_enabled) do
			assertt(name, "string")
			
			enabled_set[name] = "on"
		end
	end
	
	local ckecklist_entries = {}	
	
	for _, name in ipairs(t_avail) do
		
		local entry = name
		local flag_s = enabled_set[name] or "0"
		
		table.insert(ckecklist_entries, ('"%s" "" %s'):format(entry, flag_s))
	end
	
	local res_t = tshell.dialog("--stdout", "--separate-output", "--checklist", "'"..title.."'", best_sz.h, best_sz.w, 0, table.concat(ckecklist_entries, " "))
	-- nil on cancel
	
	return res_t
end

---- INSTANTIATE ---------------------------------------------------------------

return
{
	Init = Init,
	PromptYesNo = PromptYesNo,
	SelectFile = SelectFileDir,
	SelectDir = SelectFileDir,
	Checklist = Checklist,
	Menu = SelectMenu,
}

-- nada mas
