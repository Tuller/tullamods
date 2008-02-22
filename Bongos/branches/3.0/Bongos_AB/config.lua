
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
			oomColoring = true,
			oomColor = {0.5, 0.5, 1},
			buffColoring = true,
			buffColor = {0, 1, 0},
			debuffColor = {1, 0, 1},
			rightClickUnit = 'player',
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
	Bongos:GetModule('ActionBar'):UpdateVisibility()
end

function Config:ShowingEmptyButtons()
	return self.db.profile.showEmpty
end


--show hotkeys
function Config:ShowHotkeys(enable)
	self.db.profile.showHotkeys = enable or false
	
	Bongos:GetModule('ActionBar').Button:ForAll('ShowHotkey', enable)
	Bongos:GetModule('ClassBar').Button:ForAll('ShowHotkey', enable)
	Bongos:GetModule('PetBar').Button:ForAll('ShowHotkey', enable)
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
	self.db.profile.oorColor = {r, g, b}
end

function Config:GetOORColor()
	return unpack(self.db.profile.oorColor)
end


--set oom color
function Config:SetOOMColoring(enable)
	self.db.profile.oomColoring = enable or false
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateUsable')
end

function Config:ColorOOM()
	return self.db.profile.oomColoring
end

function Config:SetOOMColor(r, g, b)
	self.db.profile.oomColor = {r, g, b}
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
	self.db.profile.buffColor = {r, g, b}
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateSpellInUse')
end

function Config:GetBuffColor(r, g, b)
	return unpack(self.db.profile.buffColor)
end

function Config:SetDebuffColor(r, g, b)
	self.db.profile.debuffColor = {r, g, b}
	Bongos:GetModule('ActionBar').Button:ForAll('UpdateSpellInUse')
end

function Config:GetDebuffColor(r, g, b)
	return unpack(self.db.profile.debuffColor)
end


--right click selfcast
function Config:SetRightClickUnit(unit)
	self.db.profile.rightClickUnit = unit
	
	for id,bar in Bongos:GetAll() do
		if bar.SetRightClickUnit then
			bar:SetRightClickUnit(unit)
		end
	end
end

function Config:GetRightClickUnit()
	return self.db.profile.rightClickUnit
end


--selfcast binding
function Config:SetSelfCastKey(key)
	SetActionSelfCastKey(key)
	self.db.profile.selfCastKey = key
end

function Config:GetSelfCastKey()
	return self.db.profile.selfCastKey
end