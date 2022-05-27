local vehicles = nil
local garageKeepers, garagePed, garageZones = {}, {}, {}
local VoziloVani = {}

CreateThread(function()
    while ESX == nil do
        Citizen.Wait(10)
    end

	local garageBlips = {}
	
	for k, v in pairs(Config.Garages) do
		if v.blip.show then
	  		garageBlips[k] = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
	  		SetBlipSprite(garageBlips[k], v.blip.sprite)
	  		SetBlipDisplay(garageBlips[k], v.blip.display)
	  		SetBlipScale(garageBlips[k], v.blip.scale)
	  		SetBlipColour(garageBlips[k], v.blip.color)
	  		SetBlipAsShortRange(garageBlips[k], true)
	  		BeginTextCommandSetBlipName("STRING")
	  		AddTextComponentString(v.blip.title)
	  		EndTextCommandSetBlipName(garageBlips[k])
		end
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
	
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
 	PlayerData.job = job
end)

RegisterNetEvent('rev_garaza:emptyVehicleTable')
AddEventHandler('rev_garaza:emptyVehicleTable', function()
    vehicles = nil
end)

PutInVehicle = function()
	garage = nil
    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
	local coords = GetEntityCoords(PlayerPedId())
	for k, v in pairs(Config.Garages) do
		if k ~= 'pauk' then
			if #(v.DeletePoint.pos - coords) < 40.0 then
				garage = k
				break
			end
		end
	end

	if not garage then
		ESX.ShowNotification('Nije naslo garazu')
		return
	end

	if Config.Garages[garage].job ~= nil then
		if Config.Garages[garage].job ~= PlayerData.job.name then
			ESX.ShowNotification('Nemate pristup ovoj garazi')
			return
		end
	end

	if Config.Garages[garage].illegal then
		local vehicle = GetVehiclePedIsUsing(PlayerPedId())
		
		if DoesEntityExist(vehicle) then
			local props = GetVehicleProperties(vehicle)
			ESX.TriggerServerCallback('rev_garage:validateJobCar', function(valid)
				if valid then
					TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
	
					while IsPedInVehicle(PlayerPedId(), vehicle, true) do
						Citizen.Wait(0)
					end
		
					Citizen.Wait(500)
		
					NetworkFadeOutEntity(vehicle, true, true)
		
					Citizen.Wait(100)
		
					ESX.Game.DeleteVehicle(vehicle)
	
					TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-car', 'Parkirali ste auto', 3000)
				else
					ESX.ShowNotification('Ovaj auto ne pripada vasoj organizaciji!')
				end
			end, props, garage)
		end
		
		return
	end

	if DoesEntityExist(vehicle) then
		local props = GetVehicleProperties(vehicle)

		ESX.TriggerServerCallback("rev_garaza:validateVehicle", function(valid)
			if valid then
				TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
	
				while IsPedInVehicle(PlayerPedId(), vehicle, true) do
					Citizen.Wait(0)
				end
	
				Citizen.Wait(500)
	
				NetworkFadeOutEntity(vehicle, true, true)
	
				Citizen.Wait(100)
	
				ESX.Game.DeleteVehicle(vehicle)

				TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-car', 'Parkirali ste auto', 3000)
				TriggerEvent('revolucija_notifikacije:sendFloatingText')

				if vehicles == nil then
					ESX.TriggerServerCallback("rev_garaza:fetchPlayerVehicles", function(data)
						vehicles = data
						for k, v in pairs(vehicles) do
							if v.plate == props.plate then
								vehicles[k].garage = garage
								vehicles[k].stored = 1
								vehicles[k].props = props
								break
							end
						end
					end)
				else
					for k, v in pairs(vehicles) do
						if v.plate == props.plate then
							vehicles[k].garage = garage
							vehicles[k].stored = 1
							vehicles[k].props = props
							break
						end
					end
				end
			else
				TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-car', 'Mozete parkirati samo vase vozilo', 3000)
			end
		end, props, garage)
	end
end

