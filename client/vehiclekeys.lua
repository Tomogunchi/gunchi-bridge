-- the server file defines these too, that's the point of a bridge
---@diagnostic disable: duplicate-set-field

local vkeys = Bridge.DetectVehicleKeys()
Bridge.VehicleKeysName = vkeys

Bridge.VehicleKeys = {}

local function plateOf(vehicle, plate)
    return plate or GetVehicleNumberPlateText(vehicle)
end

-- some key scripts only have server exports, for those we bounce the request
-- through the bridge server side
local function relayGive(vehicle)
    TriggerServerEvent('gunchi-bridge:server:giveVehicleKeys', NetworkGetNetworkIdFromEntity(vehicle))
end
local function relayRemove(vehicle)
    TriggerServerEvent('gunchi-bridge:server:removeVehicleKeys', NetworkGetNetworkIdFromEntity(vehicle))
end

local give = {}
local remove = {}

give['qbx_vehiclekeys'] = function(vehicle, plate) relayGive(vehicle) end
remove['qbx_vehiclekeys'] = function(vehicle, plate) relayRemove(vehicle) end

give['nd'] = function(vehicle, plate) relayGive(vehicle) end
remove['nd'] = function(vehicle, plate) relayRemove(vehicle) end

give['qb-vehiclekeys'] = function(vehicle, plate)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plateOf(vehicle, plate))
end
remove['qb-vehiclekeys'] = function(vehicle, plate)
    TriggerEvent('qb-vehiclekeys:client:RemoveKeys', plateOf(vehicle, plate))
end

give['wasabi_carlock'] = function(vehicle, plate)
    exports.wasabi_carlock:GiveKey(plateOf(vehicle, plate))
end
remove['wasabi_carlock'] = function(vehicle, plate)
    exports.wasabi_carlock:RemoveKey(plateOf(vehicle, plate))
end

-- resource folder case differs between downloads
local function mrnewb()
    return exports[Bridge.ResourceStarted('MrNewbVehicleKeys') and 'MrNewbVehicleKeys' or 'mrnewbvehiclekeys']
end
give['MrNewbVehicleKeys'] = function(vehicle, plate)
    mrnewb():GiveKeysByPlate(plateOf(vehicle, plate))
end
remove['MrNewbVehicleKeys'] = function(vehicle, plate)
    mrnewb():RemoveKeysByPlate(plateOf(vehicle, plate))
end
give['mrnewbvehiclekeys'] = give['MrNewbVehicleKeys']
remove['mrnewbvehiclekeys'] = remove['MrNewbVehicleKeys']

give['Renewed-Vehiclekeys'] = function(vehicle, plate)
    exports['Renewed-Vehiclekeys']:addKey(plateOf(vehicle, plate))
end
remove['Renewed-Vehiclekeys'] = function(vehicle, plate)
    exports['Renewed-Vehiclekeys']:removeKey(plateOf(vehicle, plate))
end

give['vehicles_keys'] = function(vehicle, plate)
    TriggerServerEvent('vehicles_keys:selfGiveVehicleKeys', plateOf(vehicle, plate))
end
remove['vehicles_keys'] = function(vehicle, plate)
    TriggerServerEvent('vehicles_keys:selfRemoveKeys', plateOf(vehicle, plate))
end

give['cd_garage'] = function(vehicle, plate)
    TriggerEvent('cd_garage:AddKeys', plateOf(vehicle, plate))
end

give['okokGarage'] = function(vehicle, plate)
    TriggerServerEvent('okokGarage:GiveKeys', plateOf(vehicle, plate))
end
remove['okokGarage'] = function(vehicle, plate)
    TriggerServerEvent('okokGarage:RemoveKeys', plateOf(vehicle, plate), cache.serverId)
end

give['mVehicle'] = function(vehicle, plate)
    exports.mVehicle:AddTemporalVehicleClient(vehicle)
end

---@param vehicle number
---@param plate? string
function Bridge.VehicleKeys.Give(vehicle, plate)
    local fn = give[vkeys]
    if not fn then
        if Config.Debug then
            print(('[gunchi-bridge] no vehicle key system (%s); Give skipped'):format(vkeys))
        end
        return false
    end
    return pcall(fn, vehicle, plate)
end

-- not every key script can take keys back (cd_garage, mVehicle), those just
-- return false
---@param vehicle number
---@param plate? string
function Bridge.VehicleKeys.Remove(vehicle, plate)
    local fn = remove[vkeys]
    if not fn then return false end
    return pcall(fn, vehicle, plate)
end