local Jobs, entityForDelete = {}, {}
Jobs['usedPlates'] = {}
Jobs['possiblePlates'] = {}
Jobs['spawnedCars'] = {}

for i=0, 9999 do
    if i < 10 then
        Jobs.possiblePlates[i] = "000" .. i
    elseif i < 100 then
        Jobs.possiblePlates[i] = "00" .. i
    elseif i < 999 then
        Jobs.possiblePlates[i] = "0" .. i
    else
        Jobs.possiblePlates[i] = i
    end
end

ESX.RegisterServerCallback("rev_garaza:fetchPlayerVehicles", function(source, callback)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    MySQL.Async.fetchAll("SELECT plate, vehicle, garage, stored, description FROM owned_vehicles WHERE owner = @owner", {
        ["owner"] = xPlayer.identifier,
    }, function(result)
        local vehicles = {}
        
        for k, v in ipairs(result) do
            table.insert(vehicles, {
                ['plate'] = v.plate,
                ['props'] = v.vehicle,
                ['garage'] = v.garage,
                ['description'] = v.description, 
                ['stored'] = v.stored
            })
        end

        callback(vehicles)
    end)
end)

ESX.RegisterServerCallback("rev_garaza:validateVehicle", function(source, callback, props, garage)
    local vehicle = Rev.getCarByPlate(props.plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not vehicle then  
        callback(false)
        return
    end
    if not xPlayer then 
        callback(false)
        return 
    end
    if vehicle.owner ~= xPlayer.identifier then 
        callback(false)
        return 
    end

    if vehicle.temporary then
        callback(false)
    end

    vehicle.setGarage(props, garage, true)
    callback(true)
end)

ESX.RegisterServerCallback('rev_garage:checkStore', function(source, cb, plate)
    -- local vehicle = Rev.getCarByPlate(plate)
    -- local xPlayer = ESX.GetPlayerFromId(source)

    -- if not vehicle then return end
    -- if not xPlayer then return end

    -- if vehicle.stored == 0 then
    --     cb({ on = false, error = 'Vozilo je vani' })
    --     return
    -- end

    -- if vehicle.stored == 1 then
    --     cb({ on = true})
    --     return
    -- end

    -- cb(false)

    cb({on = true})
end)

RegisterNetEvent('rev_garaza:takeVehicleOut')
AddEventHandler('rev_garaza:takeVehicleOut', function(props, garage, impound, out)
    local vehicle = Rev.getCarByPlate(props.plate)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not vehicle then return end
    if not xPlayer then return end

    if not Config.Garages[garage] then
        return
    end

    if Config.Garages[garage].illegal then
        local job = xPlayer.getJob().name
        if not Jobs['spawnedCars'][job][vehicle.plate] then
            return
        end

        local _garage, _out = 'Ilegalni Pauk', false
    
        if not impound then
            _garage = garage
        end
    
        if not out then
            _out = true
        end

        vehicle.setGarage(props, _garage, _out)
    else
        if vehicle.owner ~= xPlayer.identifier then 
            DropPlayer(source, 'Nice try kiddo')
            return 
        end

        if garage == 'pauk' then
            xPlayer.removeMoney(Config.ImpoundPrice)
            TriggerClientEvent('revolucija_notifikacije:sendNotification', xPlayer.source, 'fas fa-user', 'Platili ste parking servis - ' .. Config.ImpoundPrice .. '$')
        end
    
        local _garage, _out = 'pauk', false
    
        if not impound then
            _garage = garage
        end
    
        if not out then
            _out = true
        end
    
        vehicle.setGarage(props, _garage, _out)
    end
end)

ESX.RegisterServerCallback("rev_garaza:canPayImpound", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if xPlayer.getMoney() < Config.ImpoundPrice then
        TriggerClientEvent('revolucija_notifikacije:sendNotification', xPlayer.source, 'fas fa-user', 'Nemate dovoljno novca da izvadite vozilo!', 3000)
        cb(false)
        return
    end

    cb(true)
end)

function GetNewJobPlate(prefix)
    if #prefix ~= 3 then
        return false
    end

    if not Jobs['usedPlates'][prefix] then
        Jobs['usedPlates'][prefix] = {
            lastIndex = 0,
            plate = prefix .. Jobs['possiblePlates'][0]
        }
        return Jobs['usedPlates'][prefix]
    end

    Jobs['usedPlates'][prefix].lastIndex = Jobs['usedPlates'][prefix].lastIndex + 1
    Jobs['usedPlates'][prefix].plate = prefix .. Jobs['possiblePlates'][Jobs['usedPlates'][prefix].lastIndex]

    return Jobs['usedPlates'][prefix]
end

function GetJobPrefix(job)
    if not Config.JobsPrefix[job] then 
        return nil 
    end

    return Config.JobsPrefix[job]
end

ESX.RegisterServerCallback('rev_garage:getJobPlate', function(source, cb, desc)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cb({ on = false, error = 'Igrac nije nadjen' })
        return nil
    end

    local prefix = GetJobPrefix(xPlayer.getJob().name)

    if not prefix then
        cb({ on = false, error = 'Greska - Vas prefix tablica ne postoji (kontaktiraj skriptera)' })
        return nil
    end

    local prop = GetNewJobPlate(prefix)
    Rev.OwnerCars[prop.plate] = CreateOwnedVehicle(prop.plate, xPlayer.getJob().name, nil, 'Ilegalni Pauk', 0, {}, true)
    
    if not Jobs['spawnedCars'][xPlayer.getJob().name] then
        Jobs['spawnedCars'][xPlayer.getJob().name] = {}
    end

    Jobs['spawnedCars'][xPlayer.getJob().name][prop.plate] = prop.plate
    cb({ on = true, plate = prop.plate})

end)

ESX.RegisterServerCallback('rev_garage:getJobCars', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cb(false)
        return
    end

    local job = xPlayer.getJob().name

    if not Jobs['spawnedCars'][job] then
        cb(false)
        return
    end

    local cars, data = Jobs['spawnedCars'][job], {}

    for k, v in pairs(cars) do
        local vehicle = Rev.getCarByPlate(v)
        local desc = Config.CarDesc['NOT FOUND']

        for i, j in pairs(Config.CarDesc) do
            if vehicle.vehicle then
                if GetHashKey(string.lower(i)) == vehicle.vehicle.model then
                    desc = j
                    break
                end
            end
        end

        table.insert(data, {
            ['plate'] = vehicle.plate,
            ['props'] = json.encode(vehicle.vehicle),
            ['garage'] = vehicle.garage,
            ['description'] = json.encode(desc), 
            ['stored'] = vehicle.stored
        })
    end

    cb(data)
end)

ESX.RegisterServerCallback('rev_garage:validateJobCar', function(source, cb, props, garage)
    local vehicle = Rev.getCarByPlate(props.plate)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not vehicle then return end
    if not xPlayer then return end

    local job = xPlayer.getJob().name

    if not Jobs['spawnedCars'][job] then
        cb(false)
        return
    end

    if not Jobs['spawnedCars'][job][vehicle.plate] then
        cb(false)
        return
    end

    if garage == 'pauk' then
        xPlayer.removeMoney(Config.ImpoundPrice)
        TriggerClientEvent('revolucija_notifikacije:sendNotification', xPlayer.source, 'fas fa-user', 'Platili ste parking servis - ' .. Config.ImpoundPrice .. '$', 3000)
    end

    vehicle.setGarage(props, garage, true)
    cb(true)
end)


-- RegisterCommand('dajkljuc', function(source, args)

	
-- 	myself = source
-- 	other = args[1]
-- 	if args[1] == nil or args[1] == 0 then
--         TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Nisi unio ID!")
--         return
--     else
-- 	    if(GetPlayerName(tonumber(args[1])))then
        
-- 	    else
--             TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Nepostojeci ID!")
-- 	    	return
-- 	    end
--     end
-- 	local plate1 = args[2]
-- 	local plate2 = args[3]
-- 	local plate3 = args[4]
-- 	local plate4 = args[5]
-- 	if plate1 ~= nil then plate01 = plate1 else plate01 = "" end
-- 	if plate2 ~= nil then plate02 = plate2 else plate02 = "" end
-- 	if plate3 ~= nil then plate03 = plate3 else plate03 = "" end
-- 	if plate4 ~= nil then plate04 = plate4 else plate04 = "" end
-- 	local plate = (plate01 .. " " .. plate02 .. " " .. plate03 .. " " .. plate04)	
-- 	mySteamID = GetPlayerIdentifiers(source)
-- 	mySteam = mySteamID[1]
-- 	myID = ESX.GetPlayerFromId(source).identifier
-- 	myName = ESX.GetPlayerFromId(source).name
-- 	targetSteamID = GetPlayerIdentifiers(args[1])
-- 	targetSteamName = ESX.GetPlayerFromId(args[1]).name
-- 	targetSteam = targetSteamID[1]
-- 	local xPlayer = ESX.GetPlayerFromId(source)
--     local xTarget = ESX.GetPlayerFromId(args[1])
-- 	 MySQL.Async.fetchAll(
--          'SELECT * FROM owned_vehicles WHERE plate = @plate',
--          {
--              ['@plate'] = plate
--          },
--          function(result)
--              if result[1] ~= nil then
--                 local voziloMrtvo = Rev.getCarByPlate(ESX.Math.Trim(plate))
--                 if voziloMrtvo then
--                    local playerName = ESX.GetPlayerFromIdentifier(result[1].owner).identifier
-- 			    	local pName = ESX.GetPlayerFromIdentifier(result[1].owner).name
-- 			    	CarOwner = playerName
-- 			    	if myID ~= CarOwner then	
-- 			    		data = {}
-- 			    			TriggerClientEvent('chatMessage', other, "^4Auto sa tablicama ^*^1" .. plate .. "^r^4je prebacen tebi od: ^*^2" .. myName)
-- 			    			MySQL.Sync.execute("UPDATE owned_vehicles SET owner=@owner WHERE plate=@plate", {['@owner'] = targetSteam, ['@plate'] = plate})
-- 			    			TriggerClientEvent('chatMessage', source, "^4Ti si  ^*^4prebacio^0^4 tvoje vozilo sa tablicom ^*^1" .. plate .. "\" ^r^4:^*^2".. targetSteamName)
--                             xPlayer.triggerEvent("rev_garaza:emptyVehicleTable")
--                             xTarget.triggerEvent("rev_garaza:emptyVehicleTable")
--                             voziloMrtvo.setOwner(xTarget.identifier)
-- 			    	else
-- 			    		TriggerClientEvent('chatMessage', source, "^*^1Kako ces sebi prepisat svega ti?!")
-- 			    	end
--                 else
--                     TriggerClientEvent('chatMessage', source, "^1^GRESKA: ^r^0Morate napisati /dajkljuc id igraca i tablice vozila")
-- 			    	TriggerClientEvent('chatMessage', source, "^1^GRESKA: ^r^0Tablice ovog vozila ne postoje ili nisu dobro napisane(VELIKIM SLOVIMA)!")
--                 end
-- 			    else
-- 			    	TriggerClientEvent('chatMessage', source, "^1^GRESKA: ^r^0Morate napisati /dajkljuc id igraca i tablice vozila")
-- 			    	TriggerClientEvent('chatMessage', source, "^1^GRESKA: ^r^0Tablice ovog vozila ne postoje ili nisu dobro napisane(VELIKIM SLOVIMA)!")
--                 end
--          end)
-- end)
