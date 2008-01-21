--[[
	vBagnon\inventoryFrame.lua
		An inventory frame.  An inventory contains a display for the player's money,
		a listing of all the player's inventory bags, plus the main bag and key ring,
		and should open automatically under the conditions the main bag would open under
--]]

local INVENTORY_BAGS = {0, 1, 2, 3, 4, -2}

local function CreateInventory()
	local settings = Bagnon_GetPlayerSets()
	
	Bagnon = BagnonFrame.CreateSaved(format(BAGNON_INVENTORY_TITLE, UnitName('player')), settings.inventory, INVENTORY_BAGS)
	table.insert(UISpecialFrames, Bagnon:GetName())
	
	local OnShow = Bagnon:GetScript('OnShow')
	Bagnon:SetScript('OnShow', function()
		PlaySound("igBackPackOpen")
		OnShow()
	end)

	local OnHide = Bagnon:GetScript('OnHide')
	Bagnon:SetScript('OnHide', function()
		PlaySound("igBackPackClose")
		OnHide()
	end)
	
	if not Bagnon:IsUserPlaced() then
		Bagnon:SetPoint('RIGHT', UIParent)
	end
end

--[[ Visibility Functions ]]--

function Bagnon_ShowInventory(auto)
	if Bagnon then
		if not Bagnon:IsVisible() then
			Bagnon:Show()
			Bagnon.manOpened = not auto
		end
	else
		CreateInventory()
		Bagnon.manOpened = not auto
	end
	return true
end

function Bagnon_HideInventory(auto)
	if Bagnon and not(auto and Bagnon.manOpened) then
		Bagnon:Hide()
	end
	return true
end

function Bagnon_ToggleInventory(auto)
	if Bagnon and Bagnon:IsVisible() then
		return Bagnon_HideInventory(auto)
	else
		return Bagnon_ShowInventory(auto)
	end
end