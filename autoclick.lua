local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local guiName = "VIP_MultiClicker_Mobile"

-- Dọn dẹp UI cũ
if PlayerGui:FindFirstChild(guiName) then
    PlayerGui[guiName]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 1000000
ScreenGui.IgnoreGuiInset = true -- SỬA LỖI LỆCH TÂM TRÊN MOBILE (RẤT QUAN TRỌNG)
ScreenGui.Parent = PlayerGui

-- ==========================================
-- MENU ĐIỀU KHIỂN CHÍNH
-- ==========================================
local MenuFrame = Instance.new("Frame")
MenuFrame.Size = UDim2.new(0, 190, 0, 180)
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
Title.Text = "MULTI CLICK"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.Parent = TopBar

-- Khu vực Thêm/Xóa Mục Tiêu
local TargetControlFrame = Instance.new("Frame")
TargetControlFrame.Size = UDim2.new(0.9, 0, 0, 40)
TargetControlFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
TargetControlFrame.BackgroundTransparency = 1
TargetControlFrame.Parent = MenuFrame

local AddBtn = Instance.new("TextButton")
AddBtn.Size = UDim2.new(0.45, 0, 1, 0)
AddBtn.Position = UDim2.new(0, 0, 0, 0)
AddBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
AddBtn.Text = "+ THÊM ĐIỂM"
AddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddBtn.Font = Enum.Font.GothamBold
AddBtn.TextSize = 11
AddBtn.Parent = TargetControlFrame

local AddCorner = Instance.new("UICorner")
AddCorner.CornerRadius = UDim.new(0, 5)
AddCorner.Parent = AddBtn

local RemoveBtn = Instance.new("TextButton")
RemoveBtn.Size = UDim2.new(0.45, 0, 1, 0)
RemoveBtn.Position = UDim2.new(0.55, 0, 0, 0)
RemoveBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
RemoveBtn.Text = "- XÓA ĐIỂM"
RemoveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RemoveBtn.Font = Enum.Font.GothamBold
RemoveBtn.TextSize = 11
RemoveBtn.Parent = TargetControlFrame

local RemoveCorner = Instance.new("UICorner")
RemoveCorner.CornerRadius = UDim.new(0, 5)
RemoveCorner.Parent = RemoveBtn

-- Cài đặt Tốc độ
local CpsLabel = Instance.new("TextLabel")
CpsLabel.Size = UDim2.new(0.6, 0, 0, 25)
CpsLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
CpsLabel.BackgroundTransparency = 1
CpsLabel.Text = "Tốc độ (Click/s):"
CpsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CpsLabel.Font = Enum.Font.GothamSemibold
CpsLabel.TextSize = 12
CpsLabel.TextXAlignment = Enum.TextXAlignment.Left
CpsLabel.Parent = MenuFrame

local CpsInput = Instance.new("TextBox")
CpsInput.Size = UDim2.new(0.3, 0, 0, 25)
CpsInput.Position = UDim2.new(0.65, 0, 0.55, 0)
CpsInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CpsInput.Text = "10"
CpsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CpsInput.Font = Enum.Font.GothamBold
CpsInput.TextSize = 14
CpsInput.Parent = MenuFrame

local CpsCorner = Instance.new("UICorner")
CpsCorner.CornerRadius = UDim.new(0, 4)
CpsCorner.Parent = CpsInput

-- Nút Start/Stop
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.9, 0, 0, 35)
StartBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
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
-- HỆ THỐNG QUẢN LÝ ĐIỂM CLICK
-- ==========================================
local targetPoints = {}
local isClicking = false
local isMinimized = false

