--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

--// Triggerbot Settings
local triggerbotSettings = {
    -- Module Metadata
    _version = "1.0.0",
    
    -- Main Settings
    enabled = false,
    keybind = Enum.KeyCode.T, -- Can be KeyCode or UserInputType
    holdMode = false, -- true = hold key to enable, false = toggle on/off
    
    -- Firing Settings
    delay = 0.1, -- seconds between clicks
    minTargetHP = 0, -- only auto-fire if target's Health > this
    maxClicksPerSecond = 20, -- rate limit (prevents spam)
    randomDelay = false, -- add slight randomization to delay
    randomDelayRange = 0.02, -- +/- range for randomization
    
    -- Target Validation
    requireCamlockTarget = true, -- only fire when camlock has valid target
    teamCheck = true, -- don't fire on teammates
    aliveCheck = true, -- don't fire on dead players
    
    -- Notification Settings
    notifications = false,
    notifyOnFire = false,
    notificationColor = Color3.fromRGB(255, 85, 85), -- Red
    notificationDuration = 1.0,
    notificationSize = 14,
    
    -- Advanced Settings
    smartFiring = true, -- only fire when crosshair is near target
    smartFiringTolerance = 50, -- pixels tolerance for smart firing
    burstMode = false, -- fire in bursts instead of continuous
    burstCount = 3, -- shots per burst
    burstDelay = 0.5, -- delay between bursts
    
    -- Visual Settings
    showFireIndicator = false,
    fireIndicatorColor = Color3.fromRGB(255, 0, 0),
    fireIndicatorDuration = 0.1,
    
    -- Debug Settings
    debug = false,
    showDebugOverlay = false,
    debugOverlayPosition = Vector2.new(0.02, 0.15),
    debugOverlaySize = 12,
    debugOverlayColor = Color3.fromRGB(255, 165, 0), -- Orange
    
    -- Input Method
    inputMethod = "mouse1click", -- "mouse1click", "virtual", or "userinput"
    
    -- Callback Hooks
    onFire = nil, -- function(targetPlayer)
    onToggle = nil, -- function(enabled)
}

