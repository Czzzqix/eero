--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Camlock Settings
local camlockSettings = {
    -- Module Metadata
    _version = "1.0.0",
    
    -- Main Settings
    enabled = false,
    keybind = Enum.KeyCode.E, -- Can be KeyCode or UserInputType (e.g. Enum.UserInputType.MouseButton2)
    aimPart = "Head", -- "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
    aimPartFallbacks = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Head"}, -- Fallback order if aimPart not found
    holdMode = false, -- Hold to lock instead of toggle
    
    -- FOV Settings
    FOVRadius = 120,
    useFOV = false,
    showFOV = false,
    
    -- FOV Fill Settings
    showFOVFill = false,
    FOVFillColor = Color3.fromRGB(0, 170, 255),
    FOVFillTransparency = 0.8,
    
    -- FOV Outline Settings
    showFOVOutline = false,
    FOVOutlineColor = Color3.fromRGB(0, 170, 255),
    FOVOutlineThickness = 1.5,
    FOVOutlineTransparency = 0.3,
    
    -- Prediction Settings
    autoPrediction = false,
    enablePrediction = false,
    predictionValue = 0.107,
    predictionTable = { -- Ping-based prediction values (configurable)
        [70] = 0.107,
        [80] = 0.117,
        [90] = 0.127,
        [100] = 0.137,
        [110] = 0.147,
        [120] = 0.157,
        [130] = 0.163,
        [140] = 0.173,
        [math.huge] = 0.183 -- Default for anything above 140
    },
    
    -- Notification Settings
    notifications = false,
    notificationColor = Color3.fromRGB(85, 255, 127),
    notificationDuration = 1.5,
    notificationSize = 15,
    
    -- Display Settings
    showPingDisplay = false,
    pingDisplaySize = 16,
    pingDisplayColor = Color3.fromRGB(255, 255, 255),
    pingDisplayPosition = Vector2.new(0.5, 0.90), -- 0-1 screen percentage
    
    -- Smoothing Settings
    smoothing = false,
    smoothingFactor = 0.2, -- 0.1 = very smooth, 1 = no smoothing
    
    -- Advanced Settings
    wallCheck = false, -- Check if target is behind walls
    teamCheck = false, -- Don't target teammates
    aliveCheck = false, -- Don't target dead players
    maxDistance = math.huge, -- Maximum distance to target
    
    -- Visual Settings
    highlightTarget = false,
    highlightColor = Color3.fromRGB(255, 0, 0),
    
    -- Debugging
    debug = false,
    showDebugOverlay = false,
    debugOverlayPosition = Vector2.new(0.02, 0.02), -- Top-left corner
    debugOverlaySize = 14,
    debugOverlayColor = Color3.fromRGB(255, 255, 0),
    
    -- Callback Hooks
    onTargetLocked = nil, -- function(targetPlayer)
    onTargetUnlocked = nil, -- function(previousTargetPlayer)
    onToggle = nil, -- function(enabled)
}

