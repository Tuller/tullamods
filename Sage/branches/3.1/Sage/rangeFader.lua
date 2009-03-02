--[[
	rangeFader.lua
		Handles out of range fading for frames
--]]

local RangeFader = CreateFrame('Frame')
Sage.RangeFader = RangeFader

RangeFader.nextUpdate = 0
RangeFader.delay = 0.05
RangeFader.frames = {}

function RangeFader:OnUpdate(elapsed)
	self.nextUpdate = self.nextUpdate - elapsed

	if self.nextUpdate < 0 then
		self.nextUpdate = self.delay

		for _,f in pairs(self.frames) do
			self:Fade(f)
		end
	end
end

function RangeFader:Fade(f)
	local unit = f:GetAttribute('unit')
	if (not UnitInRange(unit)) and (UnitIsUnit(unit, 'pet') or UnitInParty(unit) or UnitInRaid(unit)) then
		f:SetAlpha(f:GetOORAlpha())
	else
		f:SetAlpha(f:GetFrameAlpha())
	end
end

function RangeFader:Register(f)
	for _,frame in pairs(self.frames) do
		if f == frame then
			return
		end
	end

	table.insert(self.frames, f)
	self:Show()
end

function RangeFader:Unregister(f)
	local found = false

	for i,frame in pairs(self.frames) do
		if f == frame then
			found = true
			table.remove(self.frames, i)
			break
		end
	end

	if found and #self.frames == 0 then
		self:Hide()
	end
end

--register nifty nachos
RangeFader:SetScript('OnUpdate', RangeFader.OnUpdate)
RangeFader:Hide()