-- BaseService.luau (ModuleScript, ServerScriptService)
-- Owns the four base plots: hands them out on join, walks bought brainrots
-- home to their slot pads, keeps pad glow rings and name boards truthful,
-- and runs the base lock and the slot shop.

local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ServerScriptService:WaitForChild("Config"))
local PlayerState = require(ServerScriptService:WaitForChild("PlayerState"))
local BrainrotFactory = require(ServerScriptService:WaitForChild("BrainrotFactory"))

local BaseService = {}

local ctx = nil

local function toast(player, text)
	if ctx and ctx.remotes and ctx.remotes.Toast then
		ctx.remotes.Toast:FireClient(player, text)
	end
end

local function groundCFrame(model, position)
	local body = model.PrimaryPart
	return CFrame.new(position.X, position.Y + body.Size.Y / 2, position.Z)
end

local function setPadGlow(plot, slotIndex, record)
	local pad = plot.pads[slotIndex]
	if not pad then
		return
	end
	if record then
		pad.ring.Color = Config.RarityColors[record.rarity] or Color3.fromRGB(255, 255, 255)
	else
		pad.ring.Color = Color3.fromRGB(120, 120, 120)
	end
end

local function setPadVisible(plot, slotIndex, visible)
	local pad = plot.pads[slotIndex]
	if not pad then
		return
	end
	pad.root.Transparency = visible and 0 or 1
	pad.ring.Transparency = visible and 0 or 1
	pad.root.CanCollide = visible
end

function BaseService.assignPlot(player)
	local state = PlayerState.get(player)
	if not state then
		return nil
	end
	for _, plot in ipairs(ctx.world.plots) do
		if plot.owner == nil then
			plot.owner = player
			state.basePlot = plot.index
			for slotIndex = 1, Config.MaxSlots do
				setPadVisible(plot, slotIndex, slotIndex <= state.slotCount)
				setPadGlow(plot, slotIndex, nil)
			end
			BaseService.refreshBaseBoards()
			return plot
		end
	end
	return nil
end

function BaseService.releasePlot(player)
	local state = PlayerState.get(player)
	if not state or not state.basePlot then
		return
	end
	local plot = ctx.world.plots[state.basePlot]
	if plot then
		for _, record in pairs(state.slots) do
			if record.model then
				record.model:Destroy()
			end
		end
		plot.owner = nil
		for slotIndex = 1, Config.MaxSlots do
			setPadGlow(plot, slotIndex, nil)
		end
	end
	state.slots = {}
	state.basePlot = nil
	PlayerState.recomputeIncome(state)
	BaseService.refreshBaseBoards()
end

function BaseService.getPlotOf(player)
	local state = PlayerState.get(player)
	if state and state.basePlot then
		return ctx.world.plots[state.basePlot]
	end
	return nil
end

function BaseService.isInsidePlot(player, plot)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not plot then
		return false
	end
	return math.abs(root.Position.X - plot.centre.X) <= 9.5
		and math.abs(root.Position.Z - plot.centre.Z) <= 9.5
end

function BaseService.isInsideAnyBase(player)
	for _, plot in ipairs(ctx.world.plots) do
		if BaseService.isInsidePlot(player, plot) then
			return true
		end
	end
	return false
end

-- placeBrainrotOnBaseSlot(player, model, slotIndex)
-- Walks the model from wherever it stands to the pad, then registers it as
-- the slot's income record and arms its steal prompt.
function BaseService.placeBrainrotOnBaseSlot(player, model, slotIndex)
	local state = PlayerState.get(player)
	local plot = BaseService.getPlotOf(player)
	if not state or not plot then
		return false
	end
	local pad = plot.pads[slotIndex]
	if not pad then
		return false
	end
	local record = {
		model = model,
		name = model:GetAttribute("DefName"),
		rarity = model:GetAttribute("Rarity"),
		income = model:GetAttribute("Income"),
	}
	state.slots[slotIndex] = record
	PlayerState.recomputeIncome(state)
	setPadGlow(plot, slotIndex, record)

	task.spawn(function()
		local body = model.PrimaryPart
		local target = groundCFrame(model, pad.position)
		local steps = 26
		local start = body.CFrame
		for step = 1, steps do
			if not model.Parent then
				return
			end
			model:SetPrimaryPartCFrame(start:Lerp(target, step / steps))
			task.wait(0.03)
		end
		model:SetPrimaryPartCFrame(target)
		BrainrotFactory.startIdleBob(model)
	end)

	if ctx.services.StealService then
		ctx.services.StealService.watchBrainrot(model, player)
	end
	BaseService.refreshBaseBoards()
	return true
end

function BaseService.removeBrainrotFromSlot(owner, model)
	local state = PlayerState.get(owner)
	if not state then
		return nil
	end
	local slotIndex, record = PlayerState.findSlotByModel(state, model)
	if not slotIndex then
		return nil
	end
	state.slots[slotIndex] = nil
	PlayerState.recomputeIncome(state)
	local plot = BaseService.getPlotOf(owner)
	if plot then
		setPadGlow(plot, slotIndex, nil)
	end
	BaseService.refreshBaseBoards()
	return record
end

-- clearPadGlows(player): every pad ring on the player's plot back to grey,
-- used when a rebirth wipes the base.
function BaseService.clearPadGlows(player)
	local plot = BaseService.getPlotOf(player)
	if not plot then
		return
	end
	for slotIndex = 1, Config.MaxSlots do
		setPadGlow(plot, slotIndex, nil)
	end
end

function BaseService.lockBaseWithCooldown(player)
	local state = PlayerState.get(player)
	if not state or not state.basePlot then
		return
	end
	local now = os.clock()
	if now < state.lockCooldownUntil then
		toast(player, "Kunci masih cooldown " .. math.ceil(state.lockCooldownUntil - now) .. " detik")
		return
	end
	state.lockUntil = now + Config.LockDuration
	state.lockCooldownUntil = now + Config.LockCooldown
	toast(player, "Base terkunci " .. Config.LockDuration .. " detik!")
	BaseService.refreshBaseBoards()
end

function BaseService.buySlotUpgrade(player)
	local state = PlayerState.get(player)
	if not state or not state.basePlot then
		return
	end
	local price = Config.slotPriceFor(state.slotCount)
	if not price then
		toast(player, "Slot sudah maksimum")
		return
	end
	if state.cash < price then
		toast(player, "Uang tidak cukup untuk slot baru")
		return
	end
	PlayerState.addCash(state, -price)
	state.slotCount += 1
	local plot = BaseService.getPlotOf(player)
	if plot then
		setPadVisible(plot, state.slotCount, true)
	end
	toast(player, "Slot baru! Sekarang " .. state.slotCount .. " slot")
end

function BaseService.refreshBaseBoards()
	if not ctx or not ctx.world then
		return
	end
	local now = os.clock()
	for _, plot in ipairs(ctx.world.plots) do
		if plot.owner then
			local state = PlayerState.get(plot.owner)
			if state then
				local locked = now < state.lockUntil
				local info = plot.owner.Name .. " • $" .. tostring(math.floor(PlayerState.effectiveIncome(state))) .. "/detik"
				if locked then
					info ..= " • TERKUNCI"
				end
				plot.boardInfo.Text = info
				plot.border.Color = locked and Color3.fromRGB(255, 70, 90) or Color3.fromRGB(40, 40, 48)
			end
		else
			plot.boardInfo.Text = "Kosong"
			plot.border.Color = Color3.fromRGB(40, 40, 48)
		end
	end
end

function BaseService.init(context)
	ctx = context
end

return BaseService
