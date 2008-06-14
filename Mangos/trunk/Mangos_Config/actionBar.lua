local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB')
local Options = Mangos.Options


--[[ Panels ]]--

function Options:AddGeneralPanel()
	local panel = self:CreatePanel(LibStub('AceLocale-3.0'):GetLocale('Bongos3').General)
	panel:SetWidth(180); panel:SetHeight(200)
	panel:SetPoint('TOPLEFT', 10, -24)

	--local action bar button positions
	local lockButtons = self:CreateCheckButton(LOCK_ACTIONBAR_TEXT, panel)
	lockButtons:SetScript('OnShow', function(self)
		self:SetChecked(LOCK_ACTIONBAR == '1')
	end)
	lockButtons:SetScript('OnClick', function(self)
		if self:GetChecked() then
			SetCVar('lockActionBars', 1)
			LOCK_ACTIONBAR = '1'
		else
			SetCVar('lockActionBars', 0)
			LOCK_ACTIONBAR = '0'
		end
	end)
	lockButtons:SetPoint('TOPLEFT', 10, -8)

	local rightClickSelfCast = self:CreateCheckButton(L.EnableRightClickSelfCast, panel)
	rightClickSelfCast:SetScript('OnShow', function(self)
		self:SetChecked(Config:GetRightClickUnit() == 'player')
	end)
	rightClickSelfCast:SetScript('OnClick', function(self)
		if self:GetChecked() then
			Config:SetRightClickUnit('player')
		else
			Config:SetRightClickUnit(nil)
		end
	end)
	rightClickSelfCast:SetPoint('TOP', lockButtons, 'BOTTOM')

	local selfCast = self:AddClickActionSelector(L.SelfCastKey, panel, 'SELFCAST')
	selfCast:SetPoint('TOPLEFT', rightClickSelfCast, 'BOTTOMLEFT', -14, -14)

	local quickMove = self:AddClickActionSelector(L.QuickMoveKey, panel, 'PICKUPACTION')
	quickMove:SetPoint('TOP', selfCast, 'BOTTOM', 0, -16)

	return panel
end

function Options:AddDisplayPanel()
	local panel = self:CreatePanel(L.Display)
	panel:SetWidth(180); panel:SetHeight(200)
	panel:SetPoint('TOPRIGHT', -10, -24)

	local showEmpty = self:CreateCheckButton(L.ShowEmptyButtons, panel)
	showEmpty:SetScript('OnShow', function(self)
		self:SetChecked(Config:ShowingEmptyButtons())
	end)
	showEmpty:SetScript('OnClick', function(self)
		Config:ShowEmptyButtons(self:GetChecked())
	end)
	showEmpty:SetPoint('TOPLEFT', 10, -8)

	local showTooltips, inCombat
	do
		showTooltips = self:CreateCheckButton(L.ShowTooltips, panel)
		showTooltips:SetScript('OnShow', function(self)
			self:SetChecked(Config:ShowingTooltips())
		end)
		showTooltips:SetScript('OnClick', function(self)
			Config:ShowTooltips(self:GetChecked())

			if self:GetChecked() then
				inCombat:Enable()
			else
				inCombat:Disable()
			end
		end)
		showTooltips:SetPoint('TOP', showEmpty, 'BOTTOM')

		inCombat = self:CreateCheckButton(L.ShowTipsInCombat, panel)
		inCombat:SetScript('OnShow', function(self)
			self:SetChecked(Config:ShowingTooltipsInCombat())

			if showTooltips:GetChecked() then
				self:Enable()
			else
				self:Disable()
			end
		end)
		inCombat:SetScript('OnClick', function(self)
			Config:ShowTooltipsInCombat(self:GetChecked())
		end)
		inCombat:SetPoint('TOP', showTooltips, 'BOTTOM', 16, 0)
	end

	local showBindings = self:CreateCheckButton(L.ShowBindings, panel)
	showBindings:SetScript('OnShow', function(self)
		self:SetChecked(Config:ShowingHotkeys())
	end)
	showBindings:SetScript('OnClick', function(self)
		Config:ShowHotkeys(self:GetChecked())
	end)
	showBindings:SetPoint('TOP', inCombat, 'BOTTOM', -16, 0)

	local showMacros = self:CreateCheckButton(L.ShowMacros, panel)
	showMacros:SetScript('OnShow', function(self)
		self:SetChecked(Config:ShowingMacros())
	end)
	showMacros:SetScript('OnClick', function(self)
		Config:ShowMacros(self:GetChecked())
	end)
	showMacros:SetPoint('TOP', showBindings, 'BOTTOM')
