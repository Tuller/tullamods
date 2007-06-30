--[[
	A general options panel
--]]

local L = BONGOS_LOCALS
L.General = "General"
L.SetLock = "Lock Bars"
L.SetSticky = "Enable Sticky Bars"
L.ShowMinimap = "Show Minimap Button"

function BongosOptions:AddGeneralPanel()
	local panel = self:AddPanel(L.General)

	local lock = panel:AddCheckButton(L.SetLock)
	lock:SetScript("OnShow", function(self) self:SetChecked(Bongos:IsLocked()) end)
	lock:SetScript("OnClick", function(self) Bongos:SetLock(self:GetChecked()) end)

	local sticky = panel:AddCheckButton(L.SetSticky)
	sticky:SetScript("OnShow", function(self) self:SetChecked(Bongos:IsSticky()) end)
	sticky:SetScript("OnClick", function(self) Bongos:SetSticky(self:GetChecked()) end)
	
	local minmap = panel:AddCheckButton(L.ShowMinimap)
	minmap:SetScript("OnShow", function(self) self:SetChecked(Bongos:ShowingMinimap()) end)
	minmap:SetScript("OnClick", function(self) Bongos:SetShowMinimap(self:GetChecked()) end)
	
	local opacity = panel:AddSlider(L.Opacity, 0, 100, 1)
	opacity:SetScript("OnShow", function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	opacity:SetScript("OnValueChanged", function(self, value)
		if not self.onShow then
			BBar:ForAll("SetFrameAlpha", self:GetValue()/100)
		end
		self.text:SetText(value)
	end)
	
	local scale = panel:AddSlider(L.Scale, 50, 150, 1)
	scale:SetScript("OnShow", function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	scale:SetScript("OnValueChanged", function(self, value)
		if not self.onShow then
			BBar:ForAll("SetFrameScale", self:GetValue()/100)
		end
		self.text:SetText(value)
	end)
	
	return panel
end

BongosOptions:AddGeneralPanel()