RegisterNUICallback('takeVehicleOut', function(data)
	local spawnPoints, foundSpawn = Config.Garages[data.garage].spawn, nil
	local model = data.props.model
	WaitForModel(model)

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(vector3(spawnPoints[i].x, spawnPoints[i].y, spawnPoints[i].z), 3.0) then
			foundSpawn = i
			break
		end
	end

	if not foundSpawn then
		TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-user', 'Recite ljudima da se pomere', 3000)
		return
	end

	if data.garage == 'pauk' then
		local canPay = nil
		ESX.TriggerServerCallback("rev_garaza:canPayImpound", function(hasEnoughMoney)
			canPay = hasEnoughMoney
		end)

		while canPay == nil do
			Wait(10)
		end

		if not canPay then
			return
		end
	end

	ESX.TriggerServerCallback('rev_garage:checkStore', function(retval)
		if not retval.on then
			ESX.ShowNotification(data.error)
			return
		end

		ESX.Game.SpawnVehicle(model, vector3(spawnPoints[foundSpawn].x, spawnPoints[foundSpawn].y, spawnPoints[foundSpawn].z), spawnPoints[foundSpawn].h, function(vehicle)
	
			SetVehicleProperties(vehicle, data.props)
	
			NetworkFadeInEntity(vehicle, true, true)
	
			SetModelAsNoLongerNeeded(model)
	
			TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
	
			SetEntityAsMissionEntity(vehicle, true, true)
			
			TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-user', 'Isparkirali ste auto', 3000)
	
	
			local impound, out = true, true
			if Config.JobAvoidImpound[PlayerData.job.name] or Config.JobAvoidStore[PlayerData.job.name] then
				for k, v in pairs(Config.VehicleShops) do
					if v.job == PlayerData.job.name then
						for k, v in pairs(v.cars) do
							if GetHashKey(v.model) == model then
								if Config.JobAvoidImpound[PlayerData.job.name] then
									impound = not impound
								end
	
								if Config.JobAvoidStore[PlayerData.job.name] then
									out = not out
								end
							end
						end
					end
				end
			end
	
			print(impound, out)
			TriggerServerEvent('rev_garaza:takeVehicleOut', data.props, data.garage, impound, out)
			if not Config.Garages[data.garage].illegal then
				for k, v in pairs(vehicles) do
					if v.plate == data.props.plate then
						if impound then
							vehicles[k].garage = 'pauk'
						else
							vehicles[k].garage = data.garage
						end
					
						if out then
							vehicles[k].stored = 0
						else
							vehicles[k].stored = 1
						end
						VoziloVani[k] = vehicle
						break
					end
				end
			end
		end)	
	end, data.props.plate)

end)

