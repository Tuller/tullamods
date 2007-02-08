--[[
	Sage Target
		A Target Frame based on Sage

	TODO
		Streamline the buff and debuff layout code
--]]

local BUFF_SIZE_LARGE = 30
local BUFF_SIZE_SMALL = 16


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
	local combo = parent:CreateFontString(nil, 'OVERLAY')
	combo:SetFontObject(SageFontSmall)
	combo:SetJustifyV('TOP')
	combo:SetNonSpaceWrap(false)
	combo:SetWidth(16)
	combo:SetHeight(75)	

	combo.Update = ComboFrame_Update
	
	return combo
end

--npc info frame
--update the unit's level/name/class/type/faction
local function NPCInfo_Update(self, unit)
	self.class:SetText(SageInfo.GetClass(unit))
	self.type:SetText(SageInfo.GetClassification(unit))
end

local function NPCInfo_Create(parent)
	local npc = CreateFrame('Frame', nil, parent)
	npc:SetAlpha(parent:GetAlpha())

	npc.class = npc:CreateFontString(nil, 'OVERLAY')
	npc.class:SetFontObject(SageFontSmall)
	npc.class:SetJustifyH('LEFT')
	npc.class:SetPoint('LEFT', npc)
	
	npc.type = npc:CreateFontString(nil, 'OVERLAY')
	npc.type:SetFontObject(SageFontSmall)
	npc.type:SetJustifyH('RIGHT')
	npc.type:SetPoint('RIGHT', npc)	

	npc.Update = NPCInfo_Update

	return npc
end


--[[ Update Functions ]]--

local function BuffFrame_PlaceLeft(self)
	local left = self:GetParent().leftContainer
	self:SetPoint('TOPLEFT', left)
	self:SetWidth(left:GetWidth())
	self:SetHeight(left:GetHeight())	
end

local function BuffFrame_PlaceBottom(self)
	local bottom = self:GetParent().bottomContainer
	self:SetPoint('TOPLEFT', bottom)
	self:SetWidth(bottom:GetWidth())
	self:SetHeight(bottom:GetHeight())	
end

local function LayoutBuffs(self, count)
	if UnitIsFriend('player', self.id) then
		BuffFrame_PlaceBottom(self)
	else
		BuffFrame_PlaceLeft(self)
	end
	self:LayoutIcons(count)
end

local function LayoutDebuffs(self, count)
	if UnitIsFriend('player', self.id) then
		BuffFrame_PlaceLeft(self)
	else
		BuffFrame_PlaceBottom(self)
	end
	self:LayoutIcons(count)
end

--hides the manabar if its not mana, and an NPC, because NPC's only use mana
local function UpdateManaBar(self)
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
local function UpdateAll(self)
	local unit = self.id	

	self.npc:Update(unit)
	if self.combo then 
		self.combo:Update(self.sets.numericCombo)
	end
	
	UpdateManaBar(self)

	self.info:UpdateAll()
	self.info:UpdateNameColor()
	self.health:UpdateAll()
	self.mana:Update()
	self.buff:Update()
	self.debuff:Update()
end


--[[ Event Hander ]]--

local function OnEvent()
	if event == "PLAYER_TARGET_CHANGED" then
		UpdateAll(this)
		CloseDropDownMenus()
	elseif this:IsShown() then
		if event == "PLAYER_COMBO_POINTS" then
			this.combo:Update(this.sets.numericCombo)
		elseif arg1 == this.id then
			if event == "UNIT_CLASSIFICATION_CHANGED" then
				this.npc:Update(arg1)
			elseif event == "UNIT_FACTION" then
				this.info:UpdateNameColor()
			end
		end
	end
end


--[[ Startup Functions ]]--

local function AddEvents(frame)
	frame:SetScript("OnEvent", OnEvent)
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("UNIT_FACTION")
	frame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
	if frame.combo then
		frame:RegisterEvent("PLAYER_COMBO_POINTS")
	end

	frame:SetScript("OnReceiveDrag", TargetFrame_OnReceiveDrag)
end

