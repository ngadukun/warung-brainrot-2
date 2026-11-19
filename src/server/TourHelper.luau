-- TourHelper.luau (ModuleScript, ServerScriptService)
-- Reviewer helpers named by TOUR.json: each function brings the running
-- game to one of the entry's screenshots — a named brainrot on the belt,
-- a Gold + Diamond showcase, the krupuk wave — or tops up the reviewer's
-- cash so they can buy their way to a stocked base.

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Config = require(ServerScriptService:WaitForChild("Config"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))

local TourHelper = {}

local ctx = nil

local function firstPlayerState()
	local players = Players:GetPlayers()
	if #players == 0 then
		return nil
	end
	return PlayerState.get(players[1])
end

-- TOUR step 2 (and general use): put one named brainrot on the conveyor.
function TourHelper.spawnBrainrot(name)
	if not Config.getDefByName(name) then
		return
	end
	if ctx and ctx.services.ConveyorService then
		ctx.services.ConveyorService.spawnBrainrotOnBelt(name)
	end
end

-- TOUR step 2: one Gold and one Diamond on the belt at once.
function TourHelper.spawnMutationShowcase(_arg)
	if not ctx or not ctx.services.ConveyorService then
		return
	end
	ctx.services.ConveyorService.spawnBrainrotOnBelt("Nasi Padang Raksasa", "Gold")
	ctx.services.ConveyorService.spawnBrainrotOnBelt("Garuda Emas", "Diamond")
end

-- TOUR step 4: fire the Hujan Krupuk wave right now.
function TourHelper.triggerWave(_arg)
	if ctx and ctx.services.EventService then
		task.spawn(function()
			ctx.services.EventService.triggerKrupukWave()
		end)
	end
end

-- The other event, for completeness: thirty seconds of disco.
function TourHelper.triggerDisco(_arg)
	if ctx and ctx.services.EventService then
		ctx.services.EventService.startDiscoLights()
	end
end

-- TOUR step 3: top up the reviewer's cash so they can stock their base.
function TourHelper.grantCash(amount)
	local state = firstPlayerState()
	local value = tonumber(amount) or 0
	if state and value > 0 then
		PlayerState.grantCash(state, value)
	end
end

-- The jackpot screen: a Rainbow Tung-Tung Sahur, the rarest roll in the
-- game, parading down the belt.
function TourHelper.spawnJackpot(_arg)
	if ctx and ctx.services.ConveyorService then
		ctx.services.ConveyorService.spawnBrainrotOnBelt("Tung-Tung Sahur", "Rainbow")
	end
end

function TourHelper.init(context)
	ctx = context
end

return TourHelper
