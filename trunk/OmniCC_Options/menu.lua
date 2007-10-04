--[[
	OmiCC Options
		A configuration GUI for OmniCC
--]]

OmniCCOptions = {}

local SML = LibStub and LibStub:GetLibrary('LibSharedMedia-2.0') --shared media library
local L = OMNICC_LOCALS


--[[ Color Select Code ]]--

local colorSelectors = {}
local colorCopier

local function ColorSelect_SetColor(self, r, g, b)
	self:GetNormalTexture():SetVertexColor(r, g, b)
	OmniCC:SetDurationColor(self:GetParent().duration, r, g, b)
end

local function ColorSelect_CopyColor(self)
	colorCopier.bg:SetVertexColor(self:GetNormalTexture():GetVertexColor())
	colorCopier:Show()
end

local function ColorSelect_PasteColor(self)
	local r, g, b = colorCopier.bg:GetVertexColor()
	colorCopier:Hide()

	self:GetNormalTexture():SetVertexColor(r, g, b)
	OmniCC:SetDurationColor(self:GetParent().duration, r, g, b)
end

local function ColorSelect_OnClick(self)
	if ColorPickerFrame:IsShown() then
		ColorPickerFrame:Hide()
	else
		self.r, self.g, self.b = OmniCC:GetDurationFormat(self:GetParent().duration)

		UIDropDownMenuButton_OpenColorPicker(self)
		ColorPickerFrame:SetFrameStrata('TOOLTIP')
		ColorPickerFrame:Raise()
	end
end

local function ColorCopier_Create()
	local copier = CreateFrame('Frame')
	copier:SetHeight(24)
	copier:SetWidth(24)
	copier:Hide()

	copier:EnableMouse(true)
	copier:SetToplevel(true)
	copier:SetMovable(true)

	copier:RegisterForDrag('LeftButton')
	copier:SetFrameStrata('TOOLTIP')

	copier:SetScript('OnUpdate', function(self)
		local x, y = GetCursorPosition()
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x - 8, y + 8)
	end)

	copier:SetScript('OnMouseUp', function(self) self:Hide() end)

	copier:SetScript('OnReceiveDrag', function(self)
		for _,selector in pairs(colorSelectors) do
			if MouseIsOver(selector, 8, -8, -8, 8) then
				ColorSelect_PasteColor(selector)
			end
		end
		self:Hide()
	end)

	copier.bg = copier:CreateTexture()
	copier.bg:SetTexture('Interface/ChatFrame/ChatFrameColorSwatch')
	copier.bg:SetAllPoints(copier)

	return copier
end

function OmniCCOptions:LoadColorSelect(frame)
	frame.SetColor = ColorSelect_SetColor
	frame.swatchFunc = function() frame:SetColor(ColorPickerFrame:GetColorRGB()) end
	frame.cancelFunc = function() frame:SetColor(frame.r, frame.g, frame.b) end
	
	frame:RegisterForDrag('LeftButton')
	frame:SetScript('OnDragStart', ColorSelect_CopyColor)
	frame:SetScript('OnClick', ColorSelect_OnClick)

	if not next(colorSelectors) then
		colorCopier = ColorCopier_Create()
	end
	table.insert(colorSelectors, frame)
end


--[[ Dropdowns ]]--

local info = {}
local function AddItem(text, value, func, checked)
	info.text = text
	info.func = func
	info.value = value
	info.checked = checked
	UIDropDownMenu_AddButton(info)
end

function OmniCC.OnFontFaceLoad(frame)
	function frame.OnClick()
		OmniCC:SetFont(this.value)
		UIDropDownMenu_SetSelectedName(frame, this.value)
	end

	function frame.Initialize()
		local selectedFont = OmniCC:GetFontName()
		for _,font in ipairs(SML:List(SML.MediaType.FONT)) do
			AddItem(font, font, frame.OnClick, font == selectedFont)
		end
	end

	frame:SetScript('OnShow', function(self)
		UIDropDownMenu_Initialize(self, self.Initialize)
		UIDropDownMenu_SetWidth(132, self)
		UIDropDownMenu_SetSelectedName(self, OmniCC:GetFontName())
	end)
end

function OmniCC.OnFontOutlineLoad(frame)
	local styles = {NONE, L.Thin, L.Thick}
	local outlines = {nil, 'OUTLINE', 'THICKOUTLINE'}

	function frame.OnClick()
		OmniCC:SetFontOutline(outlines[this.value])
		UIDropDownMenu_SetSelectedValue(frame, this.value)
	end

	function frame.Initialize()
		local selectedOutline = OmniCC:GetFontOutline()
		for i,style in ipairs(styles) do
			AddItem(style, i, frame.OnClick, outlines[i] == selectedOutline)
		end
	end

	frame:SetScript('OnShow', function(self)
		UIDropDownMenu_Initialize(self, self.Initialize)
		UIDropDownMenu_SetWidth(132, self)

		local selectedOutline = OmniCC:GetFontOutline()
		for i, outline in pairs(outlines) do
			if outline == selectedOutline then
				UIDropDownMenu_SetSelectedValue(self, i)
				break
			end
		end
	end)
end