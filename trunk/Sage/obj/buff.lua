--[[
	Sage\buff.lua
		Functions for buff and debuff frames and icons
--]]

local DebuffTypeColor = DebuffTypeColor
local bg = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true,
	tileSize = 1,
	edgeFile = "",
	edgeSize = 0,
	insets = {left = 0, right = 0, top = 0, bottom = 0}
}


--[[ buff/debuff icons ]]--

local function Debuff_OnEnter(self)
	local unit = self:GetParent().id
	local sets = Sage:GetFrameSets(unit)

	local filter = (sets and sets.showCurable and UnitIsFriend("player", unit)) or false
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitDebuff(unit, self:GetID(), filter)
end

local function Buff_OnEnter(self)
	local unit = self:GetParent().id
	local sets = Sage:GetFrameSets(unit)

	local filter = (sets and sets.showCastable and UnitIsFriend("player", unit)) or false
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitBuff(unit, self:GetID(), filter)
end

local function Buff_OnLeave()
	GameTooltip:Hide()
end

local function Buff_Create(parent, id, isDebuff)
	local buff = CreateFrame("Frame", format("Sage%sBuff%d", parent.id, id), parent)
	buff:EnableMouse(true)
	buff:SetID(id)
	buff:SetWidth(36); buff:SetHeight(36)

	local icon = buff:CreateTexture(format("Sage%sBuff%dIcon", parent.id, id))
	if(isDebuff) then
		icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
		icon:SetPoint("TOPLEFT", buff, "TOPLEFT", 4, -4)
		icon:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", -4, 4)
	else
		icon:SetTexCoord(0.06,0.94,0.06,0.94)
		icon:SetAllPoints(buff)
	end
	buff.icon = icon

	local count = buff:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GameFontHighlightLarge)
	count:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT")
	buff.count = count

	local cooldown = CreateFrame("Cooldown", format("Sage%sBuff%dCooldown", parent.id, id), buff, "CooldownFrameTemplate")
	cooldown:SetAllPoints(buff)
	cooldown:SetReverse(true)
	cooldown:Hide()
	buff.cooldown = cooldown

	if(isDebuff) then
		buff:SetBackdrop(bg)

		-- local border = buff:CreateTexture(nil, "OVERLAY")
		-- border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		-- border:SetPoint("TOPLEFT", buff, "TOPLEFT", -1, 1)
		-- border:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", 1, -1)
		-- border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
		-- buff.border = border

		buff:SetScript("OnEnter", Debuff_OnEnter)
	else
		buff:SetScript("OnEnter", Buff_OnEnter)
	end
	buff:SetScript("OnLeave", Buff_OnLeave)

	return buff
end


--[[ buff/debuff frames ]]--

--update a single buff icon
local function BuffFrame_UpdateBuff(self, unit, index, filter, isDebuff)
	local name, rank, icon, count, type, duration, timeLeft
	if(isDebuff) then
		name, rank, icon, count, type, duration, timeLeft = UnitDebuff(unit, index, filter)
	else
		name, rank, icon, count, duration, timeLeft = UnitBuff(unit, index, filter)
	end

	local buff = self.buffs and self.buffs[index]
	if name then
		if not buff then
			buff = Buff_Create(self, index, isDebuff)
			if(not self.buffs) then self.buffs = {} end
			self.buffs[index] = buff
		end

		--set the icon
		buff.icon:SetTexture(icon)

		--set how many times the current buff has been applied
		if count > 1 then
			buff.count:SetText(count)
			buff.count:Show()
		else
			buff.count:Hide()
		end

		-- Handle cooldowns
		if duration and duration > 0 then
			CooldownFrame_SetTimer(buff.cooldown, GetTime()-(duration-timeLeft), duration, 1)
			buff.cooldown:Show()
		else
			buff.cooldown:Hide()
		end

		--set the debuff border color
		if(isDebuff) then
			local color = DebuffTypeColor[type or "none"]
			buff:SetBackdropColor(color.r, color.g, color.b)
			-- buff.border:SetVertexColor(color.r, color.g, color.b)
		end

		buff:Show()
		return true
	elseif buff then
		buff:Hide()
	end
end

--update all buff icons, then layout the frame
local function BuffFrame_Update(self)
	local unit = self.id
	local isDebuff = self.isDebuff

	local filter
	if(UnitIsFriend("player", unit)) then
		local sets = Sage:GetFrameSets(unit)
		if(isDebuff) then
			filter = sets and sets.showCurable
		else
			filter = sets and sets.showCastable
		end
	end

	local count = 0
	while self:UpdateBuff(unit, count+1, filter, isDebuff) do
		count = count + 1
	end

	local prevCount = self.count or 0
	if(prevCount ~= count) then
		self.count = count
		local buffs = self.buffs
		for i = count+1, prevCount do
			buffs[i]:Hide()
		end
		self:Layout(self.count)
	end
end

--layout buffs in the frame
local function BuffFrame_LayoutIcons(self)
	local count = self.count or 0
	local width = ceil(self:GetWidth())
	local height = ceil(self:GetHeight())
	local size = 36
	local scale = min(width, height) / size

	local rows = 1
	while size * scale  * count / rows > width do
		scale = scale - 0.01
		rows = height / (size * scale)
	end
	local cols = ceil(count / rows)
	rows = floor(rows)
	-- size = size * scale

	local buffs = self.buffs
	for row = 0, rows-1 do
		for col = 0, cols-1 do
			local index = (col+1) + row*cols
			if(index <= count) then
				local buff = buffs[index]
				buff:ClearAllPoints()
				buff:SetScale(scale)
				buff:SetPoint("TOPLEFT", self, "TOPLEFT", (size * col), -(size * row))
			else return end
		end
	end
end

local function BuffFrame_OnShow(self) self:Update() end


--[[ Usable Functions ]]--

SageBuff = {}

function SageBuff:Create(parent, id, Layout, isDebuff)
	local frame = CreateFrame("Frame", nil, parent)
	local id = id or parent.id

	frame.id = id
	frame.isDebuff = isDebuff

	frame.LayoutIcons = BuffFrame_LayoutIcons
	frame.Layout = Layout or BuffFrame_LayoutIcons
	frame.Update = BuffFrame_Update
	frame.UpdateBuff = BuffFrame_UpdateBuff
	frame:SetScript("OnShow", BuffFrame_OnShow)

	if(isDebuff) then
		if(not self.debuffFrames) then self.debuffFrames = {} end
		self.debuffFrames[id] = frame
	else
		if(not self.buffFrames) then self.buffFrames = {} end
		self.buffFrames[id] = frame
	end
	parent:Attach(frame)

	return frame
end

function SageBuff:OnEvent(unit)
	local buffFrame = self:Get(unit)
	if(buffFrame and buffFrame:IsVisible()) then
		buffFrame:Update()
	end

	local debuffFrame = self:Get(unit, true)
	if(debuffFrame and debuffFrame:IsVisible()) then
		debuffFrame:Update()
	end
end

function SageBuff:Get(unit, isDebuff)
	if(isDebuff) then
		return self.debuffFrames and self.debuffFrames[unit]
	end
	return self.buffFrames and self.buffFrames[unit]
end