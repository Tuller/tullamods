--[[
	Dominos
		Because sometimes I feel bad about doing to much
--]]

local menuButtons = {
	CharacterMicroButton,
	SpellbookMicroButton,
	TalentMicroButton,
	AchievementMicroButton,
	QuestLogMicroButton,
	SocialsMicroButton,
	PVPMicroButton,
	LFGMicroButton,
	MainMenuMicroButton,
	HelpMicroButton
}

do
	TalentMicroButton:SetScript('OnEvent', function(self, event)
		if (event == 'PLAYER_LEVEL_UP' or event == 'PLAYER_LOGIN') then
			if UnitCharacterPoints('player') > 0 and not CharacterFrame:IsShown() then
				SetButtonPulse(self, 60, 1)
			end
		elseif event == 'UPDATE_BINDINGS' then
			self.tooltipText =  MicroButtonTooltipText(TALENTS_BUTTON, 'TOGGLETALENTS')
		end
	end)
	TalentMicroButton:UnregisterAllEvents()
	TalentMicroButton:RegisterEvent('PLAYER_LEVEL_UP')
	TalentMicroButton:RegisterEvent('PLAYER_LOGIN')
	TalentMicroButton:RegisterEvent('UPDATE_BINDINGS')
	
	--simialr thing, but the achievement button
	AchievementMicroButton:UnregisterAllEvents()
end


--[[ Menu Bar ]]--

local MenuBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.MenuBar  = MenuBar

function MenuBar:New()
	local f = self.super.New(self, 'menu')
	f.sets.numButtons = #menuButtons --hack of doom
	f:LoadButtons()
	f:Layout()

	return f
end

function MenuBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		x = -244,
		y = 0,
		numButtons = #menuButtons,
	}
end

function MenuBar:AddButton(i)
	local b = menuButtons[i]
	b:SetParent(self.header)
	b:Show()

	self.buttons[i] = b
end

function MenuBar:RemoveButton(i)
	local b = self.buttons[i]
	b:SetParent(nil)
	b:Hide()

	self.buttons[i] = nil
end

--override, because the menu bar has weird button sizes
local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

function MenuBar:Layout()
	if #self.buttons > 0 then
		local cols = min(self:NumColumns(), #self.buttons)
		local rows = ceil(#self.buttons / cols)
		local pW, pH = self:GetPadding()
		local spacing = self:GetSpacing()

		local b = self.buttons[1]
		local w = b:GetWidth() + spacing - WIDTH_OFFSET
		local h = b:GetHeight() + spacing - HEIGHT_OFFSET

		for i,b in pairs(self.buttons) do
			local col = (i-1) % cols
			local row = ceil(i / cols) - 1
			b:ClearAllPoints()
			b:SetPoint('TOPLEFT', w*col + pW, -(h*row + pH) + HEIGHT_OFFSET)
		end

		self:SetWidth(w*cols - spacing + pW*2 + WIDTH_OFFSET)
		self:SetHeight(h*ceil(#self.buttons/cols) - spacing + pH*2)
	else
		self:SetWidth(30); self:SetHeight(30)
	end
end