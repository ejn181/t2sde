-- --- T2-COPYRIGHT-NOTE-BEGIN ---
-- T2 SDE: package/*/sam/sam/config.lua
-- Copyright (C) 2006 - 2022 The T2 SDE Project
-- 
-- This Copyright note is generated by scripts/Create-CopyPatch,
-- more information can be found in the files COPYING and README.
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License version 2.
-- --- T2-COPYRIGHT-NOTE-END ---

sam = sam or {}

local config_mapping = {
	SDECFG_ARCH         = "ARCH",
	SDECFG_CROSSBUILD   = "CROSSBUILD",

	-- ...

	SDECFG_SHORTID      = "SHORTID",
	SDECFG_ID           = "ID",
}

-- tab = sam.config(config-name)
--   Read config, return table (with mappings).
--   The original data is stored in "tab.config[SDECFG_...]",
--   the mapped values are in "tab[...]".
function sam.config(config)
	local retval = { config = {} }
	local t2dir = os.getenv("T2DIR") or "."
	local f = assert(io.open(t2dir .. "/config/" .. config .. "/config"))

	--  parse config/$config/config, put it into retval.config
	for line in f:lines() do
		_, _, name, value = string.find(line, "export ([^=]+)=['\"]?([^'\"=]+)['\"]?")
		
		if name then
			retval.config[name] = value

			if config_mapping[name] then
				retval[ config_mapping[name] ] = value
			end
		end
	end

	return retval
end
