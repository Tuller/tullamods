--[[
	BongosStats
		A movable memory, latency and fps display for Bongos

	Version History
		10/8/5
			Initial release
		10/11/5
			Updated for Bongos 0.4.0/Patch 1800
		12/16/05
			Made the text bigger
			Added a seperate keybinding
		8/14/6
			Made into a full Bongos Bar
		10/27/6
			Modified to use MiB instead of MB
			Added customization options
		12/28/6
			Updated to use new Bongos code
--]]


local UPDATE_DELAY = 1

local function Update(self)
	if self.sets.showFPS then
		self.fps:SetText(format("%.1ffps", GetFramerate()))
	else
		self.fps:SetText('')
	end

	if self.sets.showMemory then
		self.mem:SetText(format("%.3fmb", gcinfo() / 1024))
	else
		self.mem:SetText('')
	end

	if self.sets.showLatency then
		local latency = select(3, GetNetStats())
		if (latency > PERFORMANCEBAR_MEDIUM_LATENCY) then
			self.ping:SetTextColor(1, 0, 0)
		elseif (latency > PERFORMANCEBAR_LOW_LATENCY) then
			self.ping:SetTextColor(1, 1, 0)
		else
			self.ping:SetTextColor(0, 1, 0)
		end
		self.ping:SetText(format("%dms", latency))
	else
		self.ping:SetText('')
	end

	local width = self.fps:GetStringWidth() + self.mem:GetStringWidth() + self.ping:GetStringWidth()
	if width == 0 then
		self:SetWidth(24)
	else
		self:SetWidth(width + 4)
	end
end

local function OnUpdate()
	if this.toNextUpdate <= 0 then
		this.toNextUpdate = UPDATE_DELAY
		Update(this)
	else
		this.toNextUpdate = this.toNextUpdate - arg1
	end
end


--[[ Menu Functions ]]--

local function SetFlag(self, var, enable)
	if enable then
		self.sets[var] = 1
	else
		self.sets[var] = nil
	end
	Update(self)
end

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText("Stats Bar")
	menu:SetWidth(220)
	menu:SetHeight(220)

	--checkbuttons
	local fps = CreateFrame("CheckButton", name .. "FPS", menu, "GooeyCheckButton")
	fps:SetScript("OnClick", function() SetFlag(frame, 'showFPS', this:GetChecked()) end)
	fps:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -28)
	fps:SetText(BONGOS_STATS_SHOW_FPS)

	local mem = CreateFrame("CheckButton", name .. "Memory", menu, "GooeyCheckButton")
	mem:SetScript("OnClick", function() SetFlag(frame, 'showMemory', this:GetChecked()) end)
	mem:SetPoint("TOP", fps, "BOTTOM", 0, 2)
	mem:SetText(BONGOS_STATS_SHOW_MEMORY)

	local ping = CreateFrame("CheckButton", name .. "Latency", menu, "GooeyCheckButton")
	ping:SetScript("OnClick", function() SetFlag(frame, 'showLatency', this:GetChecked()) end)
	ping:SetPoint("TOP", mem, "BOTTOM", 0, 2)
	ping:SetText(BONGOS_STATS_SHOW_LATENCY)
	
	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)
	
	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosStatsBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1
	
	getglobal(name .. 'FPS'):SetChecked(self.sets.showFPS)
	getglobal(name .. 'Memory'):SetChecked(self.sets.showMemory)
	getglobal(name .. 'Latency'):SetChecked(self.sets.showLatency)

	self:DisplayMenu(menu)

	menu.onShow = nil
end


--[[ Startup ]]--

local function OnCreate(self)
	self.fps = self:CreateFontString()
	self.fps:SetFontObject("GameFontNormalLarge")
	self.fps:SetPoint("LEFT", self)

	self.mem = self:CreateFontString()
	self.mem:SetFontObject("GameFontHighlightLarge")
	self.mem:SetPoint("LEFT", self.fps, "RIGHT", 2, 0)

	self.ping = self:CreateFontString()
	self.ping:SetFontObject("GameFontHighlightLarge")
	self.ping:SetPoint("LEFT", self.mem, "RIGHT", 2, 0)
	
	self.toNextUpdate = 0
	self.ShowMenu = ShowMenu

	self:SetWidth(120)
	self:SetHeight(20)
	self:SetScript("OnUpdate", OnUpdate)
end

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('stats') then
		Bongos.SetBarSets('stats', {x = 1271.714, y = 903.142, showMemory = 1, showLatency = 1, showFPS = 1, vis = 1})
	end	
	BBar.Create('stats', OnCreate) 
end)