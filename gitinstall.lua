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

local s_repo_lut =
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
	
	-- inhance
	rapidjson = "git://github.com/miloyip/rapidjson.git",
	re2 = "git://github.com/google/re2.git",
	hashlibpp = "git://github.com/aksalj/hashlibpp.git",
	cpprestdsk = "clone git://github.com/Microsoft/cpprestsdk.git",
}

local s_ext_repos =
{
	"asio",
	"lua",
	"libsndfile",
	"faad2",
	"catch",
	"freetyp2",
	"portaudio",
	"mpg123",
	"soundtouch",
}

local s_inhance_repos =
{
	"rapidjson",
	"re2",
	"hashlibpp",
	"cpprestdsk",
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
	shell.rm("-rf", Util.EscapePath(dir))
	
	ok = not Util.DirExists(dir)
	Log.f(" dir %S blank = %s", dir, tostring(ok))
	
	return ok
end

---- Filter Existing local Repos -----------------------------------------------

local
function FilterExistingLocal(lxgit, repo_list)

	assertt(lxgit, "string")
	assertt(repo_list, "table")
	
	local res_t = {}
	
	for _, repo_name in ipairs(repo_list) do
	
		local dest_dir = lxgit .. "/" .. repo_name
		
		if (not Util.DirExists(dest_dir)) then
			table.insert(res_t, repo_name)
		else
			Log.f(" ignored repo %S, local already exists", repo_name)
		end
	end
	
	table.sort(res_t)
end

---- Get Repo ------------------------------------------------------------------

local
function GetRepo(repo_name)

	assertt(repo_name, "string")
	
	local url = s_repo_lut[repo_name]
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
		return false
	end
	
	Log.f("cloning scc %S from %S to %S", scc, url, dest_dir)
	shell[scc](scc_arg, url, dest_dir)
	
	return true
end

---- main ----------------------------------------------------------------------

function main()

	Log.Init("git_installer.log")
	Log.SetTimestamp("%H:%M:%S > ")
	
	local lxgit_default = os.getenv("LXGIT") or ""
	-- local lxgit_default = "/media/vm/test"
	local lxgit = dialog.SelectDir("select lxgit", lxgit_default)
	if (not lxgit) then
		Log.f(" aborted on lxgit select")
		return
	end
	
	assertt(lxgit, "string")
	if (not Util.DirExists(lxgit)) then
		Util.MkDir(lxgit)
	end
	
	local checklist = {}
	
	for repo_name, v in pairs(s_my_repos) do
		table.insert(checklist, repo_name)
	end
	
	table.sort(checklist)
	
	local selected_t = dialog.Checklist("my repos", FilterExistingLocal(checklist))
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
		shell.git("clone", url, dest_dir)
		
		if (branch ~= "") then
			shell.git("-C", dest_dir, "checkout", branch)
		end
	end
	
	selected_t = dialog.Checklist("external repos", FilterExistingLocal(s_ext_repos))
	if (not selected_t) then
		Log.f(" aborted external repos")
		return
	end
	assertt(selected_t, "table")
	
	for _, repo_name in ipairs(selected_t) do
		local ok = GetRepo(repo_name)
		if (not ok) then
			Log.f(" aborted external repos")
		return
	end
	
	selected_t = dialog.Checklist("Inhance repos", FilterExistingLocal(s_inhance_repos))
	if (not selected_t) then
		Log.f(" aborted Inhance repos")
		return
	end
	assertt(selected_t, "table")
	
	for _, repo_name in ipairs(selected_t) do
		local ok = GetRepo(repo_name)
		if (not ok) then
			Log.f(" aborted Inhance repos")
		return
	end
end

main()
