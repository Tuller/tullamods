--[[
	vBagnon\hooks.lua
		Hooks for automatically opening/closing bank and inventory frames
--]]

local function FrameOpened(id, auto)
	local sets = BagnonLib.GetSets()
	
	return (sets.replaceBags and Bagnon_HasBag(id) and Bagnon_ShowInventory(auto)) or
	   (Banknon_HasBag(id) and Bagnon_ShowBank(auto))
end

local function FrameClosed(id, auto)
	local sets = BagnonLib.GetSets()
	
	return (sets.replaceBags and Bagnon_HasBag(id) and Bagnon_HideInventory(auto)) or
		   (Banknon_HasBag(id) and Bagnon_HideBank(auto))
end

local function FrameToggled(id, auto)
	local sets = BagnonLib.GetSets()

	return (sets.replaceBags and Bagnon_HasBag(id) and Bagnon_ToggleInventory(auto)) or
	   (Banknon_HasBag(id) and Bagnon_ToggleBank(auto))
end


--[[ The Hooks ]]--

local oOpenBackpack = OpenBackpack
OpenBackpack = function()
	if not BagnonLib.GetSets().replaceBags then
		oOpenBackpack()
	end
end

local oToggleBag = ToggleBag
ToggleBag = function(id)
	if IsOptionFrameOpen() then return end
	
	if not FrameToggled(id) then
		oToggleBag(id)
	end
end

local oOpenAllBags = OpenAllBags
OpenAllBags = function(force)
	if BagnonLib.GetSets().replaceBags then
		if force then
			Bagnon_ShowInventory()
		else
			Bagnon_ToggleInventory()
		end
	else
		oOpenAllBags(force)
	end
end

local bCloseAllBags = CloseAllBags
CloseAllBags = function()
	if BagnonLib.GetSets().replaceBags then
		Bagnon_HideInventory()
	else
		bCloseAllBags()
	end
end