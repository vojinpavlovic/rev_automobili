CreateOwnedVehicle = function(plate, owner, vehicle, garage, stored, trunk, temporary)
    local self = {}

    self.plate = plate
    self.owner = owner
    self.vehicle = vehicle
    self.garage = garage
    self.stored = stored
    self.trunk = trunk
    self.weight = 0
    self.temporary = temporary

    self.setGarage = function(props, garage, parking)
        self.garage = garage
        self.vehicle = props

        if parking then
            self.stored = 1
        else
            self.stored = 0
        end


        if not self.temporary then
            MySQL.Async.execute("UPDATE owned_vehicles SET garage = @garage, vehicle = @vehicle, stored = @stored WHERE plate = @plate", {
                ["@plate"] = self.plate,
                ["@garage"] = garage,
                ['@stored'] = self.stored,
                ["@vehicle"] = json.encode(props)
            }, function(rowsChanged) end)
        end
    end


    self.addTrunkItem = function(name, label, count, type) 
        if not name then return end
        if not label then return end
        if not count then return end
        if not type then return end

        local found = false

        for k, v in ipairs(self.trunk) do
            if v.name == name then
                found = true
                self.trunk[k].count = self.trunk[k].count + count
                break
            end
        end

        if not found then
            table.insert(self.trunk, {
                name = name,
                label = label,
                count = count,
                type = type 
            })
        end

        self.addWeight(name, count)
        self.saveTrunk()
    end
    self.setOwner = function(new)
        self.owner = new
    end

    self.removeTrunkItem = function(src, name, count) 
        if not name then return end
        if not count then return end
        for k, v in ipairs(self.trunk) do
            if v.name == name then
                local newCount = self.trunk[k].count - count
                if newCount == 0 then
                    self.removeWeight(name, count)
                    table.remove(self.trunk, k)
                    break
                elseif 0 > newCount then
                    return
                else
                    self.removeWeight(name, count)
                    self.trunk[k].count = newCount
                    local newCount = self.trunk[k].count - count
                    break
                end
            end
        end

        self.saveTrunk()
    end

    self.addWeaponTrunk = function(name, label, count, components)
        if not name or not count or not components then return end

        table.insert(self.trunk, {
            name = name,
            count = count, 
            label = label,
            components = components,
            type = 'item_weapon',
            uuid = self.uuid()
        })

        self.addWeight(name, count, true)
        self.saveTrunk()
    end

    self.removeWeaponTrunk = function(name, uuid)
        if not name or not uuid then return end

        for k, v in ipairs(self.trunk) do
            if v.type == 'item_weapon' then
                if v.uuid == uuid then
                    table.remove(self.trunk, k)
                    self.removeWeight(name, count, true)
                    self.saveTrunk()
                    return
                end
            end
        end
    end

    self.addWeight = function(name, count, weapon)
        if weapon then
            if Config.ItemWeight[name] then
                self.weight = self.weight + Config.ItemWeight[name]
            end

            self.weight = self.weight + 1000
        else
            if Config.ItemWeight[name] then
                self.weight = self.weight + (Config.ItemWeight[name] * count)
                return
            end
    
            self.weight = self.weight + (100 * count)
        end
    end

    self.removeWeight = function(name, count, weapon)
        if weapon then
            if Config.ItemWeight[name] then
                self.weight = self.weight - Config.ItemWeight[name]
            end

            self.weight = self.weight - 1000
        else
            if Config.ItemWeight[name] then
                self.weight = self.weight - (Config.ItemWeight[name] * count)
                return
            end
    
            self.weight = self.weight - (100 * count)
        end
    end

    for k, v in ipairs(trunk) do
        if not string.find(v.name, 'WEAPON_') then
            self.addWeight(v.name, v.count)
        else
            self.addWeight(v.name, v.count, true)
        end
    end

    self.saveTrunk = function()
        if self.temporary then
            return
        end
        MySQL.Async.execute("UPDATE owned_vehicles SET trunk = @trunk WHERE plate = @plate", {
            ["@plate"] = self.plate,
            ['@trunk'] = json.encode(self.trunk)
        }, function(rowsChanged) end)
    end

    self.uuid = function()
        local random = math.random
        local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
        return string.gsub(template, '[xy]', function (c)
            local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
            return string.format('%x', v)
        end)
    end

    return self
end