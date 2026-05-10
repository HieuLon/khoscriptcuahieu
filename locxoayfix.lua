-- =====================================================================
-- ADMIN WALKFLING: INVISIBLE SPIKE VELOCITY EDITION
-- Tích hợp sẵn Rayfield UI, Tối ưu hóa Vật lý & Chống lag/lỗi
-- =====================================================================

-- [1] RÀO BẢO VỆ: Tránh chạy đè script nhiều lần gây lỗi UI
if getgenv().AdminWalkFlingLoaded then 
    warn("Script đã được chạy trước đó!")
    return 
end
getgenv().AdminWalkFlingLoaded = true

-- [2] KHỞI TẠO DỊCH VỤ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Nạp thư viện Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- [3] CẤU HÌNH HỆ THỐNG TOÀN CỤC (GLOBAL CONFIG)
getgenv().Config = {
    WalkFlingEnabled = false,
    FlingPower = 50000,
    HitboxRadius = 4,
    Whitelist = {}
}

local isFlinging = false
local originalVelocity = Vector3.zero

-- [4] HÀM HỖ TRỢ (LỌC & TÌM MỤC TIÊU)
local function IsWhitelisted(playerName)
    for _, name in ipairs(getgenv().Config.Whitelist) do
        if name == playerName then return true end
    end
    return false
end

local function GetClosestTarget()
    local closestPlayer = nil
    local shortestDistance = getgenv().Config.HitboxRadius
    
    local character = LocalPlayer.Character
    if not character then return nil end
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsWhitelisted(player.Name) and player.Character then
            -- Bỏ qua những người có ForceField (khiêng bất tử) để tránh lỗi
            if player.Character:FindFirstChildOfClass("ForceField") then continue end
            
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChild("Humanoid")
            
            if targetRoot and targetHum and targetHum.Health > 0 then
                local distance = (myRoot.Position - targetRoot.Position).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

-- [5] HÀM QUẢN LÝ VẬT LÝ
local function SetFlingPhysics(enabled)
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if enabled then
                -- Bật chế độ Tạ sắt tàng hình: Nặng tối đa, 0 ma sát
                part.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
                -- Tắt va chạm tay chân để không bị vấp, chỉ giữ HRP và Torso
                if part.Name ~= "HumanoidRootPart" and not part.Name:match("Torso") then
                    part.CanCollide = false
                end
            else
                -- Trả về vật lý bình thường
                part.CustomPhysicalProperties = nil
                part.CanCollide = true
            end
        end
    end
end

-- [6] VÒNG LẶP CORE LOGIC (HEARTBEAT - XỬ LÝ MỖI KHUNG HÌNH)
RunService.Heartbeat:Connect(function()
    if not getgenv().Config.WalkFlingEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end
    
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not myRoot or not humanoid or humanoid.Health <= 0 then return end

    -- Đảm bảo vật lý luôn ở trạng thái Fling
    SetFlingPhysics(true)

    -- Quét và tấn công
    local target = GetClosestTarget()
    if target and target.Character and not isFlinging then
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            isFlinging = true
            
            -- Bảo lưu vận tốc để bạn vẫn đi lại bình thường
            originalVelocity = myRoot.AssemblyLinearVelocity

            -- Tính toán Vector hất (Đẩy xa + Hất tung lên trời)
            local flingDirection = (targetRoot.Position - myRoot.Position).Unit
            local spikeForce = (flingDirection * getgenv().Config.FlingPower) + Vector3.new(0, getgenv().Config.FlingPower * 0.8, 0)
            
            -- Bơm vận tốc chớp nhoáng
            myRoot.AssemblyLinearVelocity = spikeForce
            myRoot.AssemblyAngularVelocity = Vector3.new(getgenv().Config.FlingPower, getgenv().Config.FlingPower, getgenv().Config.FlingPower)

            -- Chờ 1 khung hình vật lý (Heartbeat yield) để game nhận diện va chạm
            RunService.Heartbeat:Wait()
            
            -- Khôi phục ngay lập tức để không bị mất kiểm soát
            if myRoot then
                myRoot.AssemblyLinearVelocity = originalVelocity
                myRoot.AssemblyAngularVelocity = Vector3.zero
            end
            
            -- Cooldown nhỏ để hệ thống vật lý không bị quá tải
            task.wait(0.05)
            isFlinging = false
        end
    end
end)

