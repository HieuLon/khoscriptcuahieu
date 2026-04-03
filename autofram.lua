-- =========================================================================
-- 🚀 TỐI THƯỢNG AUTO HUB - V5 (GIẢM LAG QUÁI ĐÔNG, ANTI-FALL, PAD KHỔNG LỒ)
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- BẢNG TRẠNG THÁI
local Config = {
    AutoFarm = false,
    AutoChest = false,
    AutoClick = false,
    AntiLag = false,
    Radius = 6,
    OrbitSpeed = 2,
    SafePadHeight = 50000,
    FarmPoint = nil -- Lưu vị trí đứng farm ban đầu
}

-- ==========================================
-- HỆ THỐNG ANTI-AFK
-- ==========================================
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
end)

-- ==========================================
-- HỆ THỐNG GIAO DIỆN (UI DI CHUYỂN & THU NHỎ)
-- ==========================================
local function CreateButton(parent, text, pos)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local ScreenGui = Instance.new("ScreenGui")
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 280)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.Draggable = true 
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 😎
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(100, 100, 255)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "⚡ SUPREME HUB V5"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundTransparency = 1

local btnMinimize = Instance.new("TextButton", MainFrame)
btnMinimize.Size = UDim2.new(0, 30, 0, 30)
btnMinimize.Position = UDim2.new(1, -35, 0, 2)
btnMinimize.Text = "-"
btnMinimize.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
btnMinimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", btnMinimize).CornerRadius = UDim.new(0, 6)

local btnFarm = CreateButton(MainFrame, "Farm & Return: Tắt", UDim2.new(0.05, 0, 0.15, 0))
local btnChest = CreateButton(MainFrame, "Chest & Return: Tắt", UDim2.new(0.05, 0, 0.30, 0))
local btnClick = CreateButton(MainFrame, "Giả Lập Click: Tắt", UDim2.new(0.05, 0, 0.45, 0))
local btnAntiLag = CreateButton(MainFrame, "Bật Anti-Lag Max", UDim2.new(0.05, 0, 0.60, 0))

local isMinimized = false
btnMinimize.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 250, 0, 35) or UDim2.new(0, 250, 0, 280)
    btnFarm.Visible = not isMinimized
    btnChest.Visible = not isMinimized
    btnClick.Visible = not isMinimized
    btnAntiLag.Visible = not isMinimized
    btnMinimize.Text = isMinimized and "+" or "-"
end)

-- ==========================================
-- SAFE PAD KHỔNG LỒ
-- ==========================================
local SafePad = nil
local function SetupSafePad()
    if not SafePad then
        SafePad = Instance.new("Part")
        SafePad.Size = Vector3.new(2000, 5, 2000) -- Rất to để tránh rớt quái
        SafePad.Position = Vector3.new(0, Config.SafePadHeight, 0)
        SafePad.Anchored = true
        SafePad.Transparency = 0.5
        SafePad.Material = Enum.Material.ForceField
        SafePad.Color = Color3.fromRGB(0, 255, 255)
        SafePad.Parent = Workspace
    end
end

-- ==========================================
-- HÀM KIỂM TRA CHỐNG LỆCH & ANTI-FALL
-- ==========================================
local function CheckAndReturnHome()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and Config.FarmPoint then
        -- 1. Anti-Fall: Nếu rơi rớt dưới FarmPoint 50 studs, kéo về lập tức
        if hrp.Position.Y < (Config.FarmPoint.Y - 50) then
            hrp.CFrame = Config.FarmPoint
            return
        end
        
        -- 2. Chống lệch X, Z quá 30 studs
        local distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(Config.FarmPoint.X, 0, Config.FarmPoint.Z)).Magnitude
        if distance > 30 then
            hrp.CFrame = Config.FarmPoint
        end
    end
end