--// Setting Validation
local function ValidateSettings()
    -- Validate aimPart
    local validParts = {Head=true, UpperTorso=true, LowerTorso=true, HumanoidRootPart=true}
    if not validParts[camlockSettings.aimPart] then
        warn("[Eero Camlock]: Invalid aimPart: " .. tostring(camlockSettings.aimPart) .. " - Defaulting to 'Head'")
        camlockSettings.aimPart = "Head"
    end
    
    -- Validate keybind (now supports both KeyCode and UserInputType)
    if not camlockSettings.keybind or 
       (typeof(camlockSettings.keybind) ~= "EnumItem" or 
        (camlockSettings.keybind.EnumType ~= Enum.KeyCode and camlockSettings.keybind.EnumType ~= Enum.UserInputType)) then
        warn("[Eero Camlock]: Invalid keybind - Defaulting to 'E'")
        camlockSettings.keybind = Enum.KeyCode.E
    end
    
    -- Validate aimPart fallbacks
    if typeof(camlockSettings.aimPartFallbacks) ~= "table" then
        warn("[Eero Camlock]: Invalid aimPartFallbacks - Defaulting to standard fallbacks")
        camlockSettings.aimPartFallbacks = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Head"}
    end
    
    -- Validate numeric ranges
    if camlockSettings.FOVRadius <= 0 or camlockSettings.FOVRadius > 1000 then
        warn("[Eero Camlock]: Invalid FOVRadius: " .. tostring(camlockSettings.FOVRadius) .. " - Defaulting to 120")
        camlockSettings.FOVRadius = 120
    end
    
    if camlockSettings.predictionValue < 0 or camlockSettings.predictionValue > 1 then
        warn("[Eero Camlock]: Invalid predictionValue: " .. tostring(camlockSettings.predictionValue) .. " - Defaulting to 0.107")
        camlockSettings.predictionValue = 0.107
    end
    
    if camlockSettings.smoothingFactor <= 0 or camlockSettings.smoothingFactor > 1 then
        warn("[Eero Camlock]: Invalid smoothingFactor: " .. tostring(camlockSettings.smoothingFactor) .. " - Defaulting to 0.2")
        camlockSettings.smoothingFactor = 0.2
    end
    
    if camlockSettings.notificationDuration <= 0 or camlockSettings.notificationDuration > 10 then
        warn("[Eero Camlock]: Invalid notificationDuration: " .. tostring(camlockSettings.notificationDuration) .. " - Defaulting to 1.5")
        camlockSettings.notificationDuration = 1.5
    end
    
    if camlockSettings.maxDistance <= 0 then
        warn("[Eero Camlock]: Invalid maxDistance: " .. tostring(camlockSettings.maxDistance) .. " - Defaulting to math.huge")
        camlockSettings.maxDistance = math.huge
    end
    
    -- Validate position ranges (0-1)
    if camlockSettings.pingDisplayPosition.X < 0 or camlockSettings.pingDisplayPosition.X > 1 or
       camlockSettings.pingDisplayPosition.Y < 0 or camlockSettings.pingDisplayPosition.Y > 1 then
        warn("[Eero Camlock]: Invalid pingDisplayPosition - Defaulting to (0.5, 0.90)")
        camlockSettings.pingDisplayPosition = Vector2.new(0.5, 0.90)
    end
    
    -- Validate transparency ranges (0-1)
    if camlockSettings.FOVFillTransparency < 0 or camlockSettings.FOVFillTransparency > 1 then
        warn("[Eero Camlock]: Invalid FOVFillTransparency: " .. tostring(camlockSettings.FOVFillTransparency) .. " - Defaulting to 0.8")
        camlockSettings.FOVFillTransparency = 0.8
    end
    
    if camlockSettings.FOVOutlineTransparency < 0 or camlockSettings.FOVOutlineTransparency > 1 then
        warn("[Eero Camlock]: Invalid FOVOutlineTransparency: " .. tostring(camlockSettings.FOVOutlineTransparency) .. " - Defaulting to 0.3")
        camlockSettings.FOVOutlineTransparency = 0.3
    end
    
    -- Validate color objects
    if typeof(camlockSettings.FOVFillColor) ~= "Color3" then
        warn("[Eero Camlock]: Invalid FOVFillColor - Defaulting to blue")
        camlockSettings.FOVFillColor = Color3.fromRGB(0, 170, 255)
    end
    
    if typeof(camlockSettings.FOVOutlineColor) ~= "Color3" then
        warn("[Eero Camlock]: Invalid FOVOutlineColor - Defaulting to blue")
        camlockSettings.FOVOutlineColor = Color3.fromRGB(0, 170, 255)
    end
    
    if typeof(camlockSettings.notificationColor) ~= "Color3" then
        warn("[Eero Camlock]: Invalid notificationColor - Defaulting to green")
        camlockSettings.notificationColor = Color3.fromRGB(85, 255, 127)
    end
    
    if typeof(camlockSettings.highlightColor) ~= "Color3" then
        warn("[Eero Camlock]: Invalid highlightColor - Defaulting to red")
        camlockSettings.highlightColor = Color3.fromRGB(255, 0, 0)
    end
    
    -- Validate prediction table
    if typeof(camlockSettings.predictionTable) ~= "table" then
        warn("[Eero Camlock]: Invalid predictionTable - Defaulting to standard values")
        camlockSettings.predictionTable = {
            [70] = 0.107,
            [80] = 0.117,
            [90] = 0.127,
            [100] = 0.137,
            [110] = 0.147,
            [120] = 0.157,
            [130] = 0.163,
            [140] = 0.173,
            [math.huge] = 0.183
        }
    end
