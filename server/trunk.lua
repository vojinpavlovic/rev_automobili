local busyTrunks = {}
componentsTable = {
    ['suppressor'] = true,
    ['luxary_finish'] = true,
    ['flashlight'] = true,
    ['clip_extended'] = true,
    ['scope'] = true
}

ESX.RegisterServerCallback('rev_trunk:getTrunk', function(source, cb, plate)
    local vehicle = Rev.getCarByPlate(ESX.Math.Trim(plate))
    if vehicle then
        if busyTrunks[vehicle.plate] ~= nil then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Netko je vec u gepeku', 2500)
            return
        end

        busyTrunks[vehicle.plate] = source
        cb({inventory = vehicle.trunk, weight = vehicle.weight})
    else
        cb(false)
    end
end)

RegisterServerEvent('rev_trunk:addTrunk')
AddEventHandler('rev_trunk:addTrunk', function(plate, data, class)
    if GetPlayerPing(source) >= 200 then
        TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Vasa konekcija je nestabilna pokusajte ponovo', 2000)
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicle = Rev.getCarByPlate(ESX.Math.Trim(plate))
    if not xPlayer then return end
    if not vehicle then return end

    if data.item.type == 'item_standard' then

        if data.number <= 0 then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Kolicina mora biti pozitivna', 2000)
            return
        end

        local item = xPlayer.getInventoryItem(data.item.name)
        if item.count < data.number then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Nedovoljna kolicina', 2000)
            return
        end


        if calculateNewWeight(data.item.name, vehicle.weight, data.number) > Config.TrunkSize[class] then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Nemate vise mesta u gepeku', 2000)
            return
        end
        if data.item.name ~= "dozvolaoruzije" then
            xPlayer.removeInventoryItem(data.item.name, data.number)
            vehicle.addTrunkItem(data.item.name, data.item.label, data.number, data.item.type)
            TriggerEvent('revolucija_core:discordLog', 'gepek', 'Gepek', '**Igrač**: ' .. GetPlayerName(source) .. '\n**Steam Hex**: '.. xPlayer.identifier ..'\n**ID**: ' .. source .. '\n**Tablice**: ' .. plate .. '\n**Akcija**: Stavljanje\n**Item**: ' .. data.item.label ..'\n**Količina**: ' .. data.number)
            TriggerClientEvent('rev_trunk:refresh', xPlayer.source, {inventory = vehicle.trunk, weight = vehicle.weight})
        else
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Ne mozes ovo staviti u gepek!', 2000)
        end
    elseif data.item.type == 'item_account' then
        local money = xPlayer.getAccount('black_money').money

        if data.number <= 0 then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Kolicina mora biti pozitivna', 2000)
            return
        end

        if calculateNewWeight(data.item.name, vehicle.weight, data.number) > Config.TrunkSize[class] then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Nemate vise mesta u gepeku', 2000)
            return
        end

        if money < data.number then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Nedovoljna kolicina', 2000)
            return
        end

        xPlayer.removeAccountMoney('black_money', data.number)
        vehicle.addTrunkItem(data.item.name, 'Prljave pare', data.number, data.item.type)
        TriggerEvent('revolucija_core:discordLog', 'gepek', 'Gepek', '**Igrač**: ' .. GetPlayerName(source) .. '\n**Steam Hex**: '.. xPlayer.identifier ..'\n**ID**: ' .. source .. '\n**Tablice**: ' .. plate .. '\n**Akcija**: Stavljanje\n**Item**: Prljave pare\n**Količina**: ' .. data.number)
        TriggerClientEvent('rev_trunk:refresh', xPlayer.source, {inventory = vehicle.trunk, weight = vehicle.weight})

    elseif data.item.type == 'item_weapon' then
        local name, components, ammo = data.item.name, {}, data.number
        
        if not xPlayer.hasWeapon(name) then return end

        if calculateNewWeightWeapon(name, vehicle.weight) > Config.TrunkSize[class] then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Nemate vise mesta u gepeku', 2000)
            return
        end

        for k, v in pairs(componentsTable) do
            local hasComponent = xPlayer.hasWeaponComponent(name, k)
            if hasComponent then
                table.insert(components, k)
            end
        end
        
        xPlayer.removeWeapon(name)
        vehicle.addWeaponTrunk(name, data.item.label, ammo, components)
        TriggerEvent('revolucija_core:discordLog', 'gepek', 'Gepek', '**Igrač**: ' .. GetPlayerName(source) .. '\n**Steam Hex**: '.. xPlayer.identifier ..'\n**ID**: ' .. source .. '\n**Tablice**: ' .. plate .. '\n**Akcija**: Stavljanje Oruzija\n**Item**: '..data.item.label..'\n**Količina Municije**: ' .. ammo)
        TriggerClientEvent('rev_trunk:refresh', xPlayer.source, {inventory = vehicle.trunk, weight = vehicle.weight})
        TriggerClientEvent('rev_trunk:dissarmPlayer', xPlayer.source)
    end
end)

