--[[
	SageMana
		Handles mana/rage/energy/focus bars
--]]

SageMana = CreateFrame("StatusBar")
local Bar_MT = {__index = SageMana}

local ManaBarColor = ManaBarColor
local function Bar_OnShow(self) self:Update() end

--[[ Usable Stuff ]]--

local function Bar_OnValueChanged(self, value)
	if(UnitPowerType(self.id) == 0) then
		Bar_UpdateManaColor(self, value)
	end
end

function SageMana:Create(parent, id)
	local bar = setmetatable(SageBar:Create(parent, id, SageFont:GetSmallBarFont()), Bar_MT)
	bar:SetScript("OnShow", Bar_OnShow)
	bar:Update()
	bar:UpdateTexture()
	
	local info = ManaBarColor[2]
	bar.bg:SetVertexColor(info.r * 0.6, info.g * 0.6, info.b * 0.6, 0.6)

	if(not self.bars) then self.bars = {} end
	self.bars[bar.id] = bar

	return bar
end

function SageMana:Update()
	local unit = self.id
	local maxMana = UnitManaMax(unit)
	self:SetMinMaxValues(0, maxMana)

	--set grey if disconnected
	if not UnitIsConnected(unit) then
		self:SetValue(maxMana)
		self:SetStatusBarColor(0.5, 0.5, 0.5)
		self.text:SetText("")
	else
		--update mana bar color
		local info = ManaBarColor[UnitPowerType(unit)]
		self:SetStatusBarColor(info.r, info.g, info.b)

		self:SetValue(UnitMana(unit))
		self:UpdateText()
	end
end

function SageMana:UpdateText()
	local unit = self.id
	self:SetText(UnitMana(unit), UnitManaMax(unit), Sage:GetManaTextMode(unit))
end

SageMana.SetText = SageBar.SetText
SageMana.ShowText = SageBar.ShowText
SageMana.UpdateTexture = SageBar.UpdateTexture


--[[ Utility Functions ]]--

function SageMana:ForAll(method, ...)
	local bars = self.bars
	if(bars) then
		for _,bar in pairs(bars) do
			bar[method](bar, ...)
		end
	end
end

function SageMana:Get(id)
	return self.bars and self.bars[id]
end


--[[ Events ]]--

function SageMana:OnEvent(unit)
	local bar = self:Get(unit)
	if(bar and bar:IsVisible()) then
		bar:Update()
	end
end