-- =====================================================================
-- ADMIN WALKFLING V4: STEALTH DESTRUCTOR & ULTIMATE SAFE GUARD
-- Đi bộ bình thường, Hất văng cực căng, Chống bay bản thân 100%
-- =====================================================================

if getgenv().WalkFlingV4Loaded then return end
getgenv().WalkFlingV4Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

getgenv().Config = {
    WalkFling = false,
    FlingPower = 9999999, -- Lực siêu cực đại để đảm bảo đụng là bay màu
    HitboxRadius = 3.5,
    Whitelist = {}
}

-- Biến an toàn (Safety Checks)
local LastSafeCFrame = nil
local SafetyThreshold = 80 -- Nếu tốc độ của bạn vượt mốc này -> Đang bị văng -> Kích hoạt hãm phanh

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
-- [1] VÒNG LẶP LOOP NOCLIP (TẮT VA CHẠM NGƯỜI KHÁC)
-- Chạy trước engine vật lý (Stepped) để đảm bảo không bị dội lực
-- =====================================================================
RunService.Stepped:Connect(function()
    if not getgenv().Config.WalkFling then return end
    
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
-- [2] HỆ THỐNG KIỂM TRA AN TOÀN TỐI THƯỢNG & TẤN CÔNG (HEARTBEAT)
-- =====================================================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end

    if getgenv().Config.WalkFling then
        -- [BƯỚC 1: LƯU TRẠNG THÁI AN TOÀN]
        -- Kiểm tra xem bạn có đang đứng trên mặt đất đàng hoàng không (không rơi tự do)
        if humanoid.FloorMaterial ~= Enum.Material.Air and hrp.AssemblyLinearVelocity.Magnitude < 30 then
            LastSafeCFrame = hrp.CFrame
        end

        -- [BƯỚC 2: CHECK AN TOÀN (ANTI-SELF FLING)]
        -- Nếu tốc độ của bạn đột nhiên chớp lên > 80 (chắc chắn là do bị dội lực Fling)
        if hrp.AssemblyLinearVelocity.Magnitude > SafetyThreshold or hrp.AssemblyLinearVelocity.Y > 50 or hrp.AssemblyLinearVelocity.Y < -200 then
            -- Lập tức hãm phanh lại bằng Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            -- Nếu có tọa độ an toàn, snap ngược về ngay lập tức để không bị văng
            if LastSafeCFrame then
                hrp.CFrame = LastSafeCFrame
            end
        end

        -- [BƯỚC 3: ÉP CƠ THỂ NẶNG TỐI ĐA (DENSITY MAX)]
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
            end
        end

        -- [BƯỚC 4: TÌM & HẤT ĐỊCH]
        local target = GetClosestTarget()
        if target then
            -- Bơm thẳng hàng triệu lực xoay vào cả 3 TRỤC. Phá nát vật lý đối phương.
            -- Nhưng bạn không bị xoay hình ảnh vì Noclip và Hệ thống phanh trên máy tính của bạn giữ bạn lại.
            hrp.AssemblyAngularVelocity = Vector3.new(getgenv().Config.FlingPower, getgenv().Config.FlingPower, getgenv().Config.FlingPower)
        else
            -- Ép lực xoay về 0 để đi bộ mượt mà bình thường
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    else
        -- Khi tắt script, trả lại vật lý tự nhiên
        if LastSafeCFrame ~= nil then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = nil
                end
            end
            LastSafeCFrame = nil
        end
    end
end)

-- =====================================================================
-- GIAO DIỆN RAYFIELD UI
-- =====================================================================
local Window = Rayfield:CreateWindow({
   Name = "Admin WalkFling V4 | Bất Tử",
   LoadingTitle = "Đang nạp Anti-Fling & Physics...",
   LoadingSubtitle = "An Toàn Tuyệt Đối",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("Tấn Công V4", 4483362458)

MainTab:CreateToggle({
   Name = "Bật WalkFling (Cực Căng + Chống Bay)",
   CurrentValue = false,
   Flag = "ToggleWF",
   Callback = function(Value)
        getgenv().Config.WalkFling = Value
        if not Value then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            end
        else
            Rayfield:Notify({Title = "Hệ thống An Toàn", Content = "Đã BẬT LoopNoclip và Anti-Văng! Sẵn sàng quét sạch."})
        end
   end,
})

MainTab:CreateSlider({
   Name = "Bán Kính Kích Hoạt (Studs)",
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
   PlaceholderText = "Username...",
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
            Rayfield:Notify({Title = "Đã né", Content = "Không hất " .. PlayerInput})
        end
   end,
})

ListTab:CreateButton({
   Name = "Xóa Whitelist",
   Callback = function()
        getgenv().Config.Whitelist = {}
        Rayfield:Notify({Title = "Thành công", Content = "Xóa sạch danh sách bảo vệ!"})
   end,
})
