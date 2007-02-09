--[[
	clock.lua
		A digital clock for bongos, loosely based on myClock
--]]

local offset = 0
local is24Hours
local UPDATE_DELAY = 30

local function UpdateTime(text, hours, minutes)
	hours = math.fmod(hours + offset, 24)

	if is24Hours then
		text:SetText(format(TEXT(TIME_TWENTYFOURHOURS), hours, minutes));
	else
		local pm = hours >= 12
		hours = math.fmod(hours, 12)
		if hours == 0 then
			hours = 12
		end

		if pm then
			text:SetText(format(TEXT(TIME_TWELVEHOURPM), hours, minutes))
		else
			text:SetText(format(TEXT(TIME_TWELVEHOURAM), hours, minutes))
		end
	end
end

local function OnUpdate()
	if  this.elapsed <= 0 then
		this.elapsed = UPDATE_DELAY

		local hours, minutes = GetGameTime()
		UpdateTime(getglobal(this:GetName() .. 'Text'), hours, minutes)
	else
		this.elapsed = this.elapsed - arg1
	end
end

local function Clock_Create(parent)
	local clock = CreateFrame('Frame', 'BongosClock', parent)
	clock:SetAllPoints(parent)

	local text = clock:CreateFontString(clock:GetName() .. 'Text', 'OVERLAY')
	text:SetFontObject('GameFontNormalSmall')
	text:SetAllPoints(clock)
	
	clock:SetBackdrop({ 
	  bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground", 
	  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, 
	  insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	
	clock.elapsed = 0
	clock:SetScript('OnUpdate', OnUpdate)
end


--[[ Startup ]]--

local function OnCreate(self)
	self:SetWidth(70); self:SetHeight(24)	
	Clock_Create(self)
end

Bongos.AddStartup(function() 
	local bar = BBar.Create('clock', OnCreate) 
	if not bar:IsUserPlaced() then
		bar:SetPoint("TOPRIGHT", UIParent)
	end
end)