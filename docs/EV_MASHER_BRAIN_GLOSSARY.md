# Masher vs EV brain (naming)

Use this so TeAka / Cursor / PC5000 docs do not talk past each other.

## The Brain = **Masher**

**The Brain** is the **masher** — the layer that merges profiles, bridge JSON, git state, and operator context into what EV actually runs on. That is **not** the same thing as a folder or repo literally named `EV_Brain`.

When someone says “wire the brain,” they usually mean **masher + operator runtime**, not “open any file called ev_brain.”

## Not the Brain (common mislabels)

| Name | What it actually is |
|------|---------------------|
| **`EV_Brain` (Drive / folders)** | Sync / archive / launcher paths (e.g. Google Drive exports, `EV_GOOGLE_DRIVE_LAUNCHER_BRIDGE_*.json`) |
| **`ev_virtual_brain.json` / `ev_brain_state.json` (TeAka or Ev copies)** | Snapshots or inputs the masher (or operator) may read — **not** the masher itself |
| **`Ev` git repo** | Operator + PC5000 bridge + evidence — **control plane git**, not the masher |
| **`Git_Satellite_Brain` git** | **Add-on** to help **run The Brain (masher)** — GitHub Operator helper, not a second brain |
| **`EV_Brain_Clock` (`Clock` repo)** | Clock / timezone / throttle **git** — couples to Cloak, not brain authority |
| **5056 / GEMBot sidecar** | Qwen/Ollama advisory lane — **explicitly not** authoritative Brain queries (see Ev `CURSOR_BRAIN_BINDING` evidence) |
| **Codex / GPT `memories` repo** | Personal profile baseline — separate from system masher |

## Satellite = add-on to run The Brain

**Git_Satellite_Brain** (and similar “satellite” naming) is **not** another masher. It is an **optional add-on** wired to **run / support The Brain** (git mailbox, GitHub Operator, etc.). Turn it off and The Brain is still The Brain; the satellite just helps operation.

## Practical rule on PC5000

1. **Authority for “what is true now”** → **masher (The Brain)** + **`Ev\bridge\live\pc5000\`** + **`C:\EV_Operator`** runtime.  
2. **“Brain” in a folder name** → usually artifact or sync (`EV_Brain` on Drive), not the masher.  
3. **“Satellite”** → add-on to run the brain, not brain authority.  
4. **TeAka** → trading + `5050` + handoff `scratch\`; it **consumes** operator/masher signals, it is not the masher.

Handoff scripts (`federation`, `evlink`) map **git and ports**; they do not replace masher logic. Say **`scratch\ev_federation_registry.json`** to cloud agents for federation, not “read EV brain” unless you mean a specific file path.
