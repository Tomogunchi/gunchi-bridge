-- detection helpers, loaded on both sides. client/*.lua and server/*.lua
-- add their own functions onto the same Bridge table.

Bridge = Bridge or {}

local function started(resource)
    return GetResourceState(resource) == 'started'
end
Bridge.ResourceStarted = started

function Bridge.DetectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if started('qbx_core') then return 'qbx' end
    if started('qb-core') then return 'qb' end
    if started('es_extended') then return 'esx' end
    if started('ND_Core') or started('nd_core') then return 'nd' end
    return 'standalone'
end

function Bridge.DetectInventory()
    if Config.Inventory ~= 'auto' then return Config.Inventory end
    if started('ox_inventory') then return 'ox' end
    if started('qb-inventory') then return 'qb' end
    if started('tgiann-inventory') then return 'tgiann' end
    if started('origen_inventory') then return 'origen' end
    -- esx with no dedicated inventory script runs its built in one
    if started('es_extended') then return 'esx' end
    return nil
end

function Bridge.DetectTarget()
    if Config.Target ~= 'auto' then return Config.Target end
    if started('ox_target') then return 'ox' end
    if started('qb-target') then return 'qb' end
    if started('sleepless_interact') then return 'interact' end
    return nil
end

-- ox_lib is a hard dependency so these normally land on 'ox', the framework
-- fallbacks only matter when someone forces the config
function Bridge.DetectNotify()
    if Config.Notify ~= 'auto' then return Config.Notify end
    if started('ox_lib') then return 'ox' end
    if started('es_extended') then return 'esx' end
    return 'qb'
end

function Bridge.DetectTextUI()
    if Config.TextUI ~= 'auto' then return Config.TextUI end
    if started('ox_lib') then return 'ox' end
    if started('es_extended') then return 'esx' end
    return 'qb'
end

local function firstStarted(resources)
    for i = 1, #resources do
        if started(resources[i]) then return resources[i] end
    end
    return nil
end

-- these return the actual resource name, easier than making up short aliases
-- for every dispatch/key/fuel script out there

function Bridge.DetectDispatch()
    if Config.Dispatch ~= 'auto' then return Config.Dispatch end
    return firstStarted({
        'ps-dispatch', 'cd_dispatch', 'rcore_dispatch', 'core_dispatch',
        'tk_dispatch', 'aty_dispatch', 'codem-dispatch', 'origen_police',
        'lb-tablet', 'kartik-mdt',
    }) or 'none'
end

function Bridge.DetectVehicleKeys()
    if Config.VehicleKeys ~= 'auto' then return Config.VehicleKeys end
    local found = firstStarted({
        'qbx_vehiclekeys', 'qb-vehiclekeys', 'wasabi_carlock',
        'MrNewbVehicleKeys', 'mrnewbvehiclekeys', 'Renewed-Vehiclekeys',
        'vehicles_keys', 'cd_garage', 'okokGarage', 'mVehicle',
    })
    if found then return found end
    -- nd core has vehicle access built in
    if started('ND_Core') or started('nd_core') then return 'nd' end
    return 'none'
end

function Bridge.DetectFuel()
    if Config.Fuel ~= 'auto' then return Config.Fuel end
    return firstStarted({
        'ox_fuel', 'LegacyFuel', 'ps-fuel', 'cdn-fuel', 'lc_fuel',
        'qb-fuel', 'Renewed-Fuel',
    }) or 'native'
end

-- squash the different notify type names down to what ox_lib accepts
function Bridge.MapNotifyType(ntype)
    if not ntype then return 'inform' end
    ntype = tostring(ntype):lower()
    local map = {
        success = 'success',
        error = 'error',
        warning = 'warning',
        warn = 'warning',
        info = 'inform',
        inform = 'inform',
        primary = 'inform',
        speech = 'inform',
    }
    return map[ntype] or 'inform'
end