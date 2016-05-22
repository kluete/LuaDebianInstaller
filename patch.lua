---- Parse Patch ---------------------------------------------------------------

local
function ParsePatch(patch, simul_prefix, dest_simul_dir)

	assertf(type(patch) == "table", "illegal patch type %S", type(patch))
	
	local rewrite_f = (Debian.simulate) and (nil ~= simul_prefix)
	
	local title = patch.title
	assertf(type(title) == "string", "illegal patch title")
	
	printf("ParsePatch(%S)", title)
	
	local op_LUT = {addlines = Debian.AppendLines, gsublines = Debian.GsubLines, exec = Debian.Exec}
	local readable_f = true
	
	for k, entry in ipairs(patch) do
	
		assertf(type(entry) == "table", "illegal patch entry type")
		local op = entry.op
		assertf(type(op) == "string", "illegal patch op type")
		assertf(type(entry.path) == "string", "illegal patch path")
		local args = entry.args
		assertf(type(args) == "table", "illegal patch args type")
		assertf(#args > 0, "patch has zero args")
		
		local op_fn = op_LUT[op]
		assertf(type(op_fn) == "function", "illegal patch op name")
		
		local src_path
		
		if (rewrite_f) then
			src_path = simul_prefix .. Util.NormalizePath(entry.path, "", {LSK = '/home/lsk'})
			assertf(Util.FileExists(src_path), "src_path doesn't exist")
		else
			src_path = Util.NormalizePath(entry.path, "", {LSK = '/home/'..Debian.USER})
		end
		
		-- poke back
		entry.src_path = src_path
		assertf(type(src_path) == 'string', 'illegal src_path type')
		
		-- cummulate readable flag for multi-file patch
		if ("addlines" ~= op) then
			readable_f = readable_f and Util.StatFile(src_path, "r")
			if (not readable_f) then
				printf("  not readable %S", src_path)
				break
			end
		end
		
		printf("  src_path %S", src_path)
					
		local dest_path
		
		entry.simul_dest_path = dest_simul_dir .. '/' .. entry.path:gsub('([/%.%$])', '_')
		printf("  simul_dest_path %S", entry.simul_dest_path)
		
		entry.dest_path = Util.NormalizePath(entry.path, nil, {LSK = '/home/'..Debian.USER})
		printf("  dest_path %S", entry.dest_path)
	end
	
	patch.readable_f = readable_f
end

---- Parse All Patches ---------------------------------------------------------

local
function ParseAllPatches(simul_prefix, simul_dest)

	Log.f("ParseAllPatches(simul_prefix = %S, simul_dest = %S", tostring(simul_prefix), tostring(simul_dest))
	
	-- simulated dest in home folder
	local dest_simul_dir = Debian.HOME .. simul_dest
	if (not Util.DirExists(dest_simul_dir)) then
		Util.MkDir(dest_simul_dir)
	end
	
	for k, patch in ipairs(patches_def) do
	
		ParsePatch(patch, simul_prefix, dest_simul_dir)
	end
	
	return dest_simul_dir
end

---- Apply Patch ---------------------------------------------------------------

local
function ApplyPatch(patch)

	assertf(type(patch) == "table", "illegal patch type %S", type(patch))
	
	local title = patch.title
	assertf(type(title) == "string", "illegal patch title")
	
	local op_LUT = {addlines = Debian.AppendLines, gsublines = Debian.GsubLines, exec = Debian.Exec}
	
	for k, entry in ipairs(patch) do
	
		assertf(type(entry) == "table", "illegal patch entry type")
		local op = entry.op
		assertf(type(op) == "string", "illegal patch op type")
		assertf(type(entry.path) == "string", "illegal patch path")
		local args = entry.args
		assertf(type(args) == "table", "illegal patch args type")
		
		local op_fn = op_LUT[op]
		assertf(type(op_fn) == "function", "illegal patch op type is not a function")
		
		local src_path = entry.src_path
		assertf(type(src_path) == 'string', 'illegal src_path type')
		
		local dest_path
		
		if (Debian.simulate) then
			dest_path = entry.simul_dest_path
		else
			dest_path = entry.dest_path
		end
		assertf(type(dest_path) == 'string', 'illegal dest_path type')
		
		local res = op_fn(src_path, args, dest_path)
		if (not res) then
			return		-- canceled
		end
	end
	
	return "nopause"
end

---- Build Patches Menu --------------------------------------------------------

local
function BuildPatchesCheckList()

	local patches_checklist = {}
	local patchesLUT = {}

	for k, patch in ipairs(patches_def) do
	
		assertf("table" == type(patch), "illegal patch entry")
		assertf("string" == type(patch.title), "illegal patch title")
		
		if (patch.readable_f) then
			-- (all patches are disabled by default)
			table.insert(patches_checklist, ('"%s" "" 0'):format(patch.title))
		
			patchesLUT[patch.title] = patch
		else
			printf("ignored non-readable patch %S", patch.title)
		end
	end
	
	return patches_checklist, patchesLUT
end

---- Patches Menu --------------------------------------------------------------

local
function ApplyPatchesMenu()

	local patches_checklist, patchesLUT = BuildPatchesCheckList()

	shell.clear()
		
	local menu_title = sprintf("'Patches - %s'", Debian.simulate_str)
	
	-- prompt patches checklist (could use --output-separator <char>)
	local res_s = pshell.dialog("--stdout --ok-label 'Apply' --cancel-label 'Back' --checklist", menu_title, 0, 0, 0, table.concat(patches_checklist, " "))
	if (not res_s) then
		return "nopause"
	end
		
	-- decode checklist reply, separated by double-quote
	local res_t = {}
	string.gsub(res_s, '"([^"]+)"',	function(s)
						table.insert(res_t, s)
					end)

	-- apply patches
	for k, patch_s in ipairs(res_t) do
		
		printf("applying patch[%d]: %S", k, tostring(patch_s))
	
		local patch = patchesLUT[patch_s]
		assertf(type(patch) == "table", "patchesLUT[%S] failed", tostring(patch_s))
		
		local res = ApplyPatch(patch)
		if (not res) then
			-- canceled
			return "exit"
		end
	end

	if (not Debian.simulate) then
		Debian.Update()
	end
end

local Patches =
{
	ApplyMenu = ApplyPatchesMenu,
	BuildCheckList = BuildPatchesCheckList,
	ApplyOne =  ApplyPatch,
	ParseAllPatches = ParseAllPatches,

}

function GetPatches()

	return Patches

end

