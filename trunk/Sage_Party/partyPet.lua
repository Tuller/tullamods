SagePartyPet = CreateFrame('Button')
local Frame_mt = {__index = SagePartyPet}

local frames = {}

local function OnEnter() this:OnEnter() end
local function OnLeave() this:OnLeave() end

function SagePartyPet.Create(parent)
	local frame = CreateFrame('Button', nil, parent, 'SecureUnitButtonTemplate')
	frame.id = 'partypet' .. parent.id:match('%d')
	frame:Hide()

	setmetatable(frame, Frame_mt)

	frame:SetAlpha(parent:GetAlpha())
	frame:SetFrameLevel(0)
	frame:RegisterForClicks("anyUp")
	SecureUnitButton_OnLoad(frame, frame.id)

	frame.health = SageHealth.Create(frame)
	frame.health:SetAllPoints(frame)
	
	frame:SetScript('OnEnter', OnEnter)
	frame:SetScript('OnLeave', OnLeave)
	
	frames[frame.id] = frame
	
	return frame
end

function SagePartyPet:OnEnter()
	if SpellIsTargeting() then
		if SpellCanTargetUnit(self.id) then
			SetCursor("CAST_CURSOR")
		else
			SetCursor("CAST_ERROR_CURSOR")
		end
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	if GameTooltip:SetUnit(self.id) then
		self.updateTooltip = TOOLTIP_UPDATE_TIME
	else
		self.updateTooltip = nil
	end
	GameTooltipTextLeft1:SetTextColor(GameTooltip_UnitColor(self.id))
	
	self.health:ShowText(true)
end

function SagePartyPet:OnLeave()
	if SpellIsTargeting() then
		SetCursor("CAST_ERROR_CURSOR")
	end

	GameTooltip:Hide()
	this.updateTooltip = nil
	
	if not Sage.ShowingText() then
		self.health:ShowText(nil)
	end
end