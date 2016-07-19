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

---- main ----------------------------------------------------------------------

function main()

	Log.Init("git_installer.log")
	Log.SetTimestamp("%H:%M:%S > ")
	
	-- local lxgit = os.getenv("LXGIT")
	local lxgit = "/media/vm/test"
	assertt(lxgit, "string")
	
	local checklist = {}
	
	for repo_name, v in pairs(s_my_repos) do
		table.insert(checklist, repo_name)
	end
	
	table.sort(checklist)
	
	local selected_t = dialog.Checklist("my repos", checklist)
	assertt(selected_t, "table")
	
	local github_prefix = "ssh://git@github.com/kluete/"
	
	for _, repo_name in ipairs(selected_t) do
		local branch = s_my_repos[repo_name]
		assertt(branch, "string")
		
		local url = github_prefix .. repo_name
		local repo_local_dir = lxgit .. "/" .. repo_name
		
		Log.f("cloning %S to %S", url, repo_local_dir)
		pshell.git("clone", url, repo_local_dir)
		
		if (branch ~= "") then
			pshell.git("-C", repo_local_dir, "checkout", branch)
		end
	end
	
	checklist = {}
	
	for repo_name, _ in pairs(s_ext_repos) do
		table.insert(checklist, repo_name)
	end
	
	table.sort(checklist)
	
	selected_t = dialog.Checklist("external repos", checklist)
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
		
		local repo_local_dir = lxgit .. "/" .. repo_name
		
		Log.f("cloning scc %S from %S to %S", scc, url, repo_local_dir)
		pshell[scc](scc_arg, url, repo_local_dir)
	end
	
end


main()
