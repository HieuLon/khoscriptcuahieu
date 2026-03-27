local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- DỌN DẸP UI CŨ
-- ==========================================
local guiName = "AssassinLoopTele_UI"
if CoreGui:FindFirstChild(guiName) then
    CoreGui[guiName]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui

-- ==========================================
-- 1. MENU ĐIỀU KHIỂN (BẬT / TẮT)
-- ==========================================
local MenuFrame = Instance.new("Frame")
MenuFrame.Size = UDim2.new(0, 160, 0, 80)
MenuFrame.Position = UDim2.new(0.5, -80, 0.1, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 8)
MenuCorner.Parent = MenuFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Chế Độ Sát Thủ"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MenuFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
ToggleBtn.Text = "ĐANG TẮT (OFF)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MenuFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 5)
ToggleCorner.Parent = ToggleBtn

-- ==========================================
-- 2. NÚT TRÒN ATTACK (GÓC DƯỚI PHẢI)
-- ==========================================
local ActionBtn = Instance.new("TextButton")
ActionBtn.Size = UDim2.new(0, 70, 0, 70)
ActionBtn.Position = UDim2.new(1, -90, 1, -160)
ActionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ActionBtn.Text = "ATTACK\n(Khóa)"
ActionBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 12
ActionBtn.Active = true
ActionBtn.Draggable = true -- Có thể kéo thả tự do
ActionBtn.Parent = ScreenGui

local ActionCorner = Instance.new("UICorner")
ActionCorner.CornerRadius = UDim.new(1, 0)
ActionCorner.Parent = ActionBtn

local ActionStroke = Instance.new("UIStroke")
ActionStroke.Color = Color3.fromRGB(100, 100, 100)
ActionStroke.Thickness = 3
ActionStroke.Parent = ActionBtn

-- ==========================================
-- LOGIC CHIẾN ĐẤU (LOOP TELEPORT)
-- ==========================================
local isSystemOn = false
local isAttacking = false
local originalPos = nil
local currentTarget = nil
local maxScanRadius = 200 -- Khoảng cách quét tìm mục tiêu
local distanceBehind = 3.5 -- Đứng cách lưng địch 3.5 studs

-- Hàm lấy người chơi gần nhất
local function getNearestPlayer()
    local nearest = nil
    local minDist = maxScanRadius
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local enemyChar = player.Character
            if enemyChar and enemyChar:FindFirstChild("HumanoidRootPart") and enemyChar:FindFirstChild("Humanoid") then
                if enemyChar.Humanoid.Health > 0 then
                    local dist = (enemyChar.HumanoidRootPart.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = player
                    end
                end
            end
        end
    end
    return nearest
end

-- Bật / Tắt Hệ Thống (Menu)
ToggleBtn.MouseButton1Click:Connect(function()
    isSystemOn = not isSystemOn
    if isSystemOn then
        ToggleBtn.Text = "ĐANG BẬT (ON)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        ActionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActionBtn.Text = "ATTACK\n(Sẵn Sàng)"
        ActionStroke.Color = Color3.fromRGB(255, 100, 100)
    else
        ToggleBtn.Text = "ĐANG TẮT (OFF)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        ActionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        ActionBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        ActionBtn.Text = "ATTACK\n(Khóa)"
        ActionStroke.Color = Color3.fromRGB(100, 100, 100)
        isAttacking = false -- Tắt luôn đòn tấn công nếu đang chém
    end
end)

-- Bấm Nút Tròn Để Ám Sát
ActionBtn.MouseButton1Click:Connect(function()
    if not isSystemOn then return end -- Nếu hệ thống tắt, nút này vô tác dụng

    if isAttacking then
        -- Bấm lần nữa để chủ động Hủy ám sát bay về (nếu muốn)
        isAttacking = false
        return
    end

    -- Tìm mục tiêu
    currentTarget = getNearestPlayer()
    if not currentTarget then return end -- Không có ai xung quanh

    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = myChar.HumanoidRootPart

    -- Lưu lại vị trí an toàn trước khi bay đi
    originalPos = myRoot.CFrame
    isAttacking = true
    ActionBtn.Text = "ĐANG\nCHÉM..."
    ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)

    -- Bắt đầu vòng lặp dính sau lưng
    task.spawn(function()
        local touchID = math.random(1000, 9999)
        local cam = Workspace.CurrentCamera
        
        -- Chạy liên tục cho đến khi địch chết HOẶC bạn chết HOẶC bạn tắt
        while isAttacking do
            local enemyChar = currentTarget.Character
            
            -- Kiểm tra xem địch còn sống và tồn tại không
            if enemyChar and enemyChar:FindFirstChild("HumanoidRootPart") and enemyChar:FindFirstChild("Humanoid") then
                if enemyChar.Humanoid.Health <= 0 then
                    break -- Địch đã chết, thoát vòng lặp
                end
                
                -- Kiểm tra xem bản thân có đang sống không
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.Humanoid.Health <= 0 then
                    break
                end

                local targetRoot = enemyChar.HumanoidRootPart
                
                -- LOOP TELEPORT: Dịch chuyển lập tức ra sau lưng địch (CFrame.new(0, 0, 3.5) là lùi về sau)
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, distanceBehind)
                
                -- Giữ vận tốc bằng 0 để không bị văng đi lung tung
                LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)

                -- Tự động Click giữa màn hình để chém
                if cam then
                    local cx = cam.ViewportSize.X / 2
                    local cy = cam.ViewportSize.Y / 2
                    VirtualInputManager:SendTouchEvent(touchID, 0, cx, cy)
                    task.wait(0.01)
                    VirtualInputManager:SendTouchEvent(touchID, 2, cx, cy)
                end
            else
                break -- Mất tín hiệu mục tiêu (thoát game hoặc chết)
            end
            
            task.wait() -- Vòng lặp siêu nhanh để bám chặt lưng không bị rớt nhịp
        end

        -- KẾT THÚC ÁM SÁT (Địch chết hoặc tự hủy)
        isAttacking = false
        if isSystemOn then
            ActionBtn.Text = "ATTACK\n(Sẵn Sàng)"
            ActionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end

        -- DỊCH CHUYỂN VỀ VỊ TRÍ CŨ
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and originalPos then
            LocalPlayer.Character.HumanoidRootPart.CFrame = originalPos
        end
    end)
end)
