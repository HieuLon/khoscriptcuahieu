--[[ 
    GEMINI V18 OVERLORD - CLASSIC EDITION
    UI: Circular Button (Draggable) - Old Style
    CORE: V18 Brain (Intent + True Orbit + Backstab + Physic Constraints)
    AUTHOR: Refactored by AI Senior Developer
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--// 1. CẤU HÌNH & TRẠNG THÁI
getgenv().G_Apex = {
    Enabled = false,
    ActiveTarget = nil,
    IntentMemory = {}, 
    ThreatCount = 0,         
    CanEngage = false,       
    CurrentMode = "IDLE",
    -- Cooldown Tracker cho Combat Không Delay
    Cooldowns = {
        Skill1 = 0,
        Skill4 = 0,
        Skill2 = 0
    }
}

--// 2. PHYSICS PROFILES (ĐÃ ĐƯỢC TỐI ƯU HÓA TỐC ĐỘ LƯỚT)
local MODES = {
    -- OrbitSpeed: Tốc độ xoay vòng | Predict: Bật dự đoán hướng đi
    STALK   = {Offset = 14, OrbitSpeed = 3.5, Predict = false, Type = "Orbit"},
    LETHAL  = {Offset = 4,  OrbitSpeed = 0,   Predict = true,  Type = "Backstab"}, 
    GHOST   = {Offset = 25, OrbitSpeed = 0,   Predict = false, Type = "Solve"},
}

--// 3. UI SETUP - GIỮ NGUYÊN MENU HÌNH TRÒN CŨ
if game.CoreGui:FindFirstChild("GeminiV18_Classic") then game.CoreGui.GeminiV18_Classic:Destroy() end

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GeminiV18_Classic"
ScreenGui.ResetOnSpawn = false

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Name = "ApexToggle"
ToggleBtn.Size = UDim2.new(0, 60, 0, 60)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "OFF"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18
ToggleBtn.AutoButtonColor = true
ToggleBtn.BorderSizePixel = 2
ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)

local UICorner = Instance.new("UICorner", ToggleBtn)
UICorner.CornerRadius = UDim.new(1, 0)

local Shadow = Instance.new("UIStroke", ToggleBtn)
Shadow.Thickness = 2
Shadow.Color = Color3.fromRGB(255, 255, 255)

local dragging, dragInput, dragStart, startPos
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
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function CleanUpPhysics()
    local Char = LocalPlayer.Character
    if Char and Char:FindFirstChild("HumanoidRootPart") then
        local Root = Char.HumanoidRootPart
        if Root:FindFirstChild("ApexAP") then Root.ApexAP:Destroy() end
        if Root:FindFirstChild("ApexAO") then Root.ApexAO:Destroy() end
        if Root:FindFirstChild("ApexAtt") then Root.ApexAtt:Destroy() end
        Char.Humanoid.AutoRotate = true
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().G_Apex.Enabled = not getgenv().G_Apex.Enabled
    if getgenv().G_Apex.Enabled then
        ToggleBtn.Text = "ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50) -- Đổi sang màu Đỏ Sát thủ
        Shadow.Color = Color3.fromRGB(255, 50, 50)
        ToggleBtn.BorderColor3 = Color3.fromRGB(255, 50, 50)
    else
        ToggleBtn.Text = "OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Shadow.Color = Color3.fromRGB(255, 255, 255)
        ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        getgenv().G_Apex.CurrentMode = "IDLE"
        CleanUpPhysics()
    end
end)

--// 4. MÁY TRẠNG THÁI & PHÂN TÍCH (INTENT ENGINE)
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
    
    table.insert(Buff.Facings, 1, Facing)
    table.insert(Buff.Speeds, 1, Speed)
    table.insert(Buff.Positions, 1, TargetRoot.Position)
    
    if #Buff.Facings > 15 then 
        table.remove(Buff.Facings); table.remove(Buff.Speeds); table.remove(Buff.Positions) 
    end
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
                    if WorldDir.Unit:Dot((v.Character.HumanoidRootPart.Position - MyRoot.Position).Unit) > 0.5 then 
                        Score = Score - (1000/Dist) 
                    end 
                end
            end
        end
        if Workspace:Raycast(MyRoot.Position, WorldDir, RaycastParams.new()) then Score = Score - 5000 end
        if Score > MaxScore then MaxScore = Score; BestDir = WorldDir end
    end
    return BestDir or Vector3.new(0,0,1)
end

-- Tự động tạo Movers để Server đồng bộ chuyển động
local function SetupPhysicsMovers(Root)
    local AP = Root:FindFirstChild("ApexAP")
    local AO = Root:FindFirstChild("ApexAO")
    local Att = Root:FindFirstChild("ApexAtt")
    
    if not AP then
        Att = Instance.new("Attachment", Root)
        Att.Name = "ApexAtt"
        
        AP = Instance.new("AlignPosition", Root)
        AP.Name = "ApexAP"
        AP.Attachment0 = Att
        AP.Mode = Enum.PositionAlignmentMode.OneAttachment
        AP.MaxForce = 150000 
        AP.MaxVelocity = 120 -- Tốc độ lao đến mục tiêu cực gắt
        AP.Responsiveness = 100
        
        AO = Instance.new("AlignOrientation", Root)
        AO.Name = "ApexAO"
        AO.Attachment0 = Att
        AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        AO.MaxTorque = 150000
        AO.Responsiveness = 100
    end
    return AP, AO
end

