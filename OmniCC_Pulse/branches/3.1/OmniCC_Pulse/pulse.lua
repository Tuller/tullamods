--[[
	Magician
--]]

local OmniCC = _G['OmniCC']
assert(OmniCC, 'Could not find an instance of OmniCC')
assert(not OmniCC.OnFinishCooldown, 'Another finish effect is already loaded')


--[[ the pulse object ]]--

local Pulse = OmniCC:CreateClass('Frame')
local ANIMATION_TEMPLATE = 'OmniCCAnimationTemplate_Pulse'

function Pulse:New(parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent)) 
	f:SetAllPoints(parent)
	f:SetToplevel(true)
	f:Hide()
	
	f.ani = f:CreateAnimationGroup(nil, ANIMATION_TEMPLATE)
	f:SetScript('OnHide', f.OnHide)

	local icon = f:CreateTexture(nil, 'OVERLAY')
	icon:SetPoint('CENTER')
	icon:SetBlendMode('ADD')
	icon:SetAllPoints(f)
	f.icon = icon

	return f
end

function Pulse:Start(texture)
	if not self.ani:IsPlaying() then
		local icon = self.icon
		local r, g, b = icon:GetVertexColor()
		icon:SetVertexColor(r, g, b, 0.7)
		icon:SetTexture(texture)

		self:Show()
		self.ani:Play()
	end
end

function Pulse:OnHide()
	if self.ani:IsPlaying() then
		self.ani:Stop()
	end
	self:Hide()
end


--[[ omnicc hooks ]]--

do
	local pulses = setmetatable({}, {__index = function(t, k)
		local f = Pulse:New(k)
		t[k] = f
		return f
	end})

	OmniCC.OnFinishCooldown = function(self, timer)
		local icon = timer.icon
		local parent = timer:GetParent()

		if icon and icon.GetTexture and parent:IsVisible() then
			pulses[parent]:Start(icon:GetTexture())
		end
	end
end