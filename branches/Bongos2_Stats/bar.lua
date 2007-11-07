--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

BongosStats = Bongos:NewModule("Bongos-Stats")

local L = BONGOS_LOCALS
local NUM_ADDONS_TO_DISPLAY = 15
local UPDATE_DELAY = 1
local topAddOns

local function Stats_AddCPULine(name, secs)
	if secs > 3600 then
		GameTooltip:AddDoubleLine(name, format("%.2f h", secs/3600), 1, 1, 1, 1, 0.2, 0.2)
	elseif secs > 60 then
		GameTooltip:AddDoubleLine(name, format("%.2f m", secs/60), 1, 1, 1, 1, 1, 0.2)
	elseif secs >= 1 then
		GameTooltip:AddDoubleLine(name, format("%.1f s", secs), 1, 1, 1, 0.2, 1, 0.2)
	elseif secs > 0 then
		GameTooltip:AddDoubleLine(name, format("%.1f ms", secs * 1000), 1, 1, 1, 0.2, 1, 0.2)
	end
end

local function Stats_AddMemoryLine(name, size)
	if(size > 1000) then
		GameTooltip:AddDoubleLine(name, format("%.2f mb", size/1000), 1, 1, 1, 1, 1, 0.2)
	elseif(size > 0) then
		GameTooltip:AddDoubleLine(name, format("%.2f kb", size), 1, 1, 1, 0.2, 1, 0.2)
	end
end

local function Stats_UpdateAddonsList(self, watchingCPU)
	if(watchingCPU) then
		UpdateAddOnCPUUsage()
	else
		UpdateAddOnMemoryUsage()
	end

	local total = 0
	for i=1, GetNumAddOns() do
		local value = (watchingCPU and GetAddOnCPUUsage(i)/1000) or GetAddOnMemoryUsage(i)
		local name = GetAddOnInfo(i)
		total = total + value

		for j,addon in ipairs(topAddOns) do
			if(value > addon.value) then
				for k = NUM_ADDONS_TO_DISPLAY, 1, -1 do
					if(k == j) then
						topAddOns[k].value = value
						topAddOns[k].name = GetAddOnInfo(i)
						break
					elseif(k ~= 1) then
						topAddOns[k].value = topAddOns[k-1].value
						topAddOns[k].name = topAddOns[k-1].name
					end
				end
				break
			end
		end
	end

	if (total > 0) then
		if(watchingCPU) then
			GameTooltip:SetText(L.CPUUsage)
		else
			GameTooltip:SetText(L.MemUsage)
		end
		GameTooltip:AddLine("--------------------------------------------------")

		for _,addon in ipairs(topAddOns) do
			if(watchingCPU) then
				Stats_AddCPULine(addon.name, addon.value)
			else
				Stats_AddMemoryLine(addon.name, addon.value)
			end
		end

		GameTooltip:AddLine("--------------------------------------------------")
		if(watchingCPU) then
			Stats_AddCPULine(L.Total, total)
		else
			Stats_AddMemoryLine(L.Total, total)
		end
	end
	GameTooltip:Show()
end

local function Stats_UpdateTooltip(self)
	--clear topAddOns list
	if topAddOns then
		for i,addon in pairs(topAddOns) do
			addon.value = 0
		end
	else
		topAddOns = {}
		for i=1, NUM_ADDONS_TO_DISPLAY do
			topAddOns[i] = {name = "", value = 0}
		end
	end

	Stats_UpdateAddonsList(self, GetCVar("scriptProfile") == "1" and not IsModifierKeyDown())
end

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

	if GameTooltip:IsOwned(self) then
		Stats_UpdateTooltip(self)
	end
end

local function Stats_OnEnter(self)
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	end
	Stats_UpdateTooltip(self)
end

local function Stats_OnLeave(self)
	GameTooltip:Hide()
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

	frame:SetScript("OnEvent", function(self)
		if(GameTooltip:IsOwned(self)) then
			Stats_UpdateTooltip(self)
		end
	end)
	frame:RegisterEvent("MODIFIER_STATE_CHANGED")

	frame:SetScript("OnUpdate", Stats_OnUpdate)
	frame:SetScript("OnClick", Stats_OnClick)
	frame:SetScript("OnEnter", Stats_OnEnter)
	frame:SetScript("OnLeave", Stats_OnLeave)

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
		x = 1254, y = 895, showMemory = true, showPing = true, showFPS = true,
	})
end

function BongosStats:Unload()
	self.bar:Destroy()
end


--[[ Config Functions ]]--

function BongosStats:SetShowFPS(enable)
	local bar = self.bar
	if enable then
		bar.sets.showFPS = true
		Stats_Update(bar.frame)
	else
		bar.sets.showFPS = nil
		bar.frame.fps:SetText("")
	end
end

function BongosStats:SetShowPing(enable)
	local bar = self.bar
	if enable then
		bar.sets.showPing = true
		Stats_Update(bar.frame)
	else
		bar.sets.showPing = nil
		bar.frame.ping:SetText("")
	end
end

function BongosStats:SetShowMemory(enable)
	local bar = self.bar
	if enable then
		bar.sets.showMemory = true
		Stats_Update(bar.frame)
	else
		bar.sets.showMemory = nil
		bar.frame.mem:SetText("")
	end
end