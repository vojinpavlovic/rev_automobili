ESX = nil
local shopKeepers, shopPed, shopZones, stocksDict = {}, {}, {}, {}
local currentShop = nil
PlayerData = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	local shopBlip
	shopBlip = AddBlipForCoord(Config.VehShopBlip.pos)
	SetBlipSprite(shopBlip, Config.VehShopBlip.sprite)
	SetBlipDisplay(shopBlip, Config.VehShopBlip.display)
	SetBlipScale(shopBlip, Config.VehShopBlip.scale)
	SetBlipColour(shopBlip, Config.VehShopBlip.color)
	SetBlipAsShortRange(shopBlip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(Config.VehShopBlip.title)
	EndTextCommandSetBlipName(shopBlip)

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
 	PlayerData.job = job
end)

RegisterNUICallback('close', function()
	TriggerScreenblurFadeOut()
	SetNuiFocus(false, false)
end)

RegisterNUICallback('buyvehicle', function(data)
	-- TriggerServerEvent('sssssss:ssssss')
	if IsModelInCdimage(GetHashKey(data.model)) then
		local onStock = false
		for k, v in pairs(Config.VehicleShops[currentShop].cars) do
			if data.model == v.model then
				if v.stock > 0 then
					onStock = true
				end
			end
		end

		if not onStock then
			ESX.ShowNotification('Auto nema na stanju')
			return
		end


		ESX.TriggerServerCallback('revolucija_autosalon:hasEnoughMoney', function(hasEnoughMoney)
			if not hasEnoughMoney then
				TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-user', 'Nemate dovoljno para da kupite ovaj automobil.', 4000) 
				return 
			end

			RequestModel(GetHashKey(data.model))
			while not HasModelLoaded(GetHashKey(data.model)) do
				ESX.ShowHelpNotification("~y~Ucitavanje ~s~Asseta Vozila...")
				Citizen.Wait(37)
			end

			--DoScreenFadeOut(1000)
			ESX.Game.SpawnVehicle(data.model, Config.VehicleShops[currentShop].spawn.coords, Config.VehicleShops[currentShop].spawn.heading, function(vehicle)
				local newPlate = GeneratePlate()
				local props = ESX.Game.GetVehicleProperties(vehicle)
				props.plate = newPlate
				TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-car', 'Auto sa tablicama pripada vama ' .. props.plate, 4000)
				SetVehicleNumberPlateText(vehicle, newPlate)
				TriggerServerEvent('revolucija_autosalon:setVehicleOwner', data, props)
				TriggerEvent('rev_garaza:emptyVehicleTable')
				TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
				--DoScreenFadeIn(3000)
			end)
		end, data.model)
	else
		ESX.ShowNotification("Vozilo ne postoji u Server Assetima! Kontaktiraj Skriptera.")
	end
end)

RegisterCommand('fadeoff', function()
	DoScreenFadeIn(3000)
end)

LoadModel = function(model)
	RequestModel(model)

	while not HasModelLoaded(model) do
		Citizen.Wait(37)
	end
end

Citizen.CreateThread(function()
	for k, v in pairs(Config.VehicleShops) do
		shopKeepers[k] = GetHashKey(v.entering.ped)
		LoadModel(GetHashKey(v.entering.ped))
		local coords = vector3(v.entering.x, v.entering.y, v.entering.z)
		shopPed[k] = CreatePed(0, shopKeepers[k], coords - vector3(0.0, 0.0, 1.0), v.entering.h, false, true)
		SetEntityInvincible(shopPed[k], true)
		SetBlockingOfNonTemporaryEvents(shopPed[k], true)
		SetPedDiesWhenInjured(shopPed[k], false)
		SetPedFleeAttributes(shopPed[k], 2)
		FreezeEntityPosition(shopPed[k], true)
		SetPedCanPlayAmbientAnims(shopPed[k], false)
		SetPedCanRagdollFromPlayerImpact(shopPed[k], false)
		shopZones[k] = BoxZone:Create(coords, 5.0, 5.0, {name = v.label, heading = v.entering.h, debugPoly = false, minZ = coords - 1.0, maxZ = coords + 2.0})

		
        shopZones[k]:onPlayerInOut(function(isPointInside)
            if isPointInside then
				canAccessI = true
            else
				canAccessI = false
            end
        end)

		RegisterNetEvent('rev_autosalon:openShop-' .. k)
		AddEventHandler('rev_autosalon:openShop-' .. k, function()
			if Config.VehicleShops[k].job ~= nil then
				if Config.VehicleShops[k].job ~= PlayerData.job.name then
					ESX.ShowNotification('Nemate pristup ovom salonu')
					return
				end
			end

			TriggerScreenblurFadeIn()
			currentShop = k
			ESX.TriggerServerCallback('rev_shop:getStocks', function(stocks)
				for k, v in pairs(stocks) do
					local model, stock = k, v
					for k, v in pairs(Config.VehicleShops) do
						local shop, cars = k, v.cars
						for k, v in pairs(cars) do
							if model == v.model then	
								Config.VehicleShops[shop].cars[k].stock = stock
							end
						end
					end
				end

				local data = {}
				
				for k, v in pairs(Config.VehicleShops[k].cars) do
					if v.grade then
						if v.grade[PlayerData.job.grade_name] then
							table.insert(data, v)
						end
					else
						table.insert(data, v)
					end
				end
				SendNUIMessage({action = 'shop', shopList = data})
				SetNuiFocus(true, true)
			end)
		end)

		exports['qtarget']:AddTargetModel({shopKeepers[k]}, {
			options = {
				{
					event = 'rev_autosalon:openShop-' .. k,
					icon = 'fa-solid fa-car',
					label = v.label,
					num = 1,
					canInteract = function()
						return canAccessI
					end
				}
			},
			distance = 3.5
		})
	end
end)

----------------------UTILIS-------------------------------
local NumberCharset, Charset = {}, {}
for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function GeneratePlate()
	local generatedPlate
	local doBreak = false
	while true do
		Citizen.Wait(2)
		math.randomseed(GetGameTimer())
		generatedPlate = string.upper(GetRandomLetter(Config.PlateLetters) .. GetRandomNumber(Config.PlateNumbers))	
		ESX.TriggerServerCallback('revolucija_autosalon:isPlateTaken', function (isPlateTaken)
			if not isPlateTaken then
				doBreak = true
			end
		end, generatedPlate)

		if doBreak then
			break
		end
	end

	return generatedPlate
end


function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

function GetRandomLetter(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

RegisterNUICallback('testvehicle', function(data)
	if IsModelInCdimage(GetHashKey(data.model)) then
		RequestModel(GetHashKey(data.model))
		while not HasModelLoaded(GetHashKey(data.model)) do
			ESX.ShowHelpNotification("~y~Ucitavanje ~s~Asseta Vozila...")
			Citizen.Wait(37)
		end
		TriggerServerEvent('revolucija_autosalon:checkTestSession', 'car', GetEntityCoords(PlayerPedId()), data.model)
	else
		ESX.ShowNotification("Vozilo ne postoji u Server Assetima! Kontaktiraj Skriptera.")
	end
end)