-- installer patches

---- Apply Patch ---------------------------------------------------------------

local
function ApplyPatch(patch)

	Log.f("ApplyPatch(patch = %s)", type(patch))
	assertf(type(patch) == "table", "illegal patch type %S", type(patch))
	
	local title = patch.title
	assertf(type(title) == "string", "illegal patch title")
	
	Log.f(" title %S)", title)
	
	for k, entry in ipairs(patch) do
	
		assertf(type(entry) == "table", "illegal patch entry type")
		local parsed_e = entry.parsed_e
		assertf(type(parsed_e) == "table", "illegal patch parsed_e")
		
		local op_name = parsed_e.op_name
		assertf(type(op_name) == "string", "illegal parsed patch op_name")
		
		Log.f("  op_name = %S)", op_name)

		local func = parsed_e.func
		assertf(type(func) == "function", "illegal parsed patch function")
		
		local arg_list = parsed_e.arg_list
		assertf(type(arg_list) == 'table', 'illegal parsed patch arg_list type')
		
		local res = func(unpack(arg_list))
		if (not res) then
			return		-- canceled
		end
	end
	
	return "nopause"
end

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
		addlines = {	func = Debian.AppendLines,
				arg_names = {"path", "args", "nmatch"}
				},
		gsublines = {	func = Debian.GsubLines,
				arg_names = {"path", "args"}
				},
		exec = {	func = Debian.Exec,
				arg_names = {"path", "args"}
				},
	}
	
	local arg_types =
	{
		path = "string",
		args = "table",
		nmatch = "string",
	}
	
	for k, entry in ipairs(patch) do
	
		assertf(type(entry) == "table", "illegal patch entry type")
		local op_name = entry.op
		assertf(type(op_name) == "string", "illegal patch op type")
		Log.f("  patch.entry = %S", op_name)  
		
		local op_e = op_LUT[op_name]
		assertf(type(op_e) == "table", "illegal patch op entry (should be table)")
		local func = op_e.func
		assertf(type(func) == "function", "illegal patch entry op func")
		
		local arg_names = op_e.arg_names
		assertf(type(arg_names) == "table", "illegal patch op args")
		
		local arg_list = {}
		
		for _, arg_name in ipairs(arg_names) do
		
			local arg_t = arg_types[arg_name]
			assertf(arg_t, "illegal/undeclared patch arg name %S", arg_name)
			
			local arg_v = entry[arg_name]
			assertf(arg_v, "missing patch arg %S", arg_name)
			assertf(type(arg_v) == arg_t, "illegal mismatched patch arg type %S is %s", arg_k, type(arg_v))
			
			if (arg_name == "path") then
				arg_v = Util.NormalizePath(arg_v, "", {LSK = Debian.HOME})
				
				Log.f("  normalized path = %S", tostring(arg_v))
			end
				
			table.insert(arg_list, arg_v)
		end
		
		entry.parsed_e = {op_name = op_name, func = func, arg_list = arg_list}
	end
end

---- Parse All Patches ---------------------------------------------------------

local
function ParseAllPatches()

	Log.f("ParseAllPatches(%d entries)", #patches_def)
	
	for k, patch in ipairs(patches_def) do
	
		ParsePatch(patch)
	end
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

	-- Debian.Update()
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

