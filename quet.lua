-- ==========================================
-- V6 - SMOOTH ULTRA DEEP ANALYZER
-- Luôn quét sâu nhất, không lag, mượt 100%
-- Dùng coroutine + batch yield để game chạy bình thường
-- ==========================================

-- ====== DỌN UI CŨ NẾU CÒN ======
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("V6Analyzer")
    if old then old:Destroy() end
end)

-- ==========================================
-- CẤU HÌNH - chỉnh ở đây nếu muốn
-- ==========================================
local CFG = {
    MAX_DEPTH        = 12,    -- độ sâu đệ quy tối đa
    YIELD_EVERY      = 8,     -- yield sau mỗi N objects (càng nhỏ càng mượt, càng chậm)
    MAX_NORMAL_PER_FOLDER = 999, -- giới hạn object NORMAL mỗi folder (tránh log vô tận)
}

-- ==========================================
-- UI
-- ==========================================
local CoreGui   = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name          = "V6Analyzer"
ScreenGui.ResetOnSpawn  = false
ScreenGui.Parent        = CoreGui

local Main = Instance.new("Frame")
Main.Name               = "Main"
Main.Size               = UDim2.new(0, 300, 0, 210)
Main.Position           = UDim2.new(0.05, 0, 0.08, 0)
Main.BackgroundColor3   = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel    = 0
Main.Active             = true
Main.Draggable          = true
Main.Parent             = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color     = Color3.fromRGB(100, 0, 220)
Stroke.Thickness = 1.5

-- Title
local Title = Instance.new("TextLabel", Main)
Title.Size              = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3  = Color3.fromRGB(22, 0, 50)
Title.BorderSizePixel   = 0
Title.Font              = Enum.Font.Code
Title.Text              = "⚡ V6 SMOOTH DEEP ANALYZER"
Title.TextColor3        = Color3.fromRGB(180, 80, 255)
Title.TextSize          = 13
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- Stat bar
local StatBar = Instance.new("TextLabel", Main)
StatBar.Size              = UDim2.new(0.96, 0, 0, 20)
StatBar.Position          = UDim2.new(0.02, 0, 0, 34)
StatBar.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
StatBar.BorderSizePixel   = 0
StatBar.Font              = Enum.Font.Code
StatBar.Text              = "Remote: 0  Script: 0  Object: 0"
StatBar.TextColor3        = Color3.fromRGB(80, 255, 140)
StatBar.TextSize          = 11
Instance.new("UICorner", StatBar).CornerRadius = UDim.new(0, 4)

-- Progress bg
local PBG = Instance.new("Frame", Main)
PBG.Size             = UDim2.new(0.96, 0, 0, 12)
PBG.Position         = UDim2.new(0.02, 0, 0, 58)
PBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
PBG.BorderSizePixel  = 0
Instance.new("UICorner", PBG).CornerRadius = UDim.new(0, 6)

local PFill = Instance.new("Frame", PBG)
PFill.Size             = UDim2.new(0, 0, 1, 0)
PFill.BackgroundColor3 = Color3.fromRGB(120, 0, 255)
PFill.BorderSizePixel  = 0
Instance.new("UICorner", PFill).CornerRadius = UDim.new(0, 6)

-- Stage label (hiện bước đang làm)
local StageLabel = Instance.new("TextLabel", Main)
StageLabel.Size              = UDim2.new(0.96, 0, 0, 16)
StageLabel.Position          = UDim2.new(0.02, 0, 0, 74)
StageLabel.BackgroundTransparency = 1
StageLabel.Font              = Enum.Font.Code
StageLabel.Text              = "Chờ lệnh..."
StageLabel.TextColor3        = Color3.fromRGB(140, 140, 160)
StageLabel.TextSize          = 10
StageLabel.TextXAlignment    = Enum.TextXAlignment.Left

-- Status (multi-line)
local Status = Instance.new("TextLabel", Main)
Status.Size              = UDim2.new(0.96, 0, 0, 46)
Status.Position          = UDim2.new(0.02, 0, 0, 93)
Status.BackgroundTransparency = 1
Status.Font              = Enum.Font.Code
Status.Text              = "Nhấn SCAN để bắt đầu quét sâu tự động."
Status.TextColor3        = Color3.fromRGB(180, 180, 180)
Status.TextSize          = 11
Status.TextWrapped        = true
Status.TextXAlignment    = Enum.TextXAlignment.Left
Status.TextYAlignment    = Enum.TextYAlignment.Top

