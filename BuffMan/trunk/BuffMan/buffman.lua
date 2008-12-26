local BuffMan = CreateFrame('Frame', 'BuffMan', UIParent)
BuffMan:SetAllPoints(BuffMan:GetParent())

function BuffMan:Load()
	self.buffs = {}
	self.debuffs = {}

	self.buffFrame = self.AuraContainer:New('BuffManBuffs')
--	self.buffFrame:SetAlpha(0.5)
	self.buffFrame:SetWidth(180)
	self.buffFrame:SetHeight(38)
	self.buffFrame:SetPoint('CENTER', -180/2, -400)

	self.debuffFrame = self.AuraContainer:New('BuffManDebuffs')
--	self.debuffFrame:SetAlpha(0.5)
	self.debuffFrame:SetWidth(180)
	self.debuffFrame:SetHeight(38)
	self.debuffFrame:SetPoint('CENTER', 180/2, -400)

	self:SetScript('OnUpdate', self.OnUpdate)
	self:SetScript('OnEvent', self.OnEvent)
	self:RegisterEvent('UNIT_AURA')
	self:RegisterEvent('PLAYER_LOGIN')
	self:RegisterEvent('PLAYER_TARGET_CHANGED')
	self:RegisterEvent('PLAYER_FOCUS_CHANGED')
end

--[[ Events ]]--

function BuffMan:OnEvent(event, ...)
	self[event](self, ...)
end

function BuffMan:OnUnitEvent(unit)
	if UnitExists(unit) then
		if self:IsFriend(unit) then
			self:UpdateFriend(unit)
		else
			self:UpdateFoe(unit)
		end
	else
		self:ClearBuffs(unit)
		self:ClearDebuffs(unit)
	end
end

function BuffMan:UNIT_AURA(unit)
	self:OnUnitEvent(unit)
end

function BuffMan:PLAYER_LOGIN()
	self:OnUnitEvent('player')
end

function BuffMan:PLAYER_TARGET_CHANGED()
	self:OnUnitEvent('target')
end

function BuffMan:PLAYER_FOCUS_CHANGED()
	self:OnUnitEvent('focus')
end

function BuffMan:PARTY_MEMBERS_CHANGED()
	for i = 1, NUM_PARTY_MEMBERS do
		self:OnUnitEvent('party' .. i)
	end
end


--[[ Layout ]]--

function BuffMan:OnUpdate()
	self:Layout()
	self:Hide()
end

function BuffMan:RequestLayout(frame)
	frame.needsLayout = true
	self:Show()
end

function BuffMan:Layout()
	if self.buffFrame.needsLayout then
		self.buffFrame.needsLayout = nil
		self.buffFrame:Update(self:GetSummary(self.buffs))
	end
	
	if self.debuffFrame.needsLayout then
		self.debuffFrame.needsLayout = nil
		self.debuffFrame:Update(self:GetSummary(self.debuffs))
	end
end

local function summarySort(aura1, aura2)
	return aura1.expirationTime < aura2.expirationTime 
end

local function detailsSort(unit1, unit2)
	return UnitName(unit1.unit) < UnitName(unit2.unit)
end

function BuffMan:GetInfo(summary, aura)
	for _, info in pairs(summary) do
		if info.name == aura.name and info.expirationTime == aura.expirationTime then
			return info
		end
	end
	
	local newInfo = {
		name = aura.name, 
		expirationTime = aura.expirationTime, 
		details = {}
	}
	table.insert(summary, newInfo)

	return newInfo
end

function BuffMan:GetSummary(tbl)
	local summary = {}

	for unit, auras in pairs(tbl) do
		for id, aura in pairs(auras) do
			local info = self:GetInfo(summary, aura)
			local found = false

			for _,detail in pairs(info.details) do
				if UnitIsUnit(detail.unit, aura.unit) then
					found = true
					break
				end
			end
			
			if not found then
				table.insert(info.details, aura)
			end
		end
	end
	
	for _,info in pairs(summary) do
		table.sort(info.details, detailsSort)
	end
	table.sort(summary, summarySort)
	return summary
end


--[[ Updating ]]--

function BuffMan:Update(tbl, unit, filter)
	local id = 1
	local index = 0
	local name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable = UnitAura(unit, id, filter)
	local changed = false

	while name do
		if duration > 0 then
			index = index + 1

			local auras = tbl[unit] or {}
			local info = auras[index] or {}
			if not(info.name == name and info.count == count and info.duration == duration and info.expirationTime == expirationTime) then
				changed = true
			end

			info.id = id
			info.filter = filter
			info.unit = unit
			info.name = name
			info.count = count
			info.icon = icon
			info.duration = duration
			info.expirationTime = expirationTime
			info.debuffType = debuffType
			
			auras[index] = info
			tbl[unit] = auras
		end

		id = id + 1
		name, rank, icon, count, debuffType, duration, expirationTime, isMine, isStealable = UnitAura(unit, id, filter)
	end

	local auras = tbl[unit] 
	if auras then
		for i = index + 1, #auras do
			auras[i] = nil
			changed = true
		end
		
		if #auras == 0 then
			tbl[unit] = nil
		end
	end
	
	return changed
