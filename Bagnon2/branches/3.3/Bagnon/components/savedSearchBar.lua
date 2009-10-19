--[[
	savedSearchBar.lua
		Bagnon's saved search bar
--]]

local SavedSearchBar = Bagnon.Classy:New('Frame')
Bagnon.SavedSearchBar = SavedSearchBar


function SavedSearchBar:New(frameID)
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

function SavedSearchBar:SAVED_SEARCH_ADD(frameID, searchID)
	self:UpdateButtons()
end

--[[
	Update Methods
--]]

--[[
	Properties
--]]

function F