-- Scan button
local ScanBtn = Instance.new("TextButton", Main)
ScanBtn.Size             = UDim2.new(0.96, 0, 0, 30)
ScanBtn.Position         = UDim2.new(0.02, 0, 0, 143)
ScanBtn.BackgroundColor3 = Color3.fromRGB(70, 0, 160)
ScanBtn.BorderSizePixel  = 0
ScanBtn.Font             = Enum.Font.Code
ScanBtn.Text             = "▶  SCAN SÂU"
ScanBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
ScanBtn.TextSize         = 13
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

-- Copy button
local CopyBtn = Instance.new("TextButton", Main)
CopyBtn.Size             = UDim2.new(0.96, 0, 0, 26)
CopyBtn.Position         = UDim2.new(0.02, 0, 0, 177)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 70, 35)
CopyBtn.BorderSizePixel  = 0
CopyBtn.Font             = Enum.Font.Code
CopyBtn.Text             = "📋  COPY LOG"
CopyBtn.TextColor3       = Color3.fromRGB(80, 80, 80)
CopyBtn.TextSize         = 12
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- STATE
-- ==========================================
local finalLog   = ""
local isScanning = false
local objCounter = 0   -- dùng để yield theo batch

local stats = { remote = 0, script = 0, object = 0 }

-- ==========================================
-- HELPERS
-- ==========================================

local function safeGet(obj, prop)
    local ok, v = pcall(function() return obj[prop] end)
    return ok and tostring(v) or "?"
end

local function updateStatBar()
    StatBar.Text = string.format(
        "Remote: %d  Script: %d  Object: %d",
        stats.remote, stats.script, stats.object
    )
end

-- Tween progress mượt
local function setProgress(pct)
    TweenService:Create(PFill,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.new(pct, 0, 1, 0) }
    ):Play()
end

-- Yield thông minh: chỉ yield khi đến batch
local function smartYield()
    objCounter = objCounter + 1
    if objCounter % CFG.YIELD_EVERY == 0 then
        task.wait()   -- nhường frame cho game
    end
end

