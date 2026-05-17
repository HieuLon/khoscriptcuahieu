--[[
    NAME: HiuCTE MENU - V8 MEMORY OVERLORD
    DEVELOPER: Senior Roblox Exploit Developer
    PLATFORM: DeltaX / PC / MOBILE
    FEATURES: Auto Save/Load Configs, Loop Mid, Multi-Clicker, Noclip, Inf Jump, Trigger Farm.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // CONFIGURATION & FLAGS // --
local Config = {
    Safe = nil,
    PreSafe = nil,
    Farm = nil,
    
    AutoFarm = false,
    LoopFarm = false,
    LoopMid = false,
    FastPick = false, 
    NoMidTween = false,
    NoMidTele = false,
    IsBusy = false,
    TweenSpeed = 1200,
    WaitTime = 0.8,
    
    SpiritMode = false,
    OriginalBodyCFrame = nil,
    GhostSpeed = 2,
    
    LoopStats = false,
    WalkSpeed = 16,
    JumpPower = 50,
    MoneyFarm = false,
    MoneyLoop = false,

    ClickCPS = 10,
    Noclip = false,
    InfiniteJump = false
}

local MoneyPoints = {}
local ClickCircles = {}
local GlobalClicking = false
local visSafe, visPre, visFarm, visBodyDummy
local StatusLabel
local PointLabel 
local SaveFileName = "HiuCTE_Configs/Game_" .. tostring(game.PlaceId) .. ".json"

-- // CORE UTILITIES // --
local function GetChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function GetRoot() return GetChar():WaitForChild("HumanoidRootPart") end
local function GetHum() return GetChar():WaitForChild("Humanoid") end

local function Notify(text)
    if StatusLabel then StatusLabel.Text = "Status: " .. text end
    print("[HiuCTE] " .. text)
end

-- // VISUAL ESP SYSTEM // --
local ESPFolder = workspace:FindFirstChild("HiuCTE_ESP") or Instance.new("Folder", workspace)
ESPFolder.Name = "HiuCTE_ESP"

local function UpdateVisuals()
    if visSafe then visSafe:Destroy() visSafe = nil end
    if visPre then visPre:Destroy() visPre = nil end
    if visFarm then visFarm:Destroy() visFarm = nil end

    local function createVis(name, color, cf)
        local p = Instance.new("Part", ESPFolder)
        p.Name = name; p.Anchored = true; p.CanCollide = false
        p.Size = Vector3.new(1, 15, 1); p.Transparency = 0.6
        p.Material = Enum.Material.Neon; p.Color = color
        p.CFrame = cf; p.CastShadow = false
        
        local bg = Instance.new("BillboardGui", p)
        bg.Size = UDim2.new(0, 150, 0, 40)
        bg.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bg)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.Text = name; txt.TextColor3 = color
        txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBlack; txt.TextScaled = true
        return p
    end

    if Config.Safe then visSafe = createVis("SAFE ZONE", Color3.fromRGB(0, 255, 255), Config.Safe) end
    if Config.PreSafe then visPre = createVis("PRE-SAFE (MID)", Color3.fromRGB(255, 255, 0), Config.PreSafe) end
    if Config.Farm then visFarm = createVis("FARM SPOT", Color3.fromRGB(255, 50, 50), Config.Farm) end
end

-- // FILE SYSTEM: SAVE & LOAD // --
local function SerializeCFrame(cf)
    if not cf then return nil end
    return {cf:GetComponents()}
end

local function DeserializeCFrame(arr)
    if not arr then return nil end
    return CFrame.new(unpack(arr))
end

local function SaveConfig()
    local data = {
        Safe = SerializeCFrame(Config.Safe),
        PreSafe = SerializeCFrame(Config.PreSafe),
        Farm = SerializeCFrame(Config.Farm),
        MoneyPoints = {},
        ClickCPS = Config.ClickCPS,
        WalkSpeed = Config.WalkSpeed,
        JumpPower = Config.JumpPower,
        LoopMid = Config.LoopMid,
        LoopFarm = Config.LoopFarm
    }
    for i, cf in ipairs(MoneyPoints) do
        data.MoneyPoints[i] = SerializeCFrame(cf)
    end
    
    if not isfolder("HiuCTE_Configs") then makefolder("HiuCTE_Configs") end
    writefile(SaveFileName, HttpService:JSONEncode(data))
    Notify("💾 Đã lưu cấu hình Game này!")
end

local function LoadConfig()
    if isfile(SaveFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(SaveFileName)) end)
        if success and type(decoded) == "table" then
            Config.Safe = DeserializeCFrame(decoded.Safe)
            Config.PreSafe = DeserializeCFrame(decoded.PreSafe)
            Config.Farm = DeserializeCFrame(decoded.Farm)
            
            MoneyPoints = {}
            if decoded.MoneyPoints then
                for _, arr in ipairs(decoded.MoneyPoints) do
                    table.insert(MoneyPoints, DeserializeCFrame(arr))
                end
            end
            
            if decoded.ClickCPS then Config.ClickCPS = decoded.ClickCPS end
            if decoded.WalkSpeed then Config.WalkSpeed = decoded.WalkSpeed end
            if decoded.JumpPower then Config.JumpPower = decoded.JumpPower end
            if decoded.LoopMid ~= nil then Config.LoopMid = decoded.LoopMid end
            if decoded.LoopFarm ~= nil then Config.LoopFarm = decoded.LoopFarm end

            UpdateVisuals()
            if PointLabel then PointLabel.Text = "Saved Pads: " .. #MoneyPoints end
            Notify("📂 Đã tải cấu hình cũ thành công!")
            return true
        end
    end
    return false
