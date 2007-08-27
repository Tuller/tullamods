--[[
	SellFish/db.lua -
		Based on SellValueLite and ColaLight, allows viewing of sell values from anywhere
		This portion provides sell value data access

	Copyright (C) 2007 Tuller
	ColaLight (C) 2006  Murazorz
	ItemPrice (C) 2007 Bam

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
	02110-1301, USA.
--]]

local CURRENT_VERSION = GetAddOnMetadata("SellFish", "Version")
local L = SELLFISH_LOCALS

local tonumber, tostring, floor, format = tonumber, tostring, math.floor, string.format
local GetItemInfo = GetItemInfo

--[[ Local Functions ]]--

--prints a message, optionally with addon text
local function msg(message, showAddon)
	if showAddon then
		ChatFrame1:AddMessage(format("|cFF33FF99SellFish|r: %s", tostring(message)))
	else
		ChatFrame1:AddMessage(tostring(message))
	end
end

--converts a base 10 integer into base<base>
local base36 = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
local maxBase = 10 + #base36

local function ToBase(num, base)
	local newNum = ""
	while num > 0 do
		local remain = num % base
		num = floor(num / base)
		if remain > 9 then
			newNum = base36[remain-9] .. newNum
		else
			newNum = remain .. newNum
		end
	end
	return newNum
end

--returns the numeric code of an item link
local function ToID(link)
	if link then
		return tonumber(link) or tonumber(link:match("item:(%d+)") or tonumber(select(2, GetItemInfo(link)):match("item:(%d+)")))
	end
end

--gets a value from the
local cache = setmetatable({}, {__index = function(t, i)
	local c = SellFishDB.newVals[i] or (SellFishDB.data:match(";" .. i .. ",(%w+);")) or 0
	t[i] = c
	return c
end})


--[[ Startup/Shutdown ]]--

SellFish = {}

function SellFish:Load()
	local tip = CreateFrame("GameTooltip", "SellFishTooltip", UIParent, "GameTooltipTemplate")
	tip:SetScript("OnTooltipAddMoney", function(tip, cost)
		if not InRepairMode() then
			tip.lastCost = cost
		end
	end)

	tip:SetScript("OnEvent", function()
		if event == "MERCHANT_SHOW" then
			self:ScanPrices()
		elseif event == "ADDON_LOADED" then
			if(arg1 == "SellFish") then
				this:UnregisterEvent("ADDON_LOADED")
				self:Initialize()
			end
		elseif event == "PLAYER_LOGOUT" then
			self:ClearDefaults()
		end
	end)
	tip:RegisterEvent("MERCHANT_SHOW")
	tip:RegisterEvent("ADDON_LOADED")
	tip:RegisterEvent("PLAYER_LOGOUT")
	self.tip = tip

	self:LoadSlashCommands()
end

function SellFish:Initialize()
	if not(SellFishDB and SellFishDB.version) then
		SellFish:LoadDefaults()
	else
		local version = SellFishDB.version
		if(version ~= CURRENT_VERSION) then
			local cMajor = CURRENT_VERSION:match("(%w+)%.")
			local major = version:match("(%w+)%.")

			--a major version change, reset the database
			if major ~= cMajor then
				self:LoadDefaults()
			else
				self:UpdateVersion()
			end
		end
	end
end

function SellFish:LoadDefaults()
	SellFishDB = {
		style = 3,
		newVals = {},
		data = SellFish_GetDefaultData(),
		version = CURRENT_VERSION
	}
end

function SellFish:UpdateVersion()
	SellFishDB.version = CURRENT_VERSION
	msg(format(L.Updated, SellFishDB.version), true)
end


--[[ Item Price Scanning ]]--

function SellFish:ScanPrices()
	local tip = self.tip

	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local cost = self:GetItemValue(bag, slot)
				if cost then
					local count = (select(2, GetContainerItemInfo(bag, slot)))
					self:SaveCost(ToID(link), cost/count)
				end
			end
		end
	end
end

