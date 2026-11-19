-- Game.client.luau (LocalScript, StarterPlayerScripts/Client)
-- Client bootstrap for Warung Brainrot: builds the HUD, wires its buttons
-- to the server remotes, and feeds it the server's state snapshots, toasts
-- and event warnings.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Hud = require(script.Parent:WaitForChild("Hud"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateState = remotes:WaitForChild("UpdateState")
local toastRemote = remotes:WaitForChild("Toast")
local eventWarning = remotes:WaitForChild("EventWarning")
local toggleLock = remotes:WaitForChild("ToggleLock")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local buySlot = remotes:WaitForChild("BuySlot")

local hud = Hud.build({
	onLock = function()
		toggleLock:FireServer()
	end,
	onBuySlot = function()
		buySlot:FireServer()
	end,
	onRebirth = function()
		rebirthRemote:FireServer()
	end,
})

hud.gui.Parent = player:WaitForChild("PlayerGui")

updateState.OnClientEvent:Connect(function(snapshot)
	hud.update(snapshot)
end)

toastRemote.OnClientEvent:Connect(function(text)
	hud.showToast(text)
end)

eventWarning.OnClientEvent:Connect(function(payload)
	hud.showBanner(payload.title, payload.sub, payload.seconds)
end)

-- Keyboard shortcuts for the three buttons, bound through
-- ContextActionService so they never fight the camera keys.
local function bindKey(actionName, keyCode, remote)
	ContextActionService:BindAction(actionName, function(_action, inputState)
		if inputState == Enum.UserInputState.Begin then
			remote:FireServer()
		end
		return Enum.ContextActionResult.Pass
	end, false, keyCode)
end

bindKey("WarungLockBase", Enum.KeyCode.L, toggleLock)
bindKey("WarungBuySlot", Enum.KeyCode.B, buySlot)
bindKey("WarungRebirth", Enum.KeyCode.R, rebirthRemote)
