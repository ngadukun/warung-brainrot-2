-- PlayerState.luau (ModuleScript, ServerScriptService)
-- The single store of game state: one record per player (cash, slots, lock
-- timers, what they are carrying) plus the shared world-event state. Every
-- service reads and writes state through here and nowhere else.

local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ServerScriptService:WaitForChild("Config"))

local PlayerState = {}

local states = {} -- [Player] = state

-- Shared event state, written by EventService and read by EconomyService/HUD.
PlayerState.eventState = {
	name = "none", -- "none" | "krupuk" | "disco"
	incomeFactor = 1,
	endsAt = 0,
	nextEventAt = 0,
	nextEventName = "Hujan Krupuk",
}

function PlayerState.registerPlayer(player)
	local state = {
		player = player,
		cash = Config.StartCash,
		totalEarned = 0,
		incomePerSecond = 0,
		rebirths = 0,
		multiplier = 1,
		basePlot = nil, -- plot index assigned by BaseService
		slots = {}, -- [slotIndex] = { model, name, rarity, income }
		slotCount = Config.StartSlots,
		lockUntil = 0,
		lockCooldownUntil = 0,
		carrying = nil, -- { defName, mutation, income } while carrying a steal home
	}
	states[player] = state
	return state
end

function PlayerState.get(player)
	return states[player]
end

function PlayerState.removePlayer(player)
	states[player] = nil
end

function PlayerState.eachState()
	return states
end

function PlayerState.addCash(state, amount)
	state.cash += amount
	if amount > 0 then
		state.totalEarned += amount
	end
end

function PlayerState.grantCash(state, amount)
	-- Reviewer helper money: tops up cash without counting as earned income.
	state.cash += amount
end

function PlayerState.recomputeIncome(state)
	local total = 0
	for _, record in pairs(state.slots) do
		total += record.income
	end
	state.incomePerSecond = total
	return total
end

function PlayerState.effectiveIncome(state)
	return state.incomePerSecond * state.multiplier * PlayerState.eventState.incomeFactor
end

function PlayerState.freeSlotIndex(state)
	for index = 1, state.slotCount do
		if state.slots[index] == nil then
			return index
		end
	end
	return nil
end

function PlayerState.findSlotByModel(state, model)
	for slotIndex, record in pairs(state.slots) do
		if record.model == model then
			return slotIndex, record
		end
	end
	return nil, nil
end

function PlayerState.usedSlotCount(state)
	local used = 0
	for _ in pairs(state.slots) do
		used += 1
	end
	return used
end

function PlayerState.snapshot(state)
	local now = os.clock()
	local event = PlayerState.eventState
	return {
		cash = math.floor(state.cash),
		incomePerSecond = PlayerState.effectiveIncome(state),
		multiplier = state.multiplier,
		rebirths = state.rebirths,
		slotCount = state.slotCount,
		usedSlots = PlayerState.usedSlotCount(state),
		slotPrice = Config.slotPriceFor(state.slotCount),
		lockLeft = math.max(0, math.ceil(state.lockUntil - now)),
		lockCooldownLeft = math.max(0, math.ceil(state.lockCooldownUntil - now)),
		carryingName = state.carrying and state.carrying.defName or nil,
		canRebirth = state.totalEarned >= Config.RebirthThreshold,
		activeEventName = event.name,
		activeEventLeft = event.name ~= "none" and math.max(0, math.ceil(event.endsAt - now)) or 0,
		nextEventName = event.nextEventName,
		nextEventIn = math.max(0, math.ceil(event.nextEventAt - now)),
	}
end

return PlayerState
