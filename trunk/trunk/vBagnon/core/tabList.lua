--[[
	TabList
		A list of category tabs
--]]

BagnonTabList = CreateFrame('Frame')
local TabList_mt = {__index = BagnonTabList}

--[[ Constructor ]]--

local function OnShow()
	this:UpdateAllTabs()
end

local function OnHide()
	this:RemoveAllTabs()
end

local function TabList_Create(lastCreated)
	local name = 'BagnonTabList' .. lastCreated
	local tabList = CreateFrame('Frame', name)
	setmetatable(tabList, TabList_mt)
	
	tabList.tabs = {}
	tabList:SetClampedToScreen(true)
	
	tabList:SetScript('OnShow', OnShow)
	tabList:SetScript('OnHide', OnHide)

	return tabList
end

function BagnonTabList.Create(parent)
	local tabList = TPool.Get('BagnonTabList', TabList_Create)	
	tabList:Set(parent)
	
	return tabList
end

function BagnonTabList:Set(frame)
	self:SetFrameLevel(0)
	self:SetParent(frame)
	self:SetAlpha(frame:GetAlpha())
	self:UpdateAllTabs()
end

function BagnonTabList:Release()
	self:RemoveAllTabs()
	TPool.Release(self, 'BagnonTabList')
end

function BagnonTabList:Update(index)
	self:SetTab(index)
end

function BagnonTabList:SetTab(index, dontUpdate)
	local tab = self.tabs[index]
	if not tab then
		tab = BagnonTab.Get()
		self.tabs[index] = tab
	end
	tab:Set(self, index)
	
	if not dontUpdate then
		self:Layout()
	end
end

function BagnonTabList:UpdateAllTabs()
	local cats = self:GetParent().cats
	local oldCount = self.count or 0
	local count = 0

	if cats then
		for i = 1, self:GetParent():GetNumCats() do
			local cat = cats[i]
			if cat then
				self:SetTab(i, true)
				count = count + 1
			else
				self:RemoveTab(i, true)
			end
		end
		
		for i in pairs(self.tabs) do
			local cat = cats[i]
			if not cat then
				self:RemoveTab(i, true)
			end
		end
	end
	
	if count ~= oldCount then
		self.count = count
		self:GetParent().sizeChanged = true
	end
	
	self:Layout()
end

function BagnonTabList:RemoveTab(i, dontLayout)
	local tab = self.tabs[i]
	if tab then
		tab:Release()
		self.tabs[i] = nil
	end
end

function BagnonTabList:RemoveAllTabs()
	for i in pairs(self.tabs) do
		self:RemoveTab(i, true)
	end
end

function BagnonTabList:Layout()
	--figure out if there's multiple tabs
	local count = 0
	for _ in pairs(self.tabs) do
		count = count + 1
		if count > 1 then break end
	end
	
	--one tab open, hide the tab window
	if count <= 1 then
		self:Hide()
		self:SetWidth(0); self:SetHeight(0)	
	--multiple tabs open, lay them out
	else
		self:Show()

		local prev
		local width = 0
		local count = 0
		for i = 1, self:GetParent():GetNumCats() do
			local tab = self.tabs[i]
			if tab then
				tab:SetPoint('TOPLEFT', self, 'TOPLEFT', (tab:GetWidth() + 2)*count, 0)
				count = count + 1
			end
		end
		self:SetWidth(26 * count)
		self:SetHeight(26)
	end
end