--[[
	Dominos
		Because sometimes I feel bad about doing to much
--]]

--libs and omgspeed
--local LBF = LibStub('LibButtonFacade', true)

local NT_RATIO = 64/37

--load up the bag set...
local bags = {}
do
	local function Add(b)
		table.insert(bags, b)
	end

	local function ResizeItemButton(b, size)
		b:SetWidth(size)
		b:SetHeight(size)
		b:GetNormalTexture():SetWidth(size * NT_RATIO)
		b:GetNormalTexture():SetHeight(size * NT_RATIO)

		local count = getglobal(b:GetName() .. 'Count')
		count:SetFontObject('NumberFontNormalSmall')
		count:SetPoint('BOTTOMRIGHT', 0, 2)

		getglobal(b:GetName() .. 'Stock'):SetFontObject('NumberFontNormalSmall')
		getglobal(b:GetName() .. 'Stock'):SetVertexColor(1, 1, 0)
	end

	local function CreateKeyRing()
		local b = CreateFrame('CheckButton', 'DominosKeyringButton', UIParent, 'ItemButtonTemplate')
		b:RegisterForClicks('anyUp')
		b:Hide()

		b:SetScript('OnClick', function()
			if CursorHasItem() then
				PutKeyInKeyRing()
			else
				ToggleKeyRing()
			end
		end)

		b:SetScript('OnReceiveDrag', function()
			if CursorHasItem() then
				PutKeyInKeyRing()
			end
		end)

		b:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

			local color = HIGHLIGHT_FONT_COLOR
			GameTooltip:SetText(KEYRING, color.r, color.g, color.b)
			GameTooltip:AddLine()
		end)

		b:SetScript('OnLeave', function()
			GameTooltip:Hide()
		end)

		getglobal(b:GetName() .. 'IconTexture'):SetTexture('Interface\\ContainerFrame\\KeyRing-Bag-Icon')
		getglobal(b:GetName() .. 'IconTexture'):SetTexCoord(0, 0.9, 0.1, 1)

		ResizeItemButton(b, 30)

		return b
	end

	Add(CreateKeyRing())
	Add(CharacterBag3Slot)
	Add(CharacterBag2Slot)
	Add(CharacterBag1Slot)
	Add(CharacterBag0Slot)

	ResizeItemButton(MainMenuBarBackpackButton, 30)
	Add(MainMenuBarBackpackButton)
end


--[[ Bag Bar ]]--

local BagBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.BagBar  = BagBar


function BagBar:New()
	local f = self.super.New(self, 'bags')
	f:LoadButtons()
	f:Layout()

	return f
end

function BagBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		numButtons = #bags,
		spacing = 2
	}
end

function BagBar:AddButton(i)
	local b = bags[i]
	b:SetParent(self.header)
	b:Show()

	self.buttons[i] = b
end

function BagBar:RemoveButton(i)
	local b = self.buttons[i]
	b:SetParent(nil)
	b:Hide()

	self.buttons[i] = nil
end