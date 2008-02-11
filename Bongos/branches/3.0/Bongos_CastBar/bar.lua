--[[
	BCastBar
		A Bongos based cast bar
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local CastBar = Bongos:NewModule('CastBar')
local CastingBar = Bongos:CreateWidgetClass('StatusBar')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-CastBar')

function CastBar:Load()
	local bar, isNew = Bongos.Bar:Create('cast', {showText = true, x = 618, y = 617}, false, 'HIGH')
	if isNew then
		self:OnBarCreate(bar)
	end
	bar:ToggleText(bar.sets.showText)

	self.bar = bar
end

function CastBar:Unload()
	self.bar:Destroy()
end

--[[ Bongos Bar Methods ]]--

function CastBar:OnBarCreate(bar)
	bar.ToggleText = function(self, enable)
		self.sets.showText = enable or nil
		if enable then
			getglobal(self.castBar:GetName() .. 'Time'):Show()
		else
			getglobal(self.castBar:GetName() .. 'Time'):Hide()
		end
		self.castBar:AdjustWidth()
	end

	bar.CreateMenu = function(self)
		local menu = Bongos.Menu:Create(self.id)
		local panel = menu:AddLayoutPanel()

		--checkbuttons
		local time = panel:CreateCheckButton(L.ShowTime)
		time:SetScript('OnClick', function(b) self:ToggleText(b:GetChecked()) end)
		time:SetScript('OnShow', function(b) b:SetChecked(self.sets.showText) end)

		return menu
	end
	
	CastingBarFrame:UnregisterAllEvents()
	CastingBarFrame:Hide()
	
	bar.castBar = CastingBar:Create(bar)
	bar.castBar:SetPoint('CENTER')
	bar:Attach(bar.castBar)

	bar:SetWidth(bar.castBar:GetWidth() + 4)
	bar:SetHeight(24)
end


--[[ CastingBar Stuff ]]--

local BORDER_SCALE = 197/150 --its magic!

function CastingBar:Create(parent)
	local _G = getfenv(0)
	local bar = self:New(CreateFrame('StatusBar', 'BongosCastBar', parent, 'BongosCastingBarTemplate'))
	local name = bar:GetName()

	bar.sparkTexture = _G[name .. 'Spark']
	bar.flashTexture = _G[name .. 'Flash']
	bar.borderTexture = _G[name .. 'Border']
	bar.time = _G[name .. 'Time']
	bar.text = _G[name .. 'Text']

	bar.normalWidth = bar:GetWidth()
	bar.AdjustWidth = CastingBar_AdjustWidth

	bar:SetScript('OnUpdate', self.OnUpdate)
	bar:SetScript('OnEvent', self.OnEvent)

	return bar
end

function CastingBar:OnEvent(event, ...)
	local unit, spell = ...
	if unit == "player" then
		if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
			self.failed = true
		elseif event == "UNIT_SPELLCAST_START" then
			self.failed = nil
		end
		CastingBarFrame_OnEvent(event, ...)
		self:UpdateColor(spell)
	end
end

function CastingBar:OnUpdate(elapsed)
	local name = self:GetName()
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
	local name = self:GetName()
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
		self:GetParent():SetWidth(self:GetParent():GetWidth() + diff)

		local newWidth = self:GetWidth() + diff
		self:SetWidth(newWidth)
		self.borderTexture:SetWidth(newWidth * BORDER_SCALE)
		self.flashTexture:SetWidth(newWidth * BORDER_SCALE)
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