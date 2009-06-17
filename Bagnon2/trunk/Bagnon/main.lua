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
	self:HookBagEvents()
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
	Automatic Bag Display
--]]

local function ShowBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_OPENED')
end

local function HideBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_CLOSED')
end

function Bagnon:HookBagEvents()
	--backpack
	hooksecurefunc('CloseBackpack', function()
		self:HideFrame('inventory')
	end)

	local oOpenBackpack = OpenBackpack
	OpenBackpack = function(...)
		if not self:ShowFrame('inventory') then
			oOpenBackpack(...)
		end
	end

	local oToggleBackpack = ToggleBackpack
	ToggleBackpack = function(...)
		if not self:ToggleFrame('inventory') then
			oToggleBackpack(...)
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

	--bank
	BankFrame:UnregisterEvent('BANKFRAME_OPENED')
	BankFrame:UnregisterEvent('BANKFRAME_CLOSED')

	self.BagEvents:Listen(self, 'BANK_OPENED', function()
		self:ShowFrame('inventory')
		
		if not self:ShowFrame('bank') then
			ShowBlizzardBankFrame()
		end
	end)

	self.BagEvents:Listen(self, 'BANK_CLOSED', function()
		self:HideFrame('inventory')
		
		if not self:HideFrame('bank') then
			HideBlizzardBankFrame()
		end
	end)

	--mailbox auto open/close evnet
	self:RegisterEvent('MAIL_CLOSED', function() self:HideFrame('inventory') end)
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
		print(format(' - |cFF33FF99%s|r: %s', cmd, desc))
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