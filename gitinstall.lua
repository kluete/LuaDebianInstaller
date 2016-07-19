#!/usr/bin/env lua

--[[
	apt-get install dialog git subversion


]]

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
	mupdf = "inhance",
}

local s_ext_repos =
{
	asio = "git://github.com/chriskohlhoff/asio.git",
	lua = "git://github.com/lua/lua.git",
	libsndfile = "git://github.com/erikd/libsndfile.git",
	faad2 = "git://github.com/mecke/faad2.git",
	catch = "git://github.com/philsquared/Catch.git",
	freetype2 = "git://git.sv.gnu.org/freetype/freetype2.git",
	
	-- svn
	portaudio = "https://subversion.assembla.com/svn/portaudio/portaudio/trunk",
	mpg123 = "svn://orgis.org/mpg123/trunk",
	soundtouch = "http://svn.code.sf.net/p/soundtouch/code/trunk",
}

---- Check Dest Dir ------------------------------------------------------------

local
function CheckDestDir(dir)

	assertt(dir, "string")
	
	if (not Util.DirExists(dir)) then
		return true
	end
	
	local res = dialog.PromptYesNo(sprintf("%s already exists", dir), "continue?")
	if (res ~= "yes") then
		return false
	end
	
	res = dialog.PromptYesNo(sprintf("erase dir %s", dir), "are you sure?", "no")
	if (res ~= "yes") then
		return false
	end
	
	Log.f(" erasing dir %S", dir)
	pshell.rm("-rf", Util.EscapePath(dir))
	
	ok = not Util.DirExists(dir)
	Log.f(" dir %S blank = %s", dir, tostring(ok))
	
	return ok
end

---- main ----------------------------------------------------------------------

function main()

	Log.Init("git_installer.log")
	Log.SetTimestamp("%H:%M:%S > ")
	
	-- local lxgit_default = os.getenv("LXGIT")
	local lxgit_default = "/media/vm/test"
	local lxgit = dialog.SelectDir("select lxgit", lxgit_default)
	assertt(lxgit, "string")
	if (not Util.DirExists(lxgit)) then
		Util.MkDir(lxgit)
	end
	
	local checklist = {}
	
	for repo_name, v in pairs(s_my_repos) do
		table.insert(checklist, repo_name)
	end
	
	table.sort(checklist)
	
	local selected_t = dialog.Checklist("my repos", checklist)
	if (not selected_t) then
		Log.f(" aborted my repos")
		return
	end
	assertt(selected_t, "table")
	
	local github_prefix = "ssh://git@github.com/kluete/"
	
	for _, repo_name in ipairs(selected_t) do
		local branch = s_my_repos[repo_name]
		assertt(branch, "string")
		
		local url = github_prefix .. repo_name
		local dest_dir = lxgit .. "/" .. repo_name
		
		if (not CheckDestDir(dest_dir)) then
			Log.f(" aborted on dir %S", dest_dir)
			return
		end
		
		Log.f("cloning %S to %S", url, dest_dir)
		pshell.git("clone", url, dest_dir)
		
		if (branch ~= "") then
			pshell.git("-C", dest_dir, "checkout", branch)
		end
	end
	
	checklist = {}
	
	for repo_name, _ in pairs(s_ext_repos) do
		table.insert(checklist, repo_name)
	end
	
	table.sort(checklist)
	
	selected_t = dialog.Checklist("external repos", checklist)
	if (not selected_t) then
		Log.f(" aborted external repos")
		return
	end
	assertt(selected_t, "table")
	
	for _, repo_name in ipairs(selected_t) do
		local url = s_ext_repos[repo_name]
		assertt(url, "string")
		
		local scc, scc_arg
		
		if (url:find("^git://")) then
			-- git
			scc = "git"
			scc_arg = "clone"
		elseif (url:find("svn")) then
			-- svn
			scc = "svn"
			scc_arg = "co"		-- (checkout)
		else
			-- error, couldn't determine SCC
			assertf(false, "couldn't determine SCC from url %S", url)
		end
		
		local dest_dir = lxgit .. "/" .. repo_name
		
		if (not CheckDestDir(dest_dir)) then
			Log.f(" aborted on dir %S", dest_dir)
			return
		end
		
		Log.f("cloning scc %S from %S to %S", scc, url, dest_dir)
		pshell[scc](scc_arg, url, dest_dir)
	end
	
end


main()