-- Xác định importance
local function getImp(obj)
    local ok, _ = pcall(function() return obj.ClassName end)
    if not ok then return "normal" end
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then return "critical" end
    if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then return "critical" end
    if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then return "high" end
    if obj:IsA("Model") then
        if obj:FindFirstChildWhichIsA("Humanoid") then return "high" end
    end
    if obj:IsA("BasePart") then
        if obj:FindFirstChildWhichIsA("ClickDetector")
        or obj:FindFirstChildWhichIsA("ProximityPrompt")
        or obj:FindFirstChild("TouchInterest") then
            return "high"
        end
    end
    if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue")
    or obj:IsA("NumberValue") or obj:IsA("ObjectValue") or obj:IsA("Vector3Value")
    or obj:IsA("Color3Value") or obj:IsA("CFrameValue") then return "medium" end
    if obj:IsA("Folder") then
        local ok2, ch = pcall(function() return #obj:GetChildren() end)
        if ok2 and ch > 8 then return "medium" end
    end
    if obj:IsA("ScreenGui") or obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then return "medium" end
    return "normal"
end

-- ==========================================
-- PHÂN TÍCH 1 OBJECT → trả về string
-- ==========================================
local function analyzeOne(obj, depth)
    smartYield()
    stats.object = stats.object + 1

    local pad = string.rep("  ", depth)
    local imp = getImp(obj)
    local name = safeGet(obj, "Name")
    local cls  = obj.ClassName
    local line = string.format("%s[%s] %s (%s)\n", pad, imp:upper(), name, cls)

    -- Remote
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        stats.remote = stats.remote + 1
        line = line .. pad .. "  Path: " .. obj:GetFullName() .. "\n"

    -- Script
    elseif obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        stats.script = stats.script + 1
        line = line .. pad .. "  Path: " .. obj:GetFullName() .. "\n"
        line = line .. pad .. "  Kind: " .. cls .. "\n"
        local ok2, src = pcall(function() return obj.Source end)
        if ok2 and src and #src > 0 then
            local fl = src:match("([^\n]*)")
            if fl and #fl > 0 then
                line = line .. pad .. "  Line1: " .. fl:sub(1,80) .. "\n"
            end
        end

    -- Bindable
    elseif obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
        line = line .. pad .. "  Path: " .. obj:GetFullName() .. "\n"

    -- Model
    elseif obj:IsA("Model") then
        local h = obj:FindFirstChildWhichIsA("Humanoid")
        if h then
            line = line .. pad .. string.format("  HP: %s / %s\n", safeGet(h,"Health"), safeGet(h,"MaxHealth"))
            line = line .. pad .. "  WalkSpeed: " .. safeGet(h,"WalkSpeed") .. "\n"
        end

    -- BasePart
    elseif obj:IsA("BasePart") then
        line = line .. pad .. "  Size:     " .. safeGet(obj,"Size") .. "\n"
        line = line .. pad .. "  Pos:      " .. safeGet(obj,"Position") .. "\n"
        line = line .. pad .. "  Anchored: " .. safeGet(obj,"Anchored") .. "\n"
        local cd = obj:FindFirstChildWhichIsA("ClickDetector")
        if cd then line = line .. pad .. "  [!] ClickDetector dist=" .. safeGet(cd,"MaxActivationDistance") .. "\n" end
        local pp = obj:FindFirstChildWhichIsA("ProximityPrompt")
        if pp then line = line .. pad .. '  [!] ProximityPrompt "' .. safeGet(pp,"ActionText") .. '"\n' end
        if obj:FindFirstChild("TouchInterest") then line = line .. pad .. "  [!] TouchInterest\n" end

    -- Values
    elseif obj:IsA("ValueBase") or obj:IsA("IntValue") or obj:IsA("StringValue")
        or obj:IsA("BoolValue") or obj:IsA("NumberValue") or obj:IsA("ObjectValue")
        or obj:IsA("Vector3Value") or obj:IsA("Color3Value") or obj:IsA("CFrameValue") then
        local ok2, val = pcall(function() return obj.Value end)
        line = line .. pad .. "  Value: " .. (ok2 and tostring(val) or "?") .. "\n"

    -- Sound
    elseif obj:IsA("Sound") then
        line = line .. pad .. "  SoundId: " .. safeGet(obj,"SoundId") .. "\n"
        line = line .. pad .. "  Playing: " .. safeGet(obj,"Playing") .. "\n"

    -- Tool
    elseif obj:IsA("Tool") then
        line = line .. pad .. "  ToolTip: " .. safeGet(obj,"ToolTip") .. "\n"

    -- ScreenGui
    elseif obj:IsA("ScreenGui") then
        line = line .. pad .. "  Enabled: " .. safeGet(obj,"Enabled") .. "\n"

    -- Animation
    elseif obj:IsA("Animation") then
        line = line .. pad .. "  AnimId: " .. safeGet(obj,"AnimationId") .. "\n"

    -- Team
    elseif obj:IsA("Team") then
        line = line .. pad .. "  Color: " .. safeGet(obj,"TeamColor") .. "\n"
    end

    return line
end

-- ==========================================
-- QUÉT ĐỆ QUY MƯỢT
-- ==========================================
local function scanNode(obj, depth)
    if depth > CFG.MAX_DEPTH then return "" end

    local result = ""
    local ok, _ = pcall(function()
        result = analyzeOne(obj, depth)
    end)
    if not ok then return "" end

    -- Lấy children
    local ok2, children = pcall(function() return obj:GetChildren() end)
    if not ok2 or #children == 0 then return result end

    -- Nhóm theo importance
    local groups = { critical={}, high={}, medium={}, normal={} }
    for _, c in ipairs(children) do
        local imp = getImp(c)
        table.insert(groups[imp], c)
    end

    local normalCount = 0
    local function processGroup(list)
        for _, c in ipairs(list) do
            -- giới hạn normal
            if getImp(c) == "normal" then
                normalCount = normalCount + 1
                if normalCount > CFG.MAX_NORMAL_PER_FOLDER then
                    result = result .. string.rep("  ", depth+1)
                        .. "... (bỏ qua " .. (#list - normalCount + 1) .. " normal objects)\n"
                    return
                end
            end
            result = result .. scanNode(c, depth + 1)
        end
    end

    processGroup(groups.critical)
    processGroup(groups.high)
    processGroup(groups.medium)
    processGroup(groups.normal)

    return result
end

-- ==========================================
-- SCAN CHÍNH
-- ==========================================
local SERVICES = {
    "ReplicatedStorage", "ReplicatedFirst",
    "StarterGui", "StarterPack",
    "Lighting", "SoundService",
    "Chat", "Teams", "TextChatService",
}

local function doScan()
    stats = { remote=0, script=0, object=0 }
    objCounter = 0
    finalLog = ""

    local player = game.Players.LocalPlayer

    -- Header
    finalLog = "==============================================\n"
    finalLog = finalLog .. "  V6 SMOOTH DEEP ANALYZER\n"
    finalLog = finalLog .. "==============================================\n"
    finalLog = finalLog .. "Game    : " .. safeGet(game,"Name") .. "\n"
    finalLog = finalLog .. "PlaceId : " .. safeGet(game,"PlaceId") .. "\n"
    finalLog = finalLog .. "Player  : " .. safeGet(player,"Name") .. "\n"
    finalLog = finalLog .. "Time    : " .. os.date("%d/%m/%Y %H:%M:%S") .. "\n"
    finalLog = finalLog .. "MaxDepth: " .. CFG.MAX_DEPTH .. "\n"
    finalLog = finalLog .. "==============================================\n\n"

    -- ============================================================
    -- [1] REMOTES (GetDescendants cả game, nhanh + đầy đủ nhất)
    -- ============================================================
    StageLabel.Text = "[1/5] Quét tất cả Remotes toàn game..."
    setProgress(0.05)
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[1] ALL REMOTES & BINDABLES\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    local ok1, desc = pcall(function() return game:GetDescendants() end)
    if ok1 then
        local batch = 0
        for _, obj in ipairs(desc) do
            local isRemote = false
            pcall(function()
                isRemote = obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                        or obj:IsA("BindableEvent") or obj:IsA("BindableFunction")
            end)
            if isRemote then
                local path = obj:GetFullName()
                if not (path:find("RobloxReplicatedStorage") or
                        path:find("DefaultChatSystemChatEvents") or
                        path:find("CoreGui")) then
                    finalLog = finalLog .. analyzeOne(obj, 0)
                end
            end
            batch = batch + 1
            if batch % CFG.YIELD_EVERY == 0 then task.wait() end
            updateStatBar()
        end
    end
    finalLog = finalLog .. string.format("\n→ Tổng: %d remotes\n\n", stats.remote)
    setProgress(0.20)

    -- ============================================================
    -- [2] SCRIPTS
    -- ============================================================
    StageLabel.Text = "[2/5] Quét tất cả Scripts..."
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[2] ALL SCRIPTS & MODULES\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    local ok2, desc2 = pcall(function() return game:GetDescendants() end)
    if ok2 then
        local batch = 0
        for _, obj in ipairs(desc2) do
            local isScript = false
            pcall(function()
                isScript = obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
            end)
            if isScript then
                finalLog = finalLog .. analyzeOne(obj, 0)
            end
            batch = batch + 1
            if batch % CFG.YIELD_EVERY == 0 then task.wait() end
            updateStatBar()
        end
    end
    finalLog = finalLog .. string.format("\n→ Tổng: %d scripts\n\n", stats.script)
    setProgress(0.40)

    -- ============================================================
    -- [3] WORKSPACE đệ quy sâu
    -- ============================================================
    StageLabel.Text = "[3/5] Quét Workspace đệ quy (depth=" .. CFG.MAX_DEPTH .. ")..."
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[3] WORKSPACE (đệ quy sâu)\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    local ok3, wsChildren = pcall(function() return game.Workspace:GetChildren() end)
    if ok3 then
        -- sắp xếp: nhiều con lên trước
        table.sort(wsChildren, function(a,b)
            local ca, cb = 0, 0
            pcall(function() ca = #a:GetChildren() end)
            pcall(function() cb = #b:GetChildren() end)
            return ca > cb
        end)
        for _, child in ipairs(wsChildren) do
            finalLog = finalLog .. scanNode(child, 0)
            updateStatBar()
        end
    end
    finalLog = finalLog .. "\n"
    setProgress(0.60)

    -- ============================================================
    -- [4] PLAYER (GUI, Backpack, Character, Scripts)
    -- ============================================================
    StageLabel.Text = "[4/5] Quét Player..."
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[4] LOCAL PLAYER\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    local playerContainers = {
        { name="PlayerGui",     getter=function() return player:WaitForChild("PlayerGui",3) end },
        { name="Backpack",      getter=function() return player:WaitForChild("Backpack",3) end },
        { name="PlayerScripts", getter=function() return player:WaitForChild("PlayerScripts",3) end },
        { name="Character",     getter=function() return player.Character end },
    }
    for _, pc in ipairs(playerContainers) do
        local okp, cont = pcall(pc.getter)
        if okp and cont then
            finalLog = finalLog .. "\n  [" .. pc.name .. "]\n"
            local okc, ch = pcall(function() return cont:GetChildren() end)
            if okc then
                for _, v in ipairs(ch) do
                    finalLog = finalLog .. scanNode(v, 2)
                    updateStatBar()
                end
            end
        end
    end
    finalLog = finalLog .. "\n"
    setProgress(0.80)

    -- ============================================================
    -- [5] SERVICES
    -- ============================================================
    StageLabel.Text = "[5/5] Quét Services..."
    task.wait()

    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "[5] SERVICES\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"

    -- StarterPlayer sub-folders
    local sp = game:GetService("StarterPlayer")
    for _, sub in ipairs({"StarterPlayerScripts","StarterCharacterScripts"}) do
        local oksp, child = pcall(function() return sp:FindFirstChild(sub) end)
        if oksp and child then
            finalLog = finalLog .. "\n  [StarterPlayer." .. sub .. "]\n"
            local okc, ch = pcall(function() return child:GetChildren() end)
            if okc then
                for _, v in ipairs(ch) do finalLog = finalLog .. scanNode(v, 2) end
            end
        end
    end

    for _, svcName in ipairs(SERVICES) do
        local oks, svc = pcall(function() return game:GetService(svcName) end)
        if oks and svc then
            local okc, ch = pcall(function() return svc:GetChildren() end)
            if okc and #ch > 0 then
                finalLog = finalLog .. string.format("\n  [%s] (%d children)\n", svcName, #ch)
                for _, v in ipairs(ch) do
                    finalLog = finalLog .. scanNode(v, 2)
                    updateStatBar()
                end
            end
        end
    end
    finalLog = finalLog .. "\n"
    setProgress(0.97)
    task.wait()

    -- ============================================================
    -- TỔNG KẾT
    -- ============================================================
    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "TỔNG KẾT\n"
    finalLog = finalLog .. "══════════════════════════════════════\n"
    finalLog = finalLog .. "  Objects  : " .. stats.object .. "\n"
    finalLog = finalLog .. "  Remotes  : " .. stats.remote .. "\n"
    finalLog = finalLog .. "  Scripts  : " .. stats.script .. "\n"
    finalLog = finalLog .. "  Log size : " .. #finalLog .. " chars\n"
    finalLog = finalLog .. "==============================================\n"
    finalLog = finalLog .. "  END - V6 SMOOTH DEEP ANALYZER\n"
    finalLog = finalLog .. "==============================================\n"

    -- Hoàn tất UI
    setProgress(1.0)
    PFill.BackgroundColor3  = Color3.fromRGB(0, 210, 100)
    StageLabel.Text         = "✅ XONG! " .. stats.remote .. " remotes, " .. stats.script .. " scripts, " .. stats.object .. " objects"
    Status.Text             = "Nhấn COPY LOG để lấy kết quả.\nLog: " .. math.floor(#finalLog/1024) .. " KB"
    ScanBtn.Text            = "🔄  QUÉT LẠI"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(70, 0, 160)
    CopyBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
    isScanning              = false
    updateStatBar()
end

-- ==========================================
-- EVENTS
-- ==========================================
ScanBtn.MouseButton1Click:Connect(function()
    if isScanning then return end
    isScanning = true
    finalLog = ""
    stats = { remote=0, script=0, object=0 }
    objCounter = 0
    ScanBtn.Text             = "⏳ ĐANG QUÉT..."
    ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    CopyBtn.TextColor3       = Color3.fromRGB(60, 60, 60)
    PFill.BackgroundColor3   = Color3.fromRGB(120, 0, 255)
    Status.Text              = "Đang khởi động scan nền...\nGame vẫn chạy bình thường."
    updateStatBar()
    task.spawn(doScan)  -- chạy hoàn toàn nền, không block game
end)

CopyBtn.MouseButton1Click:Connect(function()
    if isScanning or finalLog == "" then return end
    local copied = false
    if setclipboard then pcall(function() setclipboard(finalLog) copied = true end) end
    if not copied and Clipboard then pcall(function() Clipboard.set(finalLog) copied = true end) end
    if copied then
        Status.Text = "📋 Đã copy " .. math.floor(#finalLog/1024) .. " KB!\nDán vào Notepad / VS Code để đọc."
    else
        Status.Text = "⚠️ Executor không hỗ trợ clipboard.\nThử executor khác (Synapse, KRNL...)."
    end
end)
