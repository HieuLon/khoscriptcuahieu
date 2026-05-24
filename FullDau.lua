-- ==========================================
-- 👑 SIÊU QUỶ HUB | MOBILE V6 ULTIMATE
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

local Vector2_new, Vector3_new = Vector2.new, Vector3.new
local CFrame_new = CFrame.new
local math_abs, math_clamp = math.abs, math.clamp
local tick_func = tick

-- ==========================================
-- CẤU HÌNH TỐI GIẢN
-- ==========================================
local Config = {
    AIM = { 
        Enabled = false, 
        WallCheck = true,  -- TẮT = bắn xuyên tường
        TeamCheck = true,  -- BẬT = không bắn đồng đội
        Smoothness = 0.1,  -- Tốc độ aim đầu (1 = max, 0.1 = cực nhanh)
        FOV = 100
    },
    ESP = { 
        Enabled = false,   -- BẬT = vẽ người địch màu đỏ tự động
        EnemyColor = Color3.fromRGB(255, 50, 50),
        TeamColor = Color3.fromRGB(50, 150, 255)
    }
}

local State = {
    Target = nil,
    ESPDrawings = {},
    ValidPlayers = {},
    Connections = {}
}

-- ==========================================
-- ESP TỰ ĐỘNG NHẬN DIỆN TEAM
-- ==========================================
local function IsEnemy(player)
    if not Config.AIM.TeamCheck then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

local function CreateESP(player)
    if State.ESPDrawings[player] then return end
    
    local drawings = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    drawings.Box.Thickness = 2
    drawings.Box.Filled = false
    
    drawings.Name.Size = 16
    drawings.Name.Center = true
    drawings.Name.Outline = true
    
    drawings.Tracer.Thickness = 1.5
    
    State.ESPDrawings[player] = drawings
end

local function UpdateESP()
    if not Config.ESP.Enabled then return end
    
    local viewport = Camera.ViewportSize
    local center = Vector2_new(viewport.X / 2, viewport.Y)
    
    for player, drawings in pairs(State.ESPDrawings) do
        local char = State.ValidPlayers[player]
        
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            for _, draw in pairs(drawings) do draw.Visible = false end
            continue
        end
        
        local hrp = char.HumanoidRootPart
        local head = char:FindFirstChild("Head")
        
        if hrp and head then
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3_new(0, 0.5, 0))
            if not onScreen then
                for _, draw in pairs(drawings) do draw.Visible = false end
                continue
            end
            
            -- Tự động chọn màu theo team
            local isEnemy = IsEnemy(player)
            local color = isEnemy and Config.ESP.EnemyColor or Config.ESP.TeamColor
            
            -- Vẽ box
            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3_new(0, 3, 0))
            local height = math_abs(headPos.Y - legPos.Y)
            local width = height / 2
            
            drawings.Box.Size = Vector2_new(width, height)
            drawings.Box.Position = Vector2_new(headPos.X - width/2, headPos.Y)
            drawings.Box.Color = color
            drawings.Box.Visible = true
            
            -- Vẽ tên
            drawings.Name.Text = player.Name
            drawings.Name.Position = Vector2_new(headPos.X, headPos.Y - 20)
            drawings.Name.Color = color
            drawings.Name.Visible = true
            
            -- Vẽ tracer
            drawings.Tracer.From = center
            drawings.Tracer.To = Vector2_new(legPos.X, legPos.Y)
            drawings.Tracer.Color = color
            drawings.Tracer.Visible = true
        else
            for _, draw in pairs(drawings) do draw.Visible = false end
        end
    end
end

-- ==========================================
-- AIMBOT TỐC ĐỘ MAX + TỰ ĐỘNG TEAM CHECK
-- ==========================================
local function CanTarget(player)
    -- Tự động kiểm tra team
    if Config.AIM.TeamCheck then
        if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            return false
        end
    end
    
    local char = State.ValidPlayers[player]
    if not char then return false end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    -- Kiểm tra tường (nếu bật)
    if Config.AIM.WallCheck then
        local targetPart = char:FindFirstChild("Head")
        if not targetPart then return false end
        
        local origin = Camera.CFrame.Position
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = Workspace:Raycast(origin, targetPart.Position - origin, raycastParams)
        if result and result.Instance and not result.Instance:IsDescendantOf(char) then
            return false
        end
    end
    
    return true
end

