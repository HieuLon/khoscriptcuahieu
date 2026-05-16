--[[ 
    RAYFIELD MOBILE - HYBRID FARM V7 (ANTI-SINK & INDIVIDUAL DELETE)
    Update Log:
    - Fix: Set điểm sẽ tự động nâng cao độ (Y + 3) để không bị lún đất khi Tele/Tween.
    - Add: 3 Nút xóa riêng biệt cho Safe, PreSafe (Mid), FarmSpot.
    - Keep: Spirit Mode (Anti-Gravity), Auto Farm, Stats Loop.
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- --- BIẾN CẤU HÌNH ---
local Config = {
    -- Map Points
    SafeZoneCFrame = nil,
    PreSafeCFrame = nil,
    FarmSpotCFrame = nil,
    
    -- Auto Farm
    IsBusy = false,       
    TweenSpeed = 1200,
    WaitTime = 0.8,       
    AutoFarm = false,
    InstantPrompt = true,
    
    -- Spirit Mode
    SpiritMode = false,
    OriginalBodyCFrame = nil,
    GhostSpeed = 2, 
    
    -- Player Stats
    WalkSpeed = 16,
    JumpPower = 50,
    LoopStats = false
}

-- --- HỆ THỐNG VISUAL ---
local visSafe, visPre, visFarm, visBodyDummy

local function updateVisuals()
    if visSafe then visSafe:Destroy() visSafe = nil end
    if visPre then visPre:Destroy() visPre = nil end
    if visFarm then visFarm:Destroy() visFarm = nil end

    local function createVis(name, color, cf)
        local p = Instance.new("Part", workspace)
        p.Name = name; p.Anchored = true; p.CanCollide = false
        p.Size = Vector3.new(2, 500, 2); p.Transparency = 0.6
        p.Material = Enum.Material.Neon; p.Color = color
        p.CFrame = cf
        return p
    end

    if Config.SafeZoneCFrame then visSafe = createVis("Vis_Safe", Color3.fromRGB(0, 255, 255), Config.SafeZoneCFrame) end
    if Config.PreSafeCFrame then visPre = createVis("Vis_Pre", Color3.fromRGB(255, 255, 0), Config.PreSafeCFrame) end
    if Config.FarmSpotCFrame then visFarm = createVis("Vis_Farm", Color3.fromRGB(255, 50, 50), Config.FarmSpotCFrame) end
end

-- --- HÀM TỰ ĐỘNG NHẬP XÁC ---
local function checkAndReturnToBody()
    if Config.SpiritMode and Config.SafeZoneCFrame and Config.PreSafeCFrame and Config.FarmSpotCFrame then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root and Config.OriginalBodyCFrame then
            Config.SpiritMode = false 
            root.Anchored = false 
            root.CFrame = Config.OriginalBodyCFrame
            
            if visBodyDummy then visBodyDummy:Destroy() visBodyDummy = nil end
            
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("Decal") then
                    v.Transparency = 0
                    if v:IsA("BasePart") then v.CanCollide = true end
                end
            end
            
            Rayfield:Notify({Title = "Hoàn Tất", Content = "Đã set đủ 3 điểm. Nhập xác!", Duration = 3})
        end
    end
end

-- --- LOGIC AUTO FARM ---
local function executeFarmCycle()
    if Config.IsBusy or not Config.SafeZoneCFrame or not Config.FarmSpotCFrame or not Config.PreSafeCFrame then return end
    if Config.SpiritMode then return end 

    Config.IsBusy = true
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if not root then Config.IsBusy = false return end

    -- 1. Tele ra PreSafe
    if hum then hum.PlatformStand = true end
    root.CanCollide = false
    root.Anchored = false
    root.CFrame = Config.PreSafeCFrame 
    task.wait(0.15) 

    -- 2. Tween về SafeZone
    Rayfield:Notify({Title = "Auto", Content = "Đang về SafeZone...", Duration = 1})
    local dist = (root.Position - Config.SafeZoneCFrame.Position).Magnitude
    local time = dist / Config.TweenSpeed
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tweenGo = TweenService:Create(root, tweenInfo, {CFrame = Config.SafeZoneCFrame})
    
    tweenGo:Play()
    
    tweenGo.Completed:Connect(function()
        -- 3. Chờ
        task.wait(Config.WaitTime)
        
        -- 4. Tele về FarmSpot
        if hum then hum.PlatformStand = false end
        root.CanCollide = true
        root.CFrame = Config.FarmSpotCFrame 
        
        Rayfield:Notify({Title = "Auto", Content = "Đã quay lại!", Duration = 1})
        Config.IsBusy = false
    end)
end

-- --- LOOP TỔNG HỢP (SPIRIT + STATS) ---
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    -- 1. Spirit Mode (Anti-Gravity)
    if Config.SpiritMode and char and root and hum then
        root.Anchored = true 
        root.CanCollide = false
        
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local newPos = root.CFrame + (Camera.CFrame.LookVector * (moveDir.Magnitude * Config.GhostSpeed))
            root.CFrame = newPos
        end
    end

    -- 2. Loop Stats
    if not Config.SpiritMode and Config.LoopStats and hum then
        hum.WalkSpeed = Config.WalkSpeed
        hum.JumpPower = Config.JumpPower
    end
end)

-- --- SỰ KIỆN TƯƠNG TÁC ---
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer and Config.AutoFarm then
        if Config.SpiritMode then return end
        executeFarmCycle()
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.InstantPrompt then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then v.HoldDuration = 0 end
            end
        end
    end
end)