end

function Options:AddColorPanel()
	local panel = self:CreatePanel(L.Colors)
	panel:SetWidth(367); panel:SetHeight(156)
	panel:SetPoint('BOTTOMLEFT', 10, 10)

	local colorOOR = self:CreateCheckButton(L.ColorOOR, panel)
	colorOOR:SetScript('OnShow', function(self)
		self:SetChecked(Config:ColorOOR())
	end)
	colorOOR:SetScript('OnClick', function(self)
		Config:SetOORColoring(self:GetChecked())
	end)
	colorOOR:SetPoint('TOPLEFT', 10, -8)

	local oorColor = self:CreateColorSelector(L.OORColor, panel)
	oorColor.LoadColor = function(self)
		return Config:GetOORColor()
	end
	oorColor.SaveColor = function(self, r, g, b)
		Config:SetOORColor(r, g, b)
	end
	oorColor:SetPoint('TOP', colorOOR, 'BOTTOM', 12, 0)

	--out of mana coloring
	local oomColor = self:CreateColorSelector(L.OOMColor, panel)
	oomColor.LoadColor = function(self)
		return Config:GetOOMColor()
	end
	oomColor.SaveColor = function(self, r, g, b)
		Config:SetOOMColor(r, g, b)
	end
	oomColor:SetPoint('TOP', oorColor, 'BOTTOM', -12, -14)

	local equipColor = self:CreateColorSelector(L.EquipColor, panel)
	equipColor.LoadColor = function(self)
		return Config:GetEquippedColor()
	end
	equipColor.SaveColor = function(self, r, g, b)
		Config:SetEquippedColor(r, g, b)
	end
	equipColor:SetPoint('TOP', oomColor, 'BOTTOM', 0, -10)

	local highlightBuffs = self:CreateCheckButton(L.HighlightBuffs, panel)
	highlightBuffs:SetScript('OnShow', function(self)
		self:SetChecked(Config:HighlightingBuffs())
	end)
	highlightBuffs:SetScript('OnClick', function(self)
		Config:SetHighlightBuffs(self:GetChecked())
	end)
	highlightBuffs:SetPoint('TOPLEFT', panel, 'TOP', 10, -8)

	local buffColor = self:CreateColorSelector(L.BuffColor, panel)
	buffColor.LoadColor = function(self)
		return Config:GetBuffColor()
	end
	buffColor.SaveColor = function(self, r, g, b)
		Config:SetBuffColor(r, g, b)
	end
	buffColor:SetPoint('TOP', highlightBuffs, 'BOTTOM', 12, 0)

	local debuffColor = self:CreateColorSelector(L.DebuffColor, panel)
	debuffColor.LoadColor = function(self)
		return Config:GetDebuffColor()
	end
	debuffColor.SaveColor = function(self, r, g, b)
		Config:SetDebuffColor(r, g, b)
	end
	debuffColor:SetPoint('TOP', buffColor, 'BOTTOM', 0, -2)
end


--[[ Widget Templates ]]--

local info = {}
local function AddItem(text, value, func, checked, arg1)
	info.text = text
	info.func = func
	info.value = value
	info.checked = checked
	info.arg1 = arg1
	UIDropDownMenu_AddButton(info)
end

function Options:AddClickActionSelector(name, parent, action)
	local dropdown = self:CreateDropdown(name, parent)

	dropdown:SetScript('OnShow', function(self)
		UIDropDownMenu_SetWidth(110, self)
		UIDropDownMenu_Initialize(self, self.Initialize)
		UIDropDownMenu_SetSelectedValue(self, GetModifiedClick(action) or 'NONE')
	end)

	local function Item_OnClick()
		SetModifiedClick(action, this.value)
		UIDropDownMenu_SetSelectedValue(dropdown, this.value)
		SaveBindings(GetCurrentBindingSet())
	end

	function dropdown.Initialize()
		local selected = GetModifiedClick(action) or 'NONE'

		AddItem(ALT_KEY, 'ALT', Item_OnClick, 'ALT' == selected)
		AddItem(CTRL_KEY, 'CTRL', Item_OnClick, 'CTRL' == selected)
		AddItem(SHIFT_KEY, 'SHIFT', Item_OnClick, 'SHIFT' == selected)
		AddItem(NONE_KEY, 'NONE', Item_OnClick, 'NONE' == selected)
	end

	return dropdown
end

Options:AddGeneralPanel()
Options:AddDisplayPanel()
Options:AddColorPanel()