end

-- // ANTI-LAG // --
local function EnableAntiLag()
    Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9
    if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere:Destroy() end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.CastShadow = false
        elseif v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
    end
    Notify("Anti-Lag Kích Hoạt!")
end

-- // SPIRIT MODE // --
local function ReturnToBody()
    if Config.SpiritMode and Config.OriginalBodyCFrame then
        local char = GetChar(); local root = GetRoot()
        Config.SpiritMode = false; root.Anchored = false; root.CFrame = Config.OriginalBodyCFrame
        if visBodyDummy then visBodyDummy:Destroy() visBodyDummy = nil end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 0; if v:IsA("BasePart") then v.CanCollide = true end end
        end
        Notify("Đã nhập xác!")
    end
end

local function ToggleSpiritMode()
    if Config.Safe and Config.PreSafe and Config.Farm then Notify("Xóa điểm để set lại.") return end
    if Config.SpiritMode then ReturnToBody() return end

    local char = GetChar(); local root = GetRoot()
    if root then
        Config.OriginalBodyCFrame = root.CFrame; Config.SpiritMode = true
        visBodyDummy = Instance.new("Part", workspace); visBodyDummy.Name = "Dummy_Body"
        visBodyDummy.Anchored = true; visBodyDummy.CanCollide = false
        visBodyDummy.Size = Vector3.new(4, 5, 4); visBodyDummy.Transparency = 0.4
        visBodyDummy.Material = Enum.Material.ForceField; visBodyDummy.Color = Color3.fromRGB(150, 150, 150)
        visBodyDummy.CFrame = root.CFrame
        for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 0.8 end end
        Notify("Đã xuất hồn!")
    end
end

