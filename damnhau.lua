--[[ 
    GEMINI V17.1 STABLE - APEX PREDATOR
    PART 1: THE BRAIN & SMART OPTIMIZER
    
    [FIX LOG]:
    - Fixed Invisible Player: Script now ignores LocalPlayer when nuking textures.
    - Fixed Solid Screen: Water Transparency set to 1 (Invisible) instead of 0 (Solid).
    - UI: Adjusted for better visibility.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

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

--// 2. PHYSICS PROFILES
local MODES = {
    STALK   = {Offset = 14, Strict = false, VelMult = 2,   RotateLock = false, Type = "Orbit"},
    LETHAL  = {Offset = 4,  Strict = false, VelMult = 22,  RotateLock = true,  Type = "Strike"}, 
    GHOST   = {Offset = 18, Strict = false, VelMult = 45,  RotateLock = true,  Type = "Solve"},
}

--// 3. ZERO LATENCY ENGINE (SAFE MODE)
task.spawn(function()
    pcall(function()
        setfpscap(360) 
        
        -- Lighting: Tối ưu nhưng vẫn giữ độ sáng để nhìn thấy đường
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 2
        
        -- SMART NUKE: Chừa nhân vật của mình ra
        local MyChar = LocalPlayer.Character
        
        for _, v in pairs(Workspace:GetDescendants()) do
            -- [QUAN TRỌNG] Nếu là part của mình -> BỎ QUA, KHÔNG XÓA
            if MyChar and v:IsDescendantOf(MyChar) then 
                continue 
            end

            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy() -- Xóa họa tiết môi trường
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false -- Tắt hiệu ứng rác
            end
        end
        
        -- FIX NƯỚC: Chỉnh thành trong suốt (1) để không bị che màn hình
        if Workspace:FindFirstChildOfClass('Terrain') then
            Workspace.Terrain.WaterWaveSize = 0
            Workspace.Terrain.WaterWaveSpeed = 0
            Workspace.Terrain.WaterReflectance = 0
            Workspace.Terrain.WaterTransparency = 1 -- [FIXED] 1 = Trong suốt
        end
    end)
end)

--// 4. UI SETUP (HIGH CONTRAST)
if game.CoreGui:FindFirstChild("GeminiV17_Final") then game.CoreGui.GeminiV17_Final:Destroy() end
local ScreenGui = Instance.new("ScreenGui", game.CoreGui); ScreenGui.Name = "GeminiV17_Final"
local Btn = Instance.new("TextButton", ScreenGui)
Btn.Size = UDim2.new(0, 140, 0, 50); Btn.Position = UDim2.new(0.5, -70, 0.05, 0) -- Cao hơn xíu để dễ nhìn
Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Btn.BackgroundTransparency = 0.2
Btn.BorderColor3 = Color3.fromRGB(0, 255, 150); Btn.BorderSizePixel = 2
Btn.Text = "SYSTEM: READY"; Btn.TextColor3 = Color3.fromRGB(0, 255, 150); Btn.Font = Enum.Font.GothamBlack; Btn.TextSize = 14
local UICorner = Instance.new("UICorner", Btn); UICorner.CornerRadius = UDim.new(0, 6)

Btn.MouseButton1Click:Connect(function()
    getgenv().G_Apex.Enabled = not getgenv().G_Apex.Enabled
    Btn.Text = getgenv().G_Apex.Enabled and "APEX: HUNTING" or "SYSTEM: IDLE"
    Btn.TextColor3 = getgenv().G_Apex.Enabled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 150)
    Btn.BorderColor3 = getgenv().G_Apex.Enabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 150)
    
    if not getgenv().G_Apex.Enabled then
        getgenv().G_Apex.CurrentMode = "IDLE"
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
end)

--// 5. LOGIC & SOLVER (GIỮ NGUYÊN)
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
    
    local AvgFacing = 0
    for _, v in pairs(Buff.Facings) do AvgFacing = AvgFacing + v end
    AvgFacing = AvgFacing / #Buff.Facings
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
                if Dist < 35 then
                    if WorldDir.Unit:Dot((v.Character.HumanoidRootPart.Position - MyRoot.Position).Unit) > 0.5 then Score = Score - (1000/Dist) end
                end
            end
        end
        if Workspace:Raycast(MyRoot.Position, WorldDir, RaycastParams.new()) then Score = Score - 5000 end
        if Score > MaxScore then MaxScore = Score; BestDir = WorldDir end
    end
    return BestDir or Vector3.new(0,0,1)
end
--[[ 
    GEMINI V17.1 STABLE - PART 2: THE BODY
    [FIXED] Removed aggressive movement locks that caused camera glitches.
]]

RunService.Heartbeat:Connect(function()
    if not getgenv().G_Apex.Enabled then return end
    
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    
    -- [FIX] Chỉ dùng Move(0) mà không khóa cứng (tham số thứ 2 là false)
    Char.Humanoid.WalkSpeed = 16 
    Char.Humanoid:Move(Vector3.zero, false) -- Fix lỗi kẹt camera
    
    local MyRoot = Char.HumanoidRootPart
    
    -- A. THREAT GEOMETRY
    local TargetCandidate, ClosestDist = nil, 999
    local ThreatsInCone = 0
    local MyForward = MyRoot.CFrame.LookVector
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            local EPos = v.Character.HumanoidRootPart.Position
            local ToEnemy = (EPos - MyRoot.Position)
            local Dist = ToEnemy.Magnitude
            if Dist < 45 then
                if MyForward:Dot(ToEnemy.Unit) > 0.2 then ThreatsInCone = ThreatsInCone + 1 end
                if Dist < ClosestDist then ClosestDist = Dist; TargetCandidate = v end
            end
        end
    end
    
    getgenv().G_Apex.ActiveTarget = TargetCandidate
    getgenv().G_Apex.ThreatCount = ThreatsInCone
    
    -- B. STATE MACHINE
    if not TargetCandidate then
        getgenv().G_Apex.CurrentMode = "IDLE"
    else
        if getgenv().G_Apex.IsStriking then
            -- Busy
        elseif ThreatsInCone > 1 then
            getgenv().G_Apex.CurrentMode = "GHOST"
        else
            local Safe = AnalyzeTemporalIntent(TargetCandidate, MyRoot)
            getgenv().G_Apex.CanEngage = Safe
            getgenv().G_Apex.CurrentMode = Safe and "LETHAL" or "STALK"
        end
    end
    
    -- C. PHYSICS
    local ModeData = MODES[getgenv().G_Apex.CurrentMode] or MODES.STALK
    local GoalPos, LookPos = MyRoot.Position, MyRoot.Position
    
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
        else
            local Dir = (MyRoot.Position - EPos).Unit
            GoalPos = EPos + (Dir * ModeData.Offset)
            LookPos = EPos
        end
    end
    
    Char.Humanoid.AutoRotate = not ModeData.RotateLock
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
        VirtualInputManager:SendKeyEvent(true, k, false, game)
        task.wait(0.01)
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
                
                -- MID-COMBO CHECK
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
