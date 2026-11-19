-- Hud.luau (ModuleScript, StarterPlayerScripts/Client)
-- Builds the whole ScreenGui: a centred top bar (cash, income, rebirths),
-- the three action buttons, the next-event chip, the centre event banner,
-- the toast and the hint line. Nothing sits in the top-left corner, where
-- Roblox's own menu button lives. Text stays big: it must read at 768x480.

local Hud = {}

local function formatMoney(value)
	local digits = tostring(math.floor(value))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1."):reverse()
	grouped = grouped:gsub("^%.", "")
	return "$" .. grouped
end

local function makeLabel(parent, name, size, position, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Text = ""
	label.Parent = parent
	return label
end

local function makeButton(parent, name, position, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(168, 44)
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
	button.BackgroundTransparency = 0.15
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Parent = parent
	return button
end

-- Hud.build(callbacks) -> hud
-- callbacks = { onLock = fn, onBuySlot = fn, onRebirth = fn }
function Hud.build(callbacks)
	local gui = Instance.new("ScreenGui")
	gui.Name = "WarungHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 8)
	topBar.Size = UDim2.fromOffset(600, 56)
	topBar.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
	topBar.BackgroundTransparency = 0.25
	topBar.BorderSizePixel = 0
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 12)
	barCorner.Parent = topBar
	topBar.Parent = gui

	local cashLabel = makeLabel(topBar, "Cash", UDim2.new(0, 210, 1, 0), UDim2.new(0, 16, 0, 0), 27, Color3.fromRGB(150, 255, 160), Enum.Font.GothamBlack)
	cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	local incomeLabel = makeLabel(topBar, "Income", UDim2.new(0, 230, 1, 0), UDim2.new(0, 226, 0, 0), 21, Color3.fromRGB(255, 255, 255))
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Center
	local rebirthLabel = makeLabel(topBar, "Rebirths", UDim2.new(0, 130, 1, 0), UDim2.new(1, -146, 0, 0), 21, Color3.fromRGB(255, 210, 120))
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.AnchorPoint = Vector2.new(0.5, 0)
	buttonRow.Position = UDim2.new(0.5, 0, 0, 74)
	buttonRow.Size = UDim2.fromOffset(540, 44)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = gui

	local lockButton = makeButton(buttonRow, "LockButton", UDim2.new(0, 0, 0, 0), "Kunci Base")
	local slotButton = makeButton(buttonRow, "SlotButton", UDim2.new(0, 186, 0, 0), "Beli Slot")
	local rebirthButton = makeButton(buttonRow, "RebirthButton", UDim2.new(0, 372, 0, 0), "Rebirth")
	lockButton.Activated:Connect(callbacks.onLock)
	slotButton.Activated:Connect(callbacks.onBuySlot)
	rebirthButton.Activated:Connect(callbacks.onRebirth)

	local chip = Instance.new("TextLabel")
	chip.Name = "EventChip"
	chip.AnchorPoint = Vector2.new(1, 0)
	chip.Position = UDim2.new(1, -10, 0, 74)
	chip.Size = UDim2.fromOffset(250, 36)
	chip.BackgroundColor3 = Color3.fromRGB(16, 18, 30)
	chip.BackgroundTransparency = 0.3
	chip.BorderSizePixel = 0
	chip.Font = Enum.Font.GothamBold
	chip.TextSize = 18
	chip.TextColor3 = Color3.fromRGB(255, 225, 150)
	chip.Text = ""
	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0, 9)
	chipCorner.Parent = chip
	chip.Parent = gui

	local banner = Instance.new("Frame")
	banner.Name = "EventBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 150)
	banner.Size = UDim2.fromOffset(640, 120)
	banner.BackgroundColor3 = Color3.fromRGB(120, 20, 30)
	banner.BackgroundTransparency = 0.2
	banner.BorderSizePixel = 0
	banner.Visible = false
	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 14)
	bannerCorner.Parent = banner
	banner.Parent = gui
	local bannerTitle = makeLabel(banner, "BannerTitle", UDim2.new(1, 0, 0, 66), UDim2.new(0, 0, 0, 8), 46, Color3.fromRGB(255, 240, 170), Enum.Font.GothamBlack)
	local bannerSub = makeLabel(banner, "BannerSub", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 74), 24, Color3.fromRGB(255, 255, 255))

	local carryLabel = makeLabel(gui, "Carrying", UDim2.new(0, 640, 0, 34), UDim2.new(0.5, -320, 0, 126), 20, Color3.fromRGB(255, 170, 220))
	carryLabel.Visible = false

	local toast = makeLabel(gui, "Toast", UDim2.new(0, 460, 0, 44), UDim2.new(1, -470, 1, -58), 21, Color3.fromRGB(255, 255, 255))
	toast.TextXAlignment = Enum.TextXAlignment.Right
	toast.Visible = false

	local hint = makeLabel(gui, "Hint", UDim2.new(0, 700, 0, 30), UDim2.new(0.5, -350, 1, -36), 18, Color3.fromRGB(220, 220, 220))
	hint.Text = "Dekati brainrot lalu tekan E untuk Beli / Curi — kunci base-mu sebelum diserang!"

	local hud = { gui = gui, bannerToken = 0, toastToken = 0 }

	function hud.update(snapshot)
		cashLabel.Text = formatMoney(snapshot.cash)
		local incomeText = formatMoney(snapshot.incomePerSecond) .. "/detik"
		if snapshot.multiplier and snapshot.multiplier > 1 then
			incomeText ..= "  (x" .. tostring(snapshot.multiplier) .. ")"
		end
		incomeLabel.Text = incomeText
		rebirthLabel.Text = "Rebirth: " .. tostring(snapshot.rebirths)
		if snapshot.lockLeft > 0 then
			lockButton.Text = "TERKUNCI " .. snapshot.lockLeft .. "d"
		elseif snapshot.lockCooldownLeft > 0 then
			lockButton.Text = "Kunci (" .. snapshot.lockCooldownLeft .. "d)"
		else
			lockButton.Text = "Kunci Base"
		end
		if snapshot.slotPrice then
			slotButton.Text = "Beli Slot " .. formatMoney(snapshot.slotPrice)
		else
			slotButton.Text = "Slot MAX"
		end
		rebirthButton.Text = snapshot.canRebirth and "REBIRTH!" or "Rebirth"
		if snapshot.carryingName then
			carryLabel.Text = "Membawa " .. snapshot.carryingName .. " — lari pulang ke base!"
			carryLabel.Visible = true
		else
			carryLabel.Visible = false
		end
		if snapshot.activeEventName == "disco" then
			chip.Text = "LAMPU DISKO aktif! " .. snapshot.activeEventLeft .. "d"
		elseif snapshot.activeEventName == "krupuk" then
			chip.Text = "HUJAN KRUPUK datang!"
		else
			chip.Text = "Event berikut: " .. snapshot.nextEventName .. " • " .. snapshot.nextEventIn .. "d"
		end
	end

	function hud.showBanner(title, sub, seconds)
		hud.bannerToken += 1
		local token = hud.bannerToken
		bannerTitle.Text = title
		bannerSub.Text = sub or ""
		banner.Visible = true
		task.delay(math.max(2, seconds or 3), function()
			if hud.bannerToken == token then
				banner.Visible = false
			end
		end)
	end

	function hud.showToast(text)
		hud.toastToken += 1
		local token = hud.toastToken
		toast.Text = text
		toast.Visible = true
		task.delay(3, function()
			if hud.toastToken == token then
				toast.Visible = false
			end
		end)
	end

	return hud
end

return Hud
