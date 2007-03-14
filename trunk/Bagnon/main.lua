--[[
	Bagnon2
		Handles settings management, and bank and inventory viewing
--]]

Bagnon = DongleStub("Dongle-Beta1"):New("Bagnon")
Bagnon.atBank = false


--[[ Startup and settings management ]]--

function Bagnon:Initialize()
	local cVersion = GetAddOnMetadata('Bagnon', 'Version')
	local defaults = {
		inventory = {
			bags = {0, 1, 2, 3, 4},
			bg = {r = 0, g = 0.2, b = 0, a = 0.5},
		},

		bank = {
			bags = {-1, 5, 6, 7, 8, 9, 10, 11},
			bg = {r = 0, g = 0, b = 0.2, a = 0.5},
		},

		replaceBags = 1,
		replaceBank = 1,
		showTooltips = 1,
		showBagsAtMail = 1,
		showBagsAtVendor = 1,
		showBagsAtBank = 1,
		showBagsAtAH = 1,
		showBankAtBank = 1,
		qualityBorders = 1,
		version = cVersion,
	}
	
	if not BagnonSets or not BagnonSets.version then
		BagnonSets = defaults
		self:Print('New user detected, default settings loaded.')
	else
		local cMajor, cMinor = cVersion:match('(%d+)%.(%d+)')
		local major, minor = BagnonSets.version:match('(%d+)%.(%d+)')
		
		if major ~= cMajor then
			self:Print('Upgrading from an incompatible version, defaults loaded.')
			BagnonSets = defaults
		elseif minor ~= cMinor then
			self:UpdateSettings(cVersion)
		end
	end
	self.sets = BagnonSets
end

function Bagnon:UpdateSettings(cVersion)
	BagnonSets.version = cVersion
	self:Print(format('Updated to v%s', cVersion))
end

function Bagnon:Enable()
	BankFrame:UnregisterEvent('BANKFRAME_OPENED')
	
	self:RegisterEvent('BANKFRAME_OPENED')
	self:RegisterEvent('BANKFRAME_CLOSED')
	self:RegisterEvent('TRADE_SHOW')
	self:RegisterEvent('TRADE_CLOSED')
	self:RegisterEvent('TRADE_SKILL_SHOW')
	self:RegisterEvent('TRADE_SKILL_CLOSE')
	self:RegisterEvent('AUCTION_HOUSE_SHOW')
	self:RegisterEvent('AUCTION_HOUSE_CLOSED')
	self:RegisterEvent('MAIL_SHOW')
	self:RegisterEvent('MAIL_CLOSED')
	self:RegisterEvent('MERCHANT_SHOW')
	self:RegisterEvent('MERCHANT_CLOSED')
	
	self:RegisterSlashCommands()
end


--[[ Inventory Frame Display ]]--

local INVENTORY_BAGS = {0, 1, 2, 3, 4, -2}

function Bagnon:CreateInventory()
	local bags = BagnonFrame.New(BAGNON_INVENTORY_TITLE, self.sets.inventory, INVENTORY_BAGS)
	table.insert(UISpecialFrames, bags:GetName())

	local OnShow = bags:GetScript('OnShow')
	bags:SetScript('OnShow', function()
		PlaySound('igBackPackOpen')
		OnShow()
	end)

	local OnHide = bags:GetScript('OnHide')
	bags:SetScript('OnHide', function()
		PlaySound('igBackPackClose')
		OnHide()
	end)

	if not bags:IsUserPlaced() then
		bags:SetPoint('RIGHT', UIParent)
	end
	
	self.bags = bags

	return bags
end

function Bagnon:ShowInventory(auto)
	local bags = self.bags
	if bags then
		if not bags:IsVisible() then
			bags:Show()
			bags.manOpened = not auto
		end
	else
		bags = self:CreateInventory()
		bags.manOpened = not auto
	end
end

function Bagnon:HideInventory(auto)
	local bags = self.bags
	if bags and not(auto and bags.manOpened) then
		bags:Hide()
	end
end

function Bagnon:ToggleInventory(auto)
	local bags = self.bags
	if bags and bags:IsVisible() then
		self:HideInventory(auto)
	else
		self:ShowInventory(auto)
	end
end

function Bagnon:InventoryHasBag(id)
	local bags = self.sets.inventory.bags
	for _, bag in pairs(bags) do
		if bag == id then
			return true
		end
	end
end

function Bagnon:GetInventory()
	return self.bags
end


--[[ Bank Frame Display ]]--

local BANK_BAGS = {-1, 5, 6, 7, 8, 9, 10, 11}

function Bagnon:CreateBank()
	local bank = BagnonFrame.New(BAGNON_BANK_TITLE, self.sets.bank, BANK_BAGS, true)
	table.insert(UISpecialFrames, bank:GetName())

	local OnShow = bank:GetScript('OnShow')
	bank:SetScript('OnShow', function()
		PlaySound('igBagnonMenuOpen')
		OnShow()
	end)

	local OnHide = bank:GetScript('OnHide')
	bank:SetScript('OnHide', function()
		PlaySound('igBagnonMenuClose')

		if self.atBank then
			CloseBankFrame()
		end
		OnHide()
	end)

	if not bank:IsUserPlaced() then
		bank:SetPoint('LEFT', UIParent, 'LEFT', 24, 100)
	end
	
	self.bank = bank

	return bank
end

