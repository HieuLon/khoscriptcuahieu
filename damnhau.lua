--[[ 
    ZENITH FLING: REVENGE EDITION (AUTO BLACKLIST)
    - Logic: V17 + V20 Hybrid
    - Feature: Bị đánh -> Tự động thêm kẻ địch vào Blacklist
    - UI: Hiển thị tên đầy đủ (@username)
]]

if getgenv().ZenithLoaded then
    game.StarterGui:SetCore("SendNotification", {Title = "Zenith", Text = "Script đang chạy rồi!", Duration = 3})
    return
end
getgenv().ZenithLoaded = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- CẤU HÌNH HỆ THỐNG
----------------------------------------------------------------
getgenv().Config = {
    AutoFling = false,          -- Tự động đánh
    RevengeMode = true,         -- Tự động thêm kẻ đánh mình vào Blacklist
    UseBlacklistOnly = false,   -- Chỉ đánh những người trong Blacklist
    
    Whitelist = {},
    Blacklist = {},             -- Danh sách kẻ thù
    
    DragHeight = 600,
    SpinSpeed = 25000,
}

local IsAttacking = false
local SelectedPlayerName = "" -- Chỉ lưu Username để xử lý cho chuẩn

----------------------------------------------------------------
-- HÀM HỖ TRỢ (UTILITIES)
----------------------------------------------------------------
local function IsWhitelisted(player)
    return table.find(getgenv().Config.Whitelist, player.Name) ~= nil
end

local function IsBlacklisted(player)
    return table.find(getgenv().Config.Blacklist, player.Name) ~= nil
end

local function GetCharacterParts(target)
    if not target or not target.Character then return nil end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    local hum = target.Character:FindFirstChild("Humanoid")
    return root, hum
end

-- Hàm tìm kẻ địch gần nhất (Để xác định ai vừa đánh mình)
local function GetClosestEnemy()
    local closest, dist = nil, 50 -- Chỉ tìm trong bán kính 50m
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then
                closest = p
                dist = d
            end
        end
    end
    return closest
end

----------------------------------------------------------------
-- AUTO REVENGE SYSTEM (TỰ ĐỘNG THÊM VÀO BLACKLIST)
----------------------------------------------------------------
local function InitRevengeSystem()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local oldHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < oldHp and getgenv().Config.RevengeMode then
            local enemy = GetClosestEnemy()
            if enemy and not IsWhitelisted(enemy) and not IsBlacklisted(enemy) then
                -- Thêm vào Blacklist
                table.insert(getgenv().Config.Blacklist, enemy.Name)
                
                -- Thông báo
                Rayfield:Notify({
                    Title = "PHÁT HIỆN TẤN CÔNG",
                    Content = "Đã thêm [" .. enemy.DisplayName .. "] vào Sổ Tử Thần!",
                    Duration = 3,
                    Image = 4483362458,
                })

                -- Tự động bật chế độ truy sát nếu chưa bật
                getgenv().Config.AutoFling = true
                getgenv().Config.UseBlacklistOnly = true -- Tập trung đánh nó
            end
        end
        oldHp = hp
    end)
end

----------------------------------------------------------------
-- CORE HYBRID ATTACK LOGIC (GIỮ NGUYÊN)
----------------------------------------------------------------
local function HybridAttack(target)
    local TRoot, THum = GetCharacterParts(target)
    local MyRoot, MyHum = GetCharacterParts(LocalPlayer)
    
    if not TRoot or not MyRoot or IsAttacking then return end
    IsAttacking = true

    -- Noclip logic
    local Noclip = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)

    MyHum.PlatformStand = true
    
    local isMoving = TRoot.Velocity.Magnitude > 2

    if isMoving then
        -- [LOGIC V20: ABSOLUTE LOCK]
        local BAV = Instance.new("BodyAngularVelocity", MyRoot)
        BAV.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        BAV.AngularVelocity = Vector3.new(0, getgenv().Config.SpinSpeed, 0)

        local BP = Instance.new("BodyPosition", MyRoot)
        BP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BP.P = 15000
        BP.D = 150

        local AttackLoop = RunService.RenderStepped:Connect(function()
            if not TRoot.Parent then return end
            BP.Position = TRoot.Position
            MyRoot.CFrame = TRoot.CFrame * CFrame.new(0, 0, 0.5)
            MyRoot.RotVelocity = Vector3.new(0, 15000, 0)
        end)

        task.wait(2.5)
        AttackLoop:Disconnect()
        BAV:Destroy()
        BP:Destroy()
    else
        -- [LOGIC V17: SKYHOOK]
        local Att = Instance.new("Attachment", MyRoot)
        local LV = Instance.new("LinearVelocity", MyRoot)
        LV.Attachment0 = Att
        LV.MaxForce = math.huge
        LV.VectorVelocity = Vector3.new(0, 12000, 0)

        local AttackLoop = RunService.Heartbeat:Connect(function()
            if not TRoot.Parent then return end
            MyRoot.CFrame = TRoot.CFrame * CFrame.new(0, -2, 0)
        end)

        local start = tick()
        repeat task.wait() until TRoot.Position.Y > getgenv().Config.DragHeight or (tick() - start > 2)

        AttackLoop:Disconnect()
        LV:Destroy()
        Att:Destroy()
    end

    -- Reset
    Noclip:Disconnect()
    MyHum.PlatformStand = false
    MyRoot.Velocity = Vector3.zero
    MyRoot.RotVelocity = Vector3.zero
    IsAttacking = false
