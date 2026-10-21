# Touch Grass: The Hollow Chronicle
## Game Design Document and Agent Implementation Guide (v3, Godot)

> **Purpose:** This is the single source of truth for building the game in **Godot** with an AI coding agent (Claude Code, Antigravity, or similar). It contains the story, the build order, the art direction, the asset hand-off rules, the Godot architecture, and the acceptance criteria. Read it completely before touching the project.
>
> **Status of names:** Character names (Arjun, Kitsu, Aaji) are working names. Keep them in one data file so they can be changed later.
>
> **Scope note:** This is a Godot desktop game. It is **not** a web game and does not run on localhost. Do not add npm, Vite, Phaser, React, or any browser tooling.

---

## 0. How the agent should use this document

1. Read this file completely, then audit the existing Godot project (Phase 0) before writing code.
2. Continue the existing project. Do not start a new one or restructure it without a reason.
3. Build in the order given in Section 14. Do not start a later phase until the previous exit criteria pass.
4. Use the assets the project owner supplies (Section 6). Never invent asset filenames, never stretch art, and label every placeholder.
5. When something is unknown, inspect the project or ask one focused question. Do not silently invent a conflicting implementation.
6. Keep this file updated when decisions change.

---

## 1. Project snapshot and decisions

| Item | Value |
|---|---|
| Genre | Story-driven action RPG with light combat and exploration |
| Presentation | Top-down / 2.5D pixel art, similar in look and feel to Stardew Valley |
| First deliverable | A playable vertical slice: prologue, tutorial, village defense, elder scene, castle cutscene |
| Engine | **Godot 4.x**, GDScript (read the exact version from `project.godot` and match it) |
| Platform | Desktop first. Web or mobile export is not a goal |
| Existing work | An unfinished Godot project already exists. Build on it |
| Art baseline | Tiny Swords tileset plus the project's own character sprites |

### Decisions

| Decision | Current choice | Status |
|---|---|---|
| Language | Typed GDScript | Decided |
| Map authoring | Godot `TileMapLayer` (or `TileMap` on older 4.x). Agent proposes whether maps are painted by the owner in the editor or built from a layout file by script | Confirm in Phase 0 |
| Cutscenes | Data-driven runner (steps defined in data, played by one node) | Required, see Section 4 |
| Regions beyond the slice | Roadmap only, not part of the first build | Decided |

---

## 2. Story

### 2.1 Premise

Arjun is a young corporate employee who is completely burned out. Haunted by a dream of a village being destroyed, he finally takes a break and travels to his grandparents' village. There he finds a book under his childhood bed that pulls him into **the Hollow**, a world that turns out to be the village from his dream, and it is in danger.

### 2.2 Characters (working names)

- **Arjun:** the player character. Young, exhausted, kind. Visual reference: brown spiky hair, light-blue shirt, blue pants, chibi proportions (see the supplied sprite).
- **Aaji:** his grandmother. Warm, cooks, waits at the door. (A grandfather can be added if the owner confirms.)
- **Kitsu:** a small fox-like guide spirit with glowing paws. Explains the world and combat, and leads Arjun to the village.
- **The Elder:** the village elder in the Hollow. Names Arjun the hero and explains the Monster King.
- **Villagers:** a handful of frightened NPCs in the Hollow village.
- **Monsters:** the Monster King's creatures that attack the village.
- **The Monster King:** the main antagonist, who lives in a castle floating in the sky. He never appears in person in the first slice.

### 2.3 Story beats (the first slice)

**Act 0: Prologue (non-interactive cutscene, skippable)**

1. **The dream.** Red-tinted sky. A village burns while monsters rampage. In the distance a dark castle floats in the sky. The scene cuts to Arjun waking up in his apartment, gasping.
2. **The office.** Desaturated grey. His inbox shows 412 unread emails. A notification reads "Quick sync? 9:47 PM". He closes the laptop. Caption: "He hadn't seen the sky in three weeks."
3. **The bus.** Side view from inside a bus. The city scrolls past and slowly turns into fields. Color returns gradually.
4. **The village (real world).** Sunset. A creaky gate, a neem tree, his grandparents' house. Aaji waits at the door.
5. **The room.** Day three. He looks for a spare blanket and finds a book wrapped in saffron cloth under his childhood bed. Ink writes across the first page: "You have been away too long. The Hollow remembers you." Light pours out, a white flash, he is pulled in.
6. **Title card.** "Touch Grass: The Hollow Chronicle". Gameplay begins.

