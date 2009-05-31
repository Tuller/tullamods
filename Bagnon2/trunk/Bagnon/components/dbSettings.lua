
--[[

function DBSettings:Initialize(currentVersion)
	db = self:GetDB() or self:NewDB()
	if not self:GetDB() then
		db = {
			['version'] = version
		}
		db = 
	local db = _G['
end

function DBSettings:GetDB()
	

function DBSettings:GetDB()
	return _G['BagnonSettings']
end

function DBSettings

function DBSettings:GetGlobalSettings()
	local settings = self:GetDB().global
	if not settings then
		settings = self:GetDefaultGlobalSettings()
		self:GetDB().global = settings
	end
	return settings
end


function DBSettings:GetPlayerSettings(player, realm)
	local dbIndex = player .. '|' .. realm
	local settings = _G['BagnonSets'][dbIndex]
	
	if not settings then
		settings = self:ConstructPlayerSettings()
		_G['BagnonSets'][dbIndex] = settings
	end
	
	return settings
end

function DBSettings:GetFrameSettings(player, realm, frameID)
	local playerSettings = self:GetPlayerSettings()
	local settings = playerSettings.frames[frameID]
	
	if not settings then
		settings = self:ConstructFrameSettings()
		playerSettings.frames[frameID] = settings
	end
	return 
end

function DBSettings:ConstructGlobalSettings()
	return {
		highlightSlotsByQuality = true,
		highlightQuestItems = true,
	}
end

function DBSettings:ConstructPlayerSettings()
	return {
		frames = {
			inventory = {
				point = 'RIGHT',
				x = 0,
				y = 0,
				
				bags = {BACKPACK_CONTAINER, 1, 2, 3, 4},
				hiddenBags = {},
				
				locked = true,
				hasBagFame = true,
				hasMoneyFrame = true,
				isBagFrameVisible = true,
				
				bgColor = {
					r = 0,
					g = 0,
					b = 0.2,
					a = 0.5
				},
				
				columns = 8,
				spacing = 2
				scale = 1,
				opacity = 1,
			}
			bank = {
				point = 'LEFT',
				x = 0,
				y = 0,
				
				bags = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10}
				
				hiddenBags = {},
				
				locked = true,
				hasBagFrame = true,
				hasMoneyFrame = true,
				isBagFrameVisible = true,
				
				bgColor = {
					r = 0,
					g = 0,
					b = 0.2,
					a = 0.5
				}
				
				columns = 10,
				spacing = 2
				scale = 1,
				opacity = 1
			}
			keys = {
				point = 'RIGHT',
				x = 0,
				y = 0,
				
				x = 0,
				y = 300
				
				bags = {KEYRING_CONTAINER},
				
				hasBagFrame = false,
				hasMoneyFrame = false,
				isBagFrameVisible = false,
				
				bgColor = {
					r = 0,
					g = 0,
					b = 0,
					a = 0.5
				}
				
				columns = 4,
				spacing = 2
				scale = 1,
				opacity = 1
			}
		}
	}
end

function DBSettings:ConstructFrameSettings()
	return {
		point = 'CENTER',
		x = 0,
		y = 0,
		
		bags = {BACKPACK_CONTAINER, 1, 2, 3, 4},
		hiddenBags = {},
		
		locked = false,
		hasBagFame = true,
		hasMoneyFrame = true,
		isBagFrameVisible = true,
		
		bgColor = {
			r = 0,
			g = 0,
			b = 0,
			a = 0.5
		},
		
		columns = 10,
		spacing = 2
		scale = 1,
		opacity = 1
	}
end
--]]