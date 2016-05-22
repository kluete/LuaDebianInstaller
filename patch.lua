---- Parse Patch ---------------------------------------------------------------

local
function ParsePatch(patch)

	Log.f("ParsePatch(patch = %s)", type(patch))
	assertf(type(patch) == "table", "illegal patch type %S", type(patch))
	
	local title = patch.title
	assertf(type(title) == "string", "illegal patch title")
	
	Log.f("  title %S)", title)
	
	local op_LUT =
	{
		addlines = {	fn = Debian.AppendLines,
				args = {"path", "nmatch", "args"}
				},
		gsublines = {	fn = Debian.GsubLines,
				args = {"path", "args"}
				},
		exec = {	fn = Debian.Exec,
				args = {"path", "args"}
				},
	}
		
	for k, entry in ipairs(patch) do
	
		assertf(type(entry) == "table", "illegal patch entry type")
		local op = entry.op
		assertf(type(op) == "string", "illegal patch op type")
		
		Log.f("  patch.entry = %S", op)  
		
		assertf(type(entry.path) == "string", "illegal patch path")
		local args = entry.args
		assertf(type(args) == "table", "illegal patch args type")
		assertf(#args > 0, "patch has zero args")
		
		local op_e = op_LUT[op]
		assertf(type(op_e) == "table", "illegal patch op entry (should be table)")
		local op_fn = op_e.fn
		assertf(type(op_fn) == "function", "illegal patch entry op fn")
		local op_args = op_e.args
		assertf(type(op_args) == "table", "illegal patch op args")
		
		local src_path = Util.NormalizePath(entry.path, "", {LSK = '/home/'..Debian.USER})
		
		-- poke back
		entry.src_path = src_path
		assertf(type(src_path) == 'string', 'illegal src_path type')
		
		Log.f("    src_path %S", src_path)					
	end
end

---- Parse All Patches ---------------------------------------------------------

local
function ParseAllPatches()

	Log.f("ParseAllPatches()")
	
	for k, patch in ipairs(patches_def) do
	
		ParsePatch(patch)
	end
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
		
		local res = op_fn(src_path, args)
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
		
		-- (all patches are disabled by default)
		table.insert(patches_checklist, ('"%s" "" 0'):format(patch.title))
		
		patchesLUT[patch.title] = patch
	end
	
	return patches_checklist, patchesLUT
end

---- Patches Menu --------------------------------------------------------------

local
function ApplyPatchesMenu()

	local patches_checklist, patchesLUT = BuildPatchesCheckList()

	shell.clear()
		
	local menu_title = sprintf("'Patches'")
	
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

	Debian.Update()
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

