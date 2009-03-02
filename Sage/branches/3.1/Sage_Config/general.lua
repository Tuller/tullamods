--[[
	general.lua
		The general panel of the Sage options menu
--]]

local L = LibStub('AceLocale-3.0'):GetLocale('Sage-Config')
local _G = _G

local function CreateOptionsMenu()
	if not Sage.Options then
		local addonName, title, notes = GetAddOnInfo('Sage')
		Sage.Options = Sage.Panel:New('SageOptions', title, notes, [[Interface\Icons\INV_Helmet_62]])
	end
	return Sage.Options
end

local Options = CreateOptionsMenu()

--[[ Buttons ]]--

--toggle config mode
local lock = Options:NewButton(L.MoveFrames, 136, 22)
lock:SetScript('OnClick', function(self)
	Sage:ToggleLockedFrames()
	HideUIPanel(InterfaceOptionsFrame)
end)
lock:SetPoint('TOPLEFT', 12, -72)


--[[ General Settings ]]--

--sticky frames
local sticky = Options:NewCheckButton(L.EnableStickyFrames)
sticky:SetScript('OnShow', function(self)
	self:SetChecked(Sage:Sticky())
end)
sticky:SetScript('OnClick', function(self)
	Sage:SetSticky(self:GetChecked())
end)
sticky:SetPoint('TOPLEFT', lock, 'BOTTOMLEFT', 0, -24)

--color health by class
local classColoring = Options:NewCheckButton(L.ColorHealthByClass)
classColoring:SetScript('OnShow', function(self)
	self:SetChecked(Sage:ColorHealthByClass())
end)
classColoring:SetScript('OnClick', function(self)
	Sage:SetColorHealthByClass(self:GetChecked())
end)
classColoring:SetPoint('TOPLEFT', sticky, 'BOTTOMLEFT', 0, -2)

--color health when debuffed
local debuffColoring = Options:NewCheckButton(L.ColorHealthWhenDebuffed)
debuffColoring:SetScript('OnShow', function(self)
	self:SetChecked(Sage:ColorHealthByDebuff())
end)
debuffColoring:SetScript('OnClick', function(self)
	Sage:SetColorHealthByDebuff(self:GetChecked())
end)
debuffColoring:SetPoint('TOPLEFT', classColoring, 'BOTTOMLEFT', 0, -2)

--show pvp icons
local showPvPIcons = Options:NewCheckButton(L.ShowPvPIcons)
showPvPIcons:SetScript('OnShow', function(self)
	self:SetChecked(Sage:ShowingPVPIcons())
end)
showPvPIcons:SetScript('OnClick', function(self)
	Sage:ShowPVPIcons(self:GetChecked())
end)
showPvPIcons:SetPoint('TOPLEFT', debuffColoring, 'BOTTOMLEFT', 0, -2)

local textMode = Options:NewTextModeSelector('all')
textMode:SetPoint('BOTTOMLEFT', 8, 6)


--[[ Texture Selector ]]--

local selector = Sage.TextureSelector:New(L.Texture, Options)
selector:SetPoint('TOPRIGHT', -8, -72)