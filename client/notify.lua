-- the server file defines this too, that's the point of a bridge
---@diagnostic disable: duplicate-set-field

local notify = Bridge.DetectNotify()

---@param message string
---@param ntype? string
---@param duration? number
function Bridge.Notify(message, ntype, duration)
    ntype = Bridge.MapNotifyType(ntype)
    duration = duration or 5000

    if notify == 'ox' then
        lib.notify({
            description = message,
            -- ox_lib's types don't list 'inform' but it still maps it to 'info'
            ---@diagnostic disable-next-line: assign-type-mismatch
            type = ntype,
            duration = duration,
        })
    elseif notify == 'esx' then
        TriggerEvent('esx:showNotification', message)
    else
        -- qb only knows primary/success/error
        local qbType = ntype == 'inform' and 'primary' or ntype
        TriggerEvent('QBCore:Notify', message, qbType, duration)
    end
end