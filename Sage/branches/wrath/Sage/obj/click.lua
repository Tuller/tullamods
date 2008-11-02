--[[
	ClickFrame
		The portion of a Sage frame that responds to mouseover events
--]]

local ClickFrame = Sage:CreateClass('Button')
Sage.Click = ClickFrame

local id = 1
function ClickFrame:New(parent)
	local f = self:Bind(CreateFrame('Button', 'SageClick' .. id, parent, 'SecureUnitButtonTemplate'))
	f:UpdateUnit()

	SecureUnitButton_OnLoad(f, parent:GetAttribute('unit'), function() f:ShowMenu() end)

	--support for click casting mods that use the clique standard
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[f] = true

	f:RegisterForClicks('anyUp')
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)

	id = id + 1
	return f
end

--show tooltip, show text if its not always shown
function ClickFrame:OnEnter()
	UnitFrame_OnEnter(self)
	Sage.StatusBar:OnFrameEnter(self:GetParent():GetAttribute('unit'))
end

--hide tooltip, and text if its not always shown
function ClickFrame:OnLeave()
	UnitFrame_OnLeave(self)
	Sage.StatusBar:OnFrameLeave(self:GetParent():GetAttribute('unit'))
end

--credit goes to agUF for this function
function ClickFrame:ShowMenu()
	local unit = self:GetParent():GetAttribute('unit')
	local menu

	if unit == 'player' then
		menu = _G['PlayerFrameDropDown']
	elseif unit == 'target' then
		menu = _G['TargetFrameDropDown']
	elseif unit == 'focus' then
		menu = _G['FocusFrameDropDown']
	elseif unit == 'pet' then
		menu = _G['PetFrameDropDown']
	else
		local id = unit:match('party(%d+)')
		menu = id and _G['PartyMemberFrame' .. id .. 'DropDown']
	end

	--magic numbers evil
	if menu then
		HideDropDownMenu(1)
		ToggleDropDownMenu(1, nil, menu, 'cursor')
	end
end