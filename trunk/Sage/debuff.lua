--[[
	Sage\buff.lua
		Functions for buff and debuff frames and icons

	Notes:
		Debuff curing code will most likely not work in WoW 2.0
--]]

SageDebuff = CreateFrame('Frame')
local Frame_mt = {__index = SageDebuff}
local frames = {}


--[[ debuff ]]--

local function Debuff_OnEnter()
	local unitFrame = this:GetParent():GetParent()
	local sets = unitFrame.sets
	local unit = unitFrame.id

	local showCurable
	if sets and sets.showCurable and UnitIsFriend("player", unit) then
		showCurable = 1
	end

	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitDebuff(unit, this:GetID(), showCurable)
end

local function Debuff_OnLeave() 
	GameTooltip:Hide() 
end

local function Debuff_Create(parent, id)
	local debuff = CreateFrame("Frame", nil, parent)
	debuff:EnableMouse(true)
	debuff:SetAlpha(parent:GetAlpha())
	debuff:SetID(id)

	debuff.icon = debuff:CreateTexture(nil, "ARTWORK")
	debuff.icon:SetTexCoord(0.06,0.94,0.06,0.94)
	debuff.icon:SetAllPoints(debuff)

	debuff.border = debuff:CreateTexture(nil, "OVERLAY")
	debuff.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
	debuff.border:SetPoint("TOPLEFT", debuff, "TOPLEFT", -1, 1)
	debuff.border:SetPoint("BOTTOMRIGHT", debuff, "BOTTOMRIGHT", 1, -1)
	debuff.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)

	debuff.count = debuff:CreateFontString(nil, "OVERLAY")
	debuff.count:SetFontObject(SageFontSmall)
	debuff.count:SetPoint("BOTTOMRIGHT", debuff, "BOTTOMRIGHT", -1, 0)

	debuff:SetScript("OnEnter", Debuff_OnEnter)
	debuff:SetScript("OnLeave", Debuff_OnLeave)
	
	parent[id] = debuff

	return debuff
end

local function UpdateDebuff(frame, unit, index, curable)
	local name, rank, icon, count, type = UnitDebuff(unit, index, curable)
	local debuff = frame[index]

	if name then
		if not debuff then
			debuff = Debuff_Create(frame, index)
		end

		--set debuff icon
		debuff.icon:SetTexture(icon)

		--set how many times the current buff has been applied
		if count > 1 then
			debuff.count:SetText(count)
			debuff.count:Show()
		else
			debuff.count:Hide()
		end

		--set the debuff border icon
		local color = DebuffTypeColor[type or 'none']
		debuff.border:SetVertexColor(color.r, color.g, color.b)
		debuff:Show()
		
		return true
	end

	if debuff then debuff:Hide() end
end

local function OnShow() this:Update() end

--[[ Usable Functions ]]--

function SageDebuff.Create(parent, Layout, id)
	local frame = CreateFrame("Frame", nil, parent)
	setmetatable(frame, Frame_mt)
	
	frame.id = id or parent.id
	frame.Layout = Layout
	frames[frame.id] = frame

	frame:SetAlpha(parent:GetAlpha())
	frame:SetScript("OnShow", OnShow)

	return frame
end

function SageDebuff:Update()
	local unit = self.id

	local showCurable
	if UnitIsFriend("player", unit) then
		local sets = Sage.GetFrameSets(unit)
		if sets then
			showCurable = sets.showCurable
		end
	end

	local i = 1
	local count = 0
	while UpdateDebuff(self, unit, i, showCurable) do
		count = count + 1
		i = i + 1
	end

	i = i + 1
	local debuff
	repeat
		debuff = self[i]
		if debuff then
			debuff:Hide()
			i = i + 1
		end
	until not debuff

	self:Layout(count)
end

SageDebuff.LayoutIcons = SageBuff.LayoutIcons

function SageDebuff.Get(unit) 
	return frames[unit]
end