RegisterServerEvent('rev_trunk:removeTrunk')
AddEventHandler('rev_trunk:removeTrunk', function(plate, data)
    if GetPlayerPing(source) >= 200 then
        TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Vasa konekcija je nestabilna pokusajte ponovo', 2000)
        return
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicle = Rev.getCarByPlate(ESX.Math.Trim(plate))
    if not xPlayer then return end
    if not vehicle then return end

    if data.item.type == 'item_standard' then
        local item = xPlayer.getInventoryItem(data.item.name)

        if data.number <= 0 then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Kolicina mora biti pozitivna', 2000)
            return
        end

        if not item then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Item ne postoji u bazu (Prijavite ako mislite da je greska)', 2000)
            return
        end

        if not xPlayer.canCarryItem(data.item.name, data.number) then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Nemate mesta u inventaru', 2000)
            return
        end
        if data.item.name ~= "dozvolaoruzije" then
            xPlayer.addInventoryItem(data.item.name, data.number)
            vehicle.removeTrunkItem(xPlayer.source, data.item.name, data.number)
            TriggerEvent('revolucija_core:discordLog', 'gepek', 'Gepek', '**Igrač**: ' .. GetPlayerName(source) .. '\n**Steam Hex**: '.. xPlayer.identifier ..'\n**ID**: ' .. source .. '\n**Tablice**: ' .. plate .. '\n**Akcija**: Uzimanje\n**Item**: ' ..ESX.GetItemLabel(data.item.name)..'\n**Količina**: ' .. data.number)
            TriggerClientEvent('rev_trunk:refresh', xPlayer.source, {inventory = vehicle.trunk, weight = vehicle.weight})
        else
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Ne mozes ovo izvaditi iz gepeka!', 2000)
        end
    elseif data.item.type == 'item_account' then

        if data.number <= 0 then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Kolicina mora biti pozitivna', 2000)
            return
        end

        xPlayer.addAccountMoney('black_money', data.number)
        vehicle.removeTrunkItem(xPlayer.source, data.item.name, data.number)
        TriggerEvent('revolucija_core:discordLog', 'gepek', 'Gepek', '**Igrač**: ' .. GetPlayerName(source) .. '\n**Steam Hex**: '.. xPlayer.identifier ..'\n**ID**: ' .. source .. '\n**Tablice**: ' .. plate .. '\n**Akcija**: Uzimanje\n**Item**: Prljav Novac\n**Količina**: ' .. data.number)
        TriggerClientEvent('rev_trunk:refresh', xPlayer.source, {inventory = vehicle.trunk, weight = vehicle.weight})
    elseif data.item.type == 'item_weapon' then
        local name, components, ammo, uuid = data.item.name, data.item.components, data.item.count, data.item.uuid
        
        if xPlayer.hasWeapon(name) then
            TriggerClientEvent('revolucija_notifikacije:sendNotification', source, 'fas fa-user', 'Vec imate to oruzije kod sebe!', 2000)
            return
        end

        xPlayer.addWeapon(name, ammo)

        for i = 1, #components do
            xPlayer.addWeaponComponent(name, components[i])
        end

        vehicle.removeWeaponTrunk(name, uuid)
        TriggerEvent('revolucija_core:discordLog', 'gepek', 'Gepek', '**Igrač**: ' .. GetPlayerName(source) .. '\n**Steam Hex**: '.. xPlayer.identifier ..'\n**ID**: ' .. source .. '\n**Tablice**: ' .. plate .. '\n**Akcija**: Uzimanje\n**Item**: '..name..'\n**Količina Municije**: ' .. ammo)
        TriggerClientEvent('rev_trunk:refresh', xPlayer.source, {inventory = vehicle.trunk, weight = vehicle.weight})
        TriggerClientEvent('rev_trunk:dissarmPlayer', xPlayer.source)
    end
end)

function removeSourceFromTrunk(src)
    for k, v in pairs(busyTrunks) do
        if src == v then
            busyTrunks[k] = nil
            break
        end
    end
end

function calculateNewWeightWeapon(name, weight)
    if Config.ItemWeight[name] then
        weight = weight + Config.ItemWeight[name]
        return weight
    end

    local newWeight = weight + 1000
    return newWeight
end

function calculateNewWeight(name, weight, count)
    if not weight then return end
    if not name then return end

    if Config.ItemWeight[name] then
        weight = weight + (Config.ItemWeight[name] * count)
        return weight
    end

    local newWeight = weight + (100 * count)

    return newWeight
end

AddEventHandler('playerDropped', function()
    removeSourceFromTrunk(source)
end)

RegisterNetEvent("j0le:MakniGaBuraz")
AddEventHandler("j0le:MakniGaBuraz", function()
    if not source then return end
    removeSourceFromTrunk(source)
end)