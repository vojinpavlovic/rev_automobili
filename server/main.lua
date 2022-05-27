ESX = nil
Rev = {}
Rev.OwnerCars = {}
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
--TriggerEvent('rev_framework:frameworkObject', function(obj) ESX = obj end)

local loadOwnedCars = function(cars)
    local counter = 0
    local storedCounter = 0
    for k, v in pairs(cars) do
        if not v.stored then
            MySQL.Async.execute("UPDATE owned_vehicles SET stored = @stored WHERE plate = @plate", {
                ["@plate"] = v.plate,
                ['@stored'] = 1
            }, function(rowsChanged) 
                storedCounter = storedCounter + 1
            end)
        end
        Rev.OwnerCars[v.plate] = CreateOwnedVehicle(v.plate, v.owner, v.vehicle, v.garage, 1, json.decode(v.trunk), false)
        counter = counter + 1
    end

end

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles', {}, function(result)
        loadOwnedCars(result)
    end)
end)

-- Functions 

Rev.getCarByPlate = function(plate)
    if Rev.OwnerCars[plate] then
        return Rev.OwnerCars[plate]
    end

    return nil
end

RegisterNetEvent("j0le_prepisivanje/rev_automobili/server/SyncajAuto")
AddEventHandler("j0le_prepisivanje/rev_automobili/server/SyncajAuto", function(Izvor, Tablice)
    if not Izvor then return end
    if not Tablice then return end

    xPlayer = ESX.GetPlayerFromId(Izvor)
    Vozilica = Rev.getCarByPlate(Tablice)

    if not xPlayer then return end
    if not Vozilica then return end

    Vozilica.setOwner(xPlayer.identifier)
end)