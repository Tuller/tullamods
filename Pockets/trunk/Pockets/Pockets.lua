--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

Pockets = Bongos:NewModule('Bongos-Pockets')
local UNKNOWN_ITEM = 'Interface/Icons/INV_Misc_QuestionMark'


--[[ DockButton Object ]]--

local DockButton = PocketUtil:CreateWidgetClass('Button')

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
	for i, rule in ipairs(self.sets.cats) do
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

	for i = #self.sets.cats + 1, #self.items do
		self.items[i]:Hide()
		item:Hide()
	end

	self:SetSize(#self.sets.cats * (37 + 1) - 1, 37)
end

local function Bar_OnCreate(self)
	self.Layout = Bar_Layout
end


--[[ Startup ]]--

function Pockets:Load()
	self.bar = BBar:Create('pockets', Bar_OnCreate, nil, {xOff = 0, yOff = 0, point = 'CENTER', cats = {'food & drink', 'quest', 'bandage', 'misc', 'ammo'}})
	self.bar:Layout()
end

function Pockets:Unload()
	self.bar:Destroy()
	self:UnregisterAllMessages()
end