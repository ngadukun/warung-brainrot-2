-- ConveyorService.luau (ModuleScript, ServerScriptService)
-- Owns the conveyor belt: spawns a brainrot every few seconds, walks each
-- one from the north end to the south end, despawns it there, and wires the
-- "Beli" ProximityPrompt that hands the brainrot to EconomyService.

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Config = require(ServerScriptService:WaitForChild("Config"))
local BrainrotFactory = require(ServerScriptService:WaitForChild("BrainrotFactory"))

local ConveyorService = {}

local ctx = nil
local belt = {} -- array of { model = Model, x = number, z = number }
local random = Random.new()

local function groundCFrame(model, x, groundY, z)
	local body = model.PrimaryPart
	return CFrame.new(x, groundY + body.Size.Y / 2, z)
end

function ConveyorService.isOnBelt(model)
	for _, entry in ipairs(belt) do
		if entry.model == model then
			return true
		end
	end
	return false
end

function ConveyorService.removeFromBelt(model)
	for index, entry in ipairs(belt) do
		if entry.model == model then
			table.remove(belt, index)
			return true
		end
	end
	return false
end

function ConveyorService.countOnBelt()
	return #belt
end

local function pickWeightedDef()
	local total = 0
	for _, def in ipairs(Config.Cast) do
		total += def.weight
	end
	local roll = random:NextNumber() * total
	local cumulative = 0
	for _, def in ipairs(Config.Cast) do
		cumulative += def.weight
		if roll <= cumulative then
			return def
		end
	end
	return Config.Cast[1]
end

local function attachBuyPrompt(model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Beli"
	prompt.ObjectText = model:GetAttribute("DefName") .. " — $" .. tostring(model:GetAttribute("Price"))
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.BuyDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if ctx and ctx.services.EconomyService then
			ctx.services.EconomyService.buyBrainrotFromConveyor(player, model)
		end
	end)
	return prompt
end

-- spawnBrainrotOnBelt(defName, forcedMutationName) -> Model | nil
-- Used by the spawn loop and by TourHelper's showcase calls.
function ConveyorService.spawnBrainrotOnBelt(defName, forcedMutationName)
	local model = BrainrotFactory.buildBrainrotModel(defName, forcedMutationName)
	if not model then
		return nil
	end
	local x = random:NextNumber(-0.9, 0.9)
	local entry = { model = model, x = x, z = Config.BeltStartZ }
	model:SetPrimaryPartCFrame(groundCFrame(model, x, Config.BeltTopY, entry.z))
	model.Parent = workspace
	attachBuyPrompt(model)
	table.insert(belt, entry)
	return model
end

local function spawnLoop()
	while true do
		task.wait(Config.SpawnInterval)
		if #belt < Config.MaxOnBelt then
			local def = pickWeightedDef()
			ConveyorService.spawnBrainrotOnBelt(def.name)
		end
	end
end

local function pulseChevrons()
	-- The belt's neon arrows chase each other toward the south end.
	if not ctx or not ctx.world or not ctx.world.chevrons then
		return
	end
	local phase = math.floor(os.clock() * 2.4) % 2
	for index, chevron in ipairs(ctx.world.chevrons) do
		if (index + phase) % 2 == 0 then
			chevron.Color = Color3.fromRGB(255, 240, 130)
		else
			chevron.Color = Color3.fromRGB(150, 130, 40)
		end
	end
end

local function moveLoop()
	RunService.Heartbeat:Connect(function(dt)
		pulseChevrons()
		for index = #belt, 1, -1 do
			local entry = belt[index]
			if not entry.model.Parent then
				table.remove(belt, index)
			else
				entry.z += Config.BeltSpeed * dt
				if entry.z >= Config.BeltEndZ then
					entry.model:Destroy()
					table.remove(belt, index)
				else
					entry.model:SetPrimaryPartCFrame(groundCFrame(entry.model, entry.x, Config.BeltTopY, entry.z))
				end
			end
		end
	end)
end

function ConveyorService.init(context)
	ctx = context
	moveLoop()
	task.spawn(spawnLoop)
end

return ConveyorService
