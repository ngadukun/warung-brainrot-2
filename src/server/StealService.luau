-- StealService.luau (ModuleScript, ServerScriptService)
-- The genre's tension: hold E on a brainrot in someone else's unlocked base
-- to hoist it onto your head, run it home, and it is yours. Caught outside
-- by the Hujan Krupuk wave, you drop it where you stand for anyone to grab.

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Config = require(ServerScriptService:WaitForChild("Config"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))
local BrainrotFactory = require(ServerScriptService:WaitForChild("BrainrotFactory"))

local StealService = {}

local ctx = nil
local carryModels = {} -- [Player] = Model riding on their head
local droppedData = {} -- [Model] = { defName, mutation, income } lying on the ground

local function toast(player, text)
	if ctx and ctx.remotes and ctx.remotes.Toast then
		ctx.remotes.Toast:FireClient(player, text)
	end
end

function StealService.watchBrainrot(model, owner)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Curi"
	prompt.ObjectText = model:GetAttribute("DefName")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = Config.StealHoldTime
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(thief)
		StealService.stealBrainrotFromBase(thief, model, owner)
	end)
end

local function startCarrying(player, data)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local model = BrainrotFactory.buildBrainrotModel(data.defName, data.mutation ~= "" and data.mutation or nil)
	if not model then
		return
	end
	-- The factory re-rolls nothing when a mutation is forced, but a plain
	-- carry must keep the stolen one's exact income: pin it from the data.
	model:SetAttribute("Income", data.income)
	state.carrying = data
	carryModels[player] = model
	model.Parent = workspace
	toast(player, "Dapat " .. data.defName .. "! Lari pulang ke base kamu!")
end

function StealService.stealBrainrotFromBase(thief, model, owner)
	if thief == owner then
		return
	end
	local thiefState = PlayerState.get(thief)
	local ownerState = PlayerState.get(owner)
	if not thiefState or not ownerState then
		return
	end
	if thiefState.carrying then
		toast(thief, "Tangan penuh! Pulang dulu ke base")
		return
	end
	if os.clock() < ownerState.lockUntil then
		toast(thief, "Base " .. owner.Name .. " sedang terkunci!")
		return
	end
	if not PlayerState.freeSlotIndex(thiefState) then
		toast(thief, "Base kamu penuh!")
		return
	end
	local base = ctx.services.BaseService
	local record = base and base.removeBrainrotFromSlot(owner, model)
	if not record then
		return
	end
	local data = {
		defName = model:GetAttribute("DefName"),
		mutation = model:GetAttribute("Mutation"),
		income = model:GetAttribute("Income"),
	}
	model:Destroy()
	startCarrying(thief, data)
	toast(owner, "Brainrot kamu dicuri " .. thief.Name .. "!")
end

local function depositCarriedBrainrot(player)
	local state = PlayerState.get(player)
	if not state or not state.carrying then
		return
	end
	local base = ctx.services.BaseService
	local slotIndex = PlayerState.freeSlotIndex(state)
	if not base or not slotIndex then
		return
	end
	local data = state.carrying
	state.carrying = nil
	local carry = carryModels[player]
	carryModels[player] = nil
	if carry then
		carry:Destroy()
	end
	local model = BrainrotFactory.buildBrainrotModel(data.defName, data.mutation ~= "" and data.mutation or nil)
	if not model then
		return
	end
	model:SetAttribute("Income", data.income)
	local plot = base.getPlotOf(player)
	if plot then
		local pad = plot.pads[slotIndex]
		local body = model.PrimaryPart
		model:SetPrimaryPartCFrame(CFrame.new(pad.position.X, pad.position.Y + body.Size.Y / 2, pad.position.Z))
	end
	model.Parent = workspace
	base.placeBrainrotOnBaseSlot(player, model, slotIndex)
	toast(player, data.defName .. " aman di base!")
end

-- dropCarry(player): the carried brainrot falls at the player's feet with an
-- "Ambil" prompt; anyone with a free slot can pick it up and carry it on.
function StealService.dropCarry(player)
	local state = PlayerState.get(player)
	if not state or not state.carrying then
		return
	end
	local data = state.carrying
	state.carrying = nil
	local carry = carryModels[player]
	carryModels[player] = nil
	if carry then
		carry:Destroy()
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local model = BrainrotFactory.buildBrainrotModel(data.defName, data.mutation ~= "" and data.mutation or nil)
	if not model then
		return
	end
	model:SetAttribute("Income", data.income)
	local body = model.PrimaryPart
	model:SetPrimaryPartCFrame(CFrame.new(root.Position.X, body.Size.Y / 2 + 0.4, root.Position.Z))
	model.Parent = workspace
	droppedData[model] = data
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Ambil"
	prompt.ObjectText = data.defName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(picker)
		local pickerState = PlayerState.get(picker)
		if not pickerState or pickerState.carrying then
			return
		end
		if not PlayerState.freeSlotIndex(pickerState) then
			toast(picker, "Base kamu penuh!")
			return
		end
		local held = droppedData[model]
		if not held then
			return
		end
		droppedData[model] = nil
		model:Destroy()
		startCarrying(picker, held)
	end)
end

local function carryLoop()
	RunService.Heartbeat:Connect(function()
		for player, model in pairs(carryModels) do
			local character = player.Character
			local head = character and character:FindFirstChild("Head")
			if head and model.Parent then
				local body = model.PrimaryPart
				model:SetPrimaryPartCFrame(CFrame.new(head.Position.X, head.Position.Y + 0.9 + body.Size.Y / 2, head.Position.Z))
			end
			local base = ctx and ctx.services.BaseService
			if base and base.getPlotOf(player) and base.isInsidePlot(player, base.getPlotOf(player)) then
				depositCarriedBrainrot(player)
			end
		end
	end)
end

function StealService.init(context)
	ctx = context
	carryLoop()
	-- A carrier who dies drops the brainrot where they fall.
	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				StealService.dropCarry(player)
			end)
		end)
	end)
end

return StealService
