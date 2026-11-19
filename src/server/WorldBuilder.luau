-- WorldBuilder.luau (ModuleScript, ServerScriptService)
-- Builds the whole night market at server start: baseplate and stone path,
-- the central conveyor with neon edges and chevron arrows, the entrance
-- arch, four player base plots with slot pads and name boards, the spawn
-- platform, and all decoration (stalls, trees, lamps, fence, tents,
-- lampion string lights, moon and stars). Returns the world table the
-- services share: plots, chevrons, string bulbs and the spawn CFrame.

local WorldBuilder = {}

local SLOT_OFFSETS = {
	Vector3.new(-5, 0, -4.5), Vector3.new(0, 0, -4.5), Vector3.new(5, 0, -4.5),
	Vector3.new(-5, 0, 4.5), Vector3.new(0, 0, 4.5), Vector3.new(5, 0, 4.5),
	Vector3.new(-5, 0, 0), Vector3.new(5, 0, 0),
	Vector3.new(0, 0, 0), Vector3.new(0, 0, -7.5),
}

local PLOT_DEFS = {
	{ name = "BASE BIRU", colorName = "Biru", color = Color3.fromRGB(50, 110, 235), centre = Vector3.new(0, 0, -52) },
	{ name = "BASE MERAH", colorName = "Merah", color = Color3.fromRGB(225, 60, 55), centre = Vector3.new(52, 0, 0) },
	{ name = "BASE KUNING", colorName = "Kuning", color = Color3.fromRGB(240, 195, 45), centre = Vector3.new(0, 0, 52) },
	{ name = "BASE HIJAU", colorName = "Hijau", color = Color3.fromRGB(60, 185, 90), centre = Vector3.new(-52, 0, 0) },
}

local STALL_COLORS = {
	Color3.fromRGB(230, 90, 70), Color3.fromRGB(70, 160, 230), Color3.fromRGB(245, 180, 60),
	Color3.fromRGB(120, 200, 110), Color3.fromRGB(200, 110, 220), Color3.fromRGB(240, 130, 170),
	Color3.fromRGB(90, 210, 200), Color3.fromRGB(250, 150, 80),
}

