-- ==========================================
-- TÊN: V5 - ULTRA DEEP GAME STRUCTURE ANALYZER
-- PHIÊN BẢN: 5.0 - Full Recursive + Multi-Service Scan
-- CHỨC NĂNG: Quét đệ quy toàn bộ game, phân loại ưu tiên,
--            phát hiện interactions, đọc values, bao pcall toàn bộ
-- ==========================================

-- ==========================================
-- PHẦN 1: TẠO UI
-- ==========================================

local ScreenGui      = Instance.new("ScreenGui")
local MainFrame      = Instance.new("Frame")
local TitleLabel     = Instance.new("TextLabel")
local ScanButton     = Instance.new("TextButton")
local CopyButton     = Instance.new("TextButton")
local StatusLabel    = Instance.new("TextLabel")
local ProgressBar    = Instance.new("Frame")
local ProgressFill   = Instance.new("Frame")       -- FIX: Instance.new đúng
local AdvancedFrame  = Instance.new("Frame")
local DeepToggle     = Instance.new("TextButton")
local MaxDepthLabel  = Instance.new("TextLabel")
local DepthMinus     = Instance.new("TextButton")
local DepthPlus      = Instance.new("TextButton")
local StatLabel      = Instance.new("TextLabel")

-- ScreenGui
ScreenGui.Parent        = game:GetService("CoreGui")
ScreenGui.Name          = "UltraAnalyzerV5"
ScreenGui.ResetOnSpawn  = false

-- MainFrame
MainFrame.Parent           = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel  = 0
MainFrame.Position         = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.Size             = UDim2.new(0, 340, 0, 340)
MainFrame.Active           = true
MainFrame.Draggable        = true

-- Viền tím neon cho MainFrame
local UIStroke1 = Instance.new("UIStroke")
UIStroke1.Color     = Color3.fromRGB(140, 0, 255)
UIStroke1.Thickness = 1.5
UIStroke1.Parent    = MainFrame

-- TitleLabel
TitleLabel.Parent          = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 0, 60)
TitleLabel.Size            = UDim2.new(1, 0, 0, 32)
TitleLabel.Font            = Enum.Font.Code
TitleLabel.Text            = "⚡ V5 ULTRA DEEP ANALYZER"
TitleLabel.TextColor3      = Color3.fromRGB(200, 100, 255)
TitleLabel.TextSize        = 14
TitleLabel.BorderSizePixel = 0

-- ScanButton
ScanButton.Parent           = MainFrame
ScanButton.BackgroundColor3 = Color3.fromRGB(80, 0, 180)
ScanButton.Position         = UDim2.new(0.05, 0, 0, 42)
ScanButton.Size             = UDim2.new(0.9, 0, 0, 36)
ScanButton.Font             = Enum.Font.Code
ScanButton.Text             = "▶  BẮT ĐẦU QUÉT SÂU"
ScanButton.TextColor3       = Color3.fromRGB(255, 255, 255)
ScanButton.TextSize         = 14
ScanButton.BorderSizePixel  = 0
local UICorner1 = Instance.new("UICorner")
UICorner1.CornerRadius = UDim.new(0, 6)
UICorner1.Parent = ScanButton

-- ProgressBar background
ProgressBar.Parent           = MainFrame
ProgressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
ProgressBar.Position         = UDim2.new(0.05, 0, 0, 88)
ProgressBar.Size             = UDim2.new(0.9, 0, 0, 10)
ProgressBar.BorderSizePixel  = 0
local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 5)
UICorner2.Parent = ProgressBar

-- ProgressFill
ProgressFill.Parent           = ProgressBar
ProgressFill.BackgroundColor3 = Color3.fromRGB(120, 0, 255)
ProgressFill.Size             = UDim2.new(0, 0, 1, 0)
ProgressFill.BorderSizePixel  = 0
local UICorner3 = Instance.new("UICorner")
UICorner3.CornerRadius = UDim.new(0, 5)
UICorner3.Parent = ProgressFill

-- StatLabel (hiển thị số liệu: remotes, scripts, objects đã tìm)
StatLabel.Parent              = MainFrame
StatLabel.BackgroundColor3    = Color3.fromRGB(20, 20, 30)
StatLabel.Position            = UDim2.new(0.05, 0, 0, 106)
StatLabel.Size                = UDim2.new(0.9, 0, 0, 28)
StatLabel.Font                = Enum.Font.Code
StatLabel.Text                = "Remotes: 0  |  Scripts: 0  |  Objects: 0"
StatLabel.TextColor3          = Color3.fromRGB(160, 255, 160)
StatLabel.TextSize            = 11
StatLabel.BorderSizePixel     = 0

