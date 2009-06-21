--[[
	main.lua
		The bagnon driver thingy
--]]

Bagnon = LibStub('AceAddon-3.0'):NewAddon('Bagnon', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')


--[[
	Binding Setup
--]]

BINDING_HEADER_BAGNON = 'Bagnon'
BINDING_NAME_BAGNON_TOGGLE = L.ToggleBags
BINDING_NAME_BANKNON_TOGGLE = L.ToggleBank
BINDING_NAME_BAGNON_KEYS_TOGGLE = L.ToggleKeys


--[[
	Startup
--]]

function Bagnon:OnEnable()
	self.frames = {}

	self:HookBagClickEvents()
	self:RegisterAutoDisplayEvents()
	self:AddSlashCommands()
	self:CreateOptionsLoader()
	self:CreateLDBLauncher()
end

--create a loader for the options menu
function Bagnon:CreateOptionsLoader()
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn('Bagnon_Config')
	end)
end

function Bagnon:CreateLDBLauncher()
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if not LDB then return end

	LDB:NewDataObject('BagnonLauncher', {
		type = 'launcher',

		icon = [[Interface\Icons\INV_Misc_Bag_07]],

		OnClick = function(_, button)
			if button == 'LeftButton' then
				if IsShiftKeyDown() then
					Bagnon:ToggleFrame('bank')
				elseif IsAltKeyDown() then
					Bagnon:ToggleFrame('keys')
				else
					Bagnon:ToggleFrame('inventory')
				end
			elseif button == 'RightButton' then
				Bagnon:ShowOptions()
			end
		end,

		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end

			tooltip:AddLine('Bagnon')
			tooltip:AddLine(L.TipShowInventory, 1, 1, 1)
			tooltip:AddLine(L.TipShowBank, 1, 1, 1)
			tooltip:AddLine(L.TipShowKeyring, 1, 1, 1)
			tooltip:AddLine(L.TipShowOptions, 1, 1, 1)
		end,
	})
end


--[[
	Frame Display
--]]

function Bagnon:GetFrame(frameID)
	for i, frame in pairs(self.frames) do
		if frame:GetFrameID() == frameID then
			return frame
		end
	end
end

function Bagnon:CreateFrame(frameID)
	table.insert(self.frames, self.Frame:New(frameID))
end

function Bagnon:ShowFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		if not self:GetFrame(frameID) then
			self:CreateFrame(frameID)
		end

		self.FrameSettings:Get(frameID):Show()
		return true
	end
	return false
end

function Bagnon:HideFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		self.FrameSettings:Get(frameID):Hide()
		return true
	end
	return false
end

function Bagnon:ToggleFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		if not self:GetFrame(frameID) then
			self:CreateFrame(frameID)
		end

		self.FrameSettings:Get(frameID):Toggle()
		return true
	end
	return false
end

function Bagnon:IsFrameEnabled(frameID)
	return self.Settings:IsFrameEnabled(frameID)
end


--[[
	Bag Click Events
--]]

function Bagnon:HookBagClickEvents()
	--backpack
	hooksecurefunc('CloseBackpack', function()
		self:HideFrame('inventory')
	end)

	local oOpenBackpack = OpenBackpack
	OpenBackpack = function()
		if not self:ShowFrame('inventory') then
			oOpenBackpack()
		end
	end

	local oToggleBackpack = ToggleBackpack
	ToggleBackpack = function()
		if not self:ToggleFrame('inventory') then
			oToggleBackpack()
		end
	end

	--single bag
	local oToggleBag = ToggleBag
	ToggleBag = function(bag)
		local toggled = false
		if self.BagSlotInfo:IsBankBag(bag) then
			toggled = self:ToggleFrame('bank')
		else
			toggled = self:ToggleFrame('inventory')
		end
		if not toggled then
			oToggleBag(bag)
		end
	end

	--keyring
	local oToggleKeyRing = ToggleKeyRing
	ToggleKeyRing = function()
		if not self:ToggleFrame('keys') then
			oToggleKeyRing()
		end
	end

	--all bags
	--closing the game menu triggers this function, and can be done in combat
	hooksecurefunc('CloseAllBags', function()
		self:HideFrame('inventory')
	end)

	local oOpenAllBags = OpenAllBags
	OpenAllBags = function(force)
		local opened = false
		if force then
			opened = self:ShowFrame('inventory')
		else
			opened = self:ToggleFrame('inventory')
		end

		if not opened then
			oOpenAllBags(force)
		end
	end

	local function bag_checkIfInventoryShown(self)
		if Bagnon:IsFrameEnabled('inventory') then
			self:SetChecked(Bagnon.FrameSettings:Get('inventory'):IsShown())
		end
	end

	--handle checking/unchecking of the backpack buttons based on frame display
	hooksecurefunc('BagSlotButton_UpdateChecked', bag_checkIfInventoryShown)
	hooksecurefunc('BackpackButton_UpdateChecked', bag_checkIfInventoryShown)
	self.Callbacks:Listen(self, 'FRAME_SHOW')
	self.Callbacks:Listen(self, 'FRAME_HIDE')
end


--[[ Click Events ]]--

function Bagnon:FRAME_SHOW(msg, frameID)
	if frameID == 'inventory' then
		if self:IsFrameEnabled('inventory') then
			self:CheckBagFrameBags(true)
		end
	end
end

function Bagnon:FRAME_HIDE(msg, frameID)
	if frameID == 'inventory' then
		if self:IsFrameEnabled('inventory') then
			self:CheckBagFrameBags(false)
		end
	end
end