local LAMPION_COLORS = {
	Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 120, 130),
	Color3.fromRGB(255, 220, 110), Color3.fromRGB(255, 150, 200),
}

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function disc(parent, name, radius, height, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function buildGroundAndPath(folder)
	part(folder, "Baseplate", Vector3.new(170, 1, 170), CFrame.new(0, -0.5, 0), Color3.fromRGB(28, 62, 34))
	part(folder, "StonePath", Vector3.new(15, 0.24, 128), CFrame.new(0, 0.02, 0), Color3.fromRGB(96, 92, 88), Enum.Material.Cobblestone)
	part(folder, "CrossPath", Vector3.new(128, 0.24, 15), CFrame.new(0, 0.02, 0), Color3.fromRGB(96, 92, 88), Enum.Material.Cobblestone)
end

local function buildConveyor(folder, world)
	local belt = Instance.new("Folder")
	belt.Name = "Conveyor"
	belt.Parent = folder
	part(belt, "BeltBase", Vector3.new(7.5, 1, 66), CFrame.new(0, 0.5, 0), Color3.fromRGB(52, 52, 60), Enum.Material.Metal)
	part(belt, "BeltSurface", Vector3.new(6.2, 0.22, 63), CFrame.new(0, 1.0, 0), Color3.fromRGB(24, 24, 28), Enum.Material.Rubber)
	for _, side in ipairs({ -3.6, 3.6 }) do
		part(belt, "BeltEdge", Vector3.new(0.45, 0.3, 63), CFrame.new(side, 1.05, 0), Color3.fromRGB(255, 225, 60), Enum.Material.Neon)
	end
	world.chevrons = {}
	for i = 0, 9 do
		local z = -27 + i * 6
		for _, dir in ipairs({ -1, 1 }) do
			local chevron = part(belt, "Chevron", Vector3.new(0.5, 0.18, 2.4),
				CFrame.new(dir * 0.85, 1.14, z) * CFrame.Angles(0, dir * 0.6, 0),
				Color3.fromRGB(255, 240, 130), Enum.Material.Neon)
			table.insert(world.chevrons, chevron)
		end
	end
end

local function buildEntranceArch(folder)
	local arch = Instance.new("Folder")
	arch.Name = "EntranceArch"
	arch.Parent = folder
	for _, side in ipairs({ -8, 8 }) do
		part(arch, "ArchPole", Vector3.new(0.9, 13, 0.9), CFrame.new(side, 6.5, 40), Color3.fromRGB(190, 45, 45), Enum.Material.Wood)
	end
	local board = part(arch, "ArchBoard", Vector3.new(19, 3.4, 0.6), CFrame.new(0, 13.4, 40), Color3.fromRGB(120, 30, 60))
	part(arch, "ArchFrameTop", Vector3.new(19.6, 0.35, 0.7), CFrame.new(0, 15.25, 40), Color3.fromRGB(255, 210, 80), Enum.Material.Neon)
	part(arch, "ArchFrameBottom", Vector3.new(19.6, 0.35, 0.7), CFrame.new(0, 11.55, 40), Color3.fromRGB(255, 210, 80), Enum.Material.Neon)
	for _, side in ipairs({ -10.6, 10.6 }) do
		local star = part(arch, "ArchStar", Vector3.new(1.5, 1.5, 1.5), CFrame.new(side, 13.4, 40), Color3.fromRGB(255, 235, 130), Enum.Material.Neon)
		star.Shape = Enum.PartType.Ball
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 240, 170)
		sparkles.Parent = star
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "ArchSign"
	gui.Size = UDim2.fromOffset(620, 110)
	gui.StudsOffset = Vector3.new(0, 0.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 64)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 58
	title.TextColor3 = Color3.fromRGB(255, 225, 110)
	title.TextStrokeTransparency = 0.2
	title.Text = "WARUNG BRAINROT"
	title.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Position = UDim2.new(0, 0, 0, 66)
	sub.Size = UDim2.new(1, 0, 0, 34)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextSize = 28
	sub.TextColor3 = Color3.fromRGB(255, 255, 255)
	sub.TextStrokeTransparency = 0.3
	sub.Text = "Pasar Malam Brainrot"
	sub.Parent = gui
	gui.Parent = board
end

