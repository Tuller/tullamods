--[[
	Combuctor.lua
		Some sort of crazy visual inventory management system
--]]

Combuctor = DongleStub("Dongle-1.0"):New("Combuctor")

COMBUCTOR_LOCALS = {}
local L = COMBUCTOR_LOCALS
L.InventoryTitle = "%s's Inventory"
L.BankTitle = "%s's Bank"

function Combuctor:Enable()
	CombuctorDB = {
		frames = {
			inventory = {
				bags = {0, 1, 2, 3, 4, -2},
				pushable = 2,
			},
			bank = {
				bags = {-1, 5, 6, 7, 8, 9, 10, 11},
				pushable = 1,
			}
		}
	}

	self.frames = {
		CombuctorFrame:Create(L.InventoryTitle, CombuctorDB.frames.inventory),
		CombuctorFrame:Create(L.BankTitle, CombuctorDB.frames.bank, true)
	}

	self:HookBagEvents()
end

function Combuctor:Show(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:ShowBag(bag, auto)
				return
			end
		end
	end
end

function Combuctor:Hide(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:HideBag(bag, auto)
				return
			end
		end
	end
end

function Combuctor:Toggle(bag, auto)
	for _,frame in pairs(self.frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bagID == bag then
				frame:ToggleBag(bag, auto)
				return
			end
		end
	end
end

function Combuctor:HookBagEvents()
	local backpack = 0
	local keyring = KEYRING_CONTAINER

	OpenBackpack = function()
		Combuctor:Show(backpack, true)
	end

	CloseBackpack = function()
		Combuctor:Hide(backpack, true)
	end

	ToggleBackpack = function()
		Combuctor:Toggle(backpack)
	end

	OpenAllBags = function(force)
		if force then
			Combuctor:Show(backpack)
		else
			Combuctor:Toggle(backpack)
		end
	end

	CloseAllBags = function()
		Combuctor:Hide(backpack)
	end

	ToggleBag = function(bag)
		Combuctor:Toggle(bag)
	end

	ToggleKeyRing = function()
		Combuctor:Toggle(keyring)
	end

	BankFrame:UnregisterAllEvents()
	self:RegisterEvent('BANKFRAME_OPENED', function() self:Show(-1, true) end)
	self:RegisterEvent('BANKFRAME_CLOSED', function() self:Hide(-1, true) end)
end