**Act 1: Awakening and tutorial**

- Arjun wakes in a clearing in the Whispering Woods (the forest map). Two moons, floating lanterns.
- Kitsu introduces itself and explains the Hollow in short lines.
- Kitsu teaches movement, interaction, and combat in order, using safe practice targets and then one or two weak monsters.
- Kitsu says a village nearby needs help and leads him along the forest path.

**Act 2: The village is attacked**

- Arriving at Mossveil Village, the player finds it under attack. This is the village from the dream.
- The player fights waves of monsters with Kitsu's help. Optional: a stronger mini-boss for the last wave (owner to confirm).
- Flags track the attack start, wave progress, and the village being saved.

**Act 3: The hero and the Monster King**

- The Elder names Arjun a hero and explains who the Monster King is and what he wants (details to be written with the owner).
- Short cutscene: the camera pans up to a monster castle floating in the sky. End of the vertical slice with a "to be continued" hook.

### 2.4 Theme

Burnout and rest. The real world is grey and rushed, the Hollow gets its color back as Arjun helps it. Reflect this through palette changes, not long dialogue. A "Focus vs Rest" combat mechanic is a **proposed idea** only. Do not build it until the owner confirms.

### 2.5 Dialogue drafts (placeholders, owner will refine)

- Kitsu: "Finally. You're late, Reader."
- Kitsu: "This is the Hollow. The book wrote it into being, and it needs you."
- Kitsu: "Try moving first. Then we will talk about the monsters."
- Elder: "You saved us. From today, you are our hero."
- Elder: "The Monster King watches from his castle in the sky."

---

## 3. Game flow and scenes

| # | Scene | Type | Notes |
|---|---|---|---|
| 1 | Dream | Cutscene | Red palette, burning village, floating castle silhouette |
| 2 | Apartment (wake up) | Cutscene | Short |
| 3 | Office | Cutscene | Desaturated, inbox, notification |
| 4 | Bus | Cutscene | Parallax, city to fields, color returns |
| 5 | Grandparents' village | Cutscene | Gate, neem tree, house, Aaji |
| 6 | Grandparents' room | Cutscene | Book, ink text, flash |
| 7 | Title card | Cutscene | Then game starts |
| 8 | Whispering Woods | Playable | Tutorial, Kitsu, practice targets, first monsters |
| 9 | Mossveil Village | Playable | Village under attack, wave defense |
| 10 | Elder scene | Dialogue | Hero title, Monster King explained |
| 11 | Floating castle | Cutscene | End of slice |

