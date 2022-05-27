RegisterKeyMapping('+lockcar', 'Zakljucavanje/Otkljucavanje auta', 'keyboard', 'U')

RegisterCommand('+lockcar', function()
    local closeCar = ESX.Game.GetClosestVehicle()
    local plate = GetVehicleNumberPlateText(closeCar)
    local ped = PlayerPedId()

    if not plate and IsPedFalling(ped) and IsPedFalling(ped) and IsPedUsingAnyScenario(ped) and IsEntityDead(ped) and IsEntityPlayingAnim(igrac,'random@mugging3', 'handsup_standing_base', 3) then return end

    plate = ESX.Math.Trim(plate)
    ESX.TriggerServerCallback('rev_lock:isCarOwner', function(isOwner)
        if isOwner then
            ToggleVehLock(closeCar)
        end
    end, plate)
end)

RegisterCommand('-lockcar', function() end)

function ToggleVehLock(car)
    local ped = PlayerPedId()
    NetworkGetNetworkIdFromEntity(car)

    while not NetworkGetNetworkIdFromEntity(car) do
        Wait(10)
    end

    SetEntityAsMissionEntity(car, true, false)
    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(car), true)

    if IsPedInAnyVehicle(ped, false) then return end

    local prop = AnimateLock(ped)

    local locked = GetVehicleDoorLockStatus(car)

    if locked == 1 then
        LockCar(car, prop)
    elseif locked == 4 then
        UnlockCar(car, prop)
    end
end

function LockCar(car, prop) 
    SetVehicleDoorsLockedForAllPlayers(car, true)
    SetVehicleDoorsLocked(car, 4)
    SetVehicleLights(car, 2)
    Wait(200)
    SetVehicleLights(car, 0)
    Wait(200)
    SetVehicleLights(car, 2)
    Wait(400)
    SetVehicleLights(car, 0)	
    PlayVehicleDoorCloseSound(car, 1)
    SetVehicleEngineOn(car, 2, false)
    DeleteObject(prop)
    TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-car', 'Zakljucali ste auto', 2500)
end

function UnlockCar(car, prop)
    SetVehicleDoorsLockedForAllPlayers(car, false)
    SetVehicleDoorsLocked(car, 1)
    SetVehicleLights(car, 2)
    Wait(200)
    SetVehicleLights(car, 0)
    Wait(200)
    SetVehicleLights(car, 2)
    Wait(400)
    SetVehicleLights(car, 0)
    PlayVehicleDoorOpenSound(car, 0)
    DeleteObject(prop)
    TriggerEvent('revolucija_notifikacije:sendNotification', 'fas fa-car', 'Otkljucali ste auto', 2500)
end

function AnimateLock(ped)
    local dict = "anim@mp_player_intmenu@key_fob@"

    RequestAnimDict(dict)
    local x, y, z = table.unpack(GetEntityCoords(ped))
    local prop = CreateObject(GetHashKey('p_car_keys_01'), x, y, z + 0.2, true, true, true)
    local boneIndex = GetPedBoneIndex(ped, 0xDEAD)

    AttachEntityToEntity(prop, ped, boneIndex, 0.15, 0.01, 0.01, 0.0, 360.0, 0.0, true, true, false, true, 1, true)

    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(0)
    end

    TaskPlayAnim(ped, dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
    DeleteObject(prop)
    DeleteObject(prop)

    return prop
end
