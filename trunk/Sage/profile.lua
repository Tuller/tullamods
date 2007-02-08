--[[
	SProfile
		Functions for saving and loading Sage settings
--]]

SProfile = {}

local saved = {}

function SProfile.Load(name)
	SageFrame.ForAll('Delete')

	for varName,value in pairs(SageProfiles[name]) do
		if type(value) == 'table' then
			TLib.SetField(varName, TLib.TCopy(value))
		else
			TLib.SetField(varName, value)
		end
	end
	
	BVent:Call('SAGE_STARTUP')
	SageFrame.ForAll('Reanchor')
	SageStatusBar.UpdateAllTextures()
end

function SProfile.Save(name)
	local profile = {}

	for _,varName in pairs(saved) do
		local var = getglobal(varName)
		if var and type(var) == 'table' then
			profile[varName] = TLib.TCopy(var)
		else
			profile[varName] = var
		end
	end
	
	SageProfiles[name] = profile
end

function SProfile.Delete(name)
	SageProfiles[name] = nil
end

function SProfile.RegisterForSave(varName)
	for _,name in pairs(saved) do
		if name == varName then
			return
		end
	end
	table.insert(saved, varName)
end

function SProfile.Reset()
	SageFrame.ForAll('Delete')

	for _,var in pairs(saved) do
		TLib.SetField(var, nil)
	end

	BVent:Call('SAGE_STARTUP')
end


--[[ Events ]]--

BVent:AddAction('PLAYER_LOGIN', function()
	if not SageProfiles then
		SageProfiles = {}
	end
	BVent:Call('SAGE_STARTUP') 
end)