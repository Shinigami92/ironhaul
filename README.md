# Ironhaul: Veins of Kareth

A first-person mech game set in the lost-origin star system of Kareth. Primarily PvE, with drop-in/drop-out co-op planned. Inspired primarily by **Hawken**, with design notes borrowed from **Armored Core VI**, **Titanfall**, and **Anthem**.

> **Status: very early development.** This repository contains a greybox prototype scaffold. Nothing is playable yet; nothing looks like the long-term art direction yet. The current goal is to prove the core gameplay loop before investing in assets.

## Vision

You are a hauler — a salvager-mercenary piloting a customizable mech through the ruins and frontier zones of the Kareth system. Earth is forgotten. Ore, scrap, and lost technology are the economy. The cockpit is your office. The horizon is full of other mechs who want what you have.

- **Perspective:** first-person cockpit, grounded Hawken-style weight (not AC6-fast).
- **Combat:** heat-gated weapons, thruster-boost mobility, no stagger.
- **Build system:** AC6-style part slots (head / core / arms / legs / weapons). Linear upgrades in v1; depth later.
- **World:** a hub + procedurally generated zones (parameterized terrain + handcrafted POIs).
- **Co-op:** up to 4 players drop-in/drop-out (post-v0.1).
- **Persistence:** local save files + per-platform cloud saves. No central backend.

## Tech

- **Engine:** Godot 4.6, Forward+ renderer, Jolt Physics.
- **Scripting:** GDScript.
- **Networking:** Godot `MultiplayerAPI` with swappable transport (ENet in dev, Steam/EOS peers at publish time).
- **Target platforms:** Windows first, Linux/Mac as Godot makes convenient.

## How to run

1. Install [Godot 4.6](https://godotengine.org/download).
2. Clone this repo.
3. Open `project.godot` in the Godot editor.
4. Press **F5** to run the main scene.

## Roadmap

- **v0.1 (current):** Hub + sandbox arena. One greybox mech, thruster movement, heat-gated weapon, one grunt enemy, basic HUD, scene transitions, local save pipeline.
- **v0.2:** Part-composition system — code assembles mechs at runtime from real 3D part assets (one asset per head / core / arms / legs / weapon slot) rather than from primitives. First real mech parts sourced from friends, community contributions, or AI-generation. Mission-objective scaffolding in the arena.
- **v0.3:** Procedural zones (parameterized terrain + POI placement), materials-to-upgrades hub loop, first pass at cockpit immersion.
- **v0.4+:** Drop-in/drop-out co-op (Godot `MultiplayerAPI`, ENet first, Steam/EOS peers per platform at publish).

## Art direction

The long-term visual target is the grungy, brutalist, atmospheric look of Hawken and Kowloon-dense sci-fi concept art — realistic PBR, heavy volumetric fog, bloom, Hawken-teal / warm-gold color grading. **v0.1 is deliberately greybox** and does not try to achieve that look; it exists to prove the gameplay loop.

## License

[MIT](./LICENSE). See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to help.
