local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')
local Options = Bongos.Options

--General
--Enable Sticky Bars, Show Minimap Button, Scale, Opacity
--Show Minimap Button
--Scale
--Opacity
function Options:AddGeneralPanel()
	local panel = self:CreatePanel(L.General)
	panel:SetWidth(180); panel:SetHeight(200)
	panel:SetPoint('TOPLEFT', 10, -24)
	
	--show models
	local stickyBars = self:CreateCheckButton(L.EnableStickyBars, panel)
	stickyBars:SetScript('OnShow', function(self) self:SetChecked(Bongos:IsSticky()) end)
	stickyBars:SetScript('OnClick', function(self) Bongos:SetSticky(self:GetChecked()) end)
	stickyBars:SetPoint('TOPLEFT', 10, -8)

	--show cooldown pulse
	local showMinimap = self:CreateCheckButton(L.ShowMinimapButton, panel)
	showMinimap:SetScript('OnShow', function(self) self:SetChecked(Bongos:ShowingMinimap()) end)
	showMinimap:SetScript('OnClick', function(self) Bongos:SetShowMinimap(self:GetChecked()) end)
	showMinimap:SetPoint('TOP', stickyBars, 'BOTTOM')
	
	--minimum scale slider
	local scale = self:CreateSlider(L.Scale, panel, 50, 150, 1)
	scale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	scale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(value)
		if not self.onShow then
			Bongos.Bar:ForBar('all', 'SetFrameScale', value/100)
		end
	end)
	scale:SetPoint('TOPLEFT', showMinimap, 'BOTTOMLEFT', 0, -15)
	
	--minimum scale slider
	local opacity = self:CreateSlider(L.Opacity, panel, 0, 100, 1)
	opacity:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	opacity:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(value)
		if not self.onShow then
			Bongos.Bar:ForBar('all', 'SetFrameAlpha', value/100)
		end
	end)
	opacity:SetPoint('TOPLEFT', scale, 'BOTTOMLEFT', 0, -20)
	
	local faded = self:CreateSlider(L.FadedOpacity, panel, 0, 100, 1)
	faded:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	faded:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(value)
		if not self.onShow then
			Bongos.Bar:ForBar('all', 'SetFadeAlpha', value/100)
		end
	end)
	faded:SetPoint('TOPLEFT', opacity, 'BOTTOMLEFT', 0, -20)

	return panel
end

Options:AddGeneralPanel()