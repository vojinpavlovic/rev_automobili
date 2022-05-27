ESX.RegisterServerCallback('rev_lock:isCarOwner', function(source, cb, plate)
    local vehicle = Rev.getCarByPlate(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if vehicle and xPlayer then
        if vehicle.owner == xPlayer.identifier then
            cb(true)
            return
        end

        if vehicle.owner == xPlayer.getJob().name then
            if Config.AuthJobLocks[xPlayer.getJob().name] then
                cb(true)
                return
            end
        end

        cb(false)
    end
end)