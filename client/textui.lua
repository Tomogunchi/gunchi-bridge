local textui = Bridge.DetectTextUI()

Bridge.TextUI = {}

function Bridge.TextUI.Show(text, opts)
    opts = opts or {}
    if textui == 'ox' then
        lib.showTextUI(text, {
            position = opts.position or 'left-center',
            icon = opts.icon,
        })
    elseif textui == 'esx' then
        exports.es_extended:getSharedObject().TextUI(text)
    else
        exports['qb-core']:DrawText(text, opts.position or 'left')
    end
end

function Bridge.TextUI.Hide()
    if textui == 'ox' then
        lib.hideTextUI()
    elseif textui == 'esx' then
        exports.es_extended:getSharedObject().HideUI()
    else
        exports['qb-core']:HideText()
    end
end