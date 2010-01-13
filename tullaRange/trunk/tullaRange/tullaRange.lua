--[[
	tullaRange
		Adds out of range coloring to action buttons
		Derived from RedRange with negligable improvements to CPU usage
--]]

--[[ locals and speed ]]--

local _G = _G
local UPDATE_DELAY = 0.1
local ATTACK_BUTTON_FLASH_TIME = ATTACK_BUTTON_FLASH_TIME

local ActionButton_GetPagedID = ActionButton_GetPagedID
local ActionButton_IsFlashing = ActionButton_IsFlashing
local ActionHasRange = ActionHasRange
local IsActionInRange = IsActionInRange
local IsUsableAction = IsUsableAction


--[[ The main thing ]]--

local tullaRange = CreateFrame('Frame', 'tullaRange', UIParent); tullaRange:Hide()

function tullaRange:Load()
	self:SetScript('OnUpdate', self.OnUpdate)
	self:SetScript('OnHide', self.OnHide)
	self:SetScript('OnEvent', self.OnEvent)

	self:RegisterEvent('PLAYER_LOGIN')
end


--[[ Frame Events ]]--

function tullaRange:OnEvent(event, ...)
	local action = self[event]
	if action then
		action(self, event, ...)
	end
end

function tullaRange:OnUpdate(elapsed)
	if self.elapsed < UPDATE_DELAY then
		self.elapsed = self.elapsed + elapsed
	else
		self:Update()
	end
end

function tullaRange:OnHide()
	self.elapsed = 0
end


--[[ Game Events ]]--

function tullaRange:PLAYER_LOGIN()
	if not TULLARANGE_COLORS then
		self:LoadDefaults()
	end

	self.colors = TULLARANGE_COLORS
	self.buttonsToUpdate = {}

	hooksecurefunc('ActionButton_OnUpdate', self.RegisterButton)
	hooksecurefunc('ActionButton_UpdateUsable', self.UpdateButtonUsable)
	hooksecurefunc('ActionButton_Update', self.UpdateButtonUsable)

	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('PLAYER_TARGET_CHANGED')
	self:RegisterEvent('PLAYER_FOCUS_CHANGED')
end

function tullaRange:PLAYER_ENTERING_WORLD()
	self:Update()
end

function tullaRange:PLAYER_TARGET_CHANGED()
	self:Update()
end

function tullaRange:PLAYER_FOCUS_CHANGED()
	self:Update()
end


--[[ Actions ]]--

function tullaRange:Update()
	self:UpdateButtons(self.elapsed)
	self.elapsed = 0
end

function tullaRange:ForceColorUpdate()
	for button in pairs(self.buttonsToUpdate) do
		button.redRangeRed = nil
		tullaRange.UpdateButtonUsable(button)
	end
end

function tullaRange:UpdateShown()
	if next(self.buttonsToUpdate) then
		self:Show()
	else
		self:Hide()
	end
end

function tullaRange:UpdateButtons(elapsed)
	if not next(self.buttonsToUpdate) then
		self:Hide()
		return
	end

	for button in pairs(self.buttonsToUpdate) do
		self:UpdateButton(button, elapsed)
	end
end

function tullaRange:UpdateButton(button, elapsed)
	tullaRange.UpdateButtonUsable(button)
	tullaRange.UpdateFlash(button, elapsed)
end

function tullaRange:UpdateButtonStatus(button)
	if button:IsVisible() then
		self.buttonsToUpdate[button] = true
	else
		self.buttonsToUpdate[button] = nil
	end
	self:UpdateShown()
end



--[[ Button Hooking ]]--

function tullaRange.RegisterButton(button)
	button:HookScript('OnShow', tullaRange.OnButtonShow)
	button:HookScript('OnHide', tullaRange.OnButtonHide)
	button:SetScript('OnUpdate', nil)

	tullaRange:UpdateButtonStatus(button)
end

function tullaRange.OnButtonShow(button)
	tullaRange:UpdateButtonStatus(button)
end

function tullaRange.OnButtonHide(button)
	tullaRange:UpdateButtonStatus(button)
end


--[[ Range Coloring ]]--

function tullaRange.UpdateButtonUsable(button)
	local id = ActionButton_GetPagedID(button)
	local isUsable, notEnoughMana = IsUsableAction(id)
	local r, g, b, a

	--usable
	if isUsable then
		--but out of range
		if ActionHasRange(id) and IsActionInRange(id) == 0 then
			if not button.redRangeRed then
				r, g, b = tullaRange:GetColor('oor')
				button.redRangeRed = true
			end
		--in rage
		elseif button.redRangeRed then
			r, g, b = tullaRange:GetColor('normal')
			button.redRangeRed = nil
		end
	--out of mana
	elseif notEnoughMana then
		r, g, b = tullaRange:GetColor('oom')
	end

	if r then
		local icon =  _G[button:GetName() .. 'Icon']
		icon:SetVertexColor(r, g, b)

		local nt = button:GetNormalTexture()
		nt:SetVertexColor(r, g, b)
	end
end

function tullaRange.UpdateFlash(button, elapsed)
	if ActionButton_IsFlashing(button) then
		local flashtime = button.flashtime - elapsed

		if flashtime <= 0 then
			local overtime = -flashtime
			if overtime >= ATTACK_BUTTON_FLASH_TIME then
				overtime = 0
			end
			flashtime = ATTACK_BUTTON_FLASH_TIME - overtime

			local flashTexture = _G[button:GetName() .. 'Flash']
			if flashTexture:IsShown() then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end

		button.flashtime = flashtime
	end
end


--[[ Configuration ]]--

function tullaRange:LoadDefaults()
	TULLARANGE_COLORS = {
		normal = {1, 1, 1},
		oor = {1, 0.3, 0.1},
		oom = {0.1, 0.3, 1},
	}
end

function tullaRange:Reset()
	self:LoadDefaults()
	self.colors = TULLARANGE_COLORS

	self:ForceColorUpdate()
end

function tullaRange:SetColor(index, r, g, b)
	local color = self.colors[index]
	color[1] = r
	color[2] = g
	color[3] = b

	self:ForceColorUpdate()
end

function tullaRange:GetColor(index)
	local color = self.colors[index]
	return color[1], color[2], color[3]
end

--[[ Load The Thing ]]--

tullaRange:Load()