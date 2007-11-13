--[[
	Bongos MapBar
		Makes the minimap frame movable
--]]

BongosMapBar = Bongos:NewModule('Bongos-MapBar')
local L = BONGOS_LOCALS

--[[
	Compatibility Fixes
		These functions are for fixing issues with other addons
--]]

--Make titan not take control of the minimap
if IsAddOnLoaded('Titan') then
	local oTitanMovableFrame_CheckTopFrame = TitanMovableFrame_CheckTopFrame
	TitanMovableFrame_CheckTopFrame = function(frameTop, top, frameName)
		if frameName ~= 'MinimapCluster' then
			oTitanMovableFrame_CheckTopFrame(frameTop, top, frameName)
		end
	end
	TitanMovableData['MinimapCluster'] = nil
end


--[[ Clock Functions ]]--

local UPDATE_DELAY = 30

local function Clock_UpdateTime(text, hours, minutes)
	local pm = hours >= 12
	hours = mod(hours, 12)
	if(hours == 0) then hours = 12 end

	if pm then
		text:SetText(format(TEXT(TIME_TWELVEHOURPM), hours, minutes))
	else
		text:SetText(format(TEXT(TIME_TWELVEHOURAM), hours, minutes))
	end
end

local function Clock_OnUpdate(self, elapsed)
	if self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
	else
		self.nextUpdate = UPDATE_DELAY

		local hours, minutes = GetGameTime()
		hours = hours + (self.offset or 0)
		Clock_UpdateTime(self.text, hours, minutes)
	end
end

local function Clock_Create(parent)
	local clock = CreateFrame('Frame', nil, parent)
	clock:SetWidth(70) clock:SetHeight(24)

	local text = clock:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject('GameFontNormalSmall')
	text:SetAllPoints(clock)
	clock.text = text

	clock.nextUpdate = 0
	clock:SetScript('OnUpdate', Clock_OnUpdate)
	clock:SetPoint('BOTTOM', parent)

	return clock
end


--[[ Config ]]--

local function Bar_ToggleClock(self, enable)
	if enable then
		if not self.clock then
			self.clock = Clock_Create(self)
		end
		self.clock.offset = self.sets.offset
		self.clock:Show()
		self.sets.showClock = 1
	else
		if self.clock then
			self.clock:Hide()
		end
		self.sets.showClock = nil
	end
end

local function Bar_ToggleTitle(self, enable)
	if enable then
		self.sets.showTitle = 1
		self:SetHeight(MinimapCluster:GetHeight())

		MinimapZoneTextButton:Show()
		MinimapToggleButton:Show()
		MinimapBorderTop:Show()

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetPoint('TOPLEFT')
	else
		self.sets.showTitle = nil
		self:SetHeight(MinimapCluster:GetHeight() - 12)

		MinimapZoneTextButton:Hide()
		MinimapToggleButton:Hide()
		MinimapBorderTop:Hide()

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetPoint('TOPLEFT', 0, 12)
	end
end

local function Bar_ToggleZoomButtons(self, enable)
	if enable then
		self.sets.showZoom = 1

		MinimapZoomIn:Show()
		MinimapZoomOut:Show()
	else
		self.sets.showZoom = nil

		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	end
end

local function Bar_ToggleDayIndicator(self, enable)
	if enable then
		self.sets.showDay = 1
		GameTimeFrame:Show()
	else
		self.sets.showDay = nil
		GameTimeFrame:Hide()
	end
end

local function Bar_ToggleMap(self, enable)
	if enable then
		self.sets.showMap = 1
		MiniMapWorldMapButton:Show()
	else
		self.sets.showMap = nil
		MiniMapWorldMapButton:Hide()
	end
end