end

function BuffMan:UpdateFriend(unit)
	if self:Update(self.buffs, unit, 'HELPFUL|PLAYER') then
		self:RequestLayout(self.buffFrame)
	end
end

function BuffMan:UpdateFoe(unit)
	if self:Update(self.debuffs, unit, 'HARMFUL|PLAYER') then
		self:RequestLayout(self.debuffFrame)
	end
end

function BuffMan:Clear(tbl, unit)
	local auras = tbl[unit] 
	if auras then
		tbl[unit] = nil
		return true
	end
end

function BuffMan:ClearBuffs(unit)
	if self:Clear(self.buffs, unit) then
		self:RequestLayout(self.buffFrame)
	end
end

function BuffMan:ClearDebuffs(unit)
	if self:Clear(self.debuffs, unit) then
		self:RequestLayout(self.debuffFrame)
	end
end


--[[ Utility ]]--

function BuffMan:IsFriend(unit)
	return unit == 'player' or unit == 'pet' or unit == 'vehicle' or UnitInParty(unit) or UnitInRaid(unit)
end

function BuffMan:Print(...)
	print('Buffman:', ...)
end

function BuffMan:CreateClass(type, parentClass)
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


--[[
	Aura Button
		An aura icon display
--]]

local AuraButton = BuffMan:CreateClass('Button')

local _G = _G
local DebuffTypeColor = _G['DebuffTypeColor']
local UnitAura = _G['UnitAura']
local ICON_SIZE = 37
local floor = math.floor
local ceil = math.ceil

--TODO: replace with my own, prettier buff icon template
--needs to be XML based since blizzard forgot to make the brighter cooldown model attribute able to be set via lua
function AuraButton:New(id, parent)
	local name = parent:GetName() .. id
	local f = self:Bind(CreateFrame('Button', name, parent, 'ActionButtonTemplate'))

	f.count = _G[name .. 'Count']
	f.icon = _G[name .. 'Icon']
	f.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	f.border = _G[name .. 'Border']
	f.border:SetAlpha(1)
	f.cooldown = _G[name .. 'Cooldown']
	f.cooldown:SetReverse(true)

	f:SetScript('OnUpdate', self.OnUpdate)
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)

	return f
end

function AuraButton:Update(info)
	local first = info.details[1]

	self.elapsed = 0
	self.info = info
	self.first = first
	self.icon:SetTexture(first.icon)
	self:UpdateCount(first.count)
	self:UpdateDebuffBorder(first.debuffType)
	self:UpdateCooldown(first.duration, first.expirationTime)
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
	GameTooltip:SetUnitAura(self.first.unit, self.first.id, self.first.filter)
	
	for i,detail in ipairs(self.info.details) do
		local color = RAID_CLASS_COLORS[select(2, UnitClass(detail.unit)) or 'WARRIOR']
		GameTooltip:AddLine(UnitName(detail.unit), color.r, color.g, color.b)
	end

	GameTooltip:Show()
end

function AuraButton:OnLeave()
	GameTooltip:Hide()
end

function AuraButton:OnUpdate(elapsed)
	self.elapsed = (self.elapsed or 0) - elapsed
	if self.elapsed < 0 then
		self.elapsed = 0.1

		local first = self.info.details[1]
		self:SetAlpha(1 - ((first.expirationTime - GetTime()) / first.duration))
	end
end


--[[
	AuraContainer
		A container for aura buttons
--]]

local AuraContainer = BuffMan:CreateClass('Frame')
BuffMan.AuraContainer = AuraContainer

function AuraContainer:New(name)
	local f = self:Bind(CreateFrame('Frame', name, UIParent))

	f.buttons = setmetatable({}, {__index = function(t, k)
		local b = AuraButton:New(k, f)
		t[k] = b
		return b
	end})

	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnSizeChanged', self.OnSizeChanged)

	return f
end

function AuraContainer:Update(summary)
	local count = #summary

	for i,info in ipairs(summary) do
		local b = self.buttons[i]
		b:Update(info)
		b:Show()
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
function AuraContainer:Layout()
	local width, height = self:GetWidth(), self:GetHeight()
	local spacing = 2
	local count = self.count or 0
	local cols = 0
	local scale, rows

	if count > 0 and width > 0 and height > 0 then
		local size = self.buttons[1]:GetHeight() + spacing*2
		
		repeat
			cols = cols + 1
			scale = width / (size*cols)
			rows = floor(height / (size*scale))
		until(cols*rows >= count)

		--layout the stuff
		for i = 1, count do
			local row = (i-1) % cols
			local col = ceil(i/cols)-1
			local b = self.buttons[i]

			b:ClearAllPoints()
			b:SetScale(scale)
			b:SetPoint('TOPLEFT', size*row + spacing, -(size*col + spacing))
		end
	end
end

BuffMan:Load()