-- Advanced Options Frame
AdvancedFrame.Parent           = MainFrame
AdvancedFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
AdvancedFrame.Position         = UDim2.new(0.05, 0, 0, 142)
AdvancedFrame.Size             = UDim2.new(0.9, 0, 0, 70)
AdvancedFrame.BorderSizePixel  = 0
local UICorner4 = Instance.new("UICorner")
UICorner4.CornerRadius = UDim.new(0, 6)
UICorner4.Parent = AdvancedFrame

-- DeepToggle button
DeepToggle.Parent           = AdvancedFrame
DeepToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
DeepToggle.Position         = UDim2.new(0.03, 0, 0.1, 0)
DeepToggle.Size             = UDim2.new(0.94, 0, 0, 24)
DeepToggle.Font             = Enum.Font.Code
DeepToggle.Text             = "🔍 Quét sâu (đệ quy): TẮT"
DeepToggle.TextColor3       = Color3.fromRGB(200, 200, 200)
DeepToggle.TextSize         = 12
DeepToggle.BorderSizePixel  = 0
local UICorner5 = Instance.new("UICorner")
UICorner5.CornerRadius = UDim.new(0, 4)
UICorner5.Parent = DeepToggle

-- Depth controls label
MaxDepthLabel.Parent           = AdvancedFrame
MaxDepthLabel.BackgroundTransparency = 1
MaxDepthLabel.Position         = UDim2.new(0.03, 0, 0, 36)
MaxDepthLabel.Size             = UDim2.new(0.5, 0, 0, 26)
MaxDepthLabel.Font             = Enum.Font.Code
MaxDepthLabel.Text             = "Độ sâu tối đa: 5"
MaxDepthLabel.TextColor3       = Color3.fromRGB(180, 180, 180)
MaxDepthLabel.TextSize         = 12
MaxDepthLabel.TextXAlignment   = Enum.TextXAlignment.Left

DepthMinus.Parent           = AdvancedFrame
DepthMinus.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
DepthMinus.Position         = UDim2.new(0.66, 0, 0, 38)
DepthMinus.Size             = UDim2.new(0.14, 0, 0, 22)
DepthMinus.Font             = Enum.Font.Code
DepthMinus.Text             = " - "
DepthMinus.TextColor3       = Color3.fromRGB(255, 255, 255)
DepthMinus.TextSize         = 14
DepthMinus.BorderSizePixel  = 0

DepthPlus.Parent           = AdvancedFrame
DepthPlus.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
DepthPlus.Position         = UDim2.new(0.82, 0, 0, 38)
DepthPlus.Size             = UDim2.new(0.14, 0, 0, 22)
DepthPlus.Font             = Enum.Font.Code
DepthPlus.Text             = " + "
DepthPlus.TextColor3       = Color3.fromRGB(255, 255, 255)
DepthPlus.TextSize         = 14
DepthPlus.BorderSizePixel  = 0

-- CopyButton
CopyButton.Parent           = MainFrame
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
CopyButton.Position         = UDim2.new(0.05, 0, 0, 222)
CopyButton.Size             = UDim2.new(0.9, 0, 0, 36)
CopyButton.Font             = Enum.Font.Code
CopyButton.Text             = "📋  COPY LOG DỮ LIỆU"
CopyButton.TextColor3       = Color3.fromRGB(100, 100, 100)
CopyButton.TextSize         = 14
CopyButton.BorderSizePixel  = 0
local UICorner6 = Instance.new("UICorner")
UICorner6.CornerRadius = UDim.new(0, 6)
UICorner6.Parent = CopyButton

-- StatusLabel
StatusLabel.Parent              = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position            = UDim2.new(0.03, 0, 0, 268)
StatusLabel.Size                = UDim2.new(0.94, 0, 0, 65)
StatusLabel.Font                = Enum.Font.Code
StatusLabel.Text                = "⏳ Trạng thái: Đang chờ lệnh..."
StatusLabel.TextColor3          = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize            = 11
StatusLabel.TextWrapped         = true
StatusLabel.TextXAlignment      = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment      = Enum.TextYAlignment.Top

