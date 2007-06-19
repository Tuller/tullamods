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
local base36 = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
local maxBase = 10 + #base36

local tonumber, tostring, mod, floor = tonumber, tostring, mod, floor
local GetItemInfo = GetItemInfo

--[[ Local Functions ]]--

local function msg(message, showAddon)
	if showAddon then
		ChatFrame1:AddMessage(format("|cFF33FF99SellFish|r: %s", tostring(message)))
	else
		ChatFrame1:AddMessage(tostring(message))
	end
end

--converts a base 10 integer into base<base>
local function ToBase(num, base)
	local newNum = ""
	while num > 0 do
		local remain = mod(num, base)
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

local cache = setmetatable({}, {__index = function(t, i)
	if SellFishDB and SellFishDB.data then
		local c = (SellFishDB.data:match(";" .. i .. ",(%w+);")) or 0
		t[i] = c
		return c
	end
end})


--[[ Startup/Shutdown ]]--

SellFish = {}
SellFish.defaults = {style = 3, version = CURRENT_VERSION, newVals = {}, data = SellFish_GetDefaults()}

function SellFish:Load()
	local tip = CreateFrame("GameTooltip", "SellFishTooltip", UIParent, "GameTooltipTemplate")
	tip:SetScript("OnTooltipAddMoney", function()
		if not InRepairMode() then
			tip.lastCost = arg1
		end
	end)

	tip:SetScript("OnEvent", function()
		if event == "MERCHANT_SHOW" then
			self:ScanPrices()
		elseif event == "ADDON_LOADED" and arg1 == "SellFish" then
			this:UnregisterEvent("ADDON_LOADED")
			self:Initialize()
		end
	end)
	tip:RegisterEvent("MERCHANT_SHOW")
	tip:RegisterEvent("ADDON_LOADED")

	self.tip = tip

	self:LoadSlashCommands()
end

function SellFish:Initialize()
	SellFishDB = setmetatable(SellFishDB or {}, {__index = self.defaults})

	if(SellFishDB.version ~= CURRENT_VERSION) then
		local cMajor, cMinor = CURRENT_VERSION:match("(%d+)%.(%d+)")
		local major, minor = SellFishDB.version:match("(%d+)%.(%d+)")
		if major ~= cMajor then
			self:LoadDefaults()
		elseif minor ~= cMinor then
			self:UpdateVersion()
		end
	end

	if(not SellFishDB.data) then
		self:LoadSellValues()
	end
end

function SellFish:LoadDefaults()
	SellFishDB = {}
	self:LoadSellValues(true)
end

function SellFish:UpdateVersion()
	if(SellFishDB.short) then
		SellFishDB.short = nil
		SellFishDB.style = 2
	end
	self:LoadSellValues(true)

	SellFishDB.version = CURRENT_VERSION
	msg(format(L.Updated, SellFishDB.version), true)
end


--[[ Data Stuff ]]--

function SellFish:ScanPrices()
	local tip = self.tip

	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			local repairCost = select(2, tip:SetBagItem(bag, slot))
			if(not(repairCost) or repairCost == 0) then
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
end

function SellFish:GetItemValue(bag, slot)
	self.tip.lastCost = nil
	self.tip:SetBagItem(bag, slot)

	return self.tip.lastCost
end

function SellFish:SaveCost(id, cost)
	local id = ToBase(id, maxBase)
	local cost = ToBase(cost, maxBase)

	if cost ~= cache[id] then
		SellFishDB.newVals[id] = cost
	end
end

function SellFish:GetCost(id, count)
	local id = ToBase(id, maxBase)
	local cost = SellFishDB.newVals[id] or cache[id]

	if cost and cost ~= "" then
		return tonumber(cost, maxBase) * (count or 1)
	end
end

function SellFish:CompressDB()
	local appendString = ""
	for id, cost in pairs(SellFishDB.newVals) do
		if cost == "" then cost = "0" end

		local prevCost = cache[id]
		if prevCost then
			if(cost ~= prevCost) then
				if cost == "0" then
					SellFishDB.data:gsub(format(";%s,%s;", id, prevCost), "");
				else
					SellFishDB.data:gsub(format(";%s,%s;", id, prevCost), format(";%s,%s;", id, cost))
				end
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


--[[ Converters ]]--

function SellFish:LoadSellValues(reset)
	if reset or SellFish_GetDefaults then
		SellFishDB.data = nil
	end

	local changed = false
	if CompletePrices then
		changed = changed or self:ConvertPriceMaster(CompletePrices)
	end
	if ColaLight and ColaLight.db.account.SellValues then
		changed = changed or self:ConvertColaLight(ColaLight.db.account.SellValues)
	end
	if self.ConvertItemPrice then
		changed = changed or self:ConvertItemPrice()
	end
	if(changed) then self:CompressDB() end

	msg(format(L.Loaded, self:GetNumValues()), true)
end

-- function SellFish:ConvertItemPrice()
	-- local prices = ""

	-- local byte = string.byte
	-- function get(id)
		-- if id and id <= 33052 and id > 0 then
			-- local index = id * 3
			-- local a, b, c = byte(prices, index - 2, index)
			-- if b == 0 then
				-- if c == 0 then
					-- if a == 0 then return else return a * 65536 end
				-- else
					-- return a * 65536 + c
				-- end
			-- else
				-- return a * 65536 + b * 256 + c
			-- end
		-- end
	-- end

	-- local newVals = SellFishDB.newVals
	-- for i = 1, 33052 do
		-- local price = get(i)
		-- if(price) then
			-- newVals[ToBase(i, maxBase)] = ToBase(price, maxBase)
			-- changed = true
		-- end
	-- end

	-- return changed
-- end

--adds all of cola light"s sellvalue data to the list of new values, then compresses if new data has been added
function SellFish:ConvertColaLight(t)
	local changed = false
	for id, cost in pairs(t) do
		local cost = ToBase(tonumber(cost), maxBase)
		local id = ToBase(tonumber(id), maxBase)
		if SellFishDB.newVals[id] ~= cost then
			changed = true
		end
		SellFishDB.newVals[id] = cost
	end
	return changed
end

function SellFish:ConvertPriceMaster(t)
	local changed = false
	for id, data in pairs(t) do
		local price = data.p
		if price then
			local cost = ToBase(tonumber(price), maxBase)
			local id = ToBase(tonumber(id), maxBase)
			if SellFishDB.newVals[id] ~= cost then
				changed = true
			end
			SellFishDB.newVals[id] = cost
		end
	end

	return changed
end


--[[ Usable Functions ]]--

-- cost = GetSellValue(itemID | "name" | "link" [, count])
local oGetSellValue = GetSellValue
function GetSellValue(link)
	assert(link, "Usage: GetSellValue(itemID|\"name\"|\"itemLink\")")

	local id = tonumber(link)
	if id then
		return SellFish:GetCost(id)
	else
		local link = select(2, GetItemInfo(link))
		if link then
			return SellFish:GetCost(ToID(link))
		end
	end

	return oGetSellValue and oGetSellValue(link)
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
				self:CompressDB()
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