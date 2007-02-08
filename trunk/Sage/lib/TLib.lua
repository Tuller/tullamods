--[[
	TLib
		Lua functions I use for one reason or another
--]]

local VERSION = '6.12.23'


--[[ Functions TLib needs to load ]]--

--converts a version string into a number.  Yes, I'm lazy
local function VToN(versionString)
	if tonumber(versionString) then
		return tonumber(versionString)
	end

	local major, minor, point = versionString:match("(%d+)%.(%d+)%.(%d+)")
	major = tonumber(major); minor = tonumber(minor); point = tonumber(point)
	if major and minor and point then
		return major * 10000 + minor * 100 + point
	end
end

local function IsCurrent(lib, version)
	return lib and lib.version and VToN(lib.version) >= VToN(version)
end

if IsCurrent(TLib, VERSION) then return end

if not TLib then 
	TLib = {} 
end
TLib.version = version


--[[ Library Functions ]]--

TLib.VToN = VToN
TLib.IsCurrent = IsCurrent
TLib.OlderIsBetter = IsCurrent

function TLib.NeedToInit(lib, version)
	return not(lib and lib.version) or VToN(lib.version) > VToN(version)
end

function TLib.NeedToUpdate(lib, version)
	return lib and lib.version and VToN(lib.version) < VToN(version)
end

--[[ Table Functions ]]--

--Adapted from http://www.lua.org/pil/14.1.html,
--sets a specific global variable string to the given value, with table.table.table access
function TLib.GetField(f)
	local v = getfenv(0)    -- start with the table of globals
	for w in f:gmatch('[%w_]+') do
		v = v[w]
	end
	return v
end

function TLib.SetField(f, v)
	local t = getfenv(0)			
	for w, d in f:gmatch('([%w_]+)(.?)') do
		if d == "." then
			t[w] = t[w] or {}
			t = t[w]
		else
			t[w] = v
		end
	end
end

--taken from http://lua-users.org/wiki/PitLibTablestuff, performs a deep table copy
function TLib.TCopy(t)
	if t then
		local copy = {}
		for i, v in pairs(t) do
			if type(v) == 'table' then
				copy[i] = TLib.TCopy(v)
			else
				copy[i] = v
			end
		end
		return copy
	end
end