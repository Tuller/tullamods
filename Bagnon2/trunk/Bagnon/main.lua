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
	if not self:GetFrame(frameID) then
		self:CreateFrame(frameID)
	end
	self.FrameSettings:Get(frameID):ShowFrame()
end

function Bagnon:HideFrame(frameID)
	self.FrameSettings:Get(frameID):HideFrame()
end

function Bagnon:ToggleFrame(frameID)
	if not self:GetFrame(frameID) then
		self:CreateFrame(frameID)
	end
	self.FrameSettings:Get(frameID):ToggleFrame()
end


--[[
	Automatic Bag Display
--]]

function Bagnon:HookBagEvents()
	--backpack
	hooksecurefunc('CloseBackpack', function()
		self:HideFrame('inventory')
	end)

	OpenBackpack = function()
		self:ShowFrame('inventory')
	end

	ToggleBackpack = function()
		self:ToggleFrame('inventory')
	end

	--single bag
	ToggleBag = function(bag)
		if self.BagSlotInfo:IsBankBag(bag) then
			self:ToggleFrame('bank')
		else
			self:ToggleFrame('inventory')
		end
	end

	--keyring
	ToggleKeyRing = function()
		self:ToggleFrame('keys')
	end

	--all bags
	--closing the game menu triggers this function, and can be done in combat
	hooksecurefunc('CloseAllBags', function()
		self:HideFrame('inventory')
	end)

	OpenAllBags = function(force)
		if force then
			self:ShowFrame('inventory')
		else
			self:ToggleFrame('inventory')
		end
	end

	--bank
	BankFrame:UnregisterAllEvents()

	self.BagEvents:Listen(self, 'BANK_OPENED', function()
		self:ShowFrame('inventory')
		self:ShowFrame('bank')
	end)

	self.BagEvents:Listen(self, 'BANK_CLOSED', function()
		self:HideFrame('inventory')
		self:HideFrame('bank')
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
	else
		self:PrintHelp()
	end
end

function Bagnon:PrintVersion()
	self:Print(self.SavedSettings:GetDBVersion())
end

function Bagnon:PrintHelp(cmd)
	local function PrintCmd(cmd, desc)
		print(format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print(L.Commands)
	PrintCmd('bags', L.CmdShowInventory)
	PrintCmd('bank', L.CmdShowBank)
	PrintCmd('keys', L.CmdShowKeyring)
	PrintCmd('version', L.CmdShowVersion)
end