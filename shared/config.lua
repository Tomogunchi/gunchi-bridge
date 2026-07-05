-- gunchi-bridge config
-- leave stuff on 'auto' and the bridge figures out what the server runs.
-- only force a value if you're on a rename/fork and detection gets it wrong.

Config = Config or {}

-- 'auto' | 'qbx' | 'qb' | 'esx' | 'nd' | 'standalone'
-- standalone = no framework at all, job/money stuff turns into safe no-ops
Config.Framework = 'auto'

-- 'auto' | 'ox' | 'qb' | 'tgiann' | 'origen' | 'esx' (es_extended built in)
Config.Inventory = 'auto'

-- 'auto' | 'ox' | 'qb' | 'interact' (sleepless_interact)
Config.Target = 'auto'

-- 'auto' | 'ox' (ox_lib notify) | 'qb' (QBCore:Notify)
Config.Notify = 'auto'

-- 'auto' | 'ox' | 'qb'
Config.TextUI = 'auto'

-- 'auto' | 'ox' (ox_lib logger -> discord/datadog/loki, set up in ox_lib) | 'none'
Config.Logging = 'auto'

-- 'auto' | 'none' | one of:
--   ps-dispatch, cd_dispatch, rcore_dispatch, core_dispatch, tk_dispatch,
--   aty_dispatch, codem-dispatch, origen_police, lb-tablet, kartik-mdt
-- 'none' = alerts just notify on duty police instead
Config.Dispatch = 'auto'

-- 'auto' | 'none' | one of:
--   qbx_vehiclekeys, qb-vehiclekeys, wasabi_carlock, MrNewbVehicleKeys,
--   Renewed-Vehiclekeys, vehicles_keys, cd_garage, okokGarage, mVehicle
Config.VehicleKeys = 'auto'

-- 'auto' | 'native' | one of:
--   ox_fuel, LegacyFuel, ps-fuel, cdn-fuel, lc_fuel, qb-fuel, Renewed-Fuel
-- 'native' just sets the fuel level directly, works with most LegacyFuel forks
Config.Fuel = 'auto'

-- print what got detected on start
Config.Debug = true