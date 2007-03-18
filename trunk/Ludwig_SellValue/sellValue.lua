--[[
	Ludwig_SellValue -
		Originally based on SellValueLite, this addon allows viewing of sellvalues
--]]

local base36 = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
local maxBase = 10 + #base36
local lastMoney = 0

local function ToBase(num, base)
	local newNum = ''
	while num > 0 do
		local remain = mod(num, base)
		num = floor(num / base)
		if remain > 9 then
			newNum = base36[remain-9] .. newNum
		else
			newNum = remain .. newNum
		end
	end
	return newNum
end

local cache = {}
setmetatable(cache, {__index = function(t, i)
	if LudwigSV then
		local c = LudwigSV:match(i .. ',(%w+);')
		if c then t[i] = c end
		return c
	end
end})

--[[ Local Functions ]]--

local function LinkToID(link)
	if link then
		return tonumber(link) or tonumber(link:match('item:(%d+)') or tonumber(select(2, GetItemInfo(link)):match('item:(%d+)')))
	end
end

local function SaveCost(id, cost)
	local id = ToBase(id, maxBase)
	local cost = ToBase(cost, maxBase)

	if cost ~= cache[id] then 
		LudwigSVCache[id] = cost
	end
end

local function GetCost(id)
	local id = ToBase(id, maxBase)
	local cost = LudwigSVCache[id] or cache[id]

	if cost then
		return tonumber(cost, maxBase)
	end
end


--[[  Function Hooks ]]--

local function AddMoneyToTooltip(frame, id, count)
    if id and not MerchantFrame:IsVisible() then
		local cost = GetCost(id)
		if cost then
			frame:AddLine(SELLVALUE_COST, 1, 1,	0)
			SetTooltipMoney(frame, cost * (count or 1))
			frame:Show()
		end
    end
end

local function pHook(action, method)
	return function(...)
		action(...)
		method(...)
	end
end

local function IsValidTooltip(frame)
	return frame == GameTooltip and frame:IsShown()
end

GameTooltip.SetBagItem = pHook(GameTooltip.SetBagItem, function(self, bag, slot)
	if IsValidTooltip(self) then
		local id = LinkToID(GetContainerItemLink(bag, slot))
		local count = select(2, GetContainerItemInfo(bag, slot))

		AddMoneyToTooltip(GameTooltip, id, count)
	end
end)

GameTooltip.SetLootItem = pHook(GameTooltip.SetLootItem, function(self, slot)
	if IsValidTooltip(self) then
		local id = LinkToID(GetLootSlotLink(slot))
		local count = select(3, GetLootSlotInfo(slot))

		AddMoneyToTooltip(self, id, count)
	end
end)

GameTooltip.SetHyperlink = pHook(GameTooltip.SetHyperlink, function(self, link)
	if IsValidTooltip(self) then
		AddMoneyToTooltip(self, LinkToID(link))
	end
end)

GameTooltip.SetLootRollItem = pHook(GameTooltip.SetLootRollItem, function(self, id)
	if IsValidTooltip(self) then
		local id = LinkToID(GetLootRollItemLink(id))
		local count = select(3, GetLootRollItemInfo(id))

		AddMoneyToTooltip(self, id, count)
	end
end)

GameTooltip.SetAuctionItem = pHook(GameTooltip.SetAuctionItem , function(self, type, index)
	if IsValidTooltip(self) then
		local id = LinkToID(GetAuctionItemLink(type, index))
		local count = select(3, GetAuctionItemInfo(type, index))

		AddMoneyToTooltip(self, id, count)
	end
end)

GameTooltip.SetQuestItem = pHook(GameTooltip.SetQuestItem, function(self, type, id)
	if IsValidTooltip(self) then
		AddMoneyToTooltip(self, LinkToID(GetQuestItemLink(type, id)), 1)
	end
end)

GameTooltip.SetTradeSkillItem = pHook(GameTooltip.SetTradeSkillItem, function(self, type, id)
	if IsValidTooltip(self) then
		if not id then
			AddMoneyToTooltip(self, LinkToID(GetTradeSkillItemLink(type)), 1)
		end
	end
end)


--[[ Tooltip Scanner ]]--

local function SavePrices(tip)
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = LinkToID(GetContainerItemLink(bag, slot))
			if id then
				local count = select(2, GetContainerItemInfo(bag, slot))
				lastMoney = 0
				tip:SetBagItem(bag, slot)

				if lastMoney and lastMoney > 0 then
					SaveCost(id, lastMoney/count)
				end
			end
		end
	end
end

-- local function ConvertData(t)
	-- for id, cost in pairs(t) do
		-- if cost > 0 then
			-- local cost = ToBase(tonumber(cost), maxBase)
			-- local id = ToBase(tonumber(id), maxBase)
			-- local prevCost = cache[id]
			-- if prevCost then
				-- if prevCost ~= cost then
					-- LudwigSV:gsub(format('%s,%s;', id, prevCost), format('%s,%s;', id, cost))
				-- end
			-- else
				-- LudwigSV = (LudwigSV or '') .. format('%s,%s;', id, cost)
			-- end
		-- end
	-- end
-- end

-- local function LoadData()
	-- if not LudwigSVCache then
		-- LudwigSVCache = {}
	-- end
		
	-- if not LudwigSV then
		-- if LudwigSV_Defaults then
			-- ConvertData(LudwigSV_Defaults)
		-- end

		-- if Ludwig_SellValues then
			-- ConvertData(Ludwig_SellValues)
		-- end
		
		-- if ColaLight and ColaLight.db.account.SellValues then
			-- ConvertData(ColaLight.db.account.SellValues)
		-- end
	-- end
-- end

function LudwigSV_Compress()
	for id, cost in pairs(LudwigSVCache) do
		local prevCost = cache[id]
		if prevCost then
			if prevCost ~= cost then
				LudwigSV:gsub(format('%s,%s;', id, prevCost), format('%s,%s;', id, cost))
			end
		else
			LudwigSV = (LudwigSV or '') .. format('%s,%s;', id, cost)
		end
		LudwigSVCache[id] = nil
	end
end


--[[ Events ]]--

local f = CreateFrame('GameTooltip', 'LudwigSVTooltip', nil, 'GameTooltipTemplate')
f:SetScript('OnTooltipAddMoney', function() if not InRepairMode() then lastMoney = arg1 end end)

f:SetScript('OnEvent', function()
	if event == 'MERCHANT_SHOW' then
		SavePrices(this)
	elseif event == 'ADDON_LOADED' and arg1 == 'Ludwig_SellValue' then
		this:UnregisterEvent('ADDON_LOADED')
		if LudwigSV_LoadDefaults then
			LudwigSV_LoadDefaults()
		end
	end
end)
f:RegisterEvent('MERCHANT_SHOW')
f:RegisterEvent('ADDON_LOADED')