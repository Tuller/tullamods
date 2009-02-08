--[[
	Magician
--]]

local OmniCC = _G['OmniCC']
assert(OmniCC, 'Could not find an instance of OmniCC')
assert(not OmniCC.OnFinishCooldown, 'Another finish effect is already loaded')

--[[ the Shine object ]]--

local Shine = OmniCC:CreateClass('Frame')
Shine.SCALE = 5
Shine.STEP = 0.03

function Shine:New(parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))
	f:SetAllPoints(parent)
	f:SetToplevel(true)
	f:Hide()

	f:SetScript('OnUpdate', f.OnUpdate)
	f:SetScript('OnHide', f.OnHide)

	local icon = f:CreateTexture(nil, 'OVERLAY')
	icon:SetPoint('CENTER')
	icon:SetBlendMode('ADD')
	icon:SetTexture([[Interface\Cooldown\star4]])
	icon:SetHeight(f:GetHeight())
	icon:SetWidth(f:GetWidth())
	f.icon = icon

	return f
end

function Shine:Start(texture)
	if not self.active then
		self.active = true
		self.icon:SetAlpha(1)
		self:Show()
	end
end

--omg speed
local max = math.max
function Shine:OnUpdate(elapsed)
	local shine = self.icon
	local newAlpha = max(shine:GetAlpha() * (1 - self.STEP), 0)

	if newAlpha < 0.1 then
		self:Hide()
	else
		shine:SetAlpha(newAlpha)

		local multiplier = newAlpha * self.SCALE
		shine:SetHeight(self:GetHeight() * multiplier)
		shine:SetWidth(self:GetWidth() * multiplier)
	end
end

--this may look stupid, but it handles the case of the Shine no longer being visible due to its parent hiding
function Shine:OnHide()
	self.active = nil
	self:Hide()
end


--[[ omnicc hooks ]]--

do
	local shines = setmetatable({}, {__index = function(t, k)
		local f = Shine:New(k)
		t[k] = f
		return f
	end})

	OmniCC.OnFinishCooldown = function(self, timer)
		local icon = timer.icon
		local parent = timer:GetParent()

		if icon and icon.GetTexture and parent:IsVisible() then
			shines[parent]:Start(icon:GetTexture())
		end
	end
end