end

-- Run validation
ValidateSettings()

--// State
local Target = nil
local CurrentCFrame = nil
local Connections = {} -- Track all connections for cleanup
local PreviousTargetPlayer = nil -- Track for unlock callback

--// Debug Function
local function Debug(message)
    if camlockSettings.debug then
        print("[Eero Camlock Debug]: " .. tostring(message))
    end
end

--// Notification Function
local function Notify(text, color, duration, size)
    if not camlockSettings.notifications then return end
    
    task.spawn(function()
        local notif = Drawing.new("Text")
        notif.Text = text
        notif.Size = size or camlockSettings.notificationSize
        notif.Font = 2
        notif.Center = true
        notif.Outline = true
        notif.Color = color or camlockSettings.notificationColor
        notif.Transparency = 1
        notif.Visible = true

        notif.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.85)

        task.wait(duration or camlockSettings.notificationDuration)

        for i = 1, 15 do
            task.wait(0.03)
            notif.Transparency = notif.Transparency - 0.07
        end

        notif:Remove()
    end)
end

--// FOV Circle Drawing (Separate circles for fill and outline)
local FOVCircleFilled = Drawing.new("Circle")  -- Filled background circle
local FOVCircleOutline = Drawing.new("Circle") -- Outline circle

-- Initialize FOV circles
FOVCircleFilled.Thickness = 1
FOVCircleOutline.Thickness = 1

--// Prediction Display
local PredDisplay = Drawing.new("Text")

--// Debug Overlay
local DebugOverlay = Drawing.new("Text")

--// Target Highlight
local TargetHighlight = nil

--// Wall Check Function
local function IsWallBetween(start, target)
    if not camlockSettings.wallCheck then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, target.Parent}
    
    local raycastResult = workspace:Raycast(start, (target.Position - start), raycastParams)
    return raycastResult ~= nil
end

--// Team Check Function
local function IsSameTeam(player)
    if not camlockSettings.teamCheck then return false end
    return player.Team == LocalPlayer.Team
end

--// Alive Check Function
local function IsPlayerAlive(player)
    if not camlockSettings.aliveCheck then return true end
    
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

--// Get Live Ping
local function GetLivePing()
    local success, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    
    if success and ping then
        return math.floor(ping)
    end
    
    -- Fallback method
    local success2, ping2 = pcall(function()
        return Stats.PerformanceStats.Ping:GetValue()
    end)
    
    if success2 and ping2 then
        return math.floor(ping2)
    end
    
    -- Another fallback
    local success3, ping3 = pcall(function()
        return LocalPlayer:GetNetworkPing() * 1000
    end)
    
    if success3 and ping3 then
        return math.floor(ping3)
    end
    
    return 50 -- Final fallback
end

--// Get Closest Player in FOV (with aimPart fallback)
local function GetClosestTargetInFOV()
    local closest = nil
    local shortestDistance = camlockSettings.useFOV and camlockSettings.FOVRadius or math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Check team
            if IsSameTeam(player) then continue end
            
            -- Check if alive
            if not IsPlayerAlive(player) then continue end
            
            -- Try to find aimPart with fallback
            local targetPart = nil
            local usedPart = camlockSettings.aimPart
            
            -- First try the configured aimPart
            if player.Character:FindFirstChild(camlockSettings.aimPart) then
                targetPart = player.Character[camlockSettings.aimPart]
            else
                -- Try fallbacks
                for _, fallbackPart in ipairs(camlockSettings.aimPartFallbacks) do
                    if player.Character:FindFirstChild(fallbackPart) then
                        targetPart = player.Character[fallbackPart]
                        usedPart = fallbackPart
                        warn("[Eero Camlock]: " .. camlockSettings.aimPart .. " not found on " .. player.Name .. ", using " .. fallbackPart)
                        break
                    end
                end
            end
            
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    local worldDistance = (Camera.CFrame.Position - targetPart.Position).Magnitude
                    
                    -- Check max distance
                    if worldDistance > camlockSettings.maxDistance then continue end
                    
                    -- Check wall
                    if IsWallBetween(Camera.CFrame.Position, targetPart) then continue end
                    
                    if distance <= shortestDistance then
                        closest = targetPart
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    return closest
end