local function buildBasePlot(folder, def, index)
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Base" .. def.colorName
	plotFolder.Parent = folder
	local centre = def.centre
	part(plotFolder, "PlotFloor", Vector3.new(17, 0.5, 17), CFrame.new(centre.X, 0.25, centre.Z), def.color, Enum.Material.SmoothPlastic)
	-- A low border the BaseService recolours while the base is locked.
	local border = part(plotFolder, "PlotBorder", Vector3.new(17.8, 0.7, 17.8), CFrame.new(centre.X, 0.1, centre.Z), Color3.fromRGB(40, 40, 48), Enum.Material.Neon)

	local pads = {}
	for slotIndex, offset in ipairs(SLOT_OFFSETS) do
		local pos = centre + offset + Vector3.new(0, 0.5, 0)
		local pad = disc(plotFolder, "Pad" .. slotIndex, 2.1, 0.35, pos + Vector3.new(0, 0.18, 0), Color3.fromRGB(225, 225, 225))
		local ring = disc(plotFolder, "PadRing" .. slotIndex, 2.45, 0.16, pos + Vector3.new(0, 0.08, 0), Color3.fromRGB(120, 120, 120), Enum.Material.Neon)
		pads[slotIndex] = { root = pad, ring = ring, position = pos + Vector3.new(0, 0.36, 0) }
	end

	local boardPos = centre - Vector3.new(centre.X, 0, centre.Z).Unit * 10 + Vector3.new(0, 4.6, 0)
	if centre.X == 0 and centre.Z == 0 then
		boardPos = centre + Vector3.new(0, 4.6, -10)
	end
	local board = part(plotFolder, "NameBoard", Vector3.new(9, 3.2, 0.4), CFrame.new(boardPos), Color3.fromRGB(30, 30, 40))
	local gui = Instance.new("BillboardGui")
	gui.Name = "BoardGui"
	gui.Size = UDim2.fromOffset(300, 100)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 110
	local title = Instance.new("TextLabel")
	title.Name = "BoardTitle"
	title.Size = UDim2.new(1, 0, 0, 44)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 36
	title.TextColor3 = def.color
	title.TextStrokeTransparency = 0.25
	title.Text = def.name
	title.Parent = gui
	local info = Instance.new("TextLabel")
	info.Name = "BoardInfo"
	info.Position = UDim2.new(0, 0, 0, 46)
	info.Size = UDim2.new(1, 0, 0, 40)
	info.BackgroundTransparency = 1
	info.Font = Enum.Font.GothamBold
	info.TextSize = 26
	info.TextColor3 = Color3.fromRGB(255, 255, 255)
	info.TextStrokeTransparency = 0.3
	info.Text = "Kosong"
	info.Parent = gui
	gui.Parent = board

	return {
		index = index,
		name = def.name,
		colorName = def.colorName,
		color = def.color,
		centre = centre,
		pads = pads,
		border = border,
		boardTitle = title,
		boardInfo = info,
		owner = nil,
	}
end

local function buildSpawnPlatform(folder, world)
	disc(folder, "SpawnPlatform", 5.5, 0.5, Vector3.new(20, 0.25, 0), Color3.fromRGB(45, 130, 140))
	disc(folder, "SpawnRing", 6.1, 0.18, Vector3.new(20, 0.1, 0), Color3.fromRGB(120, 240, 230), Enum.Material.Neon)
	world.spawnCFrame = CFrame.new(20, 2.2, 0)
end

local function buildStalls(folder, stallNames)
	local positions = {
		Vector3.new(-40, 0, -38), Vector3.new(40, 0, -38), Vector3.new(-40, 0, -13), Vector3.new(40, 0, -13),
		Vector3.new(-40, 0, 13), Vector3.new(40, 0, 13), Vector3.new(-40, 0, 38), Vector3.new(40, 0, 38),
	}
	for i, pos in ipairs(positions) do
		local stall = Instance.new("Folder")
		stall.Name = "Stall" .. i
		stall.Parent = folder
		local color = STALL_COLORS[i]
		local facing = pos.X < 0 and 1 or -1
		part(stall, "Counter", Vector3.new(3, 2.6, 6.5), CFrame.new(pos.X, 1.3, pos.Z), color)
		for _, dz in ipairs({ -3, 3 }) do
			part(stall, "Post", Vector3.new(0.4, 6.4, 0.4), CFrame.new(pos.X - facing * 1.6, 3.2, pos.Z + dz), Color3.fromRGB(90, 60, 35), Enum.Material.Wood)
		end
		local roof = part(stall, "Roof", Vector3.new(5.5, 3.4, 8),
			CFrame.new(pos.X - facing * 0.4, 7, pos.Z) * CFrame.Angles(0, facing > 0 and math.rad(-90) or math.rad(90), 0), color)
		roof.Shape = Enum.PartType.Wedge
		local lamp = part(stall, "Lamp", Vector3.new(0.9, 0.9, 0.9), CFrame.new(pos.X - facing * 1.6, 5.6, pos.Z), Color3.fromRGB(255, 200, 110), Enum.Material.Neon)
		lamp.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 110)
		light.Brightness = 1.6
		light.Range = 17
		light.Parent = lamp
		local sign = part(stall, "Sign", Vector3.new(0.3, 1.5, 5.6), CFrame.new(pos.X - facing * 1.7, 4.4, pos.Z), Color3.fromRGB(35, 30, 45))
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(220, 52)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 80
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 26
		label.TextColor3 = Color3.fromRGB(255, 235, 180)
		label.TextStrokeTransparency = 0.3
		label.Text = stallNames[i]
		label.Parent = gui
		gui.Parent = sign
	end