--check/uncheck the bag frames
function Bagnon:CheckBagFrameBags(checked)
	_G['MainMenuBarBackpackButton']:SetChecked(checked)
	_G["CharacterBag0Slot"]:SetChecked(checked)
	_G["CharacterBag1Slot"]:SetChecked(checked)
	_G["CharacterBag2Slot"]:SetChecked(checked)
	_G["CharacterBag3Slot"]:SetChecked(checked)
end


--[[
	Automatic Display
--]]

function Bagnon:RegisterAutoDisplayEvents()
	self.BagEvents:Listen(self, 'BANK_OPENED')
	self.BagEvents:Listen(self, 'BANK_CLOSED')
	self:RegisterEvent('MAIL_CLOSED')
	self:RegisterEvent('AUCTION_HOUSE_SHOW')
	self:RegisterEvent('AUCTION_HOUSE_CLOSED')
	self:RegisterEvent('MERCHANT_SHOW')
	self:RegisterEvent('MERCHANT_CLOSED')
	self:RegisterEvent('TRADE_SHOW')
	self:RegisterEvent('TRADE_CLOSED')
	self:RegisterEvent('TRADE_SKILL_SHOW')
	self:RegisterEvent('TRADE_SKILL_CLOSE')
	self:RegisterEvent('GUILDBANKFRAME_OPENED')
	self:RegisterEvent('GUILDBANKFRAME_CLOSED')

	--override normal bank display
	BankFrame:UnregisterEvent('BANKFRAME_OPENED')
	BankFrame:UnregisterEvent('BANKFRAME_CLOSED')
end

function Bagnon:ShowFrameAtEvent(frameID, event)
	if self:AutoDisplayingFrameOnEvent(frameID, event) then
		self:ShowFrame(frameID)
	end
end

function Bagnon:HideFrameAtEvent(frameID, event)
	if self:AutoDisplayingFrameOnEvent(frameID, event) then
		self:HideFrame(frameID)
	end
end

function Bagnon:AutoDisplayingFrameOnEvent(frameID, event)
	return self.Settings:IsFrameShownAtEvent(frameID, event)
end

function Bagnon:ShowBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_OPENED')
end

function Bagnon:HideBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_CLOSED')
end


--[[ Display Events ]]--

--visiting the bank
function Bagnon:BANK_OPENED()
	if not self:ShowFrame('bank') then
		self:ShowBlizzardBankFrame()
	end
	self:ShowFrameAtEvent('inventory', 'bank')
end

function Bagnon:BANK_CLOSED()
	if not self:HideFrame('bank') then
		HideBlizzardBankFrame()
	end
	self:HideFrameAtEvent('inventory', 'bank')
end

--visiting the mailbox
--mail frame is a special case, since its automatically handled by the stock interface
function Bagnon:MAIL_CLOSED()
	self:HideFrame('inventory')
end

--visiting the auction house
function Bagnon:AUCTION_HOUSE_SHOW()
	self:ShowFrameAtEvent('inventory', 'ah')
end

function Bagnon:AUCTION_HOUSE_CLOSED()
	self:HideFrameAtEvent('inventory', 'ah')
end

--visitng a vendor
function Bagnon:MERCHANT_SHOW()
	self:ShowFrameAtEvent('inventory', 'vendor')
end

function Bagnon:MERCHANT_CLOSED()
	self:HideFrameAtEvent('inventory', 'vendor')
end

--trading
function Bagnon:TRADE_SHOW()
	self:ShowFrameAtEvent('inventory', 'trade')
end

function Bagnon:TRADE_CLOSED()
	self:HideFrameAtEvent('inventory', 'trade')
end

--visiting the guild bank
function Bagnon:GUILDBANKFRAME_OPENED()
	self:ShowFrameAtEvent('inventory', 'guildbank')
end

function Bagnon:GUILDBANKFRAME_CLOSED()
	self:HideFrameAtEvent('inventory', 'guildbank')
end

--crafting
function Bagnon:TRADE_SKILL_SHOW()
	self:ShowFrameAtEvent('inventory', 'craft')
end

function Bagnon:TRADE_SKILL_CLOSE()
	self:HideFrameAtEvent('inventory', 'craft')
end


--[[
	Slash Commands
--]]

function Bagnon:AddSlashCommands()
	self:RegisterChatCommand('bagnon', 'HandleSlashCommand')
	self:RegisterChatCommand('bgn', 'HandleSlashCommand')
end

function Bagnon:HandleSlashCommand(cmd)
	cmd = cmd and cmd:lower() or ''
	if cmd == 'bank' then
		self:ToggleFrame('bank')
	elseif cmd == 'bags' then
		self:ToggleFrame('inventory')
	elseif cmd == 'keys' then
		self:ToggleFrame('keys')
	elseif cmd == 'version' then
		self:PrintVersion()
	elseif cmd == 'config' then
		self:ShowOptions()
	elseif cmd == '?' or cmd == 'help' then
		self:PrintHelp()
	else
		if not self:ShowOptions() then
			self:PrintHelp()
		end
	end
end

function Bagnon:PrintVersion()
	self:Print(self.SavedSettings:GetDBVersion())
end

function Bagnon:PrintHelp()
	local function PrintCmd(cmd, desc)
		print(string.format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print(L.Commands)
	PrintCmd('bags', L.CmdShowInventory)
	PrintCmd('bank', L.CmdShowBank)
	PrintCmd('keys', L.CmdShowKeyring)
	PrintCmd('version', L.CmdShowVersion)
end

function Bagnon:ShowOptions()
	if LoadAddOn('Bagnon_Config') then
		InterfaceOptionsFrame_OpenToCategory(self.GeneralOptions)
		return true
	end
	return false
end