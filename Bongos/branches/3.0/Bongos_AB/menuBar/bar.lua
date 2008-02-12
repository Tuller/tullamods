--[[
	BMenuBar
		A movable bar for the micro buttons
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Menu = Bongos:NewModule('MenuBar')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB')

local DEFAULT_SPACING = 2
local DEFAULT_ROWS = 1
local buttons = {
	CharacterMicroButton,
	SpellbookMicroButton,
	TalentMicroButton,
	QuestLogMicroButton,
	SocialsMicroButton,
	LFGMicroButton,
	MainMenuMicroButton,
	HelpMicroButton
}


--[[ Bar Functions ]]--

local Bar = {}

function Bar:CreateMenu()
	local menu = Bongos.Menu:Create(self.id)
	local panel = menu:AddLayoutPanel()

	local vertical = panel:CreateCheckButton(L.Vertical)
	vertical:SetScript('OnShow', function(b) b:SetChecked(self.sets.rows) end)
	vertical:SetScript('OnClick', function(b) self:SetVertical(b:GetChecked()) end)

	panel:CreateSpacingSlider()

	return menu
end

function Bar:Layout(rows, spacing)
	rows = (rows or self.sets.rows or DEFAULT_ROWS)
	if rows == DEFAULT_ROWS then
		self.sets.rows = nil
	else
		self.sets.rows = rows
	end

	spacing = (spacing or self.sets.spacing or DEFAULT_SPACING)
	if spacing == DEFAULT_SPACING then
		self.sets.spacing = nil
	else
		self.sets.spacing = spacing
	end

	for _,button in pairs(buttons) do button:ClearAllPoints() end
	buttons[1]:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 20)

	local actspacing = spacing
	if rows == DEFAULT_ROWS then
		--horizontal layout
		spacing = spacing - 4 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint('LEFT', buttons[i-1], 'RIGHT', spacing, 0)
		end

		self:SetHeight(39)
		self:SetWidth(14 + (24 + actspacing) * #buttons - actspacing)
	else
		--vertical layoute
		spacing = spacing - 24 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint('TOP', buttons[i-1], 'BOTTOM', 0, -spacing)
		end

		self:SetHeight(12 + (33 + actspacing) * #buttons - actspacing)
		self:SetWidth(28)
	end
end

function Bar:SetSpacing(spacing)
	self:Layout(nil, spacing)
end

function Bar:GetSpacing()
	return self.sets.spacing or DEFAULT_SPACING
end

function Bar:SetVertical(enable)
	self:Layout(enable and 5 or 1)
end


--[[ Startup ]]--

function Menu:Load()
	local defaults = {
		point = 'BOTTOMRIGHT',
		x = -230,
		y = 0,
	}

	local bar, isNew = Bongos.Bar:Create('menu', defaults)
	if isNew then
		self:OnBarCreate(bar)
	end
	self.bar = bar

	--hack to make sure all the buttons are shown properly
	if bar:IsShown() then
		bar:Hide()
		bar:Show()
	end
	bar:Layout()
end

function Menu:OnBarCreate(bar)
	for k,v in pairs(Bar) do
		bar[k] = v
	end

	for _,button in pairs(buttons) do
		bar:Attach(button)
	end

	--mess with the talent button to make it hide properly, it causes layout issues otherwise
	local function TalentButton_Update(self)
		if UnitLevel('player') < 10 then
			self:Hide()
		elseif Bongos.Bar:Get('menu') then
			self:Show()
		end
	end

	TalentMicroButton:SetScript('OnEvent', function(self, event)
		if event == 'PLAYER_LEVEL_UP' then
			TalentButton_Update(self)
			if not CharacterFrame:IsShown() then
				SetButtonPulse(self, 60, 1)
			end
		elseif event == 'UNIT_LEVEL' or event == 'PLAYER_ENTERING_WORLD' then
			TalentButton_Update(self)
		elseif event == 'UPDATE_BINDINGS' then
			self.tooltipText =  MicroButtonTooltipText(TALENTS_BUTTON, 'TOGGLETALENTS')
		end
	end)
end

function Menu:Unload()
	self.bar:Destroy()
end