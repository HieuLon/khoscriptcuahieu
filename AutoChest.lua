local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- DỌN DẸP UI CŨ
-- ==========================================
local guiName = "AutoChest_V4_Final"
if CoreGui:FindFirstChild(guiName) then
    CoreGui[guiName]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui

-- ==========================================
-- GIAO DIỆN CHÍNH (CÓ THỂ THU GỌN)
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 180) -- Tăng chiều cao lên chút để chứa dòng Status
MainFrame.Position = UDim2.new(0.5, -110, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true -- Cực kỳ quan trọng để làm tính năng thu gọn
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- THANH TOPBAR (CHỨA TIÊU ĐỀ & NÚT - X)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0.05, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AUTO RƯƠNG V4"
Title.TextColor3 = Color3.fromRGB(255, 150, 50)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -60, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TopBar

-- CONTAINER (Chứa các nút bên dưới TopBar)
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, 0, 1, -30)
Container.Position = UDim2.new(0, 0, 0, 30)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local KeywordInput = Instance.new("TextBox")
KeywordInput.Size = UDim2.new(0.9, 0, 0, 30)
KeywordInput.Position = UDim2.new(0.05, 0, 0.1, 0)
KeywordInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
KeywordInput.Text = "Chest"
KeywordInput.PlaceholderText = "Tên rương..."
KeywordInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeywordInput.Font = Enum.Font.Gotham
KeywordInput.TextSize = 13
KeywordInput.Parent = Container
Instance.new("UICorner", KeywordInput).CornerRadius = UDim.new(0, 5)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
StatusLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Trạng thái: Đang chờ lệnh"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = Container

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ToggleBtn.Text = "▶ BẮT ĐẦU QUÉT"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = Container
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

-- ==========================================
-- LOGIC THU GỌN GIAO DIỆN
-- ==========================================
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 220, 0, 30) -- Chỉ hiện thanh TopBar
        MinBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 220, 0, 180) -- Hiện lại toàn bộ
        MinBtn.Text = "-"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    _G.AutoChestRunning = false
    ScreenGui:Destroy()
end)

-- ==========================================
-- LOGIC AUTO MỞ RƯƠNG THÔNG MINH
-- ==========================================
_G.AutoChestRunning = false
local lootedBlacklist = {} -- Bảng lưu các rương ĐÃ MỞ để không loot lại

local function getPromptCFrame(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    if parent:IsA("BasePart") then return parent.CFrame end
    if parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then return parent.Parent.CFrame end
    if parent:IsA("Model") and parent.PrimaryPart then return parent.PrimaryPart.CFrame end
    return nil
end

ToggleBtn.MouseButton1Click:Connect(function()
    _G.AutoChestRunning = not _G.AutoChestRunning

    if _G.AutoChestRunning then
        ToggleBtn.Text = "⏸ ĐANG MỞ (DỪNG)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StatusLabel.Text = "Trạng thái: Đang quét map..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)

        task.spawn(function()
            while _G.AutoChestRunning do
                local keyword = KeywordInput.Text:lower()
                if keyword == "" then keyword = "chest" end

                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local foundAnyChest = false

                if root then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if not _G.AutoChestRunning then break end

                        -- Chỉ quét các nút chưa bị cho vào danh sách đen và còn đang Enabled
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            -- Nếu rương này mới mở trong vòng 20 giây đổ lại thì bỏ qua
                            if lootedBlacklist[obj] and (tick() - lootedBlacklist[obj] < 20) then
                                continue
                            end

                            local pName = obj.Parent and obj.Parent.Name:lower() or ""
                            local aText = obj.ActionText:lower()
                            local oText = obj.ObjectText:lower()

                            if pName:match(keyword) or aText:match(keyword) or oText:match(keyword) then
                                local targetCFrame = getPromptCFrame(obj)
                                
                                if targetCFrame then
                                    foundAnyChest = true
                                    local chestName = obj.ObjectText ~= "" and obj.ObjectText or "Rương VIP"
                                    StatusLabel.Text = "Mục tiêu: " .. chestName
                                    StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
                                    
                                    -- 1. Bay đến rương
                                    root.CFrame = targetCFrame
                                    root.Velocity = Vector3.new(0, 0, 0)
                                    task.wait(0.5)

                                    -- 2. Kiểm tra lại lần nữa coi rương còn không trước khi mở
                                    if obj.Enabled then
                                        obj.HoldDuration = 0
                                        if fireproximityprompt then
                                            fireproximityprompt(obj)
                                        else
                                            obj:InputHoldBegin()
                                            task.wait(0.05)
                                            obj:InputHoldEnd()
                                        end
                                        
                                        -- 3. Đánh dấu ĐÃ MỞ vào Blacklist để không kẹt ở rương này
                                        lootedBlacklist[obj] = tick()
                                        
                                        -- Đợi 1.5s cho đồ rớt ra
                                        task.wait(1.5)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Nếu quét hết 1 vòng bản đồ mà không thấy cái rương nào (hoặc đã mở sạch)
                if not foundAnyChest and _G.AutoChestRunning then
                    StatusLabel.Text = "Hết rương, đang chờ..."
                    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
                
                -- Nghỉ 1 giây trước khi đi tuần tra quét map lần nữa
                task.wait(1)
            end
        end)
    else
        ToggleBtn.Text = "▶ BẮT ĐẦU QUÉT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        StatusLabel.Text = "Trạng thái: Đang chờ lệnh"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)
