--[[
	SellFish/db.lua -
		Based on SellValueLite and ColaLight, allows viewing of sell values from anywhere
		This portion provides sell value data access

	Copyright (C) 2008 Tuller
	ColaLight (C) 2006 Murazorz
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

local ItemPrice, IP_REVISION
if LibStub then
	ItemPrice, IP_REVISION = LibStub('ItemPrice-1.1', true)
end

local CURRENT_VERSION = GetAddOnMetadata('SellFish', 'Version')
local L = SELLFISH_LOCALS

local tonumber, tostring, floor, format = tonumber, tostring, math.floor, string.format
local GetItemInfo = GetItemInfo

--[[ Local Functions ]]--

--prints a message, optionally with addon text
local function msg(message, showAddon)
	if showAddon then
		ChatFrame1:AddMessage(format('|cFF33FF99SellFish|r: %s', tostring(message)))
	else
		ChatFrame1:AddMessage(tostring(message))
	end
end

--returns the numeric code of an item link
local function ToID(link)
	if link then
		return tonumber(link) or tonumber(link:match('item:(%d+)') or tonumber(select(2, GetItemInfo(link)):match('item:(%d+)')))
	end
end

--[[ Startup/Shutdown ]]--

local SellFish = {}

function SellFish:Load()
	local tip = CreateFrame('GameTooltip', 'SellFishTooltip', UIParent, 'GameTooltipTemplate')
	tip:SetScript('OnTooltipAddMoney', function(self, cost) self.lastCost = cost end)

	tip:SetScript('OnEvent', function(self, event, arg1)
		if event == 'MERCHANT_SHOW' then
			SellFish:ScanPrices()
		elseif event == 'ADDON_LOADED' then
			if(arg1 == 'SellFish') then
				self:UnregisterEvent('ADDON_LOADED')
				SellFish:Initialize()
			end
		end
	end)
	tip:RegisterEvent('MERCHANT_SHOW')
	tip:RegisterEvent('ADDON_LOADED')
	self.tip = tip

	self:LoadSlashCommands()
end

function SellFish:Initialize()
	if not(SellFishDB and SellFishDB.version) then
		self:LoadDefaults()
	else
		local cMajor, cMinor = CURRENT_VERSION:match("(%d+)%.(%d+)")
		local major, minor = SellFishDB.version:match("(%d+)%.(%d+)")

		if major ~= cMajor then
			self:LoadDefaults()
		elseif minor ~= cMinor then
			self:UpdateSettings()
		end

		if SellFishDB.version ~= CURRENT_VERSION then
			self:UpdateVersion()
		end
	end

	if SellFishDB.ipRevision ~= IP_REVISION then
		self:UpdateDatabase()
	end

	self.db = SellFishDB
end

function SellFish:LoadDefaults()
	SellFishDB = {
		style = 3,
		newVals = {},
		ipRevision = IP_REVISION,
		version = CURRENT_VERSION,
	}
end

function SellFish:UpdateSettings()
	--update settings
end

function SellFish:UpdateVersion()
	SellFishDB.version = CURRENT_VERSION
	msg(format(L.Updated, SellFishDB.version), true)
end

function SellFish:UpdateDatabase()
	SellFishDB.newVals = {}
	SellFishDB.ipRevision = IP_REVISION
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
	if (repairCost or 0) == 0 then
		return self.tip.lastCost or 0
	end
end

--saves the price to newVals if its not the same as the one in the database
function SellFish:SaveCost(id, cost)
	if cost ~= self:GetCost(id) then
		self.db.newVals[id] = cost
	end
end

--get the price by checking newVals, then the main database
function SellFish:GetCost(id, count)
	local ipCost = (ItemPrice and ItemPrice:GetPriceById(id)) or 0
	return (self.db.newVals[id] or ipCost) * (count or 1)
end


--[[ Usable Functions ]]--

-- cost = GetSellValue(itemID | 'name' | 'link')
local oGetSellValue = GetSellValue
function GetSellValue(link)
	assert(link, "Usage: GetSellValue(itemID|'name'|'itemLink')")

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


--[[ Slash Commands ]]--

function SellFish:LoadSlashCommands()
	SlashCmdList['SellFishCOMMAND'] = function(cmd)
		if cmd == '' then
			self:ShowCommands()
		else
			cmd = cmd:lower()
			if cmd == 'help' or cmd == '?' then
				self:ShowCommands()
			elseif cmd == 'reset' then
				self:LoadDefaults()
			elseif cmd == 'style' then
				self:ToggleStyle()
			elseif cmd == 'version' then
				self:PrintVersion()
			else
				msg(format(L.UnknownCommand, cmd), true)
			end
		end
	end

	SLASH_SellFishCOMMAND1 = '/sellfish'
	if GetLocale() ~= 'deDE' then
		SLASH_SellFishCOMMAND2 = '/sf'
	end
end

function SellFish:ShowCommands()
	local cmdStr = ' - |cffffd700%s|r: %s'

	msg(L.CommandsHeader)
	msg(format(cmdStr, '?', L.HelpDesc))
	msg(format(cmdStr, 'style', L.StyleDesc))
	msg(format(cmdStr, 'reset', L.ResetDesc))
end

function SellFish:ToggleStyle()
	local style = self.db.style or 1
	if(style == 1) then
		self.db.style  = 2
		msg(format(L.SetStyle, 'Compact'), true)
	elseif(style == 2) then
		self.db.style  = 3
		msg(format(L.SetStyle, 'Short'), true)
	elseif(style == 3) then
		self.db.style = 1
		msg(format(L.SetStyle, 'Blizzard'), true)
	end
end

function SellFish:PrintVersion()
	msg(self.db.version, true)
end

--Load the thing
SellFish:Load()