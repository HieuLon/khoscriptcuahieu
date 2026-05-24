-- ==========================================
-- 👑 SIÊU QUỶ HUB | MOBILE V6 (VIP PRODUCTION)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Tự động cập nhật Camera nếu game thay đổi góc nhìn
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

local Vector2_new, Vector3_new = Vector2.new, Vector3.new
local CFrame_new = CFrame.new
local math_abs, math_clamp = math.abs, math.clamp
local tick_func = tick

-- ==========================================
-- BẢNG CẤU HÌNH (LƯU TRỮ CÁC TÍNH NĂNG)
-- ==========================================
local Config = {
    Combat = { 
        Aimbot = false, 
        AutoShoot = false, 
        AimPart = "Head", 
        Smoothness = 0.3, 
        WallCheck = true, -- Bật = Bị tường chặn, Tắt = Bắn xuyên tường
        TeamCheck = true, 
        FOVRadius = 150, 
        ShowFOV = true,
        AutoFlick = false, -- Tính năng xoay phắt người
        FlickDistance = 30 -- Bán kính phát hiện địch móc lốp (studs)
    },
    Visuals = { 
        Box = false, 
        Name = false, 
        Tracer = false 
    },
    Misc = { 
        Hitbox = false, 
        HitboxSize = 3 
    }
}

local State = {
    Target = nil,
    LastShoot = 0,
    LastTargetScan = 0,
    OriginalHitboxes = {},
    ESPObjects = {},
    Connections = {}, 
    ValidPlayersCache = {} 
}

-- Tối ưu hóa tia Laser (Raycast) để tránh lag
local RaycastIgnoreTable = {LocalPlayer.Character, Camera}
local SharedRaycastParams = RaycastParams.new()
SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SharedRaycastParams.IgnoreWater = true
SharedRaycastParams.FilterDescendantsInstances = RaycastIgnoreTable

LocalPlayer.CharacterAdded:Connect(function(char)
    RaycastIgnoreTable[1] = char
    SharedRaycastParams.FilterDescendantsInstances = RaycastIgnoreTable
end)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    RaycastIgnoreTable[2] = Workspace.CurrentCamera
    SharedRaycastParams.FilterDescendantsInstances = RaycastIgnoreTable
end)

-- ==========================================
-- HỆ THỐNG HITBOX TO
-- ==========================================
local HitboxManager = {}

function HitboxManager.ApplyToPlayer(player, head)
    if not head then return end
    local original = State.OriginalHitboxes[player]
    if not original then return end

    if Config.Misc.Hitbox then
        head.Size = Vector3_new(Config.Misc.HitboxSize, Config.Misc.HitboxSize, Config.Misc.HitboxSize)
        head.Transparency = 0.5
        head.CanCollide = false
    else
        head.Size = original.Size
        head.Transparency = original.Transparency
        head.CanCollide = original.CanCollide
    end
end

function HitboxManager.UpdateAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            HitboxManager.ApplyToPlayer(player, player.Character:FindFirstChild("Head"))
        end
    end
end

-- ==========================================
-- HỆ THỐNG ESP (NHÌN XUYÊN TƯỜNG)
-- ==========================================
local ESPManager = {}

function ESPManager.Create(player)
    if State.ESPObjects[player] then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 1.5; box.Filled = false
    
    local name = Drawing.new("Text")
    name.Size = 16; name.Center = true; name.Outline = true
    
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1.5
    
    State.ESPObjects[player] = { Box = box, Name = name, Tracer = tracer }
    ESPManager.Hide(player)
end

function ESPManager.Hide(player)
    local esp = State.ESPObjects[player]
    if esp then
        esp.Box.Visible = false; esp.Name.Visible = false; esp.Tracer.Visible = false
    end
end

function ESPManager.Cleanup(player)
    if State.ESPObjects[player] then
        for _, drawing in pairs(State.ESPObjects[player]) do drawing:Remove() end
        State.ESPObjects[player] = nil
    end
    State.OriginalHitboxes[player] = nil
    State.ValidPlayersCache[player] = nil
    
    if State.Connections[player] then
        for _, conn in ipairs(State.Connections[player]) do conn:Disconnect() end
        State.Connections[player] = nil
    end
end

-- ==========================================
-- LOGIC AIMBOT & AUTO FLICK (CHỐNG MÓC LỐP)
-- ==========================================
local TargetManager = {}

local function IsTeammate(player)
    if not Config.Combat.TeamCheck then return false end
    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        return LocalPlayer.Team == player.Team
    end
    return false
end

local function isVisible(targetPart)
    -- Nếu WallCheck bị TẮT, luôn trả về true (Bắn xuyên tường)
    if not Config.Combat.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local result = Workspace:Raycast(origin, targetPart.Position - origin, SharedRaycastParams)
    return (result and result.Instance and result.Instance:IsDescendantOf(targetPart.Parent))
end

function TargetManager.IsTargetValid()
    local target = State.Target
    if not target or not target.Parent then return false end
    if not target:IsDescendantOf(Workspace) then return false end
    
    local hum = target.Parent:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