-- // TRIGGER-BASED AUTO FARM // --
local function ExecuteFarmCycle()
    if Config.IsBusy or not Config.Farm or Config.SpiritMode then return end 
    Config.IsBusy = true; local root = GetRoot(); local hum = GetHum()
    
    if hum then hum.PlatformStand = true end
    root.CanCollide = false; root.Anchored = false
    
    if Config.LoopMid then
        if Config.PreSafe then root.CFrame = Config.PreSafe; task.wait(1) else task.wait(1) end
        if hum then hum.PlatformStand = false end
        root.CanCollide = true; root.CFrame = Config.Farm
        Config.IsBusy = false
        return
    end

    if not Config.Safe then Config.IsBusy = false return end
    if Config.NoMidTele then root.CFrame = Config.Safe; task.wait(0.2)
    elseif Config.NoMidTween then
        local tween = TweenService:Create(root, TweenInfo.new((root.Position - Config.Safe.Position).Magnitude / Config.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = Config.Safe})
        tween:Play(); tween.Completed:Wait()
    else
        if Config.PreSafe then root.CFrame = Config.PreSafe; task.wait(0.15) end
        local tween = TweenService:Create(root, TweenInfo.new((root.Position - Config.Safe.Position).Magnitude / Config.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = Config.Safe})
        tween:Play(); tween.Completed:Wait()
    end

    task.wait(Config.WaitTime)
    if hum then hum.PlatformStand = false end
    root.CanCollide = true
    if Config.LoopFarm then root.CFrame = Config.Farm end
    Config.IsBusy = false
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer and Config.AutoFarm and not Config.SpiritMode then ExecuteFarmCycle() end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Config.FastPick then for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v.HoldDuration = 0 end end end
    end
end)

-- // AUTO CLICKER LOGIC // --
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "HiuCTE_V8"; ScreenGui.Parent = game:GetService("CoreGui"); ScreenGui.ResetOnSpawn = false

local function ToggleAllCircles(state)
    GlobalClicking = state
    for _, circle in pairs(ClickCircles) do if circle and circle:IsA("TextButton") then circle.BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0) end end
    if state then
        task.spawn(function()
            while GlobalClicking do
                for _, circle in pairs(ClickCircles) do
                    if not GlobalClicking then break end
                    if circle and circle.Parent then
                        local cx = circle.AbsolutePosition.X + (circle.AbsoluteSize.X / 2); local cy = circle.AbsolutePosition.Y + (circle.AbsoluteSize.Y / 2)
                        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1); VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                    end
                end
                task.wait(1 / Config.ClickCPS)
            end
        end)
    end
end

local function CreateClickCircle()
    local Circle = Instance.new("TextButton", ScreenGui)
    Circle.Size = UDim2.new(0, 50, 0, 50); Circle.Position = UDim2.new(0.5, -25, 0.5, -25)
    Circle.BackgroundColor3 = GlobalClicking and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    Circle.Text = "🎯"; Circle.TextColor3 = Color3.new(1,1,1); Circle.Font = Enum.Font.GothamBold; Circle.ZIndex = 10
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    table.insert(ClickCircles, Circle)
    
    local dragging, dragStart, startPos = false, nil, nil; local hasMoved = false
    Circle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; hasMoved = false; dragStart = input.Position; startPos = Circle.Position end
    end)
    Circle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if dragging then dragging = false; if not hasMoved then ToggleAllCircles(not GlobalClicking) end end end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart; if delta.Magnitude > 5 then hasMoved = true end
            Circle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- // LOOPS SYSTEMS // --
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid")
    if Config.SpiritMode and root and hum then
        root.Anchored = true; root.CanCollide = false
        local moveDir = hum.MoveDirection; if moveDir.Magnitude > 0 then root.CFrame = root.CFrame + (Camera.CFrame.LookVector * (moveDir.Magnitude * Config.GhostSpeed)) end
    elseif not Config.SpiritMode and Config.LoopStats and hum then
        hum.WalkSpeed = Config.WalkSpeed; hum.JumpPower = Config.JumpPower
    end
    if Config.Noclip and not Config.SpiritMode then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
    end