end

----------------------------------------------------------------
-- GIAO DIỆN RAYFIELD UI (ĐÃ CẬP NHẬT)
----------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Zenith Revenge V26",
    LoadingTitle = "Đang nạp Sổ Tử Thần...",
    ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("Tấn Công", 4483362458)
local ListTab = Window:CreateTab("Danh Sách (Player)", 4483362458)

-- TAB TẤN CÔNG
MainTab:CreateToggle({
    Name = "KÍCH HOẠT FLING",
    CurrentValue = false,
    Callback = function(v) 
        getgenv().Config.AutoFling = v 
        if v then
            task.spawn(function()
                while getgenv().Config.AutoFling do
                    -- Ưu tiên 1: Đánh kẻ trong Blacklist trước
                    for _, name in pairs(getgenv().Config.Blacklist) do
                        local target = Players:FindFirstChild(name)
                        if target then HybridAttack(target) end
                    end

                    -- Ưu tiên 2: Đánh người thường (nếu không bật chế độ 'Chỉ Blacklist')
                    if not getgenv().Config.UseBlacklistOnly then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and not IsWhitelisted(p) and not IsBlacklisted(p) then
                                HybridAttack(p)
                            end
                            if not getgenv().Config.AutoFling then break end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

MainTab:CreateToggle({
    Name = "Tự động ghim thù (Auto Blacklist)",
    CurrentValue = true,
    Callback = function(v) getgenv().Config.RevengeMode = v end,
})

MainTab:CreateToggle({
    Name = "Chỉ đánh Blacklist (Target Focus)",
    CurrentValue = false,
    Callback = function(v) getgenv().Config.UseBlacklistOnly = v end,
})

-- TAB DANH SÁCH
local function GetFormattedList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            -- Format: DisplayName (@Username)
            table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return list
end

local PlayerDrop = ListTab:CreateDropdown({
    Name = "Chọn Người Chơi",
    Options = GetFormattedList(),
    CurrentOption = "",
    Flag = "PlayerSelect",
    Callback = function(Option)
        -- Tách lấy Username thật từ chuỗi "Display (@Username)"
        local selectedString = Option[1]
        local realUsername = string.match(selectedString, "@(.*)%)")
        if realUsername then
            SelectedPlayerName = realUsername
        else
            -- Fallback nếu không parse được (hiếm)
            SelectedPlayerName = selectedString
        end
    end,
})

ListTab:CreateButton({
    Name = "Làm mới danh sách (Refresh)",
    Callback = function()
        PlayerDrop:Refresh(GetFormattedList())
    end
})

ListTab:CreateButton({
    Name = "Thêm vào BLACKLIST (Giết)",
    Callback = function()
        if SelectedPlayerName ~= "" and not table.find(getgenv().Config.Blacklist, SelectedPlayerName) then
            table.insert(getgenv().Config.Blacklist, SelectedPlayerName)
            Rayfield:Notify({Title = "Đã thêm", Content = "Mục tiêu: " .. SelectedPlayerName})
        end
    end
})

ListTab:CreateButton({
    Name = "Thêm vào WHITELIST (Bạn bè)",
    Callback = function()
        if SelectedPlayerName ~= "" and not table.find(getgenv().Config.Whitelist, SelectedPlayerName) then
            table.insert(getgenv().Config.Whitelist, SelectedPlayerName)
            Rayfield:Notify({Title = "Đã thêm", Content = "Bạn bè: " .. SelectedPlayerName})
        end
    end
})

ListTab:CreateButton({
    Name = "Xóa Blacklist (Reset)",
    Callback = function()
        getgenv().Config.Blacklist = {}
        Rayfield:Notify({Title = "Xóa", Content = "Đã xóa sạch danh sách thù địch!"})
    end
})

-- KHỞI CHẠY
LocalPlayer.CharacterAdded:Connect(InitRevengeSystem)
InitRevengeSystem() -- Chạy lần đầu