function SellFish:GetItemValue(bag, slot)
	self.tip.lastCost = nil

	local repairCost = (select(2, self.tip:SetBagItem(bag, slot)))
	if not(repairCost) or repairCost == 0 then
		return self.tip.lastCost or 0
	end
end

--save the price, only if its not the same as in the main database
function SellFish:SaveCost(id, cost)
	local id = ToBase(id, maxBase)
	local cost = ToBase(cost, maxBase)

	if cost ~= cache[id] then
		SellFishDB.newVals[id] = cost
	end
end

--get the price by checking newVals, then the main database
function SellFish:GetCost(id, count)
	local id = ToBase(id, maxBase)
	local cost = cache[id]

	if cost and cost ~= "" then
		return tonumber(cost, maxBase) * (count or 1)
	end
end

-- Takes all the values in the list newVals, and replaces/adds entries in the big sellfish string
function SellFish:CompressDB(newVals)
	local appendString = ""
	for id, cost in pairs(newVals) do
		if cost == "" then cost = "0" end

		local prevCost = cache[id]
		if prevCost then
			if(cost ~= prevCost) then
				SellFishDB.data:gsub(format(";%s,%s;", id, prevCost), (cost == 0 and "") or format(";%s,%s;", id, cost))
			end
		elseif cost ~= "0" then
			appendString = (appendString or "") .. format(";%s,%s", id, cost)
		end
		SellFishDB.newVals[id] = nil
	end

	if appendString ~= "" then
		SellFishDB.data = (SellFishDB.data or "") .. appendString
	end
end


--[[ Usable Functions ]]--

-- cost = GetSellValue(itemID | "name" | "link")
local oGetSellValue = GetSellValue
function GetSellValue(link)
	assert(link, 'Usage: GetSellValue(itemID|"name"|"itemLink")')

	local id = tonumber(link)
	if id then
		return SellFish:GetCost(id)
	else
		local link = select(2, GetItemInfo(link))
		if link then
			return SellFish:GetCost(ToID(link))
		end
	end

	if oGetSellValue then
		return oGetSellValue(link)
	end
end

function SellFish:GetNumValues()
	local count = 0
	for word in SellFishDB.data:gmatch("%w+,%w+;") do
		count = count + 1
	end
	return count
end


--[[ Slash Commands ]]--

function SellFish:LoadSlashCommands()
	SlashCmdList["SellFishCOMMAND"] = function(cmd)
		if cmd == "" then
			self:ShowCommands()
		else
			cmd = cmd:lower()
			if cmd == "help" or cmd == "?" then
				self:ShowCommands()
			elseif cmd == "reset" then
				self:LoadDefaults()
			elseif cmd == "style" then
				self:ToggleStyle()
			elseif cmd == "compress" then
				self:CompressDB(self.sets.newVals)
			else
				msg(format(L.UnknownCommand, cmd), true)
			end
		end
	end

	SLASH_SellFishCOMMAND1 = "/sellfish"
	if(GetLocale() ~= "deDE") then
		SLASH_SellFishCOMMAND2 = "/sf"
	end
end

function SellFish:ShowCommands()
	local cmdStr = " - |cffffd700%s|r: %s"

	msg(L.CommandsHeader)
	msg(format(cmdStr, "?", L.HelpDesc))
	msg(format(cmdStr, "style", L.StyleDesc))
	msg(format(cmdStr, "compress", L.CompressDesc))
	msg(format(cmdStr, "reset", L.ResetDesc))
end

function SellFish:ToggleStyle()
	local style = SellFishDB.style or 1
	if(style == 1) then
		SellFishDB.style  = 2
		msg(format(L.SetStyle, "Compact"), true)
	elseif(style == 2) then
		SellFishDB.style  = 3
		msg(format(L.SetStyle, "Short"), true)
	elseif(style == 3) then
		SellFishDB.style = 1
		msg(format(L.SetStyle, "Blizzard"), true)
	end
end

--Load the thing
SellFish:Load()