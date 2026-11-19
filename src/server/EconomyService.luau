-- EconomyService.luau (ModuleScript, ServerScriptService)
-- The money loop: every second each player's cash grows by their effective
-- income (base income x rebirth multiplier x event factor) and the client
-- gets a fresh state snapshot. Also validates and settles conveyor buys.

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Config = require(ServerScriptService:WaitForChild("Config"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))

local EconomyService = {}

local ctx = nil

local function toast(player, text)
	if ctx and ctx.remotes and ctx.remotes.Toast then
		ctx.remotes.Toast:FireClient(player, text)
	end
end

function EconomyService.buyBrainrotFromConveyor(player, model)
	local state = PlayerState.get(player)
	if not state or not state.basePlot then
		return
	end
	local conveyor = ctx.services.ConveyorService
	local base = ctx.services.BaseService
	if not conveyor or not base then
		return
	end
	if not conveyor.isOnBelt(model) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local body = model.PrimaryPart
	if not root or not body then
		return
	end
	if (root.Position - body.Position).Magnitude > Config.BuyDistance + 4 then
		return
	end
	local price = model:GetAttribute("Price")
	if state.cash < price then
		toast(player, "Uang tidak cukup untuk " .. model:GetAttribute("DefName"))
		return
	end
	local slotIndex = PlayerState.freeSlotIndex(state)
	if not slotIndex then
		toast(player, "Base penuh! Beli slot atau jual dulu")
		return
	end
	PlayerState.addCash(state, -price)
	conveyor.removeFromBelt(model)
	local prompt = body:FindFirstChild("BuyPrompt")
	if prompt then
		prompt:Destroy()
	end
	if base.placeBrainrotOnBaseSlot(player, model, slotIndex) then
		toast(player, model:GetAttribute("DefName") .. " dibeli! +$" .. tostring(model:GetAttribute("Income")) .. "/detik")
	end
end

local function tickIncomePerSecond()
	for player, state in pairs(PlayerState.eachState()) do
		local gain = PlayerState.effectiveIncome(state)
		if gain > 0 then
			PlayerState.addCash(state, gain)
		end
		if ctx.remotes and ctx.remotes.UpdateState then
			ctx.remotes.UpdateState:FireClient(player, PlayerState.snapshot(state))
		end
	end
	if ctx.services.BaseService then
		ctx.services.BaseService.refreshBaseBoards()
	end
end

function EconomyService.init(context)
	ctx = context
	task.spawn(function()
		while true do
			task.wait(Config.TickSeconds)
			tickIncomePerSecond()
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			local state = PlayerState.get(player)
			if state and ctx.remotes and ctx.remotes.UpdateState then
				ctx.remotes.UpdateState:FireClient(player, PlayerState.snapshot(state))
			end
		end)
	end)
end

return EconomyService