-- ==========================================
-- PHẦN 2: BIẾN TRẠNG THÁI
-- ==========================================

local finalLog      = ""
local isScanning    = false
local deepScan      = false
local maxDepth      = 5

local stats = {
    remotes  = 0,
    scripts  = 0,
    objects  = 0,
    values   = 0,
    prompts  = 0,
}

-- ==========================================
-- PHẦN 3: HELPER FUNCTIONS
-- ==========================================

-- Lấy giá trị thuộc tính an toàn, tránh crash
local function safeGet(obj, prop)
    local ok, val = pcall(function() return obj[prop] end)
    if not ok then return "N/A" end
    return tostring(val)
end

-- Cập nhật label thống kê
local function updateStats()
    StatLabel.Text = string.format(
        "Remotes: %d  |  Scripts: %d  |  Objects: %d",
        stats.remotes, stats.scripts, stats.objects
    )
end

-- Xác định mức độ quan trọng
local function getImportance(obj)
    local ok, _ = pcall(function()
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then return end
    end)
    if not ok then return "normal" end

    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then return "critical" end
    if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then return "critical" end
    if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then return "high" end
    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") then return "high" end
    if obj:IsA("BasePart") then
        if obj:FindFirstChild("TouchInterest")
        or obj:FindFirstChildWhichIsA("ClickDetector")
        or obj:FindFirstChildWhichIsA("ProximityPrompt") then
            return "high"
        end
    end
    if obj:IsA("Folder") and #obj:GetChildren() > 10 then return "medium" end
    if obj:IsA("ScreenGui") or obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then return "medium" end
    if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue")
       or obj:IsA("NumberValue") or obj:IsA("ObjectValue") or obj:IsA("Vector3Value") then
        return "medium"
    end
    return "normal"
end

-- ==========================================
-- PHẦN 4: PHÂN TÍCH CHI TIẾT ĐỐI TƯỢNG
-- ==========================================

