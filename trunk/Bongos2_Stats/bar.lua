--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

BongosStats = Bongos:NewModule("Bongos-Stats")

local L = BONGOS_STATS_LOCALS
local UPDATE_DELAY = 1

--display frame
local function Stats_OnUpdate(self, arg1)
	if not self.toNextUpdate or self.toNextUpdate <= 0 then
		self.toNextUpdate = UPDATE_DELAY
		BongosStats:Update()
	else
		self.toNextUpdate = self.toNextUpdate - arg1
	end
end

local function Stats_OnClick(self, button)
	if IsAltKeyDown() then
		ReloadUI()
	end
end

local function Stats_Create(self)
	local frame = CreateFrame("Button", nil, UIParent)
	frame:RegisterForClicks("AnyUp")

	self.fps = frame:CreateFontString()
	self.fps:SetFontObject("GameFontNormalLarge")
	self.fps:SetPoint("LEFT", frame)

	self.mem = frame:CreateFontString()
	self.mem:SetFontObject("GameFontHighlightLarge")
	self.mem:SetPoint("LEFT", self.fps, "RIGHT", 2, 0)

	self.ping = frame:CreateFontString()
	self.ping:SetFontObject("GameFontHighlightLarge")
	self.ping:SetPoint("LEFT", self.mem, "RIGHT", 2, 0)

	frame:SetScript("OnUpdate", Stats_OnUpdate)
	frame:SetScript("OnClick", Stats_OnClick)

	self.toNextUpdate = 0
	self.frame = frame
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
	self:SetSize(24)
end


--[[ Startup ]]--

function BongosStats:Initialize()
	Stats_Create(self)
end

function BongosStats:Load()
	self.bar = BBar:Create("stats", Bar_OnCreate, nil, {
		["y"] = 895, ["x"] = 1254, ["showMemory"] = true, ["showPing"] = true, ["showFPS"] = true,
	})

	self.bar:Attach(self.frame)
	self.frame:SetAllPoints(self.bar)
end

function BongosStats:Unload()
	self.bar:Destroy()
end


--[[ Update Functions ]]--

function BongosStats:Update()
	local sets = self.bar.sets

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

	self:UpdateWidth()
end

function BongosStats:UpdateWidth()
	local width = self.fps:GetStringWidth() + self.mem:GetStringWidth() + self.ping:GetStringWidth()
	self.bar:SetWidth(max(24, width+4))
end


--[[ Config Functions ]]--

function BongosStats:SetShowFPS(enable)
	if enable then
		self.bar.sets.showFPS = true
		self:Update()
	else
		self.bar.sets.showFPS = nil
		self.fps:SetText("")
	end
end

function BongosStats:SetShowPing(enable)
	if enable then
		self.bar.sets.showPing = true
		self:Update()
	else
		self.bar.sets.showPing = nil
		self.ping:SetText("")
	end
end

function BongosStats:SetShowMemory(enable)
	if enable then
		self.bar.sets.showMemory = true
		self:Update()
	else
		self.bar.sets.showMemory = nil
		self.mem:SetText("")
	end
end