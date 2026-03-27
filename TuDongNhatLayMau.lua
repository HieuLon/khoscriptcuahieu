local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- DỌN DẸP UI CŨ
-- ==========================================
local guiName = "SmartLearnerAutoCollect"
if CoreGui:FindFirstChild(guiName) then
    CoreGui[guiName]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui

-- ==========================================
-- GIAO DIỆN CHÍNH
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Position = UDim2.new(0.5, -110, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "AUTO NHẶT THÔNG MINH"
Title.TextColor3 = Color3.fromRGB(255, 200, 50)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 35)
StatusLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Trạng thái: Đang chờ..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ToggleBtn.Text = "▶ BẬT CHẾ ĐỘ HỌC"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 5)
BtnCorner.Parent = ToggleBtn

local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(0.9, 0, 0, 30)
ResetBtn.Position = UDim2.new(0.05, 0, 0.72, 0)
ResetBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
ResetBtn.Text = "🔄 RESET MẪU VẬT"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.Font = Enum.Font.GothamBold
ResetBtn.TextSize = 12
ResetBtn.Parent = MainFrame

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 5)
ResetCorner.Parent = ResetBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = MainFrame

-- ==========================================
-- LOGIC HỌC VÀ NHẶT ĐỒ
-- ==========================================
local isSystemOn = false
local learnedItemName = nil
local previousNearbyObjects = {}

-- Hàm quét các vật phẩm trong bán kính 10 mét
local function getNearbyObjects(radius)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local pos = root.Position
    local list = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) then
            -- Bỏ qua địa hình khổng lồ (Baseplate)
            if obj.Size.Magnitude < 100 then
                if (obj.Position - pos).Magnitude <= radius then
                    list[obj] = obj.Name
                end
            end
        elseif obj:IsA("Model") and obj.PrimaryPart and not obj:IsDescendantOf(LocalPlayer.Character) then
            if (obj.PrimaryPart.Position - pos).Magnitude <= radius then
                list[obj] = obj.Name
            end
        end
    end
    return list
end

-- Hàm tìm vật phẩm gần nhất trên TOÀN BẢN ĐỒ theo tên đã học
local function getNearestItem(itemName)
    local nearest = nil
    local minDist = math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local myPos = root.Position

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == itemName and not obj:IsDescendantOf(LocalPlayer.Character) then
            local pos = nil
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") and obj.PrimaryPart then
                pos = obj.PrimaryPart.Position
            end

            if pos then
                local dist = (pos - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

-- Vòng lặp chính
ToggleBtn.MouseButton1Click:Connect(function()
    isSystemOn = not isSystemOn

    if isSystemOn then
        ToggleBtn.Text = "⏸ DỪNG AUTO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        task.spawn(function()
            while isSystemOn do
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if not root then task.wait(1) continue end

                -- 1. CHẾ ĐỘ HỌC: Đợi bạn nhặt 1 cái
                if learnedItemName == nil then
                    StatusLabel.Text = "Trạng thái: HÃY NHẶT 1 VẬT PHẨM BẤT KỲ ĐỂ DẠY!"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
                    
                    local currentNearby = getNearbyObjects(15) -- Quét 15 mét quanh người
                    
                    -- Kiểm tra xem có vật nào vừa biến mất không (tức là vừa bị nhặt)
                    for obj, name in pairs(previousNearbyObjects) do
                        if not obj.Parent or obj.Parent == char or obj.Parent == LocalPlayer:FindFirstChild("Backpack") then
                            learnedItemName = name -- LƯU TÊN LẠI!
                            break
                        end
                    end
                    
                    previousNearbyObjects = currentNearby
                    task.wait(0.1)

                -- 2. CHẾ ĐỘ AUTO: Đã biết tên, bay đi nhặt liên tục
                else
                    StatusLabel.Text = "Mục tiêu: " .. learnedItemName .. " | Đang bay..."
                    StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)

                    local target = getNearestItem(learnedItemName)
                    if target then
                        local targetCFrame
                        if target:IsA("BasePart") then
                            targetCFrame = target.CFrame
                        elseif target:IsA("Model") and target.PrimaryPart then
                            targetCFrame = target.PrimaryPart.CFrame
                        end

                        if targetCFrame then
                            -- Teleport tới vật phẩm
                            root.CFrame = targetCFrame
                            root.Velocity = Vector3.new(0, 0, 0) -- Giữ cho không bị văng

                            -- Chờ nó biến mất (đã nhặt xong) hoặc timeout 3 giây (chống kẹt)
                            local timeOut = 0
                            while target and target.Parent and target.Parent ~= char and isSystemOn and timeOut < 30 do
                                task.wait(0.1)
                                timeOut = timeOut + 1
                            end
                        end
                    else
                        -- Hết vật phẩm, chờ nó spawn ra lại
                        StatusLabel.Text = "Mục tiêu: " .. learnedItemName .. " | Đang chờ spawn..."
                        task.wait(1)
                    end
                end
            end
        end)
    else
        ToggleBtn.Text = "▶ BẬT CHẾ ĐỘ HỌC"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        StatusLabel.Text = "Trạng thái: Đang dừng."
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- Nút Reset (Quên mẫu vật để dạy lại)
ResetBtn.MouseButton1Click:Connect(function()
    learnedItemName = nil
    previousNearbyObjects = {}
    if isSystemOn then
        StatusLabel.Text = "Đã xóa mẫu! HÃY NHẶT LẠI 1 CÁI MỚI!"
    else
        StatusLabel.Text = "Đã xóa mẫu. Sẵn sàng học."
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    isSystemOn = false
    ScreenGui:Destroy()
end)
