fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Gunchi'
description 'Gunchi Bridge - framework / inventory / target / dispatch / keys / fuel compatibility layer'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/util.lua',
}

client_scripts {
    'client/framework.lua',
    'client/notify.lua',
    'client/target.lua',
    'client/textui.lua',
    'client/vehiclekeys.lua',
    'client/fuel.lua',
    'client/main.lua',
}

server_scripts {
    'server/framework.lua',
    'server/inventory.lua',
    'server/notify.lua',
    'server/logger.lua',
    'server/dispatch.lua',
    'server/vehiclekeys.lua',
    'server/fuel.lua',
    'server/main.lua',
}

dependency 'ox_lib'