local function FindTarget()
    if not Config.AIM.Enabled then return nil end
    
    local center = Vector2_new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest = nil
    local closestDist = Config.AIM.FOV
    
    for player, char in pairs(State.ValidPlayers) do
        if not CanTarget(player) then continue end
        
        local head = char:FindFirstChild("Head")
        if not head then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if onScreen then
            local dist = (Vector2_new(pos.X, pos.Y) - center).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = head
            end
        end
    end
    
    return closest
end

-- ==========================================
-- HỆ THỐNG THEO DÕI NGƯỜI CHƠI
-- ==========================================
local function SetupPlayer(player)
    if player == LocalPlayer then return end
    
    CreateESP(player)
    State.Connections[player] = {}
    
    local function CharacterAdded(char)
        State.ValidPlayers[player] = char
        
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            table.insert(State.Connections[player], hum.Died:Connect(function()
                State.ValidPlayers[player] = nil
                if State.Target and State.Target.Parent == char then
                    State.Target = nil
                end
            end))
        end
    end
    
    table.insert(State.Connections[player], player.CharacterAdded:Connect(CharacterAdded))
    if player.Character then CharacterAdded(player.Character) end
end

local function CleanupPlayer(player)
    if State.Connections[player] then
        for _, conn in ipairs(State.Connections[player]) do conn:Disconnect() end
        State.Connections[player] = nil
    end
    
    if State.ESPDrawings[player] then
        for _, drawing in pairs(State.ESPDrawings[player]) do
            drawing:Remove()
        end
        State.ESPDrawings[player] = nil
    end
    
    State.ValidPlayers[player] = nil
end

-- Khởi tạo người chơi hiện có
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then SetupPlayer(player) end
end

Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(CleanupPlayer)

-- ==========================================
-- VÒNG LẶP CHÍNH - TỐC ĐỘ MAX
-- ==========================================
RunService.Heartbeat:Connect(function()
    -- Tìm mục tiêu mới
    State.Target = FindTarget()
    
    -- AIMBOT: Tốc độ max, kéo thẳng lên đầu
    if State.Target and Config.AIM.Enabled then
        local currentCF = Camera.CFrame
        local targetPos = State.Target.Position
        local newCF = CFrame_new(currentCF.Position, targetPos)
        
        -- Smoothness = 0.1 để aim cực nhanh, gần như tức thì
        Camera.CFrame = currentCF:Lerp(newCF, Config.AIM.Smoothness)
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

-- ==========================================
-- GIAO DIỆN TỐI GIẢN - CHỈ 2 CHỨC NĂNG
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🔥 SIÊU QUỶ HUB | V6 ULTIMATE",
    LoadingTitle = "Đang kích hoạt...",
    LoadingSubtitle = "AIM MAX + ESP AUTO TEAM",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- TAB AIM
local AimTab = Window:CreateTab("🎯 AIM", 4483362458)
AimTab:CreateToggle({
    Name = "BẬT AIMBOT",
    CurrentValue = false,
    Callback = function(v)
        Config.AIM.Enabled = v
        if not v then State.Target = nil end
    end
})

AimTab:CreateToggle({
    Name = "WALLCHECK (TẮT = BẮN XUYÊN TƯỜNG)",
    CurrentValue = true,
    Callback = function(v) Config.AIM.WallCheck = v end
})

AimTab:CreateToggle({
    Name = "TEAM CHECK (KHÔNG BẮN ĐỒNG ĐỘI)",
    CurrentValue = true,
    Callback = function(v) Config.AIM.TeamCheck = v end
})

AimTab:CreateSlider({
    Name = "TỐC ĐỘ AIM (0.1 = MAX)",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(v)
        Config.AIM.Smoothness = math_clamp(v/10, 0.1, 1)
    end
})

AimTab:CreateSlider({
    Name = "FOV",
    Range = {50, 300},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(v) Config.AIM.FOV = v end
})

-- TAB ESP
local ESPTab = Window:CreateTab("👁 ESP", 4483362458)
ESPTab:CreateToggle({
    Name = "BẬT ESP (TỰ ĐỘNG NHẬN TEAM)",
    CurrentValue = false,
    Callback = function(v) Config.ESP.Enabled = v end
})

ESPTab:CreateLabel("⚠️ ĐỊCH: MÀU ĐỎ | ĐỒNG ĐỘI: MÀU XANH")
ESPTab:CreateLabel("ESP tự động phân biệt team khi bật Team Check")

Rayfield:Notify({
    Title = "SIÊU QUỶ HUB",
    Content = "Đã kích hoạt thành công! AIM + ESP đã sẵn sàng.",
    Duration = 3,
    Image = 4483362458
})