end)
UserInputService.JumpRequest:Connect(function() if Config.InfiniteJump then local hum = GetHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

-- // MONEY FARM TOOL LOGIC // --
local function GiveSetPointTool()
    local bp = LocalPlayer:FindFirstChild("Backpack"); if not bp then return end
    local tool = bp:FindFirstChild("[HiuCTE] Set Point")
    if not tool then
        tool = Instance.new("Tool", bp); tool.Name = "[HiuCTE] Set Point"; tool.RequiresHandle = false
        tool.Activated:Connect(function() local root = GetRoot(); if root then table.insert(MoneyPoints, root.CFrame); if PointLabel then PointLabel.Text = "Saved Pads: " .. #MoneyPoints end; Notify("Đã lưu Pad Point #" .. #MoneyPoints) end end)
        Notify("Đã nhận Tool! Cầm và bấm vào màn hình.")
    end
end

-- // MAIN FRAME UI // --
local MiniButton = Instance.new("TextButton", ScreenGui)
MiniButton.Size = UDim2.new(0, 50, 0, 50); MiniButton.Position = UDim2.new(0, 20, 0.5, -25); MiniButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40); MiniButton.Text = "Hiu"; MiniButton.TextColor3 = Color3.new(1,1,1); MiniButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(0, 25)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 350); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -175); MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40); TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
local Title = Instance.new("TextLabel", TopBar); Title.Text = " HiuCTE V8 | AUTO SAVE"; Title.Size = UDim2.new(1, 0, 1, 0); Title.BackgroundTransparency = 1; Title.TextColor3 = Color3.new(1, 1, 1); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Font = Enum.Font.GothamBold
StatusLabel = Instance.new("TextLabel", TopBar); StatusLabel.Size = UDim2.new(0, 200, 1, 0); StatusLabel.Position = UDim2.new(1, -210, 0, 0); StatusLabel.BackgroundTransparency = 1; StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255); StatusLabel.Text = "Status: Idle"; StatusLabel.TextXAlignment = Enum.TextXAlignment.Right; StatusLabel.Font = Enum.Font.Gotham

local TabContainer = Instance.new("ScrollingFrame", MainFrame)
TabContainer.Size = UDim2.new(0, 120, 1, -40); TabContainer.Position = UDim2.new(0, 0, 0, 40); TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TabContainer.ScrollBarThickness = 2; TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", TabContainer)

local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, -120, 1, -40); PageContainer.Position = UDim2.new(0, 120, 0, 40); PageContainer.BackgroundTransparency = 1

local Pages = {}
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", PageContainer)
    Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.AutomaticCanvasSize = Enum.AutomaticSize.Y; Page.ScrollBarThickness = 3; Pages[name] = Page
    local TabBtn = Instance.new("TextButton", TabContainer); TabBtn.Size = UDim2.new(1, 0, 0, 40); TabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); TabBtn.Text = name; TabBtn.TextColor3 = Color3.new(1,1,1); TabBtn.Font = Enum.Font.Gotham
    TabBtn.Activated:Connect(function() for _, p in pairs(Pages) do p.Visible = false end Page.Visible = true end)
    local UIList = Instance.new("UIListLayout", Page); UIList.Padding = UDim.new(0, 5); UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center; Instance.new("UIPadding", Page).PaddingTop = UDim.new(0, 5)
    return Page
end

-- // UI HELPERS // --
local function CreateButton(txt, parent, callback, color)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(0.95, 0, 0, 35); btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50); btn.Text = txt; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Gotham
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6); btn.Activated:Connect(function() callback(btn) end); return btn
end
local function CreateToggle(txt, parent, flagKey, syncCallback)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(0.95, 0, 0, 35); btn.BackgroundColor3 = Config[flagKey] and Color3.fromRGB(10, 60, 10) or Color3.fromRGB(40, 10, 10); btn.Text = txt .. (Config[flagKey] and ": ON" or ": OFF"); btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Gotham
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Activated:Connect(function() Config[flagKey] = not Config[flagKey]; if syncCallback then syncCallback(btn) else btn.Text = txt .. (Config[flagKey] and ": ON" or ": OFF"); btn.BackgroundColor3 = Config[flagKey] and Color3.fromRGB(10, 60, 10) or Color3.fromRGB(40, 10, 10) end end)
    return btn
