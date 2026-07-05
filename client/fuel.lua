-- the server file defines these too, that's the point of a bridge
---@diagnostic disable: duplicate-set-field

local fuel = Bridge.DetectFuel()
Bridge.FuelName = fuel

Bridge.Fuel = {}

local function clamp(amount)
    amount = tonumber(amount) or 0
    if amount < 0 then amount = 0 end
    if amount > 100 then amount = 100 end
    return amount + 0.0
end

-- most LegacyFuel forks read the _FUEL_LEVEL decor, so setting the native
-- level + decor covers a lot of scripts we don't explicitly support
local function setNative(vehicle, amount)
    SetVehicleFuelLevel(vehicle, amount)
    if DecorIsRegisteredAsType('_FUEL_LEVEL', 1) then
        DecorSetFloat(vehicle, '_FUEL_LEVEL', amount)
    end
end

-- these have a client SetFuel export
local clientExports = {
    ['LegacyFuel'] = true,
    ['ps-fuel'] = true,
    ['cdn-fuel'] = true,
    ['qb-fuel'] = true,
}

-- these only have server exports, bounce through the bridge
local serverSide = {
    ['lc_fuel'] = true,
    ['Renewed-Fuel'] = true,
}

---@param vehicle number
---@param amount number
function Bridge.Fuel.Set(vehicle, amount)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    amount = clamp(amount)

    if fuel == 'ox_fuel' then
        Entity(vehicle).state:set('fuel', amount, true)
        SetVehicleFuelLevel(vehicle, amount)
    elseif clientExports[fuel] then
        local ok = pcall(function()
            exports[fuel]:SetFuel(vehicle, amount)
        end)
        if not ok then setNative(vehicle, amount) end
    elseif serverSide[fuel] then
        TriggerServerEvent('gunchi-bridge:server:setFuel', NetworkGetNetworkIdFromEntity(vehicle), amount)
    else
        setNative(vehicle, amount)
    end
end

-- every fuel script keeps the native level in sync on the owning client, so
-- this is safe regardless of what's running
---@param vehicle number
function Bridge.Fuel.Get(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return 0 end
    return GetVehicleFuelLevel(vehicle)
end

RegisterNetEvent('gunchi-bridge:client:setFuel', function(netId, amount)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    Bridge.Fuel.Set(vehicle, amount)
end)