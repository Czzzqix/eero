--[[
    Eero Camlock Loader Script
    Complete configuration example with all available settings
]]--

local eero = {}
eero.camlock = loadstring(game:HttpGet("https://raw.githubusercontent.com/Czzzqix/eero/refs/heads/main/eero%20modules/camlock/testing/CamlockTest.luau"))()

--// ========================================
--// MAIN SETTINGS
--// ========================================
eero.camlock.settings.enabled = true
eero.camlock.settings.keybind = Enum.UserInputType.MouseButton2 -- Can also use Enum.UserInputType.MouseButton2, etc.
eero.camlock.settings.aimPart = "UpperTorso" -- "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
eero.camlock.settings.aimPartFallbacks = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Head"} -- Auto-fallback order
eero.camlock.settings.holdMode = true -- true = hold key to lock, false = toggle on/off

-- Alternative keybind examples:
-- eero.camlock.settings.keybind = Enum.UserInputType.MouseButton2 -- Right mouse button
-- eero.camlock.settings.keybind = Enum.KeyCode.LeftControl -- Left Ctrl key
-- eero.camlock.settings.keybind = Enum.UserInputType.MouseButton1 -- Left mouse button

--// ========================================
--// FOV SETTINGS
--// ========================================
eero.camlock.settings.FOVRadius = 120
eero.camlock.settings.useFOV = true
eero.camlock.settings.showFOV = false -- Legacy setting (use showFOVFill/showFOVOutline instead)

--// FOV Fill Settings
eero.camlock.settings.showFOVFill = true
eero.camlock.settings.FOVFillColor = Color3.fromRGB(225, 133, 255)
eero.camlock.settings.FOVFillTransparency = 0.2

--// FOV Outline Settings
eero.camlock.settings.showFOVOutline = true
eero.camlock.settings.FOVOutlineColor = Color3.fromRGB(245, 131, 228)
eero.camlock.settings.FOVOutlineThickness = 4
eero.camlock.settings.FOVOutlineTransparency = 1

--// ========================================
--// PREDICTION SETTINGS
--// ========================================
eero.camlock.settings.autoPrediction = false
eero.camlock.settings.enablePrediction = false
eero.camlock.settings.predictionValue = 0.107 -- Manual fallback value

-- Custom prediction table (ping-based auto prediction)
eero.camlock.settings.predictionTable = {
    [70] = 0.107,   -- <= 70ms ping
    [80] = 0.117,   -- <= 80ms ping  
    [90] = 0.127,   -- <= 90ms ping
    [100] = 0.137,  -- <= 100ms ping
    [110] = 0.147,  -- <= 110ms ping
    [120] = 0.157,  -- <= 120ms ping
    [130] = 0.163,  -- <= 130ms ping
    [140] = 0.173,  -- <= 140ms ping
    [math.huge] = 0.183 -- > 140ms ping (default)
}

--// ========================================
--// NOTIFICATION SETTINGS
--// ========================================
eero.camlock.settings.notifications = true
eero.camlock.settings.notificationColor = Color3.fromRGB(85, 255, 127) -- Green
eero.camlock.settings.notificationDuration = 1.5
eero.camlock.settings.notificationSize = 15

--// ========================================
--// DISPLAY SETTINGS
--// ========================================
eero.camlock.settings.showPingDisplay = true
eero.camlock.settings.pingDisplaySize = 16
eero.camlock.settings.pingDisplayColor = Color3.fromRGB(255, 255, 255) -- White
eero.camlock.settings.pingDisplayPosition = Vector2.new(0.5, 0.90) -- Center bottom

--// ========================================
--// SMOOTHING SETTINGS
--// ========================================
eero.camlock.settings.smoothing = false
eero.camlock.settings.smoothingFactor = 0.2 -- 0.1 = very smooth, 1 = no smoothing

--// ========================================
--// ADVANCED SETTINGS
--// ========================================
eero.camlock.settings.wallCheck = false -- Check if target is behind walls
eero.camlock.settings.teamCheck = false -- Don't target teammates
eero.camlock.settings.aliveCheck = true -- Don't target dead players
eero.camlock.settings.maxDistance = math.huge -- Maximum distance to target