function Bagnon:ShowBank(auto)
	if BagnonDB or self.atBank then
		local bank = self.bank
		if bank then
			if not bank:IsShown() then
				bank:Show()
				bank.manOpened = not auto
			end
		else
			bank = self:CreateBank()
			bank.manOpened = not auto
		end
	else
		UIErrorFrame:AddMessage("No cached data available, cannot open the bank")
	end
end

function Bagnon:HideBank(auto)
	local bank = self.bank
	if bank and not(auto and bank.manOpened) then
		bank:Hide()
	end
end

function Bagnon:ToggleBank(auto)
	local bank = self.bank
	if bank and bank:IsVisible() then
		return self:HideBank(auto)
	else
		return self:ShowBank(auto)
	end
end

function Bagnon:BankHasBag(id)
	local bags = self.sets.bank.bags
	for _, bag in pairs(bags) do
		if bag == id then
			return true
		end
	end
end

function Bagnon:GetBank()
	return self.bank
end


--[[ 
	Frame Hiding/Showing - bag clicks
		These functions allow bagnon/banknon to be shown by clicking ona bag, or by using a bag's hotkey
--]]

local function FrameOpened(id, auto)
	local sets = self.sets
	
	if sets.replaceBags and Bagnon:InventoryHasBag(id) then
		Bagnon:ShowInventory(auto)
		return true
	end
	
	if sets.replaceBank and Bagnon:BankHasBag(id) then
		Bagnon:ShowBank(auto)
		return true
	end
end

local function FrameClosed(id, auto)
	local sets = self.sets

	if sets.replaceBags and Bagnon:InventoryHasBag(id) then
		Bagnon:HideInventory(auto)
		return true
	end
	
	if sets.replaceBank and Bagnon:BankHasBag(id) then
		Bagnon:HideBank(auto)
		return true
	end
end

local function FrameToggled(id, auto)
	local sets = Bagnon.sets

	if sets.replaceBags and Bagnon:InventoryHasBag(id) then
		Bagnon:ToggleInventory(auto)
		return true
	end
	
	if sets.replaceBank and Bagnon:BankHasBag(id) then
		Bagnon:ToggleBank(auto)
		return true
	end
end

local oOpenBackpack = OpenBackpack
OpenBackpack = function()
	if not Bagnon.sets.replaceBags then
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
	if Bagnon.sets.replaceBags then
		if force then
			Bagnon:ShowInventory()
		else
			Bagnon:ToggleInventory()
		end
	else
		oOpenAllBags(force)
	end
end

local bCloseAllBags = CloseAllBags
CloseAllBags = function()
	if Bagnon.sets.replaceBags then
		Bagnon:HideInventory()
	else
		bCloseAllBags()
	end
end


--[[ 
	Automatic Frame Display 
		These functions control the display of bagnon/banknon when an event happens, like opeing the AH
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

local function ShowAtEvent(event, showBlizBank)
	if Bagnon.sets[format('showBagsAt%s', event)] then
		Bagnon:ShowInventory(true)
	end
	
	if Bagnon.sets[format('showBankAt%s', event)] then
		Bagnon:ShowBank(true)
	elseif showBlizBank then
		ShowBlizBank()
	end
end

local function HideAtEvent(event)
	if Bagnon.sets[format('showBagsAt%s', event)] then
		Bagnon:HideInventory(true)
	end
	
	if Bagnon.sets[format('showBankAt%s', event)] then
		Bagnon:HideBank(true)
	end
end

function Bagnon:BANKFRAME_OPENED()
	self.atBank = true
	ShowAtEvent('Bank', true)
end

function Bagnon:BANKFRAME_CLOSED()
	self.atBank = false
	HideAtEvent('Bank')
end

function Bagnon:TRADE_SHOW()
	ShowAtEvent('Trade')
end

function Bagnon:TRADE_CLOSED()
	HideAtEvent('Trade')
end

function Bagnon:TRADE_SKILL_SHOW()
	ShowAtEvent('Craft')
end

function Bagnon:TRADE_SKILL_CLOSE()
	HideAtEvent('Craft')
end

function Bagnon:AUCTION_HOUSE_SHOW()
	ShowAtEvent('AH')
end

function Bagnon:AUCTION_HOUSE_CLOSED()
	HideAtEvent('AH')
end

function Bagnon:MAIL_SHOW()
	ShowAtEvent('Mail')
end

function Bagnon:MAIL_CLOSED()
	HideAtEvent('Mail')
end

function Bagnon:MERCHANT_SHOW()
	ShowAtEvent('Vendor')
end

function Bagnon:MERCHANT_CLOSED()
	HideAtEvent('Vendor')
end


--[[ 
	Slash Commands
--]]

function Bagnon:RegisterSlashCommands()
	local slash = self:InitializeSlashCommand("Commands", "BAGNON", "bagnon", "bgn")
	slash:RegisterSlashHandler("menu - Shows the options menu", "menu", "ShowMenu")
	slash:RegisterSlashHandler("bags - Toggles the inventory frame", "bags", "ToggleInventory")
	slash:RegisterSlashHandler("bank - Toggles the bank frame", "bank", "ToggleBank")
	self.slash = slash
end

function Bagnon:ShowMenu()
	local enabled = select(4, GetAddOnInfo("Bagnon_Options"))
	if enabled then
		if IsAddOnLoaded("Bagnon_Options") then
			BagnonOptions:Show()
		else
			LoadAddOn("Bagnon_Options")
		end
	else
		self:ShowHelp()
	end	
end