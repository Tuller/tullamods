--[[
	Side Filters
		Used for setting what types of items to show
--]]

--[[
	A side filter button, switches parent filters on click
--]]

local SideFilterButton = Combuctor:NewClass('CheckButton')
do
	local nextID = 0

	function SideFilterButton:New(parent)
		local button = self:Bind(CreateFrame('CheckButton', format('CombuctorItemFilter%d', nextID), parent, 'SpellBookSkillLineTabTemplate'))
		button:GetNormalTexture():SetTexCoord(0.06, 0.94, 0.06, 0.94)
		button:SetScript('OnClick', self.OnClick)
		button:SetScript('OnEnter', self.OnEnter)
		button:SetScript('OnLeave', self.OnLeave)

		nextID = nextID + 1
		return button
	end
end

function SideFilterButton:OnClick()
	self:GetParent():GetParent():SetCategory(self.set)
end

function SideFilterButton:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	GameTooltip:SetText(self.set.name)
	GameTooltip:Show()
end

function SideFilterButton:OnLeave()
	GameTooltip:Hide()
end

function SideFilterButton:Set(set)
	self.set = set
	self:SetNormalTexture(set.icon)
end

function SideFilterButton:UpdateHighlight(setName)
	self:SetChecked(self.set.name == setName)
end


--[[
	Side Filter Object
--]]

local SideFilter = Combuctor:NewClass('Frame')
Combuctor.SideFilter = SideFilter
local CombuctorSets = Combuctor:GetModule('Sets')


function SideFilter:New(parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))

	--metatable magic for button creation on demand
	f.buttons = setmetatable({}, {__index = function(t, k)
		local button = SideFilterButton:New(f)

		if k > 1 then
			button:SetPoint('TOPLEFT', f.buttons[k-1], 'BOTTOMLEFT', 0, -17)
		else
			button:SetPoint('TOPLEFT', parent, 'TOPRIGHT', -32, -65)
		end

		t[k] = button

		return button
	end})

	f:UpdateFilters()

	return f
end

function SideFilter:UpdateFilters()
	local numFilters = 0
	local parent = self:GetParent()

	for _,set in parent:GetSets() do
		local setData = CombuctorSets:Get(set.name)
		if setData then
			numFilters = numFilters + 1
			self.buttons[numFilters]:Set(setData)
		end
	end

	--show only used buttons
	if numFilters > 1 then
		for i = 1, numFilters do
			self.buttons[i]:Show()
		end

		for i = numFilters + 1, #self.buttons do
			self.buttons[i]:Hide()
		end

		self:UpdateHighlight()
	--at most one filter active, hide all side buttons
	else
		for _,button in pairs(self.buttons) do
			button:Hide()
		end
	end
end

function SideFilter:UpdateHighlight()
	local category = self:GetParent():GetCategory()

	for _,button in pairs(self.buttons) do
		button:UpdateHighlight(category)
	end
end