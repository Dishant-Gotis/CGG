# Assignment 6: Game Overview & Technical Summary

## 1. Game Overview & Core Mechanism
* **Genre:** 2D Top-Down Action-Adventure RPG built with **Godot Engine 4** using Tiny Swords assets.
* **Core Loop:** Explore forest and village environments, interact with story NPCs, defeat enemies in real-time melee combat, unlock tools/keys (Cave Torch), and enter dark crystal cavern dungeons to retrieve sacred relics (Piece of Elixir).
* **Inventory & Tools:** Persistent inventory bag (`[B]`) and a vertical 5-slot tool/hotbar on the right edge of the screen for active item selection.

---

## 2. Implementation
* **Engine & Language:** Godot 4.x using GDScript.
* **Architecture:** Modular scene-tree hierarchy powered by three Autoload singletons:
  * `GameState`: Manages player stats, inventory, active hotbar slot, and quest/story flags.
  * `UIManager`: Handles HUD, dialogue overlays, toasts, vertical hotbar, and inventory modals.
  * `AudioManager`: Central audio bus manager for polyphonic SFX and looping BGM.
* **Data-Driven:** Combat parameters (speed, health, damage) configured via `combat.json`.

---

## 3. Levels
* **Overworld / Village (`world.tscn`):** Forest biome with trails, village NPCs, destructible decorations, slime spawns, and the sealed cave entrance.
* **Glowing Crystal Caverns (`cave.tscn`):** Dark underground dungeon featuring internal rock colliders, ambient crystal light clusters, patrolling torch goblins, NPC Grimm, and the Crystal Altar.

---

## 4. Player & Skills
* **Node Type:** `CharacterBody2D` with state machine (`IDLE`, `RUN`, `ATTACK`, `HURT`, `DEAD`).
* **Vitals:** 6 Hearts HUD (`❤️`/`🖤`) and Mana Bar (100 MP) that auto-regenerates over time (+16 MP/s).
* **Melee Combat:** Directional sword attack hitbox enabled during active animation frames with cooldown and safety timers (`[Q]` / Space).
* **Mana Throw Skill:** Ranged magic bolt skill (`Right-Click` / `[F]`) consuming 20 MP to fire a glowing Mana Projectile that deals 2 damage, pierces/explodes, and knocks back foes from distance.
* **Cave Illumination:** Cave Torch illuminates dark subterranean caverns with dynamic light when inside the cave dungeon.
* **Interaction:** Forward `InteractProbe` (`Area2D`) triggers context-sensitive NPC conversations or scene transitions on `[E]` or left click.

---

## 5. Enemies
* **Forest Slimes (`enemy.gd`):** State-machine AI (`WANDER`, `CHASE`, `ATTACK`, `HURT`, `DEAD`). Aggros when player enters detection radius, leaps forward to bite, takes sword knockback, and triggers death SFX.
* **Torch Goblins (`torch_goblin.gd`):** Cavern sentinels that patrol waypoints, wield glowing torches (`PointLight2D`), detect the player, and execute telegraphed melee attacks.

---

## 6. NPCs & Companion
* **Village & Cave NPCs (`npc.gd`):** Static bodies with Layer 7 interaction areas, speech scale animations, and multi-stage dialogue trees that evaluate story flags and award quest items (e.g., Cave Torch).
* **Companion Fox (`companion.gd`):** Autonomous companion entity that smoothly follows the player using distance damping.

---

## 7. Physics & Collisions
* **Layer Segregation:**
  * **Layer 1 (World):** Static rock and tree colliders blocking player/enemy movement.
  * **Layer 2 (Player Body):** Physical collision shape for the player character.
  * **Layer 3 (Enemies):** Kinematic physical bounds for monster navigation.
  * **Layer 4 & 5 (Hitbox / Hurtbox):** Non-physical trigger layers for sword swings and damage delivery.
  * **Layer 7 (Interactables):** Probes for talking to NPCs, reading altars, and entering/exiting scenes.

---

## 8. Movement
* **Input Vector:** 8-directional input polling (`Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")`).
* **Physics Integration:** Normalized direction vector multiplied by player speed, applied via `move_and_slide()` with collision sliding against obstacles.
* **Facing & Animation:** Updates directional facing (`up`, `down`, `right`, flipped `left`) and transitions between run/idle animation loops.

---

## 9. Audio
* **BGM:** Background music stream player running on Master bus at balanced `-5.0 dB` with auto-looping.
* **SFX System:** Dedicated footstep audio player (`walk.mp3`) with randomized pitch variation + 8-channel polyphonic pool for sword swings, slime deaths, and subtle `-14.0 dB` UI dialogue selections.

---

## 10. Camera & Rendering
* **Camera (`Camera2D`):** Centered on player with position smoothing (`position_smoothing_enabled = true`) for fluid motion.
* **Depth Sorting:** 2D Y-Sort enabled so entities render correctly in front of or behind world objects based on vertical feet position.
* **Lighting System:** Dynamic 2D lighting via `CanvasModulate` (subterranean darkness in caves) and radial `PointLight2D` nodes on crystals, entrance waypoints, and enemy torches.
