--[[
	OmiCC Options
		A configuration GUI for OmniCC
--]]

local SML = LibStub and LibStub:GetLibrary('LibSharedMedia-2.0') --shared media library
local L = OMNICC_LOCALS

OmniCCOptions = {}

local function ColorPicker_CopyColor(self)
	local dragger = OmniCCOptions.dragger
	dragger.bg:SetVertexColor(self:GetNormalTexture():GetVertexColor())
	dragger:Show()
end

local function ColorPicker_PasteColor(self, dragger)
	local r, g, b = dragger.bg:GetVertexColor()
	dragger:Hide()

	self:GetNormalTexture():SetVertexColor(r, g, b)
	OmniCC:SetDurationColor(self:GetParent().duration, r, g, b)
end

function OmniCCOptions:LoadColorPicker(frame)
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

	frame:RegisterForDrag('LeftButton')
	frame:SetScript('OnDragStart', ColorPicker_CopyColor)

	self.pickers = self.pickers or {}
	table.insert(self.pickers, frame)
end

function OmniCCOptions:LoadColorDragger(parent)
	local dragger = CreateFrame('Frame')
	dragger:SetFrameStrata('TOOLTIP')
	dragger:SetToplevel(true)
	dragger:SetMovable(true)
	dragger:SetHeight(24)
	dragger:SetWidth(24)
	dragger:Hide()
	dragger:EnableMouse(true)
	dragger:RegisterForDrag('LeftButton')

	dragger:SetScript('OnUpdate', function(self)
		local x, y = GetCursorPosition()
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x - 8, y + 8)
	end)

	dragger:SetScript('OnMouseUp', function(self)
		self:Hide()
	end)

	dragger:SetScript('OnReceiveDrag', function(self)
		for _,picker in pairs(OmniCCOptions.pickers) do
			if MouseIsOver(picker, 8, -8, -8, 8) then
				ColorPicker_PasteColor(picker, dragger)
			end
		end
		self:Hide()
	end)

	dragger.bg = dragger:CreateTexture()
	dragger.bg:SetTexture('Interface/ChatFrame/ChatFrameColorSwatch')
	dragger.bg:SetAllPoints(dragger)

	self.dragger = dragger
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