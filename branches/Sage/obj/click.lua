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
	frame.unit = id or parent.id

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
	UnitFrame_OnEnter()
	SageBar:UpdateText(self.unit, true)
end

--hide tooltip, and text if its not always shown
function SageClick:OnLeave()
	UnitFrame_OnLeave()
	SageBar:UpdateText(self.unit, false)
end

--credit goes to agUF for this function
function SageClick:ShowMenu()
	local unit = self:GetAttribute("unit")
	local menu
	
	if unit == "player" then
		menu = PlayerFrameDropDown
	elseif unit == "target" then
		menu = TargetFrameDropDown
	elseif unit == "pet" then
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