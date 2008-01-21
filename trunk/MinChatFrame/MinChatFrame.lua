--[[
		MinChatFrame
			Tweaks to the Chat Frame

		Version History:
			9/29/5
				Added mousewheel scrolling
				Moved the editbox to the top of the chat frame
				Hid the scroll buttons
				Hid the emote/language buttons
--]]

local function HideEmoteButtons()
	ChatFrameMenuButton:Hide()
	ChatMenu:Hide()
	EmoteMenu:Hide()
	LanguageMenu:Hide()
	VoiceMacroMenu:Hide()
end

local function HideScrollButtons()
	for i = 1, 7 do
		getglobal("ChatFrame" .. i):SetScript("OnShow", MinChat_HideButtonsOnShow)
		getglobal("ChatFrame" .. i .. "BottomButton"):Hide()
		getglobal("ChatFrame" .. i .. "DownButton"):Hide()
		getglobal("ChatFrame" .. i .. "UpButton"):Hide()
	end
end

function MinChatFrame_HideButtonsOnShow()
	SetChatWindowShown(this:GetID(), 1)
end

function MinChatFrame_Load()
	ChatFrameEditBox:SetPoint("TOPLEFT", "ChatFrame1", "TOPLEFT", -5, 10)
	ChatFrameEditBox:SetWidth(400)

	HideEmoteButtons()
	HideScrollButtons()
end