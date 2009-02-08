--[[
	Magician
--]]

local OmniCC = _G['OmniCC']
assert(OmniCC, 'Could not find an instance of OmniCC')
assert(not OmniCC.OnFinishCooldown, 'Another finish effect is already loaded')


--[[ the pulse object ]]--

local Pulse = OmniCC:CreateClass('Frame')

function Pulse:New(parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))
	f:SetAllPoints(parent)
	f:SetToplevel(true)
	f:Hide()

	f:SetScript('OnUpdate', f.OnUpdate)
	f:SetScript('OnHide', f.OnHide)

	local icon = f:CreateTexture(nil, 'OVERLAY')
	icon:SetPoint('CENTER')
	icon:SetBlendMode('ADD')
	icon:SetHeight(f:GetHeight())
	icon:SetWidth(f:GetWidth())
	f.icon = icon

	return f
end

function Pulse:Start(texture)
	if not self.active then
		self.scale = 1
		self.active = true

		local icon = self.icon
		local r, g, b = icon:GetVertexColor()
		icon:SetVertexColor(r, g, b, 0.7)
		icon:SetTexture(texture)

		self:Show()
	end
end

--omg speed
local max = math.max
local min = math.min
function Pulse:OnUpdate(elapsed)
	if self.scale >= 2 then
		self.shrinking = true
	end

	local delta = (self.shrinking and -1 or 1) * self.scale * (elapsed/0.5)
	self.scale = max(min(self.scale + delta, 2), 1)

	if self.scale > 1 then
		local icon = self.icon
		icon:SetHeight(self:GetHeight() * self.scale)
		icon:SetWidth(self:GetWidth() * self.scale)
	else
		self:Hide()
	end
end

--this may look stupid, but it handles the case of the pulse no longer being visible due to its parent hiding
function Pulse:OnHide()
	self.active = nil
	self.shrinking = nil
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