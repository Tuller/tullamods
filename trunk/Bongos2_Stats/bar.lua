--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

BongosStats = Bongos:NewModule("Bongos-Stats")

local L = BONGOS_STATS_LOCALS
local UPDATE_DELAY = 1

--display frame
local function Stats_Update(self)
	local parent = self:GetParent()
	local sets = parent.sets

	if sets.showFPS then
		self.fps:SetText(format("%.1ffps", GetFramerate()))
	end

	if sets.showMemory then
		self.mem:SetText(format("%.3fmb", gcinfo() / 1024))
	end

	if sets.showPing then
		local latency = select(3, GetNetStats())
		if (latency > PERFORMANCEBAR_MEDIUM_LATENCY) then
			self.ping:SetTextColor(1, 0, 0)
		elseif (latency > PERFORMANCEBAR_LOW_LATENCY) then
			self.ping:SetTextColor(1, 1, 0)
		else
			self.ping:SetTextColor(0, 1, 0)
		end
		self.ping:SetText(format("%dms", latency))
	end

	local width = self.fps:GetStringWidth() + self.mem:GetStringWidth() + self.ping:GetStringWidth()
	parent:SetWidth(max(24, width+4))
end

local function Stats_OnUpdate(self, arg1)
	if not self.toNextUpdate or self.toNextUpdate <= 0 then
		self.toNextUpdate = UPDATE_DELAY
		Stats_Update(self)
	else
		self.toNextUpdate = self.toNextUpdate - arg1
	end
end

local function Stats_OnClick(self, button)
	if IsAltKeyDown() then ReloadUI() end
end

local function Stats_Create(parent)
	local frame = CreateFrame("Button", nil, parent)
	frame:RegisterForClicks("AnyUp")
	frame:SetAllPoints(parent)

	frame.fps = frame:CreateFontString()
	frame.fps:SetFontObject("GameFontNormalLarge")
	frame.fps:SetPoint("LEFT", frame)

	frame.mem = frame:CreateFontString()
	frame.mem:SetFontObject("GameFontHighlightLarge")
	frame.mem:SetPoint("LEFT", frame.fps, "RIGHT", 2, 0)

	frame.ping = frame:CreateFontString()
	frame.ping:SetFontObject("GameFontHighlightLarge")
	frame.ping:SetPoint("LEFT", frame.mem, "RIGHT", 2, 0)

	frame:SetScript("OnUpdate", Stats_OnUpdate)
	frame:SetScript("OnClick", Stats_OnClick)

	frame.toNextUpdate = 0
	
	return frame
end

--stats bar
local function Bar_CreateMenu(self)
	local menu, panel = BongosMenu:CreateMenu(self.id)

	local showMemory = panel:AddCheckButton(L.ShowMemory)
	showMemory:SetScript("OnShow", function(b) b:SetChecked(self.sets.showMemory) end)
	showMemory:SetScript("OnClick", function() BongosStats:SetShowMemory(not self.sets.showMemory) end)

	local showFPS = panel:AddCheckButton(L.ShowFPS)
	showFPS:SetScript("OnShow", function(b) b:SetChecked(self.sets.showFPS) end)
	showFPS:SetScript("OnClick", function() BongosStats:SetShowFPS(not self.sets.showFPS) end)

	local showPing = panel:AddCheckButton(L.ShowPing)
	showPing:SetScript("OnShow", function(b) b:SetChecked(self.sets.showPing) end)
	showPing:SetScript("OnClick", function() BongosStats:SetShowPing(not self.sets.showPing) end)

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.frame = Stats_Create(self)
	self:SetSize(24)
end


--[[ Startup ]]--

function BongosStats:Load()
	self.bar = BBar:Create("stats", Bar_OnCreate, nil, {
		["y"] = 895, ["x"] = 1254, ["showMemory"] = true, ["showPing"] = true, ["showFPS"] = true,
	})
end

function BongosStats:Unload()
	self.bar:Destroy()
end


--[[ Config Functions ]]--

function BongosStats:SetShowFPS(enable)
	if enable then
		self.bar.sets.showFPS = true
		Stats_Update(self.bar.frame)
	else
		self.bar.sets.showFPS = nil
		self.fps:SetText("")
	end
end

function BongosStats:SetShowPing(enable)
	if enable then
		self.bar.sets.showPing = true
		Stats_Update(self.bar.frame)
	else
		self.bar.sets.showPing = nil
		self.ping:SetText("")
	end
end

function BongosStats:SetShowMemory(enable)
	if enable then
		self.bar.sets.showMemory = true
		Stats_Update(self.bar.frame)
	else
		self.bar.sets.showMemory = nil
		self.mem:SetText("")
	end
end