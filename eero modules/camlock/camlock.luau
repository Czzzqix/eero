--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Camlock Settings
local camlockSettings = {
    -- Main Settings
    enabled = false,
    keybind = Enum.KeyCode.E,
    aimPart = "Head", -- "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
    
    -- FOV Settings
    FOVRadius = 120,
    useFOV = false,
    showFOV = false,
    FOVColor = Color3.fromRGB(0, 170, 255),
    FOVThickness = 1.5,
    FOVTransparency = 0.6,
    FOVFilled = false,
    
    -- Prediction Settings
    autoPrediction = false,
    enablePrediction = false,
    predictionValue = 0.107,
    
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
    debug = false
}

--// State
local Target = nil
local CurrentCFrame = nil

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

--// FOV Circle Drawing
local FOVCircle = Drawing.new("Circle")

--// Prediction Display
local PredDisplay = Drawing.new("Text")

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

--// Get Closest Player in FOV
local function GetClosestTargetInFOV()
    local closest = nil
    local shortestDistance = camlockSettings.useFOV and camlockSettings.FOVRadius or math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(camlockSettings.aimPart) then
            -- Check team
            if IsSameTeam(player) then continue end
            
            -- Check if alive
            if not IsPlayerAlive(player) then continue end
            
            local part = player.Character[camlockSettings.aimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                local worldDistance = (Camera.CFrame.Position - part.Position).Magnitude
                
                -- Check max distance
                if worldDistance > camlockSettings.maxDistance then continue end
                
                -- Check wall
                if IsWallBetween(Camera.CFrame.Position, part) then continue end
                
                if distance <= shortestDistance then
                    closest = part
                    shortestDistance = distance
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

--// Toggle Lock
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == camlockSettings.keybind then
        if camlockSettings.enabled then
            camlockSettings.enabled = false
            Target = nil
            Debug("Camlock disabled via keybind")
            print("Camlock: OFF")
            UpdateTargetHighlight()
        else
            local found = GetClosestTargetInFOV()
            if found then
                Target = found
                camlockSettings.enabled = true
                local targetPlayer = Players:GetPlayerFromCharacter(found.Parent)
                Debug("Camlock enabled, target: " .. (targetPlayer and targetPlayer.Name or "Unknown"))
                print("Camlock: ON")
                if targetPlayer then
                    Notify("Locked onto " .. targetPlayer.Name)
                end
                UpdateTargetHighlight()
            else
                Debug("No valid target found")
                print("No target found.")
                camlockSettings.enabled = false
            end
        end
    end
end)

--// Get prediction from ping
local function GetPrediction(ping)
    if ping <= 70 then return 0.107 end
    if ping <= 80 then return 0.117 end
    if ping <= 90 then return 0.127 end
    if ping <= 100 then return 0.137 end
    if ping <= 110 then return 0.147 end
    if ping <= 120 then return 0.157 end
    if ping <= 130 then return 0.163 end
    if ping <= 140 then return 0.173 end
    return 0.183
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
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Update FOV Circle
    FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    FOVCircle.Radius = camlockSettings.FOVRadius
    FOVCircle.Thickness = camlockSettings.FOVThickness
    FOVCircle.Color = camlockSettings.FOVColor
    FOVCircle.Filled = camlockSettings.FOVFilled
    FOVCircle.Transparency = camlockSettings.FOVTransparency
    FOVCircle.Visible = camlockSettings.showFOV and camlockSettings.useFOV

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
    if camlockSettings.enabled then
        if not Target or not Target:IsDescendantOf(workspace) then
            camlockSettings.enabled = false
            Target = nil
            Debug("Target lost - no longer in workspace")
            print("Target lost. Camlock OFF.")
            UpdateTargetHighlight()
            return
        end

        -- Check if target is still valid
        local targetPlayer = Players:GetPlayerFromCharacter(Target.Parent)
        if targetPlayer then
            if IsSameTeam(targetPlayer) or not IsPlayerAlive(targetPlayer) then
                camlockSettings.enabled = false
                Target = nil
                Debug("Target no longer valid - team/alive check failed")
                print("Target no longer valid. Camlock OFF.")
                UpdateTargetHighlight()
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
    if FOVCircle then FOVCircle:Remove() end
    if PredDisplay then PredDisplay:Remove() end
    if TargetHighlight then TargetHighlight:Remove() end
end

--// Setup cleanup on script end
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        Cleanup()
    end
end)

--// Print module loaded message
print("Eero Camlock module loaded!")

--// Return the settings table (pure module)
return camlockSettings
