--[[
	Combuctor.lua
		Some sort of crazy visual inventory management system
--]]

Combuctor = LibStub('AceAddon-3.0'):NewAddon('Combuctor', 'AceEvent-3.0', 'AceConsole-3.0')
Combuctor:SetDefaultModuleLibraries('AceEvent-3.0')

local L = COMBUCTOR_LOCALS

function Combuctor:OnEnable()
	CombuctorDB = CombuctorDB or {
		frames = {
			inventory = {
				bags = {-2, 0, 1, 2, 3, 4},
				position = {'RIGHT', nil, 'RIGHT', 0, 0},
				pushable = 1,
				showBags = false,
			},
			bank = {
				bags = {-1, 5, 6, 7, 8, 9, 10, 11},
				pushable = 2,
				showBags = true,
			}
		}
	}

	self.frames = {
		CombuctorFrame:Create(L.InventoryTitle, CombuctorDB.frames.inventory),
		CombuctorFrame:Create(L.BankTitle, CombuctorDB.frames.bank, true)
	}

	self:HookBagEvents()

	self:RegisterChatCommand('combuctor', 'OnSlashCommand')
	self:RegisterChatCommand('cbt', 'OnSlashCommand')
end

function Combuctor:Show(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:ShowBag(bag, auto)
				return
			end
		end
	end
end

function Combuctor:Hide(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:HideBag(bag, auto)
				return
			end
		end
	end
end

function Combuctor:Toggle(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:ToggleBag(bag, auto)
				return
			end
		end
	end
end

function Combuctor:HookBagEvents()
	local backpack = BACKPACK_CONTAINER
	local keyring = KEYRING_CONTAINER
	local bank = BANK_CONTAINER

	OpenBackpack = function()
		Combuctor:Show(backpack, true)
	end

	CloseBackpack = function()
		Combuctor:Hide(backpack, true)
	end

	ToggleBackpack = function()
		Combuctor:Toggle(backpack)
	end

	OpenAllBags = function(force)
		if force then
			Combuctor:Show(backpack)
		else
			Combuctor:Toggle(backpack)
		end
	end

	CloseAllBags = function()
		Combuctor:Hide(backpack)
	end

	ToggleBag = function(bag)
		Combuctor:Toggle(bag)
	end

	ToggleKeyRing = function()
		Combuctor:Toggle(keyring)
	end

	BankFrame:UnregisterAllEvents()
	self:RegisterMessage('COMBUCTOR_BANK_OPENED', function()
		self:Show(bank, true)
		self:Show(backpack, true)
	end)
	self:RegisterMessage('COMBUCTOR_BANK_CLOSED', function()
		self:Hide(bank, true)
		self:Hide(backpack, true)
	end)

	--auto magic display code
	local ShowInventory = function() self:Show(backpack, true) end
	local HideInventory = function() self:Hide(backpack, true) end

	self:RegisterEvent('MAIL_CLOSED', HideInventory)

	self:RegisterEvent('TRADE_SHOW', ShowInventory)
	self:RegisterEvent('TRADE_CLOSED', HideInventory)

	self:RegisterEvent('TRADE_SKILL_SHOW', ShowInventory)
	self:RegisterEvent('TRADE_SKILL_CLOSE', HideInventory)

	self:RegisterEvent('AUCTION_HOUSE_SHOW', ShowInventory)
	self:RegisterEvent('AUCTION_HOUSE_CLOSED', HideInventory)

	self:RegisterEvent('AUCTION_HOUSE_SHOW', ShowInventory)
	self:RegisterEvent('AUCTION_HOUSE_CLOSED', HideInventory)
end

function Combuctor:OnSlashCommand(msg)
	if msg == 'bank' then
		self:Toggle(BANK_CONTAINER)
	elseif msg == 'bags' then
		self:Toggle(BACKPACK_CONTAINER)
	elseif msg == 'keys' then
		self:Toggle(KEYRING_CONTAINER)
	else
		self:Print('Commands (/cbt or /combuctor)')
		ChatFrame1:AddMessage('- bank: Toggle bank')
		ChatFrame1:AddMessage('- bags: Toggle inventory')
		ChatFrame1:AddMessage('- keys: Toggle keyring')
	end
end