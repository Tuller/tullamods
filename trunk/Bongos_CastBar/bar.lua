--[[
	BCastBar
		A Bongos based cast bar
--]]

BongosCastBar = Bongos:NewModule("Bongos-CastBar")

--[[ CastingBar Stuff ]]--

local function CastingBar_AdjustWidth(self)
	local name = self:GetName()
	local textWidth = getglobal(name .. "Text"):GetStringWidth()

	local time = getglobal(name .. "Time")
	if time:IsShown() then
		textWidth = textWidth + 64
	end

	local diff = textWidth - self.normalWidth
	if diff > 0 then
		diff = textWidth - self:GetWidth()
	else
		diff = self.normalWidth - self:GetWidth()
	end

	if diff ~= 0 then
		self:GetParent():SetWidth(self:GetParent():GetWidth() + diff)
		self:SetWidth(self:GetWidth() + diff)
	end
end

local function CastingBar_OnUpdate(self, arg1)
	local name = self:GetName()
	local barSpark = getglobal(name.."Spark")
	local barFlash = getglobal(name.."Flash")
	local barTime = getglobal(name.."Time")

	if self.casting then
		local status = GetTime()
		if status > self.maxValue then
			status = self.maxValue
		end
		if status == self.maxValue then
			self:SetValue(self.maxValue)
			self:SetStatusBarColor(0.0, 1.0, 0.0)
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
		barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 2)

		--time display
		barTime:SetText(format("%.1f", self.maxValue - status))
		self:AdjustWidth()
	elseif self.channeling then
		local time = GetTime()
		if time > self.endTime then
			time = self.endTime
		end
		if time == self.endTime then
			self:SetStatusBarColor(0.0, 1.0, 0.0)
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
		barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 2)

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
	local bar = CreateFrame("StatusBar", "BongosCastBar", parent, "BongosCastingBarTemplate")
	bar.AdjustWidth = CastingBar_AdjustWidth
	bar.normalWidth = bar:GetWidth()
	bar:SetScript("OnUpdate", CastingBar_OnUpdate)

	return bar
end


--[[ Bongos Bar Methods ]]--

local function Bar_CreateMenu(frame)
	local name = format("BongosMenu%s", frame.id)
	local menu = BongosMenu:Create(name)
	menu.frame = frame
	menu.text:SetText("Cast Bar")

	--checkbuttons
	local time = menu:CreateCheckButton(menu, name .. "Time")
	time:SetScript("OnClick", function(self) frame:ToggleText(self:GetChecked()) end)
	time:SetScript("OnShow", function(self) self:SetChecked(frame.sets.showText) end)
	time:SetText(BONGOS_CASTBAR_SHOW_TIME)

	return menu
end

local function Bar_ShowMenu(self)
	if not self.menu then
		self.menu = Bar_CreateMenu(self)
	end

	local menu = self.menu
	menu.onShow = true
	self:PlaceMenu(menu)
	menu.onShow = nil
end

local function Bar_ToggleText(self, enable)
	local castingBar = self.castBar
	if enable then
		getglobal(castingBar:GetName() .. "Time"):Show()
		self.sets.showText = true
	else
		getglobal(castingBar:GetName() .. "Time"):Hide()
		self.sets.showText = nil
	end
	castingBar:AdjustWidth()
end

local function Bar_OnCreate(self)
	CastingBarFrame:UnregisterAllEvents()
	CastingBarFrame:Hide()

	self.ShowMenu = Bar_ShowMenu
	self.ToggleText = Bar_ToggleText

	self.castBar = CastingBar_Create(self)
	self.castBar:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -2)
	self:Attach(self.castBar)

	self:SetSize(207, 24)
end


--[[ Startup ]]--

function BongosCastBar:Load()
	local bar = BBar:Create("cast", Bar_OnCreate, nil, {["y"] = 617, ["x"] = 618, ["showText"] = true})
	bar:ToggleText(bar.sets.showText)

	self.bar = bar
end

function BongosCastBar:Unload()
	self.bar:Destroy()
end