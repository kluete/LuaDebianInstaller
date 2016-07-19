#!/usr/bin/env lua

package.path = package.path .. ";../?.lua;../DebLua/?.lua"

require "lua_shell"

local dialog = require "lua_dialog"

local s_my_repos =
{
	lxUtils = "",
	lxUtilsDev = "",
	libgit2cpp = "",
	JUCE = "focus",
	juce_lib = "",
	LuaDebianInstaller = "",
	recover_itunes = "",
	wxWidgets = "petah",
	codelite = "stable92",
	taglib = "petah",
}

function main()

	Log.Init("git_installer.log")
	Log.SetTimestamp("%H:%M:%S > ")
	
	local checklist = {}
	
	for k, v in pairs(s_my_repos) do
		table.insert(checklist, k)
	end
	
	table.sort(checklist)
	
	local selected_t = dialog.Checklist("repos", checklist)
	
	
end


main()
