local dispatch = Bridge.DetectDispatch()
Bridge.DispatchName = dispatch

Bridge.Dispatch = {}

-- Bridge.Dispatch.Alert(src, data)
--   title, description, code ('10-90'), coords (defaults to the player's),
--   jobs ({'police'}), flash, length (blip minutes), sprite, colour, scale, radius
-- works no matter what dispatch is installed, worst case it just notifies
-- on duty cops

local function normalise(src, data)
    local coords = data.coords
    if not coords and src then
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then coords = GetEntityCoords(ped) end
    end
    return {
        title = data.title or 'Alert',
        description = data.description or data.title or 'Alert',
        code = data.code or '10-90',
        coords = coords or vector3(0.0, 0.0, 0.0),
        jobs = data.jobs or { 'police' },
        flash = data.flash or false,
        length = data.length or 5,
        sprite = data.sprite or 161,
        colour = data.colour or 1,
        scale = data.scale or 1.0,
        radius = data.radius or 0.0,
    }
end

local senders = {}

senders['ps-dispatch'] = function(src, a)
    TriggerEvent('ps-dispatch:server:notify', {
        jobs = a.jobs,
        coords = a.coords,
        code = a.code,
        message = a.title,
        length = a.length,
        flash = a.flash,
        alert = {
            sound = 'Lose_1st',
            sound2 = 'GTAO_FM_Events_Soundset',
            sprite = a.sprite,
            scale = a.scale,
            color = a.colour,
            flashes = a.flash,
            text = a.title,
            length = a.length,
        },
    })
end

senders['cd_dispatch'] = function(src, a)
    TriggerEvent('cd_dispatch:AddNotification', {
        job_table = a.jobs,
        coords = a.coords,
        title = ('%s - %s'):format(a.code, a.title),
        message = a.description,
        flash = a.flash and 1 or 0,
        unique_id = tostring(math.random(0000000, 9999999)),
        sound = 1,
        blip = {
            sprite = a.sprite,
            scale = a.scale,
            colour = a.colour,
            flashes = a.flash,
            text = a.title,
            time = a.length, -- minutes
            radius = a.radius,
        },
    })
end

senders['rcore_dispatch'] = function(src, a)
    TriggerEvent('rcore_dispatch:server:sendAlert', {
        code = a.code,
        default_priority = 'high',
        coords = a.coords,
        job = a.jobs,
        text = a.title,
        type = 'alerts',
        blip_time = a.length * 60, -- seconds
        blip = {
            sprite = a.sprite,
            colour = a.colour,
            scale = a.scale,
            text = a.title,
        },
    })
end

senders['core_dispatch'] = function(src, a)
    for i = 1, #a.jobs do
        exports['core_dispatch']:sendAlert({
            code = a.code,
            message = a.description,
            extraInfo = {},
            coords = a.coords,
            priority = a.flash,
            job = a.jobs[i],
            time = a.length * 60000, -- ms
            blip = a.sprite,
            color = a.colour,
        })
    end
end

senders['tk_dispatch'] = function(src, a)
    exports.tk_dispatch:addCall({
        title = a.title,
        code = a.code,
        message = a.description,
        coords = a.coords,
        flash = a.flash,
        playSound = true,
        jobs = a.jobs,
        blip = {
            sprite = a.sprite,
            scale = a.scale,
            color = a.colour,
            flash = a.flash,
        },
    })
end

senders['aty_dispatch'] = function(src, a)
    TriggerEvent('aty_dispatch:server:customDispatch',
        a.title, a.code, { street = '', road = '' }, a.coords,
        nil, nil, nil, nil, a.sprite, a.jobs)
end

senders['codem-dispatch'] = function(src, a)
    exports['codem-dispatch']:CustomDispatch({
        type = 'General',
        header = a.title,
        text = a.description,
        code = a.code,
    })
end

senders['origen_police'] = function(src, a)
    for i = 1, #a.jobs do
        exports['origen_police']:SendAlert({
            coords = a.coords,
            title = a.title,
            type = 'GENERAL',
            message = a.description,
            job = a.jobs[i],
        })
    end
end

senders['lb-tablet'] = function(src, a)
    for i = 1, #a.jobs do
        exports['lb-tablet']:AddDispatch({
            priority = a.flash and 'high' or 'normal',
            code = a.code,
            title = a.title,
            description = a.description,
            location = {
                label = a.title,
                coords = vec2(a.coords.x, a.coords.y),
            },
            time = a.length * 60, -- seconds
            job = a.jobs[i],
            blip = {
                sprite = a.sprite,
                color = a.colour,
                size = a.scale,
                label = a.title,
            },
        })
    end
end

senders['kartik-mdt'] = function(src, a)
    local jobs = {}
    for i = 1, #a.jobs do jobs[a.jobs[i]] = true end
    TriggerEvent('kartik-mdt:server:sendDispatchNotification', {
        title = a.title,
        code = a.code,
        description = a.description,
        location = 'Unknown',
        sound = 'dispatch',
        type = 'Alert',
        x = a.coords.x,
        y = a.coords.y,
        z = a.coords.z,
        blip = {
            radius = a.radius,
            sprite = a.sprite,
            color = a.colour,
            scale = a.scale,
            length = a.length,
        },
        jobs = jobs,
    })
end

-- no dispatch installed, just tell whoever's on duty
senders['none'] = function(src, a)
    local targets = Bridge.GetPlayersWithJob(a.jobs, true)
    for i = 1, #targets do
        Bridge.Notify(targets[i], ('%s: %s'):format(a.code, a.description), 'inform', 7500)
    end
end

function Bridge.Dispatch.Alert(src, data)
    local send = senders[dispatch] or senders['none']
    local ok, err = pcall(send, src, normalise(src, data or {}))
    if not ok then
        print(('[gunchi-bridge] dispatch alert via %s failed: %s'):format(dispatch, err))
    end
end