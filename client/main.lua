-- local Bridge = exports['gunchi-bridge']:getBridge()
exports('getBridge', function()
    return Bridge
end)

CreateThread(function()
    if not Config.Debug then return end
    print(('[gunchi-bridge] client ready | framework: %s | target: %s | notify: %s | keys: %s | fuel: %s'):format(
        tostring(Bridge.Framework),
        tostring(Bridge.TargetName),
        tostring(Bridge.DetectNotify()),
        tostring(Bridge.VehicleKeysName),
        tostring(Bridge.FuelName)
    ))
end)