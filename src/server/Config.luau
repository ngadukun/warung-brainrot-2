-- Config.luau (ModuleScript, ServerScriptService)
-- Every tuning number and the whole brainrot cast for Warung Brainrot lives
-- here, so the services below never hard-code a balance value.

local Config = {}

-- Economy
Config.StartCash = 150
Config.TickSeconds = 1

-- Conveyor
Config.SpawnInterval = 4
Config.MaxOnBelt = 8
Config.BeltSpeed = 3 -- studs per second
Config.BeltStartZ = -28
Config.BeltEndZ = 28
Config.BeltTopY = 1.1 -- height of the belt surface the brainrots stand on

-- Bases and slots
Config.StartSlots = 6
Config.MaxSlots = 10
Config.SlotBasePrice = 500 -- slot n costs SlotBasePrice * 2 ^ (n - StartSlots - 1 + 1)

-- Stealing and locking
Config.LockDuration = 20
Config.LockCooldown = 60
Config.StealHoldTime = 2.5
Config.BuyDistance = 14

-- Events
Config.EventInterval = 100
Config.KrupukWarningSeconds = 5
Config.DiscoDuration = 30
Config.DiscoFactor = 2

-- Rebirth
Config.RebirthThreshold = 25000
Config.RebirthStep = 0.5

-- Rarity display colours (pad rings, label text)
Config.RarityColors = {
	Common = Color3.fromRGB(205, 205, 205),
	Rare = Color3.fromRGB(85, 170, 255),
	Epic = Color3.fromRGB(190, 95, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 105, 180),
	["Brainrot God"] = Color3.fromRGB(165, 85, 255),
	Secret = Color3.fromRGB(70, 220, 255),
}

-- The cast: name, rarity, income ($/second), buy price, spawn weight, body colour.
Config.Cast = {
	{ name = "Krupuk Terbang", rarity = "Common", income = 2, price = 30, weight = 28, color = Color3.fromRGB(245, 238, 215) },
	{ name = "Es Teh Manis", rarity = "Common", income = 4, price = 75, weight = 20, color = Color3.fromRGB(196, 138, 74) },
	{ name = "Klepon Gemas", rarity = "Common", income = 6, price = 120, weight = 16, color = Color3.fromRGB(96, 186, 92) },
	{ name = "Gorengan Sakti", rarity = "Rare", income = 9, price = 200, weight = 12, color = Color3.fromRGB(240, 190, 60) },
	{ name = "Kopi Tubruk Titan", rarity = "Rare", income = 15, price = 450, weight = 9, color = Color3.fromRGB(96, 58, 32) },
	{ name = "Nasi Padang Raksasa", rarity = "Epic", income = 30, price = 1000, weight = 6, color = Color3.fromRGB(214, 48, 38) },
	{ name = "Becak Terbang", rarity = "Epic", income = 55, price = 2200, weight = 4, color = Color3.fromRGB(38, 178, 160) },
	{ name = "Komodo Berkepala Dua", rarity = "Legendary", income = 110, price = 5000, weight = 2.6, color = Color3.fromRGB(110, 140, 70) },
	{ name = "Garuda Emas", rarity = "Mythic", income = 250, price = 12000, weight = 1.4, color = Color3.fromRGB(255, 205, 45) },
	{ name = "Rendang Dewa", rarity = "Mythic", income = 380, price = 20000, weight = 0.6, color = Color3.fromRGB(120, 28, 34) },
	{ name = "Kujang Petir", rarity = "Brainrot God", income = 600, price = 30000, weight = 0.3, color = Color3.fromRGB(138, 80, 235) },
	{ name = "Tung-Tung Sahur", rarity = "Secret", income = 1500, price = 75000, weight = 0.1, color = Color3.fromRGB(32, 52, 110) },
}

-- Mutations rolled at spawn: income factor, body scale, label symbol.
Config.Mutations = {
	{ name = "Gold", chance = 0.08, factor = 2, scale = 1.15, symbol = "★", color = Color3.fromRGB(255, 214, 64) },
	{ name = "Diamond", chance = 0.03, factor = 5, scale = 1.3, symbol = "◆", color = Color3.fromRGB(120, 235, 255) },
	{ name = "Rainbow", chance = 0.005, factor = 10, scale = 1.45, symbol = "✦", color = nil },
}

-- Warung stall names for the market decoration.
Config.StallNames = {
	"WARUNG TEH", "SATE MADURA", "BAKSO SOLO", "MIE AYAM",
	"ES KELAPA", "TAHU BULAT", "SOTO LAMONGAN", "NASI GORENG",
}

-- Lampu Disko: the colours the market lights cycle through, and how far a
-- Rainbow brainrot's hue advances each cycle step.
Config.DiscoPalette = {
	Color3.fromRGB(255, 90, 160), Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(255, 220, 80), Color3.fromRGB(140, 255, 140),
	Color3.fromRGB(200, 120, 255),
}
Config.RainbowHueStep = 0.01

function Config.getDefByName(name)
	for _, def in ipairs(Config.Cast) do
		if def.name == name then
			return def
		end
	end
	return nil
end

function Config.getMutationByName(name)
	for _, mutation in ipairs(Config.Mutations) do
		if mutation.name == name then
			return mutation
		end
	end
	return nil
end

function Config.slotPriceFor(slotCount)
	-- Price of the next slot when the player already owns slotCount slots.
	if slotCount >= Config.MaxSlots then
		return nil
	end
	return Config.SlotBasePrice * 2 ^ (slotCount - Config.StartSlots)
end

return Config
