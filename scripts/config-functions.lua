#!/usr/bin/lua
-- --- T2-COPYRIGHT-NOTE-BEGIN ---
-- This copyright note is auto-generated by ./scripts/Create-CopyPatch.
-- 
-- T2 SDE: scripts/config-functions.lua
-- Copyright (C) 2006 The T2 SDE Project
-- Copyright (C) 2006 Rene Rebe <rene@exactcode.de>
-- 
-- More information can be found in the files COPYING and README.
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License. A copy of the
-- GNU General Public License can be found in the file COPYING.
-- --- T2-COPYRIGHT-NOTE-END ---

packages = {} -- our internal package array of tables

function pkglistread (filename)
   local f = io.open (filename, "r")
   
   packages = {}
   
   for line in f:lines() do
      -- use captures to yank out the various parts:
      -- X -----5---9 149.800 develop lua 5.1.1 / extra/development DIETLIBC 0
      -- X -----5---- 112.400 xorg bigreqsproto 1.0.2 / base/x11 0
      
      -- hm - maybe strtok as one would do in C?
      
      pkg = {}
      pkg.status, pkg.stages, pkg.priority, pkg.repository,
      pkg.name, pkg.ver, pkg.extraver, pkg.categories, pkg.flags =
	 string.match (line, "([XO]) *([0123456789-]+) *([0123456789.]+) *(%S+) *(%S+) *(%S+) *(%S*) */ ([abcdefghijklmnopqrstuvwxyz0123456789/ ]+) *([ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _-]*) 0")
      
      -- shortcomming of above regex
      pkg.categories = string.match (pkg.categories, "(.*%S) *");
      
      pkg.alias = pkg.name
      pkg.default_status = pkg.status
      
      --[[
      print (line);
      
      if pkg.categories == nil then
	 pkg.categories = "nil" end
      
      if pkg.flags == nil then
	 pkg.flags = "nil" end
      io.write ("'",pkg.categories,"'",pkg.flags,"'\n")
      ]]--
      
      if pkg.alias == nil then
	 print ("error parsing: ", line)
      else
	 packages[#packages+1] = pkg
      end
      
   end
   f:close()
end

function pkglistwrite (filename)
   local f = io.open (filename, "w")
   
   for i,pkg in ipairs(packages) do
      -- only write not fully disabled packages
      if pkg.status ~= "-" then
	 
	 f:write (pkg.status, " ", pkg.stages, " ", pkg.priority, " ",
		  pkg.repository, " ", pkg.alias, " ", pkg.ver)
	 
	 if string.len(pkg.extraver) > 0 then
	    f:write (" ", pkg.extraver)
	 end
	 
	 f:write (" / ", pkg.categories)
	 
	 if string.len(pkg.flags) > 0 then
	    f:write (" ", pkg.flags)
	 end
	 
	 f:write (" 0\n")
      end
   end
   f:close()
end

-- tracks the state and also expands patterns
-- either called with just packages or repository/package
-- allowing wildcards such as perl/*
local function pkgswitch (mode, ...)

   local tr = { ["+"] = "%+",
                ["-"] = "%-",
                ["*"] = ".*" }

   for i,arg in ipairs {...} do
      -- split repo from the package and expand wildcard to regex
      local rep, pkg = string.match (arg, "(.*)/(.*)");
      if rep == nil then
	 rep = "*"
	 pkg = arg
      end
      
      rep = "^" .. string.gsub (rep, "([+*-])", tr) .. "$"
      pkg = "^" .. string.gsub (pkg, "([+*-])", tr) .. "$"
      
      --optimization, to skip the package traversal early
      local pkg_match = false
      if string.find (pkg, "*") == nil then
	 pkg_match = true
      end
      
      --print ("regex> rep: " .. rep .. ", pkg: '" .. pkg .. "'")
      
      for j,p in ipairs(packages) do
	 -- match
	 --[[
	 if (pkg == "linux-header") then
	    print ("pkg> p.rep: " .. p.repository ..
		   ", p.alias: '" .. p.alias .. "'")
	    local s1 = string.match(p.alias, pkg)
	    local s2 = string.match(p.repository, rep)
	    if s1 == nil then s1 = "nil" end
	    if s2 == nil then s2 = "nil" end
	    print ("match pkg: " .. s1)
	    print ("match rep: " .. s2)
	 end
         ]]--
	 if (string.match(p.alias, pkg) and
	     string.match(p.repository, rep)) then
	    -- if not already disabled completely
	    --print ("matched rep: " .. rep .. ", pkg: " .. pkg)
	    --print ("with    rep: " .. p.repository ..", pkg: " .. p.alias)
	    if p.status ~= "-" then
	       --print ("set to: " .. mode)
	       if mode == "=" then
		  p.status = p.default_status
	       else
		  p.status = mode
	       end
	    end
	    -- just optimization
	    if pkg_match then
	       break
	    end
	 end
      end
   end
   -- return error if no match was found?
end

function pkgenable (pkg)
   pkgswitch ("X", pkg)
end

function pkgdisable (pkg)
   pkgswitch ("O", pkg)
end

function pkgremove (pkg)
   pkgswitch ("-", pkg)
end

function pkgcheck (pattern, mode)
   -- split the pattern seperated by "|"
   p = {}
   for x in string.gmatch(pattern, "[^|]+") do
      p[#p+1] = x
   end
   
   for i,pkg in ipairs(packages) do
      for j,x in ipairs (p) do
	 if pkg.alias == x then
	    if mode == "X" then
	       if pkg.status == "X" then return true end
	    elseif mode == "O" then
	       if pkg.status == "O" then return true end
	    elseif mode == "." then
	       return 0
	    else
	       print ("Syntax error near pkgcheck: "..pattern.." "..mode)
	    end
	 end
      end
   end
   return false
end

--

-- Parse pkg selection rules
--
-- Example:
--   X python     - selects just the python package
--   O perl/*     - deselects all perl repository packages
--   = glibc      - sets package glibc to it's default state
--   include file - recursively parse file specified
--

function pkgsel_parse (filename)
   local f = io.open (filename, "r")
   if f == nil then
      print ("Error opening file: '" .. filename .."'")
      return
   end
   
   for line in f:lines() do
      line = string.gsub (line, "#.*","")
      
      local action
      local pattern
      action, pattern = string.match (line, "(%S+) +(%S+)")
      
      if action == "x" or action == "X" then
	 pkgswitch ("X", pattern)
      elseif action == "o" or action == "O" then
	 pkgswitch ("O", pattern)
      elseif action == "-" then
	 pkgswitch ("-", pattern)
      elseif action == "=" then
	 pkgswitch ("=", pattern)
      elseif action == "include" then
	 pkgsel_parse (pattern)
      else
	 if not line == "" then
	    print ("unparsed: "..line)
	 end
      end
   end
   f:close()
end

--

print "LUA accelerator (C) 2006 by Valentin Ziegler & Rene Rebe, ExactCODE"

-- register shortcuts for the functions above
bash.register("pkglistread")
bash.register("pkglistwrite")
bash.register("pkgcheck")
bash.register("pkgremove")
bash.register("pkgenable")
bash.register("pkgdisable")
bash.register("pkgsel_parse")
