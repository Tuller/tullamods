--[[
	BRollBar
		A movable frame for rolling on items
--]]


--[[ Config Functions ]]--

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText("Roll Bar")
	menu:SetWidth(220)
	menu:SetHeight(140)

	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)
	
	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosRollBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1
	self:DisplayMenu(menu)
	menu.onShow = nil
end


--[[ Startup ]]--

local function OnCreate(self)
	self.ShowMenu = ShowMenu

	local frame = getglobal("GroupLootFrame"..1)
	frame:ClearAllPoints()
	frame:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 4, 2)
	self:Attach(frame)

	for i=2, NUM_GROUP_LOOT_FRAMES do
		local frame = getglobal("GroupLootFrame"..i)
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOM", "GroupLootFrame" .. (i-1), "TOP", 0, 3)		
		self:Attach(frame)
	end

	self:SetWidth(GroupLootFrame1:GetWidth() + 4)
	self:SetHeight((GroupLootFrame1:GetHeight() + 3) * NUM_GROUP_LOOT_FRAMES)
end

Bongos.AddStartup(function()
	local bar = BBar.Create('roll', OnCreate)
	if not bar:IsUserPlaced() then
		bar:SetPoint("LEFT", UIParent)
	end
end)