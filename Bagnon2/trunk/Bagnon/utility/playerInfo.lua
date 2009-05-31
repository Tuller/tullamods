--[[
	player.lua
		Generic methods for accessing player information
--]]


--[[ Player Info ]]--

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local PlayerInfo = {}
Bagnon.PlayerInfo = PlayerInfo

local CURRENT_PLAYER = UnitName('player')

function PlayerInfo:IsCached(player)
	return player ~= CURRENT_PLAYER
end

function PlayerInfo:AtBank()
	return Bagnon.BagEvents:AtBank()
end