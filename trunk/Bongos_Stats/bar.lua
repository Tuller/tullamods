--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

BongosStats = Bongos:NewModule("Bongos-Stats")
BongosStats.defaults = {showFPS = true, showMemory = true, showPing = true, x = 1253.7466, y = 895.0568}
					
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

local function Stats_OnEnter()
	BongosStats:UpdateProfilingInfo()
end

local function Stats_OnLeave()
	GameTooltip:Hide()
end

local function Stats_OnClick(self, button)
	if IsAltKeyDown() then
		if button == "LeftButton" then
			ReloadUI()
		elseif button == "RightButton" then
			if GetCVar("scriptProfile") == "1" then
				SetCVar("scriptProfile", "0")
			else
				SetCVar("scriptProfile", "1")
			end
			ReloadUI()
		end
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
	if not(GetBuildInfo() == "2.0.12") then
		frame:SetScript("OnEnter", Stats_OnEnter)
	end
	frame:SetScript("OnLeave", Stats_OnLeave)
	frame:SetScript("OnClick", Stats_OnClick)

	self.toNextUpdate = 0
	self.frame = frame
end

--stats bar
local function Bar_CreateMenu(self)
	local name = format("BongosMenu%s", self.id)
	local menu = BongosMenu:Create(name)
	menu.text:SetText(L.StatsBar)

	local showMemory = menu:CreateCheckButton(name .. "ShowMemory")
	showMemory:SetScript("OnShow", function(b) b:SetChecked(self.sets.showMemory) end)
	showMemory:SetScript("OnClick", function() BongosStats:SetShowMemory(not self.sets.showMemory) end)
	showMemory:SetText(L.ShowMemory)

	local showFPS = menu:CreateCheckButton(name .. "ShowFPS")
	showFPS:SetScript("OnShow", function(b) b:SetChecked(self.sets.showFPS) end)
	showFPS:SetScript("OnClick", function() BongosStats:SetShowFPS(not self.sets.showFPS) end)
	showFPS:SetText(L.ShowFPS)

	local showPing = menu:CreateCheckButton(name .. "ShowPing")
	showPing:SetScript("OnShow", function(b) b:SetChecked(self.sets.showPing) end)
	showPing:SetScript("OnClick", function() BongosStats:SetShowPing(not self.sets.showPing) end)
	showPing:SetText(L.ShowPing)

	menu.frame = self

	return menu
end

local function Bar_ShowMenu(self)
	if not self.menu then
		self.menu = Bar_CreateMenu(self)
	end

	local menu = self.menu
	menu.onShow = 1
	self:PlaceMenu(menu)
	menu.onShow = nil
end

local function Bar_OnCreate(self)
	self.ShowMenu = Bar_ShowMenu
	self:SetSize(24)
end


--[[ Startup ]]--

function BongosStats:Initialize()
	Stats_Create(self)
end

function BongosStats:Load()
	self.bar = BBar:Create("stats", Bar_OnCreate, nil, self.defaults)

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

	if GameTooltip:IsOwned(self.bar) then
		self:UpdateProfilingInfo()
	end
end

function BongosStats:UpdateProfilingInfo()
	if self.bar:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self.bar, "ANCHOR_BOTTOMLEFT")
	else
		GameTooltip:SetOwner(self.bar, "ANCHOR_BOTTOMRIGHT")
	end

	if IsModifierKeyDown() and GetCVar("scriptProfile") == "1" then
		UpdateAddOnCPUUsage()
		GameTooltip:SetText(L.CPUUsage)

		local total = 0
		for i=1, GetNumAddOns() do
			local secs = GetAddOnCPUUsage(i) / 1000
			local name = GetAddOnInfo(i)

			if secs > 3600 then
				GameTooltip:AddDoubleLine(name, format("%.2f h", secs/3600), 1, 1, 1, 1, 0.2, 0.2)
			elseif secs > 60 then
				GameTooltip:AddDoubleLine(name, format("%.2f m", secs/60), 1, 1, 1, 1, 1, 0.2)
			elseif secs >= 1 then
				GameTooltip:AddDoubleLine(name, format("%.1f s", secs), 1, 1, 1, 0.2, 1, 0.2)
			elseif secs > 0 then
				GameTooltip:AddDoubleLine(name, format("%.1f ms", secs * 1000), 1, 1, 1, 0.2, 1, 0.2)
			end
			total = total + secs
		end

		if total >= 60 then
			GameTooltip:AddDoubleLine(L.Total, format("%.1f m", total/60), 0.4, 0.6, 1, 1, 1, 0.2)
		elseif total >= 1 then
			GameTooltip:AddDoubleLine(L.Total, format("%.1f s", total), 0.4, 0.6, 1, 1, 1, 0.2)
		else
			GameTooltip:AddDoubleLine(L.Total, format("%.1f ms", total * 1000), 0.4, 0.6, 1, 1, 1, 0.2)
		end
	else
		UpdateAddOnMemoryUsage()
		GameTooltip:SetText(L.MemUsage)

		local total = 0
		for i=1, GetNumAddOns() do
			local mem = GetAddOnMemoryUsage(i)
			local name = GetAddOnInfo(i)

			if mem > 0 then
				if mem > 1024 then
					GameTooltip:AddDoubleLine(name, format("%.1f mb", mem/1024), 1, 1, 1, 1, 1, 0.2)
				else
					GameTooltip:AddDoubleLine(name, format("%.1f kb", mem), 1, 1, 1, 0.2, 1, 0.2)
				end
				total = total + mem
			end
		end
		GameTooltip:AddDoubleLine(L.Total, format("%.2f mb", total/1024), 0.4, 0.6, 1, 1, 1, 0.2)
	end
	GameTooltip:Show()
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