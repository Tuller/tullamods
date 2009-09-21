--[[
	tullaRange
		Out of range coloring
--]]

--[[ locals and speed ]]--

local UPDATE_DELAY = 0.1
local _G = _G
local ActionButton_GetPagedID = ActionButton_GetPagedID
local IsUsableAction = IsUsableAction
local ActionHasRange = ActionHasRange
local IsActionInRange = IsActionInRange


--[[ The main thing ]]--

local tullaRange = CreateFrame('Frame')

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
	self:UpdateTarget()
end

function tullaRange:PLAYER_TARGET_CHANGED()
	self:UpdateTarget()
end


--[[ Update Methods ]]--

function tullaRange:ForceUpdateOnNextFrame()
	self.elapsed = UPDATE_DELAY
end

function tullaRange:UpdateTarget()
	if self:IsShown() then
		self:UpdateButtons()
	end
	self:UpdateShown()
end

function tullaRange:UpdateShown()
	if next(self.buttonsToUpdate) and UnitExists('target') then
		self:Show()
	else
		self:Hide()
	end
end


--[[ Button Registering ]]--

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


--[[ Button Updating ]]--

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
	local newRange = false
	local id = ActionButton_GetPagedID(button)

	if ActionHasRange(id) and IsActionInRange(id) == 0 then
		newRange = true
	end

	if self.redRangeFlag ~= newRange then
		self.redRangeFlag = newRange
	end

	tullaRange.UpdateButtonUsable(button)
end

function tullaRange.UpdateButtonUsable(button)
	local id = ActionButton_GetPagedID(button)
	local isUsable, notEnoughMana = IsUsableAction(id)

	if isUsable then
		if ActionHasRange(id) and IsActionInRange(id) == 0 then
			local icon = _G[button:GetName() .. 'Icon']
			local normalTexture = button:GetNormalTexture()

			icon:SetVertexColor(0.8, 0.1, 0.1)
			normalTexture:SetVertexColor(0.8, 0.1, 0.1)
			button.redRangeRed = true
		elseif button.redRangeRed then
			local icon = _G[button:GetName() .. 'Icon']
			local normalTexture = button:GetNormalTexture()

			icon:SetVertexColor(1.0, 1.0, 1.0)
			normalTexture:SetVertexColor(1.0, 1.0, 1.0)
			button.redRangeRed = false
		end
	elseif notEnoughMana then
		local icon = _G[button:GetName() .. 'Icon']
		local normalTexture = button:GetNormalTexture()

		icon:SetVertexColor(0.1, 0.3, 1.0)
		normalTexture:SetVertexColor(0.1, 0.3, 1.0)
	end
end


--[[ Load The Thing ]]--

tullaRange:Load()