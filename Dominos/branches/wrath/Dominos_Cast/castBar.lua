--[[
	A Dominos based cast bar
--]]

local DCB = Dominos:NewModule('CastingBar')
local CastBar, CastingBar

function DCB:Load()
	self.frame = CastBar:New()
end

function DCB:Unload()
	self.frame:Free()
end


--[[ Dominos Frame Object ]]--

CastBar = Dominos:CreateClass('Frame', Dominos.Frame)

function CastBar:New()
	local f = self.super.New(self, 'cast')
	if not f.cast then
		f.cast = CastingBar:New(f)
		f.header:SetParent(nil)
		f.header:ClearAllPoints()
		f:SetWidth(240); f:SetHeight(24)
	end

	f:UpdateText()
	f:Layout()

	return f
end

function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		showText = true,
	}
end

function CastBar:ToggleText(enable)
	self.sets.showText = enable or nil
	self:UpdateText()
end

function CastBar:UpdateText()
	if self.sets.showText then
		self.cast.time:Show()
	else
		self.cast.time:Hide()
	end
	self.cast:AdjustWidth()
end

function CastBar:CreateMenu()
	local menu = Dominos.Menu:New(self.id)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)

	local time = panel:NewCheckButton(Dominos_SHOW_TIME)
	time:SetScript('OnClick', function(b) self:ToggleText(b:GetChecked()) end)
	time:SetScript('OnShow', function(b) b:SetChecked(self.sets.showText) end)

	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewScaleSlider()
	panel:NewPaddingSlider()

	self.menu = menu
end

function CastBar:Layout()
	self:SetWidth(self.cast:GetWidth() + 4 + self:GetPadding()*2)
	self:SetHeight(24 + self:GetPadding()*2)
end


--[[ CastingBar Object ]]--

CastingBar = Dominos:CreateClass('StatusBar')

--omg speed
local BORDER_SCALE = 197/150 --its magic!
local min = math.min
local max = math.max
local GetTime = GetTime
local CASTING_BAR_FLASH_STEP = CASTING_BAR_FLASH_STEP
local CASTING_BAR_ALPHA_STEP = CASTING_BAR_ALPHA_STEP

function CastingBar:New(parent)
	local f = self:Bind(CreateFrame('StatusBar', 'DominosCastingBar', parent, 'DominosCastingBarTemplate'))
	f:SetPoint('CENTER')

	local name = f:GetName()

	local _G = getfenv(0)
	f.sparkTexture = _G[name .. 'Spark']
	f.flashTexture = _G[name .. 'Flash']
	f.borderTexture = _G[name .. 'Border']
	f.time = _G[name .. 'Time']
	f.text = _G[name .. 'Text']

	f.normalWidth = f:GetWidth()
	f:SetScript('OnUpdate', f.OnUpdate)
	f:SetScript('OnEvent', f.OnEvent)

	return f
end

function CastingBar:OnEvent(event, ...)
	local unit, spell = ...
	if unit == self.unit then
		if event == 'UNIT_SPELLCAST_FAILED' or event == 'UNIT_SPELLCAST_INTERRUPTED' then
			self.failed = true
		elseif event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START' then
			self.failed = nil
		end
		CastingBarFrame_OnEvent(event, ...)
		self:UpdateColor(spell)
	end
end

function CastingBar:OnUpdate(elapsed)
	local barSpark = self.sparkTexture
	local barFlash = self.flashTexture
	local barTime = self.time

	if self.casting then
		local status = min(GetTime(), self.maxValue)
		if status == self.maxValue then
			self:SetValue(self.maxValue)
			barSpark:Hide()
			barFlash:SetAlpha(0)
			barFlash:Show()
			self.casting = nil
			self.flash = 1
			self.fadeOut = 1
			return
		end

		self:SetValue(status)
		barFlash:Hide()

		local sparkPosition = ((status - self.startTime) / (self.maxValue - self.startTime)) * self:GetWidth()
		if sparkPosition < 0 then
			sparkPosition = 0
		end

		barSpark:SetPoint('CENTER', self, 'LEFT', sparkPosition, 0)

		--time display
		barTime:SetFormattedText('%.1f', self.maxValue - status)
		self:AdjustWidth()
	elseif self.channeling then
		local time = min(GetTime(), self.endTime)
		if time == self.endTime then
			barSpark:Hide()
			barFlash:SetAlpha(0)
			barFlash:Show()
			self.channeling = nil
			self.flash = 1
			self.fadeOut = 1
			return
		end

		local barValue = self.startTime + (self.endTime - time)
		self:SetValue(barValue)
		barFlash:Hide()

		local sparkPosition = ((barValue - self.startTime) / (self.endTime - self.startTime)) * self:GetWidth()
		barSpark:SetPoint('CENTER', self, 'LEFT', sparkPosition, 0)

		--time display
		barTime:SetFormattedText('%.1f', self.endTime - time)
		self:AdjustWidth()
	elseif GetTime() < self.holdTime then
		return
	elseif self.flash then
		local alpha = barFlash:GetAlpha() + CASTING_BAR_FLASH_STEP
		if alpha < 1 then
			barFlash:SetAlpha(alpha)
		else
			barFlash:SetAlpha(1)
			self.flash = nil
		end
	elseif self.fadeOut then
		local alpha = self:GetAlpha() - CASTING_BAR_ALPHA_STEP
		if alpha > 0 then
			self:SetAlpha(alpha)
		else
			self.fadeOut = nil
			self:Hide()
		end
	end
end

function CastingBar:AdjustWidth()
	local textWidth = self.text:GetStringWidth()
	local timeWidth = (self.time:IsShown() and (self.time:GetStringWidth() + 8) * 2) or 0
	local width = textWidth + timeWidth

	local diff = width - self.normalWidth
	if diff > 0 then
		diff = width - self:GetWidth()
	else
		diff = self.normalWidth - self:GetWidth()
	end

	if diff ~= 0 then
		local newWidth = self:GetWidth() + diff
		self:SetWidth(newWidth)
		self.borderTexture:SetWidth(newWidth * BORDER_SCALE)
		self.flashTexture:SetWidth(newWidth * BORDER_SCALE)

		self:GetParent():Layout()
	end
end

function CastingBar:UpdateColor(spell)
	if self.failed then
		self:SetStatusBarColor(0.86, 0.08, 0.24)
	elseif spell and IsHelpfulSpell(spell) then
		self:SetStatusBarColor(0.31, 0.78, 0.47)
	elseif spell and IsHarmfulSpell(spell) then
		self:SetStatusBarColor(0.63, 0.36, 0.94)
	else
		self:SetStatusBarColor(1, 0.7, 0)
	end
end

--hide the old casting bar
CastingBarFrame:UnregisterAllEvents()
CastingBarFrame:Hide()