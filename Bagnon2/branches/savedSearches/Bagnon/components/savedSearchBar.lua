--[[
	savedSearchBar.lua
		Bagnon's saved search bar
--]]

local SavedSearchBar = Bagnon.Classy:New('Frame')
Bagnon.SavedSearchBar = SavedSearchBar


function SavedSearchBar:New(parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))
	f.buttons = {}

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f:UpdateEverything()
	
	return f
end


--[[
	Frame Events
--]]

function SavedSearchBar:OnShow()
	self:UpdateMessages()
	self:UpdateButtons()
end

function SavedSearchBar:OnHide()
	self:UpdateMessages()
end


--[[
	Frame Messages
--]]

function SavedSearchBar:SAVED_SEARCH_ADD(frameID, id)
	if self:GetFrameID() == frameID then
		self:AddButton(id)
	end
end

function SavedSearchBar:SAVED_SEARCH_REMOVE(frameID, id)
	if self:GetFrameID() == frameID then
		self:RemoveButton(id)
	end
end

function SavedSearchBar:SAVED_SEARCH_UPDATE(frameID, id)
	if self:GetFrameID() == frameID then
		self:UpdateButton(id)
	end
end

--[[
	Actions
--]]

function SavedSearchBar:UpdateEverything()
	self:UpdateMessages()
	self:UpdateButtons()
end

function SavedSearchBar:UpdateMessages()
	self:UnregisterAllMessages()

	if self:IsVisible() then
		self:RegisterMessage('SAVED_SEARCH_ADD')
		self:RegisterMessage('SAVED_SEARCH_REMOVE')
		self:RegisterMessage('SAVED_SEARCH_UPDATE')
	end
end

function SavedSearchBar:UpdateButtons()
	local layoutChanged = false

	for id, searchInfo in self:GetSearches() do
		local b = self:GetButton(id)
		if b then
			b:SetSearchInfo(searchInfo)
		else
			self:NewButton(id)
			layoutChanged = true
		end
	end
	
	if layoutChanged then
		self:Layout()
	end
end

function SavedSearchBar:UpdateButton(id)
	local b = self:GetButton(id)
	if b then
		b:SetSearchInfo(self:GetSearch(id))
	end
end


local ITEM_SPACING = 4
function SavedSearchBar:Layout()
	local w, h = 0, 0

	for i, button in self:GetButtons() do
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('LEFT')
			w = w + button:GetWidth()
		else
			button:SetPoint('LEFT', self:GetButton(i - 1), 'RIGHT', ITEM_SPACING, 0)
			w = w + (button:GetWidth() + ITEM_SPACING)
		end
		h = math.max(h, button:GetHeight())
	end

	self:SetWidth(w)
	self:SetHeight(h)
end

function SavedSearchBar:AddButton(id)
	local b = self:NewButton(id)
	if b then
		self:Layout()
	end
	return b
end

function SavedSearchBar:RemoveButton(id)
	if self:FreeButton(id) then
		self:Layout()
	end
end

function SavedSearchBar:NewButton(id)
	if not self:GetButton(id) then
		local b = Bagnon.SavedSearchButton:New(self)
		b:SetSearchInfo(self:GetSearch(id))
		
		self.buttons[id] = b
		return b
	end
	return nil
end

function SavedSearchBar:FreeButton(id)
	local b = self:GetButton(id)
	if b then
		b:Free()
		self.buttons[id] = nil
		return true
	end
	return nil
end

function SavedSearchBar:GetButton(id)
	return self.buttons[id]
end

function SavedSearchBar:GetButtons()
	return pairs(self.buttons)
end


--[[
	Properties
--]]

function SavedSearchBar:GetFrameID()
	return self:GetParent():GetFrameID()
end

function SavedSearchBar:GetSettings()
	return self:GetParent():GetSettings()
end

local searches = {
	[1] = {
		name = 'Trash',
		icon = [[Interface\Icons\INV_Misc_Bell_01]],
		rule = 'q:1&boe|q:0'
	},
	[2] = {
		name = 'Weapons',
		icon = [[Interface\Icons\INV_Axe_09]],
		rule = 't:weapon'
	},
	[3] = {
		name = 'Armor',
		icon = [[Interface\Icons\INV_Chest_Plate15]],
		rule = 'armor'
	},
	[4] = {
		name = 'Quest',
		icon = [[Interface\Icons\INV_Bijou_Green]],
		rule = 'quest'
	}
}
function SavedSearchBar:GetSearches()
	return pairs(searches)
end

function SavedSearchBar:GetSearch(id)
	return searches[id]
end