--// Update Target Highlight
local function UpdateTargetHighlight()
    if TargetHighlight then
        TargetHighlight:Remove()
        TargetHighlight = nil
    end
    
    if camlockSettings.highlightTarget and Target then
        TargetHighlight = Drawing.new("Circle")
        TargetHighlight.Radius = 8
        TargetHighlight.Thickness = 2
        TargetHighlight.Color = camlockSettings.highlightColor
        TargetHighlight.Filled = false
        TargetHighlight.Transparency = 0.8
        TargetHighlight.Visible = true
    end
end

--// Input matching function (handles both KeyCode and UserInputType)
local function DoesInputMatch(input, keybind)
    if keybind.EnumType == Enum.KeyCode then
        return input.KeyCode == keybind
    elseif keybind.EnumType == Enum.UserInputType then
        return input.UserInputType == keybind
    end
    return false
end

--// Toggle Lock
Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and DoesInputMatch(input, camlockSettings.keybind) then
        if camlockSettings.holdMode then
            -- Hold mode: enable on press
            if not camlockSettings.enabled then
                local found = GetClosestTargetInFOV()
                if found then
                    Target = found
                    camlockSettings.enabled = true
                    local targetPlayer = Players:GetPlayerFromCharacter(found.Parent)
                    PreviousTargetPlayer = targetPlayer
                    Debug("Camlock enabled (hold mode), target: " .. (targetPlayer and targetPlayer.Name or "Unknown"))
                    print("Camlock: ON (Hold)")
                    if targetPlayer then
                        Notify("Locked onto " .. targetPlayer.Name)
                        -- Trigger callback
                        if camlockSettings.onTargetLocked then
                            camlockSettings.onTargetLocked(targetPlayer)
                        end
                    end
                    UpdateTargetHighlight()
                    -- Trigger toggle callback
                    if camlockSettings.onToggle then
                        camlockSettings.onToggle(true)
                    end
                end
            end
        else
            -- Toggle mode: switch on/off
            if camlockSettings.enabled then
                camlockSettings.enabled = false
                local prevPlayer = PreviousTargetPlayer
                Target = nil
                PreviousTargetPlayer = nil
                Debug("Camlock disabled via keybind")
                print("Camlock: OFF")
                UpdateTargetHighlight()
                -- Trigger callbacks
                if prevPlayer and camlockSettings.onTargetUnlocked then
                    camlockSettings.onTargetUnlocked(prevPlayer)
                end
                if camlockSettings.onToggle then
                    camlockSettings.onToggle(false)
                end
            else
                local found = GetClosestTargetInFOV()
                if found then
                    Target = found
                    camlockSettings.enabled = true
                    local targetPlayer = Players:GetPlayerFromCharacter(found.Parent)
                    PreviousTargetPlayer = targetPlayer
                    Debug("Camlock enabled, target: " .. (targetPlayer and targetPlayer.Name or "Unknown"))
                    print("Camlock: ON")
                    if targetPlayer then
                        Notify("Locked onto " .. targetPlayer.Name)
                        -- Trigger callback
                        if camlockSettings.onTargetLocked then
                            camlockSettings.onTargetLocked(targetPlayer)
                        end
                    end
                    UpdateTargetHighlight()
                    -- Trigger toggle callback
                    if camlockSettings.onToggle then
                        camlockSettings.onToggle(true)
                    end
                else
                    Debug("No valid target found")
                    print("No target found.")
                    camlockSettings.enabled = false
                end
            end
        end
    end
