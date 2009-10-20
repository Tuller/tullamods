--[[
	hoverMenu.lua
		A popup menu that is displayed when hovering over a RazerNaga frame in configuration mode

	Copyright (c) 2009 Razer USA Ltd.
	All rights reserved.

	Redistribution and use in source and binary forms, with or without 
	modification, are permitted provided that the following conditions are met:

		* Redistributions of source code must retain the above copyright notice, 
		  this list of conditions and the following disclaimer.
		* Redistributions in binary form must reproduce the above copyright
		  notice, this list of conditions and the following disclaimer in the 
		  documentation and/or other materials provided with the distribution.
		* Neither the name of the author nor the names of its contributors may 
		  be used to endorse or promote products derived from this software 
		  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
	LIABLE FORANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.
--]]

local HoverMenu = CreateFrame('Frame', nil, UIParent)
HoverMenu:Hide()

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')
local ICON_SHOW_MENU  = [[Interface\Icons\Trade_Engineering]]
local ICON_SHOW_FRAME = [[Interface\Icons\Spell_Nature_Invisibilty]]
local ICON_HIDE_FRAME = [[Interface\Icons\Ability_Stealth]]

Dominos.HoverMenu = HoverMenu

function HoverMenu:Set(frame)
	if not self.isLoaded then
		self:Load()
	end

	if self.owner then
		self.owner.drag:UnlockHighlight()
	end

	self.owner = frame
	if frame then
		self:Hide()
		self:ClearAllPoints()
		self:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT')
		frame.drag:LockHighlight()
		self:Show()
	else
		self:Hide()
	end
end

function HoverMenu:Free()
	self:Set(nil)
end

function HoverMenu:IsOwned(frame)
	return self.owner == frame
end

function HoverMenu:OnUpdate(elapsed)
	if not(self:IsMouseOver(2, -2, -2, 2) or self.owner:IsMouseOver(2, -2, -2, 2)) then
		self:Set(nil)
	end
end

function HoverMenu:Load()
	self:SetFrameStrata('DIALOG')
	self:SetToplevel(true)
	self:EnableMouse(true)
	self:SetClampedToScreen(true)
	self:SetWidth(40)
	self:SetHeight(18)

	--show menu
	local toggleVisibility = self:CreateToggleVisibilityButton()
	toggleVisibility:SetPoint('LEFT')

	--show/hide frame
	local showMenu = self:CreateToggleConfigMenuButton()
	showMenu:SetPoint('LEFT', toggleVisibility, 'RIGHT', 0, 0)

	self:SetScript('OnUpdate', self.OnUpdate)
	self.isLoaded = true
end


local function basicButton_SetTexture(self, texture)
	self:GetNormalTexture():SetTexture(texture)
	self:GetPushedTexture():SetTexture(texture)
end

function HoverMenu:CreateBasicButton(width, height, texture)
	local b = CreateFrame('Button', nil, self)

	local nt = b:CreateTexture()
	nt:SetAllPoints(b)
	b:SetNormalTexture(nt)

	local pt = b:CreateTexture()
	pt:SetTexCoord(-0.03, 1.03, -0.03, 1.03)
	pt:SetVertexColor(0.9, 0.9, 0.9)
	pt:SetAllPoints(b)
	b:SetPushedTexture(pt)

	b:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])

	b:SetWidth(width)
	b:SetHeight(height or width)

	b.SetTexture = basicButton_SetTexture
	b:SetTexture(texture)

	return b
end

function HoverMenu:CreateToggleVisibilityButton()
	local b = self:CreateBasicButton(20, 20, ICON_HIDE_FRAME)

	b.UpdateIcon = function(self)
		if self:GetParent().owner:FrameIsShown() then
			self:SetTexture(ICON_HIDE_FRAME)
		else
			self:SetTexture(ICON_SHOW_FRAME)
		end
	end

	b.UpdateTooltip = function(self)
		if self:GetParent().owner:FrameIsShown() then
			GameTooltip:SetText(L.ToggleVisibilityHelpHide)
		else
			GameTooltip:SetText(L.ToggleVisibilityHelpShow)
		end
	end

	b:SetScript('OnShow', function(self)
		self:UpdateIcon()
	end)

	b:SetScript('OnClick', function(self)
		self:GetParent().owner:ToggleFrame()
		self:UpdateIcon()
	end)
--[[
	b:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		self:UpdateTooltip()
	end)

	b:SetScript('OnLeave', function(self)
		GameTooltip:Hide()
	end)
--]]
	return b
end

function HoverMenu:CreateToggleConfigMenuButton()
	local b = self:CreateBasicButton(20, 20, ICON_SHOW_MENU)

	b:SetScript('OnClick', function(self)
		self:GetParent().owner:ShowMenu()
	end)
--[[
	b:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetText(L.ConfigureBarHelp)
	end)

	b:SetScript('OnLeave', function(self)
		GameTooltip:Hide()
	end)
--]]
	return b
end