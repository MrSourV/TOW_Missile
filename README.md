<div align="center">

# 🎯 TOW_Missile

**A wire-guided missile system built in Roblox Luau**

[![Engine](https://img.shields.io/badge/engine-Roblox-red.svg)](https://www.roblox.com/)
[![Language](https://img.shields.io/badge/language-Luau-00A2FF.svg)](https://luau.org/)
[![Status](https://img.shields.io/badge/status-active-brightgreen.svg)]()

**[▶ Live demo on kevinlabs.dev](https://kevinlabs.dev/)**

</div>

---

## Overview

TOW_Missile simulates a tube-launched, optically-tracked, wire-guided missile inside Roblox — down to the spooling wire, staged rocket motor, and mid-flight spiral stabilization. It's built around a single `Heartbeat`-driven physics loop, no `BodyForce`/`BodyVelocity` objects, just raw drag, thrust, and gravity math.

## Features

- 🚀 **Staged motor burn** — ejection, boost, and sustain phases each with their own thrust curve, particle rate, and sound
- 🧵 **Real wire simulation** — a segmented, sagging beam trails the missile back to the launcher and updates every frame
- 🌀 **Post-launch spiral** — the missile corkscrews briefly after leaving the tube before settling onto its flight path, just like the real thing
- 🎯 **Proportional-style guidance** — locks onto a target after a delay and corrects heading with a capped turn rate
- 💨 **Aerodynamic drag** — velocity-based drag using air density, cross-section, and drag coefficient
- 💥 **Layered detonation FX** — timed bursts of sparks, smoke, debris, and shockwave particles, plus dynamic lighting and unanchoring of nearby parts for physics-based destruction
- 🔊 **Dynamic audio** — motor sound pitch/volume shifts with flight phase

## How it works

The script drives everything from one `RunService.Heartbeat` connection:

1. Apply thrust (based on time since launch), gravity, and drag to compute acceleration
2. Integrate velocity and position, blending in the spiral offset
3. Once past the guidance delay, steer velocity toward the target
4. Update wire, glow, and particle state to match the current motor phase
5. Detonate on proximity to target, max range, or timeout

## Preview

<div align="center">
  <em>screenshot / gif goes here</em>
</div>

## Setup

1. Drop the script inside a missile model with the expected children (`particleattachment`, `Folder` of detonation emitters, `p1`/`p2` sounds)
2. Place a part named `base` for the wire launcher and a part/model named `Target` in the workspace
3. Tune `stats` at the top of the script to taste

## Credits

Built by **MrSourV**

</div>