-- --- GIAO DIỆN RAYFIELD ---
local Window = Rayfield:CreateWindow({
   Name = "Hybrid Farm V7 (Anti-Sink)",
   LoadingTitle = "Đang tải...",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local MainTab = Window:CreateTab("Cài Đặt Map", 4483362458)
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)
local ExtraTab = Window:CreateTab("Tiện Ích & Tele", 4483362458)

-- === TAB 1: SETUP MAP ===
MainTab:CreateParagraph({Title = "Lưu ý", Content = "Các điểm sẽ tự động được nâng cao 3 studs để tránh bị lún đất."})

MainTab:CreateButton({
   Name = "👻 Xuất Hồn (Bay đặt điểm)",
   Callback = function()
        if Config.SafeZoneCFrame and Config.PreSafeCFrame and Config.FarmSpotCFrame then
            Rayfield:Notify({Title = "Đủ Điểm Rồi!", Content = "Xóa bớt điểm nếu muốn set lại.", Duration = 2})
            return
        end
        if Config.SpiritMode then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root then
            Config.OriginalBodyCFrame = root.CFrame
            Config.SpiritMode = true
            
            visBodyDummy = Instance.new("Part", workspace)
            visBodyDummy.Name = "Dummy_Body"
            visBodyDummy.Anchored = true; visBodyDummy.CanCollide = false
            visBodyDummy.Size = Vector3.new(4, 5, 4); visBodyDummy.Transparency = 0.4
            visBodyDummy.Material = Enum.Material.ForceField
            visBodyDummy.Color = Color3.fromRGB(150, 150, 150)
            visBodyDummy.CFrame = root.CFrame
            
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 0.8 end
            end
            Rayfield:Notify({Title = "Đã Xuất Hồn", Content = "Dùng Joystick để bay!", Duration = 2})
        end
   end,
})

MainTab:CreateSlider({
   Name = "💨 Tốc độ Hồn",
   Range = {0.5, 10},
   Increment = 0.5,
   CurrentValue = 2,
   Callback = function(v) Config.GhostSpeed = v end,
})

MainTab:CreateSection("Set Điểm (Sẽ +3 Cao Độ)")

-- NÚT SET (CÓ OFFSET CAO ĐỘ)
MainTab:CreateButton({
   Name = "🔵 1. Set SafeZone (Trả đồ)",
   Callback = function()
        if Config.SpiritMode or LocalPlayer.Character then
            -- Lấy vị trí hiện tại + 3 Studs chiều cao (Vector3.new(0, 3, 0))
            Config.SafeZoneCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            updateVisuals()
            Rayfield:Notify({Title = "1/3", Content = "SafeZone (Đã nâng cao)", Duration = 1})
            checkAndReturnToBody()
        end
   end,
})
MainTab:CreateButton({
   Name = "🟡 2. Set Pre-Safe (Mid)",
   Callback = function()
        if Config.SpiritMode or LocalPlayer.Character then
            Config.PreSafeCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            updateVisuals()
            Rayfield:Notify({Title = "2/3", Content = "Pre-Safe (Đã nâng cao)", Duration = 1})
            checkAndReturnToBody()
        end
   end,
})
MainTab:CreateButton({
   Name = "🔴 3. Set FarmSpot (Nhặt)",
   Callback = function()
        if Config.SpiritMode or LocalPlayer.Character then
            Config.FarmSpotCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            updateVisuals()
            Rayfield:Notify({Title = "3/3", Content = "FarmSpot (Đã nâng cao)", Duration = 1})
            checkAndReturnToBody()
        end
   end,
})

MainTab:CreateSection("Xóa Từng Điểm")

-- NÚT XÓA RIÊNG BIỆT
MainTab:CreateButton({
   Name = "❌ Xóa SafeZone",
   Callback = function()
       Config.SafeZoneCFrame = nil
       updateVisuals()
       Rayfield:Notify({Title = "Đã Xóa", Content = "Xóa SafeZone", Duration = 1})
   end,
})
MainTab:CreateButton({
   Name = "❌ Xóa Pre-Safe (Mid)",
   Callback = function()
       Config.PreSafeCFrame = nil
       updateVisuals()
       Rayfield:Notify({Title = "Đã Xóa", Content = "Xóa Pre-Safe", Duration = 1})
   end,
})
MainTab:CreateButton({
   Name = "❌ Xóa FarmSpot",
   Callback = function()
       Config.FarmSpotCFrame = nil
       updateVisuals()
       Rayfield:Notify({Title = "Đã Xóa", Content = "Xóa FarmSpot", Duration = 1})
   end,
})

-- === TAB 2: FARM ===
FarmTab:CreateToggle({
   Name = "🤖 Bật Auto Farm",
   CurrentValue = false,
   Callback = function(v) Config.AutoFarm = v end,
})
FarmTab:CreateToggle({
   Name = "⚡ Nhặt Nhanh",
   CurrentValue = true,
   Callback = function(v) Config.InstantPrompt = v end,
})
FarmTab:CreateSlider({
   Name = "🚀 Tốc độ Tween",
   Range = {500, 2500},
   Increment = 100,
   Suffix = "Studs/s",
   CurrentValue = 1200,
   Callback = function(v) Config.TweenSpeed = v end,
})

-- === TAB 3: TIỆN ÍCH ===
ExtraTab:CreateButton({
    Name = "✈️ Teleport SafeZone",
    Callback = function()
        if Config.SafeZoneCFrame and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = Config.SafeZoneCFrame
            Rayfield:Notify({Title = "Teleport", Content = "Về SafeZone", Duration = 1})
        else
            Rayfield:Notify({Title = "Lỗi", Content = "Chưa set SafeZone!", Duration = 1})
        end
    end,
})

ExtraTab:CreateButton({
    Name = "✈️ Teleport FarmSpot",
    Callback = function()
        if Config.FarmSpotCFrame and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = Config.FarmSpotCFrame
            Rayfield:Notify({Title = "Teleport", Content = "Đến FarmSpot", Duration = 1})
        else
            Rayfield:Notify({Title = "Lỗi", Content = "Chưa set FarmSpot!", Duration = 1})
        end
    end,
})

ExtraTab:CreateSection("Stats")
ExtraTab:CreateToggle({
    Name = "🔥 Loop Stats",
    CurrentValue = false,
    Callback = function(v) Config.LoopStats = v end,
})
ExtraTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v) Config.WalkSpeed = v end,
})
ExtraTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 500},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v) Config.JumpPower = v end,
})
