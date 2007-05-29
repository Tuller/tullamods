--[[
	clock.lua
		A digital clock for bongos, loosely based on myClock
--]]

BongosClock = Bongos:NewModule("Bongos-Clock")

local offset = 0
local UPDATE_DELAY = 30

local function Clock_UpdateTime(text, hours, minutes)
	local hours = mod(hours + offset, 24)
	local pm = hours >= 12
	hours = mod(hours-1, 12) + 1

	if pm then
		text:SetText(format(TEXT(TIME_TWELVEHOURPM), hours, minutes))
	else
		text:SetText(format(TEXT(TIME_TWELVEHOURAM), hours, minutes))
	end
end

local function Clock_OnUpdate(self, elapsed)
	if self.elapsed <= 0 then
		self.elapsed = UPDATE_DELAY

		local hours, minutes = GetGameTime()
		Clock_UpdateTime(self.text, hours, minutes)
	else
		self.elapsed = self.elapsed - elapsed
	end
end


--[[ Startup ]]--

local function Bar_OnCreate(self)
	self:SetSize(70, 24)

	local clock = CreateFrame("Frame", nil, self)
	clock:SetAllPoints(self)

	local text = clock:CreateFontString(nil, "OVERLAY")
	text:SetFontObject("GameFontNormalSmall")
	text:SetAllPoints(clock)
	clock.text = text

	clock.elapsed = 0
	clock:SetScript("OnUpdate", Clock_OnUpdate)
end

function BongosClock:Load()
	local bar = BBar:Create("clock", Bar_OnCreate)
	if not bar:IsUserPlaced() then
		bar:SetPoint("TOPRIGHT", UIParent)
	end
	self.bar = bar
end

function BongosClock:Unload()
	self.bar:Destroy()
end