-- Bắt sự kiện hồi sinh để khôi phục biến nếu người chơi reset nhân vật
LocalPlayer.CharacterAdded:Connect(function()
    isFlinging = false
end)

-- =====================================================================
-- [7] GIAO DIỆN RAYFIELD UI
-- =====================================================================
local Window = Rayfield:CreateWindow({
   Name = "Admin WalkFling | Sát Thủ Thầm Lặng",
   LoadingTitle = "Đang tải hệ thống Admin...",
   LoadingSubtitle = "by Rayfield",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AdminFlingConfigs",
      FileName = "WalkFlingHub"
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false
})

local MainTab = Window:CreateTab("Tấn Công (WalkFling)", 4483362458)

MainTab:CreateToggle({
   Name = "Bật/Tắt WalkFling (Tự động hất ai lại gần)",
   CurrentValue = false,
   Flag = "Toggle_WalkFling",
   Callback = function(Value)
        getgenv().Config.WalkFlingEnabled = Value
        if not Value then
            SetFlingPhysics(false) -- Reset vật lý lập tức khi tắt
            Rayfield:Notify({Title = "Trạng thái", Content = "Đã TẮT WalkFling và trả lại vật lý bình thường."})
        else
            Rayfield:Notify({Title = "Trạng thái", Content = "Đã BẬT WalkFling. Cứ đi dạo bình thường nhé!"})
        end
   end,
})

MainTab:CreateSlider({
   Name = "Bán Kính Va Chạm (Hitbox - Studs)",
   Range = {2, 15},
   Increment = 1,
   Suffix = " Studs",
   CurrentValue = 4,
   Flag = "Slider_Radius",
   Callback = function(Value)
        getgenv().Config.HitboxRadius = Value
   end,
})

MainTab:CreateSlider({
   Name = "Lực Hất Văng (Fling Power)",
   Range = {10000, 150000},
   Increment = 5000,
   Suffix = " Power",
   CurrentValue = 50000,
   Flag = "Slider_Power",
   Callback = function(Value)
        getgenv().Config.FlingPower = Value
   end,
})

local ListTab = Window:CreateTab("Danh Sách (Whitelist)", 4483362458)
local PlayerInput = ""

ListTab:CreateInput({
   Name = "Nhập tên người chơi (Username)",
   PlaceholderText = "Tên chính xác của người chơi...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
        PlayerInput = Text
   end,
})

ListTab:CreateButton({
   Name = "Thêm vào Whitelist (Sẽ không bị hất)",
   Callback = function()
        if PlayerInput ~= "" and not IsWhitelisted(PlayerInput) then
            table.insert(getgenv().Config.Whitelist, PlayerInput)
            Rayfield:Notify({Title = "Thành công", Content = "Đã bảo vệ: " .. PlayerInput})
        end
   end,
})

ListTab:CreateButton({
   Name = "Xóa sạch Whitelist",
   Callback = function()
        getgenv().Config.Whitelist = {}
        Rayfield:Notify({Title = "Đã xóa", Content = "Toàn bộ danh sách bảo vệ đã bị xóa!"})
   end,
})

-- Nút tự hủy script an toàn
local SettingsTab = Window:CreateTab("Hệ Thống", 4483362458)
SettingsTab:CreateButton({
   Name = "Tắt hoàn toàn Script & Đóng UI",
   Callback = function()
        getgenv().Config.WalkFlingEnabled = false
        SetFlingPhysics(false)
        Rayfield:Destroy()
        getgenv().AdminWalkFlingLoaded = false
   end,
})
