
local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Config = Bongos:NewModule('ActionBar-Config')
local CURRENT_VERSION = GetAddOnMetadata('Bongos', 'Version')

--[[ Config ]]--

function Config:OnInitialize()
	local defaults = {
		profile = {
			showTooltips = true,
			showEmpty = false,
			showHotkeys = true,
			showMacros = true,
			oorColoring = true,
			oorColor = {1, 0.5, 0.5},
			oomColor = {0.5, 0.5, 1},
			buffColoring = true,
			buffColor = {0, 1, 0},
			debuffColor = {1, 0, 1},
			equippedColor = {0, 1, 0, 0.7},
			rightClickUnit = nil,
			stateConditions = self:GetDefaultStateConditions(),
		}
	}
	self.db = Bongos.db:RegisterNamespace('actionBar', defaults)

	if Bongos3ABVersion then
		local cMajor = CURRENT_VERSION:match('(%w+)')
		local major = Bongos3ABVersion:match('(%w+)')

		--settings change
		if major ~= cMajor then
			self:UpdateSettings()
		end
	end

	--version update
	if Bongos3ABVersion ~= CURRENT_VERSION then
		self:UpdateVersion()
	end
end

function Config:UpdateSettings()
	--update settingsamagig
end

function Config:UpdateVersion()
	Bongos3ABVersion = CURRENT_VERSION
end


--[[ Update Functions ]]--


--show tooltips
function Config:ShowTooltips(enable)
	self.db.profile.showTooltips = enable or false
end

function Config:ShowingTooltips()
	return self.db.profile.showTooltips
end


--show empty buttons
function Config:ShowEmptyButtons(enable)
	self.db.profile.showEmpty = enable or false
	Bongos:GetModule('ActionBar'):UpdateShowStates()
end

function Config:ShowingEmptyButtons()
	return self.db.profile.showEmpty
end


--show hotkeys
function Config:ShowHotkeys(enable)
	self.db.profile.showHotkeys = enable or false

	local ab = Bongos:GetModule('ActionBar', true)
	if ab then
		ab.Button:ForAll('ShowHotkey', enable)
	end

	local class = Bongos:GetModule('ClassBar', true)
	if class then
		class.Button:ForAll('ShowHotkey', enable)
	end
	
	local pet = Bongos:GetModule('PetBar', true)
	if pet then
		pet.Button:ForAll('ShowHotkey', enable)
	end
end

function Config:ShowingHotkeys()
	return self.db.profile.showHotkeys
end


--show macro text
function Config:ShowMacros(enable)
	self.db.profile.showMacros = enable or false
	Bongos:GetModule('ActionBar').Button:ForAll('ShowMacro', enable)
end

function Config:ShowingMacros()
	return self.db.profile.showMacros
end


--set out of range color
function Config:SetOORColoring(enable)
	self.db.profile.oorColoring = enable or false
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateUsable')
end

function Config:ColorOOR()
	return self.db.profile.oorColoring
end

function Config:SetOORColor(r, g, b)
	self.db.profile.oorColor[1] = r
	self.db.profile.oorColor[2] = g
	self.db.profile.oorColor[3] = b
end

function Config:GetOORColor()
	return unpack(self.db.profile.oorColor)
end


--set oom color
function Config:SetOOMColor(r, g, b)
	self.db.profile.oomColor[1] = r
	self.db.profile.oomColor[2] = g
	self.db.profile.oomColor[3] = b
end

function Config:GetOOMColor()
	return unpack(self.db.profile.oomColor)
end


--buff and debuff highlighting
function Config:SetHighlightBuffs(enable)
	self.db.profile.buffColoring = enable or false
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateState')
end

function Config:HighlightingBuffs()
	return self.db.profile.buffColoring
end

function Config:SetBuffColor(r, g, b)
	self.db.profile.buffColor[1] = r
	self.db.profile.buffColor[2] = g
	self.db.profile.buffColor[3] = b
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateSpellInUse')
end

function Config:GetBuffColor()
	return unpack(self.db.profile.buffColor)
end

function Config:SetDebuffColor(r, g, b)
	self.db.profile.debuffColor[1] = r
	self.db.profile.debuffColor[2] = g
	self.db.profile.debuffColor[3] = b
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateSpellInUse')
end

function Config:GetDebuffColor()
	return unpack(self.db.profile.debuffColor)
end


--equipped items
function Config:SetEquippedColor(r, g, b, a)
	self.db.profile.equippedColor[1] = r
	self.db.profile.equippedColor[2] = g
	self.db.profile.equippedColor[3] = b
--	self.db.profile.equippedColor[4] = a
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateEquippedColor')
end

function Config:GetEquippedColor()
	return unpack(self.db.profile.equippedColor)
end


--right click selfcast
function Config:SetRightClickUnit(unit)
	self.db.profile.rightClickUnit = unit
	Bongos:GetModule('ActionBar').Bar:ForAll('SetRightClickUnit', unit)
end

function Config:GetRightClickUnit()
	return self.db.profile.rightClickUnit
end


--state conditions control what states we actually include in bongos for checking
--more importantly, it determines the order they are checked
--by default, we check for modifiers, then paging, then stances, then targeting
function Config:SetStateConditions(conditions)
	self.db.profile.stateConditions = conditions
	Bongos:GetModule('ActionBar').Bar:ForAll('UpdateStateDriver')
end

function Config:GetStateConditions()
	return self.db.profile.stateConditions
end

function Config:GetDefaultStateConditions()
	local conditions = {}

	--modifiers
	table.insert(conditions, '[mod:ctrl]')
	table.insert(conditions, '[mod:alt]')
	table.insert(conditions, '[mod:shift]')

	--paging
	for i = 2, 6 do
		table.insert(conditions, format('[bar:%d]', i))
	end

	--prowl
	table.insert(conditions, '[bonusbar:1,stealth]')

	--forms/stances
	for i = 1, 4 do
		table.insert(conditions, format('[bonusbar:%d]', i))
	end
--[[	
	for i = 1, 7 do
		table.insert(conditions, format('[form:%d]', i))
	end
--]]
	--help harm targeting
	table.insert(conditions, '[help]')
	table.insert(conditions, '[harm]')

	return conditions
end