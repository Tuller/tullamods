--[[
	Magician
--]]

local OmniCC = _G['OmniCC']
assert(OmniCC, 'Could not find an instance of OmniCC')
assert(not OmniCC.OnFinishCooldown, 'Another finish effect is already loaded')

--[[ the Shine object ]]--

local Shine = OmniCC:CreateClass('Frame')
Shine.SCALE = 5 --how big the thing should get
Shine.DURATION = 1 --how long the effect should last (in seconds)
Shine.TEXTURE = [[Interface\Cooldown\star4]] --the graphic of the effect

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
	icon:SetTexture(f.TEXTURE)
	f.icon = icon

	return f
end

function Shine:Start(texture)
	if not self:IsShown() then
		--reset everything to defaults
		self.icon:SetAlpha(1)
		self.icon:SetHeight(self:GetHeight())
		self.icon:SetWidth(self:GetWidth())
		
		--show the effect, start the cycle
		self:Show()
	end
end

--omg speed
function Shine:OnUpdate(elapsed)
	local icon = self.icon
	local newAlpha = icon:GetAlpha() - (elapsed/self.DURATION)

	--the effect is will still be visible, adjust size, etc
	if newAlpha > 0 then
		icon:SetAlpha(newAlpha)

		local multiplier = newAlpha * self.SCALE
		icon:SetHeight(self:GetHeight() * multiplier)
		icon:SetWidth(self:GetWidth() * multiplier)
	else
		self:Hide()
	end
end

--this may look stupid, but it handles the case of the Shine no longer being visible due to its parent hiding
function Shine:OnHide()
	self:Hide()
end


--[[ omnicc hooks ]]--

do
	--laziness thing to prevent creation of multiple effects for the same parent object
	local effects = setmetatable({}, {__index = function(t, k)
		local f = Shine:New(k)
		t[k] = f
		return f
	end})

	OmniCC.OnFinishCooldown = function(self, timer)
		local parent = timer:GetParent()
		if parent:IsVisible() then
			effects[parent]:Start()
		end
	end
end