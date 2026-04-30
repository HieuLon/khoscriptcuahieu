local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Ép UI hiển thị an toàn trên Mobile
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local guiName = "VIP_AutoClicker_Mobile"

-- Xóa UI cũ nếu có
if PlayerGui:FindFirstChild(guiName) then
    PlayerGui[guiName]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 1000000 -- Đè lên mọi thứ
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- ==========================================
-- 1. HÌNH TRÒN CHỈ ĐỊNH VỊ TRÍ CLICK (HỒNG TÂM)
-- ==========================================
local TargetCircle = Instance.new("Frame")
TargetCircle.Size = UDim2.new(0, 50, 0, 50)
TargetCircle.Position = UDim2.new(0.5, -25, 0.5, -25)
TargetCircle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
TargetCircle.BackgroundTransparency = 0.7
TargetCircle.Active = true
TargetCircle.Draggable = true -- Cho phép kéo thả
TargetCircle.Parent = ScreenGui

local TargetCorner = Instance.new("UICorner")
TargetCorner.CornerRadius = UDim.new(1, 0)
TargetCorner.Parent = TargetCircle

local TargetStroke = Instance.new("UIStroke")
TargetStroke.Color = Color3.fromRGB(255, 255, 255)
TargetStroke.Thickness = 2
TargetStroke.Parent = TargetCircle

-- Dấu cộng ở giữa hồng tâm
local Crosshair = Instance.new("TextLabel")
Crosshair.Size = UDim2.new(1, 0, 1, 0)
Crosshair.BackgroundTransparency = 1
Crosshair.Text = "+"
Crosshair.TextColor3 = Color3.fromRGB(255, 255, 255)
Crosshair.Font = Enum.Font.GothamBold
Crosshair.TextSize = 24
Crosshair.Parent = TargetCircle

-- ==========================================
-- 2. MENU ĐIỀU KHIỂN CHÍNH
-- ==========================================
local MenuFrame = Instance.new("Frame")
MenuFrame.Size = UDim2.new(0, 180, 0, 140)
MenuFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.ClipsDescendants = true
MenuFrame.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 8)
MenuCorner.Parent = MenuFrame

-- Thanh tiêu đề
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.Parent = MenuFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AUTO CLICK"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Nút Thu Nhỏ (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.Parent = TopBar

-- Ô nhập Số Lần Click / Giây (CPS)
local CpsLabel = Instance.new("TextLabel")
CpsLabel.Size = UDim2.new(0.6, 0, 0, 25)
CpsLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
CpsLabel.BackgroundTransparency = 1
CpsLabel.Text = "Tốc độ (Click/s):"
CpsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CpsLabel.Font = Enum.Font.GothamSemibold
CpsLabel.TextSize = 12
CpsLabel.TextXAlignment = Enum.TextXAlignment.Left
CpsLabel.Parent = MenuFrame

local CpsInput = Instance.new("TextBox")
CpsInput.Size = UDim2.new(0.3, 0, 0, 25)
CpsInput.Position = UDim2.new(0.65, 0, 0.35, 0)
CpsInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CpsInput.Text = "10" -- Mặc định 10 click/giây
CpsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CpsInput.Font = Enum.Font.GothamBold
CpsInput.TextSize = 14
CpsInput.Parent = MenuFrame

local CpsCorner = Instance.new("UICorner")
CpsCorner.CornerRadius = UDim.new(0, 4)
CpsCorner.Parent = CpsInput

-- Nút Bắt Đầu / Dừng
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.9, 0, 0, 35)
StartBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
StartBtn.Text = "BẮT ĐẦU (START)"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 14
StartBtn.Parent = MenuFrame

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 6)
StartCorner.Parent = StartBtn

-- ==========================================
-- 3. LOGIC HOẠT ĐỘNG
-- ==========================================
local isClicking = false
local isMinimized = false

-- Nút Thu Nhỏ Menu
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MenuFrame:TweenSize(UDim2.new(0, 180, 0, 30), "Out", "Quad", 0.2, true)
        MinBtn.Text = "+"
    else
        MenuFrame:TweenSize(UDim2.new(0, 180, 0, 140), "Out", "Quad", 0.2, true)
        MinBtn.Text = "-"
    end
end)

-- Nút Bật/Tắt Auto Click
StartBtn.MouseButton1Click:Connect(function()
    isClicking = not isClicking
    
    if isClicking then
        StartBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StartBtn.Text = "DỪNG LẠI (STOP)"
        TargetCircle.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Chuyển xanh lá khi đang chạy
        TargetStroke.Color = Color3.fromRGB(0, 255, 0)
    else
        StartBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        StartBtn.Text = "BẮT ĐẦU (START)"
        TargetCircle.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ khi dừng
        TargetStroke.Color = Color3.fromRGB(255, 255, 255)
    end
end)

-- Vòng Lặp Auto Click (Hoạt động độc lập không giật lag)
local touchID = math.random(1000, 9999)

task.spawn(function()
    while true do
        if isClicking then
            -- Lấy số lượt click mỗi giây
            local cps = tonumber(CpsInput.Text)
            if not cps or cps <= 0 then cps = 10 end -- Chống lỗi nhập chữ
            if cps > 100 then cps = 100 end -- Giới hạn tối đa 100 click/s tránh crash máy
            
            -- Lấy vị trí tâm của hình tròn hiện tại
            local targetX = TargetCircle.AbsolutePosition.X + (TargetCircle.AbsoluteSize.X / 2)
            local targetY = TargetCircle.AbsolutePosition.Y + (TargetCircle.AbsoluteSize.Y / 2)
            
            -- Thực hiện Touch Ảo (Mượt nhất cho Mobile)
            pcall(function()
                VirtualInputManager:SendTouchEvent(touchID, 0, targetX, targetY)
                task.wait(0.005)
                VirtualInputManager:SendTouchEvent(touchID, 2, targetX, targetY)
            end)
            
            -- Chờ nhịp tiếp theo dựa trên CPS
            task.wait(1 / cps)
        else
            -- Đang dừng thì nghỉ để tiết kiệm CPU
            task.wait(0.1)
        end
    end
end)
