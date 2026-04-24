# Contributing to Ironhaul

Thanks for being interested. Ironhaul is in very early development — expect significant flux in scope, architecture, and direction. That said, contributions are welcome.

## Before you start

- Read the [README](./README.md) for the vision and v0.1 scope.
- For anything bigger than a small fix, open an issue first so we can align.
- Contributions are accepted under the project's [MIT License](./LICENSE). By opening a pull request, you agree to license your contribution under MIT.
- **Install [Git LFS](https://git-lfs.com/)** (one-time per machine): `git lfs install`. Ironhaul routes binary assets (audio, textures, 3D models — patterns listed in [`.gitattributes`](./.gitattributes)) through LFS so clones stay fast as the asset library grows. Without LFS, the affected files will appear as short text pointers instead of real binaries.

## Tech stack

- **Godot 4.6** (Forward+ renderer, Jolt Physics).
- **GDScript** for all gameplay code.
- Tabs for indentation (Godot default).

## Editor setup

Open `project.godot` in the Godot 4.6 editor to run and debug the game. For script editing you can use Godot's built-in editor or VS Code.

If you use **VS Code with the [godot-tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) extension**, the workspace `.vscode/settings.json` points `godotTools.editorPath.godot4` at the environment variable `GODOT4_EDITOR` so each contributor can provide their own Godot install path without editing a tracked file.

Set it once on your machine:

- **Windows (PowerShell):**
  ```powershell
  [Environment]::SetEnvironmentVariable("GODOT4_EDITOR", "C:\path\to\Godot_v4.6-stable_win64.exe", "User")
  ```
  Close and reopen VS Code afterwards so it picks up the new env var.
- **Windows (GUI):** Start → *Edit environment variables for your account* → New → Name `GODOT4_EDITOR`, Value = full path to the Godot 4.6 executable.
- **Linux / macOS:** add `export GODOT4_EDITOR=/path/to/godot` to `~/.profile` (or your shell's rc file) and restart your terminal.

If you don't use VS Code, you can ignore this — nothing else in the project depends on the variable.

## Art assets

v0.1 is intentionally greybox (primitive meshes only) to prove the gameplay loop before investing in art. Real assets are planned for v0.2+.

If you'd like to contribute art:
- Only **CC0 or CC-BY (with attribution)** assets can be redistributed in this repo.
  - **CC-BY-NC (non-commercial) is not acceptable** — even a free-to-play Steam release counts as commercial distribution.
- Anything you model yourself and contribute is MIT-licensed on merge (unless you'd prefer CC0 for the asset — we can discuss).
- Do not submit assets extracted from commercial games or paid asset packs. The Atlas-G mech and other Titanfall/Hawken/AC6 IP are explicitly off-limits.

## Code style

- Follow Godot's GDScript style guide (tabs, snake_case for variables/functions, PascalCase for classes/nodes, UPPER_SNAKE for constants).
- Prefer composition (child nodes) over inheritance for gameplay systems.
- Keep scripts small and focused on one responsibility.

### Formatting and linting

Ironhaul uses [`gdtoolkit`](https://github.com/Scony/godot-gdscript-toolkit) (specifically `gdformat` and `gdlint`) for GDScript formatting and static analysis. CI runs both on every push and pull request — PRs that don't pass will be blocked.

**One-time install** (requires Python 3.10+ and `pip`):

```bash
pip install "gdtoolkit==4.*"
```

**Run locally before pushing:**

```bash
# Format in place
gdformat .

# Or check without modifying
gdformat --check .

# Lint
gdlint .
```

The `addons/` folder (GUT and any other third-party addons) is excluded via the repo's `gdlintrc` and `gdformatrc` config files — third-party code doesn't need to match our style rules. Add new directories to `excluded_directories` in both files if you ever need to exclude another.

### Running tests

Tests use [GUT (Godot Unit Test)](https://github.com/bitwes/Gut). The addon lives in `addons/gut/` and is enabled by default in `project.godot`. Test files live under `tests/` (convention: `tests/unit/test_<subject>.gd`).

**In the Godot editor:** open the GUT panel at the bottom of the editor → click *Run All*.

**From the terminal:**

```bash
"$GODOT4_EDITOR" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Replace `$GODOT4_EDITOR` with the full path to your Godot 4.6 executable if the env var isn't set (see [Editor setup](#editor-setup)).

CI runs the same invocation on every push and pull request — PRs with failing tests are blocked.

We currently rely on gdtoolkit's defaults (no `.gdlintrc` in the repo). When a default rule actively hurts us, add a `.gdlintrc` at the project root and override the rule there — don't disable rules per file.

Optional editor integration:
- **VS Code:** the [godot-tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) extension can call `gdformat` on save if Python and `gdtoolkit` are on your `PATH`.
- **Godot editor:** no built-in formatter hook; run `gdformat` from the terminal before committing.

## How to contribute

1. Fork the repo.
2. Create a feature branch.
3. Make your change with a clear, focused commit history.
4. Open a pull request with a short description of what and why.

## Questions?

Open a GitHub issue.
