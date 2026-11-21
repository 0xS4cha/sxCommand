fx_version 'cerulean'
game 'gta5'

name 'sxCommand'
description 'Real time tactical command on the minimap: squad positions, orders, intel pings and a gunfire heat map, ESX or standalone'
author '0xS4cha'
version '1.1.0'
repository 'https://github.com/0xS4cha/sxCommand'

lua54 'yes'

shared_scripts {
    'core/sh_logger.lua',
    'core/sh_translation.lua',
    'translations/*.lua',
    'core/sh_modules.lua',
    'core/sh_class.lua',
    'core/sh_callback.lua',
    'core/sh_generate.lua',
    'core/sh_utils.lua',
    'shared/config.lua',
}

client_scripts {
    'bridge/cl_bridge.lua',
    'modules/**/cl_*.lua',
    'core/sh_init.lua',
}

server_scripts {
    'bridge/sv_bridge.lua',
    'modules/**/sv_*.lua',
    'core/sh_init.lua',
}

files {
    'core/SX_COMMAND.gfx',
}