end)

-- Hold mode: release key to disable
Connections.InputEnded = UserInputService.InputEnded:Connect(function(input, processed)
    if camlockSettings.holdMode and DoesInputMatch(input, camlockSettings.keybind) then
        if camlockSettings.enabled then
            camlockSettings.enabled = false
            local prevPlayer = PreviousTargetPlayer
            Target = nil
            PreviousTargetPlayer = nil
            Debug("Camlock disabled (hold mode released)")
            print("Camlock: OFF (Released)")
            UpdateTargetHighlight()
            -- Trigger callbacks
            if prevPlayer and camlockSettings.onTargetUnlocked then
                camlockSettings.onTargetUnlocked(prevPlayer)
            end
            if camlockSettings.onToggle then
                camlockSettings.onToggle(false)
            end
        end
    end
end)

--// Get prediction from ping (now uses configurable table)
local function GetPrediction(ping)
    for threshold, predValue in pairs(camlockSettings.predictionTable) do
        if ping <= threshold then
            return predValue
        end
    end
    -- Fallback if no threshold matches
    return camlockSettings.predictionTable[math.huge] or 0.183
end

--// Smooth Camera Function
local function SmoothCamera(targetCFrame)
    if not camlockSettings.smoothing then
        return targetCFrame
    end
    
    if not CurrentCFrame then
        CurrentCFrame = Camera.CFrame
    end
    
    CurrentCFrame = CurrentCFrame:Lerp(targetCFrame, camlockSettings.smoothingFactor)
    return CurrentCFrame
end

