fx_version 'cerulean'
game 'gta5'

author 'FearlessStudios'
description 'FS-TransitHub by FearlessStudios'
version '1.0.0'

escrow_ignore {
    'server/framework.lua',
    'config/**/*'
}

client_script 'dist/client/**/*.lua'
server_script 'dist/server/**/*.lua'
shared_script 'config/**/*'
shared_script 'shared/**/*'

files {
    'config/**/*'
}

Dependecies {
    'FS-Lib'
}
