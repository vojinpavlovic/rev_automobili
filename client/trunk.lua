ESX = nil
local currentPlate = true
local lastVehicle, lastClass 

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

    while true do
        Citizen.Wait(500)
        if lastVehicle then
            if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(lastVehicle)) > 4.0 then
                TriggerEvent('sogolisica_inventar:forceClose')
                CloseTrunk(lastVehicle)
            end
        end
    end
end)

if not Config.TrunkKeymapping then
	RegisterNetEvent('rev_trunk:open')
	AddEventHandler('rev_trunk:open', function()
    	local vehFront = VehicleInFront()
    	local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
    	local closestCar = GetClosestVehicle(x, y, z, 4.0, 0, 71)

    	if vehFront > 0 and closestCar then
        	local model = GetDisplayNameFromVehicleModel(GetEntityModel(closestCar))
        	local locked = GetVehicleDoorLockStatus(closestCar)
        	local class = GetVehicleClass(vehFront)
        	local plate = GetVehicleNumberPlateText(vehFront)
        
        	if plate == nil then
            	return
        	end

        	if tonumber(string.sub(plate, 1, 2)) then
            	Notifcation('Ne mozete otvarati lokalna vozila!', 2500)
            	return
        	end

        	if locked == 1 or class == 15 or class == 16 or class == 14 then
            	lastVehicle = vehFront
            	OpenTrunkInventory(plate, vehFront, class)
        	else
            	Notifcation('Vozilo je zakljucano!', 2500)
        	end
    	else
        	Notifcation('Nema vozila u blizini')
    	end
	end)
else
	RegisterCommand('+trunk', function()
    	local vehFront = VehicleInFront()
    	local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
    	local closestCar = GetClosestVehicle(x, y, z, 4.0, 0, 71)

    	if vehFront > 0 and closestCar then
        	local model = GetDisplayNameFromVehicleModel(GetEntityModel(closestCar))
        	local locked = GetVehicleDoorLockStatus(closestCar)
        	local class = GetVehicleClass(vehFront)
        	local plate = GetVehicleNumberPlateText(vehFront)
        
        	if plate == nil then
            	return
        	end

        	if tonumber(string.sub(plate, 1, 2)) then
            	Notifcation('Ne mozete otvarati lokalna vozila!', 2500)
            	return
        	end

        	if locked == 1 or class == 15 or class == 16 or class == 14 then
            	lastVehicle = vehFront
            	OpenTrunkInventory(plate, vehFront, class)
        	else
            	Notifcation('Vozilo je zakljucano!', 2500)
        	end
    	else
        	Notifcation('Nema vozila u blizini')
    	end

	end, false)

	RegisterCommand('-trunk', function()end, false)
	RegisterKeyMapping('+trunk', 'Gepek', 'keyboard', 'l')
end

function OpenTrunkInventory(plate, veh, class)
    ESX.TriggerServerCallback('rev_trunk:getTrunk', function(data)
        if data then
            currentPlate = plate
            local items = sortInventory(data.inventory)
            local weightTable = {
                weight = data.weight,
                limit = Config.TrunkSize[class]
            }
            lastClass = class
            TriggerEvent('inventory:openInventory', 'show-trunk', false, items, weightTable)
            OpenTrunk(veh)
        else
            Notifcation('Auto ne postoji u bazi (Otvori tiket ako mislis da je greska)', 5000)
        end
    end, plate)
end

RegisterNetEvent('rev_trunk:refresh')
AddEventHandler('rev_trunk:refresh', function(data)
    local items = sortInventory(data.inventory)
    local weightTable = {
        weight = data.weight,
        limit = Config.TrunkSize[lastClass]
    }
    TriggerEvent('inventory:openInventory', 'show-trunk-refresh', false, items, weightTable)
end)

RegisterNetEvent('rev_trunk:dissarmPlayer', function()
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)
end)

RegisterNetEvent('rev_trunk:closeTrunk')
AddEventHandler('rev_trunk:closeTrunk', function()
    CloseTrunk(lastVehicle)
    TriggerServerEvent("j0le:MakniGaBuraz")
end)

function sortInventory(items)
    local data = {}
    for k, v in ipairs(items) do
        if v.name == 'black_money' then
            table.insert(data, v)
        end
    end

    for k, v in ipairs(items) do
        if v.name ~= 'black_money' then
            table.insert(data, v)
        end
    end

    return data
end

RegisterNetEvent('rev_trunk:addTrunk')
AddEventHandler('rev_trunk:addTrunk', function(data)
    TriggerServerEvent('rev_trunk:addTrunk', currentPlate, data, GetVehicleClass(lastVehicle))
end)

RegisterNetEvent('rev_trunk:removeTrunk')
AddEventHandler('rev_trunk:removeTrunk', function(data)
    TriggerServerEvent('rev_trunk:removeTrunk', currentPlate, data)
end)

-- Utilis

function getWeight(item)
    local weight = 0
    local itemWeight = 0
    if item ~= nil then
        itemWeight = Config.ItemWeight
        if arrayWeight[item] ~= nil then
            itemWeight = arrayWeight[item]
        end
    end
    return itemWeight
end

function OpenTrunk(veh) 
    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
    SetVehicleDoorOpen(veh, 5, false, false)
end

function CloseTrunk(veh)
    ClearPedTasksImmediately(PlayerPedId())
    SetVehicleDoorShut(veh, 5, false)
    lastVehicle = nil
end

function VehicleInFront()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local entityWorld = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, ped, 0)
    local a, b, c, d, result = GetRaycastResult(rayHandle)
    return result
end

function Notifcation(msg, ms) 
    if not msg then return end

    if not ms then
       TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-user', msg, 2000) 
    else
        TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-user', msg, ms) 
    end
end