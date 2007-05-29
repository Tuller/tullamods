--[[
	clock.lua
		A digital clock for bongos, loosely based on myClock
--]]

local offset = 0
local is24Hours
local UPDATE_DELAY = 30

local function UpdateTime(text, hours, minutes)
	hours = mod(hours + offset, 24)

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

local function OnUpdate(self, elapsed)
	if  self.elapsed <= 0 then
		self.elapsed = UPDATE_DELAY

		local hours, minutes = GetGameTime()
		UpdateTime(self.text, hours, minutes)
	else
		self.elapsed = self.elapsed - elapsed
	end
end

local function Clock_Create(parent)
	local clock = CreateFrame("Frame", "BongosClock", parent)
	clock:SetAllPoints(parent)

	clock.text = clock:CreateFontString(nil, "OVERLAY")
	text:SetFontObject("GameFontNormalSmall")
	text:SetAllPoints(clock)
	
	clock:SetBackdrop({
	  bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground", 
	  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, 
	  insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	
	clock.elapsed = 0
	clock:SetScript("OnUpdate", OnUpdate)
end


--[[ Startup ]]--

local function Bar_OnCreate(self)
	self:SetSize(70, 24)
	Clock_Create(self)
end

function BongosClock:Load()
	self.bar = BBar:Create("clock", Bar_OnCreate) 
	if not self.bar:IsUserPlaced() then
		self.bar:SetPoint("TOPRIGHT", UIParent)
	end
end

function BongosClock:Unload()
	self.bar:Destroy()
end