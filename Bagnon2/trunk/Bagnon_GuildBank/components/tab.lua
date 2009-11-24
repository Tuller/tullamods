--[[
	bag.lua
		A bag button object for Bagnon
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local GuildTab = Bagnon.Classy:New('CheckButton')
Bagnon.GuildTab = GuildTab

--constants
local SIZE = 32
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function GuildTab:New(tabID, frameID, parent)
	local tab = self:Create(tabID, parent)
	tab:SetFrameID(frameID)

	tab:SetScript('OnEnter', tab.OnEnter)
	tab:SetScript('OnLeave', tab.OnLeave)
	tab:SetScript('OnClick', tab.OnClick)
	tab:SetScript('OnDragStart', tab.OnDrag)
	tab:SetScript('OnReceiveDrag', tab.OnClick)
	tab:SetScript('OnEvent', tab.OnEvent)
	tab:SetScript('OnShow', tab.OnShow)
	tab:SetScript('OnHide', tab.OnHide)

	return tab
end

function GuildTab:Create(tabID, parent)
	local tab = self:Bind(CreateFrame('CheckButton', 'BagnonGuildTab' .. self:GetNextID(), parent))
	tab:SetWidth(SIZE)
	tab:SetHeight(SIZE)
	tab:SetID(tabID)

	local name = tab:GetName()
	local icon = tab:CreateTexture(name .. 'IconTexture', 'BORDER')
	icon:SetAllPoints(tab)

	local count = tab:CreateFontString(name .. 'Count', 'OVERLAY')
	count:SetFontObject('NumberFontNormalSmall')
	count:SetJustifyH('RIGHT')
	count:SetPoint('BOTTOMRIGHT', -2, 2)

	local nt = tab:CreateTexture(name .. 'NormalTexture')
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(NORMAL_TEXTURE_SIZE)
	nt:SetHeight(NORMAL_TEXTURE_SIZE)
	nt:SetPoint('CENTER', 0, -1)
	tab:SetNormalTexture(nt)

	local pt = tab:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints(tab)
	tab:SetPushedTexture(pt)

	local ht = tab:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints(tab)
	tab:SetHighlightTexture(ht)

	local ct = tab:CreateTexture()
	ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	ct:SetAllPoints(tab)
	ct:SetBlendMode('ADD')
	tab:SetCheckedTexture(ct)

	tab:RegisterForClicks('anyUp')
	tab:RegisterForDrag('LeftButton')

	return tab
end

do
	local id = 0
	function GuildTab:GetNextID()
		local nextID = id + 1
		id = nextID
		return nextID
	end
end


--[[ Events ]]--

function GuildTab:OnEvent(event, ...)
	local action = self[event]
	if action then
		action(self, event, ...)
	end
end

function GuildTab:UpdateEvents()
	--register necessary events
end


--[[ Messages ]]--


--[[ Frame Events ]]--

function GuildTab:OnShow()
	self:UpdateEverything()
end

function GuildTab:OnHide()
	self:UpdateEvents()
end

function GuildTab:OnClick()
	--on click
end

function GuildTab:OnDrag()
	--on drag
end

function GuildTab:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end

	self:UpdateTooltip()
end

function GuildTab:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ Actions ]]--

function GuildTab:UpdateEverything()
end


--[[ Tooltip Methods ]]--

function GuildTab:UpdateTooltip()
end


--[[ Accessor Functions ]]--


--returns the bagnon frame we're attached to
function GuildTab:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEverything()
	end
end

function GuildTab:GetFrameID()
	return self.frameID
end

--return the settings object associated with this frame
function GuildTab:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end