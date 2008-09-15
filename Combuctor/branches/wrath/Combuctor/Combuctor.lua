--[[
	Combuctor.lua
		Some sort of crazy visual inventory management system
--]]

LoadAddOn('Bagnon_Forever')

Combuctor = LibStub('AceAddon-3.0'):NewAddon('Combuctor', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Combuctor')
local CURRENT_VERSION = GetAddOnMetadata('Combuctor', 'Version')

--set the binding name stuff here, since its mostly locale independent
BINDING_HEADER_COMBUCTOR = 'Combuctor'
BINDING_NAME_COMBUCTOR_TOGGLE_INVENTORY = L.ToggleInventory
BINDING_NAME_COMBUCTOR_TOGGLE_BANK = L.ToggleBank

--[[
	Loading/Profile Functions
--]]

function Combuctor:OnInitialize()
	--register database events
	self.db = LibStub('AceDB-3.0'):New('CombuctorDB2', self:GetDefaults())
--[[
	self.db.RegisterCallback(self, 'OnNewProfile')
	self.db.RegisterCallback(self, 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileCopied')
	self.db.RegisterCallback(self, 'OnProfileReset')
	self.db.RegisterCallback(self, 'OnProfileDeleted')
--]]

	--version update
	if CombuctorVersion then
		if CombuctorVersion ~= CURRENT_VERSION then
			self:UpdateSettings(CombuctorVersion:match('(%w+)%.(%w+)%.(%w+)'))
			self:UpdateVersion()
		end
	--new user
	else
		CombuctorVersion = CURRENT_VERSION
	end

	--slash command support
	self:RegisterChatCommand('combuctor', 'OnSlashCommand')
	self:RegisterChatCommand('cbt', 'OnSlashCommand')
end

function Combuctor:OnEnable()
	local Frame = self:GetModule('Frame')

	self.frames = {
		Frame:New(L.InventoryTitle, self.db.profile.inventory),
		Frame:New(L.BankTitle, self.db.profile.bank, true)
	}

	self:HookBagEvents()
end

function Combuctor:GetDefaults()
	local defaults = {
		profile = {
			maxItemScale = 1.5,

			inventory = {
				bags = {-2, 0, 1, 2, 3, 4},
				position = {'RIGHT'},
				showBags = false,
				w = 384,
				h = 512,

				sets = {
					{name = L.All},
				}
			},

			bank = {
				bags = {-1, 5, 6, 7, 8, 9, 10, 11},
				showBags = false,
				w = 512,
				h = 512,

				--the reason i'm using an exclude syntax is so that this shit can work in the case of itemrack, where one might want a per outfit subfilters
				--so if someone add and removes them a lot, then they'll have to add and remove them from combuctor a lot too, which we don't want
				sets = {
					{name = L.All, exclude = {L.Keys}},
					{name = L.Equipment},
					{name = L.Usable},
					{name = L.TradeGood}
				}
			}
		}
	}


	return defaults
end

function Combuctor:UpdateSettings(major, minor, bugfix)
	--do stuff
end

function Combuctor:UpdateVersion()
	CombuctorVersion = CURRENT_VERSION
	self:Print(format(L.Updated, CombuctorVersion))
end


--[[
	Events
--]]

function Combuctor:HookBagEvents()
	local AutoShowInventory = function()
		self:Show(BACKPACK_CONTAINER, true)
	end
	local AutoHideInventory = function()
		self:Hide(BACKPACK_CONTAINER, true)
	end

	--auto magic display code
	OpenBackpack = AutoShowInventory
	hooksecurefunc('CloseBackpack', AutoHideInventory)

	ToggleBag = function(bag)
		self:Toggle(bag)
	end

	ToggleBackpack = function()
		self:Toggle(BACKPACK_CONTAINER)
	end

	ToggleKeyRing = function()
		self:Toggle(KEYRING_CONTAINER)
	end

	OpenAllBags = function(force)
		if force then
			self:Show(BACKPACK_CONTAINER)
		else
			self:Toggle(BACKPACK_CONTAINER)
		end
	end

	--closing the game menu triggers this function, and can be done in combat,
	hooksecurefunc('CloseAllBags', function()
		self:Hide(BACKPACK_CONTAINER)
	end)

	BankFrame:UnregisterAllEvents()
	self:RegisterMessage('COMBUCTOR_BANK_OPENED', function()
		self:Show(BANK_CONTAINER, true)
		self:Show(BACKPACK_CONTAINER, true)
	end)
	self:RegisterMessage('COMBUCTOR_BANK_CLOSED', function()
		self:Hide(BANK_CONTAINER, true)
		self:Hide(BACKPACK_CONTAINER, true)
	end)

	self:RegisterEvent('MAIL_CLOSED', AutoHideInventory)
	self:RegisterEvent('TRADE_SHOW', AutoShowInventory)
	self:RegisterEvent('TRADE_CLOSED', AutoHideInventory)
	self:RegisterEvent('TRADE_SKILL_SHOW', AutoShowInventory)
	self:RegisterEvent('TRADE_SKILL_CLOSE', AutoHideInventory)
	self:RegisterEvent('AUCTION_HOUSE_SHOW', AutoShowInventory)
	self:RegisterEvent('AUCTION_HOUSE_CLOSED', AutoHideInventory)
	self:RegisterEvent('AUCTION_HOUSE_SHOW', AutoShowInventory)
	self:RegisterEvent('AUCTION_HOUSE_CLOSED', AutoHideInventory)
end

function Combuctor:Show(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:ShowFrame(auto)
				return
			end
		end
	end
end

function Combuctor:Hide(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:HideFrame(auto)
				return
			end
		end
	end
end

function Combuctor:Toggle(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:ToggleFrame(auto)
				return
			end
		end
	end
end

function Combuctor:OnSlashCommand(msg)
	local msg = msg and msg:lower()

	if msg == 'bank' then
		self:Toggle(BANK_CONTAINER)
	elseif msg == 'bags' then
		self:Toggle(BACKPACK_CONTAINER)
	else
		self:Print('Commands (/cbt or /combuctor)')
		DEFAULT_CHAT_FRAME:AddMessage('- bank: Toggle bank')
		DEFAULT_CHAT_FRAME:AddMessage('- bags: Toggle inventory')
	end
end


--[[ Utility Functions ]]--

function Combuctor:SetMaxItemScale(scale)
	self.db.profile.maxItemScale = scale or 1
end

function Combuctor:GetMaxItemScale()
	return self.db.profile.maxItemScale
end

--utility function: create a widget class
function Combuctor:CreateClass(type, parentClass)
	local class = CreateFrame(type)
	class.mt = {__index = class}

	if parentClass then
		class = setmetatable(class, {__index = parentClass})
		class.super = parentClass
	end

	function class:Bind(o)
		return setmetatable(o, self.mt)
	end

	return class
end