function TargetManager.Scan()
    local center = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    local closestFOVTarget = nil
    local shortestDist = Config.Combat.FOVRadius
    
    local closestProximityTarget = nil
    local shortestProximity = Config.Combat.FlickDistance

    for player, char in pairs(State.ValidPlayersCache) do
        if IsTeammate(player) then continue end
        
        local aimPart = char:FindFirstChild(Config.Combat.AimPart)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if aimPart and hrp then
            -- 1. Xử lý phản xạ cận chiến (Auto Flick)
            if Config.Combat.AutoFlick then
                local dist3D = (Camera.CFrame.Position - hrp.Position).Magnitude
                if dist3D < shortestProximity and isVisible(aimPart) then
                    shortestProximity = dist3D
                    closestProximityTarget = aimPart
                end
            end

            -- 2. Xử lý ngắm theo vòng FOV bình thường
            local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
            if onScreen then
                local dist2D = (Vector2_new(pos.X, pos.Y) - center).Magnitude
                if dist2D < shortestDist and isVisible(aimPart) then
                    shortestDist = dist2D
                    closestFOVTarget = aimPart
                end
            end
        end
    end
    
    -- Ưu tiên thằng ở cực gần (Flick), nếu không có thì lấy thằng trong FOV
    State.Target = closestProximityTarget or closestFOVTarget
end

-- ==========================================
-- THEO DÕI SỰ KIỆN NGƯỜI CHƠI
-- ==========================================
local function OnPlayerAdded(player)
    ESPManager.Create(player)
    State.Connections[player] = {}
    
    local function setupCharacter(char)
        State.ValidPlayersCache[player] = char
        task.spawn(function()
            local head = char:WaitForChild("Head", 5)
            if head then
                State.OriginalHitboxes[player] = { Size = head.Size, Transparency = head.Transparency, CanCollide = head.CanCollide }
                HitboxManager.ApplyToPlayer(player, head)
            end
        end)
        
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            table.insert(State.Connections[player], hum.Died:Connect(function()
                State.ValidPlayersCache[player] = nil
                ESPManager.Hide(player)
                if State.Target and State.Target.Parent == char then State.Target = nil end
            end))
        end
    end
    
    table.insert(State.Connections[player], player.CharacterAdded:Connect(setupCharacter))
    if player.Character then setupCharacter(player.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then OnPlayerAdded(p) end
end
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(ESPManager.Cleanup)

-- ==========================================
-- VÒNG LẶP RENDER & TÍNH TOÁN (XỊN & MƯỢT)
-- ==========================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 50, 50)
FOVCircle.Thickness = 2
FOVCircle.Filled = false

-- Vòng lặp tính toán Aimbot
RunService.Heartbeat:Connect(function()
    local now = tick_func()
    
    if Config.Combat.Aimbot then
        if not TargetManager.IsTargetValid() then State.Target = nil end
        if now - State.LastTargetScan > 0.08 then -- Quét cực lẹ (12 lần/s)
            State.LastTargetScan = now
            TargetManager.Scan()
        end
    else
        State.Target = nil
    end
    
    -- Fix lỗi Auto Shoot kẹt Joystick Mobile (Sử dụng Tool:Activate)
    if Config.Combat.AutoShoot and State.Target and (now - State.LastShoot > 0.1) then
        State.LastShoot = now
        
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate() -- Lệnh này khiến súng tự bắn mà không chạm vào màn hình
            end
        end
        
        -- Hỗ trợ thêm cho các dòng executor có hàm mouse1click
        if mouse1click then
            task.spawn(mouse1click)
        end
    end
end)

-- Vòng lặp vẽ đồ họa
RunService.RenderStepped:Connect(function()
    local viewport = Camera.ViewportSize
    local center = Vector2_new(viewport.X / 2, viewport.Y / 2)
    
    -- Cập nhật FOV
    FOVCircle.Position = center
    FOVCircle.Radius = Config.Combat.FOVRadius
    FOVCircle.Visible = Config.Combat.ShowFOV and Config.Combat.Aimbot
    
    -- Xoay Camera mượt mà
    if State.Target then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame_new(Camera.CFrame.Position, State.Target.Position), Config.Combat.Smoothness)
    end
    
    -- Vẽ ESP Nhìn xuyên tường
    for player, esp in pairs(State.ESPObjects) do
        local char = State.ValidPlayersCache[player]
        
        if not char or IsTeammate(player) then
            ESPManager.Hide(player)
            continue
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        
        if hrp and head then
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3_new(0, 0.5, 0))
            if not onScreen then ESPManager.Hide(player); continue end
            
            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3_new(0, 3, 0))
            local boxHeight = math_abs(headPos.Y - legPos.Y)
            local boxWidth = boxHeight / 2
            
            if Config.Visuals.Box then
                esp.Box.Size = Vector2_new(boxWidth, boxHeight)
                esp.Box.Position = Vector2_new(headPos.X - boxWidth / 2, headPos.Y)
                esp.Box.Color = (State.Target and State.Target.Parent == char) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
                esp.Box.Visible = true
            else esp.Box.Visible = false end
            
            if Config.Visuals.Name then
                esp.Name.Text = player.Name
                esp.Name.Position = Vector2_new(headPos.X, headPos.Y - 20)
                esp.Name.Visible = true
            else esp.Name.Visible = false end
            
            if Config.Visuals.Tracer then
                esp.Tracer.From = Vector2_new(center.X, viewport.Y)
                esp.Tracer.To = Vector2_new(legPos.X, legPos.Y)
                esp.Tracer.Visible = true
            else esp.Tracer.Visible = false end
        else
            ESPManager.Hide(player)
        end
    end
