-- local Bridge = exports['gunchi-bridge']:getBridge()
exports('getBridge', function()
    return Bridge
end)

CreateThread(function()
    if not Config.Debug then return end
    print(('[gunchi-bridge] server ready | framework: %s | inventory: %s | notify: %s | dispatch: %s | keys: %s | fuel: %s'):format(
        tostring(Bridge.Framework),
        tostring(Bridge.InventoryName),
        tostring(Bridge.DetectNotify()),
        tostring(Bridge.DispatchName),
        tostring(Bridge.VehicleKeysName),
        tostring(Bridge.FuelName)
    ))
    if Bridge.Framework == 'standalone' then
        print('[gunchi-bridge] no framework found, running standalone (jobs use aces, money is disabled)')
    end
    if not Bridge.InventoryName then
        print('[gunchi-bridge] no inventory found, item functions are disabled')
    end
end)