--// Camera Lock Loop
Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Update FOV Circles
    -- FOV Fill Circle
    FOVCircleFilled.Position = Vector2.new(mousePos.X, mousePos.Y)
    FOVCircleFilled.Radius = camlockSettings.FOVRadius
    FOVCircleFilled.Color = camlockSettings.FOVFillColor
    FOVCircleFilled.Filled = true
    FOVCircleFilled.Transparency = camlockSettings.FOVFillTransparency
    FOVCircleFilled.Visible = camlockSettings.showFOVFill
    
    -- FOV Outline Circle  
    FOVCircleOutline.Position = Vector2.new(mousePos.X, mousePos.Y)
    FOVCircleOutline.Radius = camlockSettings.FOVRadius
    FOVCircleOutline.Thickness = camlockSettings.FOVOutlineThickness
    FOVCircleOutline.Color = camlockSettings.FOVOutlineColor
    FOVCircleOutline.Filled = false
    FOVCircleOutline.Transparency = camlockSettings.FOVOutlineTransparency
    FOVCircleOutline.Visible = camlockSettings.showFOVOutline

    -- Get live ping and prediction
    local rawPing = GetLivePing()
    local PredictionFactor = camlockSettings.autoPrediction and GetPrediction(rawPing) or camlockSettings.predictionValue

    -- Update prediction display
    if camlockSettings.showPingDisplay then
        PredDisplay.Position = Vector2.new(
            Camera.ViewportSize.X * camlockSettings.pingDisplayPosition.X,
            Camera.ViewportSize.Y * camlockSettings.pingDisplayPosition.Y
        )
        PredDisplay.Size = camlockSettings.pingDisplaySize
        PredDisplay.Color = camlockSettings.pingDisplayColor
        PredDisplay.Center = true
        PredDisplay.Outline = true
        PredDisplay.Font = 2
        PredDisplay.Visible = true
        
        local predType = camlockSettings.autoPrediction and "auto" or "manual"
        local predStatus = camlockSettings.enablePrediction and predType or "off"
        PredDisplay.Text = string.format("%d ms | %.3f prediction (%s)", rawPing, PredictionFactor, predStatus)
    else
        PredDisplay.Visible = false
    end

    -- Update debug overlay
    if camlockSettings.showDebugOverlay then
        DebugOverlay.Position = Vector2.new(
            Camera.ViewportSize.X * camlockSettings.debugOverlayPosition.X,
            Camera.ViewportSize.Y * camlockSettings.debugOverlayPosition.Y
        )
        DebugOverlay.Size = camlockSettings.debugOverlaySize
        DebugOverlay.Color = camlockSettings.debugOverlayColor
        DebugOverlay.Center = false
        DebugOverlay.Outline = true
        DebugOverlay.Font = 2
        DebugOverlay.Visible = true
        
        local targetName = "None"
        local targetDistance = "N/A"
        if Target then
            local targetPlayer = Players:GetPlayerFromCharacter(Target.Parent)
            targetName = targetPlayer and targetPlayer.Name or "Unknown"
            targetDistance = string.format("%.1f", (Camera.CFrame.Position - Target.Position).Magnitude)
        end
        
        local debugText = string.format(
            "Eero Camlock v%s\nEnabled: %s\nMode: %s\nTarget: %s\nDistance: %s\nPing: %d ms\nPrediction: %.3f (%s)\nFPS: %d",
            camlockSettings._version,
            camlockSettings.enabled and "ON" or "OFF",
            camlockSettings.holdMode and "Hold" or "Toggle",
            targetName,
            targetDistance,
            rawPing,
            PredictionFactor,
            camlockSettings.autoPrediction and "auto" or "manual",
            math.floor(1 / RunService.RenderStepped:Wait())
        )
        DebugOverlay.Text = debugText
    else
        DebugOverlay.Visible = false
    end

    -- Update target highlight
    if camlockSettings.highlightTarget and Target and TargetHighlight then
        local screenPos, onScreen = Camera:WorldToViewportPoint(Target.Position)
        if onScreen then
            TargetHighlight.Position = Vector2.new(screenPos.X, screenPos.Y)
            TargetHighlight.Visible = true
        else
            TargetHighlight.Visible = false
        end
    end

    -- Camlock logic
    if camlockSettings.enabled and not camlockSettings._paused then
        if not Target or not Target:IsDescendantOf(workspace) then
            camlockSettings.enabled = false
            local prevPlayer = PreviousTargetPlayer
            Target = nil
            PreviousTargetPlayer = nil
            Debug("Target lost - no longer in workspace")
            print("Target lost. Camlock OFF.")
            UpdateTargetHighlight()
            -- Trigger callbacks
            if prevPlayer and camlockSettings.onTargetUnlocked then
                camlockSettings.onTargetUnlocked(prevPlayer)
            end
            if camlockSettings.onToggle then
                camlockSettings.onToggle(false)
            end
            return
        end

        -- Check if target is still valid
        local targetPlayer = Players:GetPlayerFromCharacter(Target.Parent)
        if targetPlayer then
            if IsSameTeam(targetPlayer) or not IsPlayerAlive(targetPlayer) then
                camlockSettings.enabled = false
                local prevPlayer = PreviousTargetPlayer
                Target = nil
                PreviousTargetPlayer = nil
                Debug("Target no longer valid - team/alive check failed")
                print("Target no longer valid. Camlock OFF.")
                UpdateTargetHighlight()
                -- Trigger callbacks
                if prevPlayer and camlockSettings.onTargetUnlocked then
                    camlockSettings.onTargetUnlocked(prevPlayer)
                end
                if camlockSettings.onToggle then
                    camlockSettings.onToggle(false)
                end
                return
            end
        end

        local targetPos = Target.Position
        if camlockSettings.enablePrediction then
            targetPos = Target.Position + (Target.Velocity * PredictionFactor)
        end
        
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        Camera.CFrame = SmoothCamera(newCFrame)
    else
        CurrentCFrame = nil
    end
end)

--// Cleanup function
local function Cleanup()
    if FOVCircleFilled then FOVCircleFilled:Remove() end
    if FOVCircleOutline then FOVCircleOutline:Remove() end
    if PredDisplay then PredDisplay:Remove() end
    if DebugOverlay then DebugOverlay:Remove() end
    if TargetHighlight then TargetHighlight:Remove() end
end

