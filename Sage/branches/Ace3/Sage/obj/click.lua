--[[
	SageClick
		The clickable portion of a SageFrame
--]]

local ClickFrame = Sage:CreateObjectClass('Button')
Sage.ClickFrame = ClickFrame

function ClickFrame:Create(parent, id)
	local frame = self:New(CreateFrame('Button', 'SageClick' .. (id or parent.id), parent, 'SecureUnitButtonTemplate'))
	frame.unit = id or parent.id

	--menu display
	SecureUnitButton_OnLoad(frame, id or parent.id, function() frame:ShowMenu() end)
	
	--support for click casting mods that use the clique standard
	ClickCastFrames = ClickCastFrames or {}
    ClickCastFrames[frame] = true
	frame:RegisterForClicks('anyUp')

	--on mouseover events
	frame:SetScript('OnEnter', frame.OnEnter)
	frame:SetScript('OnLeave', frame.OnLeave)

	return frame
end

--show tooltip, show text if its not always shown
function ClickFrame:OnEnter()
	UnitFrame_OnEnter(self)
	Sage.StatusBar:ForUnit(self.unit, 'UpdateText', true)
end

--hide tooltip, and text if its not always shown
function ClickFrame:OnLeave()
	UnitFrame_OnLeave(self)
	Sage.StatusBar:ForUnit(self.unit, 'UpdateText', nil)
end

--credit goes to agUF for this function
function ClickFrame:ShowMenu()
	local unit = self:GetAttribute('unit')
	local menu
	
	if unit == 'player' then
		menu = PlayerFrameDropDown
	elseif unit == 'target' then
		menu = TargetFrameDropDown
	elseif unit == 'pet' then
		menu = PetFrameDropDown
	else
		local partyID = unit:match('party(%d)')
		if partyID then
			menu = getglobal(format('PartyMemberFrame%sDropDown', partyID))
		end
	end

	if menu then
		HideDropDownMenu(1)
		ToggleDropDownMenu(1, nil, menu, 'cursor')
	end
end