--// Setting Validation
local function ValidateSettings()
    -- Validate delay
    if typeof(triggerbotSettings.delay) ~= "number" or triggerbotSettings.delay < 0 or triggerbotSettings.delay > 5 then
        warn("[Eero Triggerbot]: Invalid delay: " .. tostring(triggerbotSettings.delay) .. " - Defaulting to 0.1")
        triggerbotSettings.delay = 0.1
    end
    
    -- Validate keybind
    if not triggerbotSettings.keybind or 
       (typeof(triggerbotSettings.keybind) ~= "EnumItem" or 
        (triggerbotSettings.keybind.EnumType ~= Enum.KeyCode and triggerbotSettings.keybind.EnumType ~= Enum.UserInputType)) then
        warn("[Eero Triggerbot]: Invalid keybind - Defaulting to 'T'")
        triggerbotSettings.keybind = Enum.KeyCode.T
    end
    
    -- Validate HP threshold
    if typeof(triggerbotSettings.minTargetHP) ~= "number" or triggerbotSettings.minTargetHP < 0 then
        warn("[Eero Triggerbot]: Invalid minTargetHP: " .. tostring(triggerbotSettings.minTargetHP) .. " - Defaulting to 0")
        triggerbotSettings.minTargetHP = 0
    end
    
    -- Validate rate limit
    if typeof(triggerbotSettings.maxClicksPerSecond) ~= "number" or triggerbotSettings.maxClicksPerSecond <= 0 or triggerbotSettings.maxClicksPerSecond > 100 then
        warn("[Eero Triggerbot]: Invalid maxClicksPerSecond: " .. tostring(triggerbotSettings.maxClicksPerSecond) .. " - Defaulting to 20")
        triggerbotSettings.maxClicksPerSecond = 20
    end
    
    -- Validate random delay range
    if typeof(triggerbotSettings.randomDelayRange) ~= "number" or triggerbotSettings.randomDelayRange < 0 or triggerbotSettings.randomDelayRange > 1 then
        warn("[Eero Triggerbot]: Invalid randomDelayRange: " .. tostring(triggerbotSettings.randomDelayRange) .. " - Defaulting to 0.02")
        triggerbotSettings.randomDelayRange = 0.02
    end
    
    -- Validate smart firing tolerance
    if typeof(triggerbotSettings.smartFiringTolerance) ~= "number" or triggerbotSettings.smartFiringTolerance < 0 then
        warn("[Eero Triggerbot]: Invalid smartFiringTolerance: " .. tostring(triggerbotSettings.smartFiringTolerance) .. " - Defaulting to 50")
        triggerbotSettings.smartFiringTolerance = 50
    end
    
    -- Validate burst settings
    if typeof(triggerbotSettings.burstCount) ~= "number" or triggerbotSettings.burstCount < 1 or triggerbotSettings.burstCount > 20 then
        warn("[Eero Triggerbot]: Invalid burstCount: " .. tostring(triggerbotSettings.burstCount) .. " - Defaulting to 3")
        triggerbotSettings.burstCount = 3
    end
    
    if typeof(triggerbotSettings.burstDelay) ~= "number" or triggerbotSettings.burstDelay < 0 or triggerbotSettings.burstDelay > 5 then
        warn("[Eero Triggerbot]: Invalid burstDelay: " .. tostring(triggerbotSettings.burstDelay) .. " - Defaulting to 0.5")
        triggerbotSettings.burstDelay = 0.5
    end
    
    -- Validate input method
    local validMethods = {mouse1click=true, virtual=true, userinput=true}
    if not validMethods[triggerbotSettings.inputMethod] then
        warn("[Eero Triggerbot]: Invalid inputMethod: " .. tostring(triggerbotSettings.inputMethod) .. " - Defaulting to 'mouse1click'")
        triggerbotSettings.inputMethod = "mouse1click"
    end
    
    -- Validate colors
    if typeof(triggerbotSettings.notificationColor) ~= "Color3" then
        warn("[Eero Triggerbot]: Invalid notificationColor - Defaulting to red")
        triggerbotSettings.notificationColor = Color3.fromRGB(255, 85, 85)
    end
    
    if typeof(triggerbotSettings.fireIndicatorColor) ~= "Color3" then
        warn("[Eero Triggerbot]: Invalid fireIndicatorColor - Defaulting to red")
        triggerbotSettings.fireIndicatorColor = Color3.fromRGB(255, 0, 0)
    end
    
    if typeof(triggerbotSettings.debugOverlayColor) ~= "Color3" then
        warn("[Eero Triggerbot]: Invalid debugOverlayColor - Defaulting to orange")
        triggerbotSettings.debugOverlayColor = Color3.fromRGB(255, 165, 0)
    end
end

-- Run validation
ValidateSettings()

--// State Variables
local Connections = {} -- Track all connections for cleanup
local lastFireTime = 0
local lastBurstTime = 0
local currentBurstShot = 0
local camlockModule = nil -- Reference to camlock module
local Camera = workspace.CurrentCamera

--// Debug Function
local function Debug(message)
    if triggerbotSettings.debug then
        print("[Eero Triggerbot Debug]: " .. tostring(message))
    end
end

--// Notification Function
local function Notify(text, color, duration, size)
    if not triggerbotSettings.notifications then return end
    
    task.spawn(function()
        local notif = Drawing.new("Text")
        notif.Text = text
        notif.Size = size or triggerbotSettings.notificationSize
        notif.Font = 2
        notif.Center = true
        notif.Outline = true
        notif.Color = color or triggerbotSettings.notificationColor
        notif.Transparency = 1
        notif.Visible = true

        notif.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.75)

        task.wait(duration or triggerbotSettings.notificationDuration)

        for i = 1, 15 do
            task.wait(0.02)
            notif.Transparency = notif.Transparency - 0.07
        end

        notif:Remove()
    end)
end

--// Fire Indicator
local FireIndicator = Drawing.new("Circle")
FireIndicator.Radius = 5
FireIndicator.Thickness = 2
FireIndicator.Filled = true
FireIndicator.Visible = false

--// Debug Overlay
local DebugOverlay = Drawing.new("Text")