--// Destroy/Disable function for external control
local function Destroy()
    -- Disable camlock
    local wasEnabled = camlockSettings.enabled
    local prevPlayer = PreviousTargetPlayer
    
    camlockSettings.enabled = false
    Target = nil
    CurrentCFrame = nil
    PreviousTargetPlayer = nil
    
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
    
    -- Trigger callbacks if was enabled
    if wasEnabled then
        if prevPlayer and camlockSettings.onTargetUnlocked then
            camlockSettings.onTargetUnlocked(prevPlayer)
        end
        if camlockSettings.onToggle then
            camlockSettings.onToggle(false)
        end
    end
    
    -- Reset camera if it was being controlled
    if Camera and Camera.CFrame then
        -- Camera will naturally return to normal behavior
    end
    
    Debug("Camlock module destroyed and cleaned up")
    print("Eero Camlock: Module destroyed")
end

--// API Functions
local function GetTarget()
    return Target
end

local function GetTargetPlayer()
    if Target then
        return Players:GetPlayerFromCharacter(Target.Parent)
    end
    return nil
end

local function SetTarget(player)
    if not player then
        -- Clear target
        if camlockSettings.enabled then
            local prevPlayer = PreviousTargetPlayer
            camlockSettings.enabled = false
            Target = nil
            PreviousTargetPlayer = nil
            UpdateTargetHighlight()
            -- Trigger callbacks
            if prevPlayer and camlockSettings.onTargetUnlocked then
                camlockSettings.onTargetUnlocked(prevPlayer)
            end
            if camlockSettings.onToggle then
                camlockSettings.onToggle(false)
            end
        end
        return
    end
    
    -- Handle both Player objects and Parts
    local targetPlayer = nil
    local targetPart = nil
    
    if typeof(player) == "Instance" then
        if player:IsA("Player") then
            targetPlayer = player
            if player.Character then
                -- Try configured aimPart first
                if player.Character:FindFirstChild(camlockSettings.aimPart) then
                    targetPart = player.Character[camlockSettings.aimPart]
                else
                    -- Try fallbacks
                    for _, fallbackPart in ipairs(camlockSettings.aimPartFallbacks) do
                        if player.Character:FindFirstChild(fallbackPart) then
                            targetPart = player.Character[fallbackPart]
                            warn("[Eero Camlock]: " .. camlockSettings.aimPart .. " not found, using " .. fallbackPart)
                            break
                        end
                    end
                end
            end
        elseif player.Parent and Players:GetPlayerFromCharacter(player.Parent) then
            targetPlayer = Players:GetPlayerFromCharacter(player.Parent)
            targetPart = player
        end
    end
    
    if targetPart and targetPlayer then
        -- Check validity
        if camlockSettings.teamCheck and IsSameTeam(targetPlayer) then
            warn("[Eero Camlock]: Cannot target teammate")
            return false
        end
        
        if camlockSettings.aliveCheck and not IsPlayerAlive(targetPlayer) then
            warn("[Eero Camlock]: Cannot target dead player")
            return false
        end
        
        -- Set target
        local prevPlayer = PreviousTargetPlayer
        Target = targetPart
        PreviousTargetPlayer = targetPlayer
        camlockSettings.enabled = true
        UpdateTargetHighlight()
        
        Debug("Target manually set to: " .. targetPlayer.Name)
        print("Camlock: Locked onto " .. targetPlayer.Name)
        
        -- Trigger callbacks
        if prevPlayer and prevPlayer ~= targetPlayer and camlockSettings.onTargetUnlocked then
            camlockSettings.onTargetUnlocked(prevPlayer)
        end
        if camlockSettings.onTargetLocked then
            camlockSettings.onTargetLocked(targetPlayer)
        end
        if not camlockSettings.enabled and camlockSettings.onToggle then
            camlockSettings.onToggle(true)
        end
        
        return true
    else
        warn("[Eero Camlock]: Invalid target provided to SetTarget")
        return false
    end
end

