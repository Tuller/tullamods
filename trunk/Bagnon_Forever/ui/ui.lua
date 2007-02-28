--[[
	BagnonDBUI
		Functions for the dropdown menu for showing cached data
		No alterations if this code should be needed to make it work with other databases
	
	Essentially the dropdown is used to switch between the inventory of other characters
	Why not use a normal dropdown?  It takes a lot of memory
--]]

local minWidth = 120

--[[ Character List ]]--

--create a player button, which is used to switch between characters
local function CreatePlayerButton(id, parent)
	local button = CreateFrame("CheckButton", parent:GetName() .. id, parent, "BagnonDBUINameBox")
	if id == 1 then
		button:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -4)
	else
		button:SetPoint("TOP", getglobal(parent:GetName() .. (id - 1)), "BOTTOM", 0, 6)
	end
	return button
end

function BagnonDBUI_ShowCharacterList(frame)
	BagnonDBUICharacterList.frame = frame
	
	local width = 0
	local index = 0
	for player in BagnonDB.GetPlayers() do
		index = index + 1
		
		local button = getglobal("BagnonDBUICharacterList" .. index) or CreatePlayerButton(index, BagnonDBUICharacterList)
		button:SetText(player)
		if button:GetTextWidth() + 34 > width then
			width = button:GetTextWidth() + 34
		end

		if frame:GetPlayer() == player then
			button:SetChecked(true)
			button:Show()
		else
			button:SetChecked(false)
		end
	end
		
	local i = index + 1
	while getglobal("BagnonDBUICharacterList" .. i) do
		getglobal("BagnonDBUICharacterList" .. i):Hide()
		i = i + 1
	end
		
	--resize and position the frame
	BagnonDBUICharacterList:SetHeight(16 + index * (BagnonDBUICharacterList1:GetHeight() - 6))
	BagnonDBUICharacterList:SetWidth(width)
	BagnonDBUICharacterList:ClearAllPoints()
	BagnonDBUICharacterList:SetPoint("TOPLEFT", frame:GetName() .. 'DropDown', "BOTTOMLEFT", 0, 4)
	BagnonDBUICharacterList:Show()
end