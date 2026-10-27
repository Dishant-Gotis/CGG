# Assignment 0: Game Project Plan & Proposal

## 1. Concept & Vision
* **Genre:** 2D Top-Down Action-Adventure RPG.
* **Engine:** Godot Engine 4 (GDScript).
* **Theme:** A hero ventures from Mossveil Village into shadowy crystal caverns to defeat monsters and retrieve the sacred Piece of Elixir.

---

## 2. Planned Core Features
* **Player Movement:** 8-directional movement with sprint (`Shift`) and directional animation states (Idle, Walk, Attack, Hurt, Dead).
* **Combat:**
  * **Melee:** Directional sword slash (`Q` / `Space`) with active frame hitboxes.
  * **Ranged Magic:** Auto-aimed Mana Bolt (`F` / `R`) consuming auto-regenerating Mana.
* **Inventory & UI:**
  * Full Satchel modal (`B`) to store tools, potions, and quest relics.
  * 5-slot active Hotbar (`1–5`) for instant equipment access (Sword, Cave Torch).
  * HUD displaying Heart Containers and Mana Bar.
  * Interactive Game Over menu screen on defeat with respawn options.
* **Enemies:**
  * **Forest Slimes:** Wander and chase AI with leap-attack patterns.
  * **Torch Goblins:** Dungeon guards carrying dynamic lights and patrol routes.
* **World & Levels:**
  * **Overworld (`world.tscn`):** Forest village with dialogue NPCs and secret cave entrance.
  * **Caverns (`cave.tscn`):** Dark underground dungeon requiring a Cave Torch, featuring crystal light puzzles, goblin guards, and the final Crystal Altar.

---

## 3. Computer Graphics & Physics Foundations
* **2D Transformations:**
  * **Translation ($T$):** Vector displacements ($\vec{v} \cdot \Delta t$) for smooth 8-way player movement, projectile travel, and camera tracking.
  * **Rotation ($R$):** Angle orientation for auto-aiming mana projectiles and directional melee hitboxes toward foes.
  * **Scaling & Reflection ($S$):** Sprite flipping (horizontal reflection matrix across the Y-axis) and popup bounce scale animations.
  * **Composite Transformations:** Matrix concatenation combining translation, rotation, and scaling for spawned spells and weapon swings.
* **Clipping Algorithms:**
  * **Line Clipping (Cohen-Sutherland):** Outcode tests ($L, R, B, T$) to clip attack reach, raycasts, and projectile trajectories to active camera/screen boundaries.
  * **Polygon & Viewport Clipping:** Sutherland-Hodgman window clipping to restrict rendering and lights strictly within camera frustum and cavern bounds.
* **Line & Scan-Line Filling:**
  * **Scan-Line Polygon Fill:** Edge table and parity-check filling to rasterize custom collision shapes, minimap polygons, and HUD fill bars.
* **Seed & Flood Filling:**
  * **Boundary / Flood Fill (4-Connected / 8-Connected):** Seed filling concepts applied to define cavern room zones, tile connectivity, and torch light flood propagation.
* **Physics Concepts:**
  * **Kinematics & Inertia:** Numerical integration of position and velocity ($\vec{x}_{t+1} = \vec{x}_t + \vec{v}\Delta t$) with sliding friction and velocity damping.
  * **Collision Detection (AABB & Circles):** Axis-Aligned Bounding Box (AABB) and radius overlap checks separating solid obstacles, attack hitboxes, and entity hurtboxes.
  * **Impulse & Knockback:** Momentum transfer applying directional impulse vectors that decay smoothly over time on hit impact.

---

## 4. Architecture & Technical Plan
* **Autoload Singletons:**
  * `GameState`: Central storage for player stats, inventory, and story flags.
  * `UIManager`: Screen-space UI (HUD, dialogue, inventory, game-over screen).
  * `AudioManager`: Polyphonic SFX manager and looping background music.
  * `SceneManager`: Screen fade transitions between levels.
* **Data-Driven Configuration:** `combat.json` for tuning player and enemy stats without code edits.

---

## 5. Development Roadmap
1. **Milestone 1:** Player controller, 8-way movement, and sprite animation states.
2. **Milestone 2:** Combat mechanics (sword hitboxes, enemy AI, mana projectiles, knockback impulse).
3. **Milestone 3:** World maps (village and cave dungeon) with collision boundaries and torch lighting.
4. **Milestone 4:** Dialogue system, NPC interaction, inventory bag modal, and audio/UI polish.
