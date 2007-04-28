--[[
	BongosTest.lua
		Driver for bongos bars
--]]

BongosTest = Bongos:NewModule("Bongos-Test")

function BongosTest:Initialize()
--	self:Print('Initialize')
end

function BongosTest:Enable()
--	self:Print('Enable')
end

function BongosTest:Load()
	for i = 1, 10 do
		local bar = BBar:Create(i)

		local obj = CreateFrame('Frame')
		obj.tex = obj:CreateTexture()
		obj.tex:SetTexture(1, 1, 1, 0.5)
		obj.tex:SetAllPoints(obj)

		obj:SetWidth(32); obj:SetHeight(32)
		obj:SetPoint('TOPLEFT', bar)

		bar:Attach(obj)
	end
end

function BongosTest:Unload()
	for i = 1, 10 do	
		BBar:Get(i):Destroy()
	end
end