local function analyzeObject(obj, indent)
    local info  = ""
    local imp   = getImportance(obj)
    local pad   = string.rep("  ", indent)
    local tag   = string.format("[%s]", imp:upper())

    -- Dòng tiêu đề đối tượng
    info = info .. string.format("%s%s %s (%s)\n", pad, tag, safeGet(obj, "Name"), obj.ClassName)

    -- ---- RemoteEvent / RemoteFunction ----
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        stats.remotes = stats.remotes + 1
        info = info .. pad .. "  Path: " .. obj:GetFullName() .. "\n"
        info = info .. pad .. "  Type: Remote Communication\n"

    -- ---- Scripts ----
    elseif obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        stats.scripts = stats.scripts + 1
        info = info .. pad .. "  Path: " .. obj:GetFullName() .. "\n"
        local scriptType = obj:IsA("LocalScript") and "LocalScript" 
                        or obj:IsA("ModuleScript") and "ModuleScript" 
                        or "Script"
        info = info .. pad .. "  ScriptType: " .. scriptType .. "\n"

        -- Cố đọc dòng đầu source (executor có thể cho phép)
        local ok2, src = pcall(function() return obj.Source end)
        if ok2 and src and #src > 0 then
            local firstLine = src:match("([^\n]*)")
            if firstLine and #firstLine > 0 then
                info = info .. pad .. "  Source[1]: " .. firstLine:sub(1, 80) .. "\n"
            end
        end

    -- ---- Model ----
    elseif obj:IsA("Model") then
        local primary = safeGet(obj, "PrimaryPart")
        info = info .. pad .. "  PrimaryPart: " .. primary .. "\n"
        local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            info = info .. string.format("%s  HP: %s / %s\n",
                pad, safeGet(humanoid, "Health"), safeGet(humanoid, "MaxHealth"))
            info = info .. pad .. "  WalkSpeed: " .. safeGet(humanoid, "WalkSpeed") .. "\n"
            info = info .. pad .. "  JumpPower: " .. safeGet(humanoid, "JumpPower") .. "\n"
        end

    -- ---- BasePart ----
    elseif obj:IsA("BasePart") then
        info = info .. pad .. "  Size:      " .. safeGet(obj, "Size") .. "\n"
        info = info .. pad .. "  Position:  " .. safeGet(obj, "Position") .. "\n"
        info = info .. pad .. "  Anchored:  " .. safeGet(obj, "Anchored") .. "\n"
        info = info .. pad .. "  CanCollide:" .. safeGet(obj, "CanCollide") .. "\n"
        info = info .. pad .. "  Material:  " .. safeGet(obj, "Material") .. "\n"
        info = info .. pad .. "  Massless:  " .. safeGet(obj, "Massless") .. "\n"

        -- Interactions
        local cd = obj:FindFirstChildWhichIsA("ClickDetector")
        if cd then
            info = info .. pad .. "  [!] ClickDetector (MaxDistance: " .. safeGet(cd, "MaxActivationDistance") .. ")\n"
            stats.prompts = stats.prompts + 1
        end
        local pp = obj:FindFirstChildWhichIsA("ProximityPrompt")
        if pp then
            info = info .. pad .. "  [!] ProximityPrompt: \"" .. safeGet(pp, "ActionText") .. "\" / \"" .. safeGet(pp, "ObjectText") .. "\"\n"
            stats.prompts = stats.prompts + 1
        end
        if obj:FindFirstChild("TouchInterest") then
            info = info .. pad .. "  [!] TouchInterest active\n"
        end

    -- ---- Value objects ----
    elseif obj:IsA("ValueBase") or obj:IsA("IntValue") or obj:IsA("StringValue")
        or obj:IsA("BoolValue") or obj:IsA("NumberValue") or obj:IsA("ObjectValue")
        or obj:IsA("Vector3Value") or obj:IsA("Color3Value") or obj:IsA("CFrameValue") then
        local ok2, val = pcall(function() return obj.Value end)
        info = info .. pad .. "  Value: " .. (ok2 and tostring(val) or "N/A") .. "\n"
        stats.values = stats.values + 1

    -- ---- Folder ----
    elseif obj:IsA("Folder") then
        local count = 0
        local ok2, ch = pcall(function() return obj:GetChildren() end)
        if ok2 then count = #ch end
        info = info .. pad .. "  Children: " .. count .. "\n"

    -- ---- GUI ----
    elseif obj:IsA("ScreenGui") then
        info = info .. pad .. "  Enabled: " .. safeGet(obj, "Enabled") .. "\n"
        info = info .. pad .. "  DisplayOrder: " .. safeGet(obj, "DisplayOrder") .. "\n"

    -- ---- Sound ----
    elseif obj:IsA("Sound") then
        info = info .. pad .. "  SoundId: " .. safeGet(obj, "SoundId") .. "\n"
        info = info .. pad .. "  Playing: " .. safeGet(obj, "Playing") .. "\n"
        info = info .. pad .. "  Volume:  " .. safeGet(obj, "Volume") .. "\n"

    -- ---- Animation ----
    elseif obj:IsA("Animation") then
        info = info .. pad .. "  AnimationId: " .. safeGet(obj, "AnimationId") .. "\n"

    -- ---- Bindable ----
    elseif obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
        info = info .. pad .. "  Path: " .. obj:GetFullName() .. "\n"
        info = info .. pad .. "  Type: Bindable (internal)\n"

    -- ---- Tool ----
    elseif obj:IsA("Tool") then
        info = info .. pad .. "  ToolTip: " .. safeGet(obj, "ToolTip") .. "\n"
        info = info .. pad .. "  RequiresHandle: " .. safeGet(obj, "RequiresHandle") .. "\n"

    -- ---- Team ----
    elseif obj:IsA("Team") then
        info = info .. pad .. "  TeamColor: " .. safeGet(obj, "TeamColor") .. "\n"
        info = info .. pad .. "  AutoAssignable: " .. safeGet(obj, "AutoAssignable") .. "\n"
    end

    stats.objects = stats.objects + 1
    return info
end

-- ==========================================
-- PHẦN 5: QUÉT ĐỆ QUY
-- ==========================================