local function Bar_CreateMenu(self)
	local menu, panel = BongosMenu:CreateMenu('Map Bar')

	--checkbuttons
	local showTitle = panel:AddCheckButton(L.ShowMapTitle)
	showTitle:SetScript('OnShow', function(b) b:SetChecked(self.sets.showTitle) end)
	showTitle:SetScript('OnClick', function(b) self:ToggleTitle(b:GetChecked()) end)

	local showZoom = panel:AddCheckButton(L.ShowMapZoom)
	showZoom:SetScript('OnShow', function(b) b:SetChecked(self.sets.showZoom) end)
	showZoom:SetScript('OnClick', function(b) self:ToggleZoom(b:GetChecked()) end)

	local showDayNight = panel:AddCheckButton(L.ShowMapTime)
	showDayNight:SetScript('OnShow', function(b) b:SetChecked(self.sets.showDay) end)
	showDayNight:SetScript('OnClick', function(b) self:ToggleDayIndicator(b:GetChecked()) end)

	local showMap = panel:AddCheckButton(L.ShowMapButton)
	showMap:SetScript('OnShow', function(b) b:SetChecked(self.sets.showMap) end)
	showMap:SetScript('OnClick', function(b) self:ToggleMap(b:GetChecked()) end)

	local showClock = panel:AddCheckButton(L.ShowClock)
	showClock:SetScript('OnShow', function(b) b:SetChecked(self.sets.showClock) end)
	showClock:SetScript('OnClick', function(b) self:ToggleClock(b:GetChecked()) end)

	--clock offset slider
	local offset = panel:AddSlider('Offset', 0, 23, 1)
	offset:SetScript('OnShow', function(this)
		this.onShow = true
		this:SetValue(self.sets.offset or 0)
		this.onShow = nil
	end)
	offset:SetScript('OnValueChanged', function(this, value)
		if not this.onShow then
			self.sets.offset = value
			if self.clock then
				self.clock.offset = value
				self.clock.nextUpdate = 0
			end
		end
		getglobal(this:GetName() .. 'ValText'):SetText(value)
	end)

	return menu
end


--[[ Startup ]]--

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.ToggleTitle = Bar_ToggleTitle
	self.ToggleZoom = Bar_ToggleZoomButtons
	self.ToggleMap = Bar_ToggleMap
	self.ToggleDayIndicator = Bar_ToggleDayIndicator
	self.ToggleClock = Bar_ToggleClock

	self:EnableMouse(false)
	self:Attach(MinimapCluster)
	self:SetWidth(MinimapCluster:GetWidth())

	--make the minimap scrollable via the mousewheel
	local scrollFrame = CreateFrame('Frame', nil, Minimap)
	scrollFrame:SetAllPoints(Minimap)
	scrollFrame:EnableMouse(false)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript('OnMouseWheel', function(self, arg1)
		if (Minimap:GetZoom() + arg1 <= Minimap:GetZoomLevels()) and (Minimap:GetZoom() + arg1 >= 0) then
			Minimap:SetZoom(Minimap:GetZoom() + arg1)
		end
	end)
end

function BongosMapBar:Load()
	local defaults = {
		showTitle = true,
		showZoom = true,
		showDay = true,
		showMap = true,
	}

	local bar = BBar:Create('minimap', Bar_OnCreate, nil, defaults, 'BACKGROUND')
	if not bar:IsUserPlaced() then
		bar:SetPoint('TOPRIGHT')
	end

	--load settings
	--toggle title actually places the minimap on the bar, and adjusts the bar's height
	bar:ToggleClock(bar.sets.showClock)
	bar:ToggleTitle(bar.sets.showTitle)
	bar:ToggleZoom(bar.sets.showZoom)
	bar:ToggleDayIndicator(bar.sets.showDay)
	bar:ToggleMap(bar.sets.showMap)

	--override GetMaxUIPanelsWidth
	function GetMaxUIPanelsWidth()
		return UIParent:GetRight() - UIParent:GetAttribute('RIGHT_OFFSET_BUFFER')
	end

	self.bar = bar
end

function BongosMapBar:Unload()
	self.bar:Destroy()
end