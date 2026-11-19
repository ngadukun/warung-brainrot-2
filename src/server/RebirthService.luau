-- RebirthService.luau (ModuleScript, ServerScriptService)
-- Rebirth: once a player has earned Config.RebirthThreshold in total, they
-- can wipe their cash and brainrots for a permanent +50% income multiplier.
-- It stacks, so the ladder never really ends.

local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ServerScriptService:WaitForChild("Config"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))

local RebirthService = {}

local ctx = nil

function RebirthService.rebirthForMultiplier(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if state.totalEarned < Config.RebirthThreshold then
		if ctx.remotes and ctx.remotes.Toast then
			ctx.remotes.Toast:FireClient(player, "Rebirth butuh total penghasilan $" .. Config.RebirthThreshold)
		end
		return
	end
	if state.carrying and ctx.services.StealService then
		ctx.services.StealService.dropCarry(player)
	end
	for _, record in pairs(state.slots) do
		if record.model then
			record.model:Destroy()
		end
	end
	state.slots = {}
	state.cash = Config.StartCash
	state.totalEarned = 0
	state.rebirths += 1
	state.multiplier = 1 + Config.RebirthStep * state.rebirths
	PlayerState.recomputeIncome(state)
	-- A fresh start is vulnerable: the base locks itself for ten seconds.
	state.lockUntil = math.max(state.lockUntil, os.clock() + 10)
	if ctx.services.BaseService then
		ctx.services.BaseService.clearPadGlows(player)
		ctx.services.BaseService.refreshBaseBoards()
	end
	if ctx.remotes and ctx.remotes.Toast then
		ctx.remotes.Toast:FireClient(player, "REBIRTH! Penghasilan permanen x" .. tostring(state.multiplier))
	end
end

function RebirthService.init(context)
	ctx = context
end

return RebirthService
