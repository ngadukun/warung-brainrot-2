-- Main.server.luau (Script, ServerScriptService)
-- Warung Brainrot bootstrap: creates the RemoteEvents, builds the world,
-- starts every service with the shared context, and connects player joins,
-- leaves and the three client-to-server remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))
local WorldBuilder = require(ServerScriptService:WaitForChild("WorldBuilder"))
local ConveyorService = require(ServerScriptService:WaitForChild("ConveyorService"))
local EconomyService = require(ServerScriptService:WaitForChild("EconomyService"))
local BaseService = require(ServerScriptService:WaitForChild("BaseService"))
local StealService = require(ServerScriptService:WaitForChild("StealService"))
local EventService = require(ServerScriptService:WaitForChild("EventService"))
local RebirthService = require(ServerScriptService:WaitForChild("RebirthService"))
local TourHelper = require(ServerScriptService:WaitForChild("TourHelper"))

local REMOTE_NAMES = { "ToggleLock", "Rebirth", "BuySlot", "UpdateState", "Toast", "EventWarning" }

local function buildRemotes()
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local remotes = {}
	for _, name in ipairs(REMOTE_NAMES) do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		remotes[name] = remote
	end
	return remotes
end

local remotes = buildRemotes()
local world = WorldBuilder.buildWorld()

local ctx = {
	world = world,
	remotes = remotes,
	services = {
		ConveyorService = ConveyorService,
		EconomyService = EconomyService,
		BaseService = BaseService,
		StealService = StealService,
		EventService = EventService,
		RebirthService = RebirthService,
		TourHelper = TourHelper,
	},
}

BaseService.init(ctx)
StealService.init(ctx)
ConveyorService.init(ctx)
EconomyService.init(ctx)
EventService.init(ctx)
RebirthService.init(ctx)
TourHelper.init(ctx)

local function onPlayerAdded(player)
	PlayerState.registerPlayer(player)
	BaseService.assignPlot(player)
end

local function onPlayerRemoving(player)
	if StealService.dropCarry then
		StealService.dropCarry(player)
	end
	BaseService.releasePlot(player)
	PlayerState.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
-- Anyone who joined before this script finished starting still gets a base.
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

remotes.ToggleLock.OnServerEvent:Connect(function(player)
	BaseService.lockBaseWithCooldown(player)
end)

remotes.Rebirth.OnServerEvent:Connect(function(player)
	RebirthService.rebirthForMultiplier(player)
end)

remotes.BuySlot.OnServerEvent:Connect(function(player)
	BaseService.buySlotUpgrade(player)
end)

print("Warung Brainrot v2 is open for business")