-- Hàm tạo điểm click mới
local function CreateNewTarget()
    local index = #targetPoints + 1
    
    local TargetCircle = Instance.new("Frame")
    TargetCircle.Size = UDim2.new(0, 46, 0, 46)
    TargetCircle.Position = UDim2.new(0.5, -23 + (index * 10), 0.5, -23 + (index * 10)) -- Lệch ra một chút để không đè lên nhau
    TargetCircle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    TargetCircle.BackgroundTransparency = 0.7
    TargetCircle.Active = true
    TargetCircle.Draggable = true
    TargetCircle.Parent = ScreenGui

    local TargetCorner = Instance.new("UICorner")
    TargetCorner.CornerRadius = UDim.new(1, 0)
    TargetCorner.Parent = TargetCircle

    local TargetStroke = Instance.new("UIStroke")
    TargetStroke.Color = Color3.fromRGB(255, 255, 255)
    TargetStroke.Thickness = 2
    TargetStroke.Parent = TargetCircle

    local Crosshair = Instance.new("TextLabel")
    Crosshair.Size = UDim2.new(1, 0, 1, 0)
    Crosshair.BackgroundTransparency = 1
    Crosshair.Text = "+"
    Crosshair.TextColor3 = Color3.fromRGB(255, 255, 255)
    Crosshair.Font = Enum.Font.GothamBold
    Crosshair.TextSize = 24
    Crosshair.Parent = TargetCircle
    
    local NumberLabel = Instance.new("TextLabel")
    NumberLabel.Size = UDim2.new(0, 20, 0, 20)
    NumberLabel.Position = UDim2.new(1, -10, 0, -10)
    NumberLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    NumberLabel.Text = tostring(index)
    NumberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NumberLabel.Font = Enum.Font.GothamBold
    NumberLabel.TextSize = 12
    NumberLabel.Parent = TargetCircle
    
    local NumCorner = Instance.new("UICorner")
    NumCorner.CornerRadius = UDim.new(1, 0)
    NumCorner.Parent = NumberLabel

    table.insert(targetPoints, {
        Circle = TargetCircle,
        Stroke = TargetStroke,
        Cross = Crosshair,
        Num = NumberLabel
    })
end

-- Hàm xóa điểm click gần nhất
local function RemoveLastTarget()
    if #targetPoints > 0 then
        local lastTarget = targetPoints[#targetPoints]
        lastTarget.Circle:Destroy()
        table.remove(targetPoints, #targetPoints)
    end
end

-- ==========================================
-- KẾT NỐI NÚT BẤM
-- ==========================================
AddBtn.MouseButton1Click:Connect(function()
    if not isClicking then CreateNewTarget() end
end)

RemoveBtn.MouseButton1Click:Connect(function()
    if not isClicking then RemoveLastTarget() end
end)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MenuFrame:TweenSize(UDim2.new(0, 190, 0, 30), "Out", "Quad", 0.2, true)
        MinBtn.Text = "+"
    else
        MenuFrame:TweenSize(UDim2.new(0, 190, 0, 180), "Out", "Quad", 0.2, true)
        MinBtn.Text = "-"
    end
end)

StartBtn.MouseButton1Click:Connect(function()
    if #targetPoints == 0 then return end -- Không có điểm nào thì không chạy
    
    isClicking = not isClicking
    
    if isClicking then
        StartBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StartBtn.Text = "DỪNG LẠI (STOP)"
        
        -- Khóa tất cả các điểm lại để click xuyên qua game
        for _, target in pairs(targetPoints) do
            target.Circle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            target.Stroke.Color = Color3.fromRGB(0, 255, 0)
            target.Circle.Active = false
            target.Cross.Visible = false
            target.Num.Visible = false
        end
    else
        StartBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        StartBtn.Text = "BẮT ĐẦU (START)"
        
        -- Mở khóa lại để kéo thả
        for _, target in pairs(targetPoints) do
            target.Circle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            target.Stroke.Color = Color3.fromRGB(255, 255, 255)
            target.Circle.Active = true
            target.Cross.Visible = true
            target.Num.Visible = true
        end
    end
end)

-- ==========================================
-- VÒNG LẶP AUTO CLICK CHÍNH XÁC
-- ==========================================
task.spawn(function()
    while true do
        if isClicking and #targetPoints > 0 then
            local cps = tonumber(CpsInput.Text)
            if not cps or cps <= 0 then cps = 10 end
            if cps > 100 then cps = 100 end
            
            pcall(function()
                -- Quét qua toàn bộ các điểm để click
                for i, target in ipairs(targetPoints) do
                    -- Công thức tính toán chuẩn tâm điểm, không bị lệch
                    local targetX = target.Circle.AbsolutePosition.X + (target.Circle.AbsoluteSize.X / 2)
                    local targetY = target.Circle.AbsolutePosition.Y + (target.Circle.AbsoluteSize.Y / 2)
                    
                    local touchID = 1000 + i -- Mỗi điểm một ID để game nhận là vuốt nhiều ngón (multi-touch)
                    
                    -- Chạm xuống
                    VirtualInputManager:SendTouchEvent(touchID, 0, targetX, targetY)
                    VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, true, game, 1)
                    
                    task.wait(0.002)
                    
                    -- Thả tay ra
                    VirtualInputManager:SendTouchEvent(touchID, 2, targetX, targetY)
                    VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, false, game, 1)
                end
            end)
            
            task.wait(1 / cps)
        else
            task.wait(0.1)
        end
    end
end)

-- Tự động tạo sẵn 1 điểm khi vừa load script
CreateNewTarget()
