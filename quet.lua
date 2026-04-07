-- ==========================================
-- TÊN: V4 - DEEP GAME STRUCTURE ANALYZER
-- CHỨC NĂNG: Quét toàn diện, phân loại ưu tiên, tối ưu hiệu suất
-- ==========================================

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local ScanButton = Instance.new("TextButton")
local CopyButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local ProgressBar = Instance.new("Frame")
local ProgressFill = new("Frame")
local AdvancedOptions = Instance.new("Frame")
local DeepScanToggle = Instance.new("TextButton")

-- Setup UI
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "DeepAnalyzerV4"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 320, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true

TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.Code
TitleLabel.Text = " ☣️ V4 DEEP STRUCTURE ANALYZER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
TitleLabel.TextSize = 15

ScanButton.Parent = MainFrame
ScanButton.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
ScanButton.Position = UDim2.new(0.05, 0, 0.15, 0)
ScanButton.Size = UDim2.new(0.9, 0, 0, 35)
ScanButton.Font = Enum.Font.Code
ScanButton.Text = "BẮT ĐẦU PHÂN TÍCH SÂU"
ScanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanButton.TextSize = 14

ProgressBar.Parent = MainFrame
ProgressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ProgressBar.Position = UDim2.new(0.05, 0, 0.37, 0)
ProgressBar.Size = UDim2.new(0.9, 0, 0, 10)

ProgressFill.Parent = ProgressBar
ProgressFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
ProgressFill.Size = UDim2.new(0, 0, 1, 0)

CopyButton.Parent = MainFrame
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
CopyButton.Position = UDim2.new(0.05, 0, 0.5, 0)
CopyButton.Size = UDim2.new(0.9, 0, 0, 35)
CopyButton.Font = Enum.Font.Code
CopyButton.Text = "COPY LOG DỮ LIỆU"
CopyButton.TextColor3 = Color3.fromRGB(150, 150, 150)
CopyButton.TextSize = 14

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.7, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 50)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "Trạng thái: Đang chờ lệnh..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true

-- Tùy chọn quét sâu
AdvancedOptions.Parent = MainFrame
AdvancedOptions.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AdvancedOptions.Position = UDim2.new(0.05, 0, 0.6, 0)
AdvancedOptions.Size = UDim2.new(0.9, 0, 0, 25)
AdvancedOptions.Visible = false

DeepScanToggle.Parent = AdvancedOptions
DeepScanToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
DeepScanToggle.Size = UDim2.new(1, 0, 1, 0)
DeepScanToggle.Font = Enum.Font.Code
DeepScanToggle.Text = "Quét sâu (chậm hơn): TẮT"
DeepScanToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
DeepScanToggle.TextSize = 12

local finalLog = ""
local isScanning = false
local deepScanEnabled = false

-- Bảng màu cho các loại đối tượng quan trọng
local importanceColors = {
    critical = Color3.fromRGB(255, 50, 50),     -- Đỏ: Các remote quan trọng, script
    high = Color3.fromRGB(255, 150, 50),        -- Cam: Models với humanoid, vật thể tương tác
    medium = Color3.fromRGB(255, 255, 50),      -- Vàng: Folders lớn, UI quan trọng
    normal = Color3.fromRGB(150, 150, 150)      -- Xám: Các đối tượng khác
}

-- Hàm xác định mức độ quan trọng của đối tượng
local function getImportanceLevel(obj)
    -- Remote events và functions - cực kỳ quan trọng
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        return "critical"
    end
    
    -- Scripts và LocalScripts - cực kỳ quan trọng
    if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        return "critical"
    end
    
    -- Bindable events và functions - quan trọng cao
    if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
        return "high"
    end
    
    -- Models với Humanoid - quan trọng cao
    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") then
        return "high"
    end
    
    -- Các vật thể có thể tương tác - quan trọng cao
    if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
        return "high"
    end
    
    -- Folders với nhiều con - quan trọng trung bình
    if obj:IsA("Folder") and #obj:GetChildren() > 10 then
        return "medium"
    end
    
    -- UI quan trọng - quan trọng trung bình
    if obj:IsA("ScreenGui") or obj:IsA("Frame") or obj:IsA("ImageButton") then
        return "medium"
    end
    
    return "normal"
