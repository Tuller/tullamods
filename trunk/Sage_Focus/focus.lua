--[[
	Sage Target
		A Target Frame based on Sage
--]]

SageFocus = Sage:NewModule("Sage-Focus")

local BUFF_SIZE_LARGE = 30
local BUFF_SIZE_SMALL = 16


--[[ UI Templates ]]--

--buff frame
local function BuffFrame_PlaceLeft(self)
	local left = self:GetParent().leftContainer
	self:SetPoint("TOPLEFT", left)
	self:SetWidth(left:GetWidth())
	self:SetHeight(left:GetHeight())
end

local function BuffFrame_PlaceBottom(self)
	local bottom = self:GetParent().bottomContainer
	self:SetPoint("TOPLEFT", bottom)
	self:SetWidth(bottom:GetWidth())
	self:SetHeight(bottom:GetHeight())
end

--main frame
local function Frame_LayoutBuffs(self, count)
	if UnitIsFriend("player", self.id) then
		BuffFrame_PlaceBottom(self)
	else
		BuffFrame_PlaceLeft(self)
	end
	self:LayoutIcons(count)
end

local function Frame_LayoutDebuffs(self, count)
	if UnitIsFriend("player", self.id) then
		BuffFrame_PlaceLeft(self)
	else
		BuffFrame_PlaceBottom(self)
	end
	self:LayoutIcons(count)
end

--hides the manabar if its not mana, and an NPC, because NPC"s only use mana
local function Frame_UpdateManaBar(self)
	if not UnitIsPlayer(self.id) and UnitPowerType(self.id) ~= 0 then
		self.mana:Hide()
		self.npc:SetPoint("TOPLEFT",  self.health, "BOTTOMLEFT")
		self.npc:SetPoint("BOTTOMRIGHT",  self.health, "BOTTOMRIGHT", 0, -self.mana:GetHeight())
	else
		self.mana:Show()
		self.npc:SetPoint("TOPLEFT",  self.mana, "BOTTOMLEFT")
		self.npc:SetPoint("BOTTOMRIGHT",  self.mana, "BOTTOMRIGHT", 0, -self.mana:GetHeight())
	end
end

--update everything about the target
local function Frame_Update(self)
	local unit = self.id

	self:UpdateManaBar()
	self.npc:Update()
	self.info:UpdateAll()
	self.info:UpdateNameColor()
	self.health:UpdateAll()
	self.mana:Update()
	self.buff:Update()
	self.debuff:Update()
	self.cast:Update()
end


--[[ Startup Functions ]]--

--adds all the stuff to the target frame, this function should only be done once
local function Frame_AddBars(self)
	self.UpdateManaBar = Frame_UpdateManaBar
	self.Update = Frame_Update

	--anchor point for placing buff/debuff frames
	self.leftContainer = CreateFrame("Frame", nil, self)
	self.leftContainer:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -20)
	self.leftContainer:SetWidth(BUFF_SIZE_LARGE*2)
	self.leftContainer:SetHeight(BUFF_SIZE_LARGE)
	self.extraWidth = (self.extraWidth or 0) + self.leftContainer:GetWidth()

	--unit name, health percentage, and level
	self.info = SageInfo:Create(self, nil, true)
	self.info:SetPoint("TOPLEFT", self)
	self.info:SetPoint("BOTTOMRIGHT", self.leftContainer, "TOPLEFT")

	--unit health
	self.health = SageHealth:Create(self)
	self.health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	self.health:SetPoint("TOPRIGHT", self.info, "BOTTOMRIGHT")
	self.health:SetHeight(20)

	local OnValueChanged = self.health:GetScript("OnValueChanged")
	self.health:SetScript("OnValueChanged", function(self, value)
		OnValueChanged(self, value)
		self:GetParent().info:UpdateNameColor()
	end)

	--unit mana
	self.mana = SageMana:Create(self)
	self.mana:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	self.mana:SetPoint("TOPRIGHT", self.health, "BOTTOMRIGHT")
	self.mana:SetHeight(12)

	--unit class, classification, and elite status
	self.npc = SageNPC:Create(self)
	self.npc:SetPoint("TOPLEFT", self.mana, "BOTTOMLEFT")
	self.npc:SetPoint("TOPRIGHT", self.mana, "BOTTOMRIGHT")
	self.npc:SetHeight(12)

	--anchor point for placing buff/debuff frames
	self.bottomContainer = CreateFrame("Frame", nil, self)
	self.bottomContainer:SetPoint("TOPLEFT", self.npc, "BOTTOMLEFT")
	self.bottomContainer:SetWidth(BUFF_SIZE_SMALL * 8)
	self.bottomContainer:SetHeight(BUFF_SIZE_SMALL)

	self.buff   = SageBuff:Create(self, nil, Frame_LayoutBuffs)
	self.debuff = SageBuff:Create(self, nil, Frame_LayoutDebuffs, true)

	if self.sets.showCombatText then
		SageCombat:Register(self)
	end

	--Not using dynamic anchoring here to allow the npc and mana bars to move around properly
	self.click:SetPoint("TOPLEFT", self.info)
	self.click:SetPoint("TOPRIGHT", self.info)
	self.click:SetHeight(16 + 20 + 12)

	self.cast = SageCast:Create(self)
	self.cast:SetAllPoints(self.npc)

	self:SetHeight(BUFF_SIZE_SMALL + 13 + 12 + 20 + 20)
end

function SageFocus:Load()
	local defaults = {
		combatTextSize = 24,
		x = 15.71428298950195,
		showCastable = true,
		y = 999.4287719726563,
		showCombatText = true,
		anchor = "playerBL",
		textMode = 2,
		width = 120,
	}

	self.frame = SageFrame:Create("focus", Frame_AddBars, defaults)
	self.frame.info:UpdateWidth()

	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
end

function SageFocus:Unload()
	self:UnregisterAllEvents()
	self.frame:Destroy()
end

function SageFocus:PLAYER_FOCUS_CHANGED()
	self.frame:Update()
end

function SageFocus:LoadOptions()
	local panel = SageOptions:AddPanel("Focus", "focus")
end