end

-- // BUILD PAGES // --
local SetupPage = CreatePage("1. Map & Config")
local FarmPage = CreatePage("2. Auto Farm")
local MoneyPage = CreatePage("3. Money Tele")
local ClickPage = CreatePage("4. Auto Click") 
local ExtraPage = CreatePage("5. Extras")    
SetupPage.Visible = true

-- [TAB 1: SETUP]
CreateButton("💾 LƯU CẤU HÌNH GAME NÀY", SetupPage, SaveConfig, Color3.fromRGB(20, 80, 20))
CreateButton("📂 TẢI LẠI CẤU HÌNH", SetupPage, LoadConfig, Color3.fromRGB(20, 40, 80))
CreateButton("⚡ Bật Anti-Lag (Tăng FPS)", SetupPage, EnableAntiLag, Color3.fromRGB(120, 80, 20))
CreateButton("👻 XUẤT HỒN (BAY ĐẶT ĐIỂM)", SetupPage, ToggleSpiritMode, Color3.fromRGB(80, 40, 80))
CreateButton("🔵 Set SafeZone (+3 Y)", SetupPage, function() if GetRoot() then Config.Safe = GetRoot().CFrame + Vector3.new(0, 3, 0); UpdateVisuals(); if Config.PreSafe and Config.Farm then ReturnToBody() end end end)
CreateButton("🟡 Set Pre-Safe (+3 Y)", SetupPage, function() if GetRoot() then Config.PreSafe = GetRoot().CFrame + Vector3.new(0, 3, 0); UpdateVisuals(); if Config.Safe and Config.Farm then ReturnToBody() end end end)
CreateButton("🔴 Set FarmSpot (+3 Y)", SetupPage, function() if GetRoot() then Config.Farm = GetRoot().CFrame + Vector3.new(0, 3, 0); UpdateVisuals(); if Config.Safe and Config.PreSafe then ReturnToBody() end end end)
CreateButton("❌ Xóa Tất Cả Điểm", SetupPage, function() Config.Safe = nil; Config.PreSafe = nil; Config.Farm = nil; UpdateVisuals() end, Color3.fromRGB(60, 20, 20))

-- [TAB 2: FARM]
CreateToggle("🤖 Bật Auto Farm (Trigger)", FarmPage, "AutoFarm")
local BtnLoopFarm, BtnLoopMid
local function UpdateLoopRadio()
    BtnLoopFarm.Text = "🔁 Loop Farm: " .. (Config.LoopFarm and "ON" or "OFF"); BtnLoopFarm.BackgroundColor3 = Config.LoopFarm and Color3.fromRGB(10, 60, 10) or Color3.fromRGB(40, 10, 10)
    BtnLoopMid.Text = "🔁 Loop Mid (Chờ 1s): " .. (Config.LoopMid and "ON" or "OFF"); BtnLoopMid.BackgroundColor3 = Config.LoopMid and Color3.fromRGB(10, 60, 10) or Color3.fromRGB(40, 10, 10)
end
BtnLoopFarm = CreateToggle("🔁 Loop Farm", FarmPage, "LoopFarm", function() if Config.LoopFarm then Config.LoopMid = false end; UpdateLoopRadio() end)
BtnLoopMid = CreateToggle("🔁 Loop Mid (Chờ 1s)", FarmPage, "LoopMid", function() if Config.LoopMid then Config.LoopFarm = false end; UpdateLoopRadio() end)
CreateToggle("⚡ Nhặt Nhanh (Fast Pick)", FarmPage, "FastPick")
local BtnTween, BtnTele
local function UpdateNoMidRadio()
    BtnTween.Text = "No Mid (Tween): " .. (Config.NoMidTween and "ON" or "OFF"); BtnTween.BackgroundColor3 = Config.NoMidTween and Color3.fromRGB(10, 60, 10) or Color3.fromRGB(40, 10, 10)
    BtnTele.Text = "No Mid (Tele): " .. (Config.NoMidTele and "ON" or "OFF"); BtnTele.BackgroundColor3 = Config.NoMidTele and Color3.fromRGB(10, 60, 10) or Color3.fromRGB(40, 10, 10)
