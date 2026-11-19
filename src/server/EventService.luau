-- EventService.luau (ModuleScript, ServerScriptService)
-- The two rotating world events, alternating every Config.EventInterval:
-- Hujan Krupuk, a wave that sweeps the map and knocks everyone caught
-- outside a base back to spawn, and Lampu Disko, thirty seconds of double
-- income under cycling market lights.

local ServerScriptService = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Config = require(ServerScriptService:WaitForChild("Config"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))

local EventService = {}

local ctx = nil
local waveRunning = false
local discoRunning = false
local nightAmbient = nil
local nightFog = nil

local function warnAll(title, sub, seconds)
	if ctx and ctx.remotes and ctx.remotes.EventWarning then
		ctx.remotes.EventWarning:FireAllClients({ title = title, sub = sub, seconds = seconds })
	end
end

local function buildWaveModel()
	local model = Instance.new("Model")
	model.Name = "KrupukWave"
	local wall = Instance.new("Part")
	wall.Name = "WaveWall"
	wall.Size = Vector3.new(130, 11, 1.6)
	wall.Color = Color3.fromRGB(245, 232, 195)
	wall.Transparency = 0.3
	wall.Anchored = true
	wall.CanCollide = false
	wall.CastShadow = false
	wall.Parent = model
	model.PrimaryPart = wall
	local random = Random.new()
	for i = 1, 16 do
		local krupuk = Instance.new("Part")
		krupuk.Name = "Krupuk"
		krupuk.Shape = Enum.PartType.Ball
		local size = random:NextNumber(1.2, 2.4)
		krupuk.Size = Vector3.new(size, size * 0.4, size)
		krupuk.Color = Color3.fromRGB(248, 240, 210)
		krupuk.Anchored = false
		krupuk.CanCollide = false
		krupuk.CastShadow = false
		krupuk.CFrame = CFrame.new(random:NextNumber(-62, 62), random:NextNumber(1, 10), random:NextNumber(-0.5, 0.5))
		krupuk.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = wall
		weld.Part1 = krupuk
		weld.Parent = wall
	end
	return model
end

function EventService.triggerKrupukWave()
	if waveRunning then
		return
	end
	waveRunning = true
	PlayerState.eventState.name = "krupuk"
	PlayerState.eventState.endsAt = os.clock() + Config.KrupukWarningSeconds + 3
	warnAll("HUJAN KRUPUK!", "Lari pulang ke base kamu!", Config.KrupukWarningSeconds)
	task.wait(Config.KrupukWarningSeconds)

	local wave = buildWaveModel()
	wave:SetPrimaryPartCFrame(CFrame.new(0, 5.5, -68))
	wave.Parent = workspace
	local base = ctx.services.BaseService
	local steal = ctx.services.StealService
	for step = 1, 44 do
		local z = -68 + step * 3.1
		wave:SetPrimaryPartCFrame(CFrame.new(0, 5.5, z))
		task.wait(0.045)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if base and not base.isInsideAnyBase(player) then
			if steal then
				steal.dropCarry(player)
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = ctx.world.spawnCFrame
				root.AssemblyLinearVelocity = Vector3.zero
			end
			if ctx.remotes and ctx.remotes.Toast then
				ctx.remotes.Toast:FireClient(player, "Kena sapu Hujan Krupuk!")
			end
		end
	end
	wave:Destroy()
	PlayerState.eventState.name = "none"
	PlayerState.eventState.endsAt = 0
	waveRunning = false
end

function EventService.startDiscoLights()
	if discoRunning then
		return
	end
	discoRunning = true
	local event = PlayerState.eventState
	event.name = "disco"
	event.incomeFactor = Config.DiscoFactor
	event.endsAt = os.clock() + Config.DiscoDuration
	warnAll("LAMPU DISKO!", "Penghasilan x2 selama " .. Config.DiscoDuration .. " detik!", 3)
	task.spawn(function()
		local index = 0
		local bulbs = ctx.world and ctx.world.stringBulbs or {}
		local bulbColors = {}
		for i, bulb in ipairs(bulbs) do
			bulbColors[i] = bulb.Color
		end
		while os.clock() < event.endsAt do
			index += 1
			local color = Config.DiscoPalette[(index % #Config.DiscoPalette) + 1]
			Lighting.Ambient = color
			Lighting.FogColor = color
			for i, bulb in ipairs(bulbs) do
				bulb.Color = Config.DiscoPalette[((index + i) % #Config.DiscoPalette) + 1]
			end
			task.wait(0.4)
		end
		for i, bulb in ipairs(bulbs) do
			bulb.Color = bulbColors[i]
		end
		Lighting.Ambient = nightAmbient
		Lighting.FogColor = nightFog
		event.incomeFactor = 1
		event.name = "none"
		event.endsAt = 0
		discoRunning = false
	end)
end

local function eventLoop()
	local nextKind = "krupuk"
	while true do
		local event = PlayerState.eventState
		event.nextEventAt = os.clock() + Config.EventInterval
		event.nextEventName = nextKind == "krupuk" and "Hujan Krupuk" or "Lampu Disko"
		task.wait(Config.EventInterval)
		if nextKind == "krupuk" then
			EventService.triggerKrupukWave()
			nextKind = "disco"
		else
			EventService.startDiscoLights()
			nextKind = "krupuk"
		end
	end
end

function EventService.init(context)
	ctx = context
	nightAmbient = Lighting.Ambient
	nightFog = Lighting.FogColor
	task.spawn(eventLoop)
end

return EventService
