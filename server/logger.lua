local logging = Config.Logging
if logging == 'auto' then
    logging = Bridge.ResourceStarted('ox_lib') and 'ox' or 'none'
end

-- goes to the ox_lib logger, so discord/datadog/loki gets set up in ox_lib
-- itself, not here
function Bridge.Log(src, category, title, message)
    if logging == 'ox' and lib and lib.logger then
        local playerName = src and Bridge.GetPlayerName(src) or 'system'
        lib.logger(src, category, ('[%s] %s\n%s'):format(playerName, title, message))
    elseif logging == 'print' or Config.Debug then
        print(('[gunchi-bridge] [%s] %s: %s'):format(category, title, message))
    end
end