--// Input matching function (handles both KeyCode and UserInputType)
local function DoesInputMatch(input, keybind)
    if keybind.EnumType == Enum.KeyCode then
        return input.KeyCode == keybind
    elseif keybind.EnumType == Enum.UserInputType then
        return input.UserInputType == keybind
    end
    return false
end

--// Team Check Function
local function IsSameTeam(player)
    if not triggerbotSettings.teamCheck then return false end
    return player.Team == LocalPlayer.Team
end

--// Alive Check Function
local function IsPlayerAlive(player)
    if not triggerbotSettings.aliveCheck then return true end
    
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > triggerbotSettings.minTargetHP
end

--// Smart Firing Check (crosshair near target)
local function IsSmartFiringValid(targetPart)
    if not triggerbotSettings.smartFiring then return true end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return false end
    
    local mousePos = UserInputService:GetMouseLocation()
    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
    
    return distance <= triggerbotSettings.smartFiringTolerance
end

--// Fire Input Function
local function FireInput()
    local method = triggerbotSettings.inputMethod
    
    if method == "mouse1click" then
        -- Use mouse1click() if available
        local success = pcall(function()
            mouse1click()
        end)
        if not success then
            -- Fallback to virtual input
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    elseif method == "virtual" then
        -- Use VirtualInputManager
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    elseif method == "userinput" then
        -- Use UserInputService (may not work in all contexts)
        local mouse = LocalPlayer:GetMouse()
        if mouse then
            mouse.Button1Down:Fire()
            task.wait(0.01)
            mouse.Button1Up:Fire()
        end
    end
end

--// Show Fire Indicator
local function ShowFireIndicator()
    if not triggerbotSettings.showFireIndicator then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    FireIndicator.Position = mousePos
    FireIndicator.Color = triggerbotSettings.fireIndicatorColor
    FireIndicator.Visible = true
    
    task.spawn(function()
        task.wait(triggerbotSettings.fireIndicatorDuration)
        FireIndicator.Visible = false
    end)
end

--// Get Valid Target from Camlock
local function GetValidTarget()
    if not camlockModule then return nil end
    
    -- Check if we should require camlock target
    if triggerbotSettings.requireCamlockTarget then
        if not camlockModule.settings.enabled then return nil end
        
        local target = camlockModule.GetTarget()
        local targetPlayer = camlockModule.GetTargetPlayer()
        
        if not target or not targetPlayer then return nil end
        
        return target, targetPlayer
    else
        -- TODO: Implement independent target detection if needed
        -- For now, always require camlock target
        return nil
    end
end

--// Input Handlers
Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and DoesInputMatch(input, triggerbotSettings.keybind) then
        if triggerbotSettings.holdMode then
            -- Hold mode: enable on press
            triggerbotSettings.enabled = true
            Debug("Triggerbot enabled (hold mode)")
            print("Triggerbot: ON (Hold)")
            if triggerbotSettings.onToggle then
                triggerbotSettings.onToggle(true)
            end
        else
            -- Toggle mode: switch on/off
            triggerbotSettings.enabled = not triggerbotSettings.enabled
            Debug("Triggerbot toggled: " .. (triggerbotSettings.enabled and "ON" or "OFF"))
            print("Triggerbot: " .. (triggerbotSettings.enabled and "ON" or "OFF"))
            if triggerbotSettings.onToggle then
                triggerbotSettings.onToggle(triggerbotSettings.enabled)
            end
        end
    end
end)

Connections.InputEnded = UserInputService.InputEnded:Connect(function(input, processed)
    if triggerbotSettings.holdMode and DoesInputMatch(input, triggerbotSettings.keybind) then
        triggerbotSettings.enabled = false
        Debug("Triggerbot disabled (hold mode released)")
        print("Triggerbot: OFF (Released)")
        if triggerbotSettings.onToggle then
            triggerbotSettings.onToggle(false)
        end
    end
end)

