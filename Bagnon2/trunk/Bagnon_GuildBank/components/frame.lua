--[[
	GuildItemFrame.lua
		A specialized version of the bagnon item frame for guild banks
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Frame = Bagnon.Classy:New('Frame', Bagnon.Frame)
Frame:Hide()
Bagnon.GuildFrame = Frame

function Frame:CreateItemFrame()	
	local f = Bagnon.GuildItemFrame:New(self:GetFrameID(), self)
	self.itemFrame = f
	return f
end


function Frame:OnShow()
	PlaySound('GuildVaultOpen')

	self:UpdateEvents()
	self:UpdateLook()
end

function Frame:OnHide()
--	GuildBankPopupFrame:Hide()
	StaticPopup_Hide('GUILDBANK_WITHDRAW')
	StaticPopup_Hide('GUILDBANK_DEPOSIT')
	StaticPopup_Hide('CONFIRM_BUY_GUILDBANK_TAB')
	CloseGuildBankFrame()
	PlaySound('GuildVaultClose')
	
	self:UpdateEvents()

	--fix issue where a frame is hidden, but not via bagnon controlled methods (ie, close on escape)
	if self:IsFrameShown() then
		self:HideFrame()
	end
end


do
	---settings override
	local SavedFrameSettings = Bagnon.SavedFrameSettings
	function SavedFrameSettings:GetDefaultGuildBankSettings()
		local defaults = SavedFrameSettings.guildBankDefaults or {
			--frame
			frameColor = {0, 0, 0, 0.5},
			frameBorderColor = {0, 1, 0, 1},
			scale = 1,
			opacity = 1,
			point = 'CENTER',
			x = 0,
			y = 0,
			frameLayer = 'HIGH',

			--itemFrame
			itemFrameColumns = 14,
			itemFrameSpacing = 2,

			--optional components
			hasMoneyFrame = false,
			hasBagFrame = false,
			hasDBOFrame = true,
			hasSearchToggle = true,
			hasOptionsToggle = true,

			--dbo display object
			dataBrokerObject = 'BagnonLauncher',
		}

		SavedFrameSettings.guildBankDefaults = defaults
		return defaults
	end
end