-- ==========================================
-- CHỨC NĂNG 1: AUTO FARM & GOM QUÁI (TỐI ƯU CỰC ĐẠI)
-- ==========================================
btnFarm.MouseButton1Click:Connect(function()
    Config.AutoFarm = not Config.AutoFarm
    btnFarm.Text = Config.AutoFarm and "Farm & Return: BẬT" or "Farm & Return: Tắt"
    btnFarm.BackgroundColor3 = Config.AutoFarm and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 60)
    
    if Config.AutoFarm then
        SetupSafePad()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Set Farm Point tại tâm Pad luôn để chắc chắn an toàn
            hrp.CFrame = SafePad.CFrame * CFrame.new(0, 5, 0)
            task.wait(0.1)
            Config.FarmPoint = hrp.CFrame
        end
    else
        Config.FarmPoint = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.AutoFarm then
        pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local monstersFolder = Workspace:FindFirstChild("Monsters") or Workspace:FindFirstChild("Enemies") 
            local hasTarget = false
            local MainBossHrp = nil -- Biến lưu trữ Boss chính để xoay quanh
            
            if monstersFolder then
                for _, mob in ipairs(monstersFolder:GetChildren()) do
                    local mobHrp = mob:FindFirstChild("HumanoidRootPart")
                    local humanoid = mob:FindFirstChildOfClass("Humanoid")
                    
                    if mobHrp and humanoid and humanoid.Health > 0 then
                        hasTarget = true
                        
                        -- CHỐNG LAG: Tự động xóa hiệu ứng hạt, sáng trên quái nếu AntiLag đang bật
                        if Config.AntiLag then
                            for _, v in ipairs(mob:GetDescendants()) do
                                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("PointLight") then
                                    v:Destroy()
                                end
                            end
                        end
                        
                        local isBoss = humanoid.MaxHealth > 1000 
                        
                        if isBoss then
                            -- Gán con Boss đầu tiên tìm thấy làm Boss chính
                            if not MainBossHrp then MainBossHrp = mobHrp end
                            
                            if mobHrp == MainBossHrp then
                                -- Chế độ Orbit: Chỉ xoay quanh Boss chính
                                local timeTick = tick() * Config.OrbitSpeed
                                local offsetX = math.sin(timeTick) * Config.Radius
                                local offsetZ = math.cos(timeTick) * Config.Radius
                                hrp.CFrame = mobHrp.CFrame * CFrame.new(offsetX, 0, offsetZ)
                                hrp.CFrame = CFrame.lookAt(hrp.Position, mobHrp.Position)
                            else
                                -- Đám Boss phụ sẽ bị hút vào Boss chính, không bắt nhân vật xoay theo
                                mobHrp.CanCollide = false
                                mobHrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                mobHrp.CFrame = MainBossHrp.CFrame
                            end
                        else
                            -- Chế độ gom quái thường: Ép tọa độ Y ngang nhân vật để KHÔNG BỊ RƠI
                            mobHrp.CanCollide = false
                            mobHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            
                            -- Tính tọa độ phía trước mặt
                            local targetCFrame = hrp.CFrame * CFrame.new(0, 0, -Config.Radius)
                            -- Gắn chặt Y của quái với Y của người chơi
                            mobHrp.CFrame = CFrame.new(targetCFrame.X, hrp.Position.Y, targetCFrame.Z)
                        end
                    end
                end
            end
            
            -- Nếu không còn quái (đã đánh xong), tự quay về điểm Farm ban đầu
            if not hasTarget and Config.FarmPoint then
                hrp.CFrame = Config.FarmPoint
            end
        end)
    end
end)

-- Vòng lặp kiểm tra rơi và lệch mỗi 2 giây
task.spawn(function()
    while task.wait(2) do
        if Config.AutoFarm and not Config.AutoChest then
            pcall(CheckAndReturnHome)
        end
    end
end)

-- ==========================================
-- CHỨC NĂNG 2: GIẢ LẬP CLICK
-- ==========================================
btnClick.MouseButton1Click:Connect(function()
    Config.AutoClick = not Config.AutoClick
    btnClick.Text = Config.AutoClick and "Giả Lập Click: BẬT" or "Giả Lập Click: Tắt"
    btnClick.BackgroundColor3 = Config.AutoClick and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 60)
end)

task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoClick then
            pcall(function()
                local screenSize = camera.ViewportSize
                VirtualInputManager:SendMouseButtonEvent(screenSize.X/2, screenSize.Y/2, 0, true, game, 1)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(screenSize.X/2, screenSize.Y/2, 0, false, game, 1)
            end)
        end
    end
end)

-- ==========================================
-- CHỨC NĂNG 3: AUTO CHEST (NHẶT XONG TỰ VỀ CHỖ CŨ)
-- ==========================================
btnChest.MouseButton1Click:Connect(function()
    Config.AutoChest = not Config.AutoChest
    btnChest.Text = Config.AutoChest and "Chest & Return: BẬT" or "Chest & Return: Tắt"
    btnChest.BackgroundColor3 = Config.AutoChest and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 60)
end)

task.spawn(function()
    while task.wait(1) do
        if Config.AutoChest then
            pcall(function()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if string.find(string.lower(obj.Name), "chest") then
                        local chestPart = (obj:IsA("Model") and obj.PrimaryPart) or (obj:IsA("BasePart") and obj)
                        if chestPart then
                            hrp.CFrame = chestPart.CFrame
                            task.wait(0.6)
                        end
                    end
                    if not Config.AutoChest then break end
                end
                
                if Config.FarmPoint then
                    hrp.CFrame = Config.FarmPoint
                end
            end)
        end
    end
end)

-- ==========================================
-- CHỨC NĂNG 4: ANTI-LAG XỊN XÒ (NÂNG CẤP)
-- ==========================================
btnAntiLag.MouseButton1Click:Connect(function()
    Config.AntiLag = true
    btnAntiLag.Text = "Đã Giảm Lag Max!"
    btnAntiLag.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
    
    pcall(function()
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        
        -- Dọn dẹp Workspace
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") then
                obj.Material = Enum.Material.SmoothPlastic
                if obj:IsA("Texture") or obj:IsA("Decal") then obj:Destroy() end
            end
        end
        
        -- Chặn việc tạo thêm hiệu ứng máu/sáng từ game
        Workspace.DescendantAdded:Connect(function(child)
            if Config.AntiLag then
                if child:IsA("ParticleEmitter") or child:IsA("PointLight") or child:IsA("Trail") then
                    task.wait()
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end)
end)

print("Supreme Hub V5 Initialized - Boss Optimization & Anti-Fall Active!")
