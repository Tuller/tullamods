--[[
	Aura Button
		An aura icon display
--]]

local AuraButton = Sage:CreateClass('Button')

local _G = _G
local DebuffTypeColor = _G['DebuffTypeColor']
local UnitAura = _G['UnitAura']
local ICON_SIZE = 17
local floor = math.floor
local ceil = math.ceil

--TODO: replace with my own, prettier buff icon template
--needs to be XML based since blizzard forgot to make the brighter cooldown model attribute able to be set via lua
function AuraButton:New(id, parent)
	local name = parent:GetName() .. id
	local f = self:Bind(CreateFrame('Button', name, parent, 'TargetDebuffButtonTemplate'))

	f:SetID(id)
	f.count = _G[name .. 'Count']
	f.icon = _G[name .. 'Icon']
	f.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	f.border = _G[name .. 'Border']

	f.cooldown = _G[name .. 'Cooldown']
	f.cooldown.noCooldownCount = true --disable omnicc

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
	if count and count > 1 then
		self.count:SetText(count)
		self.count:Show()
	else
		self.count:Hide()
	end
end

function AuraButton:UpdateDebuffBorder(type)
	if type then
		local color = DebuffTypeColor[type]
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
	return UnitIsFriend('player', self:GetUnit()) and self:GetParent().friendFilter or self:GetParent().filter
end


--[[
	AuraContainer
		A container for aura buttons
--]]

local AuraContainer = Sage:CreateClass('Frame')
Sage.AuraContainer = AuraContainer

local visibleFrames = {}

function AuraContainer:New(id, parent, filter, friendFilter, maxIconScale)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. id, parent))
	f.filter = filter
	f.friendFilter = friendFilter
	f.maxIconScale = maxIconScale or math.huge

	--creat aura icons on demand
	f.buttons = setmetatable({}, {__index = function(t, k)
		local b = AuraButton:New(k, f)
		t[k] = b
		return b
	end})

	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.OnHide)
	f:SetScript('OnSizeChanged', self.OnSizeChanged)
	f:UpdateUnit()

	visibleFrames[f] = true
	return f
end


--[[ Frame Events ]]--

function AuraContainer:OnShow()
	visibleFrames[self] = true
	self:Update()
end

function AuraContainer:OnHide()
	visibleFrames[self] = nil
end

function AuraContainer:OnSizeChanged()
	if self:IsVisible() then
		self:Layout()
	end
end



--[[ Update Methods ]]--

function AuraContainer:Update()
	self.needsUpdate = nil

	local unit = self.unit
	local filter = UnitIsFriend('player', unit) and self.friendFilter or self.filter
	local count = 0


	local id = 1
	local name, rank, icon, applications, debuffType, duration, expirationTime, isMine, isStealable = UnitAura(unit, id, filter)
	while name do
		if isMine then
			count = count + 1

			local b = self.buttons[count]
			b:Update(name, rank, icon, applications, debuffType, duration, expirationTime, isMine, isStealable)
			b:Show()
		end

		id = id + 1
		name, rank, icon, applications, debuffType, duration, expirationTime, isMine, isStealable = UnitAura(unit, id, filter)
	end

	local id = 1
	local name, rank, icon, applications, debuffType, duration, expirationTime, isMine, isStealable = UnitAura(unit, id, filter)
	while name do
		if not isMine then
			count = count + 1

			local b = self.buttons[count]
			b:Update(name, rank, icon, applications, debuffType, duration, expirationTime, isMine, isStealable)
			b:Show()
		end

		id = id + 1
		name, rank, icon, applications, debuffType, duration, expirationTime, isMine, isStealable = UnitAura(unit, id, filter)
	end

	for i = count + 1, #self.buttons do
		self.buttons[i]:Hide()
	end

	--only layout the frame if we now have a new number of auras
	if count ~= self.count then
		self.count = count
		self:Layout()
	end
end

--should be nearly identical to the combuctor layout code for items
--basically this scales however many aura buttons you have to fit into whatever the size of the area that the auracontainer occupies
function AuraContainer:Layout(spacing)
	local width, height = self:GetWidth(), self:GetHeight()
	local spacing = spacing or 1
	local count = self.count or 0
	local size = ICON_SIZE + spacing*2
	local cols = 0
	local scale, rows

	if count > 0 and width > 0 and height > 0 then
		repeat
			cols = cols + 1
			scale = width / (size*cols)
			rows = floor(height / (size*scale))
		until(cols*rows >= count)
		scale = min(scale, self.maxIconScale)

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
end

function AuraContainer:RequestUpdate()
	if self:IsVisible() then
		self.needsUpdate = true
		AuraContainer:Show()
	end
end


--[[ Container Attributes ]]--

function AuraContainer:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if newUnit ~= self.unit then
		self.unit = newUnit
		self:RequestUpdate()
	end
end

function AuraContainer:SetFilter(filter)
	if self.filter ~= filter then
		self.filter = filter
		self:RequestUpdate()
	end
end

function AuraContainer:SetFriendFilter(filter)
	if self.friendFilter ~= filter then
		self.friendFilter = filter
		self:RequestUpdate()
	end
end

function AuraContainer:SetMaxIconScale(scale)
	if self.maxIconScale ~= scale then
		self.maxIconScale = scale
		if self:IsVisible() then
			self:Layout()
		end
	end
end

function AuraContainer:ForVisibleUnit(unit, method, ...)
	for f in pairs(visibleFrames) do
		if f.unit == unit then
			f[method](f, ...)
		end
	end
end


--[[
	Aura event handler
--]]

do
	AuraContainer:SetScript('OnEvent', function(self, event, ...)
		if event == 'UNIT_AURA' then
			local unit = ...
			self:ForVisibleUnit(unit, 'RequestUpdate')
		elseif event == 'PLAYER_TARGET_CHANGED' then
			self:ForVisibleUnit('target', 'RequestUpdate')
		elseif event == 'PLAYER_FOCUS_CHANGED' then
			self:ForVisibleUnit('focus', 'RequestUpdate')
		end
	end)
	AuraContainer:RegisterEvent('UNIT_AURA')
	AuraContainer:RegisterEvent('PLAYER_TARGET_CHANGED')
	AuraContainer:RegisterEvent('PLAYER_FOCUS_CHANGED')


	--update everything that needs an update on the next rendered frame
	AuraContainer:SetScript('OnUpdate', function(self, elapsed)
		self.nextUpdate = self.nextUpdate - elapsed

		if self.nextUpdate < 0 then
			for f in pairs(visibleFrames) do
				if f.needsUpdate then
					f:Update()
				end
			end
			self:Hide()
		end
	end)

	AuraContainer:SetScript('OnShow', function(self)
		self.nextUpdate = 0.03 --aura updating delay
	end)

	AuraContainer:Hide()
end