end)

-- ==========================================
-- GIAO DIỆN SIÊU ĐẸP BẰNG RAYFIELD
-- ==========================================
local success, Rayfield = pcall(function() return loadstring(game:HttpGet('https://sirius.menu/rayfield'))() end)

if success and type(Rayfield) == "table" then
    local Window = Rayfield:CreateWindow({ 
        Name = "🔥 SIÊU QUỶ HUB | MOBILE V6 VIP", 
        LoadingTitle = "Đang tải hệ thống cực xịn...",
        LoadingSubtitle = "Không liệt phím, Full tính năng",
        ConfigurationSaving = { Enabled = false }, 
        KeySystem = false 
    })

    local AimTab = Window:CreateTab("🔫 Chiến Đấu", 4483362458)
    AimTab:CreateToggle({ Name = "Bật Aimbot", CurrentValue = false, Flag = "T_Aim", Callback = function(V) Config.Combat.Aimbot = V end })
    AimTab:CreateToggle({ Name = "🔥 Auto Shoot (Chuẩn Mobile - Không liệt phím)", CurrentValue = false, Flag = "T_Shoot", Callback = function(V) Config.Combat.AutoShoot = V end })
    AimTab:CreateToggle({ Name = "🛡 Không bắn đồng đội (Team Check)", CurrentValue = true, Flag = "T_Team", Callback = function(V) Config.Combat.TeamCheck = V end })
    AimTab:CreateToggle({ Name = "🧱 Kiểm tra vật cản (TẮT ĐỂ BẮN XUYÊN TƯỜNG)", CurrentValue = true, Flag = "T_Wall", Callback = function(V) Config.Combat.WallCheck = V end })
    
    AimTab:CreateSection("Phản Xạ Cận Chiến (Chống Móc Lốp)")
    AimTab:CreateToggle({ Name = "Bật Auto Flick 180 (Quay phắt lại)", CurrentValue = false, Flag = "T_Flick", Callback = function(V) Config.Combat.AutoFlick = V end })
    AimTab:CreateSlider({ Name = "Khoảng cách Flick", Range = {10, 100}, Increment = 5, CurrentValue = 30, Suffix = " studs", Flag = "S_FlickDist", Callback = function(V) Config.Combat.FlickDistance = math_clamp(V, 10, 100) end })

    AimTab:CreateSection("Cài Đặt Cảm Giác Bắn")
    AimTab:CreateSlider({ Name = "Độ mượt Camera", Range = {1, 10}, Increment = 1, CurrentValue = 3, Flag = "S_Smooth", Callback = function(V) Config.Combat.Smoothness = math_clamp(V / 10, 0.1, 1) end })
    AimTab:CreateSlider({ Name = "Kích cỡ vòng FOV", Range = {50, 400}, Increment = 10, CurrentValue = 150, Suffix = " px", Flag = "S_FOVSize", Callback = function(V) Config.Combat.FOVRadius = math_clamp(V, 50, 400) end })

    local ESPTab = Window:CreateTab("👁 Nhìn Xuyên", 4483362458)
    ESPTab:CreateToggle({ Name = "ESP Khung (Đỏ khi bị khóa mục tiêu)", CurrentValue = false, Flag = "E_Box", Callback = function(V) Config.Visuals.Box = V end })
    ESPTab:CreateToggle({ Name = "ESP Tên", CurrentValue = false, Flag = "E_Name", Callback = function(V) Config.Visuals.Name = V end })
    ESPTab:CreateToggle({ Name = "ESP Dây Tracer", CurrentValue = false, Flag = "E_Tracer", Callback = function(V) Config.Visuals.Tracer = V end })
    
    local MiscTab = Window:CreateTab("⚙ Hitbox & Phụ", 4483362458)
    MiscTab:CreateToggle({ Name = "Mở rộng Hitbox Đầu", CurrentValue = false, Flag = "H_Box", Callback = function(V) 
        Config.Misc.Hitbox = V
        HitboxManager.UpdateAll()
    end })
    MiscTab:CreateSlider({ Name = "Kích cỡ Đầu", Range = {2, 10}, Increment = 1, CurrentValue = 3, Flag = "H_Size", Callback = function(V) 
        Config.Misc.HitboxSize = math_clamp(V, 2, 10)
        if Config.Misc.Hitbox then HitboxManager.UpdateAll() end
    end })
end
