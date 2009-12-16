--[[
	tullaRange
		Adds out of range coloring to action buttons
		Derived from RedRange with negligable improvements to CPU usage
--]]

--[[ locals and speed ]]--

local _G = _G
local UPDATE_DELAY = 0.1

local ActionButton_GetPagedID = ActionButton_GetPagedID
local ActionButton_IsFlashing = ActionButton_IsFlashing
local IsUsableAction = IsUsableAction
local ActionHasRange = ActionHasRange
local IsActionInRange = IsActionInRange


--[[ The main thing ]]--

local tullaRange = CreateFrame('Frame', 'tullaRange', UIParent)

function tullaRange:Load()
	self.buttonsToUpdate = {}

	hooksecurefunc('ActionButton_OnUpdate', self.RegisterButton)
	hooksecurefunc('ActionButton_UpdateUsable', self.UpdateButtonUsable)
	hooksecurefunc('ActionButton_Update', self.UpdateButtonUsable)

	self:SetScript('OnUpdate', self.OnUpdate)
	self:SetScript('OnHide', self.OnHide)
	self:SetScript('OnEvent', self.OnEvent)

	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('PLAYER_TARGET_CHANGED')
	self:RegisterEvent('PLAYER_FOCUS_CHANGED')

	self:Hide()
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
		self.elapsed = 0
		self:UpdateButtons()
	end
end

function tullaRange:OnHide()
	self:ForceUpdateOnNextFrame()
end


--[[ Game Events ]]--

function tullaRange:PLAYER_ENTERING_WORLD()
	self:ForceUpdateOnNextFrame()
end

function tullaRange:PLAYER_TARGET_CHANGED()
	self:ForceUpdateOnNextFrame()
end

function tullaRange:PLAYER_FOCUS_CHANGED()
	self:ForceUpdateOnNextFrame()
end


--[[ Actions ]]--

function tullaRange:ForceUpdateOnNextFrame()
	self.elapsed = UPDATE_DELAY
end

function tullaRange:UpdateShown()
	if next(self.buttonsToUpdate) then
		self:Show()
	else
		self:Hide()
	end
end

function tullaRange:UpdateButtons()
	if not next(self.buttonsToUpdate) then
		self:Hide()
		return
	end

	for button in pairs(self.buttonsToUpdate) do
		self:UpdateButton(button)
	end
end

function tullaRange:UpdateButton(button)
	tullaRange.UpdateButtonUsable(button)
	tullaRange.UpdateFlash(button, UPDATE_DELAY)
end



--[[ Button Hooking ]]--

function tullaRange.RegisterButton(button)
	button:HookScript('OnShow', tullaRange.OnButtonShow)
	button:HookScript('OnHide', tullaRange.OnButtonHide)
	button:SetScript('OnUpdate', nil)

	tullaRange:UpdateButtonStatus(button)
end

function tullaRange:UpdateButtonStatus(button)
	if button:IsVisible() then
		self.buttonsToUpdate[button] = true
	else
		self.buttonsToUpdate[button] = nil
	end
	self:UpdateShown()
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

	if isUsable then
		if ActionHasRange(id) and IsActionInRange(id) == 0 then
			local icon = _G[button:GetName() .. 'Icon']
			local normalTexture = button:GetNormalTexture()
			local r, g, b = tullaRange.GetOORColor()

			icon:SetVertexColor(r, g, b)
			normalTexture:SetVertexColor(r, g, b)
			button.redRangeRed = true
		elseif button.redRangeRed then
			local icon = _G[button:GetName() .. 'Icon']
			local normalTexture = button:GetNormalTexture()
			local r, g, b = tullaRange.GetNormalColor()

			icon:SetVertexColor(r, g, b)
			normalTexture:SetVertexColor(r, g, b)
			button.redRangeRed = false
		end
	elseif notEnoughMana then
		local icon = _G[button:GetName() .. 'Icon']
		local normalTexture = button:GetNormalTexture()
		local r, g, b = tullaRange.GetOOMColor()

		icon:SetVertexColor(r, g, b)
		normalTexture:SetVertexColor(r, g, b)
	end
end

function tullaRange.UpdateFlash(button, elapsed)
	if ActionButton_IsFlashing(button) then
		local flashtime = button.flashtime
		flashtime = flashtime - elapsed

		if flashtime <= 0 then
			local overtime = -flashtime
			if overtime >= ATTACK_BUTTON_FLASH_TIME then
				overtime = 0
			end
			flashtime = ATTACK_BUTTON_FLASH_TIME - overtime

			local flashTexture = _G[self:GetName() .. 'Flash']
			if flashTexture:IsShown() then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end

		self.flashtime = flashtime
	end
end

function tullaRange.GetNormalColor()
	return 1, 1, 1
end

function tullaRange.GetOORColor()
	return 1.0, 0.3, 0.1
end

function tullaRange.GetOOMColor()
	return 0.1, 0.3, 1.0
end


--[[ Load The Thing ]]--

tullaRange:Load()