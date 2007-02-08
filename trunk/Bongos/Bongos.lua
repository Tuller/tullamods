--[[
	Bongos.lua
		Loads global and bar settings and also provides some utility functions
--]]

Bongos = {}


--[[ Configuration Functions ]]--

--lock bar positioning
function Bongos.SetLock(enable)
	if enable then
		BongosDB.locked = 1
		for _, bar in BBar.GetAll() do
			bar:Lock()
		end
	else
		BongosDB.locked = nil
		for _, bar in BBar.GetAll() do
			bar:Unlock()
		end
	end
end

function Bongos.ToggleLock()
	Bongos.SetLock(not BongosDB.locked)
end

function Bongos.IsLocked()
	return BongosDB.locked
end

--enable disable "sticky" bars
function Bongos.SetSticky(enable)
	if enable then
		BongosDB.sticky = 1
	else
		BongosDB.sticky = nil
	end
	BBar.ForAll(BBar.Reanchor)
end

function Bongos.IsSticky()
	return BongosDB.sticky
end


--[[ Utility Functions ]]--

--takes a barID, and performs the specified action on that bar
--this adds two special IDs, "all" for all bars and number-number for a range of IDs
function Bongos.ForBar(id, action, ...)
	assert(id and id ~= '', 'Invalid barID')

	if id == 'all' then
		BBar.ForAll(action, ...)
	else
		local startID, endID = id:match('(%d+)-(%d+)')
		startID = tonumber(startID)
		endID = tonumber(endID)

		if startID and endID then
			for i = startID, endID do
				local bar = BBar.Get(i)
				if bar then
					action(bar, ...)
				end
			end
		else
			local bar = BBar.Get(id)
			if bar then
				action(bar, ...)
			end
		end
	end
end

--perform an action after all saved settings are loaded
function Bongos.AddVarInit(action)
	BVent:AddAction('BONGOS_LOADED', action)
end

--perform an action after BONGOS_LOADED
function Bongos.AddStartup(action)
	BVent:AddAction('BONGOS_STARTUP', action)
end

function Bongos.GetSettings()
	return BongosDB
end

function Bongos.SetBarSets(id, settings)
	if not BongosDB.bars then
		BongosDB.bars = {}
	end
	BongosDB.bars[id] = settings

	return BongosDB.bars[id]
end

function Bongos.GetBarSets(id)
	if BongosDB.bars then
		return BongosDB.bars[id]
	end
end

function Bongos.SetMinimapVis(enable)
	if enable then
		BongosDB.hideMinimap = nil
		BongosMinimapFrame:Show()
	else
		BongosDB.hideMinimap = 1
		BongosMinimapFrame:Hide()
	end
end

function Bongos.ShowMinimap()
	return not BongosDB.hideMinimap
end

--Print a chat message
function BMsg(msg)
	ChatFrame1:AddMessage(format('|cFF00FF66Bongos|r: %s', msg or 'nil'))
end


--[[ Startup ]]--

local function LoadDefaults(currentVersion)
	BongosDB = {
		sticky = 1,
		mapx = -25.07553022700088,
		mapy = -76.43274691276581,
		version = currentVersion,
		bars = {}
	}
	BMsg(BONGOS_NEW_USER)
	LoadAddOn('Bongos_Options')
end

local function UpdateSettings(currentVersion)
	BongosDB.version = currentVersion	

	BMsg(format(BONGOS_UPDATED, currentVersion))
	LoadAddOn('Bongos_Options')
end

Bongos.AddVarInit(function()
	local version = GetAddOnMetadata('Bongos', 'Version')
	if TLib.NeedToInit(BongosDB, version) then
		LoadDefaults(version)
	end
	if TLib.NeedToUpdate(BongosDB, version) then
		UpdateSettings(version)
	end
	BProfile.RegisterForSave('BongosDB')
end)