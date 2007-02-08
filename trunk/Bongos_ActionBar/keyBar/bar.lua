--[[
	BKeyBar
		Makes the keyring button movable
--]]


--[[ Menu Stuff ]]--

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame('Button', name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText('Key Bar')
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
	local name = 'BongosKeyBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1
	self:DisplayMenu(menu)
	menu.onShow = nil
end

local function OnCreate(self)
	self.ShowMenu = ShowMenu
	
	KeyRingButton:ClearAllPoints()
	KeyRingButton:SetPoint('TOPLEFT', self)
	KeyRingButton:Show()
	
	self:Attach(KeyRingButton)
	self:SetWidth(KeyRingButton:GetWidth())
	self:SetHeight(KeyRingButton:GetHeight())
end


--[[ Startup ]]--

Bongos.AddStartup(function() 
	if not Bongos.GetBarSets('key') then
		Bongos.SetBarSets('key', {x = 1241.857, y = 39, vis = 1})
	end
	BBar.Create('key', OnCreate) 
end)