-- BrainrotFactory.luau (ModuleScript, ServerScriptService)
-- Builds a brainrot character Model out of plain Parts (no external assets):
-- a body, a head, two eyes, a rarity prop for the top tiers, a rarity glow
-- for Epic and above, and the floating name / rarity / income label.

local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ServerScriptService:WaitForChild("Config"))

local BrainrotFactory = {}

local random = Random.new()

function BrainrotFactory.rollMutation()
	local roll = random:NextNumber()
	local cumulative = 0
	-- Rarest first so the chances stack the way the design lists them.
	local ordered = { Config.Mutations[3], Config.Mutations[2], Config.Mutations[1] }
	for _, mutation in ipairs(ordered) do
		cumulative += mutation.chance
		if roll <= cumulative then
			return mutation
		end
	end
	return nil
end

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	return part
end

local function weldToBody(body, part)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = part
	weld.Parent = body
end

local function buildLabel(model, head, def, mutation, income)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 84)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextStrokeTransparency = 0.35
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	if mutation then
		title.Text = mutation.symbol .. " " .. string.upper(mutation.name) .. " " .. def.name
	else
		title.Text = def.name
	end
	title.Parent = gui

	local rarity = Instance.new("TextLabel")
	rarity.Name = "Rarity"
	rarity.Position = UDim2.new(0, 0, 0, 30)
	rarity.Size = UDim2.new(1, 0, 0, 24)
	rarity.BackgroundTransparency = 1
	rarity.Font = Enum.Font.GothamBold
	rarity.TextSize = 17
	rarity.TextStrokeTransparency = 0.35
	rarity.TextColor3 = Config.RarityColors[def.rarity] or Color3.fromRGB(255, 255, 255)
	rarity.Text = def.rarity
	rarity.Parent = gui

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "Income"
	incomeLabel.Position = UDim2.new(0, 0, 0, 54)
	incomeLabel.Size = UDim2.new(1, 0, 0, 24)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.TextSize = 17
	incomeLabel.TextStrokeTransparency = 0.35
	incomeLabel.TextColor3 = Color3.fromRGB(140, 255, 150)
	incomeLabel.Text = "$" .. tostring(income) .. "/detik"
	incomeLabel.Parent = gui

	gui.Parent = head
end

local function buildProp(body, head, def, scale)
	-- Legendary and up wear something silly: a gold wedge hat, and Mythic and
	-- up add a three-point crown of small gold blocks.
	local isLegendaryPlus = def.rarity == "Legendary" or def.rarity == "Mythic"
		or def.rarity == "Brainrot God" or def.rarity == "Secret"
	if not isLegendaryPlus then
		return
	end
	local hat = makePart("Hat", Vector3.new(1.1 * scale, 0.7 * scale, 1.1 * scale), Color3.fromRGB(255, 205, 45), Enum.Material.Neon)
	hat.Shape = Enum.PartType.Cylinder
	hat.CFrame = head.CFrame * CFrame.new(0, 0.85 * scale, 0)
	hat.Parent = body.Parent
	weldToBody(body, hat)
	if def.rarity == "Mythic" or def.rarity == "Brainrot God" or def.rarity == "Secret" then
		for i = -1, 1 do
			local spike = makePart("CrownSpike", Vector3.new(0.28 * scale, 0.55 * scale, 0.28 * scale), Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
			spike.CFrame = head.CFrame * CFrame.new(i * 0.42 * scale, 1.35 * scale, 0)
			spike.Parent = body.Parent
			weldToBody(body, spike)
		end
	end
end

local function startRainbowCycle(body)
	task.spawn(function()
		local hue = math.random()
		while body.Parent do
			hue = (hue + Config.RainbowHueStep) % 1
			body.Color = Color3.fromHSV(hue, 0.65, 1)
			task.wait(0.05)
		end
	end)
end

-- startIdleBob(model): a gentle bob for a brainrot standing on a base pad,
-- so a stocked base feels alive in captures. Ends when the model is removed.
function BrainrotFactory.startIdleBob(model)
	local body = model.PrimaryPart
	if not body then
		return
	end
	task.spawn(function()
		local base = body.CFrame
		local phase = math.random() * math.pi * 2
		while model.Parent do
			phase += 0.09
			model:SetPrimaryPartCFrame(base * CFrame.new(0, math.sin(phase) * 0.12, 0))
			task.wait(0.05)
		end
	end)
end

-- buildBrainrotModel(defName, forcedMutationName) -> Model, income
-- The model carries its stats as Attributes: DefName, Rarity, Mutation,
-- Income, Price. Its PrimaryPart is the Body, standing at the origin and
-- facing +Z; callers place it with SetPrimaryPartCFrame.
function BrainrotFactory.buildBrainrotModel(defName, forcedMutationName)
	local def = Config.getDefByName(defName)
	if not def then
		return nil, 0
	end
	local mutation = nil
	if forcedMutationName then
		mutation = Config.getMutationByName(forcedMutationName)
	else
		mutation = BrainrotFactory.rollMutation()
	end
	local scale = mutation and mutation.scale or 1
	local income = def.income * (mutation and mutation.factor or 1)
	local bodyColor = def.color
	if mutation and mutation.color then
		bodyColor = mutation.color
	end

	local model = Instance.new("Model")
	model.Name = def.name

	local body = makePart("Body", Vector3.new(2.2 * scale, 2.6 * scale, 1.4 * scale), bodyColor)
	body.CanCollide = true
	body.CFrame = CFrame.new(0, 1.3 * scale, 0)
	body.Parent = model
	model.PrimaryPart = body

	local head = makePart("Head", Vector3.new(1.5 * scale, 1.3 * scale, 1.3 * scale), bodyColor)
	head.CFrame = CFrame.new(0, (2.6 + 0.65) * scale, 0)
	head.Parent = model
	weldToBody(body, head)

	for _, side in ipairs({ -0.38, 0.38 }) do
		local eye = makePart("Eye", Vector3.new(0.24 * scale, 0.3 * scale, 0.1 * scale), Color3.fromRGB(15, 15, 15))
		eye.CFrame = CFrame.new(side * scale, (2.6 + 0.75) * scale, 0.68 * scale)
		eye.Parent = model
		weldToBody(body, eye)
	end

	buildProp(body, head, def, scale)
	buildLabel(model, head, def, mutation, income)

	if def.rarity == "Epic" or def.rarity == "Legendary" or def.rarity == "Mythic"
		or def.rarity == "Brainrot God" or def.rarity == "Secret" then
		local glow = Instance.new("PointLight")
		glow.Name = "RarityGlow"
		glow.Color = Config.RarityColors[def.rarity]
		glow.Brightness = 1.2
		glow.Range = 9
		glow.Parent = body
	end

	if mutation and mutation.name == "Rainbow" then
		startRainbowCycle(body)
	end

	model:SetAttribute("DefName", def.name)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Mutation", mutation and mutation.name or "")
	model:SetAttribute("Income", income)
	model:SetAttribute("Price", def.price)

	return model, income
end

return BrainrotFactory
