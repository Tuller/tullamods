--[[
	ClickFrame
		The portion of a Sage frame that responds to mouseover events
--]]

local ClickFrame = Sage:CreateClass('Button')
Sage.ClickFrame = ClickFrame

function ClickFrame:New(parent)
	local f = self:Bind(CreateFrame('Button', parent:GetName() .. 'Click', parent, 'SecureUnitButtonTemplate'))
	f:SetScript('OnAttributeChanged', self.OnAttributeChanged)
	f:SetAttribute('_childupdate-unit', [[ self:SetAttribute('unit', message) ]])
	SecureUnitButton_OnLoad(f, parent:GetAttribute('unit'), function() f:ShowMenu() end)

	--support for click casting mods that use the clique standard
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[f] = true

	f:RegisterForClicks('anyUp')
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)

	return f
end

function ClickFrame:OnAttributeChanged()
	self.unit = self:GetAttribute('unit')

	if GameTooltip:IsOwned(self) then
		self:OnEnter()
	end
end

--show tooltip, show text if its not always shown
local function callMethodForFrames(method, ...)
	for i = 1, select('#', ...) do
		local f = select(i, ...)
		if f[method] then
			f[method](f)
		end
	end
end

function ClickFrame:OnEnter()
	UnitFrame_OnEnter(self)
	callMethodForFrames('OnParentEnter', self:GetParent():GetChildren())
end

--hide tooltip, and text if its not always shown
function ClickFrame:OnLeave()
	GameTooltip:Hide()
	callMethodForFrames('OnParentLeave', self:GetParent():GetChildren())
end

--credit goes to agUF for this function
function ClickFrame:ShowMenu()
	local unit = self.unit
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