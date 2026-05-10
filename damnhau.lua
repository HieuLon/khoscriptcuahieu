--[[ 
    ZENITH V6: SKILL MASTER (AUTO SKILL & TIMING)
    - Rotation Logic: Xoay vòng chiêu 1->2->3->4 để tối ưu hồi chiêu
    - Skill Manager: Chọn chiêu muốn dùng (1, 2, 3, 4 hoặc Click)
    - Animation Wait: Tùy chỉnh thời gian chờ để chiêu tung ra hết
]]

if getgenv().ZenithLoaded then
    game.StarterGui:SetCore("SendNotification", {Title = "Zenith V6", Text = "Script đang chạy!", Duration = 3})
    return
end
getgenv().ZenithLoaded = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- CẤU HÌNH
----------------------------------------------------------------
getgenv().Config = {
    Enabled = false,
    SafeHeight = 18,        
    AttackInterval = 2.5,   -- Thời gian giữa các lần lao xuống
    HoldTime = 0.5,         -- Thời gian giữ dưới đất (Phải đủ lâu để múa skill)
    
    -- CẤU HÌNH CHIÊU THỨC
    UseClick = true,        -- Dùng chuột trái
    UseSkill1 = true,       -- Dùng phím 1
    UseSkill2 = true,       -- Dùng phím 2
    UseSkill3 = true,       -- Dùng phím 3
    UseSkill4 = true,       -- Dùng phím 4
    
    ComboMode = "Rotation", -- "Rotation" (Xoay vòng) hoặc "Spam" (Dồn hết)
    AutoEscape = true
}

local State = {
    IsActive = false,
    Target = nil,
    IsDiving = false,
    NextDiveTime = 0,
    LastAttackStart = 0,
    SkillIndex = 1 -- Biến đếm thứ tự chiêu cho chế độ Rotation
}

----------------------------------------------------------------
-- HÀM XỬ LÝ PHÍM (AUTO SKILL)
----------------------------------------------------------------
local function PressKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function ExecuteAttack()
    -- 1. Đánh thường (Luôn kích hoạt nếu bật)
    if getgenv().Config.UseClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end

    -- 2. Xử lý Skill theo chế độ
    local skills = {}
    if getgenv().Config.UseSkill1 then table.insert(skills, Enum.KeyCode.One) end
    if getgenv().Config.UseSkill2 then table.insert(skills, Enum.KeyCode.Two) end
    if getgenv().Config.UseSkill3 then table.insert(skills, Enum.KeyCode.Three) end
    if getgenv().Config.UseSkill4 then table.insert(skills, Enum.KeyCode.Four) end

    if #skills == 0 then return end

    if getgenv().Config.ComboMode == "Spam" then
        -- Chế độ Spam: Ấn hết các phím đã chọn
        for _, key in ipairs(skills) do
            PressKey(key)
            task.wait(0.1) -- Delay nhỏ để không bị nuốt phím
        end
    
    elseif getgenv().Config.ComboMode == "Rotation" then
        -- Chế độ Xoay vòng: Mỗi lần lao xuống dùng 1 chiêu tiếp theo
        if State.SkillIndex > #skills then State.SkillIndex = 1 end
        
        local currentKey = skills[State.SkillIndex]
        if currentKey then
            PressKey(currentKey)
            -- Thông báo nhẹ
            game.StarterGui:SetCore("SendNotification", {
                Title = "Combo", 
                Text = "Dùng chiêu: " .. tostring(State.SkillIndex), 
                Duration = 1
            })
        end
        State.SkillIndex = State.SkillIndex + 1
    end
end

----------------------------------------------------------------
-- LOGIC PHANTOM (DI CHUYỂN)
----------------------------------------------------------------
local function GetTarget()
    local closest, maxDist = nil, 300
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if p.Character.Humanoid.Health > 0 then
                local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if d < maxDist then
                    closest = p
                    maxDist = d
                end
            end
        end
    end
    return closest
end

local function PhantomLoop()
    RunService.RenderStepped:Connect(function()
        if not getgenv().Config.Enabled or not State.IsActive or not State.Target then return end
        
        local enemy = State.Target
        if not enemy.Character or not enemy.Character:FindFirstChild("HumanoidRootPart") or enemy.Character.Humanoid.Health <= 0 then
            State.IsActive = false
            State.Target = nil
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.PlatformStand = false
            end
            return
        end

        local eRoot = enemy.Character.HumanoidRootPart
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHum = LocalPlayer.Character:FindFirstChild("Humanoid")

        if myRoot and myHum then
            myHum.PlatformStand = true
            myRoot.Velocity = Vector3.zero
            myRoot.RotVelocity = Vector3.zero
            for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end

            local currentTime = tick()
            
            -- [[ LOGIC LAO XUỐNG & DÙNG CHIÊU ]]
            if State.IsDiving then
                -- Tele ra sau lưng 2.5m
                local attackPos = eRoot.CFrame * CFrame.new(0, 0, 2.5)
                myRoot.CFrame = CFrame.new(attackPos.Position, eRoot.Position)
                
                -- Hết thời gian "Ngâm" thì bay lên
                if currentTime - State.LastAttackStart > getgenv().Config.HoldTime then
                    State.IsDiving = false
                    State.NextDiveTime = currentTime + getgenv().Config.AttackInterval
                end
            else
                -- [[ LOGIC TRÊN TRỜI ]]
                local timeLeft = State.NextDiveTime - currentTime
                
                if timeLeft <= 0 then
                    -- Bắt đầu lao xuống
                    State.IsDiving = true
                    State.LastAttackStart = currentTime
                    -- GỌI HÀM DÙNG CHIÊU
                    task.spawn(ExecuteAttack) 
                else
                    -- Cảnh báo rung lắc
                    if timeLeft < 0.5 then
                        myRoot.CFrame = myRoot.CFrame + Vector3.new(math.random()-0.5, 0, math.random()-0.5)
                    end
                    -- Bay lơ lửng
                    local wobbleX = math.cos(tick() * 3) * 4
                    local wobbleZ = math.sin(tick() * 3) * 4
                    local skyPos = eRoot.Position + Vector3.new(wobbleX, getgenv().Config.SafeHeight, wobbleZ)
                    myRoot.CFrame = CFrame.new(skyPos, eRoot.Position)
                end
            end
        end
    end)
