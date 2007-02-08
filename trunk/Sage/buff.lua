--[[
	Sage\buff.lua
		Functions for buff and debuff frames and icons

	Notes:
		Debuff curing code will most likely not work in WoW 2.0
--]]


SageBuff = CreateFrame('Frame')
local Frame_mt = {__index = SageBuff}
local frames = {}


--[[ buff ]]--

local function Buff_OnEnter()
	local unitFrame = this:GetParent():GetParent()
	local sets = unitFrame.sets
	local unit = unitFrame.id

	local showCastable
	if sets and sets.showCastable and UnitIsFriend("player", unit) then
		showCastable = 1
	end

	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitBuff(unit, this:GetID(), showCastable)
end

local function Buff_OnLeave()
	GameTooltip:Hide()
end

local function Buff_Create(parent, id)
	local buff = CreateFrame('Frame', nil, parent)
	buff:EnableMouse(true)
	buff:SetAlpha(parent:GetAlpha())
	buff:SetID(id)

	buff.icon = buff:CreateTexture(nil, "ARTWORK")
	buff.icon:SetTexCoord(0.06,0.94,0.06,0.94)
	buff.icon:SetAllPoints(buff)

	buff.count = buff:CreateFontString(nil, "OVERLAY")
	buff.count:SetFontObject(SageFontSmall)
	buff.count:SetPoint("BOTTOMRIGHT", debuff, "BOTTOMRIGHT", -1, 0)

	buff:SetScript("OnEnter", Buff_OnEnter)
	buff:SetScript("OnLeave", Buff_OnLeave)

	parent[id] = buff

	return buff
end


--[[ Buff Frame ]]--

local function UpdateBuff(frame, unit, index, castable)
	local name, rank, icon, count = UnitBuff(unit, index, castable)
	local buff = frame[index]

	if name then
		if not buff then
			buff = Buff_Create(frame, index)
		end

		--set debuff icon
		buff.icon:SetTexture(icon)

		--set how many times the current buff has been applied
		if count > 1 then
			buff.count:SetText(count)
			buff.count:Show()
		else
			buff.count:Hide()
		end
		buff:Show()
		return true
	end

	if buff then buff:Hide() end
end

local function OnShow() this:Update() end


--[[ Usable Functions ]]--

function SageBuff.Create(parent, Layout, id)
	local frame = CreateFrame('Frame', nil, parent)
	setmetatable(frame, Frame_mt)

	frame.id = id or parent.id
	frame.Layout = Layout

	frames[frame.id] = frame

	frame:SetAlpha(parent:GetAlpha())
	frame:SetScript("OnShow", OnShow)

	return frame
end

function SageBuff:Update()
	local unit = self.id

	local showCastable
	if UnitCanAssist('player', unit) then
		local sets = Sage.GetFrameSets(unit)
		if sets then
			showCastable = sets.showCastable
		end
	end

	local count = 0
	local i = 1
	while UpdateBuff(self, unit, i, showCastable) do
		count = count + 1
		i = i + 1
	end

	i = i + 1
	local buff
	repeat
		buff = self[i]
		if buff then
			buff:Hide()
			i = i + 1
		end
	until not buff

	self:Layout(count)
end

function SageBuff:LayoutIcons(count)
	local width = ceil(self:GetWidth())
	local height = ceil(self:GetHeight())
	local size = min(height, width)
	
	local scale = 1
	local rows = 1
	while size * scale  * count / rows > width do
		scale = scale - 0.01
		rows = height / (size * scale)
	end
	local cols = ceil(count / rows)
	rows = floor(rows)
	size = size * scale
	
	for i = 0, rows - 1 do
		local prev
		for j = 1, cols do
			local buff = self[j + i*cols]
			if buff then
				buff:ClearAllPoints()
				buff:SetWidth(size)
				buff:SetHeight(size)
				if prev then
					buff:SetPoint('TOPLEFT', prev, 'TOPRIGHT')
				else
					buff:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, -i*size)
				end
				prev = buff
			else return end
		end
	end
end

function SageBuff.Get(unit)
	return frames[unit]
end


--[[ Events ]]--

local function UpdateFrames(_, _, unit)
	local buffFrame = SageBuff.Get(unit)
	if buffFrame and buffFrame:IsVisible() then
		buffFrame:Update()
	end

	local debuffFrame = SageDebuff.Get(unit)
	if debuffFrame and debuffFrame:IsVisible() then
		debuffFrame:Update()
	end
end
BVent:AddAction("UNIT_AURA", UpdateFrames)
BVent:AddAction("SAGE_FRAME_WIDTH_UPDATE", UpdateFrames)