# Snapshot

A World of Warcraft addon that automatically takes screenshots during memorable moments so you never miss them.

Compatible with **WotLK 3.3.5** clients including **Ascension**.

---

## Features

Snapshot listens for in-game events and fires a screenshot automatically, with a small configurable delay to let the UI animate before the shot is taken.

| Trigger | Default | Event |
|---|---|---|
| Level up | ✅ On | `PLAYER_LEVEL_UP` |
| Achievement earned | ✅ On | `ACHIEVEMENT_EARNED` |
| Death | ✅ On | `PLAYER_DEAD` |
| Boss kill | ✅ On | `BOSS_KILL` |
| PvP kill | ✅ On | `PLAYER_PVP_KILL` |
| Duel win | ✅ On | `DUEL_FINISHED` (wins only) |
| Legendary loot | ✅ On | `LOOT_OPENED` (quality 5+) |
| Zone change | ❌ Off | `ZONE_CHANGED_NEW_AREA` |

---

## Installation

1. Download or clone this repository
2. Copy the `Snapshot` folder into your addons directory:
   ```
   World of Warcraft/Interface/AddOns/Snapshot/
   ```
3. Make sure the folder contains both `Snapshot.toc` and `Snapshot.lua`
4. Launch the game and enable **Snapshot** in your addon list

---

## Commands

All commands are available via `/snapshot` or the shorthand `/ss`.

| Command | Description |
|---|---|
| `/snapshot` | Show help |
| `/snapshot status` | View all current settings |
| `/snapshot <key> on\|off` | Toggle a specific trigger |
| `/snapshot delay <seconds>` | Set screenshot delay (0–5s) |
| `/snapshot test` | Fire a test screenshot immediately |
| `/snapshot reset` | Restore all settings to defaults |

**Example:**
```
/snapshot zoneChange on
/snapshot pvpKill off
/snapshot delay 0.5
```

---

## Settings

Settings are saved per-account via `SavedVariables` and persist across sessions.

### Screenshot Delay

The default delay is **0.3 seconds**. This gives the UI time to render level-up animations, achievement banners, and other overlays before the screenshot fires. If your screenshots are cutting off animations, try increasing the delay:

```
/snapshot delay 0.8
```

### Zone Change

Zone change screenshots are **off by default** because they fire frequently during normal play. Enable them if you want to document first visits to new areas:

```
/snapshot zoneChange on
```

---

## Screenshots

Screenshots are saved to your standard WoW screenshots folder:

```
World of Warcraft/Screenshots/
```

---

## Notes

- **Duel losses** do not trigger a screenshot — only wins
- **Legendary loot** detection scans the loot window on open and checks item quality; fires once per window regardless of how many legendaries drop
- **Arena kills** are covered by the PvP kill trigger, which fires inside arenas normally
- The addon prints a brief chat message each time a screenshot is taken, including the reason

---

## License

Do whatever you want with it.
