--[[
	vBagnon\hooks.lua
		Hooks for automatically opening/closing bank and inventory frames
--]]

--[[ Local Functions ]]--

local function HasBag(id, type)
	for _, bag in Bagnon_GetShownBags(type) do
		if bag == id then
			return true
		end
	end
	return nil
end

local function FrameOpened(id, auto)
	local sets = Bagnon_GetPlayerSets()
	
	if Bagnon_IsInventoryBag(id) then
		return sets.replaceBags and Bagnon_ShowInventory(auto)
	end
	return sets.replaceBank and Bagnon_ShowBank(auto)
end

local function FrameClosed(id, auto)
	local sets = Bagnon_GetPlayerSets()
	
	if Bagnon_IsInventoryBag(id) then
		return sets.replaceBags and Bagnon_HideInventory(auto)
	end
	return sets.replaceBank and Bagnon_HideBank(auto)
end

local function FrameToggled(id, auto)
	local sets = Bagnon_GetPlayerSets()
	
	if Bagnon_IsInventoryBag(id) then
		return sets.replaceBags and Bagnon_ToggleInventory(auto)
	end
	return sets.replaceBank and Bagnon_ToggleBank(auto)
end

--[[ The Hooks ]]--

local bOpenBag = OpenBag
OpenBag = function(id)
	if not FrameOpened(id, true) then
		bOpenBag(id)
	end
end

local bCloseBag = CloseBag
CloseBag = function(id)
	if not FrameClosed(id, true) then
		bCloseBag(id)
	end
end

local bToggleBag = ToggleBag
ToggleBag = function(id)
	if not FrameToggled(id) then
		bToggleBag(id)
	end
end

local bOpenAllBags = OpenAllBags
OpenAllBags = function(forceOpen)
	if not( (forceOpen and FrameOpened(0)) or FrameToggled(0) ) then
		bOpenAllBags(forceOpen)
	end
end

local bCloseAllBags = CloseAllBags
CloseAllBags = function()
	if not FrameClosed(0) then
		bCloseAllBags()
	end
end

local bOpenBackpack = OpenBackpack
OpenBackpack = function()
	if not FrameOpened(0, true) then
		bOpenBackpack()
	end
end

local bCloseBackpack = CloseBackpack
CloseBackpack = function()
	if not FrameClosed(0, true) then
		bCloseBackpack()
	end
end

local bToggleBackpack = ToggleBackpack
ToggleBackpack = function()
	if not FrameToggled(0) then
		bToggleBackpack()
	end
end

local bToggleKeyring = ToggleKeyRing
ToggleKeyRing = function()
	if not FrameToggled(-2) then
		bToggleKeyring()
	end
end