--[[
	A profile selector panel
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')
local Options = Bongos.Options
local rows, cols = 3, 4


--[[ Profile Button ]]--

local function VisButton_OnClick(self)
	if self:GetChecked() then
		Bongos.Bar:ForBar(self.id, 'ShowFrame')
	else
		Bongos.Bar:ForBar(self.id, 'HideFrame')
	end
	
	local actionBar = self:GetParent().actionBar
	if actionBar then
		actionBar:OnShow()
	end

	local all = self:GetParent().all
	if all then
		all:OnShow()
	end
end


--[[ Panel Functions ]]--

local function Panel_UpdateButtons(self)
	for _,button in ipairs(self.buttons) do
		if button:IsShown() then
			button:SetChecked(Bongos.Bar:Get(button.id):IsShown())
		end
	end

	if self.actionBar then
		self.actionBar:OnShow()
	end

	if self.all then
		self.all:OnShow()
	end
end

local function Panel_LayoutButtons(self)
	local width = (self:GetWidth() - (self.scrollFrame:IsShown() and 20 or 0) - 16)/cols
	local height = 34

	self.all:SetPoint('TOPLEFT', 8, -8)
	if self.actionBar then
		self.actionBar:SetPoint('TOPLEFT', self.all, 'TOPLEFT', width, 0)
	end

	for i,button in ipairs(self.buttons) do
		local row = (i-1) % cols
		local col = ceil(i / cols) - 1
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', width*row + 8, -(height*col + 40))
	end
end

local function PanelSort(a, b)
	if type(a) == type(b) then
		return a < b
	elseif type(a) == 'string' then
		return false
	end
	return true
end

local list = {}
local function Panel_UpdateList(self)
	for i in pairs(list) do
		list[i] = nil
	end

	for id in Bongos.Bar:GetAll() do
		table.insert(list, id)
	end
	table.sort(list, PanelSort)


	local scroll = self.scrollFrame
	local offset = scroll.offset
	FauxScrollFrame_Update(scroll, #list, #self.buttons, self.buttons[1]:GetHeight())

	for i,button in ipairs(self.buttons) do
		local index = i + offset
		if index <= #list then
			getglobal(button:GetName() .. 'Text'):SetText(list[index])
			button.id = list[index]
			button:Show()
		else
			button:Hide()
		end
	end
	
	self:UpdateButtons()
end


--[[ Make the Panel ]]--

function Options:AddVisibilityPanel()
	local panel = self:CreatePanel(L.Visibility)
	panel:SetWidth(367); panel:SetHeight(156)
	panel:SetPoint('BOTTOMLEFT', 10, 10)
	
	panel.UpdateList = Panel_UpdateList
	panel.UpdateButtons = Panel_UpdateButtons
	panel.LayoutButtons = Panel_LayoutButtons
	
	panel:SetScript('OnShow', function(self)
		self:UpdateList()
		self:LayoutButtons()
	end)

	local scroll = CreateFrame('ScrollFrame', panel:GetName() .. 'ScrollFrame', panel, 'FauxScrollFrameTemplate')
	scroll:SetScript('OnVerticalScroll', function() 
		FauxScrollFrame_OnVerticalScroll(30, function() panel:UpdateList() end) 
	end)
	scroll:SetScript('OnShow', function() panel:LayoutButtons() end)
	scroll:SetScript('OnHide', function() panel:LayoutButtons() end)
	scroll:SetPoint('TOPLEFT', 6, -6)
	scroll:SetPoint('BOTTOMRIGHT', -28, 4)
	panel.scrollFrame = scroll

	--add list buttons
	local all = self:CreateCheckButton('all', panel)
	all:SetHitRectInsets(0, 0, 0, 0)
	
	function all:OnShow()
		for _,bar in Bongos.Bar:GetAll() do
			if not bar:IsShown() then
				self:SetChecked(false)
				return
			end
		end
		self:SetChecked(true)
	end
	all:SetScript('OnShow', all.OnShow)

	all:SetScript('OnClick', function(self)
		if self:GetChecked() then
			Bongos.Bar:ForBar('all', 'ShowFrame')
		else
			Bongos.Bar:ForBar('all', 'HideFrame')
		end
		panel:UpdateButtons()
	end)
	panel.all = all

	if Bongos:GetModule('ActionBar', true) then
		local ab = self:CreateCheckButton('action bars', panel)
		ab:SetHitRectInsets(0, 0, 0, 0)
	
		function ab:OnShow()
			for id,bar in Bongos.Bar:GetAll() do
				if tonumber(id) and not bar:IsShown() then
					self:SetChecked(false)
					return
				end
			end
			self:SetChecked(true)
		end
		ab:SetScript('OnShow', ab.OnShow)

		ab:SetScript('OnClick', function(self)
			if self:GetChecked() then
				for id,bar in Bongos.Bar:GetAll() do
					if tonumber(id) then
						bar:ShowFrame()
					end
				end
			else
				for id,bar in Bongos.Bar:GetAll() do
					if tonumber(id) then
						bar:HideFrame()
					end
				end
			end
			panel:UpdateButtons()
		end)
		panel.actionBar = ab
	end

	panel.buttons = {}
	for i = 1, (rows*cols) do
		local button = self:CreateCheckButton(i, panel)
		button:SetHitRectInsets(0, 0, 0, 0)
		button:SetScript('OnClick', VisButton_OnClick)
		panel.buttons[i] = button
	end

	return panel
end

Options:AddVisibilityPanel()