# Warung Brainrot

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ngadukun/warung-brainrot-2/rank.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ngadukun/warung-brainrot-2/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Rebut, kumpul, kaya — di pasar malam paling absurd sedunia.**

Warung Brainrot is a 3D Roblox brainrot game set in a neon Indonesian night
market. Absurd food-born characters ride the central conveyor; buy them,
walk them home to your base plot, and watch the money tick in every second.
Climb a ladder of twelve characters across seven rarities — from Krupuk
Terbang to the Secret Tung-Tung Sahur — with Gold, Diamond and Rainbow
mutations multiplying what they earn.

Defend your base with a timed lock, or hold E on a rival's brainrot and run
it home on your head. Every hundred seconds the market turns on you:
**Hujan Krupuk** sweeps a storm wave across the map and knocks anyone caught
outside back to spawn, and **Lampu Disko** doubles everyone's income under
cycling disco lights. Earn $25,000 in total to rebirth for a permanent +50%
income multiplier, and buy up to ten base slots as prices climb.

## How to play

1. Brainrots ride the conveyor down the middle of the market. Walk up to one
   and press **E** to buy it; it walks home to your coloured base plot.
2. Every brainrot on your pads pays its $/detik into your cash each second.
   Rarer brainrots and Gold (x2), Diamond (x5) and Rainbow (x10) mutations
   pay far more.
3. Hold **E** on a brainrot in someone else's base to steal it — then run it
   home before the **Hujan Krupuk** wave or its owner catches you. Lock your
   own base (button, or **L**) before you wander off.
4. Buy more slots (**B**), survive the events, and at $25,000 total earned,
   rebirth (**R**) for a permanent income multiplier.

## The game

- `src/server/` — one module per job: `Config` (the cast and every tuning
  number), `PlayerState` (the single state store), `BrainrotFactory`,
  `WorldBuilder` (the whole night market), `ConveyorService`,
  `EconomyService`, `BaseService`, `StealService`, `EventService`,
  `RebirthService` and `TourHelper`, bootstrapped by `Main.server.luau`.
- `src/client/` — `Game.client.luau` wires the remotes to `Hud`, the
  ScreenGui with the cash bar, action buttons, event chip, banner and toast.
- `default.project.json` — the Rojo project; `game.rbxl` is built from it
  with `rojo build default.project.json --output game.rbxl`.
- `main.ts` (Node 22, standard library only) hands the entry in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output folder
  and writes `dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy,
  unchanged.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

An entry for make.fun's
[roblox-brainrot-01](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
bounty.
