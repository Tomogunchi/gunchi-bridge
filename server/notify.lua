-- the client file defines this too, that's the point of a bridge
---@diagnostic disable: duplicate-set-field

local notify = Bridge.DetectNotify()

---@param src number
---@param message string
---@param ntype? string
---@param duration? number
function Bridge.Notify(src, message, ntype, duration)
    ntype = Bridge.MapNotifyType(ntype)
    duration = duration or 5000

    if notify == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, {
            description = message,
            type = ntype,
            duration = duration,
        })
    elseif notify == 'esx' then
        TriggerClientEvent('esx:showNotification', src, message)
    else
        -- qb only knows primary/success/error
        local qbType = ntype == 'inform' and 'primary' or ntype
        TriggerClientEvent('QBCore:Notify', src, message, qbType, duration)
    end
end