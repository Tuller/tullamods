--[[
	vBagnon\hooks.lua
		Hooks for automatically opening/closing bank and inventory frames
--]]

--[[ Local Functions ]]--

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

local oToggleBag = ToggleBag
ToggleBag = function(id)
	if IsOptionFrameOpen() then return end
	
	if not FrameToggled(id) then
		oToggleBag(id)
	end
end

local oToggleBackpack = ToggleBackpack
oToggleBackpack = function()
	if IsOptionFrameOpen() then return end
	
	if not FrameToggled(0) then
		oToggleBackpack()
	end
end

local oOpenBag = OpenBag
OpenBag = function(id)
	if not CanOpenPanels() then
		if UnitIsDead('player') then
			NotWhileDeadError()
		end
		return
	end
	
	if not FrameOpened(id, true) then
		oOpenBag(id)
	end
end

local oCloseBag = CloseBag
CloseBag = function(id)
	if not FrameClosed(id, true) then
		oCloseBag(id)
	end
end

local oOpenBackpack = OpenBackpack
OpenBackpack = function()
	if not CanOpenPanels() then
		if UnitIsDead("player") then
			NotWhileDeadError()
		end
		return
	end

	if not FrameOpened(0, true) then
		oOpenBackpack()
	end
end

local oCloseBackpack = CloseBackpack
CloseBackpack = function()
	if not FrameClosed(0, true) then
		oCloseBackpack()
	end
end

local oToggleKeyRing = ToggleKeyRing
ToggleKeyRing = function()
	if IsOptionFrameOpen() then return end
	
	if not FrameToggled(KEYRING_CONTAINER) then
		oToggleKeyRing()
	end
end

local oOpenAllBags = OpenAllBags
OpenAllBags = function(forceOpen)
	if BagnonLib.GetSets().replaceBags then
		if forceOpen then
			Bagnon_ShowInventory()
		else
			Bagnon_ToggleInventory()
		end
	else
		oOpenAllBags(forceOpen)
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