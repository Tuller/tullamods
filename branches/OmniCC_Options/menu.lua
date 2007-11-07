--[[
	OmiCC Options
		A configuration GUI for OmniCC
--]]

OmniCCOptions = {}

local SML = LibStub:GetLibrary('LibSharedMedia-2.0') --shared media library
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

--[[ Font Selector ]]--

local MAX_LIST_SIZE = 20

local function FontSelectorButton_OnEnter(self) self.highlight:Show() end
local function FontSelectorButton_OnLeave(self) self.highlight:Hide() end

local function FontSelectorButton_OnClick(self)
	OmniCC:SetFont(self.font)

	local parent = self:GetParent()
	parent:Hide()

	local text = getglobal(parent:GetParent():GetName() .. 'Text')
	text:SetText(OmniCC:GetFontName())

	PlaySound('UChatScrollButton')
end

local function FontSelectorButton_Create(parent)
	local button = CreateFrame('Button', nil, parent)
	button:SetHeight(UIDROPDOWNMENU_BUTTON_HEIGHT)

	local text = button:CreateFontString()
	text:SetJustifyH('LEFT')
	text:SetPoint('LEFT', 27, 0)
	button.text = text

	local check = button:CreateTexture(nil, 'ARTWORK')
	check:SetWidth(24); check:SetHeight(24)
	check:SetTexture('Interface/Buttons/UI-CheckBox-Check')
	check:SetPoint('LEFT')
	button.check = check

	local highlight = button:CreateTexture(nil, 'BACKGROUND')
	highlight:SetAllPoints(button)
	highlight:SetTexture('Interface/QuestFrame/UI-QuestTitleHighlight')
	highlight:SetAlpha(0.5)
	highlight:SetBlendMode('ADD')
	highlight:Hide()
	button.highlight = highlight

	button:SetScript('OnClick', FontSelectorButton_OnClick)
	button:SetScript('OnEnter', FontSelectorButton_OnEnter)
	button:SetScript('OnLeave', FontSelectorButton_OnLeave)

	return button
end

local function FontSelectorList_OnShow(self)
	local buttons = self.buttons
	local fonts = SML:List('font')
	local numFonts = #fonts
	local selectedFont = OmniCC:GetFontName()
	local listSize = min(numFonts, MAX_LIST_SIZE)

	local scrollFrame = self.scrollFrame
	local offset = scrollFrame.offset
	FauxScrollFrame_Update(scrollFrame, numFonts, listSize, UIDROPDOWNMENU_BUTTON_HEIGHT)

	for i = 1, listSize do
		local index = i + offset
		local button = self.buttons[i]
		local font = fonts[index]

		if font then
			button.font = font
			button.text:SetFont(SML:Fetch('font', font), UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT)
			button.text:SetText(font)

			if font == selectedFont then
				button.check:Show()
			else
				button.check:Hide()
			end

			button:SetWidth(self.width)
			button:Show()
		else
			button:Hide()
		end
	end

	for i = listSize+1, #buttons do
		buttons[i]:Hide()
	end

	if self.scrollFrame:IsShown() then
		self:SetWidth(self.width + 50)
	else
		self:SetWidth(self.width + 30)
	end
	self:SetHeight((listSize * UIDROPDOWNMENU_BUTTON_HEIGHT) + (UIDROPDOWNMENU_BORDER_HEIGHT * 2))
end

local function FontSelectorList_OnHide(self)
	if self:IsShown() then
		self:Hide()
	end
end

local function FontSelectorList_OnClick(self) self:Hide() end

local function FontSelectorList_Create(parent)
	local frame = CreateFrame('Button', parent:GetName() .. 'FSList', parent)
	frame:SetFrameLevel(frame:GetFrameLevel() + 5)
	frame:SetToplevel(true)
	frame.text = frame:CreateFontString()

	frame.buttons = setmetatable({}, {__index = function(t, i)
		local button = FontSelectorButton_Create(frame)
		if i > 1 then
			button:SetPoint('TOPLEFT', t[i-1], 'BOTTOMLEFT')
		else
			button:SetPoint('TOPLEFT', 15, -15)
		end
		t[i] = button

		return button
	end})

	local scroll = CreateFrame('ScrollFrame', frame:GetName() .. 'ScrollFrame', frame, 'FauxScrollFrameTemplate')
	scroll:SetPoint('TOPLEFT', 12, -14)
	scroll:SetPoint('BOTTOMRIGHT', -36, 13)
	scroll:SetScript('OnVerticalScroll', function()
		FauxScrollFrame_OnVerticalScroll(UIDROPDOWNMENU_BUTTON_HEIGHT, function() FontSelectorList_OnShow(frame) end)
	end)
	frame.scrollFrame = scroll

	frame:SetBackdrop{
		bgFile = 'Interface/DialogFrame/UI-DialogBox-Background',
		edgeFile = 'Interface/DialogFrame/UI-DialogBox-Border',
		insets = {left = 11, right = 12, top = 12, bottom = 11},
		tile = true, tileSize = 32, edgeSize = 32,
	}

	frame:SetScript('OnShow', function(self)
		--determine the max frame width
		self.width = 0
		for _,font in pairs(SML:List('font')) do
			self.text:SetFont(SML:Fetch('font', font, true), UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT + 1)
			self.text:SetText(font)
			self.width = max(self.text:GetWidth()+60, self.width)
		end

		FontSelectorList_OnShow(self)
	end)

	frame:SetScript('OnHide', FontSelectorList_OnHide)
	frame:SetScript('OnClick', FontSelectorList_OnClick)
	frame:SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', 6, 8)
	frame:Hide()

	return frame
end

function OmniCC.LoadFontSelector(frame)
	frame:SetScript('OnShow', function(self)
		UIDropDownMenu_SetWidth(132, self)
		getglobal(self:GetName() .. 'Text'):SetText(OmniCC:GetFontName())
	end)

	getglobal(frame:GetName() .. 'Button'):SetScript('OnClick', function(self)
		local list = self.list
		if list and list:IsShown() then
			list:Hide()
		else
			if not list then
				list = FontSelectorList_Create(self:GetParent())
				self.list = list
			end
			list:Show()
		end
	end)
end