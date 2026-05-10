-- =====================================================================
-- ADMIN WALKFLING V2: ZERO SELF-FLING & AUTO SPECTATE
-- Tích hợp Rayfield, Không tự văng, Tự động soi Camera 2s
-- =====================================================================

if getgenv().AdminWalkFlingV2Loaded then 
    return 
end
getgenv().AdminWalkFlingV2Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Nạp UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Cấu hình
getgenv().Config = {
    WalkFling = false,
    FlingPower = 999999, -- Lực siêu to để đảm bảo bay
    HitboxRadius = 3.5,
    AutoSpectate = true,
    Whitelist = {}
}

local spectating = false
local checkCooldown = false

local function IsWhitelisted(playerName)
    for _, name in ipairs(getgenv().Config.Whitelist) do
        if name == playerName then return true end
    end
    return false
end

-- Tìm người gần nhất
local function GetClosestTarget()
    local target = nil
    local shortestDist = getgenv().Config.HitboxRadius
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsWhitelisted(p.Name) and p.Character then
            -- Bỏ qua người đang có khiên tàng hình (mới hồi sinh)
            if p.Character:FindFirstChildOfClass("ForceField") then continue end
            
            local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                local dist = (myPos - tRoot.Position).Magnitude
                if dist <= shortestDist then
                    target = p
                    shortestDist = dist
                end
            end
        end
    end
    return target
end

-- Vòng lặp Cốt lõi
RunService.Heartbeat:Connect(function()
    if not getgenv().Config.WalkFling then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not char:FindFirstChild("Humanoid") then return end

    -- Bước 1: Ghim trọng tâm (Anti-Self-Fling)
    -- Nếu bị dội ngược lên trên (vận tốc Y > 10), lập tức dìm xuống để không bị bay
    if hrp.AssemblyLinearVelocity.Y > 10 then
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -5, hrp.AssemblyLinearVelocity.Z)
    end

    -- Đang xem cam người khác thì không kích hoạt fling tiếp
    if spectating then return end

    -- Tối ưu Vật lý cơ thể
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Nặng tối đa, 0 ma sát để hất người khác đi
            part.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
            -- Tắt va chạm linh tinh, chỉ giữ HRP để đi bộ
            if part.Name ~= "HumanoidRootPart" and not part.Name:match("Torso") then
                part.CanCollide = false
            end
        end
    end

    -- Bước 2: Quét mục tiêu
    local target = GetClosestTarget()
    
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local tRoot = target.Character.HumanoidRootPart
        
        -- Truyền lực xoay cực đại (Phá vỡ vật lý đối phương)
        hrp.AssemblyAngularVelocity = Vector3.new(0, getgenv().Config.FlingPower, 0)

        -- Bước 3: Xác nhận hất thành công và View Camera (Chỉ chạy 1 lần mỗi nhịp)
        if getgenv().Config.AutoSpectate and not checkCooldown then
            checkCooldown = true
            
            task.spawn(function()
                -- Đợi 0.15s cho game engine xử lý cú va chạm
                task.wait(0.15)
                
                if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local targetSpeed = target.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude
                    
                    -- NẾU MỤC TIÊU CÓ VẬN TỐC LỚN HƠN 100 -> ĐÃ BỊ HẤT VĂNG!
                    if targetSpeed > 100 then
                        spectating = true
                        
                        -- Set Camera view người đó
                        Camera.CameraSubject = target.Character:FindFirstChild("Humanoid") or target.Character.HumanoidRootPart
                        Rayfield:Notify({Title = "Thành công!", Content = "Đã hất văng " .. target.Name .. " với tốc độ " .. math.floor(targetSpeed) .. "! Đang view..."})
                        
                        -- Chờ 2 giây
                        task.wait(2)
                        
                        -- Trả Camera về mình
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                            Camera.CameraSubject = LocalPlayer.Character.Humanoid
                        end
                        spectating = false
                    end
                end
                
                -- Cooldown nhỏ trước khi kiểm tra cú hất tiếp theo
                task.wait(0.5)
                checkCooldown = false
            end)
        end
    else
        -- Trả lại bình thường nếu không có ai ở gần
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end)

-- Khi nhân vật chết/hồi sinh, trả lại Camera
LocalPlayer.CharacterAdded:Connect(function(newChar)
    spectating = false
    checkCooldown = false
    task.wait(0.5)
    Camera.CameraSubject = newChar:WaitForChild("Humanoid")
end)

-- =====================================================================
-- GIAO DIỆN RAYFIELD UI
-- =====================================================================
local Window = Rayfield:CreateWindow({
   Name = "Admin WalkFling V2 | Spectate",
   LoadingTitle = "Bypass & Anti-Fling Loaded...",
   LoadingSubtitle = "by Admin",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("Tấn Công (WalkFling)", 4483362458)

MainTab:CreateToggle({
   Name = "Bật WalkFling (Chạm là bay)",
   CurrentValue = false,
   Flag = "ToggleWF",
   Callback = function(Value)
        getgenv().Config.WalkFling = Value
        if not Value then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                Camera.CameraSubject = char:FindFirstChild("Humanoid")
            end
            spectating = false
        end
   end,
})

MainTab:CreateToggle({
   Name = "Tự động View Cam người bị hất (2s)",
   CurrentValue = true,
   Flag = "ToggleCam",
   Callback = function(Value)
        getgenv().Config.AutoSpectate = Value
   end,
})

MainTab:CreateSlider({
   Name = "Bán Kính Quét (Studs)",
   Range = {2, 10},
   Increment = 0.5,
   Suffix = " Studs",
   CurrentValue = 3.5,
   Flag = "Radius",
   Callback = function(Value)
        getgenv().Config.HitboxRadius = Value
   end,
})

local ListTab = Window:CreateTab("Bảo Vệ (Whitelist)", 4483362458)
local PlayerInput = ""

ListTab:CreateInput({
   Name = "Tên người chơi",
   PlaceholderText = "Nhập tên để không bị hất...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
        PlayerInput = Text
   end,
})

ListTab:CreateButton({
   Name = "Thêm vào Whitelist",
   Callback = function()
        if PlayerInput ~= "" and not IsWhitelisted(PlayerInput) then
            table.insert(getgenv().Config.Whitelist, PlayerInput)
            Rayfield:Notify({Title = "Bảo vệ", Content = "Đã bỏ qua: " .. PlayerInput})
        end
   end,
})

ListTab:CreateButton({
   Name = "Xóa toàn bộ Whitelist",
   Callback = function()
        getgenv().Config.Whitelist = {}
        Rayfield:Notify({Title = "Đã xóa", Content = "Danh sách trống!"})
   end,
})