-- Quét đệ quy 1 node, trả về string log
local function scanRecursive(obj, depth, currentDepth)
    local result = ""
    local ok, _ = pcall(function()
        result = result .. analyzeObject(obj, currentDepth)
    end)

    -- Dừng nếu đạt độ sâu tối đa hoặc không deep scan
    if currentDepth >= depth then
        local ok2, ch = pcall(function() return obj:GetChildren() end)
        if ok2 and #ch > 0 then
            local pad = string.rep("  ", currentDepth + 1)
            result = result .. pad .. "... (" .. #ch .. " children, max depth reached)\n"
        end
        return result
    end

    -- Lấy danh sách con và sắp xếp theo importance
    local ok2, children = pcall(function() return obj:GetChildren() end)
    if not ok2 or #children == 0 then return result end

    -- Nhóm theo importance để critical lên trước
    local groups = { critical = {}, high = {}, medium = {}, normal = {} }
    for _, child in ipairs(children) do
        local imp = getImportance(child)
        table.insert(groups[imp], child)
    end

    local sorted = {}
    for _, imp in ipairs({"critical", "high", "medium", "normal"}) do
        for _, c in ipairs(groups[imp]) do
            table.insert(sorted, c)
        end
    end

    for i, child in ipairs(sorted) do
        -- Giới hạn normal objects để tránh log quá dài
        if getImportance(child) == "normal" and i > 30 and not deepScan then
            local pad = string.rep("  ", currentDepth + 1)
            result = result .. pad .. string.format("... (%d more normal objects)\n", #sorted - i + 1)
            break
        end
        result = result .. scanRecursive(child, depth, currentDepth + 1)
        -- Yield mỗi 100 object để tránh timeout
        if stats.objects % 100 == 0 then task.wait() end
    end

    return result
end

-- ==========================================
-- PHẦN 6: HÀM QUÉT CHÍNH
-- ==========================================

local SERVICES_TO_SCAN = {
    { name = "ReplicatedStorage",    getter = function() return game:GetService("ReplicatedStorage") end },
    { name = "ReplicatedFirst",      getter = function() return game:GetService("ReplicatedFirst") end },
    { name = "StarterGui",           getter = function() return game:GetService("StarterGui") end },
    { name = "StarterPack",          getter = function() return game:GetService("StarterPack") end },
    { name = "StarterPlayerScripts", getter = function() return game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts") end },
    { name = "StarterCharacterScripts",getter = function() return game:GetService("StarterPlayer"):FindFirstChild("StarterCharacterScripts") end },
    { name = "Lighting",             getter = function() return game:GetService("Lighting") end },
    { name = "SoundService",         getter = function() return game:GetService("SoundService") end },
    { name = "Chat",                 getter = function() return game:GetService("Chat") end },
    { name = "Teams",                getter = function() return game:GetService("Teams") end },
    { name = "TextChatService",      getter = function() return game:GetService("TextChatService") end },
}

local function performScan()
    -- Reset stats
    stats = { remotes = 0, scripts = 0, objects = 0, values = 0, prompts = 0 }
    finalLog = ""

    local player = game.Players.LocalPlayer
    local depth  = deepScan and maxDepth or 3

    -- Header
    finalLog = finalLog .. "==============================================\n"
    finalLog = finalLog .. "  V5 ULTRA DEEP ANALYZER\n"
    finalLog = finalLog .. "==============================================\n"
    finalLog = finalLog .. "Game   : " .. safeGet(game, "Name") .. "\n"
    finalLog = finalLog .. "PlaceId: " .. safeGet(game, "PlaceId") .. "\n"
    finalLog = finalLog .. "JobId  : " .. safeGet(game, "JobId") .. "\n"
    finalLog = finalLog .. "Player : " .. safeGet(player, "Name") .. "\n"
    finalLog = finalLog .. "Thời gian: " .. os.date("%d/%m/%Y %H:%M:%S") .. "\n"
    finalLog = finalLog .. "Chế độ: " .. (deepScan and ("SÂU (depth=" .. maxDepth .. ")") or "TIÊU CHUẨN (depth=3)") .. "\n"
    finalLog = finalLog .. "==============================================\n\n"

    -- ============================
    -- BƯỚC 1: Remote scan toàn game (nhanh nhất bằng GetDescendants)
    -- ============================
    StatusLabel.Text = "[1/6] Quét tất cả Remote Events & Functions..."
    ProgressFill.Size = UDim2.new(0.15, 0, 1, 0)
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[1] ALL REMOTES (toàn bộ game)\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    local remoteCount = 0
    local ok1, descendants = pcall(function() return game:GetDescendants() end)
    if ok1 then
        for _, obj in ipairs(descendants) do
            local isRemote = false
            pcall(function()
                isRemote = obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or
                           obj:IsA("BindableEvent") or obj:IsA("BindableFunction")
            end)
            if isRemote then
                -- Bỏ qua remotes mặc định của Roblox
                local path = obj:GetFullName()
                local isDefault = path:find("RobloxReplicatedStorage") or
                                  path:find("DefaultChatSystemChatEvents") or
                                  path:find("CoreGui")
                if not isDefault then
                    finalLog = finalLog .. analyzeObject(obj, 0)
                    remoteCount = remoteCount + 1
                end
            end
            if remoteCount % 50 == 0 then task.wait() end
        end
    end
    finalLog = finalLog .. string.format("\n→ Tổng remotes tìm được: %d\n\n", remoteCount)
    updateStats()

    -- ============================
    -- BƯỚC 2: Script scan toàn game
    -- ============================
    StatusLabel.Text = "[2/6] Quét tất cả Scripts & Modules..."
    ProgressFill.Size = UDim2.new(0.30, 0, 1, 0)
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[2] ALL SCRIPTS & MODULES\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    local scriptCount = 0
    local ok2, descendants2 = pcall(function() return game:GetDescendants() end)
    if ok2 then
        for _, obj in ipairs(descendants2) do
            local isScript = false
            pcall(function()
                isScript = obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
            end)
            if isScript then
                finalLog = finalLog .. analyzeObject(obj, 0)
                scriptCount = scriptCount + 1
            end
            if scriptCount % 50 == 0 then task.wait() end
        end
    end
    finalLog = finalLog .. string.format("\n→ Tổng scripts tìm được: %d\n\n", scriptCount)
    updateStats()

    -- ============================
    -- BƯỚC 3: Workspace đệ quy
    -- ============================
    StatusLabel.Text = "[3/6] Quét Workspace đệ quy (depth=" .. depth .. ")..."
    ProgressFill.Size = UDim2.new(0.50, 0, 1, 0)
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[3] WORKSPACE (đệ quy)\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    local ok3, wsChildren = pcall(function() return game.Workspace:GetChildren() end)
    if ok3 then
        -- Sắp xếp: folder/model lớn lên trước
        table.sort(wsChildren, function(a, b)
            local ca, cb = 0, 0
            pcall(function() ca = #a:GetChildren() end)
            pcall(function() cb = #b:GetChildren() end)
            return ca > cb
        end)
        for _, child in ipairs(wsChildren) do
            finalLog = finalLog .. scanRecursive(child, depth, 0)
            task.wait()
        end
    end
    finalLog = finalLog .. "\n"
    updateStats()

    -- ============================
    -- BƯỚC 4: PlayerGui + LocalPlayer
    -- ============================
    StatusLabel.Text = "[4/6] Quét PlayerGui & LocalPlayer..."
    ProgressFill.Size = UDim2.new(0.65, 0, 1, 0)
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[4] PLAYER GUI & LOCAL PLAYER\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    -- PlayerGui
    local ok4, gui = pcall(function() return player:WaitForChild("PlayerGui", 3) end)
    if ok4 and gui then
        finalLog = finalLog .. "  [PlayerGui]\n"
        for _, v in ipairs(gui:GetChildren()) do
            finalLog = finalLog .. scanRecursive(v, depth, 1)
        end
    end

    -- Backpack
    local ok5, bp = pcall(function() return player:WaitForChild("Backpack", 3) end)
    if ok5 and bp then
        finalLog = finalLog .. "  [Backpack]\n"
        for _, v in ipairs(bp:GetChildren()) do
            finalLog = finalLog .. analyzeObject(v, 2)
        end
    end

    -- PlayerScripts
    local ok6, ps = pcall(function() return player:WaitForChild("PlayerScripts", 3) end)
    if ok6 and ps then
        finalLog = finalLog .. "  [PlayerScripts]\n"
        for _, v in ipairs(ps:GetChildren()) do
            finalLog = finalLog .. analyzeObject(v, 2)
        end
    end

    -- Character
    local char = player.Character
    if char then
        finalLog = finalLog .. "  [Character: " .. char.Name .. "]\n"
        for _, v in ipairs(char:GetChildren()) do
            finalLog = finalLog .. analyzeObject(v, 2)
        end
    end

    finalLog = finalLog .. "\n"
    updateStats()

    -- ============================
    -- BƯỚC 5: Tất cả services khác
    -- ============================
    StatusLabel.Text = "[5/6] Quét tất cả Services..."
    ProgressFill.Size = UDim2.new(0.80, 0, 1, 0)
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[5] SERVICES\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    for _, svcInfo in ipairs(SERVICES_TO_SCAN) do
        local ok7, svc = pcall(svcInfo.getter)
        if ok7 and svc then
            local ok8, ch = pcall(function() return svc:GetChildren() end)
            if ok8 and #ch > 0 then
                finalLog = finalLog .. string.format("\n  [%s] (%d children)\n", svcInfo.name, #ch)
                for _, v in ipairs(ch) do
                    finalLog = finalLog .. scanRecursive(v, depth, 2)
                    task.wait()
                end
            end
        end
    end
    finalLog = finalLog .. "\n"
    updateStats()

    -- ============================
    -- BƯỚC 6: Summary
    -- ============================
    StatusLabel.Text = "[6/6] Tổng hợp kết quả..."
    ProgressFill.Size = UDim2.new(0.95, 0, 1, 0)
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[6] TỔNG KẾT\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. string.format("  Tổng objects quét:  %d\n", stats.objects)
    finalLog = finalLog .. string.format("  Remote Events/Func: %d\n", stats.remotes)
    finalLog = finalLog .. string.format("  Scripts/Modules:    %d\n", stats.scripts)
    finalLog = finalLog .. string.format("  Value objects:      %d\n", stats.values)
    finalLog = finalLog .. string.format("  Interactions (PP/CD):%d\n", stats.prompts)
    finalLog = finalLog .. string.format("  Log size:           %d chars\n", #finalLog)
    finalLog = finalLog .. "==============================================\n"
    finalLog = finalLog .. "  END OF SCAN - V5 ULTRA DEEP ANALYZER\n"
    finalLog = finalLog .. "==============================================\n"

    -- Hoàn tất
    ProgressFill.Size             = UDim2.new(1, 0, 1, 0)
    ProgressFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    StatusLabel.Text              = "✅ HOÀN TẤT! Tìm được " .. stats.remotes .. " remotes, " .. stats.scripts .. " scripts. Nhấn COPY để lấy log."
    ScanButton.Text               = "🔄  QUÉT LẠI"
    ScanButton.BackgroundColor3   = Color3.fromRGB(80, 0, 180)
    CopyButton.TextColor3         = Color3.fromRGB(255, 255, 255)
    isScanning                    = false
    updateStats()
end

-- ==========================================
-- PHẦN 7: SỰ KIỆN BUTTONS
-- ==========================================

ScanButton.MouseButton1Click:Connect(function()
    if isScanning then return end
    isScanning = true
    finalLog = ""
    ScanButton.Text             = "⏳ ĐANG QUÉT NỀN..."
    ScanButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    CopyButton.TextColor3       = Color3.fromRGB(80, 80, 80)
    ProgressFill.BackgroundColor3 = Color3.fromRGB(120, 0, 255)
    ProgressFill.Size           = UDim2.new(0, 0, 1, 0)
    task.spawn(performScan)
end)

CopyButton.MouseButton1Click:Connect(function()
    if isScanning or finalLog == "" then return end
    if setclipboard then
        setclipboard(finalLog)
        StatusLabel.Text = "📋 ĐÃ COPY " .. #finalLog .. " ký tự vào clipboard! Dán vào notepad để xem."
    elseif Clipboard then
        Clipboard.set(finalLog)
        StatusLabel.Text = "📋 ĐÃ COPY (Clipboard API)!"
    else
        StatusLabel.Text = "⚠️  Executor của bạn không hỗ trợ setclipboard."
    end
end)

DeepToggle.MouseButton1Click:Connect(function()
    deepScan = not deepScan
    DeepToggle.Text             = "🔍 Quét sâu (đệ quy): " .. (deepScan and "BẬT" or "TẮT")
    DeepToggle.BackgroundColor3 = deepScan and Color3.fromRGB(80, 0, 180) or Color3.fromRGB(60, 60, 80)
end)

DepthMinus.MouseButton1Click:Connect(function()
    if maxDepth > 1 then
        maxDepth = maxDepth - 1
        MaxDepthLabel.Text = "Độ sâu tối đa: " .. maxDepth
    end
end)

DepthPlus.MouseButton1Click:Connect(function()
    if maxDepth < 15 then
        maxDepth = maxDepth + 1
        MaxDepthLabel.Text = "Độ sâu tối đa: " .. maxDepth
    end
end)
