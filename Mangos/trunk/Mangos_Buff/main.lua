--[[
	Updater.lua
		Handles ranged updating + buff highlighting updating
--]]

local Mangos = Mangos

--[[ Local Functions ]]--

--clear a table, returning true if there was stuff to clear
local function ClearTable(t)
	if next(t) then
		for i in pairs(t) do
			t[i] = nil
		end
		return true
	end
end

--remove any values from t that are not in toClone
--adds any values from tableToClone that are not in t
--requires that both tables be using the same key value pairs
local function CloneTable(from, to)
	local changed = false

	for i,oldVal in pairs(to) do
		local newVal = from[i]
		if oldVal ~= newVal then
			to[i] = newVal
			changed = true
		end
	end

	for i,newVal in pairs(from) do
		local oldVal = to[i]
		if oldVal ~= newVal then
			to[i] = newVal
			changed = true
		end
	end
	
	return changed
end

--[[
	The Code
--]]

local Updater = CreateFrame('Frame')

Updater.targetBuffs = {}
Updater.targetDebuffs = {}
Updater.playerBuffs = {}

--buff and debuff caches
local newVals = {} --store new info in here

--[[ Events ]]--

--buff and debuff updating stuff
Updater:SetScript('OnEvent', function(self, event, unit)
	if event == 'PLAYER_TARGET_CHANGED' then
		self:UpdateTargetBuffs()
	elseif event == 'UNIT_AURA' then
		if unit == 'target' then
			self:UpdateTargetBuffs()
		end
	elseif event == 'PLAYER_AURAS_CHANGED' then
		self:UpdatePlayerBuffs()
	elseif event == 'PLAYER_ENTERING_WORLD' then
		self:UpdateTargetBuffs()
		self:UpdatePlayerBuffs()
	end
end)
Updater:RegisterEvent('UNIT_AURA')
Updater:RegisterEvent('PLAYER_AURAS_CHANGED')
Updater:RegisterEvent('PLAYER_TARGET_CHANGED')
Updater:RegisterEvent('PLAYER_ENTERING_WORLD')


--on update script, handles throttled buff and debuff updating as well as range updating
Updater:SetScript('OnUpdate', function(self, elapsed)
	if self.shouldUpdateBuffs then
		self.shouldUpdateBuffs = nil

		for i = 1, Mangos:NumBars() do
			local f = Mangos.Frame:Get(i)
			if f:IsVisible() then
				for _,b in pairs(f.buttons) do
					if HasAction(b.action) then
						ActionButton_UpdateState(b)
					end
				end
			end
		end
	end
end)
Updater.nextUpdate = 1
Updater.delay = 0.025


--[[ Update Functions ]]--

function Updater:UpdatePlayerBuffs()
	local changed = false

	ClearTable(newVals)

	local buff
	local i = 1
	repeat
		buff = UnitBuff('player', i)
		if buff then
			newVals[buff] = true
		end
		i = i + 1
	until not buff

	if CloneTable(newVals, self.playerBuffs) then
		changed = true
	end

	--something changed, trigger update buffs
	if changed then
		self.shouldUpdateBuffs = true
	end
end

function Updater:UpdateTargetBuffs()
	local changed = false

	if UnitExists('target') then
		if UnitIsFriend('player', 'target') then
			changed = self:UpdateFriendlyTargetBuffs()
		else
			changed = self:UpdateEnemyTargetDebuffs()
		end
	else
		changed = self:ClearTargetBuffsAndDebuffs()
	end

	--if change, mark for updating
	if changed then
		self.shouldUpdateBuffs = true
	end
end


function Updater:UpdateFriendlyTargetBuffs()
	--friendly target, clear target debuffs
	local changed = ClearTable(self.targetDebuffs)

	--add all target buffs into newVals
	ClearTable(newVals)
	local i = 1
	local buff
	repeat
		buff = UnitBuff('target', i)
		if buff then
			newVals[buff] = true
		end
		i = i + 1
	until not buff

	--set changed to true if the target buffs table has changed
	if CloneTable(newVals, self.targetBuffs) then
		changed = true
	end

	return changed
end

function Updater:UpdateEnemyTargetDebuffs()
	--friendly target, clear target debuffs
	local changed = ClearTable(self.targetBuffs)

	--update debuffs on enemy targets
	ClearTable(newVals)
	local i = 1
	local buff, cooldown, _
	repeat
		buff, _, _, _, _, cooldown = UnitDebuff('target', i)
		if buff and cooldown then
			newVals[buff] = true
		end
		i = i + 1
	until not buff

	--set changed to true if the target debuffs table has changed
	if CloneTable(newVals, self.targetDebuffs) then
		changed = true
	end

	return changed
end

function Updater:ClearTargetBuffsAndDebuffs()
	local changed = false

	if ClearTable(self.targetBuffs) then
		changed = true
	end
	if ClearTable(self.targetDebuffs) then
		changed = true
	end

	return changed
end


--[[ Access Functions ]]--

function Updater:TargetHasBuff(buff)
	return self.targetBuffs[buff]
end

function Updater:TargetHasDebuff(debuff)
	return self.targetDebuffs[debuff]
end

function Updater:PlayerHasBuff(buff)
	return self.playerBuffs[buff]
end


--[[ Action Button Updating ]]--

local function ActionButton_UpdateBorder(self, spell)
	if spell then
		if UnitExists('target') then
			if UnitIsFriend('player', 'target') then
				if Updater:TargetHasBuff(spell) then
					self:GetCheckedTexture():SetVertexColor(0, 1, 0)
					return true
				end
			elseif Updater:TargetHasDebuff(spell) then
				self:GetCheckedTexture():SetVertexColor(1, 0, 1)
				return true
			end
		end

		if Updater:PlayerHasBuff(spell) and not UnitIsFriend('player', 'target') then
			self:GetCheckedTexture():SetVertexColor(0, 1, 0)
			return true
		end
	end
	self:GetCheckedTexture():SetVertexColor(1, 1, 1)
end

local function ActionButton_IsSpellInUse(self)
	local spellID = self.spellID
	if spellID then
		if self.type == 'macro' then
			return ActionButton_UpdateBorder(self, GetMacroSpell(spellID))
		end
		return ActionButton_UpdateBorder(self, spellID)
	end
end

local function ActionButton_UpdateSpell(self)
	if self.action then
		local type, arg1, arg2 = GetActionInfo(self.action)

		self.type = type
		if type == 'spell' then
			if arg1 and arg2 and arg1 > 0 then
				self.spellID = GetSpellName(arg1, arg2)
			else
				self.spellID = nil
			end
		elseif type == 'item' then
			self.spellID = GetItemSpell(arg1)
		else
			self.spellID = arg1
		end

		ActionButton_UpdateState(self)
	end
end

hooksecurefunc('ActionButton_UpdateState', function(self)
	local self = self or this
	self:SetChecked(ActionButton_IsSpellInUse(self) or self:GetChecked())
end)

hooksecurefunc('ActionButton_UpdateAction', function(self)
	ActionButton_UpdateSpell(self or this)
end)