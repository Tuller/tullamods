local playerSets

local function CreateEventList(parent)
	local events = {
		[BAGNON_MAINOPTIONS_SHOW_BANK] = function(enable, bank)
			if bank then
				if enable then
					playerSets.showBankAtBank = 1
				else
					playerSets.showBankAtBank = nil
				end
			else
				if enable then
					playerSets.showBagsAtBank= 1
				else
					playerSets.showBagsAtBank = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_VENDOR] = function(enable, bank)
			if bank then
				if enable then
					playerSets.showBankAtVendor= 1
				else
					playerSets.showBankAtVendor = nil
				end
			else
				if enable then
					playerSets.showBagsAtVendor= 1
				else
					playerSets.showBagsAtVendor = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_AH] = function(enable, bank)
			if bank then
				if enable then
					playerSets.showBankAtAH= 1
				else
					playerSets.showBankAtAH = nil
				end
			else
				if enable then
					playerSets.showBagsAtAH= 1
				else
					playerSets.showBagsAtAH = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_MAILBOX] = function(enable, bank)
			if bank then
				if enable then
					playerSets.showBankAtMail = 1
				else
					playerSets.showBankAtMail = nil
				end
			else
				if enable then
					playerSets.showBagsAtMail = 1
				else
					playerSets.showBagsAtMail = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_TRADING] = function(enable, bank)
			if bank then
				if enable then
					playerSets.showBankAtTrade= 1
				else
					playerSets.showBankAtTrade = nil
				end
			else
				if enable then
					playerSets.showBagsAtTrade= 1
				else
					playerSets.showBagsAtTrade = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_CRAFTING] = function(enable, bank)
			if bank then
				if enable then
					playerSets.showBankAtCraft = 1
				else
					playerSets.showBankAtCraft = nil
				end
			else
				if enable then
					playerSets.showBagsAtCraft= 1
				else
					playerSets.showBagsAtCraft = nil
				end
			end
		end
	}
	
	local show = parent:CreateFontString('ARTWORK')
	show:SetFontObject('GameFontHighlight')
	show:SetText(BAGNON_MAINOPTIONS_SHOW)
	--show:SetPoint('TOPLEFT', parent:GetName() .. 'ReplaceBank', 'BOTTOMLEFT', 6, -8)
	show:SetPoint('TOPLEFT', parent:GetName() .. 'ReplaceBags', 'BOTTOMLEFT', 6, -8)
	
	local bank = parent:CreateFontString('ARTWORK')
	bank:SetFontObject('GameFontHighlight')
	bank:SetText(BAGNON_MAINOPTIONS_BANK)
	bank:SetPoint('RIGHT', show, 'LEFT', parent:GetWidth() - 24, 0)
	
	local bags = parent:CreateFontString('ARTWORK')
	bags:SetFontObject('GameFontHighlight')
	bags:SetText(BAGNON_MAINOPTIONS_BAGS)
	bags:SetPoint('RIGHT', bank, 'LEFT', -12, 0)
	
	local prev; local i = 0
	for name, action in pairs(events) do
		i = i + 1

		local button = CreateFrame('Frame', parent:GetName() .. i, parent, 'BagnonOptionsEventButton')
		button.Click = action
		
		getglobal(button:GetName() .. 'Title'):SetText(name)

		if prev then
			button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT')
			button:SetPoint('BOTTOMRIGHT', prev, 'BOTTOMRIGHT', 0, -32)
		else
			button:SetPoint('TOPLEFT', show, 'BOTTOMLEFT', 0, -4)
			button:SetPoint('BOTTOMRIGHT', bank, 'BOTTOMRIGHT', 2, -36)
		end
		prev = button
	end
end

--[[ Config Functions ]]

function BagnonOptions_ReplaceBags(enable)
	if enable then
		playerSets.replaceBags = 1
	else
		playerSets.replaceBags = nil
	end
end
--[[
function BagnonOptions_ReplaceBank(enable)
	if enable then
		playerSets.replaceBank = 1
	else
		playerSets.replaceBank = nil
	end
end
--]]
function BagnonOptions_ShowTooltips(enable)
	if enable then
		playerSets.showTooltips = 1
	else
		playerSets.showTooltips = nil
	end
end

function BagnonOptions_ShowQualityBorders(enable)
	if enable then
		playerSets.qualityBorders = 1
	else
		playerSets.qualityBorders = nil
	end
	
	BagnonFrame.ForAllVisible('UpdateAllItems')
end

--[[ OnX Functions ]]--

function BagnonOptions_OnLoad()
	playerSets = BagnonLib.GetSets()
	CreateEventList(this)
	
	getglobal(this:GetName() .. "2Bags"):SetChecked(true)
	getglobal(this:GetName() .. "2Bags"):Disable()
	
	getglobal(this:GetName() .. "4Bags"):SetChecked(true)
	getglobal(this:GetName() .. "4Bags"):Disable()
end

function BagnonOptions_OnShow()
	local frameName = this:GetName()

	getglobal(frameName .. "Tooltips"):SetChecked(playerSets.showTooltips)
	getglobal(frameName .. "Quality"):SetChecked(playerSets.qualityBorders)
	getglobal(frameName .. "ReplaceBags"):SetChecked(playerSets.replaceBags)
--	getglobal(frameName .. "ReplaceBank"):SetChecked(playerSets.replaceBank)

	getglobal(frameName .. "1Bags"):SetChecked(playerSets.showBagsAtBank)
	--getglobal(frameName .. "ShowBagnon2"):SetChecked(BagnonSets.showBagsAtVendor)
	getglobal(frameName .. "3Bags"):SetChecked(playerSets.showBagsAtAH)
	--getglobal(frameName .. "ShowBagnon4"):SetChecked(BagnonSets.showBagsAtMail)
	getglobal(frameName .. "5Bags"):SetChecked(playerSets.showBagsAtTrade)
	getglobal(frameName .. "6Bags"):SetChecked(playerSets.showBagsAtCraft)

	getglobal(frameName .. "1Bank"):SetChecked(playerSets.showBankAtBank)
	getglobal(frameName .. "2Bank"):SetChecked(playerSets.showBankAtVendor)
	getglobal(frameName .. "3Bank"):SetChecked(playerSets.showBankAtAH)
	getglobal(frameName .. "4Bank"):SetChecked(playerSets.showBankAtMail)
	getglobal(frameName .. "5Bank"):SetChecked(playerSets.showBankAtTrade)
	getglobal(frameName .. "6Bank"):SetChecked(playerSets.showBankAtCraft)
end