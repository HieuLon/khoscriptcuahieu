--[[ 
    GEMINI V19 EXECUTIONER - CLASSIC EDITION
    CORE: Permanent Target Lock + Aggressive Spiral Orbit + Auto-Attack M1 + Precise 4-Skill Combo
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
    LockedTarget = nil, -- Mục tiêu bị ghim
    IntentMemory = {}, 
    ThreatCount = 0,         
    CanEngage = false,       
    CurrentMode = "IDLE",
    Cooldowns = {
        Skill1 = 0, Skill2 = 0, Skill3 = 0, Skill4 = 0, Attack = 0
    }
}

--// 2. PHYSICS PROFILES
local MODES = {
    -- Tốc độ xoay cực nhanh (8), bật dự đoán
    STALK   = {BaseOffset = 12, OrbitSpeed = 8, Predict = true,  Type = "Spiral"},
    LETHAL  = {BaseOffset = 4,  OrbitSpeed = 0, Predict = true,  Type = "Backstab"}, 
    GHOST   = {BaseOffset = 25, OrbitSpeed = 0, Predict = false, Type = "Solve"},
}

--// 3. UI SETUP (DRAGGABLE)
if game.CoreGui:FindFirstChild("GeminiV19_Classic") then game.CoreGui.GeminiV19_Classic:Destroy() end

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GeminiV19_Classic"
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
        ToggleBtn.Text = "KILL"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 0, 50)
        Shadow.Color = Color3.fromRGB(255, 0, 50)
        ToggleBtn.BorderColor3 = Color3.fromRGB(255, 0, 50)
    else
        ToggleBtn.Text = "OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Shadow.Color = Color3.fromRGB(255, 255, 255)
        ToggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        getgenv().G_Apex.CurrentMode = "IDLE"
        getgenv().G_Apex.LockedTarget = nil
        CleanUpPhysics()
    end
end)

--// 4. MÁY TRẠNG THÁI & MOVERS
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
        AP.MaxForce = 200000 
        AP.MaxVelocity = 150 -- Tăng kịch trần độ lướt
        AP.Responsiveness = 150
        
        AO = Instance.new("AlignOrientation", Root)
        AO.Name = "ApexAO"
        AO.Attachment0 = Att
        AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        AO.MaxTorque = 200000
        AO.Responsiveness = 150
    end
    return AP, AO
end

--// 5. MAIN LOOP (MOVEMENT & TARGET LOCK)
RunService.Heartbeat:Connect(function()
    if not getgenv().G_Apex.Enabled then return end
    
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local MyRoot = Char.HumanoidRootPart
    local Hum = Char.Humanoid
    Hum.WalkSpeed = 16 
    
    local AP, AO = SetupPhysicsMovers(MyRoot)
    
    -- A. Target Lock Logic (Ghim chết 1 thằng)
    local CurrentTarget = getgenv().G_Apex.LockedTarget
    local NeedNewTarget = false
    
    if not CurrentTarget or not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChild("Humanoid") or CurrentTarget.Character.Humanoid.Health <= 0 then
        NeedNewTarget = true
    elseif (CurrentTarget.Character.HumanoidRootPart.Position - MyRoot.Position).Magnitude > 150 then
        NeedNewTarget = true -- Xa quá thì bỏ
    end
    
    -- Tìm thằng gần nhất nếu cần đổi mục tiêu
    if NeedNewTarget then
        local ClosestDist = 999
        local NewTarget = nil
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
                local Dist = (v.Character.HumanoidRootPart.Position - MyRoot.Position).Magnitude
                if Dist < 50 and Dist < ClosestDist then
                    ClosestDist = Dist
                    NewTarget = v
                end
            end
        end
        getgenv().G_Apex.LockedTarget = NewTarget
        CurrentTarget = NewTarget
    end
    
    if not CurrentTarget then
        getgenv().G_Apex.CurrentMode = "IDLE"
        AP.Enabled = false; AO.Enabled = false; Hum.AutoRotate = true
        return
    end

    AP.Enabled = true; AO.Enabled = true; Hum.AutoRotate = false

    local TargetRoot = CurrentTarget.Character.HumanoidRootPart
    local EPos = TargetRoot.Position
    getgenv().G_Apex.CanEngage = true -- Luôn lao vào khô máu
    getgenv().G_Apex.CurrentMode = "STALK" -- Mặc định là xoay quấy rối
    
    -- Đếm mối đe dọa (Nếu bị hội đồng thì chạy)
    local ThreatsInCone = 0
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v ~= CurrentTarget and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            if (v.Character.HumanoidRootPart.Position - MyRoot.Position).Magnitude < 30 then
                ThreatsInCone = ThreatsInCone + 1
            end
        end
    end
    getgenv().G_Apex.ThreatCount = ThreatsInCone
    
    if ThreatsInCone > 1 then 
        getgenv().G_Apex.CurrentMode = "GHOST"
    end
    
    local ModeData = MODES[getgenv().G_Apex.CurrentMode]
    
    -- Prediction: Tiên đoán nhẹ để không bị hụt hướng
    if ModeData.Predict then
        EPos = EPos + (TargetRoot.AssemblyLinearVelocity * 0.1)
    end

    local GoalPos = MyRoot.Position
    local LookPos = TargetRoot.Position

    if ModeData.Type == "Solve" then
        GoalPos = MyRoot.Position + ((MyRoot.Position - EPos).Unit * ModeData.BaseOffset)
        
    elseif ModeData.Type == "Backstab" then
        GoalPos = EPos + (-TargetRoot.CFrame.LookVector * ModeData.BaseOffset)
        
    elseif ModeData.Type == "Spiral" then
        -- Vòng lặp xoay ảo ma: Offset thu hẹp và mở rộng liên tục
        local TimeSync = tick() * ModeData.OrbitSpeed
        local DynamicOffset = ModeData.BaseOffset - math.abs(math.sin(tick() * 2)) * (ModeData.BaseOffset - 3) -- Ra xa 12, chui sát vào 3
        local OrbitCircle = Vector3.new(math.cos(TimeSync) * DynamicOffset, 0, math.sin(TimeSync) * DynamicOffset)
        GoalPos = EPos + OrbitCircle
    end
    
    GoalPos = Vector3.new(GoalPos.X, EPos.Y, GoalPos.Z)
    AP.Position = GoalPos
    
    if (MyRoot.Position - LookPos).Magnitude > 0.5 then
        AO.CFrame = CFrame.lookAt(MyRoot.Position, Vector3.new(LookPos.X, MyRoot.Position.Y, LookPos.Z))
    end
end)

