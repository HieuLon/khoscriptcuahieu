--[[ 
    GEMINI V18 FINAL - BATTLEGROUNDS PREDATOR
    META UPGRADE: Dynamic Orbit, Cooldown Tracking, M1 Punish Combos.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

--// 1. TRẠNG THÁI & QUẢN LÝ HỒI CHIÊU (COOLDOWN TRACKER)
getgenv().G_Apex = {
    Enabled = false,
    LockedTarget = nil,
    IntentMemory = {}, 
    CombatState = "ORBIT", -- ORBIT hoặc PUNISH
    
    -- Trình quản lý hồi chiêu (Lưu thời điểm chiêu sẵn sàng)
    CDs = {
        M1 = 0, S1 = 0, S2 = 0, S3 = 0, S4 = 0
    }
}

-- Cấu hình thời gian hồi chiêu (Giả lập theo Battlegrounds Meta)
local CD_TIMES = {
    M1 = 0.4,  -- Tốc độ đấm
    S1 = 5.0,  -- Chiêu cấu rỉa
    S2 = 8.0,  -- Chiêu nối combo
    S3 = 6.0,  -- Chiêu cấu rỉa 2
    S4 = 15.0  -- Chiêu cuối/Finisher
}

--// 2. GIAO DIỆN HIỆN ĐẠI (TWEEN UI)
if game.CoreGui:FindFirstChild("GeminiV18_BG") then game.CoreGui.GeminiV18_BG:Destroy() end
local ScreenGui = Instance.new("ScreenGui", game.CoreGui); ScreenGui.Name = "GeminiV18_BG"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); MainFrame.Position = UDim2.new(0.5, -100, 0.2, 0); MainFrame.Size = UDim2.new(0, 200, 0, 110)
MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.BackgroundTransparency = 1; Title.Size = UDim2.new(1, 0, 0, 30); Title.Font = Enum.Font.GothamBlack; Title.Text = "GEMINI V18: BG PREDATOR"; Title.TextColor3 = Color3.fromRGB(255, 80, 80); Title.TextSize = 13
local TargetLabel = Instance.new("TextLabel", MainFrame)
TargetLabel.BackgroundTransparency = 1; TargetLabel.Position = UDim2.new(0, 0, 0, 30); TargetLabel.Size = UDim2.new(1, 0, 0, 20); TargetLabel.Font = Enum.Font.Gotham; TargetLabel.Text = "Target: NONE"; TargetLabel.TextColor3 = Color3.fromRGB(150, 150, 150); TargetLabel.TextSize = 11
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50); ToggleBtn.Position = UDim2.new(0.1, 0, 0, 60); ToggleBtn.Size = UDim2.new(0.8, 0, 0, 35); ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.Text = "ENGAGE: OFF"; ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200); ToggleBtn.TextSize = 13
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().G_Apex.Enabled = not getgenv().G_Apex.Enabled
    if getgenv().G_Apex.Enabled then
        ToggleBtn.Text = "ENGAGE: ON"; ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0); ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    else
        ToggleBtn.Text = "ENGAGE: OFF"; ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50); ToggleBtn.TextColor3 = Color3.fromRGB(200,200,200)
        getgenv().G_Apex.LockedTarget = nil; TargetLabel.Text = "Target: NONE"
        getgenv().G_Apex.CombatState = "ORBIT"
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.AutoRotate = true end
    end
end)

--// 3. HÀM TIỆN ÍCH AN TOÀN
local function GetSafeUnit(Vector)
    if Vector.Magnitude > 0.001 then return Vector.Unit end
    return Vector3.new(0, 0, 1)
end

local function IsReady(SkillName)
    return tick() >= getgenv().G_Apex.CDs[SkillName]
end

local function SetCD(SkillName)
    getgenv().G_Apex.CDs[SkillName] = tick() + CD_TIMES[SkillName]
end

