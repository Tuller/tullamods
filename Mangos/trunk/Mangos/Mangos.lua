--[[
	Mangos.lua
		Driver for Mangos Frames
--]]

Mangos = LibStub('AceAddon-3.0'):NewAddon('Mangos', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Mangos')
local CURRENT_VERSION = GetAddOnMetadata('Mangos', 'Version')


--[[ Startup ]]--

function Mangos:OnInitialize()
	--register database events
	self.db = LibStub('AceDB-3.0'):New('MangosDB', self:GetDefaults(), 'Default')
	self.db.RegisterCallback(self, 'OnNewProfile')
	self.db.RegisterCallback(self, 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileCopied')
	self.db.RegisterCallback(self, 'OnProfileReset')
	self.db.RegisterCallback(self, 'OnProfileDeleted')

	--version update
	if MangosVersion then
		if MangosVersion ~= CURRENT_VERSION then
			self:UpdateSettings(MangosVersion:match('(%w+)%.(%w+)%.(%w+)'))
			self:UpdateVersion()
		end
	--new user
	else
		MangosVersion = CURRENT_VERSION
	end

	--slash command support
	self:RegisterSlashCommands()

	--create a loader for the options menu
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn('Mangos_Config')
	end)

	--keybound support
	local kb = LibStub('LibKeyBound-1.0')
	kb.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
	kb.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')

	--button facade support
	local LBF = LibStub('LibButtonFacade', true)
	if LBF then
		LBF:RegisterSkinCallback('Mangos', self.OnSkin, self)
	end

	--hide blizzard junk
	self:HideBlizzard()
end

function Mangos:OnEnable()
	self:Load()
end

--[[ Version Updating ]]--

function Mangos:GetDefaults()
	return {
		profile = {
			possessBar = 1,

			ab = {
				count = 10,
				showgrid = true,
				style = {'Entropy: Copper', 0.5, true},
			},

			petStyle  = {'Entropy: Silver', 0.5, nil},

			classStyle = {'Entropy: Silver', 0.5, nil},

--			bagStyle = {'Entropy: Bronze', 0.5, nil},

			frames = {}
		}
	}
end

function Mangos:UpdateSettings(major, minor, bugfix)
	--do stuff
end

function Mangos:UpdateVersion()
	MangosVersion = CURRENT_VERSION
	self:Print(format(L.Updated, MangosVersion))
end


--Load is called  when the addon is first enabled, and also whenever a profile is loaded
local function HasClassBar()
	local _,class = UnitClass('player')
	return class == 'PALADIN' or class == 'DRUID' or class == 'WARRIOR' or class == 'ROGUE'
end

function Mangos:Load()
	for i = 1, self:NumBars() do
		self.ActionBar:New(i)
	end
	if HasClassBar() then
		self.ClassBar:New()
	end
	self.PetBar:New()
	self.BagBar:New()
	self.MenuBar:New()

	--button facade support
	local bf = LibStub('LibButtonFacade', true)
	if bf then
		bf:Group('Mangos', ACTIONBAR_LABEL):Skin(unpack(self.db.profile.ab.style))
		bf:Group('Mangos', 'Pet Bar'):Skin(unpack(self.db.profile.petStyle))
		bf:Group('Mangos', 'Class Bar'):Skin(unpack(self.db.profile.classStyle))
--		bf:Group('Mangos', 'Bag Bar'):Skin(unpack(self.db.profile.bagStyle))
	end

	--load in extra functionality
	for _,module in self:IterateModules() do
		module:Load()
	end

	--anchor everything
	self.Frame:ForAll('Reanchor')
end

--unload is called when we're switching profiles
function Mangos:Unload()
	self.ActionBar:ForAll('Free')
	self.Frame:ForFrame('pet', 'Free')
	self.Frame:ForFrame('class', 'Free')
	self.Frame:ForFrame('menu', 'Free')
	self.Frame:ForFrame('bags', 'Free')

	--unload any module stuff
	for _,module in self:IterateModules() do
		module:Unload()
	end
end


--[[ Blizzard Stuff Hiding ]]--

function Mangos:HideBlizzard()
	RANGE_INDICATOR = ''

	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarRight'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarLeft'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomLeft'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomRight'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MainMenuBar'] = nil

	MultiActionBar_UpdateGrid = Multibar_EmptyFunc
	MainMenuBar:UnregisterAllEvents()
	MainMenuBar:Hide()

	BonusActionBarFrame:UnregisterAllEvents()
	ShapeshiftBarFrame:UnregisterAllEvents()
	BonusActionBarFrame:Hide()
end


--[[ Button Facade Events ]]--

function Mangos:OnSkin(skin, glossAlpha, gloss, group, button, colors)
	local styleDB
	if group == ACTIONBAR_LABEL then
		styleDB = self.db.profile.ab.style
	elseif group == 'Pet Bar' then
		styleDB = self.db.profile.petStyle
	elseif group == 'Class Bar' then
		styleDB = self.db.profile.classStyle
--[[
	elseif group == 'Bag Bar' then
		styleDB = self.db.profile.bagStyle
--]]
	end

	if styleDB then
		styleDB[1] = skin
		styleDB[2] = glossAlpha
		styleDB[3] = gloss
		styleDB[4] = colors
	end
end


--[[ Keybound Events ]]--

function Mangos:LIBKEYBOUND_ENABLED()
	for _,frame in self.Frame:GetAll() do
		if frame.KEYBOUND_ENABLED then
			frame:KEYBOUND_ENABLED()
		end
	end
end

function Mangos:LIBKEYBOUND_DISABLED()
	for _,frame in self.Frame:GetAll() do
		if frame.KEYBOUND_DISABLED then
			frame:KEYBOUND_DISABLED()
		end
	end
end


--[[ Profile Functions ]]--

function Mangos:SaveProfile(name)
	local toCopy = self.db:GetCurrentProfile()
	if name and name ~= toCopy then
		self:Unload()
		self.db:SetProfile(name)
		self.db:CopyProfile(toCopy)
		self.isNewProfile = nil
		self:Load()
	end
end

function Mangos:SetProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:Unload()
		self.db:SetProfile(profile)
		self.isNewProfile = nil
		self:Load()
	else
		self:Print(format(L.InvalidProfile, name or 'null'))
	end
end

function Mangos:DeleteProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self.db:DeleteProfile(profile)
	else
		self:Print(L.CantDeleteCurrentProfile)
	end
end

function Mangos:CopyProfile(name)
	if name and name ~= self.db:GetCurrentProfile() then
		self:Unload()
		self.db:CopyProfile(name)
		self.isNewProfile = nil
		self:Load()
	end
end

function Mangos:ResetProfile()
	self:Unload()
	self.db:ResetProfile()
	self.isNewProfile = true
	self:Load()
end

function Mangos:ListProfiles()
	self:Print(L.AvailableProfiles)

	local current = self.db:GetCurrentProfile()
	for _,k in ipairs(self.db:GetProfiles()) do
		if k == current then
			DEFAULT_CHAT_FRAME:AddMessage(' - ' .. k, 1, 1, 0)
		else
			DEFAULT_CHAT_FRAME:AddMessage(' - ' .. k)
		end
	end
end

function Mangos:MatchProfile(name)
	local name = name:lower()
	local nameRealm = name .. ' - ' .. GetRealmName():lower()
	local match

	for i, k in ipairs(self.db:GetProfiles()) do
		local key = k:lower()
		if key == name then
			return k
		elseif key == nameRealm then
			match = k
		end
	end
	return match
end


--[[ Profile Events ]]--

function Mangos:OnNewProfile(msg, db, name)
	self.isNewProfile = true
	self:Print(format(L.ProfileCreated, name))
end

function Mangos:OnProfileDeleted(msg, db, name)
	self:Print(format(L.ProfileDeleted, name))
end

function Mangos:OnProfileChanged(msg, db, name)
	self:Print(format(L.ProfileLoaded, name))
end

function Mangos:OnProfileCopied(msg, db, name)
	self:Print(format(L.ProfileCopied, name))
end

function Mangos:OnProfileReset(msg, db)
	self:Print(format(L.ProfileReset, db:GetCurrentProfile()))
end


--[[ Settings...Setting ]]--

function Mangos:SetFrameSets(id, sets)
	local id = tonumber(id) or id
	self.db.profile.frames[id] = sets

	return self.db.profile.frames[id]
end

function Mangos:GetFrameSets(id)
	return self.db.profile.frames[tonumber(id) or id]
end


--[[ Options Menu Display ]]--

function Mangos:ShowOptions()
	if LoadAddOn('Mangos_Config') then
		InterfaceOptionsFrame_OpenToFrame('Mangos')
		return true
	end
	return false
end

function Mangos:NewMenu(id)
	if not self.Menu then
		LoadAddOn('Mangos_Config')
	end
	return self.Menu:New(id)
end


--[[ Slash Commands ]]--

function Mangos:RegisterSlashCommands()
	self:RegisterChatCommand('mangos', 'OnCmd')
	self:RegisterChatCommand('mg', 'OnCmd')
end

function Mangos:OnCmd(args)
	local cmd = string.split(' ', args):lower() or args:lower()

	--frame functions
	if cmd == 'config' or cmd == 'lock' then
		self:ToggleLockedFrames()
	elseif cmd == 'scale' then
		self:ScaleFrames(select(2, string.split(' ', args)))
	elseif cmd == 'setalpha' then
		self:SetOpacityForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'fade' then
		self:SetFadeForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'setcols' then
		self:SetColumnsForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'pad' then
		self:SetPaddingForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'space' then
		self:SetSpacingForFrame(select(2, string.split(' ', args)))
	elseif cmd == 'show' then
		self:ShowFrames(select(2, string.split(' ', args)))
	elseif cmd == 'hide' then
		self:HideFrames(select(2, string.split(' ', args)))
	elseif cmd == 'toggle' then
		self:ToggleFrames(select(2, string.split(' ', args)))
	--actionbar functions
	elseif cmd == 'showgrid' then
		self:ToggleGrid()
	--profile functions
	elseif cmd == 'save' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:SaveProfile(profileName)
	elseif cmd == 'set' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:SetProfile(profileName)
	elseif cmd == 'copy' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:CopyProfile(profileName)
	elseif cmd == 'delete' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:DeleteProfile(profileName)
	elseif cmd == 'reset' then
		self:ResetProfile()
	elseif cmd == 'list' then
		self:ListProfiles()
	elseif cmd == 'version' then
		self:PrintVersion()
	elseif cmd == 'help' or cmd == '?' then
		self:PrintHelp()
	--options stuff
	else
		if not self:ShowOptions() then
			self:PrintHelp()
		end
	end
end

function Mangos:PrintHelp(cmd)
	local function PrintCmd(cmd, desc)
		DEFAULT_CHAT_FRAME:AddMessage(format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print('Commands (/mg, /mangos)')
	PrintCmd('config', L.ConfigDesc)
	PrintCmd('scale <frameList> <scale>', L.SetScaleDesc)
	PrintCmd('setalpha <frameList> <opacity>', L.SetAlphaDesc)
	PrintCmd('fade <frameList> <opacity>', L.SetFadeDesc)
	PrintCmd('setcols <frameList> <columns>', L.SetColsDesc)
	PrintCmd('pad <frameList> <padding>', L.SetPadDesc)
	PrintCmd('space <frameList> <spacing>', L.SetSpacingDesc)
	PrintCmd('show <frameList>', L.ShowFramesDesc)
	PrintCmd('hide <frameList>', L.HideFramesDesc)
	PrintCmd('toggle <frameList>', L.ToggleFramesDesc)
	PrintCmd('showgrid', L.ShowGridDesc)
	PrintCmd('save <profile>', L.SaveDesc)
	PrintCmd('set <profile>', L.SetDesc)
	PrintCmd('copy <profile>', L.CopyDesc)
	PrintCmd('delete <profile>', L.DeleteDesc)
	PrintCmd('reset', L.ResetDesc)
	PrintCmd('list', L.ListDesc)
	PrintCmd('version', L.PrintVersionDesc)
end

--version info
function Mangos:PrintVersion()
	self:Print(MangosVersion)
end


--[[ Configuration Functions ]]--

--moving
Mangos.locked = true

function Mangos:SetLock(enable)
	self.locked = enable or nil
	if self.locked then
		self.Frame:ForAll('Lock')
	else
		self.Frame:ForAll('Unlock')
	end
end

function Mangos:Locked()
	return self.locked
end

function Mangos:ToggleLockedFrames()
	self:SetLock(not self:Locked())
end

--scale
function Mangos:ScaleFrames(...)
	local numArgs = select('#', ...)
	local scale = tonumber(select(numArgs, ...))

	if scale and scale > 0 and scale <= 10 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameScale', scale)
		end
	end
end

--opacity
function Mangos:SetOpacityForFrames(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameAlpha', alpha)
		end
	end
end

--faded opacity
function Mangos:SetFadeForFrames(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFadeAlpha', alpha)
		end
	end
end

--columns
function Mangos:SetColumnsForFrames(...)
	local numArgs = select('#', ...)
	local cols = tonumber(select(numArgs, ...))

	if cols then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetColumns', cols)
		end
	end
end

--spacing
function Mangos:SetSpacingForFrame(...)
	local numArgs = select('#', ...)
	local spacing = tonumber(select(numArgs, ...))

	if spacing then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetSpacing', spacing)
		end
	end
end

--padding
function Mangos:SetPaddingForFrames(...)
	local numArgs = select('#', ...)
	local pW, pH = select(numArgs - 1, ...)

	if tonumber(pW) and tonumber(pH) then
		for i = 1, numArgs - 2 do
			self.Frame:ForFrame(select(i, ...), 'SetPadding', tonumber(pW), tonumber(pH))
		end
	end
end

--visibility
function Mangos:ShowFrames(...)
	for i = 1, select('#', ...) do
		self.Frame:ForFrame(select(i, ...), 'ShowFrame')
	end
end

function Mangos:HideFrames(...)
	for i = 1, select('#', ...) do
		self.Frame:ForFrame(select(i, ...), 'HideFrame')
	end
end

function Mangos:ToggleFrames(...)
	for i = 1, select('#', ...) do
		self.Frame:ForFrame(select(i, ...), 'ToggleFrame')
	end
end

--empty button display
function Mangos:ToggleGrid()
	self:SetShowGrid(not self:ShowGrid())
end

function Mangos:SetShowGrid(enable)
	self.db.profile.showgrid = enable
	self.ActionBar:ForAll('UpdateGrid')
end

function Mangos:ShowGrid()
	return self.db.profile.showgrid
end

--right click selfcast
function Mangos:SetRightClickUnit(unit)
	self.db.profile.ab.rightClickUnit = unit
	self.ActionBar:ForAll('UpdateRightClickUnit')
end

function Mangos:GetRightClickUnit()
	return self.db.profile.ab.rightClickUnit
end

--possess bar settings
function Mangos:SetPossessBar(id)
	self.db.profile.possessBar = id

	self.ActionBar:ForAll('UpdateStateDriver')
	self.Frame:Get('pet'):UpdatePossess()
end

function Mangos:GetPossessBar()
	return self.Frame:Get(self.db.profile.possessBar)
end

--action bar numbers
function Mangos:SetNumBars(count)
	count = max(min(count, 120), 1) --sometimes, I do entertaininig things

	if count ~= self:NumBars() then
		self.ActionBar:ForAll('Delete')
		self.db.profile.ab.count = count

		for i = 1, self:NumBars() do
			self.ActionBar:New(i)
		end
	end
end

function Mangos:NumBars()
	return self.db.profile.ab.count
end


--[[ Utility Functions ]]--

--utility function: create a widget class
function Mangos:CreateClass(type, parentClass)
	local class = CreateFrame(type)
	class.mt = {__index = class}

	if parentClass then
		class = setmetatable(class, {__index = parentClass})
		class.super = parentClass
	end

	function class:Bind(o)
		return setmetatable(o, self.mt)
	end

	return class
end