local sets

local function CreateEventList(parent)
	local events = {
		[BAGNON_MAINOPTIONS_SHOW_BANK] = function(enable, bank)
			if bank then
				if enable then
					sets.showBankAtBank = 1
				else
					sets.showBankAtBank = nil
				end
			else
				if enable then
					sets.showBagsAtBank= 1
				else
					sets.showBagsAtBank = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_VENDOR] = function(enable, bank)
			if bank then
				if enable then
					sets.showBankAtVendor= 1
				else
					sets.showBankAtVendor = nil
				end
			else
				if enable then
					sets.showBagsAtVendor= 1
				else
					sets.showBagsAtVendor = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_AH] = function(enable, bank)
			if bank then
				if enable then
					sets.showBankAtAH= 1
				else
					sets.showBankAtAH = nil
				end
			else
				if enable then
					sets.showBagsAtAH= 1
				else
					sets.showBagsAtAH = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_MAILBOX] = function(enable, bank)
			if bank then
				if enable then
					sets.showBankAtMail = 1
				else
					sets.showBankAtMail = nil
				end
			else
				if enable then
					sets.showBagsAtMail = 1
				else
					sets.showBagsAtMail = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_TRADING] = function(enable, bank)
			if bank then
				if enable then
					sets.showBankAtTrade= 1
				else
					sets.showBankAtTrade = nil
				end
			else
				if enable then
					sets.showBagsAtTrade= 1
				else
					sets.showBagsAtTrade = nil
				end
			end
		end,

		[BAGNON_MAINOPTIONS_SHOW_CRAFTING] = function(enable, bank)
			if bank then
				if enable then
					sets.showBankAtCraft = 1
				else
					sets.showBankAtCraft = nil
				end
			else
				if enable then
					sets.showBagsAtCraft= 1
				else
					sets.showBagsAtCraft = nil
				end
			end
		end
	}
	
	local show = parent:CreateFontString('ARTWORK')
	show:SetFontObject('GameFontHighlight')
	show:SetText(BAGNON_MAINOPTIONS_SHOW)
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
		sets.replaceBags = 1
	else
		sets.replaceBags = nil
	end
end

function BagnonOptions_ShowTooltips(enable)
	if enable then
		sets.showTooltips = 1
	else
		sets.showTooltips = nil
	end
end

function BagnonOptions_ShowQualityBorders(enable)
	if enable then
		sets.qualityBorders = 1
	else
		sets.qualityBorders = nil
	end
	
	local bags = Bagnon:GetInventory()
	if bags and bags:IsShown() then
		bags:Regenerate()
	end
	
	local bank = Bagnon:GetBank()
	if bank and bank:IsShown() then
		bank:Regenerate()
	end
end


--[[ OnX Functions ]]--

function BagnonOptions_OnLoad()
	sets = BagnonUtil:GetSets()
	CreateEventList(this)
end

function BagnonOptions_OnShow()
	local name = this:GetName()

	getglobal(name .. "Tooltips"):SetChecked(sets.showTooltips)
	getglobal(name .. "Quality"):SetChecked(sets.qualityBorders)
	getglobal(name .. "ReplaceBags"):SetChecked(sets.replaceBags)

	getglobal(name .. "1Bags"):SetChecked(sets.showBagsAtBank)
	getglobal(name .. "2Bags"):SetChecked(sets.showBagsAtVendor)
	getglobal(name .. "3Bags"):SetChecked(sets.showBagsAtAH)
	getglobal(name .. "4Bags"):SetChecked(sets.showBagsAtMail)
	getglobal(name .. "5Bags"):SetChecked(sets.showBagsAtTrade)
	getglobal(name .. "6Bags"):SetChecked(sets.showBagsAtCraft)

	getglobal(name .. "1Bank"):SetChecked(sets.showBankAtBank)
	getglobal(name .. "2Bank"):SetChecked(sets.showBankAtVendor)
	getglobal(name .. "3Bank"):SetChecked(sets.showBankAtAH)
	getglobal(name .. "4Bank"):SetChecked(sets.showBankAtMail)
	getglobal(name .. "5Bank"):SetChecked(sets.showBankAtTrade)
	getglobal(name .. "6Bank"):SetChecked(sets.showBankAtCraft)
end