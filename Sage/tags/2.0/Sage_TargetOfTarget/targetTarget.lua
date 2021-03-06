--[[
	Sage Target of Target
		A TargetOfTarget frame based on Sage
--]]

SageTargetTarget = Sage:NewModule("Sage-TargetTarget")
local L = SAGE_LOCALS
L.UpdateInterval = "Update Interval"

local function Frame_Update(self)
	self.info.inCombat = UnitAffectingCombat(self.id)
	self.info:UpdateAll()
	self.health:UpdateAll()
	self.npc:Update()
end

local function Frame_OnCreate(self)
	self.Update = Frame_Update

	local info = SageInfo:Create(self)
	info:SetPoint("TOPLEFT", self)
	info:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -16)
	self.info = info

	local health = SageHealth:Create(self)
	health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -18)
	self.health = health

	local npc = SageNPC:Create(self)
	npc:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	npc:SetPoint("BOTTOMRIGHT", self.health , "BOTTOMRIGHT", 0, -12)
	self.npc = npc

	self.click:SetPoint("TOPLEFT", self.info)
	self.click:SetPoint("BOTTOMRIGHT", self.npc)

	self.nextUpdate = 0
	self.interval = self.sets.updateInterval
	self:SetScript("OnUpdate", function(self, elapsed)
		self.nextUpdate = self.nextUpdate - elapsed
		if self.nextUpdate <= 0 then
			self.nextUpdate = self.interval
			self:Update()
		end
	end)
	self:SetHeight(46)
end

function SageTargetTarget:Load()
	local defaults = {
		y = 503,
		x = 686,
		updateInterval = 0.1,
		anchor = "targetRT",
		width = 90,
	}

	self.frame = SageFrame:Create("targettarget", Frame_OnCreate, defaults)
	self.frame.info:UpdateWidth()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function SageTargetTarget:Unload()
	self:UnregisterAllEvents()
	self.frame:Destroy()
end

function SageTargetTarget:PLAYER_TARGET_CHANGED()
	self.frame.nextUpdate = 0
end

function SageTargetTarget:LoadOptions()
	local panel = SageOptions:AddPanel("ToT")

	panel.unit = self.frame.id
	panel:AddShowCurableButton()
	panel:AddTextDisplaySelector()
	panel:AddWidthSlider()
	panel:AddAlphaSlider()
	panel:AddScaleSlider()
	
	local slider = panel:AddSlider(L.UpdateInterval, 0, 3, 0.1)
	local frame = self.frame
	local sets = frame.sets

	slider:SetScript("OnShow", function(self)
		self:SetValue(sets.updateInterval)
	end)
	slider:SetScript("OnValueChanged", function(self,value)
		frame.interval = value
		sets.updateInterval = value
		getglobal(self:GetName() .. "ValText"):SetText(format("%.1f", value))
	end)
end