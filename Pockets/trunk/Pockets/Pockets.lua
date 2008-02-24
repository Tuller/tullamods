--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
Pockets = Bongos:NewModule('Pockets', 'AceEvent-3.0')
local UNKNOWN_ITEM = 'Interface/Icons/INV_Misc_QuestionMark'


--[[ DockButton Object ]]--

local DockButton = Bongos:CreateWidgetClass('Button')

local id = 0
function DockButton:Create(parent)
	local b = self:New(CreateFrame('Button', format('PocketTab%d', id ), parent, 'ItemButtonTemplate'))
	b:SetAlpha(0.3)
	b:SetScript('OnEnter', self.OnEnter)
	b:SetScript('OnLeave', self.OnLeave)
	getglobal(b:GetName() .. 'IconTexture'):SetTexture(UNKNOWN_ITEM)

	id = id + 1
	return b
end

function DockButton:OnEnter()
	UIFrameFadeIn(self, 0.2)
	PocketFrame:Show(self)
end


--[[ Bar Code ]]--

local function Bar_Layout(self)
	if not self.items then
		self.items = {}
	end

	local prev
	for i, rule in ipairs(PocketsDB) do
		local item = self.items[i]
		if not item then
			item = DockButton:Create(self)
			self.items[i] = item
		end
		item.rule = rule

		if prev then
			item:SetPoint('LEFT', prev, 'RIGHT', 1, 0)
		else
			item:SetPoint('LEFT', self)
		end
		prev = item
	end

	for i = #PocketsDB + 1, #self.items do
		self.items[i]:Hide()
		item:Hide()
	end

	self:SetWidth(#self.sets.cats * (37 + 1) - 1)
	self:SetHeight(37)
end

local function Bar_OnCreate(self)
	self.Layout = Bar_Layout
end


--[[ Startup ]]--

function Pockets:Load()
	local defaults = {
		point = 'CENTER', 
		cats = {'food & drink', 'quest', 'bandage', 'misc', 'ammo'}
	}

	local bar, isNew = Bongos.Bar:Create('pockets', defaults)
	if isNew then
		Bar_OnCreate(bar)
	end
	bar:Layout()
	self.bar = bar
end

function Pockets:Unload()
	self.bar:Destroy()
	self:UnregisterAllMessages()
end
