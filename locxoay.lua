--[[ 
    CINEMA FLING HYBRID: ZENITH EDITION (V17 + V20 COMBINED)
    - Target Moving: V20 Absolute Lock (Sticky Drill)
    - Target Idle: V17 Skyhook Elite (Sky Drag)
    - Features: Blacklist (Loop Kill), Whitelist (Safe), Auto-Detection
]]

if getgenv().ZenithLoaded then
    return
end
getgenv().ZenithLoaded = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- CẤU HÌNH HỆ THỐNG
----------------------------------------------------------------
getgenv().Config = {
    AutoFling = false,
    BlacklistEnabled = false,
    Whitelist = {},
    Blacklist = {},
    DragHeight = 600,
    SpinSpeed = 25000,
    IdleHeight = 150
}

local IsAttacking = false
local SelectedPlayer = ""

----------------------------------------------------------------
-- HÀM HỖ TRỢ (UTILITIES)
----------------------------------------------------------------
local function IsWhitelisted(player)
    return table.find(getgenv().Config.Whitelist, player.Name) ~= nil
end

local function IsBlacklisted(player)
    return table.find(getgenv().Config.Blacklist, player.Name) ~= nil
end

local function GetCharacterParts(target)
    if not target or not target.Character then return nil end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    local hum = target.Character:FindFirstChild("Humanoid")
    return root, hum
end

----------------------------------------------------------------
-- CORE HYBRID ATTACK LOGIC
----------------------------------------------------------------
local function HybridAttack(target)
    local TRoot, THum = GetCharacterParts(target)
    local MyRoot, MyHum = GetCharacterParts(LocalPlayer)
    
    if not TRoot or not MyRoot or IsAttacking then return end
    IsAttacking = true

    -- Noclip logic
    local Noclip = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)

    MyHum.PlatformStand = true
    
    -- Kiểm tra trạng thái mục tiêu: Di chuyển hay Đứng im?
    local isMoving = TRoot.Velocity.Magnitude > 2

    if isMoving then
        -- [LOGIC V20: ABSOLUTE LOCK]
        local BAV = Instance.new("BodyAngularVelocity", MyRoot)
        BAV.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        BAV.AngularVelocity = Vector3.new(0, getgenv().Config.SpinSpeed, 0)

        local BP = Instance.new("BodyPosition", MyRoot)
        BP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BP.P = 15000
        BP.D = 150

        local AttackLoop = RunService.RenderStepped:Connect(function()
            if not TRoot.Parent then return end
            BP.Position = TRoot.Position
            MyRoot.CFrame = TRoot.CFrame * CFrame.new(0, 0, 0.5) -- Khoan trực diện
            MyRoot.RotVelocity = Vector3.new(0, 15000, 0)
        end)

        task.wait(2.5) -- Thời gian khoan
        AttackLoop:Disconnect()
        BAV:Destroy()
        BP:Destroy()
    else
        -- [LOGIC V17: SKYHOOK]
        local Att = Instance.new("Attachment", MyRoot)
        local LV = Instance.new("LinearVelocity", MyRoot)
        LV.Attachment0 = Att
        LV.MaxForce = math.huge
        LV.VectorVelocity = Vector3.new(0, 12000, 0)

        local AttackLoop = RunService.Heartbeat:Connect(function()
            if not TRoot.Parent then return end
            MyRoot.CFrame = TRoot.CFrame * CFrame.new(0, -2, 0) -- Dưới chân kéo lên
        end)

        -- Đợi đến khi đạt độ cao hoặc timeout
        local start = tick()
        repeat task.wait() until TRoot.Position.Y > getgenv().Config.DragHeight or (tick() - start > 2)

        AttackLoop:Disconnect()
        LV:Destroy()
        Att:Destroy()
    end

    -- Reset
    Noclip:Disconnect()
    MyHum.PlatformStand = false
    MyRoot.Velocity = Vector3.zero
    MyRoot.RotVelocity = Vector3.zero
    IsAttacking = false
end

----------------------------------------------------------------
-- GIAO DIỆN RAYFIELD UI
----------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Zenith Hybrid Fling V26",
    LoadingTitle = "Initializing Hybrid Systems...",
    ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("Tấn Công", 4483362458)
local ListTab = Window:CreateTab("Danh Sách", 4483362458)

MainTab:CreateToggle({
    Name = "AUTO HYBRID FLING",
    CurrentValue = false,
    Callback = function(v) 
        getgenv().Config.AutoFling = v 
        if v then
            task.spawn(function()
                while getgenv().Config.AutoFling do
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and not IsWhitelisted(p) then
                            -- Ưu tiên Blacklist nếu đang bật
                            if getgenv().Config.BlacklistEnabled and IsBlacklisted(p) then
                                HybridAttack(p)
                            elseif not getgenv().Config.BlacklistEnabled then
                                HybridAttack(p)
                            end
                        end
                        if not getgenv().Config.AutoFling then break end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

MainTab:CreateToggle({
    Name = "CHẾ ĐỘ TRUY SÁT (Blacklist Only)",
    CurrentValue = false,
    Callback = function(v) getgenv().Config.BlacklistEnabled = v end
})

MainTab:CreateSlider({
    Name = "Độ cao Skyhook (V17)",
    Range = {300, 5000},
    Increment = 100,
    CurrentValue = 600,
    Callback = function(v) getgenv().Config.DragHeight = v end
})

-- Whitelist / Blacklist UI
local PlayerDrop = ListTab:CreateDropdown({
    Name = "Chọn Player",
    Options = {},
    CurrentOption = "",
    Callback = function(v) SelectedPlayer = v[1] end
})

ListTab:CreateButton({
    Name = "Làm mới danh sách",
    Callback = function()
        local names = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(names, p.Name) end
        end
        PlayerDrop:Refresh(names)
    end
})

ListTab:CreateButton({
    Name = "Thêm vào WHITELIST (Né)",
    Callback = function()
        if SelectedPlayer ~= "" and not table.find(getgenv().Config.Whitelist, SelectedPlayer) then
            table.insert(getgenv().Config.Whitelist, SelectedPlayer)
            Rayfield:Notify({Title = "Whitelist", Content = "Đã thêm " .. SelectedPlayer})
        end
    end
})

ListTab:CreateButton({
    Name = "Thêm vào BLACKLIST (Đá liên tục)",
    Callback = function()
        if SelectedPlayer ~= "" and not table.find(getgenv().Config.Blacklist, SelectedPlayer) then
            table.insert(getgenv().Config.Blacklist, SelectedPlayer)
            Rayfield:Notify({Title = "Blacklist", Content = "Đã thêm " .. SelectedPlayer})
        end
    end
})

ListTab:CreateButton({
    Name = "Xóa sạch danh sách",
    Callback = function()
        getgenv().Config.Whitelist = {}
        getgenv().Config.Blacklist = {}
        Rayfield:Notify({Title = "Reset", Content = "Đã xóa sạch các danh sách!"})
    end
})

-- Idle Loop (Chống rơi khi không làm gì)
RunService.Heartbeat:Connect(function()
    if getgenv().Config.AutoFling and not IsAttacking then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = CFrame.new(root.Position.X, getgenv().Config.IdleHeight, root.Position.Z)
        end
    end
end)

Rayfield:LoadConfiguration()