--// ========================================
--// ROBUST TARGETING SETTINGS
--// ========================================
-- Custom aimPart fallback order (if primary aimPart isn't found)
eero.camlock.settings.aimPartFallbacks = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Head"}
-- This prevents errors with custom character rigs or missing body parts

--// ========================================
--// VISUAL SETTINGS
--// ========================================
eero.camlock.settings.highlightTarget = false
eero.camlock.settings.highlightColor = Color3.fromRGB(255, 0, 0) -- Red

--// ========================================
--// DEBUG SETTINGS
--// ========================================
eero.camlock.settings.debug = false
eero.camlock.settings.showDebugOverlay = false -- Live debug HUD
eero.camlock.settings.debugOverlayPosition = Vector2.new(0.02, 0.02) -- Top-left corner
eero.camlock.settings.debugOverlaySize = 14
eero.camlock.settings.debugOverlayColor = Color3.fromRGB(255, 255, 0) -- Yellow

--// ========================================
--// CALLBACK HOOKS (Optional)
--// ========================================

-- Called when a target is locked onto
eero.camlock.settings.onTargetLocked = function(targetPlayer)
    print("🎯 Locked onto: " .. targetPlayer.Name)
    -- You can add custom logic here, like:
    -- - Update ESP highlights
    -- - Play sound effects
    -- - Send notifications to UI
end

-- Called when target is unlocked/lost
eero.camlock.settings.onTargetUnlocked = function(previousTargetPlayer)
    print("🔓 Unlocked from: " .. previousTargetPlayer.Name)
    -- Custom logic for target loss
end

-- Called when camlock is toggled on/off
eero.camlock.settings.onToggle = function(enabled)
    print("🔄 Camlock toggled: " .. (enabled and "ON" or "OFF"))
    -- Update UI indicators, etc.
end

--// ========================================
--// EXAMPLE USAGE OF NEW API METHODS
--// ========================================

-- Get current ping and prediction
local currentPing = eero.camlock:GetLivePing()
local currentPrediction = eero.camlock:GetPrediction(currentPing)
print("📡 Current Ping: " .. currentPing .. "ms | Prediction: " .. currentPrediction)

-- Example: Load game profile based on current game
local gameId = game.PlaceId
local gameProfiles = {
    [2788229376] = "dahood",      -- Da Hood
    [286090429] = "arsenal",      -- Arsenal  
    [292439477] = "phantom_forces", -- Phantom Forces
    [142823291] = "mm2"           -- Murder Mystery 2
}

if gameProfiles[gameId] then
    print("🎮 Auto-loading profile for current game...")
    eero.camlock:LoadProfile(gameProfiles[gameId])
else
    print("🎮 No specific profile for this game, using manual config")
end

-- Example: Dynamic settings update with advanced keybinds
--[[
eero.camlock:UpdateSettings({
    keybind = Enum.UserInputType.MouseButton2, -- Right click to aim
    FOVRadius = 150,
    predictionValue = 0.125,
    aimPart = "UpperTorso",
    aimPartFallbacks = {"UpperTorso", "LowerTorso", "HumanoidRootPart"} -- Custom fallback order
})
]]--

-- Example: Pause/Resume functionality
--[[
task.spawn(function()
    task.wait(10)
    print("⏸️ Pausing camlock for 5 seconds...")
    eero.camlock:Pause()
    
    task.wait(5)
    print("▶️ Resuming camlock...")
    eero.camlock:Resume()
end)
]]--

-- Example: Manual targeting (useful for ESP integration)
--[[
eero.camlock:SetTarget(game.Players.SomePlayerName)
local currentTarget = eero.camlock:GetTargetPlayer()
if currentTarget then
    print("🎯 Currently targeting: " .. currentTarget.Name)
end
]]--

-- Example: Get available profiles
local availableProfiles = eero.camlock:GetAvailableProfiles()
print("📋 Available profiles: " .. table.concat(availableProfiles, ", "))

-- Example: Programmatic control
--[[
task.spawn(function()
    task.wait(5) -- Wait 5 seconds
    print("🔄 Enabling camlock programmatically...")
    eero.camlock.settings.enabled = true
    
    task.wait(10) -- Wait another 10 seconds
    print("💀 Destroying camlock module...")
    eero.camlock:Destroy()
end)
]]--

--// ========================================
--// GAME-SPECIFIC PROFILES (Auto-Load Examples)  
--// ========================================

-- The module now includes built-in profiles that auto-optimize for popular games!
-- Available profiles: "dahood", "arsenal", "phantom_forces", "mm2"

-- Manual profile loading examples:
--[[
-- Load Da Hood optimized settings
eero.camlock:LoadProfile("dahood")

-- Load Arsenal optimized settings  
eero.camlock:LoadProfile("arsenal")

-- Load Phantom Forces optimized settings
eero.camlock:LoadProfile("phantom_forces")

-- Load Murder Mystery 2 optimized settings
eero.camlock:LoadProfile("mm2")
]]--

-- You can also create custom profiles by updating settings:
--[[
-- Custom competitive profile
eero.camlock:UpdateSettings({
    aimPart = "Head",
    FOVRadius = 60,
    smoothing = true,
    smoothingFactor = 0.1,
    predictionValue = 0.09,
    teamCheck = true
})
]]--

--// ========================================
--// COMPLETION MESSAGE
--// ========================================
print("✅ Eero Camlock loaded and configured!")
print("📖 Version: " .. eero.camlock.settings._version)
print("🎮 Mode: " .. (eero.camlock.settings.holdMode and "Hold" or "Toggle"))
print("🎯 Aim Part: " .. eero.camlock.settings.aimPart)
print("🔮 Prediction: " .. (eero.camlock.settings.autoPrediction and "Auto" or "Manual") .. " (" .. eero.camlock.settings.predictionValue .. ")")

--// ========================================
--// CLEANUP EXAMPLE (Optional)
--// ========================================
--[[
-- Example: Auto-cleanup after 5 minutes
task.spawn(function()
    task.wait(300) -- 5 minutes
    print("⏰ Auto-cleanup triggered")
    eero.camlock:Destroy()
end)
]]--
