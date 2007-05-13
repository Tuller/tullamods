--[[
	State.lua
		Does state changing for class bars and paging
--]]

local CAT_STANCE = 3
local PROWL_STANCE = 7
local CLASS = select(2, UnitClass("player"))
local STANCES = BONGOS_STANCES[CLASS]
local MAX_PAGES = 6

local function Trans(state, map)
	return format("%s:%s;", state, map)
end

local function Range(s, e)
	return format("%d-%d", s, e)
end


--[[ load/unload statemaps ]]--

function BState:Load()
	if not self.driver then
		local driver = CreateFrame("Frame", nil, UIParent, "SecureStateDriverTemplate")
		self:LoadStanceMaps(driver)
		self:LoadPageMaps(driver)
		self:LoadStateButton(driver)

		driver:SetAttribute("state", self:GetCurrentState())
		self.driver = driver
	end
end

function BState:Register(frame)
	if not self.driver then self:Load() end
	self.driver:SetAttribute("addchild", frame)

	frame:SetParent(self.driver)
	frame:SetAttribute("statemap-parent", "$input")
	frame:SetAttribute("state", self:GetCurrentState())
end

function BState:Unregister(frame)
	frame:SetParent(nil)
end


--[[ Stances ]]--

-- <oldStance><page>:<stance><page>;
function BState:GetStanceMap(stance)
	local stanceMap = ""
	local s, e = self:GetStanceRange()

	for oStance = s, e do
		for page = 0, MAX_PAGES-1 do
			stanceMap = stanceMap .. Trans(oStance * 10 + page, stance * 10 + page)
		end
	end
	return stanceMap
end

-- <cat><page>:<prowl><page>;
function BState:GetProwlMaps()
	local prowlMap = ""
	local catMap = ""

	for page = 0, MAX_PAGES-1 do
		prowlMap = prowlMap .. Trans(CAT_STANCE * 10 + page, PROWL_STANCE * 10 + page)
		catMap = catMap .. Trans(PROWL_STANCE * 10 + page, CAT_STANCE * 10 + page)
	end
	return prowlMap, catMap
end

function BState:LoadStanceMaps(driver)
	local s, e = self:GetStanceRange()

	if CLASS == "DRUID" then
		for stance = s, e-1 do
			driver:SetAttribute("statemap-stance-" .. stance, self:GetStanceMap(stance))
		end

		local prowl, cat = self:GetProwlMaps()
		driver:SetAttribute("statemap-stealth-1", prowl)
		driver:SetAttribute("statemap-stealth-0", cat)
	elseif e > 0 then
		for stance = s, e do
			driver:SetAttribute("statemap-stance-" .. stance, self:GetStanceMap(stance))
		end
	end
end


--[[ Paging ]]--

-- <stance><minPage>-<stance><maxPage>:<stance><newPage>;
function BState:GetPageMap(page)
	local maxPage = self:GetMaxPage()
	local pageMap = ""

	local s, e = self:GetStanceRange()
	for stance = s, e do
		pageMap = pageMap .. Trans(Range(stance*10, stance*10 + maxPage - 1), stance*10 + page-1)
	end
	return pageMap
end

function BState:LoadPageMaps(driver)
	for p = 1, MAX_PAGES do
		driver:SetAttribute("statemap-actionbar-" .. p, self:GetPageMap(p))
	end
end


--[[ Conversions ]]--

--takes a statemap (s<number> or p<number>) and returns all the states that map to it
function BState:MapToStates(stateMap)
	local _, stance, index = stateMap:match("(%w)(%d)(%d)")
	return stance * 10 + index
end

function BState:StateToMap(state)
	return format("s%d%d", mod(state, 10), state/10)
end


--[[ Access ]]--

function BState:GetStanceRange()
	if STANCES then
		if STANCES[0] then
			return 0, #STANCES
		end
		return 1, #STANCES
	end
	return 0, 0
end

function BState:GetMaxPage()
	return MAX_PAGES
end

function BState:GetStanceName(id)
	if STANCES then
		return STANCES[id] or BONGOS_UNKNOWN
	end
	return "unknown"
end

function BState:GetCurrentState()
	local state = GetActionBarPage() - 1
	local maxStance = select(2, self:GetStanceRange())
	if maxStance > 0 then
		if CLASS == "DRUID" and IsStealthed() and GetShapeshiftForm() == 3 then
			state = state + PROWL_STANCE * 10
		else
			state = state + GetShapeshiftForm() * 10
		end
	end
	return state
end