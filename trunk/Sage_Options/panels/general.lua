--[[
	general.lua
		Scripts for the General panel of the Sage options frame
--]]

function SOptionsGeneral_OnShow()
	this.onShow = 1
	
	local frameName = this:GetName()
	this.unit = 'all'

	getglobal(frameName .. "Lock"):SetChecked(Sage.IsLocked())
	getglobal(frameName .. "Sticky"):SetChecked(Sage.IsSticky())

	getglobal(frameName .. "Scale"):SetValue(100)
	getglobal(frameName .. "Alpha"):SetValue(100)
	getglobal(frameName .. "Width"):SetValue(80)

	this.onShow = nil
end