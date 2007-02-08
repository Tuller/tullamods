--[[
	BProfile
		Functions for saving and loading different settnings for Bongos
--]]

BProfile = {}

local saved = {}


--[[ Usable Functions ]]--

function BProfile.Load(name)
	local profile = BongosProfiles[name]
	if profile then
		--delete all bars
		BBar.ForAll(BBar.Delete)

		--load new settings
		for varName,value in pairs(profile) do
			if type(value) == 'table' then
				TLib.SetField(varName, TLib.TCopy(value))
			else
				TLib.SetField(varName, value)
			end
		end
		BVent:Call('BONGOS_LOADED')
		BVent:Call('BONGOS_STARTUP')
		
		BBar.ForAll(BBar.Reanchor)
	end
end

function BProfile.Save(name)
	local profile = {}

	for _,varName in pairs(saved) do
		local var = getglobal(varName)
		if var and type(var) == 'table' then
			profile[varName] = TLib.TCopy(var)
		else
			profile[varName] = var
		end
	end

	BongosProfiles[name] = profile
end

function BProfile.Delete(name)
	BongosProfiles[name] = nil
end

function BProfile.Reset()
	--delete all bars
	BBar.ForAll(BBar.Delete)

	--delete saved settings
	for _,varName in pairs(saved) do
		TLib.SetField(varName, nil)
	end
	
	BVent:Call('BONGOS_LOADED')
	BVent:Call('BONGOS_STARTUP')
end

--registers a variable to save
function BProfile.RegisterForSave(varName)
	for _,name in pairs(saved) do
		if name == varName then
			return
		end
	end

	table.insert(saved, varName)
end

--[[ Events ]]--

BVent:AddAction('PLAYER_LOGIN', function() 
	BVent:Call('BONGOS_LOADED')
	BVent:Call('BONGOS_STARTUP')
end)

BVent:AddAction('BONGOS_LOADED', function() 
	if not BongosProfiles then 
		BongosProfiles = {}
	end
end)