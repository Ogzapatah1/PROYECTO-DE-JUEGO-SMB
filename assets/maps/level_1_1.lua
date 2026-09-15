return {
	version = "1.10",
	tiledversion = "1.12.2",
	name = "level_1_1",
	class = "",
	tilewidth = 32,
	tileheight = 32,
	spacing = 0,
	margin = 0,
	width = 20,
	height = 11,
	orientation = "orthogonal",
	renderorder = "right-down",
	infinite = false,
	nextlayerid = 3,
	nextobjectid = 1,
	backgroundcolor = "#3a3a6e",
	tilesets = {
		{
			name = "cave",
			firstgid = 1,
			tilewidth = 32,
			tileheight = 32,
			spacing = 0,
			margin = 0,
			tilecount = 60,
			columns = 10,
			image = "../sprites/Tileset.png",
			imagewidth = 320,
			imageheight = 192,
			objectalignment = "unspecified",
			tileoffset = {
				x = 0,
				y = 0
			},
			tiles = {}
		}
	},
	layers = {
		{
			type = "tilelayer",
			name = "ground",
			x = 0,
			y = 0,
			width = 20,
			height = 11,
			visible = true,
			opacity = 1,
			offsetx = 0,
			offsety = 0,
			parallaxx = 1,
			parallaxy = 1,
			properties = {
				["collidable"] = true
			},
			encoding = "lua",
			data = {
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
        }
		},
		{
			type = "objectgroup",
			name = "spawn",
			visible = true,
			opacity = 1,
			offsetx = 0,
			offsety = 0,
			parallaxx = 1,
			parallaxy = 1,
			properties = {},
			objects = {
				{
					id = 1,
					name = "player_spawn",
					type = "",
					shape = "point",
					x = 160,
					y = 256,
					width = 0,
					height = 0,
					rotation = 0,
					visible = true,
					properties = {}
				}
			}
		}
	}
}