--[[
	totemBar
		A dominos totem bar
--]]

--no reason to load if we're not playing a shaman...
local class, enClass = UnitClass('player')
if enClass ~= 'SHAMAN' then
	return
end

local DTB = Dominos:NewModule('totems', 'AceEvent-3.0')
local TotemBar

--hurray for constants
local NUM_TOTEM_BARS = NUM_MULTI_CAST_PAGES --fire, water, air
local NUM_TOTEM_BAR_BUTTONS = NUM_MULTI_CAST_BUTTONS_PER_PAGE --fire, earth, water, air
local TOTEM_CALLS = {66842, 66843, 66844} --fire, water, air spellIDs
local TOTEMIC_RECALL = 36936
local TOTEM_BAR_START_ID = 132 --actionID start of the totembar


--[[ Module ]]--

function DTB:Load()
	self:LoadTotemBars()
	self:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR')
end

function DTB:Unload()
	for i = 1, NUM_TOTEM_BARS do
		local f = Dominos.Frame:Get('totem' .. i)
		if f then
			f:Free()
		end
	end
	self:UnregisterEvent('UPDATE_MULTI_CAST_ACTIONBAR')
end

function DTB:UPDATE_MULTI_CAST_ACTIONBAR()
	self:LoadTotemBars()
end

function DTB:LoadTotemBars()
	for i = 1, NUM_TOTEM_BARS do
		local f = Dominos.Frame:Get('totem' .. i)
		if not f and IsSpellKnown(TOTEM_CALLS[i]) then
			TotemBar:New(i)
		end
	end
end


--[[ Totem Bar ]]--

TotemBar = Dominos:CreateClass('Frame', Dominos.Frame)

function TotemBar:New(id)
	local f = self.super.New(self, 'totem' .. id)
	f.totemBarID = id
	f:LoadButtons()
	f:Layout()

	return f
end

function TotemBar:GetDefaults()
	return {
		point = 'CENTER',
		spacing = 2,
		showRecall = true,
		showTotems = true
	}
end

function TotemBar:NumButtons()
	local numButtons = 1 --we always show at least one button (the call of x spell)

	if self:ShowingTotems() then
		numButtons = numButtons + NUM_TOTEM_BAR_BUTTONS
	end

	if self:ShowingRecall() then
		numButtons = numButtons + 1
	end

	return numButtons
end

function TotemBar:GetBaseID()
	return TOTEM_BAR_START_ID + (NUM_TOTEM_BAR_BUTTONS * (self.totemBarID - 1))
end

--handle displaying the totemic recall button
function TotemBar:SetShowRecall(show)
	self.sets.showRecall = show and true or false
	self:LoadButtons()
	self:Layout()
end

function TotemBar:ShowingRecall()
	return self.sets.showRecall
end

--handle displaying all of the totem buttons
function TotemBar:SetShowTotems(show)
	self.sets.showTotems = show and true or false
	self:LoadButtons()
	self:Layout()
end

function TotemBar:ShowingTotems()
	return self.sets.showTotems
end


--[[ button stuff]]--

local tinsert = table.insert

function TotemBar:LoadButtons()
	local buttons = self.buttons

	--remove old buttons
	for i, b in pairs(buttons) do
		b:Free()
		buttons[i] = nil 
	end

	--add call of X button
	tinsert(buttons, self:GetCallButton())

	--add totem actions
	if self:ShowingTotems() then
		for i = 1, NUM_TOTEM_BAR_BUTTONS do
			tinsert(buttons, self:GetTotemButton(i))
		end
	end

	--add recall button
	if self:ShowingRecall() then
		tinsert(buttons, self:GetRecallButton())
	end

	self.header:Execute([[ control:ChildUpdate('action', nil) ]])
end

function TotemBar:GetCallButton()
	return self:CreateSpellButton(TOTEM_CALLS[self.totemBarID])
end

function TotemBar:GetRecallButton()
	return self:CreateSpellButton(TOTEMIC_RECALL)
end

function TotemBar:GetTotemButton(id)
	return self:CreateActionButton(self:GetBaseID() + id)
end

function TotemBar:CreateSpellButton(spellID)
	local b = Dominos.SpellButton:New(spellID)
	b:SetParent(self.header)
	return b
end

function TotemBar:CreateActionButton(actionID)
	local b = Dominos.ActionButton:New(actionID)
	b:SetParent(self.header)
	b:LoadAction()
	return b
end


--[[ right click menu ]]--

function TotemBar:AddLayoutPanel(menu)
	local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config', 'enUS')
	local panel = menu:AddLayoutPanel()
	
	--add show totemic recall toggle
	local showRecall = panel:NewCheckButton(L.ShowTotemRecall)
	
	showRecall:SetScript('OnClick', function(b) 
		self:SetShowRecall(b:GetChecked()); 
		panel.colsSlider:OnShow() --force update the columns slider
	end)
	
	showRecall:SetScript('OnShow', function(b)
		b:SetChecked(self:ShowingRecall()) 
	end)
	
	--add show totems toggle
	local showTotems = panel:NewCheckButton(L.ShowTotems)
	
	showTotems:SetScript('OnClick', function(b) 
		self:SetShowTotems(b:GetChecked());
		panel.colsSlider:OnShow() 
	end)
	
	showTotems:SetScript('OnShow', function(b) 
		b:SetChecked(self:ShowingTotems()) 
	end)
end

function TotemBar:CreateMenu()
	self.menu = Dominos:NewMenu(self.id)
	self:AddLayoutPanel(self.menu)
	self.menu:AddAdvancedPanel()
end