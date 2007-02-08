--[[
	Sage\main.lua
		Loads global settings
--]]

--where textures for Sage are located
local TEXTURE_PATH = 'Interface\\AddOns\\Sage\\textures\\%s'

--Print a chat message
function SMsg(msg)
	ChatFrame1:AddMessage(format('|cFF19B2FFSage|r: %s', msg or 'nil'))
end

Sage = {}

--[[ Global Frame Configuration ]]--

--lock frame positions
function Sage.SetLock(enable)
	if enable then
		SageDB.locked = 1
		SageFrame.ForAll('Lock')
	else
		SageDB.locked = nil
		SageFrame.ForAll('Unlock')
	end
end

function Sage.IsLocked()
	return SageDB.locked
end

--enable auto docking of frames
function Sage.SetSticky(enable)
	if enable then
		SageDB.sticky = 1
	else
		SageDB.sticky = nil
	end
	SageFrame.ForAll('Reanchor')
end

function Sage.IsSticky()
	return SageDB.sticky
end

--set the statusbar texture for each frame
function Sage.SetBarTexture(texture)
	SageDB.barTexture = texture or 'Blizzard'
	SageStatusBar.UpdateAllTextures()
end

function Sage.GetTextureID()
	return SageDB.barTexture or 'Blizzard'
end

function Sage.GetBarTexture()
	local texture = Sage.GetTextureID()
	if texture == 'Blizzard' then
		return 'Interface\\TargetingFrame\\UI-StatusBar'
	end
	return format(TEXTURE_PATH, texture)
end

--show health percentages
function Sage.ShowPercents(enable)
	if enable then
		SageDB.showPercents = 1
	else
		SageDB.showPercents = nil
	end
	SageInfo.ForAll(SageInfo.ShowPercent, enable)
end

function Sage.ShowingPercents()
	return SageDB.showPercents
end

--always show text
function Sage.ShowText(enable)
	if enable then
		SageDB.showText = 1
	else
		SageDB.showText = nil
	end
	SageStatusBar.UpdateAllText(enable)
end

function Sage.ShowingText()
	return SageDB.showText
end

--color healthbars differently when debuffed
function Sage.ColorHealthOnDebuff(enable)
	if enable then
		SageDB.colorHealthOnDebuff = 1
	else
		SageDB.colorHealthOnDebuff = nil
	end
	SageHealth.SetColorOnDebuff(enable)
end

function Sage.ColoringHealthOnDebuff()
	return SageDB.colorHealthOnDebuff
end

--set the format for displaying healthbar text
function Sage.SetHealthTextMode(mode)
	SageDB.healthTextMode = mode
	SageHealth.ForAll(SageHealth.Update)
end

function Sage.GetHealthTextMode()
	return SageDB.healthTextMode
end

--set the format for displaying manabar text
function Sage.SetManaTextMode(mode)
	SageDB.manaTextMode = mode
	SageMana.ForAll(SageMana.Update)
end

function Sage.GetManaTextMode()
	return SageDB.manaTextMode
end

--[[ Per Frame Configuration ]]--

--show only castable buffs
function Sage.ShowCastableBuffs(frame, enable)
	if enable then
		frame.sets.showCastable = 1
	else
		frame.sets.showCastable = nil
	end

	local buff = frame.buff
	if buff then 
		buff:Update()
	end
end

function Sage.ShowingCastableBuffs(frame)
	return frame.sets.showCastable
end

--show only curable debuffs
function Sage.ShowCurableDebuffs(frame, enable)
	if enable then
		frame.sets.showCurable = 1
	else
		frame.sets.showCurable = nil
	end

	local debuff = frame.debuff
	if debuff then 
		debuff:Update()
	end
end

function Sage.ShowCurableDebuffs(frame)
	return frame.sets.showCurable
end


--show combat text on the frame
function Sage.ShowCombatText(frame, enable)
	if enable then
		frame.sets.showCombatText = 1
		SageCombatText.Register(frame)
	else
		frame.sets.showCombatText = nil
		SageCombatText.Unregister(frame)
	end
end

function Sage.ShowingCombatText(frame)
	return frame.sets.showCombatText
end


--[[ Utility Functions ]]--

function Sage.SetFrameSets(id, sets)
	SageDB.frames[id] = sets
	return SageDB.frames[id]
end

function Sage.GetFrameSets(id)
	return SageDB.frames[id]
end

--Adds an action to do when Sage is first loaded, or a profile is loaded
function Sage.AddStartup(action)
	BVent:AddAction('SAGE_STARTUP', action)
end

--Takes a frameID, and performs action(frame, ...). "all" specifies all bars, and "party" specifies all party members
function Sage.ForFrame(id, action, ...)
	assert(id and id ~= '', 'No frameID given')

	if id == 'all' then
		SageFrame.ForAll(action, ...)
	elseif id == 'party' then
		for i = 1, 4 do
			local bar = SageFrame.Get(id .. i)
			if bar then 
				action(bar, ...) 
			end
		end
	else
		local bar = SageFrame.Get(id)
		if bar then 
			action(bar, ...) 
		end
	end
end

--does action on event if condition is satisfied
--will only add an action to do if there doesn't already exist an action bound to the given ID
local waitingToAct = {}
function Sage.DoOnEvent(id, event, condition, action)
	if not waitingToAct[id] then
		waitingToAct[id] = true

		BVent:AddAction(event, function(thisAction, event)
			if condition() then
				BVent:RemoveAction(event, thisAction)
				action()
				waitingToAct[id] = nil
			end
		end)
	end
end

--if condition, then do action immediately, else wait for the event to happen, then do the acton
function Sage.DoIF(id, event, condition, action)
	if condition() then
		action()
	else
		Sage.DoOnEvent(id, event, condition, action)
	end
end

--Adds a new panel to the options menu when its loaded
function Sage.AddOptionsPanel(title, frameName, OnShow)
	BVent:AddAction('ADDON_LOADED', function(action, event, addon)
		if addon == 'Sage_Options' then
			BVent:RemoveAction(event, action)
			SOptions_CreatePanel(title, frameName, OnShow)
		end
	end)
end


--[[ Startup ]]--

local function LoadDefaults(current)
	SageDB = {
		version = current,
		locked = 1,
		sticky = 1,
		healthTextMode = 1,
		manaTextMode = 1,
		colorHealthOnDebuff = 1,
		barTexture = 'Skewed',
		frames = {},
	}
	SMsg(SAGE_NEW_USER)
	LoadAddOn('Sage_Options')
end

local function UpdateSettings(currentVersion)
	SageDB.version = currentVersion
	SMsg(format(SAGE_UPDATED, currentVersion))
	LoadAddOn('Sage_Options')
end

local function LoadVariables()
	local version = GetAddOnMetadata('Sage', 'Version')

	if TLib.NeedToInit(SageDB, version) then
		LoadDefaults(version)
	elseif TLib.NeedToUpdate(SageDB, version) then
		UpdateSettings(version)
	end
end

Sage.AddStartup(function()
	SProfile.RegisterForSave('SageDB')
	LoadVariables()
	SFont.LoadAll() 
end)

BVent:AddAction('PLAYER_LOGIN', function()
	for id in pairs(SageDB.frames) do
		if not SageFrame.Get(id) then
			SageDB.frames[id] = nil
		end
	end
end)