--adds all the stuff to the target frame, this function should only be done once
local function AddBars(self)
	--anchor point for placing buff/debuff frames
	self.leftContainer = CreateFrame("Frame", nil, self)
	self.leftContainer:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, -20)
	self.leftContainer:SetWidth(BUFF_SIZE_LARGE*2)
	self.leftContainer:SetHeight(BUFF_SIZE_LARGE)

	self.extraWidth = (self.extraWidth or 0) + self.leftContainer:GetWidth()

	--combo point display
	local class = select(2, UnitClass('player'))
	if (class == 'DRUID' or class == 'ROGUE') then
		self.combo = ComboFrame_Create(self)
		self.combo:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -16)
		self.extraWidth = (self.extraWidth or 0) + 16
	end

	--unit name, health percentage, and level
	self.info = SageInfo.Create(self)
	if self.combo then
		self.info:SetPoint("TOPLEFT", self, "TOPLEFT", 16, 0)
	else
		self.info:SetPoint("TOPLEFT", self)
	end
	self.info:SetPoint('BOTTOMRIGHT', self.leftContainer, 'TOPLEFT')

	--unit health
	self.health = SageHealth.Create(self)
	self.health:SetPoint('TOPLEFT', self.info, 'BOTTOMLEFT')
	self.health:SetPoint('TOPRIGHT', self.info, 'BOTTOMRIGHT')
	self.health:SetHeight(20)

	local health_OnValueChanged = self.health:GetScript("OnValueChanged")
	self.health:SetScript("OnValueChanged", function() health_OnValueChanged() self.info:UpdateNameColor() end)

	--unit mana
	self.mana = SageMana.Create(self)
	self.mana:SetPoint('TOPLEFT', self.health, 'BOTTOMLEFT')
	self.mana:SetPoint('TOPRIGHT', self.health, 'BOTTOMRIGHT')
	self.mana:SetHeight(12)

	--unit class, classification, and elite status
	self.npc = NPCInfo_Create(self)
	self.npc:SetPoint('TOPLEFT', self.mana, 'BOTTOMLEFT', 0, -1)
	self.npc:SetPoint('TOPRIGHT', self.mana, 'BOTTOMRIGHT', 0, -1)
	self.npc:SetHeight(12)

	--anchor point for placing buff/debuff frames
	self.bottomContainer = CreateFrame("Frame", nil, self)
	self.bottomContainer:SetPoint('TOPLEFT', self.npc, 'BOTTOMLEFT')
	self.bottomContainer:SetWidth(BUFF_SIZE_SMALL * 8)
	self.bottomContainer:SetHeight(BUFF_SIZE_SMALL)

	self.buff   = SageBuff.Create(self, LayoutBuffs)
	self.debuff = SageDebuff.Create(self, LayoutDebuffs)

	if self.sets.showCombatText then 
		SageCombatText.Register(self)
	end
	
	self.click:SetPoint('TOPLEFT', self.info)
	self.click:SetPoint('BOTTOMRIGHT', self.npc)

	self:SetHeight(BUFF_SIZE_SMALL + 13 + 12 + 20 + 20)
end

local function UnregisterBlizzTargetFrame()
	ComboFrame:UnregisterAllEvents()
	ComboFrame:Hide()

	TargetFrameHealthBar:UnregisterAllEvents()
	TargetFrameManaBar:UnregisterAllEvents()
	TargetFrame:UnregisterAllEvents()
	TargetFrame:Hide()

	--this hides the mobhealth display, if it exists
	if MobHealthFrame and type(MobHealthFrame) == 'table' then
		MobHealthFrame:Hide()
	end
end


--[[
	this function is called when the target frame is actually created
	since we first create the frame just so we can move it around, we need to setup
	when we need to actually add all the "stuff" to it.
	This is handled by the BEvent call to AddBars
--]]

local function OnCreate(frame)
	UnregisterBlizzTargetFrame()
	AddBars(frame)
end


--[[
	This function's called when either a profile is loaded, or when Sage first starts up
	We should create enough of the frame so that it can be moved around, and setup
	everything necessary for adding all the stuff to the frame when we actually need it
--]]

Sage.AddStartup(function()
	if not Sage.GetFrameSets('target') then
		Sage.SetFrameSets('target', {
			combatTextSize = 24, 
			showCombatText = 1, 
			anchor = 'focusRT', 
			minWidth = 100, 
			x = 462,
			y = 511
		})
	end

	local frame = SageFrame.Create('target', OnCreate)
	frame.info:UpdateWidth()
	AddEvents(frame)
end)