end

local function buildTreesAndLamps(folder)
	local treePositions = {
		Vector3.new(36, 0, 36), Vector3.new(-36, 0, 36), Vector3.new(36, 0, -36), Vector3.new(-36, 0, -36),
		Vector3.new(44, 0, 18), Vector3.new(-44, 0, 18), Vector3.new(44, 0, -18), Vector3.new(-44, 0, -18),
		Vector3.new(18, 0, 44), Vector3.new(-18, 0, 44), Vector3.new(18, 0, -44), Vector3.new(-18, 0, -44),
	}
	for i, pos in ipairs(treePositions) do
		local trunk = part(folder, "TreeTrunk" .. i, Vector3.new(1.1, 4.4, 1.1), CFrame.new(pos.X, 2.2, pos.Z), Color3.fromRGB(96, 64, 36), Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		local leaves = part(folder, "TreeLeaves" .. i, Vector3.new(5.4, 5.4, 5.4), CFrame.new(pos.X, 6.6, pos.Z), Color3.fromRGB(30, 84, 40))
		leaves.Shape = Enum.PartType.Ball
	end
	for _, x in ipairs({ -8.5, 8.5 }) do
		for _, z in ipairs({ -45, -22, 0, 22, 45 }) do
			part(folder, "LampPole", Vector3.new(0.35, 7, 0.35), CFrame.new(x, 3.5, z), Color3.fromRGB(45, 45, 55), Enum.Material.Metal)
			local head = part(folder, "LampHead", Vector3.new(1.15, 1.15, 1.15), CFrame.new(x, 7.3, z), Color3.fromRGB(255, 205, 120), Enum.Material.Neon)
			head.Shape = Enum.PartType.Ball
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 195, 115)
			light.Brightness = 1.5
			light.Range = 18
			light.Parent = head
		end
	end
end

