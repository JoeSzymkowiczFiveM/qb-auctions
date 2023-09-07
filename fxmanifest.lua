fx_version 'cerulean'
game 'gta5'

lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
    '@salty_tokenizer/init.lua',
	'config.lua',
    'client/main.lua',
}

server_scripts {
    '@mongodb/lib/MongoDB.lua',
    '@salty_tokenizer/init.lua',
    --'@oxmysql/lib/MySQL.lua',
    'config.lua',
	'server/main.lua'
}