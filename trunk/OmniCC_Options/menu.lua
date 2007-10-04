--[[
	OmiCC Options
		A configuration GUI for OmniCC
--]]

local SML = LibStub and LibStub:GetLibrary('LibSharedMedia-2.0') --shared media library
local L = OMNICC_LOCALS

OmniCCOptions = {}

function OmniCCOptions.LoadColorPicker(frame)
	local function SetColor(r, g, b)
		frame:GetNormalTexture():SetVertexColor(r, g, b)
		OmniCC:SetDurationColor(frame:GetParent().duration, r, g, b)
	end

	local function OnColorChange()
		SetColor(ColorPickerFrame:GetColorRGB())
	end

	local function OnCancelChanges()
		SetColor(frame.r, frame.g, frame.b)
	end

	frame:SetScript('OnClick', function(self)
		if ColorPickerFrame:IsShown() then
			ColorPickerFrame:Hide()
		else
			self.r, self.g, self.b = OmniCC:GetDurationFormat(self:GetParent().duration)
			self.swatchFunc = OnColorChange
			self.cancelFunc = OnCancelChanges

			UIDropDownMenuButton_OpenColorPicker(self)
			ColorPickerFrame:SetFrameStrata('TOOLTIP')
			ColorPickerFrame:Raise()
		end
	end)
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
	local styles = {NONE, 'Thin', 'Thick'}
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