end

local function InitAutoDefense()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local oldHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < oldHp then
            if getgenv().Config.AutoEscape and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                 LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 50, 0)
            end
            
            if getgenv().Config.Enabled and not State.IsActive then
                local enemy = GetTarget()
                if enemy then
                    State.Target = enemy
                    State.IsActive = true
                    State.NextDiveTime = tick() + 1
                    State.SkillIndex = 1 -- Reset combo
                end
            end
        end
        oldHp = hp
    end)
end

----------------------------------------------------------------
-- MENU ĐIỀU KHIỂN
----------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Zenith V6: Skill Master",
    LoadingTitle = "Đang nạp dữ liệu chiêu thức...",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local MainTab = Window:CreateTab("Auto Combat", 4483345998)
local SkillTab = Window:CreateTab("Cài Đặt Chiêu", 4483345998)

-- TRẠNG THÁI
local StatusLbl = MainTab:CreateLabel("Trạng thái: 💤")
task.spawn(function()
    while task.wait(0.1) do
        if State.IsActive and State.Target then
            if State.IsDiving then
                StatusLbl:Set("🔥 ĐANG XẢ CHIÊU 🔥")
                StatusLbl.Color = Color3.fromRGB(255, 0, 0)
            else
                local t = math.max(0, math.floor((State.NextDiveTime - tick())*10)/10)
                StatusLbl:Set("⏳ Hồi chiêu: " .. t .. "s")
                StatusLbl.Color = Color3.fromRGB(0, 255, 100)
            end
        else
            StatusLbl:Set("Trạng thái: 💤 Đang nghỉ")
            StatusLbl.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end)

MainTab:CreateToggle({
    Name = "KÍCH HOẠT (Master Switch)",
    CurrentValue = false,
    Callback = function(v)
        getgenv().Config.Enabled = v
        if v then InitAutoDefense() 
        else State.IsActive = false end
    end
})

MainTab:CreateDropdown({
    Name = "Chế độ Combo",
    Options = {"Rotation", "Spam"},
    CurrentOption = "Rotation",
    Flag = "ModeDrop",
    Callback = function(Option)
        getgenv().Config.ComboMode = Option[1]
    end,
})

-- TAB SKILL
SkillTab:CreateLabel("Chọn các chiêu muốn dùng:")

SkillTab:CreateToggle({
    Name = "Dùng Chuột Trái (M1)",
    CurrentValue = true,
    Callback = function(v) getgenv().Config.UseClick = v end,
})

SkillTab:CreateToggle({
    Name = "Dùng Chiêu [1]",
    CurrentValue = true,
    Callback = function(v) getgenv().Config.UseSkill1 = v end,
})

SkillTab:CreateToggle({
    Name = "Dùng Chiêu [2]",
    CurrentValue = true,
    Callback = function(v) getgenv().Config.UseSkill2 = v end,
})

SkillTab:CreateToggle({
    Name = "Dùng Chiêu [3]",
    CurrentValue = true,
    Callback = function(v) getgenv().Config.UseSkill3 = v end,
})

SkillTab:CreateToggle({
    Name = "Dùng Chiêu [4]",
    CurrentValue = true,
    Callback = function(v) getgenv().Config.UseSkill4 = v end,
})

SkillTab:CreateSlider({
    Name = "Thời gian Múa (Hold Time)",
    Range = {0.1, 2.0},
    Increment = 0.1,
    Suffix = "Giây",
    CurrentValue = 0.5,
    Callback = function(v) getgenv().Config.HoldTime = v end,
})

SkillTab:CreateSlider({
    Name = "Khoảng cách Dive (Attack Interval)",
    Range = {1.5, 6.0},
    Increment = 0.1,
    Suffix = "Giây",
    CurrentValue = 2.5,
    Callback = function(v) getgenv().Config.AttackInterval = v end,
})

PhantomLoop()
LocalPlayer.CharacterAdded:Connect(InitAutoDefense)
Rayfield:LoadConfiguration()
