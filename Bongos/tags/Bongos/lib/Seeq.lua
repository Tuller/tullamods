--[[
	Seeq.lua
		A library of functions that will perform an action right when the user is no longer in combat
--]]

--[[ library stuff ]]--

assert(TLib, 'TLib not loaded')

local VERSION = '7.1.4'
if TLib.IsCurrent(SeeQ, VERSION) then return end

if not SeeQ then
	local function OnEvent()
		for i, action in pairs(this.actions) do
			action()
			this.actions[i] = nil
		end

		for frame in pairs(this.showList) do
			frame:Show()
			this.showList[frame] = nil
		end

		for frame in pairs(this.hideList) do
			frame:Hide()
			this.hideList[frame] = nil
		end
	end

	SeeQ = CreateFrame('Frame')
	SeeQ.actions = {}
	SeeQ.showList = {}
	SeeQ.hideList = {}
	SeeQ:SetScript('OnEvent', OnEvent)
	SeeQ:RegisterEvent('PLAYER_REGEN_ENABLED')
end
SeeQ.version = version


--[[ Usable Functions ]]--

function SeeQ:Do(action)
	if InCombatLockdown() then
		table.insert(self.actions, action)
	else
		action()
	end
end

function SeeQ:ShowFrame(frame)
	if InCombatLockdown() then
		self.showList[frame] = true
		self.hideList[frame] = nil
	else
		frame:Show()
	end
end

function SeeQ:HideFrame(frame)
	if InCombatLockdown() then
		self.hideList[frame] = true
		self.showList[frame] = nil
	else
		frame:Hide()
	end
end