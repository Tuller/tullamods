--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Stats = Bongos:NewModule('Stats')
Stats.Frame = Bongos:CreateWidgetClass('Button')

local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-Stats')
BINDING_HEADER_BSTATS = L.BongosStats
BINDING_NAME_BSTATSTOGGLE = L.ToggleBongosStats


--[[ Startup ]]--

function Stats:Load()
	local defaults = {
		x = 10,
		y = -215,
		point = 'TOPRIGHT',
		scale = 0.9,
		showMemory = true,
		showPing = true,
		showFPS = true,
	}

	local bar, isNew = Bongos.Bar:Create('stats', defaults)
	self.bar = bar

	if isNew then
		self:OnBarCreate(bar)
	end
end

function Stats:Unload()
	self.bar.frame.ping:SetText('')
	self.bar.frame.fps:SetText('')
	self.bar.frame.mem:SetText('')
	self.bar:Destroy()
end

function Stats:OnBarCreate(bar)
	bar.frame = self.Frame:Create(bar)
	bar:SetHeight(20)

	bar.CreateMenu = function(self)
		local menu = Bongos.Menu:Create(self.id)
		local panel = menu:AddLayoutPanel()

		local showMemory = panel:CreateCheckButton(L.ShowMemory)
		showMemory:SetScript('OnShow', function(b) b:SetChecked(self.sets.showMemory) end)
		showMemory:SetScript('OnClick', function() Stats:SetShowMemory(not self.sets.showMemory) end)

		local showFPS = panel:CreateCheckButton(L.ShowFPS)
		showFPS:SetScript('OnShow', function(b) b:SetChecked(self.sets.showFPS) end)
		showFPS:SetScript('OnClick', function() Stats:SetShowFPS(not self.sets.showFPS) end)

		local showPing = panel:CreateCheckButton(L.ShowPing)
		showPing:SetScript('OnShow', function(b) b:SetChecked(self.sets.showPing) end)
		showPing:SetScript('OnClick', function() Stats:SetShowPing(not self.sets.showPing) end)

		return menu
	end
end


--[[ Config Functions ]]--

function Stats:SetShowFPS(enable)
	local bar = self.bar
	if enable then
		bar.sets.showFPS = true
	else
		bar.sets.showFPS = nil
		bar.frame.fps:SetText('')
	end
	bar.frame:Update()
end

function Stats:SetShowPing(enable)
	local bar = self.bar
	if enable then
		bar.sets.showPing = true
	else
		bar.sets.showPing = nil
		bar.frame.ping:SetText('')
	end
	bar.frame:Update()
end

function Stats:SetShowMemory(enable)
	local bar = self.bar
	if enable then
		bar.sets.showMemory = true
	else
		bar.sets.showMemory = nil
		bar.frame.mem:SetText('')
	end
	bar.frame:Update()
end


--[[ Stats Frame Widget ]]--

local NUM_ADDONS_TO_DISPLAY = 15
local UPDATE_DELAY = 1
local topAddOns

local StatsFrame = Stats.Frame

function StatsFrame:Create(parent)
	local f = self:New(CreateFrame('Button', nil, parent))
	f:RegisterForClicks('AnyUp')
	f:SetAllPoints(parent)

	f.fps = f:CreateFontString()
	f.fps:SetFontObject('GameFontNormalLarge')
	f.fps:SetPoint('LEFT', f)

	f.mem = f:CreateFontString()
	f.mem:SetFontObject('GameFontHighlightLarge')
	f.mem:SetPoint('LEFT', f.fps, 'RIGHT', 2, 0)

	f.ping = f:CreateFontString()
	f.ping:SetFontObject('GameFontHighlightLarge')
	f.ping:SetPoint('LEFT', f.mem, 'RIGHT', 2, 0)

	f:SetScript('OnUpdate', self.OnUpdate)
	f:SetScript('OnClick', self.OnClick)
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)
	f:SetScript('OnShow', self.OnShow)
	f.nextUpdate = 0

	return f
end

function StatsFrame:OnClick()
	if IsAltKeyDown() then
		ReloadUI()
	end
end

