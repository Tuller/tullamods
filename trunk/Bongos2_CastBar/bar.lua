--[[
	BCastBar
		A Bongos based cast bar
--]]

BongosCastBar = Bongos:NewModule("Bongos-CastBar")
local borderScale = 197 / 150

--[[ CastingBar Stuff ]]--

local function CastingBar_AdjustWidth(self)
	local name = self:GetName()
	local textWidth = self.text:GetStringWidth()
	local timeWidth = (self.time:IsShown() and (self.time:GetStringWidth() + 8)*2) or 0
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
		self.borderTexture:SetWidth(newWidth * borderScale)
		self.flashTexture:SetWidth(newWidth * borderScale)
	end
end

local function CastingBar_OnUpdate(self, arg1)
	local name = self:GetName()
	local barSpark = self.sparkTexture
	local barFlash = self.flashTexture
	local barTime = self.time

	if self.casting then
		local status = GetTime()
		if status > self.maxValue then
			status = self.maxValue
		end
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
		barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 0)

		--time display
		barTime:SetText(format("%.1f", self.maxValue - status))
		self:AdjustWidth()
	elseif self.channeling then
		local time = GetTime()
		if time > self.endTime then
			time = self.endTime
		end
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
		barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 0)

		--time display
		barTime:SetText(format("%.1f", self.endTime - time))
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

local function CastingBar_Create(parent)
	local name = "BongosCastBar"
	local bar = CreateFrame("StatusBar", name, parent, "BongosCastingBarTemplate")
	bar.sparkTexture = getglobal(name .. "Spark")
	bar.flashTexture = getglobal(name .. "Flash")
	bar.borderTexture = getglobal(name .. "Border")
	bar.time = getglobal(name .. "Time")
	bar.text = getglobal(name .. "Text")

	bar.normalWidth = bar:GetWidth()
	bar.AdjustWidth = CastingBar_AdjustWidth

	bar:SetScript("OnUpdate", CastingBar_OnUpdate)

	return bar
end


--[[ Bongos Bar Methods ]]--

local function Bar_CreateMenu(self)
	local menu, panel = BongosMenu:CreateMenu(BONGOS_CASTBAR)

	--checkbuttons
	local time = panel:AddCheckButton("Time")
	time:SetScript("OnClick", function(b) self:ToggleText(b:GetChecked()) end)
	time:SetScript("OnShow", function(b) b:SetChecked(self.sets.showText) end)
	time:SetText(BONGOS_CASTBAR_SHOW_TIME)

	return menu
end

local function Bar_ToggleText(self, enable)
	local castingBar = self.castBar
	self.sets.showText = enable or nil
	if enable then
		getglobal(castingBar:GetName() .. "Time"):Show()
	else
		getglobal(castingBar:GetName() .. "Time"):Hide()
	end
	castingBar:AdjustWidth()
end

local function Bar_OnCreate(self)
	CastingBarFrame:UnregisterAllEvents()
	CastingBarFrame:Hide()

	self.CreateMenu = Bar_CreateMenu
	self.ToggleText = Bar_ToggleText

	self.castBar = CastingBar_Create(self)
	self.castBar:SetPoint("CENTER", self)
	self:Attach(self.castBar)

	self:SetSize(self.castBar:GetWidth() + 4, 24)
end


--[[ Startup ]]--

function BongosCastBar:Load()
	local bar = BBar:Create("cast", Bar_OnCreate, nil, {["y"] = 617, ["x"] = 618, ["showText"] = true}, 'HIGH')
	bar:ToggleText(bar.sets.showText)

	self.bar = bar
end

function BongosCastBar:Unload()
	self.bar:Destroy()
end

function BongosCastBar:UpdateColor(spell)
	local castBar = self.bar.castBar
	if castBar.failed then
		castBar:SetStatusBarColor(0.86, 0.08, 0.24)
	elseif spell and IsHelpfulSpell(spell) then
		castBar:SetStatusBarColor(0.31, 0.78, 0.47)
	elseif spell and IsHarmfulSpell(spell) then
		castBar:SetStatusBarColor(0.63, 0.36, 0.94)
	else
		castBar:SetStatusBarColor(1, 0.7, 0)
	end
end