--// 5. MAIN LOOP (MOVEMENT TỐI ƯU HÓA)
RunService.Heartbeat:Connect(function()
    if not getgenv().G_Apex.Enabled then return end
    
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    
    local MyRoot = Char.HumanoidRootPart
    local Hum = Char.Humanoid
    Hum.WalkSpeed = 16 
    
    -- Lấy Movers
    local AP, AO = SetupPhysicsMovers(MyRoot)
    
    -- A. Target Scanning
    local TargetCandidate, ClosestDist = nil, 999
    local ThreatsInCone = 0
    local MyForward = MyRoot.CFrame.LookVector
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            local EPos = v.Character.HumanoidRootPart.Position
            local Dist = (EPos - MyRoot.Position).Magnitude
            if Dist < 50 then
                if MyForward:Dot((EPos - MyRoot.Position).Unit) > 0.2 then ThreatsInCone = ThreatsInCone + 1 end
                if Dist < ClosestDist then ClosestDist = Dist; TargetCandidate = v end
            end
        end
    end
    
    getgenv().G_Apex.ActiveTarget = TargetCandidate
    getgenv().G_Apex.ThreatCount = ThreatsInCone
    
    -- B. Logic Xử Lý & Di Chuyển
    if not TargetCandidate then
        getgenv().G_Apex.CurrentMode = "IDLE"
        AP.Enabled = false
        AO.Enabled = false
        Hum.AutoRotate = true
        return
    end

    AP.Enabled = true
    AO.Enabled = true
    Hum.AutoRotate = false

    local TargetRoot = TargetCandidate.Character.HumanoidRootPart
    local EPos = TargetRoot.Position
    local Safe = AnalyzeTemporalIntent(TargetCandidate, MyRoot)
    getgenv().G_Apex.CanEngage = Safe
    
    -- Quyết định chế độ
    if ThreatsInCone > 1 then 
        getgenv().G_Apex.CurrentMode = "GHOST"
    else
        getgenv().G_Apex.CurrentMode = Safe and "LETHAL" or "STALK"
    end
    
    local ModeData = MODES[getgenv().G_Apex.CurrentMode]
    
    -- Lead Target (Dự đoán vị trí nếu địch đang di chuyển)
    if ModeData.Predict then
        local TargetVel = TargetRoot.AssemblyLinearVelocity
        EPos = EPos + (TargetVel * 0.15) -- Tiên đoán trước 0.15s
    end

    local GoalPos = MyRoot.Position
    local LookPos = EPos

    if ModeData.Type == "Solve" then
        -- Chạy trốn mượt mà
        local Escape = SolveEscapeVector(MyRoot)
        GoalPos = MyRoot.Position + (Escape.Unit * ModeData.Offset)
        
    elseif ModeData.Type == "Backstab" then
        -- Luồn ĐỘT NGỘT ra sau lưng kẻ địch (Enemy LookVector ngược lại)
        local EnemyBack = -TargetRoot.CFrame.LookVector
        GoalPos = EPos + (EnemyBack * ModeData.Offset)
        
    elseif ModeData.Type == "Orbit" then
        -- Xoay vòng quanh kẻ địch thực sự (True Orbit)
        local TimeSync = tick() * ModeData.OrbitSpeed
        local OrbitCircle = Vector3.new(math.cos(TimeSync) * ModeData.Offset, 0, math.sin(TimeSync) * ModeData.Offset)
        GoalPos = EPos + OrbitCircle
    end
    
    -- Sửa lỗi trục Y bị chìm/bay
    GoalPos = Vector3.new(GoalPos.X, EPos.Y, GoalPos.Z)
    
    -- Thực thi Vật Lý
    AP.Position = GoalPos
    
    -- Tránh lỗi Quaternion rác khi đứng quá gần (Khoảng cách < 0.5)
    if (MyRoot.Position - LookPos).Magnitude > 0.5 then
        AO.CFrame = CFrame.lookAt(MyRoot.Position, Vector3.new(LookPos.X, MyRoot.Position.Y, LookPos.Z))
    end
end)

--// 6. COMBAT LOOP (STATE MACHINE - KHÔNG TASK.WAIT CHẶN LUỒNG)
local function Press(k)
    VirtualInputManager:SendKeyEvent(true, k, false, game)
    task.delay(0.05, function() VirtualInputManager:SendKeyEvent(false, k, false, game) end)
end

RunService.RenderStepped:Connect(function()
    if not getgenv().G_Apex.Enabled then return end
    local Target = getgenv().G_Apex.ActiveTarget
    if not Target then return end

    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    local Dist = (MyRoot.Position - Target.Character.HumanoidRootPart.Position).Magnitude
    local Now = tick()

    -- Nếu đủ điều kiện dứt điểm
    if getgenv().G_Apex.CanEngage and Dist < 22 then
        -- Combo Logic (Tự chỉnh lại delay cooldown tùy game)
        if Now - getgenv().G_Apex.Cooldowns.Skill1 > 2.0 then -- Vd: Cooldown Skill 1 là 2s
            Press(Enum.KeyCode.One)
            getgenv().G_Apex.Cooldowns.Skill1 = Now
        end

        -- Chỉ xả Skill 4 nếu an toàn & đã dùng Skill 1 được một lúc (0.2s)
        if (Now - getgenv().G_Apex.Cooldowns.Skill1 > 0.2) and (Now - getgenv().G_Apex.Cooldowns.Skill4 > 3.0) then
            Press(Enum.KeyCode.Four)
            getgenv().G_Apex.Cooldowns.Skill4 = Now
        end

        -- Bồi Skill 2 nếu không bị hội đồng
        if getgenv().G_Apex.ThreatCount <= 1 and (Now - getgenv().G_Apex.Cooldowns.Skill4 > 0.5) and (Now - getgenv().G_Apex.Cooldowns.Skill2 > 4.0) then
            Press(Enum.KeyCode.Two)
            getgenv().G_Apex.Cooldowns.Skill2 = Now
        end
    end
end)
