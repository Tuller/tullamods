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

local function ShowAddonMemoryUsage()
	if this:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(this, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(this, 'ANCHOR_RIGHT')
	end

	if IsModifierKeyDown() then
		UpdateAddOnCPUUsage()

		GameTooltip:SetText("Addon CPU Usage")
		local total = 0

		for i=1, GetNumAddOns() do
			local secs = GetAddOnCPUUsage(i)/1000
			if secs > 3600 then
				GameTooltip:AddDoubleLine(GetAddOnInfo(i), format("%.2fh", secs/3600), 1, 1, 1, 1, 0.2, 0.2)
			elseif secs > 60 then
				GameTooltip:AddDoubleLine(GetAddOnInfo(i), format("%.2fm", secs/60), 1, 1, 1, 1, 1, 0.2)
			elseif floor(secs) > 0 then
				GameTooltip:AddDoubleLine(GetAddOnInfo(i), format("%ds", secs), 1, 1, 1, 0.2, 1, 0.2)
			end
			total = total + secs
		end
		GameTooltip:AddDoubleLine("Total", format("%.1fm", total/60), 0.4, 0.6, 1, 1, 1, 0.2)
	else
		UpdateAddOnMemoryUsage()

		GameTooltip:SetText("Addon Memory Usage")
		local total = 0

		for i=1, GetNumAddOns() do
			local mem = GetAddOnMemoryUsage(i)
			if mem > 0 then
				if mem > 1024 then
					GameTooltip:AddDoubleLine(GetAddOnInfo(i), format("%.1fmb", mem/1024), 1, 1, 1, 1, 1, 0.2)
				else
					GameTooltip:AddDoubleLine(GetAddOnInfo(i), format("%.1fkb", mem), 1, 1, 1, 0.2, 1, 0.2)
				end
				total = total + mem
			end
		end
		GameTooltip:AddDoubleLine("Total", format("%.2fmb", total/1024), 0.4, 0.6, 1, 1, 1, 0.2)
	end
	GameTooltip:Show()
end

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
	
	if GameTooltip:IsOwned(self) then
		ShowAddonMemoryUsage(self)
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
	self:EnableMouse(true)
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
	self:SetScript("OnEnter", function() ShowAddonMemoryUsage() end)
	self:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('stats') then
		Bongos.SetBarSets('stats', {x = 1271.714, y = 903.142, showMemory = 1, showLatency = 1, showFPS = 1, vis = 1})
	end	
	BBar.Create('stats', OnCreate) 
end)