local function buildFenceAndTents(folder)
	for _, edge in ipairs({ -61, 61 }) do
		for i = -5, 5 do
			part(folder, "Fence", Vector3.new(10.4, 1.7, 0.4), CFrame.new(i * 10.5, 0.85, edge), Color3.fromRGB(80, 55, 32), Enum.Material.Wood)
			part(folder, "Fence", Vector3.new(0.4, 1.7, 10.4), CFrame.new(edge, 0.85, i * 10.5), Color3.fromRGB(80, 55, 32), Enum.Material.Wood)
		end
	end
	local tentPositions = {
		Vector3.new(-30, 0, -26), Vector3.new(30, 0, 26), Vector3.new(-30, 0, 26),
		Vector3.new(30, 0, -26), Vector3.new(-26, 0, 0), Vector3.new(30, 0, -2),
	}
	for i, pos in ipairs(tentPositions) do
		part(folder, "TentPole" .. i, Vector3.new(0.3, 4.6, 0.3), CFrame.new(pos.X, 2.3, pos.Z), Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
		local top = part(folder, "TentTop" .. i, Vector3.new(7.6, 1.6, 7.6), CFrame.new(pos.X, 5, pos.Z), STALL_COLORS[(i % #STALL_COLORS) + 1])
		top.Shape = Enum.PartType.Ball
	end
end

local function buildStringLights(folder, world)
	world.stringBulbs = {}
	local poleTops = {}
	for _, x in ipairs({ -17, 17 }) do
		for _, z in ipairs({ -42, -14, 14, 42 }) do
			part(folder, "LampionPole", Vector3.new(0.4, 11, 0.4), CFrame.new(x, 5.5, z), Color3.fromRGB(60, 42, 26), Enum.Material.Wood)
			poleTops[tostring(x) .. "/" .. tostring(z)] = Vector3.new(x, 11, z)
		end
	end
	local function stringBetween(a, b, bulbCount)
		for i = 1, bulbCount do
			local t = i / (bulbCount + 1)
			local pos = a:Lerp(b, t)
			pos -= Vector3.new(0, 1.7 * (1 - (2 * t - 1) ^ 2), 0)
			local bulb = part(folder, "Lampion", Vector3.new(0.66, 0.66, 0.66), CFrame.new(pos),
				LAMPION_COLORS[(i % #LAMPION_COLORS) + 1], Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
			table.insert(world.stringBulbs, bulb)
		end
	end
	for _, z in ipairs({ -42, -14, 14, 42 }) do
		stringBetween(poleTops["-17/" .. z], poleTops["17/" .. z], 12)
	end
	for _, x in ipairs({ -17, 17 }) do
		stringBetween(poleTops[x .. "/-42"], poleTops[x .. "/42"], 16)
	end
end

local function buildCratesAndBarrels(folder)
	local spots = {
		Vector3.new(-34, 0, -32), Vector3.new(34, 0, 32), Vector3.new(-34, 0, 20),
		Vector3.new(34, 0, -20), Vector3.new(-24, 0, 44), Vector3.new(24, 0, -44),
	}
	for i, pos in ipairs(spots) do
		part(folder, "Crate" .. i, Vector3.new(2.2, 2.2, 2.2), CFrame.new(pos.X, 1.1, pos.Z) * CFrame.Angles(0, i * 0.7, 0),
			Color3.fromRGB(150, 105, 60), Enum.Material.Wood)
		local barrel = part(folder, "Barrel" .. i, Vector3.new(1.9, 2.8, 1.9), CFrame.new(pos.X + 2.6, 1.4, pos.Z + 1),
			Color3.fromRGB(110, 74, 44), Enum.Material.Wood)
		barrel.Shape = Enum.PartType.Cylinder
	end
end

local function buildSky(folder)
	local moon = part(folder, "Moon", Vector3.new(15, 15, 15), CFrame.new(95, 64, -95), Color3.fromRGB(240, 240, 215), Enum.Material.Neon)
	moon.Shape = Enum.PartType.Ball
	moon.CanCollide = false
	local random = Random.new(7)
	for i = 1, 56 do
		local angle = random:NextNumber() * math.pi * 2
		local radius = random:NextNumber(120, 165)
		local star = part(folder, "Star" .. i, Vector3.new(1.1, 1.1, 1.1),
			CFrame.new(math.cos(angle) * radius, random:NextNumber(42, 88), math.sin(angle) * radius),
			Color3.fromRGB(235, 240, 255), Enum.Material.Neon)
		star.Shape = Enum.PartType.Ball
		star.CanCollide = false
	end
end

function WorldBuilder.buildWorld()
	local folder = Instance.new("Folder")
	folder.Name = "WarungWorld"
	folder.Parent = workspace

	local world = { plots = {}, chevrons = {}, stringBulbs = {}, spawnCFrame = CFrame.new(20, 2.2, 0) }

	buildGroundAndPath(folder)
	buildConveyor(folder, world)
	buildEntranceArch(folder)
	for index, def in ipairs(PLOT_DEFS) do
		world.plots[index] = buildBasePlot(folder, def, index)
	end
	buildSpawnPlatform(folder, world)

	local ServerScriptService = game:GetService("ServerScriptService")
	local Config = require(ServerScriptService:WaitForChild("Config"))
	buildStalls(folder, Config.StallNames)
	buildTreesAndLamps(folder)
	buildFenceAndTents(folder)
	buildCratesAndBarrels(folder)
	buildStringLights(folder, world)
	buildSky(folder)

	return world
end

return WorldBuilder