--// Main Triggerbot Loop
Connections.RenderStepped = RunService.RenderStepped:Connect(function(deltaTime)
    -- Update debug overlay
    if triggerbotSettings.showDebugOverlay then
        DebugOverlay.Position = Vector2.new(
            Camera.ViewportSize.X * triggerbotSettings.debugOverlayPosition.X,
            Camera.ViewportSize.Y * triggerbotSettings.debugOverlayPosition.Y
        )
        DebugOverlay.Size = triggerbotSettings.debugOverlaySize
        DebugOverlay.Color = triggerbotSettings.debugOverlayColor
        DebugOverlay.Center = false
        DebugOverlay.Outline = true
        DebugOverlay.Font = 2
        DebugOverlay.Visible = true
        
        local targetInfo = "None"
        local camlockStatus = "N/A"
        if camlockModule then
            local target = camlockModule:GetTarget()
            local targetPlayer = camlockModule:GetTargetPlayer()
            if target and targetPlayer then
                targetInfo = targetPlayer.Name
            end
            camlockStatus = camlockModule.settings.enabled and "ON" or "OFF"
        end
        
        local debugText = string.format(
            "Eero Triggerbot v%s\nEnabled: %s\nMode: %s\nCamlock: %s\nTarget: %s\nMethod: %s\nLast Fire: %.2fs ago",
            triggerbotSettings._version,
            triggerbotSettings.enabled and "ON" or "OFF",
            triggerbotSettings.holdMode and "Hold" or "Toggle",
            camlockStatus,
            targetInfo,
            triggerbotSettings.inputMethod,
            tick() - lastFireTime
        )
        DebugOverlay.Text = debugText
    else
        DebugOverlay.Visible = false
    end
    
    -- Main triggerbot logic
    if not triggerbotSettings.enabled or triggerbotSettings._paused then return end
    
    -- Get valid target
    local targetPart, targetPlayer = GetValidTarget()
    if not targetPart or not targetPlayer then return end
    
    -- Validate target
    if IsSameTeam(targetPlayer) or not IsPlayerAlive(targetPlayer) then
        return
    end
    
    -- Smart firing check
    if not IsSmartFiringValid(targetPart) then
        return
    end
    
    local currentTime = tick()
    
    -- Handle burst mode
    if triggerbotSettings.burstMode then
        -- Check if we're in the middle of a burst
        if currentBurstShot > 0 and currentBurstShot < triggerbotSettings.burstCount then
            -- Continue burst
            if currentTime - lastFireTime >= triggerbotSettings.delay then
                FireInput()
                ShowFireIndicator()
                lastFireTime = currentTime
                currentBurstShot = currentBurstShot + 1
                
                Debug("Burst shot " .. currentBurstShot .. "/" .. triggerbotSettings.burstCount)
                
                if triggerbotSettings.notifyOnFire then
                    Notify("Burst " .. currentBurstShot .. "/" .. triggerbotSettings.burstCount)
                end
                
                if triggerbotSettings.onFire then
                    triggerbotSettings.onFire(targetPlayer)
                end
            end
        elseif currentBurstShot >= triggerbotSettings.burstCount then
            -- Burst completed, wait for burst delay
            if currentTime - lastBurstTime >= triggerbotSettings.burstDelay then
                currentBurstShot = 0 -- Reset for new burst
                lastBurstTime = currentTime
            end
        else
            -- Start new burst
            if currentTime - lastBurstTime >= triggerbotSettings.burstDelay then
                FireInput()
                ShowFireIndicator()
                lastFireTime = currentTime
                lastBurstTime = currentTime
                currentBurstShot = 1
                
                Debug("Starting burst 1/" .. triggerbotSettings.burstCount)
                
                if triggerbotSettings.notifyOnFire then
                    Notify("Burst started on " .. targetPlayer.Name)
                end
                
                if triggerbotSettings.onFire then
                    triggerbotSettings.onFire(targetPlayer)
                end
            end
        end
    else
        -- Normal continuous firing
        local effectiveDelay = triggerbotSettings.delay
        
        -- Add random delay if enabled
        if triggerbotSettings.randomDelay then
            local randomOffset = (math.random() - 0.5) * 2 * triggerbotSettings.randomDelayRange
            effectiveDelay = effectiveDelay + randomOffset
        end
        
        -- Rate limiting
        local minDelay = 1 / triggerbotSettings.maxClicksPerSecond
        if effectiveDelay < minDelay then
            effectiveDelay = minDelay
        end
        
        if currentTime - lastFireTime >= effectiveDelay then
            FireInput()
            ShowFireIndicator()
            lastFireTime = currentTime
            
            Debug("Fired on " .. targetPlayer.Name)
            
            if triggerbotSettings.notifyOnFire then
                Notify("Fired on " .. targetPlayer.Name)
            end
            
            if triggerbotSettings.onFire then
                triggerbotSettings.onFire(targetPlayer)
            end
        end
    end
end)

