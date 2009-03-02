--[[
	A texture selector widget
--]]

local L = LibStub('AceLocale-3.0'):GetLocale('Sage-Config')
local SML = LibStub('LibSharedMedia-3.0')
local _G = _G


--[[ List Button ]]--

local ListButton = Sage:CreateClass('Button')
ListButton.width = 160
ListButton.height = 18

function ListButton:New(id, parent)
	local button = self:Bind(CreateFrame('Button', parent:GetName() .. id, parent))
	button:SetWidth(button.width)
	button:SetHeight(button.height)

	local r, g ,b
	if id % 3 == 0 then
		r = 0.2
		g = 0.9
		b = 0.2
	elseif id % 2 == 0 then
		r = 0.2
		g = 0.2
		b = 0.9
	else
		r = 0.9
		g = 0.2
		b = 0.2
	end
	button.bg = button:CreateTexture()
	button.bg:SetVertexColor(r, g, b)
	button.bg:SetAllPoints(button)
	
	local text = button:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	text:SetJustifyH('LEFT')
	text:SetAllPoints(button)
	button:SetFontString(text)
	button:SetNormalFontObject('GameFontNormal')
	button:SetHighlightFontObject('GameFontHighlight')
	
	button:SetScript('OnClick', button.OnClick)
	
	return button
end

function ListButton:OnClick()
	self:GetParent():Select(self:GetText())
end


--[[ Texture Selector ]]--

local TextureSelector = Sage:CreateClass('Frame')
Sage.TextureSelector = TextureSelector

TextureSelector.numItems = 17
TextureSelector.spacing = 2

function TextureSelector:New(title, parent)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. title, parent, 'OptionsBoxTemplate'))
	_G[f:GetName() .. 'Title']:SetText(title)
	f:SetBackdropBorderColor(0.4, 0.4, 0.4)
	f:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
	f:SetScript('OnShow', f.OnShow)
	f:SetWidth(16 + ListButton.width)
	f:SetHeight(12 - f.spacing + f.numItems * (ListButton.height + f.spacing))
	
	--create list buttons on demand
	f.buttons = setmetatable({}, {__index = function(t, i)
		local b = ListButton:New(i, f)

		if i == 1 then
			b:SetPoint('TOPLEFT', 6, -6)
		else
			b:SetPoint('TOPLEFT', t[i - 1], 'BOTTOMLEFT', 0, -f.spacing)
			b:SetPoint('TOPRIGHT', t[i - 1], 'BOTTOMRIGHT', 0, -f.spacing)
		end

		t[i] = b
		return b
	end})
	
	--add a scroll frame
	local scrollFrame = CreateFrame('ScrollFrame', f:GetName() .. 'ScrollFrame', f, 'FauxScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', -30, -7)
	scrollFrame:SetPoint('BOTTOMRIGHT', -30, 7)
	
	scrollFrame:SetScript('OnVerticalScroll', function(self, arg1) 
		FauxScrollFrame_OnVerticalScroll(self, arg1, ListButton.height + f.spacing, function() f:UpdateList() end) 
	end)

	scrollFrame:SetScript('OnShow', function(self) 
		f.buttons[1]:SetWidth(ListButton.width - 18) 
	end)
	scrollFrame:SetScript('OnHide', function() 
		f.buttons[1]:SetWidth(ListButton.width) 
	end)
	f.scrollFrame = scrollFrame

	
	return f
end

function TextureSelector:OnShow()
	self:Select(self:GetSelectedValue(), true)
	self:UpdateList()
end

function TextureSelector:OnSelect(value)
	Sage:SetStatusBarTexture(value)
end


--[[ Update Methods ]]--

function TextureSelector:Select(value, noUpdate)
	if (not noUpdate) and value ~= self:GetSelectedValue() then
		self:OnSelect(value)
	end

	self:HighlightSelected()
end

function TextureSelector:UpdateList()
	local list = SML:List('statusbar')
	local size = #list

	local scrollFrame = self.scrollFrame
	local offset = scrollFrame.offset
	FauxScrollFrame_Update(scrollFrame, size, self.numItems, ListButton.height + self.spacing)

	for i = 1, self.numItems do
		local index = i + offset
		local b = self.buttons[i]

		if index <= size then
			local id = list[index]
			local texture = SML:Fetch('statusbar', id)

			b:SetText(id)
			b.bg:SetTexture(texture)
			b:Show()
		else
			b:Hide()
		end
	end
	
	self:HighlightSelected()
end

function TextureSelector:HighlightSelected()
	local value = self:GetSelectedValue()
	for _,b in pairs(self.buttons) do
		if b:GetText() == value then
			b:LockHighlight()
		else
			b:UnlockHighlight()
		end
	end
end

--[[ Accessor Methods ]]--

function TextureSelector:GetSelectedValue()
	return Sage.db.profile.texture
end