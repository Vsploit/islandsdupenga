local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Settings //--
local SPEED = 2
local BOOST_SPEED = 5
local SENSITIVITY = 0.2
local SMOOTHNESS = 0.1 -- Lower is smoother (0.05 - 0.3)

--// State //--
local enabled = false
local moveInput = Vector3.new()
local rotX, rotY = 0, 0
local targetCFrame = Camera.CFrame

--// Input State //--
local keys = {
	W = false, A = false, S = false, D = false,
	Q = false, E = false, LeftShift = false
}

--// Cleanup Previous Instances //--
-- This ensures if you run the script twice, it removes the old one first
if _G.FreecamConnection then
	_G.FreecamConnection:Disconnect()
	print("Previous Freecam disconnected")
end

--// Logic //--
local function getMoveVector()
	local vec = Vector3.new()
	if keys.W then vec = vec + Vector3.new(0, 0, -1) end
	if keys.S then vec = vec + Vector3.new(0, 0, 1) end
	if keys.A then vec = vec + Vector3.new(-1, 0, 0) end
	if keys.D then vec = vec + Vector3.new(1, 0, 0) end
	if keys.Q then vec = vec + Vector3.new(0, -1, 0) end -- Down
	if keys.E then vec = vec + Vector3.new(0, 1, 0) end  -- Up
	return vec
end

local function toggleFreecam()
	enabled = not enabled
	
	if enabled then
		Camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		targetCFrame = Camera.CFrame -- Reset target to current pos
		
		-- Capture current rotation to prevent snapping
		local rx, ry, rz = Camera.CFrame:ToOrientation()
		rotX = rx
		rotY = ry
		print("Freecam ON")
	else
		Camera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		print("Freecam OFF")
	end
end

--// Input Handling //--
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Toggle Key: Left Ctrl + P
	if input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		toggleFreecam()
	end
	
	if input.KeyCode == Enum.KeyCode.W then keys.W = true end
	if input.KeyCode == Enum.KeyCode.A then keys.A = true end
	if input.KeyCode == Enum.KeyCode.S then keys.S = true end
	if input.KeyCode == Enum.KeyCode.D then keys.D = true end
	if input.KeyCode == Enum.KeyCode.Q then keys.Q = true end
	if input.KeyCode == Enum.KeyCode.E then keys.E = true end
	if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = true end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then keys.W = false end
	if input.KeyCode == Enum.KeyCode.A then keys.A = false end
	if input.KeyCode == Enum.KeyCode.S then keys.S = false end
	if input.KeyCode == Enum.KeyCode.D then keys.D = false end
	if input.KeyCode == Enum.KeyCode.Q then keys.Q = false end
	if input.KeyCode == Enum.KeyCode.E then keys.E = false end
	if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = false end
end)

UserInputService.InputChanged:Connect(function(input)
	if enabled and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		rotY = rotY - delta.X * math.rad(SENSITIVITY)
		rotX = rotX - delta.Y * math.rad(SENSITIVITY)
		
		-- Clamp vertical look
		rotX = math.clamp(rotX, math.rad(-89), math.rad(89))
	end
end)

--// Render Loop //--
-- We use BindToRenderStep with high priority to ensure camera updates last
local connection = RunService.RenderStepped:Connect(function(dt)
	if not enabled then return end
	
	local currentSpeed = keys.LeftShift and BOOST_SPEED or SPEED
	local moveVec = getMoveVector()
	
	-- Create rotation CFrame
	local rotation = CFrame.fromOrientation(rotX, rotY, 0)
	
	-- Calculate target position relative to rotation
	if moveVec.Magnitude > 0 then
		moveVec = moveVec.Unit * currentSpeed
	end
	
	-- Update target CFrame
	targetCFrame = CFrame.new(targetCFrame.Position) * rotation * CFrame.new(moveVec)
	
	-- Apply to camera (with optional interpolation for smoothness)
	-- For instant movement, just use: Camera.CFrame = targetCFrame
	Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.5) 
end)

-- Store connection globally so we can clean it up if script runs again
_G.FreecamConnection = connection
