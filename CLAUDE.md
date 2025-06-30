# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 2D platformer game called "dead" featuring advanced movement mechanics including air dashing, wall sliding/climbing, momentum-based turning systems, physics-based grappling, and a sophisticated combo system.

## Development Commands

Since this is a Godot project, development is primarily done through the Godot Editor:
- Open the project in Godot Editor by loading `project.godot`
- Run the game by pressing F5 or the play button in the editor
- The main scene is `Main.tscn`

## Architecture

### Core Systems

**Player Movement (`Player.gd`)**
- Complex momentum-based movement with 8-directional air dashing
- Physics-based grappling system with natural pendulum motion and momentum conservation
- Ground time tracking system that affects turn boost mechanics
- Wall sliding and wall climbing mechanics
- Speed-based sprite animation system (idle/run/dash frames)
- Floating animation system for ground-based movement
- Multiple state machines for turning, dashing, wall interactions, and grappling

**Advanced Combo System (`EffectsManager.gd`)**
- Point-based scoring: Reverse dash/Air dash (1pt), Wall kick (2pts), Dash/Smash bulb (5pts)
- Anti-spam system: 5+ of same move in last 10 actions ignored (no reset, just no points)
- Reset conditions: 1.5s on ground, 5s low speed (0-50 units), 5s inactivity
- Rating progression: dead→asleep→boring→average→criminal→sickening→disgusting→morbid (every 10 points)
- Player benefits: Faster cooldowns and charge times based on combo points

**Interactive Elements**
- `DashBulb.gd`: Replenishes air dash when slashed, floating animation with respawn system
- `SmashBulb.gd`: Similar to dash bulb but with different visual effects (red tint)
- `InteractiveFish.gd`: NPC with multi-line dialogue system, floating and speaking animations
- `GrapplingPoint.gd`: Physics-based grappling targets with elastic rope mechanics

### Key Mechanics

**Movement Constants**
- All movement parameters defined as constants at top of `Player.gd`
- Ground time affects turn boost strength (requires 1.1s minimum for boost)
- Air dash cooldown (1.0s) with minimum air time (0.35s) and speed (120 units) requirements

**Input Mapping**
- Jump: Spacebar (`jump`)
- Dash: Shift key (`dash`) 
- Slash/Grapple: Left mouse button (`click`)
- Interact: F key (`interact`) - for NPC dialogue
- Movement: A/D keys (hardcoded in `_physics_process`)
- Respawn: R key (hardcoded)

**Grappling Physics**
- Natural pendulum motion using velocity decomposition into radial/tangential components
- Momentum conservation with energy transfer between components
- Elastic rope behavior with spring constants for smooth constraint enforcement
- Visual rope rendering with Line2D that follows grapple physics

**Visual Systems**
- Speed-based sprite animations: idle (0-599), run (600-1599), dash (1600+ or air dashing)
- Ground-only sprite animations (air uses idle except during air dash)
- Player tilts forward when running fast (not backward)
- Floating animations for both player (ground-based) and NPCs (continuous)

### Enhanced Visual Effects System

**Core Systems**
- `EffectsManager.gd`: Central hub for visual/audio effects and combo system management
- `GameUI.gd`: UI system with ground time indicator, combo counter, speed display
- `EnvironmentEffects.gd`: Environmental response system with ripples, tile shaking, debris

**Dialogue System**
- `SimpleDialogue.gd`: Multi-line dialogue with F key interaction
- Positioned dynamically near speaking NPC (Fish)
- White text display with 8-second timeout if no interaction
- Fish shaking animation duration based on text length (0.15s per word, 1s minimum)

**Visual Effects Features**
- Screen shake and camera lag based on momentum
- Particle systems for trails, dust, impacts, and energy
- Combo system with escalating visual feedback and rating-based colors
- Freeze frame effects and slow motion for impactful movements
- Environmental tile shaking and screen flash effects

**Asset Integration**
- Ground tiles use `TilesGround.PNG` texture in tileset
- Dash/Smash bulbs use scaled `Dash Bulb.PNG` (0.05x/0.06x scale respectively)
- Player uses 3-frame animation system with speed-based frame switching
- Fish NPC uses `Fish.PNG` with floating and speaking animations
- Skybox tiling system for background coverage

### Scene Structure

**Main Scene Hierarchy**
- All gameplay objects have corresponding `.tscn` scene files with scripts attached
- Uses Godot's node-based architecture with signals for inter-object communication
- Main scene automatically instantiates EffectsManager, GameUI, and dialogue systems
- Asset scaling and positioning optimized for game balance (bulbs very small, player appropriately sized)

**Critical System Integration**
- Combo system integrated into Player physics loop via `effects_manager.update_combo_state()`
- All combo-worthy actions call `effects_manager.add_combo()` with appropriate action types
- Dialogue system finds NPCs via groups and positions text dynamically
- Grappling system integrated into physics with visual rope rendering

**Dynamic Sky System (`SkyTileManager.gd`)**
- Seamless background tiling using `Seamless_Sky.PNG` (500x500 tiles)
- Dynamic tile creation/removal based on camera position for performance optimization
- Replaces static sky grid with intelligent tile management system

**Department Building System (`DepartmentBuilding.gd`)**
- Dual-sprite crossfade system: exterior and interior views with different z-indices
- Area2D-based interaction detection for smooth entry/exit transitions
- Safe node referencing with `get_node_or_null()` to prevent "previously freed" errors
- Interior objects (Manager/Handler) managed through visibility toggling

### Input Architecture

**Godot Action System (project.godot)**
- Jump: Spacebar, Dash: Shift, Slash/Grapple: Left mouse, Interact: F key
- Accessed via `Input.is_action_just_pressed()` with input buffering system

**Hardcoded Input (Player.gd)**
- Movement: A/D keys via `Input.is_key_pressed()` for precise control
- Respawn: R key, Roll: Right mouse button via `_input(event)`
- Movement restrictions during rolling states and directional blocking system

### Important Implementation Notes

- Sprite animations only use speed-based frames when grounded (air uses idle except air dash)
- Combo system designed to be forgiving: no midair speed resets, generous timeouts, no harsh repetition penalties
- Floating animations provide ethereal feel: player floats on ground, NPCs float continuously
- Physics-based grappling replaces old rigid constraint system for natural swinging motion
- Department building uses parallel tweening for seamless crossfade without visual gaps
- Sky system dynamically manages tiles around camera position for infinite scrolling background