--[[
	A profile selector panel
--]]

--local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
local CombuctorSet = Combuctor:GetModule('Sets')
local MAX_ITEMS = 13
local height, offset = 24, 0
local selected = {}
local items = {}
local profile = Combuctor:GetProfile()
local key = 'inventory'

local function AddSet(sets, name)
	for i, set in pairs(sets) do
		if set.name == name then
			return
		end
	end
	table.insert(sets, {['name'] = name})
	Combuctor:SendMessage('COMBUCTOR_CONFIG_SET_ADD', key, name)
end

local function RemoveSet(sets, name)
	for i,set in pairs(sets) do
		if set.name == name then
			table.remove(sets, i)
			Combuctor:SendMessage('COMBUCTOR_CONFIG_SET_REMOVE', key, name)
			break
		end
	end
end

local function AddSubSet(sets, name, parent)
	for i,set in pairs(sets) do
		if set.name == parent then
			if set.exclude then
				for j,child in pairs(set.exclude) do
					if child == name then
						table.remove(set.exclude, j)
						Combuctor:SendMessage('COMBUCTOR_CONFIG_SUBSET_REMOVE', key, name, parent)
						break
					end
				end
			end
		end
	end
end

local function RemoveSubSet(sets, name, parent)
	for i,set in pairs(sets) do
		if set.name == parent then
			if set.exclude then
				for j,child in pairs(set.exclude) do
					if child == name then
						return
					end
				end
				table.insert(set.exclude, name)
			else
				set.exclude = {name}
			end
			Combuctor:SendMessage('COMBUCTOR_CONFIG_SUBSET_ADD', key, name, parent)
		end
	end
end

--list button
local function ListButton_OnClick(self)
	if self.parent then
		if self:GetChecked() then
			AddSubSet(profile[key].sets, self.name, self.parent)
		else
			RemoveSubSet(profile[key].sets, self.name, self.parent)
		end
	else
		selected[self.name] = not selected[self.name]
		self:GetParent():UpdateList()
	end
end

local function HasSet(sets, name, parent)
	for i,set in pairs(sets) do
		if parent then
			if set.name == parent then
				if set.exclude then
					for j,child in pairs(set.exclude) do
						if child == name then
							return false
						end
					end
				end
				return true
			end
		elseif set.name == name then
			return true
		end
	end
	return false
end

local function ListButton_Set(self, set)
	self.name = set.name
	self.icon = set.icon
	self.parent = set.parent

	if set.icon then
		getglobal(self:GetName() .. 'Text'):SetFormattedText('|T%s:%d|t %s', set.icon, 32, set.name)
	else
		getglobal(self:GetName() .. 'Text'):SetText(set.name)
	end

	self:SetChecked(HasSet(profile[key].sets, set.name, set.parent))
end

local function ListButton_Create(id, parent)
	local b = CreateFrame('CheckButton', parent:GetName() .. 'Button' .. id, parent, 'InterfaceOptionsCheckButtonTemplate')
	b:SetScript('OnClick', ListButton_OnClick)
	b.Set = ListButton_Set

	return b
end


--[[ Panel Functions ]]--

local function Panel_UpdateList(self)
	local items = {}

	for _,parentSet in CombuctorSet:GetParentSets() do
		table.insert(items, parentSet)
		if selected[parentSet.name] then
			for _,childSet in CombuctorSet:GetChildSets(parentSet.name) do
				table.insert(items, childSet)
			end
		end
	end

	local scrollFrame = self.scrollFrame
	local offset = FauxScrollFrame_GetOffset(scrollFrame)
	local i = 1

	while i <= MAX_ITEMS and items[i + offset] do
		local button = self.buttons[i]
		button:Set(items[i + offset])

		local offLeft = button.parent and 24 or 0
		button:SetPoint('TOPLEFT', 14 + offLeft, -(64 + button:GetHeight() * i))
		button:Show()

		i = i + 1
	end

	for j = i, #self.buttons do
		self.buttons[j]:Hide()
	end

	FauxScrollFrame_Update(scrollFrame, #items, MAX_ITEMS, self.buttons[1]:GetHeight())
end

do
	local panel = Combuctor.Options
	panel.UpdateList = Panel_UpdateList
	panel:SetScript('OnShow', function(self) self:UpdateList() end)
	panel:SetScript('OnHide', function(self) selected = {} end)

	local name = panel:GetName()

	local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', panel, 'FauxScrollFrameTemplate')
	scroll:SetScript('OnVerticalScroll', function(self, arg1)
		FauxScrollFrame_OnVerticalScroll(self, arg1, height + offset, function()
			panel:UpdateList()
		end)
	end)
	scroll:SetPoint('TOPLEFT', 6, -96)
	scroll:SetPoint('BOTTOMRIGHT', -32, 8)
	panel.scrollFrame = scroll

	panel.buttons = setmetatable({}, {__index = function(t, k)
		t[k] = ListButton_Create(k, panel)
		return t[k]
	end})
end