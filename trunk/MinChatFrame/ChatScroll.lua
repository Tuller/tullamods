--------------------------------------------------------------------------
-- ChatScroll.lua 
--------------------------------------------------------------------------
--[[
ChatScroll

author: AnduinLothar    <Anduin@cosmosui.org>

Replaces an old Cosmos FrameXML Hack.
-ChatFrame Mouse Wheel Scroll


]]--

function ChatScroll_OnMouseWheel(frame, arg1)
	if not IsShiftKeyDown() then
		if arg1 > 0 then
			frame:ScrollUp()
			frame:ScrollUp()
			frame:ScrollUp()
		elseif arg1 < 0 then
			frame:ScrollDown()
			frame:ScrollDown()
			frame:ScrollDown()
		end
	else
		if arg1> 0 then
			frame:ScrollToTop()
		elseif arg1 < 0 then
			frame:ScrollToBottom()
		end
	end
end
