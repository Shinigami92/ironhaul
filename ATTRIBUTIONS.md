# Third-party asset attributions

Ironhaul is MIT-licensed, but it bundles third-party assets under their own (permissive) licenses. This file tracks every such asset, its license, its source, and where it lives in the repo.

## Audio

Audio files are organized under `audio/sfx/` **by purpose** (`weapons/`, `movement/`). License texts for each source live in `audio/sfx/LICENSES/`. Files are renamed to semantic names; original upstream filenames are shown in parentheses for provenance.

### Kenney — Sci-Fi Sounds (1.0) — CC0

- License: [CC0 1.0 Universal (Public Domain)](http://creativecommons.org/publicdomain/zero/1.0/)
- Source: <https://kenney.nl/assets/sci-fi-sounds>
- License text: [`audio/sfx/LICENSES/kenney.txt`](./audio/sfx/LICENSES/kenney.txt)
- Files used:
  - `audio/sfx/weapons/primary_fire.ogg` *(from `laserSmall_000.ogg`)* — player primary weapon fire
  - `audio/sfx/weapons/secondary_fire.ogg` *(from `laserLarge_000.ogg`)* — player secondary weapon fire
  - `audio/sfx/weapons/enemy_fire.ogg` *(from `laserRetro_000.ogg`)* — enemy weapon fire
  - `audio/sfx/weapons/impact.ogg` *(from `impactMetal_000.ogg`)* — weapon hit impact
  - `audio/sfx/movement/thruster_burst.ogg` *(from `lowFrequency_explosion_001.ogg`)* — thruster dodge burst

### Pixabay

- License: [Pixabay Content License](https://pixabay.com/service/license-summary/) — free for commercial use, no attribution required, redistribution inside derivative works permitted.
- License text: [`audio/sfx/LICENSES/pixabay.txt`](./audio/sfx/LICENSES/pixabay.txt)
- Files used:
  - `audio/sfx/movement/footstep.mp3` — mech footstep
    - Title: "Film Special Effects - Heavy Walking Footsteps"
    - Author: **universfield**
    - Source: <https://pixabay.com/sound-effects/film-special-effects-heavy-walking-footsteps-352771/>
  - `audio/sfx/movement/thruster_loop.mp3` — thruster hold loop
    - Title: "Horror Continuous Bass Rumble"
    - Author: **thestoryrug**
    - Source: <https://pixabay.com/sound-effects/horror-continuous-bass-rumble-336529/>

## Code / Libraries

### GUT (Godot Unit Test)

- License: MIT
- Source: <https://github.com/bitwes/Gut>
- Location in repo: [`addons/gut/`](./addons/gut/) (vendored; marked `linguist-vendored=true` for GitHub stats)
