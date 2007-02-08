--[[
	style.lua
		Scripts for the style panel of the Sage Options Menu
--]]

--healthbar text style constants
local DEFAULT_TEXT_STYLE = 1
local NUM_TEXT_STYLES = 5
local DEFAULT_TEXTURE = "Skewed"
local TEXTURES = {
	"Ace",
	"BantoBar",
	"Bars",
	"Blizzard",
	"Button",
	"Charcoal",
	"Dabs",
	"Diagonal",
	"Gloss",
	"Perl_StatusBar",
	"Perl_StatusBar1",
	"Perl_StatusBar2",
	"Perl_StatusBar3",
	"Skewed",
	"Smooth",
	"Steel",
	"Custom",
}

--frame name
local frameName

--[[ OnLoad, OnShow ]]--

function SOptionsStyle_OnLoad()
	frameName = this:GetName()

	getglobal(frameName.. "HealthLabel"):SetText(SAGE_OPTIONS_HEALTH_TEXT_STYLE)
	getglobal(frameName.. "ManaLabel"):SetText(SAGE_OPTIONS_MANA_TEXT_STYLE)
	getglobal(frameName.. "TextureLabel"):SetText(SAGE_OPTIONS_TEXTURE_LABEL)

	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Health"), Sage.GetHealthTextMode())
	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Mana"), Sage.GetManaTextMode())

	local default
	for i,texture in pairs(TEXTURES) do
		if texture == Sage.GetTextureID() then
			default = i
			break
		end
	end

	if default then
		UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Texture"), default)
	else
		UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Texture"), #TEXTURES)
		getglobal(frameName .. "CustomTexture"):Show()
	end
end

function SOptionsStyle_OnShow()
	this.onShow = 1

	SageStatusBar.UpdateAllText(true)

	getglobal(frameName .. "ShowText"):SetChecked(Sage.ShowingText())
	getglobal(frameName .. "Percents"):SetChecked(Sage.ShowingPercents())
	getglobal(frameName .. "OutlineNames"):SetChecked(SageDB.outlineOutsideFonts)
	getglobal(frameName .. "OutlineBarText"):SetChecked(SageDB.outlineBarFonts)
	getglobal(frameName .. "ColorOnDebuff"):SetChecked(SageDB.colorHealthOnDebuff)

	this.onShow = nil
end

function SOptionsStyle_OnHide()
	SageStatusBar.UpdateAllText(Sage.ShowingText())
end

--[[ Health Style Dropdown ]]--

local function AddButton(text, value, action, selected)
	local info = {}
	info.text = text
	info.func = action
	info.value = value
	if value == selected then
		info.checked = 1
	end
	UIDropDownMenu_AddButton(info)
end

function SOptionsStyleHealth_OnShow()
	UIDropDownMenu_Initialize(this, SOptionsStyleHealth_Initialize)
	UIDropDownMenu_SetWidth(36, this)
end

function SOptionsStyleHealth_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Health"), this.value)
	Sage.SetHealthTextMode(this.value)
end

--add all buttons to the dropdown menu
function SOptionsStyleHealth_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(getglobal(frameName .. "Health"))

	for i = 1, NUM_TEXT_STYLES do
		AddButton(i, i, SOptionsStyleHealth_OnClick, selectedValue)
	end

	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Health"), selectedValue)
end

--[[ Mana Style Dropdown ]]--

function SOptionsStyleMana_OnShow()
	UIDropDownMenu_Initialize(this, SOptionsStyleMana_Initialize)
	UIDropDownMenu_SetWidth(36, this)
end

function SOptionsStyleMana_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Mana"), this.value)
	Sage.SetManaTextMode(this.value)
end

--add all buttons to the dropdown menu
function SOptionsStyleMana_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(getglobal(frameName .. "Mana"))

	for i = 1, NUM_TEXT_STYLES do
		AddButton(i, i, SOptionsStyleMana_OnClick, selectedValue)
	end

	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Mana"), selectedValue)
end

--[[ StatusBar Texture Dropdown ]]--

function SOptionsStyleTexture_OnShow()
	UIDropDownMenu_Initialize(this, SOptionsStyleTexture_Initialize)
	UIDropDownMenu_SetWidth(72, this)
end

function SOptionsStyleTexture_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Texture"), this.value)

	if TEXTURES[this.value] == "Custom" then
		getglobal(frameName .. "CustomTexture"):Show()
	else
		Sage.SetBarTexture(TEXTURES[this.value])
		getglobal(frameName .. "CustomTexture"):Hide()
	end
end

--add all buttons to the dropdown menu
function SOptionsStyleTexture_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(getglobal(frameName .. "Texture"))

	for i, name in pairs(TEXTURES) do
		AddButton(name, i, SOptionsStyleTexture_OnClick, selectedValue)
	end

	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "Texture"), selectedValue)
end

--[[ Custom Texture EditBox ]]--

function SOptionsStyleCustomTexture_OnShow()
	getglobal(this:GetName() .. "Box"):SetText(Sage.GetTextureID())
	getglobal(this:GetName() .. "Box"):HighlightText()
end