-- Dynamic config update function
local function UpdateSettings(newSettings)
    if typeof(newSettings) ~= "table" then
        warn("[Eero Camlock]: UpdateSettings requires a table")
        return false
    end
    
    local updated = {}
    for key, value in pairs(newSettings) do
        if camlockSettings[key] ~= nil then
            local oldValue = camlockSettings[key]
            camlockSettings[key] = value
            updated[key] = {old = oldValue, new = value}
            Debug("Setting updated: " .. key .. " = " .. tostring(value))
        else
            warn("[Eero Camlock]: Unknown setting: " .. tostring(key))
        end
    end
    
    -- Re-validate settings after update
    ValidateSettings()
    
    print("[Eero Camlock]: Updated " .. #updated .. " settings")
    return updated
end

-- Pause/Resume functions
local function Pause()
    if not camlockSettings._paused then
        camlockSettings._paused = true
        camlockSettings._wasEnabled = camlockSettings.enabled
        camlockSettings.enabled = false
        
        -- Clear current target but don't trigger callbacks
        Target = nil
        CurrentCFrame = nil
        UpdateTargetHighlight()
        
        Debug("Camlock paused")
        print("Camlock: PAUSED")
    end
end

local function Resume()
    if camlockSettings._paused then
        camlockSettings._paused = false
        camlockSettings.enabled = camlockSettings._wasEnabled or false
        camlockSettings._wasEnabled = nil
        
        Debug("Camlock resumed")
        print("Camlock: RESUMED")
    end
end

-- Game profile loader
local GameProfiles = {
    dahood = {
        predictionValue = 0.123,
        aimPart = "UpperTorso",
        FOVRadius = 100,
        smoothing = true,
        smoothingFactor = 0.15,
        enablePrediction = true,
        autoPrediction = true
    },
    arsenal = {
        teamCheck = true,
        aimPart = "Head", 
        FOVRadius = 80,
        predictionValue = 0.095,
        enablePrediction = true,
        autoPrediction = false
    },
    phantom_forces = {
        aimPart = "Head",
        FOVRadius = 60,
        predictionValue = 0.08,
        smoothing = true,
        smoothingFactor = 0.25,
        teamCheck = true
    },
    mm2 = {
        aimPart = "Head",
        FOVRadius = 90,
        predictionValue = 0.11,
        teamCheck = false,
        aliveCheck = true
    }
}

local function LoadProfile(profileName)
    if typeof(profileName) ~= "string" then
        warn("[Eero Camlock]: Profile name must be a string")
        return false
    end
    
    local profile = GameProfiles[profileName:lower()]
    if not profile then
        warn("[Eero Camlock]: Unknown profile: " .. profileName)
        print("Available profiles: " .. table.concat({"dahood", "arsenal", "phantom_forces", "mm2"}, ", "))
        return false
    end
    
    local updated = UpdateSettings(profile)
    print("[Eero Camlock]: Loaded '" .. profileName .. "' profile")
    return updated
end

--// Create API Table
local CamlockAPI = {
    -- Settings access
    settings = camlockSettings,
    
    -- Control functions
    Destroy = Destroy,
    GetTarget = GetTarget,
    GetTargetPlayer = GetTargetPlayer,
    SetTarget = SetTarget,
    UpdateSettings = UpdateSettings,
    Pause = Pause,
    Resume = Resume,
    LoadProfile = LoadProfile,
    
    -- Utility functions
    GetLivePing = GetLivePing,
    GetPrediction = GetPrediction,
    
    -- Game profiles
    GetAvailableProfiles = function()
        return {"dahood", "arsenal", "phantom_forces", "mm2"}
    end
}

-- Add settings validation to API
CamlockAPI.ValidateSettings = ValidateSettings

-- Add Destroy method to settings table for backwards compatibility
camlockSettings.Destroy = Destroy

--// Setup cleanup on script end
Connections.PlayerRemoving = game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        Destroy() -- Use the new Destroy function instead
    end
end)

--// Print module loaded message
print("Eero Camlock v" .. camlockSettings._version .. " loaded!")

--// Return the API table (with backwards compatibility)
return CamlockAPI