function StatsFrame:OnEnter()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
	end
	self:UpdateTooltip()
end

function StatsFrame:OnLeave()
	GameTooltip:Hide()
end

function StatsFrame:OnShow()
	self.nextUpdate = 0
end

function StatsFrame:OnUpdate(elapsed)
	if self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
	else
		self.nextUpdate = UPDATE_DELAY
		self:Update()
	end
end

function StatsFrame:AddCPULine(name, secs)
	if secs > 3600 then
		GameTooltip:AddDoubleLine(name, format('%.2f h', secs/3600), 1, 1, 1, 1, 0.2, 0.2)
	elseif secs > 60 then
		GameTooltip:AddDoubleLine(name, format('%.2f m', secs/60), 1, 1, 1, 1, 1, 0.2)
	elseif secs >= 1 then
		GameTooltip:AddDoubleLine(name, format('%.1f s', secs), 1, 1, 1, 0.2, 1, 0.2)
	elseif secs > 0 then
		GameTooltip:AddDoubleLine(name, format('%.1f ms', secs * 1000), 1, 1, 1, 0.2, 1, 0.2)
	end
end

function StatsFrame:AddMemoryLine(name, size)
	if size > 1000 then
		GameTooltip:AddDoubleLine(name, format('%.2f mb', size/1000), 1, 1, 1, 1, 1, 0.2)
	elseif size > 0 then
		GameTooltip:AddDoubleLine(name, format('%.2f kb', size), 1, 1, 1, 0.2, 1, 0.2)
	end
end

function StatsFrame:UpdateAddonsList(watchingCPU)
	if watchingCPU then
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
			if value > addon.value then
				for k = NUM_ADDONS_TO_DISPLAY, 1, -1 do
					if k == j then
						topAddOns[k].value = value
						topAddOns[k].name = GetAddOnInfo(i)
						break
					elseif k ~= 1 then
						topAddOns[k].value = topAddOns[k-1].value
						topAddOns[k].name = topAddOns[k-1].name
					end
				end
				break
			end
		end
	end

	if total > 0 then
		if watchingCPU then
			GameTooltip:SetText(L.CPUUsage)
		else
			GameTooltip:SetText(L.MemUsage)
		end
		GameTooltip:AddLine('--------------------------------------------------')

		for _,addon in ipairs(topAddOns) do
			if watchingCPU then
				self:AddCPULine(addon.name, addon.value)
			else
				self:AddMemoryLine(addon.name, addon.value)
			end
		end

		GameTooltip:AddLine('--------------------------------------------------')
		if watchingCPU then
			self:AddCPULine(L.Total, total)
		else
			self:AddMemoryLine(L.Total, total)
		end
	end
	GameTooltip:Show()
end

function StatsFrame:UpdateTooltip()
	--clear topAddOns list
	if topAddOns then
		for i,addon in pairs(topAddOns) do
			addon.value = 0
		end
	else
		topAddOns = {}
		for i=1, NUM_ADDONS_TO_DISPLAY do
			topAddOns[i] = {name = '', value = 0}
		end
	end

	self:UpdateAddonsList(GetCVar('scriptProfile') == '1' and not IsModifierKeyDown())
end

--display frame
function StatsFrame:Update()
	local parent = self:GetParent()
	local sets = parent.sets

	if sets.showFPS then
		self.fps:SetFormattedText('%.1ffps', GetFramerate())
	end

	if sets.showMemory then
		self.mem:SetFormattedText('%.3fmb', gcinfo() / 1024)
	end

	if sets.showPing then
		local latency = select(3, GetNetStats())
		if latency > PERFORMANCEBAR_MEDIUM_LATENCY then
			self.ping:SetTextColor(1, 0, 0)
		elseif latency > PERFORMANCEBAR_LOW_LATENCY then
			self.ping:SetTextColor(1, 1, 0)
		else
			self.ping:SetTextColor(0, 1, 0)
		end
		self.ping:SetFormattedText('%dms', latency)
	end

	local width = self.fps:GetStringWidth() + self.mem:GetStringWidth() + self.ping:GetStringWidth()
	parent:SetWidth(max(24, width + 4))
end