--// 6. COMBAT LOOP (ĐÁNH THƯỜNG + 4 SKILL QUÉT LIÊN TỤC)
local function PressKey(k)
    VirtualInputManager:SendKeyEvent(true, k, false, game)
    task.delay(0.05, function() VirtualInputManager:SendKeyEvent(false, k, false, game) end)
end

local function AutoAttackM1()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.delay(0.05, function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1) end)
end

RunService.RenderStepped:Connect(function()
    if not getgenv().G_Apex.Enabled then return end
    local Target = getgenv().G_Apex.LockedTarget
    if not Target or not Target.Character then return end

    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local TargetRoot = Target.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot or not TargetRoot then return end
    
    local Dist = (MyRoot.Position - TargetRoot.Position).Magnitude
    local Now = tick()

    -- Đánh thường (M1) liên tục nếu ở gần (< 15 studs)
    if Dist < 15 and (Now - getgenv().G_Apex.Cooldowns.Attack > 0.3) then -- Đấm khoảng 3 phát / 1 giây
        AutoAttackM1()
        getgenv().G_Apex.Cooldowns.Attack = Now
    end

    -- Logic Tung Chiêu (Kiểm tra xem mặt đã quay đúng về địch chưa mới tung chiêu)
    local ToTarget = (TargetRoot.Position - MyRoot.Position).Unit
    local MyFacing = MyRoot.CFrame.LookVector
    local IsFacingTarget = MyFacing:Dot(ToTarget) > 0.85 -- Trúng 100% khi góc đủ hẹp
    
    if Dist < 25 and IsFacingTarget then
        -- Cứ hết hồi chiêu là nã (Cần tự chỉnh số giây Cooldown cho chuẩn game của bạn)
        if Now - getgenv().G_Apex.Cooldowns.Skill1 > 3.0 then 
            PressKey(Enum.KeyCode.One)
            getgenv().G_Apex.Cooldowns.Skill1 = Now
        end

        if Now - getgenv().G_Apex.Cooldowns.Skill2 > 4.0 then 
            PressKey(Enum.KeyCode.Two)
            getgenv().G_Apex.Cooldowns.Skill2 = Now
        end

        if Now - getgenv().G_Apex.Cooldowns.Skill3 > 5.0 then 
            PressKey(Enum.KeyCode.Three)
            getgenv().G_Apex.Cooldowns.Skill3 = Now
        end

        -- Chiêu cuối thường uy lực, xả khi địch ở gần hơn một chút (< 20)
        if Dist < 20 and Now - getgenv().G_Apex.Cooldowns.Skill4 > 8.0 then 
            PressKey(Enum.KeyCode.Four)
            getgenv().G_Apex.Cooldowns.Skill4 = Now
        end
    end
end)
