local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- CONFIG
local TOGGLE_KEY = Enum.KeyCode.RightControl
local SPEED = 2
local SENSITIVITY = 0.005

-- INITIALIZE STATE
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local rotX, rotY = 0, 0
local keys = {W=0, S=0, A=0, D=0, Q=0, E=0}
_G.FreecamEnabled = false

-- CLEANUP
if _G.FreecamConnection then _G.FreecamConnection:Disconnect() end
if _G.FreecamUI then _G.FreecamUI:Destroy() end

-- CREATE DRAGGABLE INFO GUI
local sg = Instance.new("ScreenGui")
sg.Name = "FreecamStatusUI"
sg.ResetOnSpawn = false
sg.Parent = player:FindFirstChild("PlayerGui") or CoreGui
_G.FreecamUI = sg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 80)
frame.Position = UDim2.new(0.05, 0, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true 
frame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.4, 0)
title.BackgroundTransparency = 1
title.Text = "FREECAM STATUS"
title.TextColor3 = Color3.new(0.8, 0.8, 0.8)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
statusLabel.Position = UDim2.new(0, 0, 0.35, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "DISABLED"
statusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 22
statusLabel.Parent = frame

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, 0, 0.2, 0)
hint.Position = UDim2.new(0, 0, 0.75, 0)
hint.BackgroundTransparency = 1
hint.Text = "Press [RightCtrl] to Toggle"
hint.TextColor3 = Color3.new(0.6, 0.6, 0.6)
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.Parent = frame

-- CHARACTER FREEZE
local function setCharacterFrozen(frozen)
    local character = player.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = frozen end
    end
end

-- TOGGLE LOGIC
local function toggle()
    _G.FreecamEnabled = not _G.FreecamEnabled
    if _G.FreecamEnabled then
        camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        setCharacterFrozen(true)
        
        statusLabel.Text = "ENABLED"
        statusLabel.TextColor3 = Color3.fromRGB(50, 200, 50)
        
        local rx, ry, rz = camera.CFrame:ToOrientation()
        rotX, rotY = rx, ry
    else
        camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        setCharacterFrozen(false)
        
        statusLabel.Text = "DISABLED"
        statusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
    end
end

-- INPUTS
UserInputService.InputBegan:Connect(function(io, p)
    if io.KeyCode == TOGGLE_KEY then toggle() end
    if not _G.FreecamEnabled or p then return end
    
    if io.KeyCode == Enum.KeyCode.W then keys.W = 1 end
    if io.KeyCode == Enum.KeyCode.S then keys.S = 1 end
    if io.KeyCode == Enum.KeyCode.A then keys.A = 1 end
    if io.KeyCode == Enum.KeyCode.D then keys.D = 1 end
    if io.KeyCode == Enum.KeyCode.E then keys.E = 1 end
    if io.KeyCode == Enum.KeyCode.Q then keys.Q = 1 end
end)

UserInputService.InputEnded:Connect(function(io)
    if io.KeyCode == Enum.KeyCode.W then keys.W = 0 end
    if io.KeyCode == Enum.KeyCode.S then keys.S = 0 end
    if io.KeyCode == Enum.KeyCode.A then keys.A = 0 end
    if io.KeyCode == Enum.KeyCode.D then keys.D = 0 end
    if io.KeyCode == Enum.KeyCode.E then keys.E = 0 end
    if io.KeyCode == Enum.KeyCode.Q then keys.Q = 0 end
end)

-- LOOP
_G.FreecamConnection = RunService.RenderStepped:Connect(function(dt)
    if not _G.FreecamEnabled then return end
    
    camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    -- Mouse rotation (No Right-Click required)
    local delta = UserInputService:GetMouseDelta()
    rotY = rotY - (delta.X * SENSITIVITY)
    rotX = math.clamp(rotX - (delta.Y * SENSITIVITY), -1.5, 1.5)
    
    local rotation = CFrame.fromEulerAnglesYXZ(rotX, rotY, 0)
    local moveDir = Vector3.new(keys.D - keys.A, keys.E - keys.Q, keys.S - keys.W)
    local accel = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4 or 1
    
    camera.CFrame = (CFrame.new(camera.CFrame.Position) * rotation) * CFrame.new(moveDir * SPEED * accel)
end)

print("Freecam Loaded. Mouse locked. Use Right Control to toggle.")
