-- the client file defines these too, that's the point of a bridge
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

-- mostly for topping up freshly spawned job vehicles
---@param vehicle number
---@param amount number
function Bridge.Fuel.Set(vehicle, amount)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    amount = clamp(amount)

    if fuel == 'ox_fuel' then
        Entity(vehicle).state.fuel = amount
        return true
    elseif fuel == 'Renewed-Fuel' then
        return pcall(function()
            exports['Renewed-Fuel']:SetFuel(vehicle, amount)
        end)
    elseif fuel == 'lc_fuel' then
        return pcall(function()
            exports['lc_fuel']:SetFuel(vehicle, amount)
        end)
    end

    -- everything else is client side, hand it to whoever owns the entity
    local owner = NetworkGetEntityOwner(vehicle)
    if not owner or owner <= 0 then return false end
    TriggerClientEvent('gunchi-bridge:client:setFuel', owner,
        NetworkGetNetworkIdFromEntity(vehicle), amount)
    return true
end

-- only ox_fuel keeps fuel somewhere the server can read (statebag), for the
-- rest this comes back nil
---@param vehicle number
function Bridge.Fuel.Get(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    local state = Entity(vehicle).state
    return state and state.fuel or nil
end

-- relay for the client api when the fuel script is server side only. clamped
-- and distance checked, worst case someone fills a tank next to them
RegisterNetEvent('gunchi-bridge:server:setFuel', function(netId, amount)
    local src = source --[[@as number]]
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > 30.0 then return end
    Bridge.Fuel.Set(vehicle, amount)
end)