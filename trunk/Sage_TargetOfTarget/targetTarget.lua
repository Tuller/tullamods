--[[
	Sage Target of Target
		A TargetOfTarget frame based on Sage

	A target of <unit frame> needs two parts:
		A watcher frame
			this frame watches a unit for changes in that unit's target.

--]]

--[[ UI Templates ]]--

--npc info frame
--update the unit's level/name/class/type/faction
local function NPCInfo_Update(self, unit)
	self.class:SetText(SageInfo.GetClass(unit))
	self.type:SetText(SageInfo.GetClassification(unit))
end

local function NPCInfo_Create(parent)
	local npc = CreateFrame('Frame', nil, parent)
	npc:SetAlpha(parent:GetAlpha())

	npc.class = npc:CreateFontString(nil, 'OVERLAY')
	npc.class:SetFontObject(SageFontSmall)
	npc.class:SetJustifyH('LEFT')
	npc.class:SetPoint('LEFT', npc)
	
	npc.type = npc:CreateFontString(nil, 'OVERLAY')
	npc.type:SetFontObject(SageFontSmall)
	npc.type:SetJustifyH('RIGHT')
	npc.type:SetPoint('RIGHT', npc)	

	npc.Update = NPCInfo_Update

	return npc
end


--[[ Update ]]--

local function UpdateAll(frame)
	frame.info:UpdateAll()
	frame.info:UpdateNameColor()
	frame.health:UpdateAll()
	frame.npc:Update(frame.id)
end


--[[ Startup ]]--

local function OnCreate(self)
	self.info = SageInfo.Create(self)
	self.info:SetPoint("TOPLEFT", self)
	self.info:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -16)

	self.health = SageHealth.Create(self)
	self.health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	self.health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -18)

	self.npc = NPCInfo_Create(self)
	self.npc:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	self.npc:SetPoint("BOTTOMRIGHT", self.health , "BOTTOMRIGHT", 0, -12)
	
	self.click:SetPoint('TOPLEFT', self.info)
	self.click:SetPoint('BOTTOMRIGHT', self.npc)
	
	self.toUpdate = 0
	self.UpdateAll = UpdateAll
	
	self:SetScript('OnEvent', function() self:UpdateAll() end)
	
	self:SetScript('OnUpdate', function()
		self.toUpdate = self.toUpdate - arg1
		if self.toUpdate <= 0 then
			self.toUpdate = self.sets.updateInterval
			self:UpdateAll()
		end
	end)
end

Sage.AddStartup(function()
	if not Sage.GetFrameSets('targettarget') then
		Sage.SetFrameSets('targettarget', {
			updateInterval = 0.1, 
			minWidth = 85, 
			x = 686, 
			y = 502.999, 
			anchor = 'targetRT',
		})
	end

	local frame = SageFrame.Create('targettarget', OnCreate)
	frame:SetWidth(frame.sets.minWidth)
	frame:SetHeight(46)

	frame:RegisterEvent('PLAYER_TARGET_CHANGED')
end)