--// 4. CHỌN MỤC TIÊU (LOCK-ON)
local function UpdateTargetLock()
    if not getgenv().G_Apex.Enabled then return end
    local C_Target = getgenv().G_Apex.LockedTarget
    if not C_Target or not C_Target.Character or not C_Target.Character:FindFirstChild("Humanoid") or C_Target.Character.Humanoid.Health <= 0 then
        local MinDist = math.huge; local NewTarget = nil
        for _, E in pairs(Players:GetPlayers()) do
            if E ~= LocalPlayer and E.Character and E.Character:FindFirstChild("HumanoidRootPart") and E.Character.Humanoid.Health > 0 then
                local Dist = (E.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Dist < MinDist then MinDist = Dist; NewTarget = E end
            end
        end
        getgenv().G_Apex.LockedTarget = NewTarget
        TargetLabel.Text = NewTarget and ("LOCKED: " .. NewTarget.Name) or "Scanning..."
    end
end

--// 5. THE BRAIN: NHẬN DIỆN DASH / TRƯỢT CHIÊU
local function GetTargetBuffer(Player)
    if not getgenv().G_Apex.IntentMemory[Player] then getgenv().G_Apex.IntentMemory[Player] = {Speeds = {}, Positions = {}} end
    return getgenv().G_Apex.IntentMemory[Player]
end

local function DetectVulnerability(TargetPlayer)
    local TargetRoot = TargetPlayer.Character.HumanoidRootPart
    local Buff = GetTargetBuffer(TargetPlayer)
    
    local Speed = TargetRoot.AssemblyLinearVelocity.Magnitude
    table.insert(Buff.Speeds, 1, Speed)
    table.insert(Buff.Positions, 1, TargetRoot.Position)
    
    if #Buff.Speeds > 10 then table.remove(Buff.Speeds); table.remove(Buff.Positions) end
    if #Buff.Speeds < 5 then return false end
    
    -- Nếu địch vừa Dash (Tốc độ cao đột ngột rồi giảm) hoặc đang đứng yên vung chiêu -> TẠO LỖ HỔNG
    local DashEnd = (Buff.Speeds[1] < Buff.Speeds[3]) and (Buff.Speeds[3] > 30) and (Buff.Speeds[1] < 10)
    return DashEnd
end

--// 6. THE LEGS (DI CHUYỂN TOÁN HỌC: ORBIT VÀ PUNISH)
local OrbitAngle = 0
RunService.Heartbeat:Connect(function(dt)
    UpdateTargetLock()
    if not getgenv().G_Apex.Enabled then return end
    local Char = LocalPlayer.Character; if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local MyRoot = Char.HumanoidRootPart
    local Target = getgenv().G_Apex.LockedTarget; if not Target then return end
    local TargetRoot = Target.Character.HumanoidRootPart
    
    Char.Humanoid.WalkSpeed = 16 
    Char.Humanoid:Move(Vector3.zero, true)
    
    -- Đọc sơ hở để đổi State
    if getgenv().G_Apex.CombatState == "ORBIT" then
        if DetectVulnerability(Target) then
            getgenv().G_Apex.CombatState = "PUNISH"
        end
    end
    
    local GoalPos, LookPos = MyRoot.Position, TargetRoot.Position
    
    if getgenv().G_Apex.CombatState == "ORBIT" then
        -- DI CHUYỂN VÒNG TRÒN (20 STUDS)
        OrbitAngle = OrbitAngle + (dt * 1.5) -- Tốc độ quay
        local OffsetX = math.cos(OrbitAngle) * 20
        local OffsetZ = math.sin(OrbitAngle) * 20
        GoalPos = TargetRoot.Position + Vector3.new(OffsetX, 0, OffsetZ)
        
        Char.Humanoid.AutoRotate = false
        MyRoot.CFrame = MyRoot.CFrame:Lerp(CFrame.lookAt(MyRoot.Position, Vector3.new(TargetRoot.Position.X, MyRoot.Position.Y, TargetRoot.Position.Z)), 0.3)
        
        local MoveDir = GetSafeUnit(GoalPos - MyRoot.Position)
        MyRoot.AssemblyLinearVelocity = MyRoot.AssemblyLinearVelocity:Lerp(Vector3.new(MoveDir.X * 25, 0, MoveDir.Z * 25), 0.3)
        
    elseif getgenv().G_Apex.CombatState == "PUNISH" then
        -- KHOÁ CHẶT SAU LƯNG ĐỂ ĐẤM (3 STUDS)
        local BackPos = TargetRoot.Position - (TargetRoot.CFrame.LookVector * 3)
        GoalPos = BackPos
        LookPos = TargetRoot.Position
        
        Char.Humanoid.AutoRotate = false
        MyRoot.CFrame = CFrame.lookAt(Vector3.new(GoalPos.X, TargetRoot.Position.Y, GoalPos.Z), Vector3.new(LookPos.X, TargetRoot.Position.Y, LookPos.Z))
        MyRoot.AssemblyLinearVelocity = Vector3.zero -- Phanh gấp để combo
    end
end)

--// 7. THE FISTS (HỆ THỐNG COMBO VÀ BẤM PHÍM CHUẨN)
task.spawn(function()
    local function Press(key)
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.02); VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
    
    local function Punch()
        -- Giả lập click chuột trái (M1) cho Battlegrounds
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.02); VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end

    while true do
        task.wait(0.05)
        if not getgenv().G_Apex.Enabled then continue end
        local Target = getgenv().G_Apex.LockedTarget
        if not Target or not Target.Character then continue end
        
        local Dist = (LocalPlayer.Character.HumanoidRootPart.Position - Target.Character.HumanoidRootPart.Position).Magnitude
        
        if getgenv().G_Apex.CombatState == "ORBIT" then
            -- Khi ở ngoài xa: Spam chiêu cấu rỉa (1 và 3)
            if Dist > 10 and Dist < 30 then
                if IsReady("S1") then Press(Enum.KeyCode.One); SetCD("S1"); task.wait(0.5) end
                if IsReady("S3") then Press(Enum.KeyCode.Three); SetCD("S3"); task.wait(0.5) end
            end
            
        elseif getgenv().G_Apex.CombatState == "PUNISH" then
            -- KHI VÀO FORM PUNISH (Sau lưng địch) -> THỰC HIỆN CHUỖI M1
            task.wait(0.1) -- Đợi CFrame đồng bộ
            
            -- Combo 4 hit M1 chuẩn Battleground
            for i = 1, 4 do
                if IsReady("M1") then Punch(); SetCD("M1") end
                task.wait(0.35) -- Tốc độ nhịp M1
            end
            
            -- Kết thúc chuỗi bằng Skill nối
            if IsReady("S2") then 
                Press(Enum.KeyCode.Two); SetCD("S2")
            elseif IsReady("S4") then 
                Press(Enum.KeyCode.Four); SetCD("S4")
            end
            
            task.wait(0.5) -- Đợi animation ra chiêu
            getgenv().G_Apex.CombatState = "ORBIT" -- RÚT VỀ THẢ DIỀU
        end
    end
end)
