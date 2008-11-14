--combo frame
local ComboFrame = Sage:CreateClass('Frame')
Sage.ComboFrame = ComboFrame

local MAX_COMBO_POINTS = 5
local COMBO_TEXT = {
	'C',
	'C O',
	'C O M',
	'C O M B',
	'C O M B O'
}

local frames = {}

function ComboFrame:New(parent, font)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. 'Combo', parent))
	f:SetScript('OnShow', f.Update)
	f:SetWidth(16)
	f:SetHeight(75)

	local text = f:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(font)
	text:SetJustifyV('TOP')
	text:SetNonSpaceWrap(false)
	text:SetAllPoints(f)
	self.text = text
	
	table.insert(frames, f)
	return f
end

function ComboFrame:SetNumeric(enable)
	self.numeric = enable or false
	self:Update()
end

function ComboFrame:Update()
	local points = GetComboPoints('player')
	if points > 0 then
		if self.numeric then
			self.text:SetText(points)
		else
			self.text:SetText(COMBO_TEXT[points])
		end
		
		if comboPoints == MAX_COMBO_POINTS then
			self.text:SetTextColor(1, 0.5, 0)
		else
			self.text:SetTextColor(1, 0.9, 0.1)
		end
		self:Show()
	else
		self:Hide()
	end
end

function ComboFrame:UpdateAllVisible()
	for _,frame in pairs(frames) do
		if frame:GetParent():IsVisible() then
			frame:Update()
		end
	end
end

do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, unit)
		if unit == 'player' then
			ComboFrame:UpdateAllVisible()
		end
	end)
	f:RegisterEvent('UNIT_COMBO_POINTS')
end