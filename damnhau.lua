
--[[ 
    GEMINI V17 FINAL - CLASSIC EDITION
    UI: Circular Button (Draggable) - Old Style
    CORE: V17 Brain (Intent + Anti-Bait)
    REMOVED: Graphics Nuke (To prevent crashes)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// 1. CẤU HÌNH & TRẠNG THÁI
getgenv().G_Apex = {
    Enabled = false,
    ActiveTarget = nil,
    IntentMemory = {}, 
    ThreatCount = 0,         
    CanEngage = false,       
    IsStriking = false,      
    CurrentMode = "IDLE"     
}

--// 2. PHYSICS PROFILES (GIỮ NGUYÊN V17)
local MODES = {
    STALK   = {Offset = 14, Strict = false, VelMult = 2,   RotateLock = false, Type = "Orbit"},
    LETHAL  = {Offset = 4,  Strict = false, VelMult = 22,  RotateLock = true,  Type = "Strike"}, 
    GHOST   = {Offset = 18, Strict = false, VelMult = 45,  RotateLock = true,  Type = "Solve"},
}

--// 3. UI SETUP - MENU HÌNH TRÒN CŨ (DRAGGABLE)
if game.CoreGui:FindFirstChild("GeminiV17_Classic") then game.CoreGui.GeminiV17_Classic:Destroy() end

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GeminiV17_Classic"
ScreenGui.ResetOnSpawn = false

-- Nút tròn chính
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Name = "ApexToggle"
ToggleBtn.Size = UDim2.new(0, 60, 0, 60) -- Kích thước tròn
ToggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0) -- Vị trí mặc định bên trái
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "OFF"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18
ToggleBtn.AutoButtonColor = true
ToggleBtn.BorderSizePixel = 2
ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
-- Biến thành hình tròn
local UICorner = Instance.new("UICorner", ToggleBtn)
UICorner.CornerRadius = UDim.new(1, 0) -- Tròn 100%

-- Hiệu ứng viền phát sáng (Shadow)
local Shadow = Instance.new("UIStroke", ToggleBtn)
Shadow.Thickness = 2
Shadow.Color = Color3.fromRGB(255, 255, 255)
Shadow.Transparency = 0

-- Tính năng Kéo Thả (Draggable)
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
ToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- Chức năng Bật/Tắt
ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().G_Apex.Enabled = not getgenv().G_Apex.Enabled
    
    if getgenv().G_Apex.Enabled then
        ToggleBtn.Text = "ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 255) -- Màu xanh Cyan
        Shadow.Color = Color3.fromRGB(0, 255, 255)
        ToggleBtn.BorderColor3 = Color3.fromRGB(0, 255, 255)
    else
        ToggleBtn.Text = "OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu trắng
        Shadow.Color = Color3.fromRGB(255, 255, 255)
        ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        
        -- Reset khi tắt
        getgenv().G_Apex.CurrentMode = "IDLE"
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
            LocalPlayer.Character.Humanoid:Move(Vector3.zero, false)
        end
    end
end)

--// 4. INTENT ENGINE (V17 BRAIN)
local function GetTargetBuffer(Player)
    if not getgenv().G_Apex.IntentMemory[Player] then
        getgenv().G_Apex.IntentMemory[Player] = { Facings = {}, Speeds = {}, Positions = {} }
    end
    return getgenv().G_Apex.IntentMemory[Player]
end

