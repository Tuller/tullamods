--[[
	Bongos MapBar
		Makes the minimap frame movable
--]]

BongosMapBar = Bongos:NewModule("Bongos-MapBar")
local L = BONGOS_LOCALS
L.ShowMapTitle = "Show Title"
L.ShowMapZoom = "Show Zoom Buttons"
L.ShowMapTime = "Show Day/Night Indicator"
L.ShowMapButton = "Show Map Button"

--[[
	Compatibility Fixes
		These functions are for fixing issues with other addons
--]]

--Make titan not take control of the minimap
-- if IsAddOnLoaded("Titan") then
	-- local oTitanMovableFrame_CheckTopFrame = TitanMovableFrame_CheckTopFrame
	-- TitanMovableFrame_CheckTopFrame = function(frameTop, top, frameName)
		-- if frameName ~= "MinimapCluster" then
			-- oTitanMovableFrame_CheckTopFrame(frameTop, top, frameName)
		-- end
	-- end
	-- TitanMovableData["MinimapCluster"] = nil
-- end


--[[ Config ]]--

local function Bar_ToggleTitle(self, enable)
	if enable then
		self.sets.showTitle = 1
		self:SetHeight(MinimapCluster:GetHeight())

		MinimapZoneTextButton:Show()
		MinimapToggleButton:Show()
		MinimapBorderTop:Show()

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetPoint("TOPLEFT", self)
	else
		self.sets.showTitle = nil
		self:SetHeight(MinimapCluster:GetHeight() - 12)

		MinimapZoneTextButton:Hide()
		MinimapToggleButton:Hide()
		MinimapBorderTop:Hide()

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 12)
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
	local menu, panel = BongosMenu:CreateMenu("Map Bar")

	--checkbuttons
	local showTitle = panel:AddCheckButton(L.ShowMapTitle)
	showTitle:SetScript("OnShow", function(b) b:SetChecked(self.sets.showTitle) end)
	showTitle:SetScript("OnClick", function(b) self:ToggleTitle(b:GetChecked()) end)

	local showZoom = panel:AddCheckButton(L.ShowMapZoom)
	showZoom:SetScript("OnShow", function(b) b:SetChecked(self.sets.showZoom) end)
	showZoom:SetScript("OnClick", function(b) self:ToggleZoom(b:GetChecked()) end)

	local showDayNight = panel:AddCheckButton(L.ShowMapTime)
	showDayNight:SetScript("OnShow", function(b) b:SetChecked(self.sets.showDay) end)
	showDayNight:SetScript("OnClick", function(b) self:ToggleDayIndicator(b:GetChecked()) end)
	
	local showMap = panel:AddCheckButton(L.ShowMapButton)
	showMap:SetScript("OnShow", function(b) b:SetChecked(self.sets.showMap) end)
	showMap:SetScript("OnClick", function(b) self:ToggleMap(b:GetChecked()) end)
	
	return menu
end


--[[ Startup ]]--

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.ToggleTitle = Bar_ToggleTitle
	self.ToggleZoom = Bar_ToggleZoomButtons
	self.ToggleMap = Bar_ToggleMap
	self.ToggleDayIndicator = Bar_ToggleDayIndicator
	
	self:EnableMouse(false)
	self:Attach(MinimapCluster)
	self:SetWidth(MinimapCluster:GetWidth())
	
	--make the minimap scrollable via the mousewheel
	local scrollFrame = CreateFrame("Frame", nil, Minimap)
	scrollFrame:SetAllPoints(Minimap)
	scrollFrame:EnableMouse(false)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(self, arg1)
		if (Minimap:GetZoom() + arg1 <= Minimap:GetZoomLevels()) and (Minimap:GetZoom() + arg1 >= 0) then
			Minimap:SetZoom(Minimap:GetZoom() + arg1)
		end
	end)
end

function BongosMapBar:Load()
	local bar = BBar:Create("minimap", Bar_OnCreate, nil, nil, "BACKGROUND")
	if not bar:IsUserPlaced() then
		bar:SetPoint("TOPRIGHT", UIParent)
	end
	
	--load settings
	--toggle title actually places the minimap on the bar, and adjusts the bar"s height
	bar:ToggleTitle(bar.sets.showTitle)
	bar:ToggleZoom(bar.sets.showZoom)
	bar:ToggleDayIndicator(bar.sets.showDay)
	bar:ToggleMap(bar.sets.showMap)
	
	self.bar = bar
end

function BongosMapBar:Unload()
	self.bar:Destroy()
end