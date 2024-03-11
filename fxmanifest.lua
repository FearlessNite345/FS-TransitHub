fx_version 'cerulean'
game "gta5"
author "FearlessStudios"
version '1.0.0'
lua54 'yes'

escrow_ignore {
  'config/**/*'
}

client_scripts {
  'client/*.lua'
}

server_scripts {
  'server/*.lua'
}

shared_scripts {
    'shared/*.lua',
    'config/*.lua'
}