end
BtnTween = CreateToggle("No Mid (Tween)", FarmPage, "NoMidTween", function() if Config.NoMidTween then Config.NoMidTele = false end; UpdateNoMidRadio() end)
BtnTele = CreateToggle("No Mid (Tele)", FarmPage, "NoMidTele", function() if Config.NoMidTele then Config.NoMidTween = false end; UpdateNoMidRadio() end)
CreateButton("✈️ Teleport Đến SafeZone", FarmPage, function() if Config.Safe then GetRoot().CFrame = Config.Safe else Notify("Chưa set SafeZone!") end end, Color3.fromRGB(20, 60, 80))
CreateButton("✈️ Teleport Đến FarmSpot", FarmPage, function() if Config.Farm then GetRoot().CFrame = Config.Farm else Notify("Chưa set FarmSpot!") end end, Color3.fromRGB(80, 40, 20))

-- [TAB 3: MONEY]
CreateButton("🛠 Nhận Tool Đặt Điểm", MoneyPage, GiveSetPointTool, Color3.fromRGB(100, 60, 20))
PointLabel = Instance.new("TextLabel", MoneyPage); PointLabel.Size = UDim2.new(0.95, 0, 0, 25); PointLabel.Text = "Saved Pads: 0"; PointLabel.TextColor3 = Color3.fromRGB(0, 255, 0); PointLabel.BackgroundTransparency = 1; PointLabel.Font = Enum.Font.GothamBold
CreateButton("[-] Xóa Điểm Gần Nhất", MoneyPage, function() table.remove(MoneyPoints); PointLabel.Text = "Saved Pads: " .. #MoneyPoints end)
CreateButton("🗑 Xóa Tất Cả Điểm", MoneyPage, function() MoneyPoints = {}; PointLabel.Text = "Saved Pads: 0" end)
CreateToggle("🔁 Loop Money Farm", MoneyPage, "MoneyLoop")
local StartMoneyBtn = Instance.new("TextButton", MoneyPage); StartMoneyBtn.Size = UDim2.new(0.95, 0, 0, 35); StartMoneyBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 10); StartMoneyBtn.Text = "▶ Bắt đầu Farm Tiền: OFF"; StartMoneyBtn.TextColor3 = Color3.new(1,1,1); StartMoneyBtn.Font = Enum.Font.Gotham; Instance.new("UICorner", StartMoneyBtn).CornerRadius = UDim.new(0, 6)
StartMoneyBtn.Activated:Connect(function()
    Config.MoneyFarm = not Config.MoneyFarm; StartMoneyBtn.Text = "▶ Bắt đầu Farm Tiền: " .. (Config.MoneyFarm and "ON" or "OFF"); StartMoneyBtn.BackgroundColor3 = Config.MoneyFarm and Color3.fromRGB(10, 60, 10) or Color3.fromRGB(40, 10, 10)
    if Config.MoneyFarm then
        if #MoneyPoints == 0 then Config.MoneyFarm = false; StartMoneyBtn.Text = "▶ Bắt đầu Farm Tiền: OFF"; StartMoneyBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 10); Notify("Chưa có Pad Point nào!"); return end
        task.spawn(function()
            local originalPos = GetRoot().CFrame
            while Config.MoneyFarm do
                for _, cf in pairs(MoneyPoints) do if not Config.MoneyFarm then break end GetRoot().CFrame = cf; task.wait(0.5) end
                if not Config.MoneyLoop then break end; task.wait(0.5)
            end
            if GetRoot() then GetRoot().CFrame = originalPos end
            Config.MoneyFarm = false; StartMoneyBtn.Text = "▶ Bắt đầu Farm Tiền: OFF"; StartMoneyBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
        end)
    end
end)