GetVehicleProperties = function(vehicle)
    if DoesEntityExist(vehicle) then
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)

        vehicleProps["tyres"] = {}
        vehicleProps["windows"] = {}
        vehicleProps["doors"] = {}

        for id = 1, 7 do
            local tyreId = IsVehicleTyreBurst(vehicle, id, false)
        
            if tyreId then
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = tyreId
        
                if tyreId == false then
                    tyreId = IsVehicleTyreBurst(vehicle, id, true)
                    vehicleProps["tyres"][ #vehicleProps["tyres"]] = tyreId
                end
            else
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = false
            end
        end

        for id = 1, 13 do
            local windowId = IsVehicleWindowIntact(vehicle, id)

            if windowId ~= nil then
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = windowId
            else
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = true
            end
        end
        
        for id = 0, 5 do
            local doorId = IsVehicleDoorDamaged(vehicle, id)
        
            if doorId then
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = doorId
            else
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = false
            end
        end

        vehicleProps["engineHealth"] = GetVehicleEngineHealth(vehicle)
        vehicleProps["bodyHealth"] = GetVehicleBodyHealth(vehicle)
        vehicleProps["fuelLevel"] = GetVehicleFuelLevel(vehicle)

        return vehicleProps
    end
end

SetVehicleProperties = function(vehicle, vehicleProps)
    ESX.Game.SetVehicleProperties(vehicle, vehicleProps)

    SetVehicleEngineHealth(vehicle, vehicleProps["engineHealth"] and vehicleProps["engineHealth"] + 0.0 or 1000.0)
    SetVehicleBodyHealth(vehicle, vehicleProps["bodyHealth"] and vehicleProps["bodyHealth"] + 0.0 or 1000.0)
    SetVehicleFuelLevel(vehicle, vehicleProps["fuelLevel"] and vehicleProps["fuelLevel"] + 0.0 or 1000.0)

    if vehicleProps["windows"] then
        for windowId = 1, 13, 1 do
            if vehicleProps["windows"][windowId] == false then
                SmashVehicleWindow(vehicle, windowId)
            end
        end
    end

    if vehicleProps["tyres"] then
        for tyreId = 1, 7, 1 do
            if vehicleProps["tyres"][tyreId] ~= false then
                SetVehicleTyreBurst(vehicle, tyreId, true, 1000)
            end
        end
    end

    if vehicleProps["doors"] then
        for doorId = 0, 5, 1 do
            if vehicleProps["doors"][doorId] ~= false then
                SetVehicleDoorBroken(vehicle, doorId - 1, true)
            end
        end
    end
end

WaitForModel = function(model)
    local DrawScreenText = function(text, red, green, blue, alpha)
        SetTextFont(4)
        SetTextScale(0.0, 0.5)
        SetTextColour(red, green, blue, alpha)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
    
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(0.5, 0.5)
    end

    if not IsModelValid(model) then
        return ESX.ShowNotification("Ovaj model ne postoji.")
    end

	if not HasModelLoaded(model) then
		RequestModel(model)
	end
	
	while not HasModelLoaded(model) do
		Citizen.Wait(0)
        DisableAllControlActions(0);
		DrawScreenText("SACEKAJTE! Ucitavnje modela...", 255, 255, 255, 150)
	end
end

Citizen.CreateThread(function()
	for k, v in pairs(Config.Garages) do
		if k ~= 'pauk' then
			RequestModel(`prop_parkingpay`) while not HasModelLoaded(`prop_parkingpay`) do Wait(100) end
			local object = CreateObject(`prop_parkingpay`, v.DeletePoint.pos, false, 1, 0)
			FreezeEntityPosition(object, true)
			SetEntityInvincible(object, true)

			exports['qtarget']:AddTargetModel({"prop_parkingpay"}, {
      			options = {
      				{
              			action = function()
							PutInVehicle()
						end,
              			icon = "fas fa-car",
              			label = "Vrati u garazu",
          			},
    			},
      			distance = 3.5
  			})
		end

		garageKeepers[k] = GetHashKey(v.position.ped)
		LoadModel(GetHashKey(v.position.ped))
		local coords = vector3(v.position.x, v.position.y, v.position.z)
		garagePed[k] = CreatePed(0, garageKeepers[k], coords - vector3(0.0, 0.0, 1.0), v.position.h, false, true)
		SetEntityInvincible(garagePed[k], true)
		SetBlockingOfNonTemporaryEvents(garagePed[k], true)
		SetPedDiesWhenInjured(garagePed[k], false)
		SetPedFleeAttributes(garagePed[k], 2)
		FreezeEntityPosition(garagePed[k], true)
		SetPedCanPlayAmbientAnims(garagePed[k], false)
		SetPedCanRagdollFromPlayerImpact(garagePed[k], false)
		garageZones[k] = BoxZone:Create(coords, 5.0, 5.0, {name = v.label, heading = v.position.h, debugPoly = false, minZ = coords - 1.0, maxZ = coords + 2.0})

		
        garageZones[k]:onPlayerInOut(function(isPointInside)
            if isPointInside then
				canAccessG = true
            else
				canAccessG = false
            end
        end)

		RegisterNetEvent('rev_autosalon:openGarage-' .. k)
		AddEventHandler('rev_autosalon:openGarage-' .. k, function()
			if Config.Garages[k].job ~= nil then
				if Config.Garages[k].job ~= PlayerData.job.name then
					ESX.ShowNotification('Nemate pristup ovoj garazi')
					return
				end
			end

			if Config.Garages[k].illegal then
				ESX.TriggerServerCallback('rev_garage:getJobCars', function(jobCars)
					SendNUIMessage({action = 'garage', vehicles = jobCars or {}, garage = k})
					SetNuiFocus(true, true)
					return
				end)
				return
			end

			TriggerScreenblurFadeIn()

			if vehicles == nil then
    			ESX.TriggerServerCallback("rev_garaza:fetchPlayerVehicles", function(data)
    			    vehicles = data
					SendNUIMessage({action = 'garage', vehicles = vehicles, garage = k})
					SetNuiFocus(true, true)
				end)
			else
				for k, v in pairs(vehicles) do
					if type(v.props) == 'table' then
						vehicles[k].props = json.encode(v.props)
					end
				end

				SendNUIMessage({action = 'garage', vehicles = vehicles, garage = k})
				SetNuiFocus(true, true)
			end
		end)

		exports['qtarget']:AddTargetModel({garageKeepers[k]}, {
			options = {
				{
					event = 'rev_autosalon:openGarage-' .. k,
					icon = 'fa-solid fa-car',
					label = 'Otvorite Garazu - ' .. k,
					num = 1,
					canInteract = function()
						return canAccessG
					end
				}
			},
			distance = 3.5
		})
	end
end)

Citizen.CreateThread(function()
	while true do
		if vehicles ~= nil then
			for Index, Value in pairs(vehicles) do
				if vehicles[Index].stored == 0 and vehicles[Index].garage == "pauk" then
					if not DoesEntityExist(VoziloVani[Index]) then
						vehicles[Index].stored = 1
						VoziloVani[Index] = nil
					end
				end
			end
		end
		Citizen.Wait(3000)		
	end
end)