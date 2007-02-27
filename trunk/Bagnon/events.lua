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
	BankFrameTitleText:SetText(UnitName('npc'))
	SetPortraitTexture(BankPortraitTexture, 'npc')
	ShowUIPanel(BankFrame)

	if not BankFrame:IsVisible() then
		CloseBankFrame()
	end
	UpdateBagSlotStatus()
end

--[[ 
	The Events 
--]]

BVent:AddAction('PLAYER_LOGIN', function() 
	playerSets = BagnonLib.GetSets()
	
	BankFrame:UnregisterEvent("BANKFRAME_OPENED")
	HideUIPanel(BankFrame)
end)


--[[ Bank ]]--

BVent:AddAction('BANKFRAME_OPENED', function()
	if playerSets.showBagsAtBank then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtBank then
		Bagnon_ShowBank(true)
	else
		ShowBlizBank()
	end
end)

BVent:AddAction('BANKFRAME_CLOSED', function()
	if playerSets.showBagsAtBank then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtBank then
		Bagnon_HideBank(true)
	end
end)


--[[ Trade Window ]]--

BVent:AddAction('TRADE_SHOW', function()
	if playerSets.showBagsAtTrade then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtTrade then
		Bagnon_ShowBank(true)
	end
end)

BVent:AddAction('TRADE_CLOSED', function()
	if playerSets.showBagsAtTrade then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtTrade then
		Bagnon_HideBank(true)
	end
end)


--[[ Tradeskill Window ]]--

BVent:AddAction('TRADE_SKILL_SHOW', function()
	if playerSets.showBagsAtCraft then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtCraft then
		Bagnon_ShowBank(true)
	end
end)

BVent:AddAction('TRADE_SKILL_CLOSE', function()
	if playerSets.showBagsAtCraft then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtCraft then
		Bagnon_HideBank(true)
	end
end)


--[[ Auction House ]]--

BVent:AddAction('AUCTION_HOUSE_SHOW', function()
	if playerSets.showBagsAtAH then
		Bagnon_ShowInventory(true)
	end

	if playerSets.showBankAtAH then
		Bagnon_ShowBank(true)
	end
end)

BVent:AddAction('AUCTION_HOUSE_CLOSED', function()
	if playerSets.showBagsAtAH then
		Bagnon_HideInventory(true)
	end

	if playerSets.showBankAtAH then
		Bagnon_HideBank(true)
	end
end)


--[[ Mail ]]--

BVent:AddAction('MAIL_SHOW', function()
	if playerSets.showBagsAtMail then
		Bagnon_ShowInventory(true)
	end
	
	if playerSets.showBankAtMail then
		Bagnon_ShowBank(true)
	end
end)

BVent:AddAction('MAIL_CLOSED', function()
	if playerSets.showBagsAtMail then
		Bagnon_HideInventory(true)
	end
	
	if playerSets.showBankAtMail then
		Bagnon_HideBank(true)
	end
end)


--[[ Merchant ]]--

BVent:AddAction('MERCHANT_SHOW', function()
	if playerSets.showBagsAtVendor then
		Bagnon_ShowInventory(true)
	end
	
	if playerSets.showBankAtVendor then
		Bagnon_ShowBank(true)
	end
end)

BVent:AddAction('MERCHANT_CLOSED', function()
	if playerSets.showBagsAtVendor then
		Bagnon_HideInventory(true)
	end
	
	if playerSets.showBankAtVendor then
		Bagnon_HideBank(true)
	end
end)