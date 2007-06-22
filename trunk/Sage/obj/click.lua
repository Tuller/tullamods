--[[
	SageClick
		The clickable portion of a SageFrame
--]]

SageClick = CreateFrame("Button")
local Frame_mt = {__index = SageClick}

local function Frame_OnEnter(self) self:OnEnter() end
local function Frame_OnLeave(self) self:OnLeave() end

function SageClick:Create(parent, id)
	local frame = CreateFrame("Button", format("SageClick%s", id or parent.id), parent, "SecureUnitButtonTemplate")
	setmetatable(frame, Frame_mt)

	SecureUnitButton_OnLoad(frame, id or parent.id, function() frame:ShowMenu() end)
	--support for click casting mods that use the clique standard
	ClickCastFrames = ClickCastFrames or {}
    ClickCastFrames[frame] = true

	frame:RegisterForClicks("anyUp")
	frame:SetScript("OnEnter", Frame_OnEnter)
	frame:SetScript("OnLeave", Frame_OnLeave)

	return frame
end

--show tooltip, show text if its not always shown
function SageClick:OnEnter()
	self:GetParent().entered = true
	local unit = self:GetAttribute("unit")

	if SpellIsTargeting() then
		if SpellCanTargetUnit(unit) then
			SetCursor("CAST_CURSOR")
		else
			SetCursor("CAST_ERROR_CURSOR")
		end
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	if GameTooltip:SetUnit(unit) then
		self.updateTooltip = TOOLTIP_UPDATE_TIME
	else
		self.updateTooltip = nil
	end
	GameTooltipTextLeft1:SetTextColor(GameTooltip_UnitColor(unit))

	SageBar:UpdateAllText(unit, true)
end

--hide tooltip, and text if its not always shown
function SageClick:OnLeave()
	self:GetParent().entered = nil
		
	if SpellIsTargeting() then
		SetCursor("CAST_ERROR_CURSOR")
	end

	GameTooltip:Hide()
	self.updateTooltip = nil

	SageBar:UpdateAllText(self:GetAttribute("unit"), Sage:ShowingText())
end

--credit goes to agUF for this function
function SageClick:ShowMenu()
	local unit = self:GetAttribute("unit")
	local menu

	if "player" then
		menu = PlayerFrameDropDown
	elseif "target" then
		menu = TargetFrameDropDown
	elseif "pet" then
		menu = PetFrameDropDown
	else
		local partyID = unit:match("party(%d)")
		if partyID then
			menu = getglobal(format("PartyMemberFrame%sDropDown", partyID))
		end
	end

	if menu then
		HideDropDownMenu(1)
		ToggleDropDownMenu(1, nil, menu, "cursor")
	end
end