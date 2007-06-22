--Texture options
local textures = {
	"Blizzard",
	"Aluminium",
	"Armory",
	"Armory2",
	"BantoBar",
	"Bars",
	"Button",
	"Charcoal",
	"Cilo",
	"Glaze",
	"Gloss",
	"Healbot",
	"MelliDark",
	"Minimalist",
	"Perl",
	"Perl2",
	"Skewed",
	"Smooth",
	"Steel",
	"XPerl7",
}
if(AceLibrary) then
	local SML = AceLibrary:HasInstance("SharedMedia-1.0") and AceLibrary("SharedMedia-1.0")
	if(SML) then
		for _,id in pairs(SML:List("statusbar")) do
			local found = false
			for _,tID in pairs(textures) do
				if(tID == id) then
					found = true; break
				end
			end
			if(not found) then
				table.insert(textures, id)
			end
		end
	end
end
	
table.sort(textures)
local BUTTON_HEIGHT = 24
local DISPLAY_SIZE = 10
local panel, scrollFrame


--[[ Texture Button ]]--

local function TextureButton_OnClick(self)
	Sage:SetBarTexture(self:GetText())
	panel:UpdateList()
end

local function TextureButton_OnMouseWheel(self, direction)
	local scrollBar = getglobal(scrollFrame:GetName() .. "ScrollBar")
	scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
	panel:UpdateList()
end

local function TextureButton_Create(name, parent)
	local button = CreateFrame("Button", name, parent)
	button.bg = button:CreateTexture()
	button.bg:SetAllPoints(button)
	local r, g, b = random(), random(), random()
	while(r + g + b < 0.6) do
		r, g, b = random(), random(), random()
	end
	button.bg:SetVertexColor(r, g, b)
	button:EnableMouseWheel(true)
	button:SetScript("OnClick", TextureButton_OnClick)
	button:SetScript("OnMouseWheel", TextureButton_OnMouseWheel)
	button:SetTextColor(1, 0.82, 0)
	button:SetHighlightTextColor(1, 1, 1)

	local text = button:CreateFontString()
	text:SetFontObject("GameFontNormalLarge"); text:SetJustifyH("LEFT")
	text:SetAllPoints(button)
	button:SetFontString(text)

	return button
end


--[[ Panel Functions ]]--

local function Panel_UpdateList()
	local offset = scrollFrame.offset
	FauxScrollFrame_Update(scrollFrame, #textures, DISPLAY_SIZE, DISPLAY_SIZE)
	local currentTexture = Sage:GetBarTexture()

	for i = 1, DISPLAY_SIZE do
		local index = i + offset
		local button = panel.buttons[i]

		if index <= #textures then
			local textureID = textures[index]
			local texture = Sage:GetBarTexture(textureID)
			button:SetText(textureID)
			button.bg:SetTexture(texture)
			if(texture == currentTexture) then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
			button:Show()
		else
			button:Hide()
		end
	end
end

local function Panel_Create()
	local panel = SageOptions:AddPanel("Texture")
	panel.UpdateList = Panel_UpdateList

	local name = panel:GetName()

	panel:SetScript("OnShow", Panel_UpdateList)

	local scroll = CreateFrame("ScrollFrame", name .. "ScrollFrame", panel, "FauxScrollFrameTemplate")
	scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(10, Panel_UpdateList) end)
	scroll:SetScript("OnShow", function()
		panel.buttons[1]:SetPoint("BOTTOMRIGHT", scroll, "TOPLEFT", -20, -(BUTTON_HEIGHT+2))
	end)
	scroll:SetScript("OnHide", function()
		panel.buttons[1]:SetPoint("BOTTOMRIGHT", scroll, "TOPLEFT", -2, -BUTTON_HEIGHT)
	end)
	scroll:SetPoint("TOPLEFT", panel, "TOPRIGHT", -8, -2)
	scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 8)
	scrollFrame = scroll

	--add list buttons
	panel.buttons = {}
	for i = 1, DISPLAY_SIZE do
		local button = TextureButton_Create(name .. i, panel)
		if(i == 1) then
			button:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -4)
		else
			button:SetPoint("TOPLEFT", name .. i-1, "BOTTOMLEFT", 0, -1)
			button:SetPoint("BOTTOMRIGHT", name .. i-1, "BOTTOMRIGHT", 0, -BUTTON_HEIGHT)
		end
		panel.buttons[i] = button
	end

	panel.height = panel.height + (DISPLAY_SIZE * BUTTON_HEIGHT)
	return panel
end
panel = Panel_Create()