local function AnalyzeTemporalIntent(TargetPlayer, MyRoot)
    local TargetRoot = TargetPlayer.Character.HumanoidRootPart
    local Buff = GetTargetBuffer(TargetPlayer)
    
    local ToMe = (MyRoot.Position - TargetRoot.Position).Unit
    local Facing = TargetRoot.CFrame.LookVector:Dot(ToMe)
    local Speed = TargetRoot.AssemblyLinearVelocity.Magnitude
    
    table.insert(Buff.Facings, 1, Facing); table.insert(Buff.Speeds, 1, Speed); table.insert(Buff.Positions, 1, TargetRoot.Position)
    if #Buff.Facings > 15 then table.remove(Buff.Facings); table.remove(Buff.Speeds); table.remove(Buff.Positions) end
    if #Buff.Facings < 8 then return false end 
    
    local AvgFacing = 0; for _, v in pairs(Buff.Facings) do AvgFacing = AvgFacing + v end; AvgFacing = AvgFacing / #Buff.Facings
    local Displacement = (Buff.Positions[#Buff.Positions] - Buff.Positions[1]).Magnitude
    return ((AvgFacing < 0.3) and (Displacement > 3.0)) or ((Buff.Speeds[1] < Buff.Speeds[#Buff.Speeds]) and (Buff.Speeds[1] < 15))
end

local function SolveEscapeVector(MyRoot)
    local BestDir, MaxScore = nil, -99999
    local Dirs = {Vector3.new(1,0,1), Vector3.new(-1,0,1), Vector3.new(1,0,-1), Vector3.new(-1,0,-1), Vector3.new(1,0,0), Vector3.new(-1,0,0), Vector3.new(0,0,1), Vector3.new(0,0,-1)}
    for _, Dir in pairs(Dirs) do
        local WorldDir = (MyRoot.CFrame * CFrame.new(Dir.Unit * 15)).Position - MyRoot.Position
        local Score = 0
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local Dist = (v.Character.HumanoidRootPart.Position - MyRoot.Position).Magnitude
                if Dist < 35 then if WorldDir.Unit:Dot((v.Character.HumanoidRootPart.Position - MyRoot.Position).Unit) > 0.5 then Score = Score - (1000/Dist) end end
            end
        end
        if Workspace:Raycast(MyRoot.Position, WorldDir, RaycastParams.new()) then Score = Score - 5000 end
        if Score > MaxScore then MaxScore = Score; BestDir = WorldDir end
    end
    return BestDir or Vector3.new(0,0,1)
end

--// 5. MAIN LOOP (ĐÃ FIX CAMERA & MOVEMENT)
RunService.Heartbeat:Connect(function()
    if not getgenv().G_Apex.Enabled then return end
    
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    
    -- Safety Move: Không bao giờ khóa camera
    Char.Humanoid.WalkSpeed = 16 
    Char.Humanoid:Move(Vector3.zero, false)
    
    local MyRoot = Char.HumanoidRootPart
    
    -- A. Target Scanning
    local TargetCandidate, ClosestDist = nil, 999
    local ThreatsInCone = 0
    local MyForward = MyRoot.CFrame.LookVector
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            local EPos = v.Character.HumanoidRootPart.Position
            local Dist = (EPos - MyRoot.Position).Magnitude
            if Dist < 45 then
                if MyForward:Dot((EPos - MyRoot.Position).Unit) > 0.2 then ThreatsInCone = ThreatsInCone + 1 end
                if Dist < ClosestDist then ClosestDist = Dist; TargetCandidate = v end
            end
        end
    end
    
    getgenv().G_Apex.ActiveTarget = TargetCandidate
    getgenv().G_Apex.ThreatCount = ThreatsInCone
    
    -- B. Mode Selector
    if not TargetCandidate then
        getgenv().G_Apex.CurrentMode = "IDLE"
    else
        if getgenv().G_Apex.IsStriking then -- Busy
        elseif ThreatsInCone > 1 then getgenv().G_Apex.CurrentMode = "GHOST"
        else
            local Safe = AnalyzeTemporalIntent(TargetCandidate, MyRoot)
            getgenv().G_Apex.CanEngage = Safe
            getgenv().G_Apex.CurrentMode = Safe and "LETHAL" or "STALK"
        end
    end
    
    -- C. Execution (Physics)
    local ModeData = MODES[getgenv().G_Apex.CurrentMode] or MODES.STALK
    local GoalPos = MyRoot.Position
    local LookPos = MyRoot.Position + MyRoot.CFrame.LookVector * 10 -- Mặc định nhìn thẳng để không lỗi Camera
    
    if TargetCandidate then
        local EPos = TargetCandidate.Character.HumanoidRootPart.Position
        if ModeData.Type == "Solve" then
            local Escape = SolveEscapeVector(MyRoot)
            GoalPos = MyRoot.Position + (Escape.Unit * ModeData.Offset)
            LookPos = EPos
        elseif ModeData.Type == "Strike" then
            local Dir = (EPos - MyRoot.Position).Unit
            GoalPos = EPos - (Dir * ModeData.Offset)
            LookPos = EPos
        else -- Orbit
            local Dir = (MyRoot.Position - EPos).Unit
            GoalPos = EPos + (Dir * ModeData.Offset)
            LookPos = EPos
        end
    end
    
    Char.Humanoid.AutoRotate = not ModeData.RotateLock
    
    -- Fix Camera NaN Error
    if (GoalPos - LookPos).Magnitude < 0.5 then LookPos = LookPos + Vector3.new(0,0,1) end

    local GoalCF = CFrame.lookAt(Vector3.new(GoalPos.X, MyRoot.Position.Y, GoalPos.Z), Vector3.new(LookPos.X, MyRoot.Position.Y, LookPos.Z))
    
    if ModeData.Type == "Strike" then
        MyRoot.CFrame = MyRoot.CFrame:Lerp(GoalCF, 0.65)
    else
        MyRoot.CFrame = MyRoot.CFrame:Lerp(GoalCF, 0.25)
    end
    
    local MoveDir = (GoalPos - MyRoot.Position).Unit
    local TargetVel = Vector3.new(MoveDir.X * ModeData.VelMult, 0, MoveDir.Z * ModeData.VelMult)
    MyRoot.AssemblyLinearVelocity = MyRoot.AssemblyLinearVelocity:Lerp(TargetVel, 0.25)
end)

--// 6. COMBAT LOOP
task.spawn(function()
    local function Press(k)
        VirtualInputManager:SendKeyEvent(true, k, false, game); task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, k, false, game)
    end
    while true do
        task.wait()
        if not getgenv().G_Apex.Enabled then continue end
        local Target = getgenv().G_Apex.ActiveTarget
        if Target and getgenv().G_Apex.CanEngage and not getgenv().G_Apex.IsStriking then
            local Dist = (LocalPlayer.Character.HumanoidRootPart.Position - Target.Character.HumanoidRootPart.Position).Magnitude
            if Dist < 22 then
                getgenv().G_Apex.IsStriking = true
                Press(Enum.KeyCode.One); task.wait(0.15)
                local StillSafe = AnalyzeTemporalIntent(Target, LocalPlayer.Character.HumanoidRootPart)
                if not StillSafe or getgenv().G_Apex.ThreatCount > 1 then
                    getgenv().G_Apex.IsStriking = false; getgenv().G_Apex.CanEngage = false
                    task.wait(0.2); continue
                end
                Press(Enum.KeyCode.Four); task.wait(0.4)
                if getgenv().G_Apex.ThreatCount <= 1 then Press(Enum.KeyCode.Two) end
                getgenv().G_Apex.IsStriking = false; getgenv().G_Apex.CanEngage = false; task.wait(0.4)
            end
        end
    end
end)
