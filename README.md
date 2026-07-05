# gunchi-bridge

A lightweight compatibility layer for Gunchi. It auto-detects
the framework, inventory, target, notify, dispatch, vehicle key and fuel
systems a server runs and exposes a single, stable API so the same script
works everywhere.

## Requirements

- **ox_lib** (required — used for notify, textui and logging)
- A supported **framework**: `qbx_core` (QBox), `qb-core` (QBCore),
  `es_extended` (ESX) or `ND_Core` — or none at all (**standalone**: jobs are
  checked through ace permissions, money functions are disabled)
- A supported **inventory**: `ox_inventory`, `qb-inventory`, `tgiann-inventory`,
  `origen_inventory` or the built-in ESX inventory
- A supported **target**: `ox_target`, `qb-target` or `sleepless_interact`

Optional (used when present, safe no-ops / fallbacks when absent):

- **Dispatch**: `ps-dispatch`, `cd_dispatch`, `rcore_dispatch`,
  `core_dispatch`, `tk_dispatch`, `aty_dispatch`, `codem-dispatch`,
  `origen_police`, `lb-tablet`, `kartik-mdt` — with none installed, alerts
  fall back to notifying on-duty players of the alert's jobs.
- **Vehicle keys**: `qbx_vehiclekeys`, `qb-vehiclekeys`, `wasabi_carlock`,
  `MrNewbVehicleKeys`, `Renewed-Vehiclekeys`, `vehicles_keys` (jaksam),
  `cd_garage`, `okokGarage`, `mVehicle`.
- **Fuel**: `ox_fuel`, `LegacyFuel`, `ps-fuel`, `cdn-fuel`, `lc_fuel`,
  `qb-fuel`, `Renewed-Fuel` — with none installed, the fuel level is set
  natively (compatible with most LegacyFuel forks).

Everything is auto-detected. If detection ever guesses wrong (renamed/forked
resources), force it in `shared/config.lua`.

## Usage

Add `gunchi-bridge` as a dependency in your resource's `fxmanifest.lua`, then:

```lua
local Bridge = exports['gunchi-bridge']:getBridge()
```

### Server API

```lua
Bridge.GetPlayer(src)                        -- RAW framework player (shape differs per framework)
Bridge.GetIdentifier(src)                    -- citizenid / esx identifier / nd id / license
Bridge.GetPlayerName(src)                    -- "First Last"
Bridge.GetPlayers()                          -- table<src, Player> of everyone online
Bridge.GetPlayersWithJob(jobs, onDutyOnly)   -- sources with job(s); onDutyOnly defaults true
Bridge.HasJob(src, job, grade, onDuty)       -- grade = minimum grade, both optional
Bridge.AddMoney(src, account, amount, reason)    -- account: 'cash'|'bank' -> boolean
Bridge.RemoveMoney(src, account, amount, reason) -- checks balance first -> boolean
Bridge.GetMoney(src, account)                    -- -> number
Bridge.Notify(src, msg, type, duration)      -- type: inform|success|error|warning

Bridge.Inventory.AddItem(src, item, amount, metadata)  -- -> boolean
Bridge.Inventory.RemoveItem(src, item, amount)         -- -> boolean
Bridge.Inventory.CanCarryItem(src, item, amount)       -- -> boolean
Bridge.Inventory.GetItemCount(src, item)               -- -> number
Bridge.Inventory.HasItem(src, item, amount)            -- -> boolean
Bridge.Inventory.GetItemLabel(item)                    -- -> string

Bridge.Dispatch.Alert(src, {                 -- police/ems alert, safe everywhere
    title = 'Suspicious digging',
    description = 'Someone is digging up the beach',
    code = '10-66',                          -- default '10-90'
    coords = vec3(x, y, z),                  -- defaults to src ped position
    jobs = { 'police' },                     -- default
    flash = false, length = 5,               -- blip minutes
    sprite = 161, colour = 1, scale = 1.0,
})

Bridge.VehicleKeys.Give(src, vehicle, plate)   -- plate optional (read from entity)
Bridge.VehicleKeys.Remove(src, vehicle, plate) -- no-op on systems without removal

Bridge.Fuel.Set(vehicle, amount)             -- 0-100; relays to owner client if needed
Bridge.Fuel.Get(vehicle)                     -- number|nil (server only knows ox_fuel)

Bridge.Log(src, category, title, message)    -- ox_lib logger / console
```

### Client API

```lua
Bridge.Notify(msg, type, duration)
Bridge.IsDead()                              -- -> boolean
Bridge.GetPlayerData()                       -- RAW framework player data
Bridge.GetJob()                              -- { name, label, grade, onDuty } or nil
Bridge.HasJob(job, grade, onDuty)            -- same rules as the server version

local zone = Bridge.Target.AddSphereZone({
    coords = vec3(x, y, z), radius = 2.0,
    label = 'Do thing', icon = 'fas fa-hand',
    canInteract = function() return not Bridge.IsDead() end,
    onSelect = function() doThing() end,
})
Bridge.Target.AddBoxZone({ coords = ..., size = vec3(2,2,2), heading = 0.0, ... })
Bridge.Target.RemoveZone(zone)

-- Entity/model targeting. Add* returns an option name; pass it (plus the same
-- entities/models) to the matching Remove*.
local opt = Bridge.Target.AddLocalEntity(ped, {
    label = 'Talk', icon = 'fas fa-comment', distance = 2.0,
    onSelect = function(entity) talkTo(entity) end,
})
Bridge.Target.RemoveLocalEntity(ped, opt)
local opt2 = Bridge.Target.AddModel({ `prop_atm_01` }, { label = 'Use', onSelect = ... })
Bridge.Target.RemoveModel({ `prop_atm_01` }, opt2)

Bridge.TextUI.Show('[E] Do thing', { position = 'left-center', icon = 'fas fa-hand' })
Bridge.TextUI.Hide()

Bridge.VehicleKeys.Give(vehicle, plate)      -- keys for the local player
Bridge.VehicleKeys.Remove(vehicle, plate)

Bridge.Fuel.Set(vehicle, amount)             -- 0-100
Bridge.Fuel.Get(vehicle)                     -- -> number
```

## Notes

- Frameworks without a duty system (ND, older ESX) always count as on duty.
- On standalone servers, job checks use ace permissions — grant them with e.g.
  `add_ace group.police gunchi.job.police allow` in your server.cfg. Money and
  item functions return false/0 there.
- `Bridge.GetPlayer` / `Bridge.GetPlayerData` return the raw framework object,
  so only touch those in framework-specific code — everything else on the
  bridge is safe on every framework.

- `Bridge.Dispatch.Alert` never errors: unsupported/missing dispatch resources
  fall back to notifying matching on-duty players, and backend failures are
  caught and printed.
- Client `VehicleKeys`/`Fuel` calls for server-side systems (qbx_vehiclekeys,
  Renewed-Fuel, lc_fuel) relay through bridge net events. The relays only act
  on the calling player and require them to be within 30m of the vehicle.
- Vehicle key removal is not supported by `cd_garage` and `mVehicle`; those
  return `false` instead of erroring.

## Adding support for another system

Each subsystem lives in its own file (`server/inventory.lua`,
`server/dispatch.lua`, `client/target.lua`, ...). Add a new branch (or a new
entry in the implementation table) keyed off the detection functions in
`shared/util.lua` — the public API stays the same for every consuming script.