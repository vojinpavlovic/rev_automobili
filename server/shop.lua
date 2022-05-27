local priceDict, stocks, stocksDict = {}, {}, {}
TestSession = {}
TestSession['car'] = false
local NaTestu = nil
local Vozilo = nil

startTest = function(source, model, key, currentCoords)
    TestSession[key] = true
    NaTestu = source
    local player = GetPlayerPed(source)
    local coords = vector3(-1658.96, -2767.54, 13.944)
    SetEntityCoords(player, vector3(-1654.31, -2770.84, 13.944), false, false, false, false)
    Wait(100)
    Vozilo = CreateVehicle(GetHashKey(model), coords, 325.0, true, true)
    SetVehicleNumberPlateText(Vozilo, "TEST" .. source)
    Wait(100)
    TaskWarpPedIntoVehicle(player, Vozilo, -1)

    CreateThread(function()
        sendFloatingText(source, 'Test vožnja traje <span>60</span> sekundi.', 3000)
        Wait(15000)
        sendFloatingText(source, 'Test vožnja traje <span>45</span> sekundi.', 3000)
        Wait(15000)
        sendFloatingText(source, 'Test vožnja traje još <span>30</span> sekundi.', 3000)
        Wait(15000)
        sendFloatingText(source, 'Test vožnja traje još <span>15</span> sekundi.', 3000)
        Wait(10000)
        sendFloatingText(source, 'Test vožnja traje još <span>5</span> sekundi.', 3000)
        Wait(5000)
        TestSession[key] = false
        NaTestu = nil
        DeleteEntity(Vozilo)
        SetEntityCoords(player, currentCoords, false, false, false, false)
        sendFloatingText(source, "Test Vožnja je <span>završena</span>!", 3000)
    end)
end

sendFloatingText = function(player, text, ms)
    CreateThread(function()
        TriggerClientEvent('panama_notifikacije:sendFloatingText', player, text)
        Wait(ms)
        TriggerClientEvent('panama_notifikacije:sendFloatingText', player)
    end)
end

RegisterServerEvent('revolucija_autosalon:checkTestSession')
AddEventHandler('revolucija_autosalon:checkTestSession', function(key, currentCoords, model)
    local _source = source
    if TestSession[key] then
        TriggerClientEvent('esx:showNotification', _source, 'Test vožnja je već u toku, pokušajte kasnije.')
    else
        startTest(_source, model, key, currentCoords)
    end
end)

for k, v in pairs(Config.VehicleShops) do
    for i, j in pairs(v.cars) do
        priceDict[j.model] = j.price
    end
end

RegisterServerEvent('sssssss:ssssss')
AddEventHandler('sssssss:ssssss', function()
    print('pokrenuo event >>', source)
end)

ESX.RegisterServerCallback('revolucija_autosalon:hasEnoughMoney', function (source, cb, model)
    if priceDict[model] == nil then return end
    local xPlayer = ESX.GetPlayerFromId(source) 

    if not stocksDict[model] then
        TriggerClientEvent('revolucija_notifikacije:sendNotification', xPlayer.source, 'fas fa-car', 'Auto nema na stanju!', 4000)
        cb(false)
        return
    end

    if stocksDict[model] <= 0 then
        TriggerClientEvent('revolucija_notifikacije:sendNotification', xPlayer.source, 'fas fa-car', 'Auto nema na stanju!', 4000)
        cb(false)
        return
    end

	if priceDict[model] and xPlayer.getMoney() >= priceDict[model] then
		xPlayer.removeMoney(priceDict[model])
		cb(true)
	else
		cb(false)
    end
end)

ESX.RegisterServerCallback('revolucija_autosalon:isPlateTaken', function (source, cb, plate)
    local doesExist = Rev.getCarByPlate(plate)
    if not doesExist then
        cb(false)
    else
        cb(true)
    end
end)

RegisterNetEvent('revolucija_autosalon:setVehicleOwner')
AddEventHandler('revolucija_autosalon:setVehicleOwner', function(data, props)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if not stocksDict[data.model] then
        TriggerClientEvent('revolucija_notifikacije:sendNotification', xPlayer.source, 'fas fa-car', 'Auto nema na stanju!', 4000)
        return
    end

    if stocksDict[data.model] <= 0 then
        TriggerClientEvent('revolucija_notifikacije:sendNotification', xPlayer.source, 'fas fa-car', 'Auto nema na stanju!', 4000)
        return
    end

    stocksDict[data.model] = stocksDict[data.model] - 1
        
    MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, description) VALUES (@owner, @plate, @vehicle, @description)',
    {
        ['@owner']   = xPlayer.identifier,
        ['@plate']   = props.plate,
        ['@vehicle'] = json.encode(props),
        ['@description'] = json.encode({
            ['img'] = data.image,
            ['name'] = data.name,
            ['brand'] = data.brand
        }),
    }, function (rowsChanged)
        MySQL.Async.execute('UPDATE autosalonstockovi SET stock = @stock WHERE model = @model', {
            ['@stock'] = stocksDict[data.model],
            ['@model'] = data.model
        })
        TriggerEvent("revolucija_core:discordLog", 'autosalon', 'Auto Salon Logovi', GetPlayerName(xPlayer.source).. ' je kupio vozilo s specifikacijama: \nNaziv: '..data.name..'\nBrend: '..data.brand..'\nSlika Vozila: '..data.image..'\nTablice: '..props.plate.."\nSpawn Kod: "..data.model.."\nHex ID igraca: "..xPlayer.identifier)
        Rev.OwnerCars[props.plate] = CreateOwnedVehicle(props.plate, xPlayer.identifier, props, 'Glavna', 0, {}, false)
    end)
    
end)

--Stockovi
function appendStock(type, station)
    stocks = MySQL.Sync.fetchAll("Select * FROM autosalonstockovi")

    for k, v in pairs(stocks) do
        stocksDict[v.model] = v.stock
    end

    addMissingStocks()
end

function addMissingStocks()
    for k, v in pairs(Config.VehicleShops) do
        local shop, cars = k, v.cars
        for k, v in pairs(cars) do
            if not stocksDict[v.model] then
                MySQL.Async.execute('INSERT INTO autosalonstockovi (model, stock) VALUE (@model, @stock)', {
                    ['@model'] = v.model,
                    ['@stock'] = 0
                })
            end
        end
    end
end

ESX.RegisterServerCallback('rev_shop:getStocks', function(source, cb)
    if source < 0 then
        return
    end

    if stocksDict then
        cb(stocksDict)
    else
        cb(false)
    end
end)

MySQL.ready(function()
    appendStock()
end)

AddEventHandler("playerDropped", function()
    if TestSession["car"] == true then
        if source == NaTestu then
            TestSession["car"] = false
            NaTestu = nil
            if DoesEntityExist(Vozilo) then
                DeleteEntity(Vozilo)
                Vozilo = nil
            end
        end
    end
end)