-- [TAB 4: CLICKER]
CreateButton("➕ TẠO VÒNG CLICK MỚI (🔴 ĐỎ)", ClickPage, function() CreateClickCircle(); Notify("Đã tạo 1 vòng Clicker!") end, Color3.fromRGB(180, 50, 50))
local CPSSettings = {1, 5, 10, 20, 50, 100}; local CIndex = 3
local CpsBtn = CreateButton("⚙️ Tốc độ Click: 10 lần/s", ClickPage, function(btn) CIndex = CIndex % #CPSSettings + 1; Config.ClickCPS = CPSSettings[CIndex]; btn.Text = "⚙️ Tốc độ Click: " .. Config.ClickCPS .. " lần/s" end, Color3.fromRGB(60, 60, 60))
CreateButton("🗑 Xóa tất cả vòng Click", ClickPage, function() ToggleAllCircles(false); for _, circle in pairs(ClickCircles) do if circle then circle:Destroy() end end ClickCircles = {}; Notify("Đã dọn dẹp!") end, Color3.fromRGB(80, 20, 20))

-- [TAB 5: EXTRAS]
CreateToggle("👻 Bật Xuyên Tường (Noclip)", ExtraPage, "Noclip")
CreateToggle("🦘 Nhảy Vô Hạn (Infinite Jump)", ExtraPage, "InfiniteJump")
CreateToggle("🔥 Loop Stats (Khóa Tốc/Nhảy)", ExtraPage, "LoopStats")
local Speeds = {16, 50, 100, 200}; local SIndex = 1
local SpeedBtn = CreateButton("WalkSpeed: 16", ExtraPage, function(btn) SIndex = SIndex % #Speeds + 1; Config.WalkSpeed = Speeds[SIndex]; btn.Text = "WalkSpeed: " .. Config.WalkSpeed end)
local Jumps = {50, 100, 200, 300}; local JIndex = 1
local JumpBtn = CreateButton("JumpPower: 50", ExtraPage, function(btn) JIndex = JIndex % #Jumps + 1; Config.JumpPower = Jumps[JIndex]; btn.Text = "JumpPower: " .. Config.JumpPower end)

-- // UPDATE UI STATS AFTER LOAD // --
local function SyncUIAfterLoad()
    CpsBtn.Text = "⚙️ Tốc độ Click: " .. Config.ClickCPS .. " lần/s"
    SpeedBtn.Text = "WalkSpeed: " .. Config.WalkSpeed
    JumpBtn.Text = "JumpPower: " .. Config.JumpPower
    UpdateLoopRadio(); UpdateNoMidRadio()
end

-- // AUTO LOAD ON INJECT // --
task.delay(1, function()
    if LoadConfig() then SyncUIAfterLoad() end
end)

-- // DRAGGING SYSTEMS // --
local miniDragging, miniHasMoved = false, false; local miniDragStart, miniStartPos
MiniButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then miniDragging = true; miniHasMoved = false; miniDragStart = input.Position; miniStartPos = MiniButton.Position end end)
MiniButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then miniDragging = false; if not miniHasMoved then MainFrame.Visible = not MainFrame.Visible end end end)
local mainDragging, mainDragStart, mainStartPos = false, nil, nil
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then mainDragging = true; mainDragStart = input.Position; mainStartPos = MainFrame.Position end end)
TopBar.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then mainDragging = false end end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if miniDragging then local delta = input.Position - miniDragStart; if delta.Magnitude > 5 then miniHasMoved = true end MiniButton.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y) end
        if mainDragging then local delta = input.Position - mainDragStart; MainFrame.Position = UDim2.new(mainStartPos.X.Scale, mainStartPos.X.Offset + delta.X, mainStartPos.Y.Scale, mainStartPos.Y.Offset + delta.Y) end
    end
end)

print("HiuCTE Menu V8 (Auto Save) Loaded Successfully!")
