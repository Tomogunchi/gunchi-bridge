-- the client file defines these too, that's the point of a bridge
---@diagnostic disable: duplicate-set-field

local vkeys = Bridge.DetectVehicleKeys()
Bridge.VehicleKeysName = vkeys

Bridge.VehicleKeys = {}

local function plateOf(vehicle, plate)
    return plate or GetVehicleNumberPlateText(vehicle)
end

local give = {}
local remove = {}

give['qbx_vehiclekeys'] = function(src, vehicle, plate)
    exports.qbx_vehiclekeys:GiveKeys(src, vehicle)
end
remove['qbx_vehiclekeys'] = function(src, vehicle, plate)
    exports.qbx_vehiclekeys:RemoveKeys(src, vehicle)
end

give['qb-vehiclekeys'] = function(src, vehicle, plate)
    plate = plateOf(vehicle, plate)
    -- newer qb-vehiclekeys has exports, old ones only had the event
    local ok = pcall(function()
        exports['qb-vehiclekeys']:GiveKeys(src, plate)
    end)
    if not ok then
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    end
end
remove['qb-vehiclekeys'] = function(src, vehicle, plate)
    plate = plateOf(vehicle, plate)
    pcall(function()
        exports['qb-vehiclekeys']:RemoveKeys(src, plate)
    end)
end

give['wasabi_carlock'] = function(src, vehicle, plate)
    exports.wasabi_carlock:GiveKey(src, plateOf(vehicle, plate))
end
remove['wasabi_carlock'] = function(src, vehicle, plate)
    exports.wasabi_carlock:RemoveKey(src, plateOf(vehicle, plate))
end

-- resource folder case differs between downloads
local function mrnewb()
    return exports[Bridge.ResourceStarted('MrNewbVehicleKeys') and 'MrNewbVehicleKeys' or 'mrnewbvehiclekeys']
end
give['MrNewbVehicleKeys'] = function(src, vehicle, plate)
    mrnewb():GiveKeysByPlate(src, plateOf(vehicle, plate))
end
remove['MrNewbVehicleKeys'] = function(src, vehicle, plate)
    mrnewb():RemoveKeysByPlate(src, plateOf(vehicle, plate))
end
give['mrnewbvehiclekeys'] = give['MrNewbVehicleKeys']
remove['mrnewbvehiclekeys'] = remove['MrNewbVehicleKeys']

give['Renewed-Vehiclekeys'] = function(src, vehicle, plate)
    exports['Renewed-Vehiclekeys']:addKey(src, plateOf(vehicle, plate))
end
remove['Renewed-Vehiclekeys'] = function(src, vehicle, plate)
    exports['Renewed-Vehiclekeys']:removeKey(src, plateOf(vehicle, plate))
end

give['vehicles_keys'] = function(src, vehicle, plate)
    exports['vehicles_keys']:giveVehicleKeysToPlayerId(src, plateOf(vehicle, plate), 'temporary')
end
remove['vehicles_keys'] = function(src, vehicle, plate)
    exports['vehicles_keys']:removeKeysFromPlayerId(src, plateOf(vehicle, plate))
end

give['cd_garage'] = function(src, vehicle, plate)
    TriggerClientEvent('cd_garage:AddKeys', src, plateOf(vehicle, plate))
end

give['okokGarage'] = function(src, vehicle, plate)
    TriggerEvent('okokGarage:GiveKeys', plateOf(vehicle, plate))
end
remove['okokGarage'] = function(src, vehicle, plate)
    TriggerEvent('okokGarage:RemoveKeys', plateOf(vehicle, plate), src)
end

give['mVehicle'] = function(src, vehicle, plate)
    exports.mVehicle:AddTemporalVehicle(src, vehicle)
end

-- nd core builds keys into the framework, its api comes from the init loader
local ndApi
local function nd()
    if not ndApi then
        NDCore = {}
        lib.load('@ND_Core.init')
        ndApi = NDCore
    end
    return ndApi
end
give['nd'] = function(src, vehicle, plate)
    nd().giveVehicleAccess(src, vehicle, true)
end
remove['nd'] = function(src, vehicle, plate)
    nd().giveVehicleAccess(src, vehicle, false)
end

---@param src number
---@param vehicle number
---@param plate? string
function Bridge.VehicleKeys.Give(src, vehicle, plate)
    local fn = give[vkeys]
    if not fn then
        if Config.Debug then
            print(('[gunchi-bridge] no vehicle key system (%s); Give skipped'):format(vkeys))
        end
        return false
    end
    return pcall(fn, src, vehicle, plate)
end

-- not every key script can take keys back (cd_garage, mVehicle), those just
-- return false
---@param src number
---@param vehicle number
---@param plate? string
function Bridge.VehicleKeys.Remove(src, vehicle, plate)
    local fn = remove[vkeys]
    if not fn then return false end
    return pcall(fn, src, vehicle, plate)
end

-- relays for the client api, some key scripts only have server exports.
-- you can only key yourself and you have to be near the vehicle, so there's
-- nothing to gain from spoofing these
local function resolveRequest(src, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    if #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > 30.0 then return nil end
    return vehicle
end

RegisterNetEvent('gunchi-bridge:server:giveVehicleKeys', function(netId)
    local src = source --[[@as number]]
    local vehicle = resolveRequest(src, netId)
    if vehicle then Bridge.VehicleKeys.Give(src, vehicle) end
end)

RegisterNetEvent('gunchi-bridge:server:removeVehicleKeys', function(netId)
    local src = source --[[@as number]]
    local vehicle = resolveRequest(src, netId)
    if vehicle then Bridge.VehicleKeys.Remove(src, vehicle) end
end)