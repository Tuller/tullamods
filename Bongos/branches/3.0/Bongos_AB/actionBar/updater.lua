--[[
	Updater.lua
		Handles ranged updating + buff highlighting updating
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')
local Config = Bongos:GetModule('ActionBar-Config')
local Updater = CreateFrame('Frame')
Action.Updater = Updater


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
local function CloneTable(t, toClone)
	local changed = false

	--remove any values not in tClone
	for i in pairs(t) do
		if not toClone[i] then
			t[i] = nil
			changed = true
		end
	end

	--add any values in tClone that are not in t
	for i,v in pairs(toClone) do
		if not t[i] then
			t[i] = v
			changed = true
		end
	end

	return changed
end

--[[
	The Code
--]]

--buff and debuff caches
local targetBuffs = {}
local targetDebuffs = {}
local playerBuffs = {}
local newVals = {} --store new info in here

--[[ Events ]]--

--buff and debuff updating stuff
Updater:SetScript('OnEvent', function(self, event, unit)
	if Config:HighlightingBuffs() then
		if event == 'PLAYER_TARGET_CHANGED' then
			self:UpdateTargetBuffs()
		elseif event == 'UNIT_AURA' then
			if unit == 'target' then
				self:UpdateTargetBuffs()
			end
		elseif event == 'PLAYER_AURAS_CHANGED' then
			self:UpdatePlayerBuffs()
		end
	end
end)
Updater:RegisterEvent('UNIT_AURA')
Updater:RegisterEvent('PLAYER_AURAS_CHANGED')
Updater:RegisterEvent('PLAYER_TARGET_CHANGED')


--on update script, handles throttled buff and debuff updating as well as range updating
Updater:SetScript('OnUpdate', function(self, elapsed)
	if self.shouldUpdateBuffs then
		self.shouldUpdateBuffs = nil

		for button in Action.Button:GetUpdatable() do
			button:UpdateState()
		end
	end

	if self.nextUpdate < 0 then
		self.nextUpdate = self.delay

		for button in Action.Button:GetUpdatable() do
			button:OnUpdate(self.delay)
		end
	else
		self.nextUpdate = self.nextUpdate - elapsed
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

	if CloneTable(playerBuffs, newVals) then
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
	local changed = ClearTable(targetDebuffs)

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
	if CloneTable(targetBuffs, newVals) then
		changed = true
	end

	return changed
end

function Updater:UpdateEnemyTargetDebuffs()
	--friendly target, clear target debuffs
	local changed = ClearTable(targetBuffs)


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
	if CloneTable(targetDebuffs, newVals) then
		changed = true
	end

	return changed
end

function Updater:ClearTargetBuffsAndDebuffs()
	local changed = false

	if ClearTable(targetBuffs) then
		changed = true
	end
	if ClearTable(targetDebuffs) then
		changed = true
	end

	return changed
end


--[[ Access Functions ]]--

function Updater:TargetHasBuff(buff)
	return targetBuffs[buff]
end

function Updater:TargetHasDebuff(debuff)
	return targetDebuffs[debuff]
end

function Updater:PlayerHasBuff(buff)
	return playerBuffs[buff]
end