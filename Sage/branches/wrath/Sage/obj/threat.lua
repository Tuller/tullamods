local ThreatDisplay = Sage:CreateClass('Frame')
Sage.ThreatDisplay = ThreatDisplay

local frames = {}

function ThreatDisplay:New(parent)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. 'Threat', parent))
	f:SetScript('OnShow', self.OnShow)
	f:SetFrameLevel(0)

	f.bg = f:CreateTexture(nil, 'BACKGROUND')
	f.bg:SetAllPoints(f)

	f:UpdateUnit()

	frames[f] = true
	return f
end


--[[ Events ]]--

function ThreatDisplay:OnShow()
	self:Update()
end

function ThreatDisplay:UNIT_THREAT_SITUATION_UPDATE(unit)
	if unit == self.unit or unit == 'player' then
		self:Update()
	end
end


--[[ Update Methods ]]--

function ThreatDisplay:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if self.unit ~= newUnit then
		self.unit = newUnit

		if self:IsVisible() then
			self:Update()
		end
	end
end

function ThreatDisplay:Update()
	local state = max(UnitThreatSituation(self.unit), UnitThreatSituation('player', self.unit))
	if state > 0 then
		local r, g, b = GetThreatStatusColor(state)
		self.bg:SetTexture(r, g, b, 0.5)
	else
		self.bg:SetTexture(0, 0, 0, 0.5)
	end
end


--[[ Utility Functions ]]--

function ThreatDisplay:ForAllVisible(method, ...)
	for f in pairs(frames) do
		if f:IsVisible() then
			f[method](f, ...)
		end
	end
end

function ThreatDisplay:Get(id)
	return frames[id]
end

do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, ...)
		ThreatDisplay:ForAllVisible(event, ...)
	end)
	f:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE')
end