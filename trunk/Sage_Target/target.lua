--[[
	Sage Target
		A Target Frame based on Sage
--]]

SageTarget = Sage:NewModule("Sage-Target")

local BUFF_SIZE_LARGE = 32
local BUFF_SIZE_SMALL = 16
local class = select(2, UnitClass("player"))
local hasCombo = (class == "DRUID" or class == "ROGUE")
local L = SAGE_LOCALS
L.NumericCombo = "Numeric Combo Display"


--[[ UI Templates ]]--

--combo frame
local function ComboFrame_Update(self, numeric)
	local comboPoints = GetComboPoints()

	if comboPoints > 0 then
		local text
		if numeric then
			text = comboPoints
		else
			text = "C"
			if comboPoints > 1 then
				text = text .. " O"
				if comboPoints > 2 then
					text = text .. " M"
					if comboPoints > 3 then
						text = text .. " B"
						if comboPoints > 4 then
							text = text .. " O"
						end
					end
				end
			end
		end

		if comboPoints > 4 then
			self:SetTextColor(1, 0.5, 0)
		else
			self:SetTextColor(1, 0.9, 0.1)
		end
		self:SetText(text)
		self:Show()
	else
		self:Hide()
	end
end

local function ComboFrame_Create(parent)
	local combo = parent:CreateFontString(nil, "OVERLAY")
	combo:SetFontObject(SageFont:GetSmallOutsideFont())
	combo:SetJustifyV("TOP")
	combo:SetNonSpaceWrap(false)
	combo:SetWidth(16); combo:SetHeight(75)

	combo.Update = ComboFrame_Update

	return combo
end


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

	if self.combo then
		self.combo:Update(self.sets.numericCombo)
	end

	self:UpdateManaBar()
	self.info:UpdateAll()
	self.info:UpdateNameColor()
	self.health:UpdateAll()
	self.mana:Update()
	self.buff:Update()
	self.debuff:Update()
	self.cast:Update()
	self.npc:Update()
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

	--combo point display
	if hasCombo then
		self.combo = ComboFrame_Create(self)
		self.combo:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -16)
		self.extraWidth = (self.extraWidth or 0) + 16
	end

	--unit name, health percentage, and level
	self.info = SageInfo:Create(self, nil, true)
	if self.combo then
		self.info:SetPoint("TOPLEFT", self, "TOPLEFT", 16, 0)
	else
		self.info:SetPoint("TOPLEFT", self)
	end
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
	self:SetScript("OnReceiveDrag", TargetFrame_OnReceiveDrag)
end

local function UnregisterBlizzTargetFrame()
	ComboFrame:UnregisterAllEvents()
	ComboFrame:Hide()

	TargetFrameHealthBar:UnregisterAllEvents()
	TargetFrameManaBar:UnregisterAllEvents()
	TargetFrame:UnregisterAllEvents()
	TargetFrame:Hide()

	--this hides the mobhealth display, if it exists
	if MobHealthFrame and type(MobHealthFrame) == "table" then
		MobHealthFrame:Hide()
	end
end


--[[
	this function is called when the target frame is actually created
	since we first create the frame just so we can move it around, we need to setup
	when we need to actually add all the "stuff" to it.
	This is handled by the BEvent call to AddBars
--]]

local function Frame_OnCreate(self)
	UnregisterBlizzTargetFrame()
	Frame_AddBars(self)
end


--[[
	This function"s called when either a profile is loaded, or when Sage first starts up
	We should create enough of the frame so that it can be moved around, and setup
	everything necessary for adding all the stuff to the frame when we actually need it
--]]

function SageTarget:Load()
	local defaults = {
		combatTextSize = 24,
		x = 303.7142028808594,
		scale = 1.25,
		showCombatText = true,
		y = 877.7142944335938,
		width = 120,
	}

	self.frame = SageFrame:Create("target", Frame_OnCreate, defaults)
	self.frame.info:UpdateWidth()
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	if(hasCombo) then self:RegisterEvent("PLAYER_COMBO_POINTS") end
end

function SageTarget:Unload()
	self:UnregisterAllEvents()
	self.frame:Destroy()
end

function SageTarget:PLAYER_TARGET_CHANGED()
	self.frame:Update()
	CloseDropDownMenus()
end

function SageTarget:PLAYER_COMBO_POINTS()
	local frame = self.frame
	if(frame:IsShown()) then
		frame.combo:Update(frame.sets.numericCombo)
	end
end

function SageTarget:LoadOptions()
	local panel = SageOptions:AddPanel("Target")
	
	if(hasCombo) then
		local frame = self.frame
		local function Numeric_OnShow(self)
			self:SetChecked(frame.sets.numericCombo)
		end
		local function Numeric_OnClick(self)
			frame.sets.numericCombo = self:GetChecked() or nil
			frame.combo:Update(frame.sets.numericCombo)
		end
		panel:AddCheckButton(L.NumericCombo, Numeric_OnClick, Numeric_OnShow)
	end
	panel:AddUnitOptions(self.frame.id)
end