--[[
	vBagnon\bankFrame.lua
		A bank frame.  Contains a display for the player's bank, 
		all of the player's bags in his or her bank, and also allows the purchase of more 
		bag slots
--]]

local BANK_BAGS = {-1, 5, 6, 7, 8, 9, 10, 11}

local function CreateBank()
	local settings = Bagnon_GetPlayerSets()

	Banknon = BagnonFrame.CreateSaved(format(BAGNON_BANK_TITLE, UnitName('player')), settings.bank, BANK_BAGS, true)
	table.insert(UISpecialFrames, Banknon:GetName())

	local OnShow = Banknon:GetScript('OnShow')
	Banknon:SetScript('OnShow', function()
		PlaySound("igMainMenuOpen")
		OnShow()
	end)

	local OnHide = Banknon:GetScript('OnHide')
	Banknon:SetScript('OnHide', function()
		PlaySound("igMainMenuClose")

		if Bagnon_PlayerAtBank() then 
			CloseBankFrame() 
		end
		OnHide()
	end)
	
	if not Banknon:IsUserPlaced() then
		Banknon:SetPoint('LEFT', UIParent, 'LEFT', 24, 100)
	end
end

--[[ Visibility Functions ]]--

function Bagnon_ShowBank(auto)
	if Banknon then
		if not Banknon:IsVisible() then
			Banknon:Show()
			Banknon.manOpened = not auto
		else
			Banknon:UpdateAllSlots()
		end
	else
		CreateBank()
		Banknon.manOpened = not auto
	end
	return true
end

function Bagnon_HideBank(auto)
	if Banknon and not(auto and Banknon.manOpened) then
		Banknon:Hide()
	end
	return true
end

function Bagnon_ToggleBank(auto)
	if BagnonDB or Bagnon_PlayerAtBank() then
		if Banknon and Banknon:IsVisible() then
			return Bagnon_HideBank(auto)
		else
			return Bagnon_ShowBank(auto)
		end
	end
end