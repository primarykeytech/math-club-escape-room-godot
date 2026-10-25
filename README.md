# Math Club Escape Room (The Vault of Newton)

A modern mathematical escape room game built with **Godot 4**. Designed with atmospheric 16:9 widescreen concept art, dynamic puzzle pools for high replayability, responsive UI theming, native sound design, and a robust answer-validation engine.

---

## Prerequisites

To run or edit this project, you will need:

* **[Godot Engine 4.x](https://godotengine.org/download)** (v4.2 or higher, including v4.7+).
  * Standard official build (no .NET/C# module required; built entirely with GDScript).

---

## How to Run the Game

### Method 1: Using the Godot Editor (Recommended)

1. Launch **Godot Engine**.
2. Click **Import** in the Project Manager.
3. Browse to and select `project.godot` inside this directory:
   ```text
   C:\Users\john\git\math-club-escape-room-godot\project.godot
   ```
4. Click **Import & Edit**.
5. Press <kbd>F5</kbd> (or click the **Play** icon in the upper-right corner) to start the game.

---

### Method 2: From the Command Line / Terminal

You can run the game directly from the terminal without opening the editor:

#### Windows (PowerShell)
```powershell
# Using the installed Godot executable:
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path "C:\Users\john\git\math-club-escape-room-godot"
```

#### Windows (Command Prompt)
```cmd
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path "C:\Users\john\git\math-club-escape-room-godot"
```

#### macOS / Linux
```bash
godot --path "/path/to/math-club-escape-room-godot"
```

---

## Game Controls

| Control | Action |
| :--- | :--- |
| **Typing & [ENTER]** | Submit answers or commands (`start`, `hint`, `next`, `quit`). |
| **[ Submit ] Button** | Submit the code typed in the console. |
| **[ Hint ] Button** | Reveal tiered progressive clues for the active challenge. |
| **[ Next Challenge ]** | Advance to the subsequent chamber upon solving a lock. |
| **[ ⛶ Fullscreen ] / F11 / Alt+Enter** | Toggle between full screen and windowed mode. |
| **[ ✕ Exit ] Button** | Exit the game (Desktop: terminates app; Web: returns to briefing). |

---

## Key Features

* **High-Resolution Widescreen Art (16:9)**: Atmospheric digital illustrations for all chambers, desks, balance scales, mosaics, vault doors, and The Professor.
* **Dynamic Puzzle Database & Replayability**: Decoupled in [`data/escape_room.json`](data/escape_room.json) with 18 distinct challenge variants across 6 stages. Each playthrough randomly selects a fresh variant per stage.
* **Synchronized Cipher Artwork**: Stage 3 automatically synchronizes the visual parchment illustration with the chosen cipher shift and message (`XJJP YMJ AFZQY ITTW`, `ATRUIQ ZNK INGSHKX`, or `YLCLHS AOL HYJOPCL`).
* **Robust Answer Validation**: GDScript regex normalization engine handles case insensitivity, spacing variations, punctuation stripping, and word equivalencies (e.g., `"15 2"` matches `"15 pencils and 2 pens"`).
* **Countdown Timer & Penalties**: 30-minute default vault timer with dynamic 30-second deductions, screen shake, and red alert flashes on wrong guesses.
* **Audio & Music Pipeline**: Looping menacing soundtrack in D minor on briefing and closing screens, with responsive sound effects for keystrokes, submit clicks, error buzzers, and victory fanfares.
* **Web / HTML5 Export Ready**: Uses the `gl_compatibility` rendering backend with responsive `canvas_items` aspect-ratio scaling for seamless export to browser games.

---

## Running Automated Tests

The project includes headless automated test suites to verify puzzle data, validation algorithms, state transitions, and UI flows without opening a window:

```powershell
# Run core validation and question database test suite (32 tests):
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "." -s res://scripts/test_runner.gd

# Run end-to-end UI integration simulation test suite (12 tests):
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "." -s res://scripts/test_ui_sim.gd
```

---

## Project Structure

```text
math-club-escape-room-godot/
├── assets/
│   ├── images/          # High-resolution 16:9 stage & character illustrations
│   └── sounds/          # Background music & synthesized WAV sound effects
├── data/
│   └── escape_room.json # Challenge specifications & multi-variant question pools
├── scenes/
│   └── main.tscn        # Main 16:9 UI layout, HUD, viewport, and audio nodes
├── scripts/
│   ├── answer_validator.gd # Regex-based answer normalization engine
│   ├── escape_room_data.gd # JSON parser and data model
│   ├── game_manager.gd     # State machine, timer, and question randomizer
│   ├── main.gd             # UI presentation, screen shake, and input controller
│   ├── sound_manager.gd    # Audio playback and BGM fade transitions
│   ├── test_runner.gd      # Core unit test suite
│   └── test_ui_sim.gd      # End-to-end headless UI simulation test suite
├── themes/
│   └── modern_escape_theme.tres # Modern dark academic UI theme & styleboxes
├── project.godot        # Godot engine project configuration
└── README.md            # Documentation and setup guide
```
