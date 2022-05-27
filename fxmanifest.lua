fx_version 'bodacious'
game 'gta5'
description 'Sogolisica'

version '1.0.0'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config.lua',
	'server/classes/vehicles.lua',
	'server/main.lua',
	'server/shop.lua',
	'server/garage.lua',
	'server/trunk.lua',
	'server/lock.lua',
}

client_scripts { 
	'@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/CircleZone.lua',
	'config.lua',
	'client/shop.lua',
	'client/garage.lua',
	'client/trunk.lua',
	'client/lock.lua',
}

ui_page 'html/index.html'

files {
	'html/js/main.js',
	'html/index.html',
	'html/css/main.css',
	'html/img/container.png',
	'html/img/Logo.png',
	'html/path.png'
}

export 'GeneratePlate'