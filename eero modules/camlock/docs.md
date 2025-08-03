# Eero Camlock - Complete Documentation

## Table of Contents
1. [Installation](#installation)
2. [Basic Usage](#basic-usage)
3. [Settings Reference](#settings-reference)
4. [Configuration Examples](#configuration-examples)
5. [Advanced Features](#advanced-features)
6. [Troubleshooting](#troubleshooting)
7. [FAQ](#faq)

---

## Installation

### Method 1: Loadstring (Recommended)
```lua
loadstring(game:HttpGet("your-url-here"))()
```

### Method 2: Direct Execution
Copy and paste the entire script into your executor.

After loading, the script will print confirmation messages and usage examples.

---

## Basic Usage

### Getting Started
Once loaded, you can access all settings through the global `eero.camlock` table:

```lua
-- Enable camlock
eero.camlock.enabled = true

-- Disable camlock
eero.camlock.enabled = false

-- Change FOV size
eero.camlock.FOVRadius = 150
```

### Default Keybind
- **E Key**: Toggle camlock on/off
- You can change this with `eero.camlock.keybind = Enum.KeyCode.Q`

---

## Settings Reference

### 🎯 Main Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable/disable the camlock |
| `keybind` | KeyCode | `Enum.KeyCode.E` | Key to toggle camlock |
| `aimPart` | string | `"Head"` | Body part to target |

**Valid aimPart values:**
- `"Head"` - Target the head
- `"UpperTorso"` - Target the upper torso/chest
- `"LowerTorso"` - Target the lower torso
- `"HumanoidRootPart"` - Target center mass

### 🎯 FOV Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `FOVRadius` | number | `120` | Size of the FOV circle in pixels |
| `useFOV` | boolean | `true` | Whether to limit targeting to FOV |
| `showFOV` | boolean | `true` | Show/hide the FOV circle |
| `FOVColor` | Color3 | `Color3.fromRGB(0, 170, 255)` | Color of the FOV circle |
| `FOVThickness` | number | `1.5` | Thickness of the FOV circle outline |
| `FOVTransparency` | number | `0.6` | Transparency of the FOV circle (0-1) |
| `FOVFilled` | boolean | `false` | Whether the FOV circle is filled |

### 🎯 Prediction Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `autoPrediction` | boolean | `true` | Use automatic ping-based prediction |
| `enablePrediction` | boolean | `true` | Enable/disable prediction entirely |
| `predictionValue` | number | `0.107` | Manual prediction value (when auto is off) |

**Auto Prediction Values by Ping:**
- ≤70ms: 0.107
- ≤80ms: 0.117
- ≤90ms: 0.127
- ≤100ms: 0.137
- ≤110ms: 0.147
- ≤120ms: 0.157
- ≤130ms: 0.163
- ≤140ms: 0.173
- >140ms: 0.183

### 🎯 Notification Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `notifications` | boolean | `true` | Enable/disable lock notifications |
| `notificationColor` | Color3 | `Color3.fromRGB(85, 255, 127)` | Color of notifications |
| `notificationDuration` | number | `1.5` | How long notifications stay (seconds) |
| `notificationSize` | number | `15` | Font size of notifications |

### 🎯 Display Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `showPingDisplay` | boolean | `true` | Show ping and prediction info |
| `pingDisplaySize` | number | `16` | Font size of ping display |
| `pingDisplayColor` | Color3 | `Color3.fromRGB(255, 255, 255)` | Color of ping display |
| `pingDisplayPosition` | Vector2 | `Vector2.new(0.5, 0.90)` | Screen position (0-1 percentage) |

### 🎯 Smoothing Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `smoothing` | boolean | `false` | Enable camera smoothing |
| `smoothingFactor` | number | `0.2` | Smoothing intensity (0.1 = very smooth, 1 = no smoothing) |

### 🎯 Advanced Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `wallCheck` | boolean | `false` | Don't target players behind walls |
| `teamCheck` | boolean | `false` | Don't target teammates |
| `aliveCheck` | boolean | `true` | Don't target dead players |
| `maxDistance` | number | `math.huge` | Maximum targeting distance |

### 🎯 Visual Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `highlightTarget` | boolean | `false` | Highlight the locked target |
| `highlightColor` | Color3 | `Color3.fromRGB(255, 0, 0)` | Color of target highlight |

### 🎯 Debug Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `debug` | boolean | `false` | Show debug messages in console |

---

## Configuration Examples

### 🌟 Stealth Configuration
Perfect for staying undetected:
```lua
eero.camlock.showFOV = false
eero.camlock.showPingDisplay = false
eero.camlock.notifications = false
eero.camlock.highlightTarget = false
eero.camlock.smoothing = true
eero.camlock.smoothingFactor = 0.1
```

### 🌟 Legit Configuration
Looks more natural and human-like:
```lua
eero.camlock.smoothing = true
eero.camlock.smoothingFactor = 0.15
eero.camlock.wallCheck = true
eero.camlock.teamCheck = true
eero.camlock.FOVRadius = 80
eero.camlock.maxDistance = 300
```

### 🌟 Rage Configuration
Maximum performance, no restrictions:
```lua
eero.camlock.useFOV = false
eero.camlock.maxDistance = math.huge
eero.camlock.smoothing = false
eero.camlock.wallCheck = false
eero.camlock.teamCheck = false
eero.camlock.enablePrediction = true
eero.camlock.autoPrediction = true
```

### 🌟 Custom FOV Styling
Make your FOV circle unique:
```lua
eero.camlock.FOVColor = Color3.fromRGB(255, 0, 255)  -- Purple
eero.camlock.FOVThickness = 3
eero.camlock.FOVTransparency = 0.3
eero.camlock.FOVFilled = true
eero.camlock.FOVRadius = 200
```

### 🌟 Body Part Targeting
Switch between different aim targets:
```lua
-- Headshots
eero.camlock.aimPart = "Head"

-- Body shots (more reliable)
eero.camlock.aimPart = "UpperTorso"

-- Center mass (most reliable)
eero.camlock.aimPart = "HumanoidRootPart"
```

### 🌟 Manual Prediction Setup
For consistent prediction regardless of ping:
```lua
eero.camlock.autoPrediction = false
eero.camlock.predictionValue = 0.125  -- Adjust based on your needs
```

---

## Advanced Features

### 🔧 Dynamic Settings Changes
All settings can be changed in real-time without reloading:

```lua
-- Change keybind while playing
eero.camlock.keybind = Enum.KeyCode.Q

-- Adjust FOV on the fly
eero.camlock.FOVRadius = 150

-- Switch aim parts instantly
eero.camlock.aimPart = "UpperTorso"
```

### 🔧 Wall Detection
When enabled, the camlock won't target players behind walls:
```lua
eero.camlock.wallCheck = true
```

### 🔧 Team Detection
Prevents targeting teammates in team-based games:
```lua
eero.camlock.teamCheck = true
```

### 🔧 Distance Limiting
Set maximum targeting distance:
```lua
eero.camlock.maxDistance = 500  -- Only target within 500 studs
```

### 🔧 Custom Display Position
Move the ping display anywhere on screen:
```lua
-- Top left corner
eero.camlock.pingDisplayPosition = Vector2.new(0.1, 0.1)

-- Bottom right corner
eero.camlock.pingDisplayPosition = Vector2.new(0.9, 0.9)

-- Center of screen
eero.camlock.pingDisplayPosition = Vector2.new(0.5, 0.5)
```

### 🔧 Debug Mode
Enable detailed logging for troubleshooting:
```lua
eero.camlock.debug = true
```

---

## Troubleshooting

### ❓ Camlock not working
1. Check if `eero.camlock.enabled = true`
2. Verify your keybind: `print(eero.camlock.keybind)`
3. Make sure targets are within FOV if `useFOV = true`
4. Enable debug mode: `eero.camlock.debug = true`

### ❓ No targets found
1. Increase FOV radius: `eero.camlock.FOVRadius = 200`
2. Disable FOV limit: `eero.camlock.useFOV = false`
3. Check if wall check is blocking targets: `eero.camlock.wallCheck = false`
4. Verify team check settings: `eero.camlock.teamCheck = false`

### ❓ FOV circle not showing
1. Enable FOV display: `eero.camlock.showFOV = true`
2. Check FOV transparency: `eero.camlock.FOVTransparency = 0.6`
3. Verify FOV is enabled: `eero.camlock.useFOV = true`

### ❓ Prediction issues
1. Check if prediction is enabled: `eero.camlock.enablePrediction = true`
2. Try manual prediction: `eero.camlock.autoPrediction = false`
3. Adjust prediction value: `eero.camlock.predictionValue = 0.125`

### ❓ Performance issues
1. Disable unnecessary features:
   ```lua
   eero.camlock.showFOV = false
   eero.camlock.showPingDisplay = false
   eero.camlock.highlightTarget = false
   eero.camlock.debug = false
   ```

---

## FAQ

### ❓ How do I change the keybind?
```lua
eero.camlock.keybind = Enum.KeyCode.Q  -- Change to Q key
```

### ❓ Can I use multiple keys?
No, but you can change the keybind dynamically or use external scripts to trigger `eero.camlock.enabled = true/false`.

### ❓ How do I make it less obvious?
Use the stealth configuration:
```lua
eero.camlock.showFOV = false
eero.camlock.showPingDisplay = false
eero.camlock.notifications = false
eero.camlock.smoothing = true
eero.camlock.smoothingFactor = 0.1
```

### ❓ Why isn't auto prediction working?
The script tries multiple methods to get ping. If all fail, it defaults to 50ms. You can use manual prediction as a backup:
```lua
eero.camlock.autoPrediction = false
eero.camlock.predictionValue = 0.125
```

### ❓ How do I target body instead of head?
```lua
eero.camlock.aimPart = "UpperTorso"  -- For body shots
```

### ❓ Can I see all current settings?
```lua
-- Print all settings
for setting, value in pairs(eero.camlock) do
    print(setting, "=", value)
end
```

### ❓ How do I reset to default settings?
Reload the script or manually reset each setting to its default value from this documentation.

### ❓ Is this detectable?
The script uses standard Roblox APIs. Use stealth settings and smoothing to reduce detection risk.

---

## Support

If you encounter issues:
1. Enable debug mode: `eero.camlock.debug = true`
2. Check the console for error messages
3. Verify your settings match the documentation
4. Try the troubleshooting steps above

Remember: All settings update in real-time, so you can experiment and adjust without reloading the script!

---

*Last updated: 2025*
