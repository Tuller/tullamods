--[[
	vBagnon\events.lua
		Controls the automatic opening of the inventory and bank windows
--]]

local playerSets

--[[
	Taken from Blizzard's code
	Shows the normal bank frame
--]]

local function ShowBlizBank()
	BankFrameTitleText:SetText(UnitName("npc"))
	SetPortraitTexture(BankPortraitTexture,"npc")
	ShowUIPanel(BankFrame)

	if not BankFrame:IsVisible() then
		CloseBankFrame()
	end
	UpdateBagSlotStatus()
end

--[[ 
	The Events 
--]]

BEvent:AddAction('PLAYER_LOGIN', function() 
	playerSets = Bagnon_GetPlayerSets()
	
	BankFrame:UnregisterEvent("BANKFRAME_OPENED")
	HideUIPanel(BankFrame)
end)

--[[ Bank ]]--

BEvent:AddAction('BANKFRAME_OPENED', function()
	if playerSets.showBagsAtBank then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtBank then
		Bagnon_ShowBank(true)
	else
		ShowBlizBank()
	end
end)

BEvent:AddAction('BANKFRAME_CLOSED', function()
	if playerSets.showBagsAtBank then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtBank then
		Bagnon_HideBank(true)
	end
end)

--[[ Trade Window ]]--

BEvent:AddAction('TRADE_SHOW', function()
	if playerSets.showBagsAtTrade then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtTrade then
		Bagnon_ShowBank(true)
	end
end)

BEvent:AddAction('TRADE_CLOSED', function()
	if playerSets.showBagsAtTrade then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtTrade then
		Bagnon_HideBank(true)
	end
end)

--[[ Tradeskill Window ]]--

BEvent:AddAction('TRADE_SKILL_SHOW', function()
	if playerSets.showBagsAtCraft then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtCraft then
		Bagnon_ShowBank(true)
	end
end)

BEvent:AddAction('TRADE_SKILL_CLOSE', function()
	if playerSets.showBagsAtCraft then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtCraft then
		Bagnon_HideBank(true)
	end
end)

--[[ Auction House ]]--

BEvent:AddAction('AUCTION_HOUSE_SHOW', function()
	if playerSets.showBagsAtAH then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtAH then
		Bagnon_ShowBank(true)
	end
end)

BEvent:AddAction('AUCTION_HOUSE_CLOSED', function()
	if playerSets.showBagsAtAH then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtAH then
		Bagnon_HideBank(true)
	end
end)

--[[ Mail ]]--

BEvent:AddAction('MAIL_SHOW', function()
	if playerSets.showBankAtMail then
		Bagnon_ShowBank(true)
	end
end)

BEvent:AddAction('MAIL_CLOSED', function()
	Bagnon_HideInventory(true)

	if playerSets.showBankAtMail then
		Bagnon_HideBank(true)
	end
end)

--[[ Merchant ]]--

BEvent:AddAction('MERCHANT_SHOW', function()
	if playerSets.showBankAtVendor then
		Bagnon_ShowBank(true)
	end
end)

BEvent:AddAction('MERCHANT_CLOSED', function()
	if playerSets.showBankAtVendor then
		Bagnon_HideBank(true)
	end
end)