--// Cleanup function
local function Cleanup()
    if FireIndicator then FireIndicator:Remove() end
    if DebugOverlay then DebugOverlay:Remove() end
end

--// Destroy function
local function Destroy()
    -- Disable triggerbot
    local wasEnabled = triggerbotSettings.enabled
    triggerbotSettings.enabled = false
    
    -- Clean up visual elements
    Cleanup()
    
    -- Disconnect all connections
    for connectionName, connection in pairs(Connections) do
        if connection then
            connection:Disconnect()
            Debug("Disconnected: " .. connectionName)
        end
    end
    
    -- Clear connections table
    Connections = {}
    
    -- Trigger callback if was enabled
    if wasEnabled and triggerbotSettings.onToggle then
        triggerbotSettings.onToggle(false)
    end
    
    Debug("Triggerbot module destroyed and cleaned up")
    print("Eero Triggerbot: Module destroyed")
end

--// API Functions
local function Enable()
    triggerbotSettings.enabled = true
    Debug("Triggerbot enabled via API")
    if triggerbotSettings.onToggle then
        triggerbotSettings.onToggle(true)
    end
end

local function Disable()
    triggerbotSettings.enabled = false
    Debug("Triggerbot disabled via API")
    if triggerbotSettings.onToggle then
        triggerbotSettings.onToggle(false)
    end
end

local function IsEnabled()
    return triggerbotSettings.enabled
end

local function UpdateSettings(newSettings)
    if typeof(newSettings) ~= "table" then
        warn("[Eero Triggerbot]: UpdateSettings requires a table")
        return false
    end
    
    local updated = {}
    for key, value in pairs(newSettings) do
        if triggerbotSettings[key] ~= nil then
            local oldValue = triggerbotSettings[key]
            triggerbotSettings[key] = value
            updated[key] = {old = oldValue, new = value}
            Debug("Setting updated: " .. key .. " = " .. tostring(value))
        else
            warn("[Eero Triggerbot]: Unknown setting: " .. tostring(key))
        end
    end
    
    -- Re-validate settings after update
    ValidateSettings()
    
    print("[Eero Triggerbot]: Updated " .. #updated .. " settings")
    return updated
end

local function Pause()
    if not triggerbotSettings._paused then
        triggerbotSettings._paused = true
        triggerbotSettings._wasEnabled = triggerbotSettings.enabled
        triggerbotSettings.enabled = false
        Debug("Triggerbot paused")
        print("Triggerbot: PAUSED")
    end
end

local function Resume()
    if triggerbotSettings._paused then
        triggerbotSettings._paused = false
        triggerbotSettings.enabled = triggerbotSettings._wasEnabled or false
        triggerbotSettings._wasEnabled = nil
        Debug("Triggerbot resumed")
        print("Triggerbot: RESUMED")
    end
end

local function SetCamlockModule(camlockRef)
    camlockModule = camlockRef
    Debug("Camlock module reference set")
end

--// Create API Table
local TriggerbotAPI = {
    -- Settings access
    settings = triggerbotSettings,
    
    -- Control functions
    Enable = Enable,
    Disable = Disable,
    IsEnabled = IsEnabled,
    UpdateSettings = UpdateSettings,
    Destroy = Destroy,
    Pause = Pause,
    Resume = Resume,
    
    -- Module integration
    SetCamlockModule = SetCamlockModule,
    
    -- Utility functions
    ValidateSettings = ValidateSettings,
}

-- Add settings validation to API
TriggerbotAPI.ValidateSettings = ValidateSettings

-- Add Destroy method to settings table for backwards compatibility
triggerbotSettings.Destroy = Destroy

--// Setup cleanup on script end
Connections.PlayerRemoving = game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        Destroy()
    end
end)

--// Print module loaded message
print("Eero Triggerbot v" .. triggerbotSettings._version .. " loaded!")

--// Return the API table
return TriggerbotAPI
