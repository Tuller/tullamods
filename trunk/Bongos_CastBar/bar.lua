--[[
	BCastBar
		A Bongos based cast bar
--]]

local function AdjustWidth(castingBar)
	local castingBarName = castingBar:GetName()
	local textWidth = getglobal(castingBarName .. "Text"):GetStringWidth()

	local time = getglobal(castingBarName .. "Time")
	if time:IsShown() then
		textWidth = textWidth + 64
	end

	local diff = textWidth - castingBar.normalWidth
	if diff > 0 then
		diff = textWidth - castingBar:GetWidth()
	else
		diff = castingBar.normalWidth - castingBar:GetWidth()
	end

	if diff ~= 0 then
		castingBar:GetParent():SetWidth(castingBar:GetParent():GetWidth() + diff)
		castingBar:SetWidth(castingBar:GetWidth() + diff)
	end
end

local function CastingBar_OnUpdate()
	local barSpark = getglobal(this:GetName().."Spark")
	local barFlash = getglobal(this:GetName().."Flash")
	local barTime = getglobal(this:GetName().."Time")

	if this.casting then
		local status = GetTime()
		if status > this.maxValue then
			status = this.maxValue
		end
		if status == this.maxValue then
			this:SetValue(this.maxValue)
			this:SetStatusBarColor(0.0, 1.0, 0.0)
			barSpark:Hide()
			barFlash:SetAlpha(0)
			barFlash:Show()
			this.casting = nil
			this.flash = 1
			this.fadeOut = 1
			return
		end
		this:SetValue(status)
		barFlash:Hide()
		local sparkPosition = ((status - this.startTime) / (this.maxValue - this.startTime)) * this:GetWidth()
		if sparkPosition < 0 then
			sparkPosition = 0
		end
		barSpark:SetPoint("CENTER", this, "LEFT", sparkPosition, 2)

		--time display
		barTime:SetText(format("%.1f", this.maxValue - status))
		AdjustWidth(this)
	elseif this.channeling then
		local time = GetTime()
		if time > this.endTime then
			time = this.endTime
		end
		if time == this.endTime then
			this:SetStatusBarColor(0.0, 1.0, 0.0)
			barSpark:Hide()
			barFlash:SetAlpha(0)
			barFlash:Show()
			this.channeling = nil
			this.flash = 1
			this.fadeOut = 1
			return
		end
		local barValue = this.startTime + (this.endTime - time)
		this:SetValue(barValue)
		barFlash:Hide()
		local sparkPosition = ((barValue - this.startTime) / (this.endTime - this.startTime)) * this:GetWidth()
		barSpark:SetPoint("CENTER", this, "LEFT", sparkPosition, 2)

		--time display
		barTime:SetText(format("%.1f", this.endTime - time))
		AdjustWidth(this)
	elseif GetTime() < this.holdTime then
		return
	elseif this.flash then
		local alpha = barFlash:GetAlpha() + CASTING_BAR_FLASH_STEP
		if alpha < 1 then
			barFlash:SetAlpha(alpha)
		else
			barFlash:SetAlpha(1)
			this.flash = nil
		end
	elseif this.fadeOut then
		local alpha = this:GetAlpha() - CASTING_BAR_ALPHA_STEP
		if alpha > 0 then
			this:SetAlpha(alpha)
		else
			this.fadeOut = nil
			this:Hide()
		end
	end
end


--[[ CastingBar Constructor ]]--

local function CastingBar_Create(parent)
	local bar = CreateFrame("StatusBar", "BongosCastBar", parent, "BongosCastingBarTemplate")
	bar.normalWidth = bar:GetWidth()

	bar:SetScript('OnUpdate', CastingBar_OnUpdate)

	return bar
end


--[[ Config Functions ]]--

local function ToggleText(self, enable)
	local castingBar = self.castBar

	if enable then
		getglobal(castingBar:GetName() .. "Time"):Show()
		self.sets.showText = 1
	else
		getglobal(castingBar:GetName() .. "Time"):Hide()
		self.sets.showText = nil
	end

	AdjustWidth(castingBar)
end

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText("Cast Bar")
	menu:SetWidth(220)
	menu:SetHeight(160)

	--checkbuttons
	local time = CreateFrame("CheckButton", name .. "Time", menu, "GooeyCheckButton")
	time:SetScript("OnClick", function() ToggleText(frame, this:GetChecked()) end)
	time:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -28)
	time:SetText(BONGOS_CASTBAR_SHOW_TIME)

	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)
	
	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosCastBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1
	
	getglobal(name .. 'Time'):SetChecked(self.sets.showText)

	self:DisplayMenu(menu)

	menu.onShow = nil
end


--[[ Startup ]]--

local function OnCreate(self)
	CastingBarFrame:UnregisterAllEvents()
	CastingBarFrame:Hide()

	self.ShowMenu = ShowMenu
	self.castBar = CastingBar_Create(self)
	self.castBar:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -2)
	self:Attach(self.castBar)

	self:SetWidth(207)
	self:SetHeight(24)
end

Bongos.AddVarInit(function()
	if not Bongos.GetBarSets('cast') then
		Bongos.SetBarSets('cast', {
			["y"] = 626.2285902168067,
			["x"] = 635.2570629826626,
			["showText"] = 1,
			["vis"] = 1,
		})
	end
end)

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('cast') then
		Bongos.SetBarSets('cast', {x = 635.257, y = 626.229, showText = 1, vis = 1})
	end
	
	local bar = BBar.Create('cast', OnCreate)
	ToggleText(bar, bar.sets.showText)
end)