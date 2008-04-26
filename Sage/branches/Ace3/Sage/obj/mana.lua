--[[
	SageMana
		Handles mana/rage/energy/focus bars
--]]

SageMana = CreateFrame('StatusBar')
local Bar_MT = {__index = SageMana}

local ManaBarColor = ManaBarColor
local function Bar_OnShow(self) self:Update() end

--[[ Usable Stuff ]]--

local function Bar_OnValueChanged(self, value)
	if(UnitPowerType(self.id) == 0) then
		Bar_UpdateManaColor(self, value)
	end
end


--[[
   Calculate RGB from HSV, reverse of RGB2HSV()
   Hue is in degrees
   Lightness is between 0 and 1
   Saturation is between 0 and 1
]]--

local function RGBtoHSV(r, g, b)
	local h, s, v, min, max, delta

	min = math.min( r, g, b )
	max = math.max( r, g, b )
	delta = max - min
	s = delta / max
	v = max

	if r == max then
		h = (g-b)/delta -- between yellow & magenta
	elseif g == max then
		h = 2 + (b-r)/delta; -- between cyan & yellow
	else
		h = 4 + (r-g )/delta; -- between magenta & cyan
	end
	
	h = h * 60;
	if h < 0 then
		h = h + 360
	end
	
	return h, s, v
end


local function HSVToRGB(h, s, v)
	if s == 0 then 
		return v, v, v 
	else
		local h = h/60;			-- sector 0 to 5
		local i = math.floor(h);
		local f = h - i;			-- factorial part of h
		local ap = v * (1 - s);
		local aq = v * (1 - s * f);
		local at = v * (1 - s * (1 - f));

		if i == 0 then
			return v, at, ap
		elseif i == 1 then
			return aq, v, ap
		elseif i == 2 then
			return ap, v, at
		elseif i == 3 then
			return ap, aq, v
		elseif i == 4 then
			return at, ap, v
		elseif i == 5 then
			return v, ap, aq
		end
	end
end

local function GetComplement(r, g, b)
	local h, s, v = RGBtoHSV(r, g, b)
	return HSVToRGB((h - 180) % 360, s, v)
end

function SageMana:Create(parent, id)
	local bar = setmetatable(SageBar:Create(parent, id, SageFont:GetSmallBarFont()), Bar_MT)
	bar:SetScript('OnShow', Bar_OnShow)
	bar:Update()
	bar:UpdateTexture()

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
	else
		--update mana bar color
		local info = ManaBarColor[UnitPowerType(unit)]

		self:SetStatusBarColor(info.r, info.g, info.b)
		local r, g, b = GetComplement(self:GetStatusBarColor())
		self.bg:SetVertexColor(r, g, b, 0.6)

		self:SetValue(UnitMana(unit))
		self:UpdateText()
	end
end

function SageMana:UpdateText()
	local unit, mode, text, entered = self.id, self.mode, self.text, self.entered
	local value = UnitMana(unit)
	local max = UnitManaMax(unit)

	if(mode == 1 and not entered) then
		text:Hide()
	else
		if(UnitIsGhost(unit) or UnitIsDead(unit) or not UnitIsConnected(unit)) then
			text:SetText('')
		else
			if(entered or mode == 3) then
				if(Sage:ShowingMaxValues()) then
					text:SetFormattedText('%d / %d', value, max)
				else
					text:SetText(value)
				end
			elseif(mode == 2) then
				if(UnitPowerType(unit) == 1 and value == 0) then
					text:SetText('')
				elseif(UnitPowerType(unit) ~= 1 and value == max) then
					text:SetText('')
				else
					if value < 1000 then
						text:SetText(value)
					else
						text:SetFormattedText('%.1fk', value / 1000)
					end
				end
			end
		end
		text:Show()
	end
end
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