--[[
	main.lua
		The bagnon driver thingy
		
	SetCurrentGuildBankTab	Selects a tab in the guild bank
	SetGuildBankTabInfo	Sets the name and icon for a guild bank tab
	SetGuildBankTabPermissions	Changes guild bank tab permissions for the guild rank being edited
	SetGuildBankTabWithdraw	Sets the number of item withdrawals allowed per day for the guild rank being edited
	SetGuildBankText	Sets the info text for a guild bank tab
	SetGuildBankWithdrawLimit	Sets the maximum amount of money withdrawals per day allowed for the guild rank being edited
		
	SplitGuildBankItem	Picks up only part of a stack of items from the guild bank
	WithdrawGuildBankMoney	Attempts to withdraw money from the guild bank
			
	AutoStoreGuildBankItem	Withdraws the item(s) from a slot in the guild bank, automatically adding to the player's bags
	BuyGuildBankTab	Purchases the next available guild bank tab
	
	CloseGuildBankFrame	Ends interaction with the guild bank vault
	DepositGuildBankMoney	Deposits money into the guild bank
	GetCurrentGuildBankTab	Returns the currently selected guild bank tab

	CanGuildBankRepair	Returns whether the player is allowed to pay for repairs using guild bank funds
	GetGuildBankItemInfo	Returns information about the contents of a guild bank item slot
	GetGuildBankItemLink	Returns a hyperlink for an item in the guild bank
	GetGuildBankMoney	Returns the amount of money in the guild bank
	GetGuildBankMoneyTransaction	Returns information about a transaction in the guild bank money log
	GetGuildBankTabCost	Returns the cost of the next available guild bank tab
	GetGuildBankTabInfo	Returns information about a guild bank tab
	GetGuildBankTabPermissions	Returns information about guild bank tab privileges for the guild rank currently being edited
	
	GetGuildBankText	Returns text associated with a guild bank tab
	GetGuildBankTransaction	Returns information about a transaction in the log for a guild bank tab
	
	GetGuildBankWithdrawLimit	Returns the guild bank money withdrawal limit for the guild rank currently being edited
	GetGuildBankWithdrawMoney	Returns the amount of money the player is allowed to withdraw from the guild bank per day
	
	GetNumGuildBankMoneyTransactions	Returns the number of transactions in the guild bank money log
	
	GetNumGuildBankTabs	Returns the number of purchased tabs in the guild bank
	
	PickupGuildBankItem	Picks up an item from or puts an item into the guild bank
	PickupGuildBankMoney	Puts money from the guild bank onto the cursor
	
	tab:
		SetCurrentGuildBankTab	Selects a tab in the guild bank
		SetGuildBankTabInfo	Sets the name and icon for a guild bank tab
		SetGuildBankTabPermissions	Changes guild bank tab permissions for the guild rank being edited
		SetGuildBankText	Sets the info text for a guild bank tab
		
		BuyGuildBankTab	Purchases the next available guild bank tab
		GetCurrentGuildBankTab	Returns the currently selected guild bank tab
		
		GetGuildBankTabCost	Returns the cost of the next available guild bank tab
		GetGuildBankTabInfo	Returns information about a guild bank tab
		GetGuildBankTabPermissions	Returns information about guild bank tab privileges for the guild rank currently being edited
		
		GetGuildBankText	Returns text associated with a guild bank tab
		GetGuildBankTransaction	Returns information about a transaction in the log for a guild bank tab
		
		GetNumGuildBankTransactions	Returns the number of entries in a guild bank tab's transaction log
		
		QueryGuildBankLog	Requests the item transaction log for a guild bank tab from the server
		QueryGuildBankTab	Requests information about the contents of a guild bank tab from the server
		QueryGuildBankText	Requests guild bank tab info text from the server
		
	item:
		AutoStoreGuildBankItem	Withdraws the item(s) from a slot in the guild bank, automatically adding to the player's bags
		GetGuildBankItemInfo	Returns information about the contents of a guild bank item slot
		GetGuildBankItemLink	Returns a hyperlink for an item in the guild bank
		
		PickupGuildBankItem	Picks up an item from or puts an item into the guild bank
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local GuildBank = Bagnon:NewModule('GuildBank', 'AceEvent-3.0', 'AceConsole-3.0')

function GuildBank:OnEnable()
	Bagnon.GuildFrame:New('guildbank')

	self:RegisterEvent('GUILDBANKFRAME_OPENED')
	self:RegisterEvent('GUILDBANKFRAME_CLOSED')
end

function GuildBank:GUILDBANKFRAME_OPENED()
	Bagnon.FrameSettings:Get('guildbank'):Show()
end

function GuildBank:GUILDBANKFRAME_CLOSED()
	Bagnon.FrameSettings:Get('guildbank'):Hide()
end