end

-- Hàm phân tích chi tiết một đối tượng
local function analyzeObjectDetails(obj, deep)
    local details = ""
    local importance = getImportanceLevel(obj)
    
    details = details .. string.format("  [%s] %s (%s)\n", 
        importance:upper(), obj.Name, obj.ClassName)
    
    -- Thêm đường dẫn đầy đủ
    details = details .. string.format("    Path: %s\n", obj:GetFullName())
    
    -- Phân tích các thuộc tính quan trọng
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        details = details .. "    Type: Remote Communication\n"
    elseif obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        details = details .. "    Type: Script\n"
        if deep then
            -- Với quét sâu, thêm một vài dòng đầu của script
            local source = obj.Source
            if source and #source > 0 then
                local firstLines = source:split("\n")
                details = details .. "    First lines: " .. (firstLines[1] or ""):sub(1, 50) .. "...\n"
            end
        end
    elseif obj:IsA("Model") then
        local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if primary then
            details = details .. string.format("    Primary Part: %s\n", primary.Name)
        end
        local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            details = details .. string.format("    Health: %d/%d\n", humanoid.Health, humanoid.MaxHealth)
        end
    elseif obj:IsA("BasePart") then
        details = details .. string.format("    Size: %s\n", tostring(obj.Size))
        details = details .. string.format("    Position: %s\n", tostring(obj.Position))
        if obj:FindFirstChild("TouchInterest") then
            details = details .. "    Interactable: Yes\n"
        end
    elseif obj:IsA("Folder") then
        details = details .. string.format("    Children Count: %d\n", #obj:GetChildren())
    elseif obj:IsA("ScreenGui") then
        details = details .. string.format("    Enabled: %s\n", tostring(obj.Enabled))
    end
  
```lua
    -- Với quét sâu, thêm thông tin về các con quan trọng
    if deep then
        local importantChildren = {}
        for _, child in pairs(obj:GetChildren()) do
            local childImportance = getImportanceLevel(child)
            if childImportance == "critical" or childImportance == "high" then
                table.insert(importantChildren, child.Name)
            end
        end
        if #importantChildren > 0 then
            details = details .. "    Important Children: " .. table.concat(importantChildren, ", ") .. "\n"
        end
    end
    
    return details
end

-- Hàm phân tích một thư mục và các đối tượng con
local function analyzeFolderContents(folder, deep)
    local children = folder:GetChildren()
    if #children == 0 then return "  [EMPTY] " .. folder.Name .. "\n" end
    
    local result = string.format("  [FOLDER] %s (%d objects)\n", folder.Name, #children)
    
    -- Sắp xếp các đối tượng theo mức độ quan trọng
    local sortedChildren = {}
    local importanceGroups = {
        critical = {},
        high = {},
        medium = {},
        normal = {}
    }
    
    for _, child in pairs(children) do
        local importance = getImportanceLevel(child)
        table.insert(importanceGroups[importance], child)
    end
    
    -- Thêm các đối tượng vào danh sách đã sắp xếp
    for _, importance in ipairs({"critical", "high", "medium", "normal"}) do
        for _, child in pairs(importanceGroups[importance]) do
            table.insert(sortedChildren, child)
        end
    end
    
    -- Phân tích các đối tượng
    for i, obj in ipairs(sortedChildren) do
        result = result .. analyzeObjectDetails(obj, deep)
        
        -- Giới hạn số lượng đối tượng hiển thị cho mỗi thư mục
        if i >= 20 and not deep then
            result = result .. "    ... (and " .. (#children - i) .. " more objects)\n"
            break
        end
    end
    
    return result .. "\n"
end

-- Hàm quét toàn diện game
local function performDeepScan()
    local player = game.Players.LocalPlayer
    finalLog = "===== PHÂN TÍCH CẤU TRÚC GAME: " .. game.Name .. " =====\n"
    finalLog = finalLog .. "Thời gian: " .. os.date("%d/%m/%Y %H:%M:%S") .. "\n"
    finalLog = finalLog .. "Chế độ quét: " .. (deepScanEnabled and "SÂU" or "TIÊU CHUẨN") .. "\n\n"
    
    -- BƯỚC 1: Phân tích các Remote Events và Functions (quan trọng nhất)
    StatusLabel.Text = "Tiến trình [1/5]: Đang quét các Remote Events/Functions..."
    ProgressFill.Size = UDim2.new(0.2, 0, 1, 0)
    
    finalLog = finalLog .. "[1] REMOTE COMMUNICATION (QUAN TRỌNG NHẤT):\n"
    local remotes = {}
    
    -- Quét tất cả các descendants để tìm remotes
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local path = obj:GetFullName()
            -- Bỏ qua các remotes mặc định của Roblox
            if not string.find(path, "RobloxReplicatedStorage") and 
               not string.find(path, "DefaultChatSystemChatEvents") and
               not string.find(path, "CoreGui") then
                table.insert(remotes, obj)
            end
        end
        -- Tạm dừng sau mỗi 500 đối tượng để tránh lag
        if #remotes % 500 == 0 then task.wait() end 
    end
    
    -- Phân tích các remotes tìm được
    for i, remote in ipairs(remotes) do
        finalLog = finalLog .. analyzeObjectDetails(remote, deepScanEnabled)
        -- Tạm dừng sau mỗi 50 remotes
        if i % 50 == 0 then task.wait() end
    end
    finalLog = finalLog .. "\n"
    
    -- BƯỚC 2: Phân tích Scripts (quan trọng cao)
    StatusLabel.Text = "Tiến trình [2/5]: Đang quét Scripts và Modules..."
    ProgressFill.Size = UDim2.new(0.4, 0, 1, 0)
    
    finalLog = finalLog .. "[2] SCRIPTS & MODULES (QUAN TRỌNG CAO):\n"
    local scripts = {}
    
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            table.insert(scripts, obj)
        end
        -- Tạm dừng sau mỗi 500 đối tượng
        if #scripts % 500 == 0 then task.wait() end 
    end
    
    -- Phân tích các scripts
    for i, script in ipairs(scripts) do
        finalLog = finalLog .. analyzeObjectDetails(script, deepScanEnabled)
        -- Tạm dừng sau mỗi 50 scripts
        if i % 50 == 0 then task.wait() end
    end
    finalLog = finalLog .. "\n"
    
    -- BƯỚC 3: Phân tích Workspace (quan trọng cao)
    StatusLabel.Text = "Tiến trình [3/5]: Đang phân tích Workspace..."
    ProgressFill.Size = UDim2.new(0.6, 0, 1, 0)
    
    finalLog = finalLog .. "[3] WORKSPACE STRUCTURE:\n"
    
    -- Phân tích các thư mục quan trọng trong Workspace
    local workspaceFolders = {}
    for _, obj in pairs(game.Workspace:GetChildren()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            table.insert(workspaceFolders, obj)
        end
    end
    
    -- Sắp xếp theo số lượng con (lớn trước)
    table.sort(workspaceFolders, function(a, b) 
        return #a:GetChildren() > #b:GetChildren() 
    end)
    
    for i, folder in ipairs(workspaceFolders) do
        finalLog = finalLog .. analyzeFolderContents(folder, deepScanEnabled)
        -- Tạm dừng sau mỗi 20 thư mục
        if i % 20 == 0 then task.wait() end
    end
    finalLog = finalLog .. "\n"
    
    -- BƯỚC 4: Phân tích PlayerGui và ReplicatedStorage
    StatusLabel.Text = "Tiến trình [4/5]: Đang quét UI và ReplicatedStorage..."
    ProgressFill.Size = UDim2.new(0.8, 0, 1, 0)
    
    finalLog = finalLog .. "[4] PLAYER GUI & REPLICATED STORAGE:\n"
    
    -- Phân tích PlayerGui
    local gui = player:WaitForChild("PlayerGui")
    finalLog = finalLog .. "  PlayerGui:\n"
    for _, v in pairs(gui:GetChildren()) do
        finalLog = finalLog .. analyzeObjectDetails(v, deepScanEnabled)
    end
    
    -- Phân tích ReplicatedStorage
    finalLog = finalLog .. "  ReplicatedStorage:\n"
    for _, v in pairs(game.ReplicatedStorage:GetChildren()) do
        finalLog = finalLog .. analyzeObjectDetails(v, deepScanEnabled)
    end
    finalLog = finalLog .. "\n"
    
    -- BƯỚC 5: Phân tích các thành phần khác
    StatusLabel.Text = "Tiến trình [5/5]: Đang hoàn thiện phân tích..."
    ProgressFill.Size = UDim2.new(0.95, 0, 1, 0)
    
    finalLog = finalLog .. "[5] OTHER COMPONENTS:\n"
    
    -- Phân tích Lighting
    finalLog = finalLog .. "  Lighting:\n"
    for _, v in pairs(game.Lighting:GetChildren()) do
        finalLog = finalLog .. analyzeObjectDetails(v, false)  -- Không cần quét sâu ở đây
    end
    
    -- Phân tích Teams
    if #game.Teams:GetChildren() > 0 then
        finalLog = finalLog .. "  Teams:\n"
        for _, team in pairs(game.Teams:GetChildren()) do
            finalLog = finalLog .. analyzeObjectDetails(team, false)
        end
    end
    
    -- Hoàn tất
    ProgressFill.Size = UDim2.new(1, 0, 1, 0)
    StatusLabel.Text = "🎉 HOÀN TẤT 100%! BẠN CÓ THỂ COPY!"
    ScanButton.Text = "QUÉT LẠI
    ScanButton.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
    CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    isScanning = false
end

-- Xử lý sự kiện click nút Scan
ScanButton.MouseButton1Click:Connect(function()
    if isScanning then return end
    isScanning = true
    ScanButton.Text = "ĐANG CHẠY NỀN..."
    ScanButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    CopyButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    finalLog = ""
    
    -- Sử dụng task.spawn để đưa vào luồng chạy nền, game không bị lag
    task.spawn(performDeepScan)
end)

-- Xử lý sự kiện click nút Copy
CopyButton.MouseButton1Click:Connect(function()
    if finalLog ~= "" and not isScanning then
        if setclipboard then
            setclipboard(finalLog)
            StatusLabel.Text = "ĐÃ COPY VÀO KHAY NHỚ TẠM! HÃY DÁN RA GHI CHÚ."
        else
            StatusLabel.Text = "Lỗi: Máy bạn không hỗ trợ setclipboard."
        end
    end
end)

-- Xử lý sự kiện click nút Deep Scan Toggle
DeepScanToggle.MouseButton1Click:Connect(function()
    deepScanEnabled = not deepScanEnabled
    DeepScanToggle.Text = "Quét sâu (chậm hơn): " .. (deepScanEnabled and "BẬT" or "TẮT")
    DeepScanToggle.BackgroundColor3 = deepScanEnabled and Color3.fromRGB(80, 0, 150) or Color3.fromRGB(60, 60, 60)
end)

-- Tự động hiển thị tùy chọn quét sâu khi chuột di chuyển vào khu vực
MainFrame.MouseEnter:Connect(function()
    AdvancedOptions.Visible = true
end)

MainFrame.MouseLeave:Connect(function()
    AdvancedOptions.Visible = false
end)
