--[[
	Aura Button
		An aura icon display
--]]

local AuraButton = Sage:CreateClass('Button')

local _G = _G
local DebuffTypeColor = _G['DebuffTypeColor']
local ICON_SIZE = 17
local floor = math.floor
local ceil = math.ceil

--TODO: replace with my own, prettier buff icon template
--needs to be XML based since blizzard forgot to make the brighter cooldown model attribute able to be set via lua
function AuraButton:New(id, parent)
	local name = parent:GetName() . id
	local f = self:Bind('Button', name, parent, 'TargetDebuffButtonTemplate')

	f:SetID(id)
	f.count = _G[name .. 'Count']
	f.icon = _G[name .. 'Icon']
	f.border = _G[name .. 'Border']
	f.cooldown = _G[name .. 'Cooldown']

	f:SetScript('OnUpdate', nil)
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)

	return f
end

function AuraButton:Update(name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable)
	self.icon:SetTexture(icon)
	self:UpdateCount(count)
	self:UpdateDebuffBorder(debuffType)
	self:UpdateCooldown(duration, expirationTime)
end

function AuraButton:UpdateCount(count)
	if count and count > 0 then
		self.count:SetText(count)
		self.count:Show()
	else
		self.count:Hide()
	end
end

function AuraButton:UpdateDebuffBorder(type)
	if type then
		local color = _G['DebuffTypeColor'][type]
		self.border:SetVertexColor(color.r, color.g, color.b)
		self.border:Show()
	else
		self.border:Hide()
	end
end

function AuraButton:UpdateCooldown(duration, expirationTime)
	if duration and duration > 0 then
		self.cooldown:SetCooldown(expirationTime - duration, duration)
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end
end

function AuraButton:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
	self:UpdateTooltip()
end

function AuraButton:UpdateTooltip()
	GameTooltip:SetUnitAura(self:GetUnit(), self:GetID(), self:GetFilter())
end

function AuraButton:OnLeave()
	GameTooltip:Hide()
end

function AuraButton:GetUnit()
	return self:GetParent().unit
end

function AuraButton:GetFilter()
	return self:GetParent().filter
end


--[[
	AuraContainer
		A container for aura buttons
--]]

local AuraContainer = Sage:CreateClass('Frame')
local frames = {}
Sage.AuraContainer = AuraContainer

function AuraContainer:New(id, parent, filter)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. id, parent))

	f.buttons = setmetatable({}, {__index = function(t, k)
		local b = AuraButton:New(k, f)
		t[k] = b
		return b
	end})

	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnSizeChanged', self.OnSizeChanged)
	f:UpdateUnit()
	table.insert(frames, f)

	return f
end

function AuraContainer:OnShow()
	self:Update()
end

function AuraContainer:OnSizeChanged()
	if self:IsVisible() then
		self:Layout()
	end
end

function AuraContainer:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if newUnit ~= self.unit then
		self.unit = newUnit
		if self:IsVisible() then
			self:Update()
		end
	end
end

function AuraContainer:Update()
	local count = 0
	local unit = self.unit
	local filter = self.filter

	local name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable
	repeat
		name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable = UnitAura(unit, count + 1, filter)
		if name then
			count = count + 1

			local b = self.buttons[count]
			b:Update(name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable)
			b:Show()
		end
	until not name

	for i = count + 1, #self.buttons do
		self.buttons[i]:Hide()
	end

	--only layout the frame if we now have a new number of auras
	if count ~= self.count then
		self.count = count
		self:Layout()
	end
end

function AuraContainer:SetFilter(filter)
	if self.filter ~= filter then
		self.filter = filter
		if self:IsVisible() then
			self:Update()
		end
	end
end

--should be nearly identical to the combuctor layout code for items
--basically this scales however many aura buttons you have to fit into whatever the size of the area that the auracontainer occupies
function AuraContainer:Layout(spacing)
	local width, height = self:GetWidth(), self:GetHeight()
	local spacing = spacing or 2
	local count = self.count or 0
	local size = ICON_SIZE + spacing*2
	local cols = 0
	local scale, rows

	--figure out the proper scale for things
	repeat
		cols = cols + 1
		scale = width / (size*cols)
		rows = floor(height / (size*scale))
	until(cols*rows >= count)

	--layout the stuff
	for i = 1, count do
		local row = (i-1) % cols
		local col = ceil(i/cols)-1
		local button = self.buttons[i]

		button:ClearAllPoints()
		button:SetScale(scale)
		button:SetPoint('TOPLEFT', size*row + spacing, -(size*col + spacing))
	end
end


--[[
	Aura event handler

	TODO: Throttle unit aura events because they fire off a lot
--]]

do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, unit)
		for _,frame in pairs(frames) do
			if frame.unit == unit and frame:IsVisible() then
				frame:Update()
			end
		end
	end)
	f:RegisterEvent('UNIT_AURA')
end