--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Silent Aim Settings
local silentAimSettings = {
    -- Main Settings
    enabled = false,
    aimPart = "Head", -- "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
    
    -- FOV Settings
    FOVRadius = 100,
    useFOV = false,
    
    -- Prediction Settings
    enablePrediction = false,
    predictionValue = 0.107,
    
    -- Advanced Settings
    wallCheck = false,
    teamCheck = false,
    aliveCheck = false,
    maxDistance = math.huge,
    
    -- Debug Settings
    debug = false
}

--// State
local isMouseDown = false

--// Debug Function
local function Debug(message)
    if silentAimSettings.debug then
        print("[Eero Silent Aim Debug]: " .. tostring(message))
    end
end

--// Team Check Function
local function IsSameTeam(player)
    if not silentAimSettings.teamCheck then return false end
    return player.Team == LocalPlayer.Team
end

--// Alive Check Function
local function IsPlayerAlive(player)
    if not silentAimSettings.aliveCheck then return true end
    
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

--// Wall Check Function
local function IsWallBetween(start, target)
    if not silentAimSettings.wallCheck then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, target.Parent}
    
    local raycastResult = workspace:Raycast(start, (target.Position - start), raycastParams)
    return raycastResult ~= nil
end

--// Get Closest Player in FOV
local function GetClosestTargetInFOV()
    local closest = nil
    local shortestDistance = silentAimSettings.useFOV and silentAimSettings.FOVRadius or math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(silentAimSettings.aimPart) then
            -- Check team
            if IsSameTeam(player) then continue end
            
            -- Check if alive
            if not IsPlayerAlive(player) then continue end
            
            local part = player.Character[silentAimSettings.aimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                local worldDistance = (Camera.CFrame.Position - part.Position).Magnitude
                
                -- Check max distance
                if worldDistance > silentAimSettings.maxDistance then continue end
                
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

--// Hook mouse events
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = true
        Debug("Mouse clicked, silent aim active")
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = false
        Debug("Mouse released, silent aim inactive")
    end
end)

--// Silent Aim Hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if silentAimSettings.enabled and isMouseDown and method == "FireServer" and self.Name == "RemoteEvent" then
        local target = GetClosestTargetInFOV()
        
        if target then
            local targetPos = target.Position
            
            -- Apply prediction if enabled
            if silentAimSettings.enablePrediction then
                targetPos = target.Position + (target.Velocity * silentAimSettings.predictionValue)
            end
            
            -- Modify the arguments to aim at target
            for i, arg in ipairs(args) do
                if typeof(arg) == "Vector3" then
                    args[i] = targetPos
                    Debug("Silent aim redirected to: " .. target.Parent.Name)
                    break
                elseif typeof(arg) == "CFrame" then
                    args[i] = CFrame.new(arg.Position, targetPos)
                    Debug("Silent aim redirected to: " .. target.Parent.Name)
                    break
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

--// Print module loaded message
print("Eero Silent Aim module loaded!")

--// Return the settings table
return silentAimSettings
