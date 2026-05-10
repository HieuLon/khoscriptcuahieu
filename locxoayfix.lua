-- =====================================================================
-- ADMIN WALKFLING V3: TRUE NOCLIP & AUTO SPECTATE
-- Sửa lỗi dội ngược lực, Noclip xuyên người, View Cam mượt
-- =====================================================================

if getgenv().AdminWalkFlingV3Loaded then return end
getgenv().AdminWalkFlingV3Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

getgenv().Config = {
    WalkFling = false,
    FlingPower = 50000,
    HitboxRadius = 3.5,
    AutoSpectate = true,
    Whitelist = {}
}

local spectating = false
local currentTarget = nil

local function IsWhitelisted(playerName)
    return table.find(getgenv().Config.Whitelist, playerName) ~= nil
end

local function GetClosestTarget()
    local target = nil
    local shortestDist = getgenv().Config.HitboxRadius
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsWhitelisted(p.Name) and p.Character then
            -- Bỏ qua khiên tàng hình
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

-- =====================================================================
-- [CORE 1] VÒNG LẶP NOCLIP (CHẠY TRƯỚC VẬT LÝ) - CHỐNG TỰ VĂNG
-- =====================================================================
RunService.Stepped:Connect(function()
    if not getgenv().Config.WalkFling then return end
    
    -- Tắt va chạm của TOÀN BỘ người chơi khác đối với bạn
    -- Bạn sẽ đi xuyên qua họ, máy bạn không bị dội lực -> KHÔNG BAO GIỜ BỊ TỰ VĂNG
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- =====================================================================
-- [CORE 2] VÒNG LẶP FLING VÀ SPECTATE
-- =====================================================================
RunService.Heartbeat:Connect(function()
    if not getgenv().Config.WalkFling then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if spectating then return end -- Tạm ngưng hất khi đang xem cam

    local target = GetClosestTarget()
    
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        -- Khi ở gần, bơm lực xoay cực mạnh vào RootPart của bạn
        hrp.AssemblyAngularVelocity = Vector3.new(0, getgenv().Config.FlingPower, 0)
        
        -- Logic View Camera (Chỉ kích hoạt nếu bật AutoSpectate)
        if getgenv().Config.AutoSpectate and currentTarget ~= target then
            currentTarget = target
            
            task.spawn(function()
                task.wait(0.2) -- Chờ server ghi nhận cú hất
                
                if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local targetSpeed = target.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude
                    
                    -- Xác nhận mục tiêu đã bay với vận tốc > 150
                    if targetSpeed > 150 then
                        spectating = true
                        hrp.AssemblyAngularVelocity = Vector3.zero -- Ngừng xoay ngay lập tức
                        
                        -- Cập nhật Camera
                        Camera.CameraSubject = target.Character:FindFirstChild("Humanoid")
                        Rayfield:Notify({Title = "Sát Thủ Lên Tiếng", Content = "Đã hất văng: " .. target.Name .. " (Tốc độ: " .. math.floor(targetSpeed) .. ")"})
                        
                        task.wait(2.5) -- View nạn nhân 2.5 giây
                        
                        -- Trả lại Camera cho bạn
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                            Camera.CameraSubject = LocalPlayer.Character.Humanoid
                        end
                        spectating = false
                    end
                end
                currentTarget = nil
            end)
        end
    else
        -- Trả lại bình thường khi không có ai ở gần (Để đi bộ không bị lắc)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    spectating = false
    currentTarget = nil
    task.wait(0.5)
    Camera.CameraSubject = newChar:WaitForChild("Humanoid")
end)

-- =====================================================================
-- GIAO DIỆN RAYFIELD UI
-- =====================================================================
local Window = Rayfield:CreateWindow({
   Name = "Admin WalkFling V3 | Noclip Edition",
   LoadingTitle = "Đang nạp Noclip & Physics...",
   LoadingSubtitle = "Zero Self-Fling",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("Tấn Công", 4483362458)

MainTab:CreateToggle({
   Name = "Bật WalkFling (Tự động Noclip & Hất)",
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
   Name = "View Camera Mục Tiêu (2.5s) khi hất",
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

local ListTab = Window:CreateTab("Danh Sách Né", 4483362458)
local PlayerInput = ""

ListTab:CreateInput({
   Name = "Nhập tên người cần né",
   PlaceholderText = "Tên người chơi...",
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
            Rayfield:Notify({Title = "Whitelist", Content = "Đã né: " .. PlayerInput})
        end
   end,
})

ListTab:CreateButton({
   Name = "Xóa danh sách",
   Callback = function()
        getgenv().Config.Whitelist = {}
        Rayfield:Notify({Title = "Đã xóa", Content = "Danh sách Whitelist đã trống."})
   end,
})