Scenes 1 to 7 and 11 all run in the same cutscene system. Real-world scenes (apartment, office, bus, grandparents' house) need non-fantasy art, see Section 6.3.

---

## 4. Prologue and cutscene system

The prologue is the first thing to build. It also creates the cutscene system reused later (castle cutscene, story moments).

### Requirements

- **Data-driven.** Each scene is an array of steps (for example `show_background`, `move_sprite`, `tween`, `caption`, `fade`, `tint`, `wait`, `shake`, `play_sound`, `flash`). One `CutsceneRunner` node plays them in order using `Tween` and signals. Story content lives in data files, not in engine code.
- **Skippable.** The player can skip the whole prologue (Enter or Escape, with a visible prompt). Skipping must land in the game with a correct state.
- **Captions.** A bottom text band, line by line, readable on any background. Reuse the same dialogue component later for NPC dialogue.
- **Palette effects.** A screen-space saturation or tint control (for example a `CanvasLayer` with a `ColorRect` and a canvas shader, or `CanvasModulate`) so the office is grey and the bus slowly regains color.
- **Transitions.** Fade to black between scenes, and a white flash for the book transfer.
- **Consistent character.** The same Arjun sprite used in gameplay must appear in cutscenes, scaled consistently with the art direction.
- **Length.** About 60 to 75 seconds in total.
- **Hand-off.** A finished prologue changes to the Whispering Woods scene with the correct spawn and sets `prologue_complete`.

### Prologue acceptance criteria

- [ ] All seven prologue scenes play in order with no missing assets.
- [ ] Skip works at any point and lands in the game with a correct state.
- [ ] Captions never overflow the screen at common window sizes.
- [ ] The color change between office and village is visibly gradual.
- [ ] The flash and title card lead directly into gameplay.
- [ ] No errors or warnings in the Godot output panel.

---

## 5. Visual direction (Stardew-style)

"Similar to Stardew Valley" means:

- Top-down 3/4 view, warm saturated palette, readable silhouettes, soft shadows under characters and props.
- Tile-based worlds with layered ground, paths, nature, props, and foreground.
- **Y-sorted drawing:** things lower on the screen draw on top of things higher up, so the player walks behind and in front of trees correctly. Use `y_sort_enabled` and place each entity's origin at its feet.
- A friendly HUD (health bar, small icons) and a dialogue box with speaker name and portrait space.
- It does **not** mean farming, crafting, or a calendar. Those are out of scope.

### Hard rules

1. Determine the real source tile size from the asset files. Do not guess.
2. Choose one base resolution and render it at an **integer** scale. Use `canvas_items` or `viewport` stretch mode with integer scaling, set from the measured tile size.
3. Set the default texture filter to **Nearest** and disable mipmaps on pixel art imports.
4. Enable pixel snapping for 2D transforms. Check the camera for jitter or shimmer when it follows the player.
5. Never stretch or squash tilesets or sprites. Preserve aspect ratio.
6. Keep all sprites at one consistent scale relative to the tiles.
7. Keep the same outline style and palette discipline across regions.

### Scale warning (verify early)

The supplied character sprite is small and chibi (roughly 12 by 16 source pixels in the preview). The official Tiny Swords terrain tiles and units are much larger (64 px tiles and large unit frames). The supplied forest screenshots also look like a different art source than the stock Tiny Swords pack. In Phase 0 the agent must measure all of these, report any mismatch, and propose one consistent approach, for example an integer rescale or using the forest art as the visual target. Do not mix scales silently.

---

## 6. Assets and hand-off

### 6.1 Rules

- The project owner will provide the assets. The agent must **use them** and must not replace them with generated art.
- Search the project for assets before creating anything. List what exists in Phase 0.
- Keep asset paths in one place (for example an `Assets.gd` constants script or an autoload). No hard-coded `res://` paths scattered across scripts.
- Missing asset: use a clearly named placeholder (for example a flat colored rectangle named `PLACEHOLDER_fox`), list it in `MISSING_ASSETS.md`, and continue.
- Do not edit or overwrite the original asset files. Use import settings for pixel art: filter Nearest, no mipmaps, lossless.
- Keep a `CREDITS.md` for Tiny Swords and any other source, and check licenses.

### 6.2 Asset inventory (owner to update)

| Asset | Status | Notes |
|---|---|---|
| Arjun player sprite | Provided | Front, back, side, and attack animations in the Godot project (`SpriteFrames`). Left and right may share a side animation (flip). Verify exact names |
| Tiny Swords tileset | Provided | Terrain, buildings, trees, props, units. Verify tile size |
| Forest map references | Provided | Two forest and pond screenshots with dirt paths, cliffs, mushrooms, a dock. Visual target for Whispering Woods |
| Kitsu (fox guide) sprites | To be provided | Idle and walk at minimum |
| Elder and villager sprites | To be provided | Tiny Swords units can be used temporarily |
| Aaji sprite | To be provided | Cutscene only |
| Monster sprites | To be provided | At least one basic enemy, optionally a mini-boss |
| Real-world art | To be provided | See 6.3 |
| UI (dialogue box, hearts, buttons) | To be provided | Agent may build simple clean placeholders |
| Audio | Optional | Add later |

### 6.3 Real-world scenes need their own art

Tiny Swords is medieval fantasy. The apartment, office, bus, and grandparents' house are modern or rural India. The owner will supply that art, or approve simple placeholder pixel art for the prologue. Build the prologue so each background is a swappable asset.

---

## 7. World and regions

### 7.1 First slice

**Whispering Woods (start of gameplay)**
- Arrival point and tutorial space, based on the forest reference art.
- Winding dirt paths, pines and bushes, mushrooms, rocks, a pond with a dock, cliffs.
- A clear main route from the arrival clearing to Mossveil Village, with a few small optional branches.
- A sign or Kitsu itself points the way.
- Spawn: arrival clearing. Exit: village approach.

**Mossveil Village**
- The attacked village. Houses, paths, a central square, villager spots, and enemy spawn points at the edges.
- Open space so combat is readable, with obstacles that do not trap the player.
- The Elder's spot is near the center.
- Spawn: village entrance. Includes defined wave spawn points.

### 7.2 World connection rules

- Each region is its own scene with an explicit entry and exit marker (`Marker2D`), tested from both sides.
- Scene changes go through one `SceneManager` autoload. Transitions preserve health, inventory, and quest flags. Do not reset the player on every transition.
- Prevent walking off the map or through blocked scenery.
- Build maps on one shared grid. When extending a map, create a matching continuation. Do not scale or redraw the original.
- Collision shapes must match the visible obstacles. Use TileSet physics layers for terrain and `StaticBody2D` for props.

### 7.3 Later roadmap (after the slice)

These come from the earlier concept and should be reviewed against the Monster King story before building: Clockwork Bazaar, Hollow Peaks, Glass City of Meetings, The Unraveling, The Blank Page. Do not build them in the first slice.

---

## 8. Player, movement, and input

### Capabilities

- Move in four directions (diagonal only if the vector is normalized).
- Correct idle and walk animation per facing direction. Preserve the last facing while idle.
- Attack with the keyboard, using the attack animation for the current facing.
- Interact with NPCs, signs, and exits.
- Take damage with a short, readable invulnerability window.

### Implementation notes

- The player is a `CharacterBody2D` using `move_and_slide()` in `_physics_process`.
- Animations come from the existing `AnimatedSprite2D` and `SpriteFrames`. Use the real animation names found in the project, which are likely `front`, `back`, `side`, `front_attack`, `back_attack`, `side_attack`. Do not assume any animation exists. If left and right share a side animation, flip horizontally.
- Define actions in the Input Map (not raw key checks): `move_up`, `move_down`, `move_left`, `move_right`, `attack`, `interact`, `pause`, `skip`.

### Default input

| Action | Default |
|---|---|
| Move | WASD or Arrow Keys |
| Attack | Q |
| Interact / Confirm | E or Space |
| Pause | Escape |
| Skip cutscene | Enter or Escape (shown on screen) |

Controls must be documented and remappable where practical. Do not bind one key to conflicting actions.

### Movement requirements

- Same speed in every direction. Use `Input.get_vector()` and normalize.
- Collide correctly against obstacles and map bounds.
- No animation flicker on rapid direction changes.
- The attack animation must finish or be interrupted by one explicit rule, never stick on one frame.
- Camera: `Camera2D` with limits set per map, and smoothing only if it does not cause pixel jitter.

---

## 9. Combat

Start simple. Extend only after movement and animation are stable.

### Core loop

1. Player presses `attack` (Q).
2. The directional attack animation plays.
3. An `Area2D` hitbox in front of the player is enabled for a short window.
4. Each enemy hurtbox inside it takes damage once per swing.
5. The hitbox is disabled when the attack window ends (use `set_deferred` for `monitoring` or shape toggles).
6. The player returns to idle or walk.

### Rules

- No attack every frame while the key is held, unless repeat attacks are intentional.
- Cooldown or state gate to prevent accidental repeats. Use a small state machine (`IDLE`, `WALK`, `ATTACK`, `HURT`, `DEAD`).
- The hitbox matches facing and never hits enemies behind the player.
- One hit per enemy per swing (track hit targets for the current swing).
- Clear feedback for hits, enemy defeat, and player damage (flash, small knockback, sound or particle).
- Combat values (damage, cooldown, reach, health) live in a config `Resource` or data file, not scattered constants.
- Use named physics layers: `world`, `player`, `enemy`, `player_hitbox`, `enemy_hitbox`, `interactable`.

### Enemy baseline

Spawn position, collision bounds, simple movement, detection range, health, damage, defeat state, and a safe way to disable collision and free the enemy after defeat. Do not build complex AI before the player loop is dependable.

### Tutorial combat (Act 1)

Kitsu teaches in order: move, interact, attack a practice target, then fight one or two weak monsters. Each step unlocks only when the previous step is done.

### Village defense (Act 2)

- Several short waves, each spawning a few monsters from defined points.
- Protecting villagers is not required in the first version unless the owner confirms.
- Defense succeeds when all waves are cleared. Failure shows a simple retry.
- Track progress with flags (Section 10).

---

## 10. NPCs, dialogue, and story state

### Interaction flow

1. Find the nearest eligible target in range (an `Area2D` interaction zone).
2. Show a prompt such as "E - Talk".
3. Open the dialogue.
4. Block movement and attack input while dialogue is open.
5. Advance with a predictable key, one line per press.
6. Update flags only when the event actually happens.

### Dialogue requirements

Short early lines, speaker names, line-by-line advance (typewriter effect optional), readable against any background, one consistent close rule. Build the dialogue UI on a `CanvasLayer` with `Control` nodes. A cutscene caption and an NPC dialogue box can share one component.

### Persistent state

Keep persistent state in one autoload (for example `GameState`): current region and spawn, health, inventory, quest flags, defeated enemies if needed, and story milestones. Do not rely on scene nodes as the only storage for progress that must survive a scene change.

### Suggested flags

`prologue_complete`, `met_kitsu`, `tutorial_move_done`, `tutorial_interact_done`, `tutorial_attack_done`, `first_monsters_defeated`, `reached_village`, `village_attack_started`, `wave_1_cleared`, `wave_2_cleared`, `wave_3_cleared`, `village_saved`, `elder_spoke`, `castle_cutscene_seen`.

---

## 11. Godot architecture

Continue the existing project structure where it works. Suggested layout (adapt, do not duplicate):

```text
project.godot
scenes/
  main/            Main.tscn
  cutscenes/       Prologue.tscn, CastleCutscene.tscn
  world/           WhisperingWoods.tscn, MossveilVillage.tscn
  entities/        Player.tscn, Kitsu.tscn, Enemy.tscn, NPC.tscn
  ui/              DialogueBox.tscn, HUD.tscn, PauseMenu.tscn, TitleCard.tscn
scripts/
  autoload/        GameState.gd, SceneManager.gd, InputConfig.gd, Assets.gd
  entities/        player.gd, enemy.gd, npc.gd, kitsu.gd
  systems/         cutscene_runner.gd, combat.gd, interaction.gd,
                   dialogue.gd, wave_manager.gd, save_system.gd
data/
  prologue.json (or .gd/.tres), dialogue.json, waves.json, combat_config.tres
assets/
  sprites/ tilesets/ maps/ audio/ cutscenes/ ui/
tests/
README.md   MISSING_ASSETS.md   CREDITS.md
```

### Rules

- Use **typed GDScript** (`var health: int = 3`, typed function signatures).
- Communicate with **signals** instead of reaching across the scene tree. Avoid long hard-coded `get_node` paths. Use `@export`, `@onready`, and groups.
- Use autoloads only for true globals: `GameState`, `SceneManager`, `Assets`, and an audio manager if needed.
- Keep story content (captions, dialogue, waves) in data files so it can be edited without touching engine code.
- Keep scenes small and composable (player, enemy, NPC, UI as reusable scenes).
- Free nodes and disconnect signals properly on scene change. No orphan nodes.
- Prefer built-in Godot features over new addons. Add an addon only if it solves a real problem, and record it in `README.md`.

### Working with an AI agent in Godot

- Hand-editing `.tscn` and `.tres` files is error-prone. Keep scene files simple, do not edit resource UIDs by hand, and prefer creating nodes in scripts when a scene file would be fragile.
- After adding or changing assets, re-import them (open the editor or run the import command for the installed version).
- The agent should run the project headless where possible to catch script and load errors. Verify the exact command-line flags for the installed Godot version before relying on them, for example a headless run of the project that quits after loading.
- The agent cannot always see the running game. If it cannot verify something visually (animation timing, collision feel, camera jitter), it must say so and ask the owner to test that item in the editor.

---

## 12. Desktop UX, save, and accessibility

- Window is resizable and keeps integer-scaled, crisp pixels. Add a fullscreen toggle.
- Pause the game when the window loses focus (handle the focus-out notification) and when the player opens the pause menu.
- Show a loading state if scene loading is noticeable. Report missing assets with a useful error, not a silent failure.
- Provide restart on game over and a New Game option.
- Menus and dialogue must be keyboard-operable. Controls must be discoverable.
- **Save** (after the loop is stable): a versioned JSON file in `user://` written with `FileAccess` containing region, position, health, inventory, and flags. Validate before loading, fall back safely, and never overwrite a valid save with partial state. Do not save transient animation state or active hitboxes. Store settings separately (for example with `ConfigFile`).
- Export presets (Windows first) are a later step. Document them in the README once they exist.

---

## 13. Quality bar

### Definition of done

A feature is done only when it works as intended with the existing controls and state, does not break other features, runs without errors in the Godot output panel, matches the art direction, and has its limitations documented. A region is not done because its art exists. It needs collision, a valid spawn, working exits, correct draw order, and a playable route.

### Testing checklist

**Prologue**
- [ ] All scenes play in order. Skip works anywhere.
- [ ] Captions fit and are readable.

**Movement and rendering**
- [ ] WASD and arrows work. Speed is consistent in all directions.
- [ ] Animation matches direction. Idle keeps the facing.
- [ ] Pixel art is crisp at integer scale. Resizing the window does not break the layout.
- [ ] No camera jitter or shimmering tiles while moving.

**Combat**
- [ ] `Q` plays the correct attack animation every time.
- [ ] The attack never sticks. One swing hits a target once.
- [ ] The hitbox is active only during the attack window.
- [ ] Defeated enemies no longer collide or deal damage.

**World**
- [ ] No walking through obstacles or off the map.
- [ ] No visible seams between map sections.
- [ ] Exits lead to the correct spawn, tested from both sides.
- [ ] Progress persists across scene changes.
- [ ] Y-sorting looks correct around trees and buildings.

**Story and interaction**
- [ ] Prompts appear only for nearby valid targets.
- [ ] Dialogue input does not leak into movement or attack.
- [ ] Flags update at the right moment. The Elder scene triggers only after the village is saved.
- [ ] The castle cutscene plays once and ends cleanly.

**Project health**
- [ ] No errors or warnings in the output panel on a normal playthrough.
- [ ] No missing or unimported assets.
- [ ] The project opens and runs from a fresh clone using the README steps.

---

## 14. Build order

The owner's required order is: **prologue, world, character movement, combat, story, NPC interaction.** Phase 0 comes first, and one small dependency is noted below.

### Phase 0: Project audit

- Open and inspect the existing Godot project: Godot version, `project.godot`, scenes, scripts, autoloads, input map, imported assets, and the player's `SpriteFrames`.
- Measure tile size, sprite size, and animation names. Report any scale mismatch (Section 5).
- Fill the asset inventory and create `MISSING_ASSETS.md`.
- Propose the smallest plan. Do not delete or rewrite working code.

**Exit:** engine version, structure, assets, and first steps are documented.

### Phase 1: Prologue

- Build the `CutsceneRunner` and a minimal caption component (needed here, and reused later by NPC dialogue).
- Build all seven prologue scenes using supplied or placeholder art.
- Add skip, fades, saturation or tint control, and the white flash.
- End by changing to the Whispering Woods scene.

**Exit:** the prologue plays start to finish and hands off to gameplay.

### Phase 2: World

- Set up crisp pixel rendering and integer scaling.
- Build Whispering Woods and Mossveil Village from the supplied art.
- Add collision, spawn markers, exits, and y-sorted drawing.

**Exit:** both maps load with correct collision and a working two-way transition.

### Phase 3: Character movement

- Input actions, four-direction movement, directional animations, facing, camera follow and limits, collision.

**Exit:** the player moves smoothly around both maps without clipping.

### Phase 4: Combat

- Attack with `Q`, hitbox lifecycle, one basic enemy, health, defeat, feedback, practice target.
- Village defense waves.

**Exit:** a complete, repeatable fight works without softlocks.

### Phase 5: Story

- Wire the flags: arrival, Kitsu's tutorial steps, village attack, village saved, Elder scene, castle cutscene.
- Add the "to be continued" ending.

**Exit:** the full slice can be played from the title card to the castle cutscene.

### Phase 6: NPC interaction

- Full interaction system, prompts, richer dialogue, villager NPCs, optional pickups and signs.
- Save and load if not already done.

**Exit:** interactions are predictable and never leak into movement or combat.

### Phase 7: Polish

- Audio, particles, lighting, hit feedback, performance, window resize and focus tests, README, controls screen, a first Windows export.

**Exit:** a fresh clone can be opened, run, and played using the README alone.

> **Note on dependencies:** Phase 4 needs the Phase 3 movement. The Kitsu tutorial needs a minimal dialogue box, which is why a small caption and dialogue component is built in Phase 1 and extended in Phase 6.

---

## 15. Coding standards for the agent

1. Inspect before editing.
2. Make focused changes. Do not rewrite unrelated scripts or scenes.
3. Use existing assets. Search before creating placeholders.
4. Do not invent Godot APIs. Check the installed version and the official docs for node and method names, because Godot 3 and Godot 4 differ.
5. Keep the project runnable after every meaningful change.
6. State assumptions. If an asset, scale, or mechanic is unknown, inspect it or mark it unresolved.
7. Do not claim a feature works unless it was run and checked, or state the verification limit.
8. Do not change tile size, base resolution, or sprite scale without a reason and a regression check.
9. Avoid unnecessary addons.
10. Update this document and the README when controls, assets, or architecture change.
11. Keep secrets out of the repository, and add a proper `.gitignore` for Godot (for example the `.godot/` cache folder).
12. Label mock data, temporary art, and unimplemented mechanics clearly.

### Per-task workflow

Restate the goal, inspect the files and assets, choose the smallest safe change, implement it, run the project and any available checks, verify behavior, and summarize files changed, commands run, results, and limitations.

---

## 16. Open questions for the owner

1. Exact Godot version (the agent reads it from `project.godot` and reports it).
2. Is there a grandfather in the prologue, or only Aaji?
3. Should the village defense include protecting villagers, or only clearing waves?
4. Is there a mini-boss at the end of the defense?
5. Who provides the real-world prologue art, and in what style?
6. Should the "Focus vs Rest" burnout mechanic be built or left as an idea?
7. Exact Monster King lore and the Elder's speech.
8. Maps: does the owner paint them in the Godot editor, or should the agent build them from a layout file?
9. Final tile size and base resolution (the agent proposes after Phase 0).

---

## 17. First task prompt for the agent

> Read `GAME_SPEC.md` completely. This is a Godot project. Audit the existing project first. Do not rewrite anything or add addons yet.
>
> Report:
> 1. The Godot version, project structure, main scene, autoloads, and input map.
> 2. Every asset found, with exact filenames and animation names, and what is missing compared with Section 6.2.
> 3. The source tile size, sprite sizes, current stretch and filter settings, and any scale mismatch between the character sprite, the Tiny Swords tiles, and the forest reference art.
> 4. What already works and what is broken or missing, including any errors in the output panel.
> 5. The smallest plan for **Phase 1 (the prologue)**, including how you will build the cutscene system.
>
> After I approve the plan, implement only Phase 1. Run the project and any available checks, report the exact commands and results, preserve the art style and asset paths, and do not claim anything is tested unless you verified it. If you cannot verify something visually, say so.

---

## 18. README essentials

The root `README.md` should eventually contain a one-paragraph overview, a screenshot or clip, implemented features only, the required Godot version, how to open and run the project, controls, export steps, asset credits and licenses, known limitations, and the roadmap.
