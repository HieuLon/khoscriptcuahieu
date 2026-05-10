--[[ 
    CINEMA FLING HYBRID: ZENITH EDITION (V17 + V20 COMBINED)
    - Updated with Modern Physics (AlignPosition & AngularVelocity)
    - Lag Compensation (Velocity Prediction)
    - Hitbox Alignment (Sub-center targeting)
    - Frictionless Attacker (0 Friction Physics)
]]

if getgenv().ZenithLoaded then
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
    AutoFling = false,
    BlacklistEnabled = false,
    Whitelist = {},
    Blacklist = {},
    DragHeight = 600,
    SpinSpeed = 25000,
    IdleHeight = 150
}

local IsAttacking = false
local SelectedPlayer = ""

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

----------------------------------------------------------------
-- CORE HYBRID ATTACK LOGIC (UPGRADED)
----------------------------------------------------------------
local function HybridAttack(target)
    local TRoot, THum = GetCharacterParts(target)
    local MyRoot, MyHum = GetCharacterParts(LocalPlayer)
    
    if not TRoot or not MyRoot or IsAttacking then return end
    IsAttacking = true

    -- [NÂNG CẤP 5: Triệt tiêu Ma sát (Frictionless Attacker)]
    local originalProperties = {}
    local Noclip = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.CanCollide = false 
                    -- Xóa bỏ ma sát trong lúc tấn công
                    if not originalProperties[v] then
                        originalProperties[v] = v.CustomPhysicalProperties
                        v.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                    end
                end
            end
        end
    end)

    MyHum.PlatformStand = true
    
    -- [NÂNG CẤP 1: Dùng AssemblyLinearVelocity thay vì Velocity cũ]
    local isMoving = TRoot.AssemblyLinearVelocity.Magnitude > 2

    -- Thiết lập Attachment dùng chung cho Constraints
    local Att0 = Instance.new("Attachment", MyRoot)

    if isMoving then
        -- [NÂNG CẤP 2: Chuyển sang Ràng Buộc Vật Lý Hiện Đại]
        local AlignPos = Instance.new("AlignPosition", MyRoot)
        AlignPos.Attachment0 = Att0
        AlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        AlignPos.RigidityEnabled = true -- Ép dính tức thời

        local AngVel = Instance.new("AngularVelocity", MyRoot)
        AngVel.Attachment0 = Att0
        AngVel.MaxTorque = math.huge
        AngVel.AngularVelocity = Vector3.new(0, getgenv().Config.SpinSpeed, 0)

        -- Dùng Heartbeat thay cho RenderStepped để đồng bộ nhịp vật lý tốt hơn
        local AttackLoop = RunService.Heartbeat:Connect(function()
            if not TRoot.Parent then return end
            
            -- [NÂNG CẤP 3: Lag Compensation / Tiên đoán Quỹ Đạo]
            local predictedPos = TRoot.Position + (TRoot.AssemblyLinearVelocity * 0.15)
            
            -- [NÂNG CẤP 4: Hitbox Alignment - Nằm thấp hơn 0.5 stud]
            AlignPos.Position = predictedPos + Vector3.new(0, -0.5, 0)
        end)

        task.wait(2.5) -- Thời gian khoan
        AttackLoop:Disconnect()
        AlignPos:Destroy()
        AngVel:Destroy()
    else
        -- [LOGIC V17: SKYHOOK - Nâng cấp lên Ràng Buộc Hiện Đại]
        local AlignPos = Instance.new("AlignPosition", MyRoot)
        AlignPos.Attachment0 = Att0
        AlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        AlignPos.RigidityEnabled = true

        local LV = Instance.new("LinearVelocity", MyRoot)
        LV.Attachment0 = Att0
        LV.MaxForce = math.huge
        LV.VectorVelocity = Vector3.new(0, 12000, 0)

        local AttackLoop = RunService.Heartbeat:Connect(function()
            if not TRoot.Parent then return end
            -- Kéo dưới chân lên thông qua AlignPosition thay vì ép CFrame
            AlignPos.Position = TRoot.Position + Vector3.new(0, -2, 0)
        end)

        local start = tick()
        repeat task.wait() until TRoot.Position.Y > getgenv().Config.DragHeight or (tick() - start > 2)

        AttackLoop:Disconnect()
        AlignPos:Destroy()
        LV:Destroy()
    end

    -- Dọn dẹp & Phục hồi
    Att0:Destroy()
    Noclip:Disconnect()
    
    -- Trả lại ma sát ban đầu
    for part, props in pairs(originalProperties) do
        if part and part.Parent then
            part.CustomPhysicalProperties = props
        end
    end

    MyHum.PlatformStand = false
    MyRoot.AssemblyLinearVelocity = Vector3.zero
    MyRoot.AssemblyAngularVelocity = Vector3.zero
    IsAttacking = false
end

----------------------------------------------------------------
-- GIAO DIỆN RAYFIELD UI
----------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Zenith Hybrid Fling V26",
    LoadingTitle = "Initializing Hybrid Systems...",
    ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("Tấn Công", 4483362458)
local ListTab = Window:CreateTab("Danh Sách", 4483362458)

MainTab:CreateToggle({
    Name = "AUTO HYBRID FLING",
    CurrentValue = false,
    Callback = function(v) 
        getgenv().Config.AutoFling = v 
        if v then
            task.spawn(function()
                while getgenv().Config.AutoFling do
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and not IsWhitelisted(p) then
                            if getgenv().Config.BlacklistEnabled and IsBlacklisted(p) then
                                HybridAttack(p)
                            elseif not getgenv().Config.BlacklistEnabled then
                                HybridAttack(p)
                            end
                        end
                        if not getgenv().Config.AutoFling then break end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

MainTab:CreateToggle({
    Name = "CHẾ ĐỘ TRUY SÁT (Blacklist Only)",
    CurrentValue = false,
    Callback = function(v) getgenv().Config.BlacklistEnabled = v end
})

MainTab:CreateSlider({
    Name = "Độ cao Skyhook (V17)",
    Range = {300, 5000},
    Increment = 100,
    CurrentValue = 600,
    Callback = function(v) getgenv().Config.DragHeight = v end
})

-- Whitelist / Blacklist UI
local PlayerDrop = ListTab:CreateDropdown({
    Name = "Chọn Player",
    Options = {},
    CurrentOption = "",
    Callback = function(v) SelectedPlayer = v[1] end
})

ListTab:CreateButton({
    Name = "Làm mới danh sách",
    Callback = function()
        local names = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(names, p.Name) end
        end
        PlayerDrop:Refresh(names)
    end
})

ListTab:CreateButton({
    Name = "Thêm vào WHITELIST (Né)",
    Callback = function()
        if SelectedPlayer ~= "" and not table.find(getgenv().Config.Whitelist, SelectedPlayer) then
            table.insert(getgenv().Config.Whitelist, SelectedPlayer)
            Rayfield:Notify({Title = "Whitelist", Content = "Đã thêm " .. SelectedPlayer})
        end
    end
})

ListTab:CreateButton({
    Name = "Thêm vào BLACKLIST (Đá liên tục)",
    Callback = function()
        if SelectedPlayer ~= "" and not table.find(getgenv().Config.Blacklist, SelectedPlayer) then
            table.insert(getgenv().Config.Blacklist, SelectedPlayer)
            Rayfield:Notify({Title = "Blacklist", Content = "Đã thêm " .. SelectedPlayer})
        end
    end
})

ListTab:CreateButton({
    Name = "Xóa sạch danh sách",
    Callback = function()
        getgenv().Config.Whitelist = {}
        getgenv().Config.Blacklist = {}
        Rayfield:Notify({Title = "Reset", Content = "Đã xóa sạch các danh sách!"})
    end
})

-- Idle Loop (Sử dụng AlignPosition để ổn định thay vì thao túng CFrame trực tiếp)
local IdleAtt0 = Instance.new("Attachment", LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
local IdleAlign = Instance.new("AlignPosition")
IdleAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
IdleAlign.RigidityEnabled = true

RunService.Heartbeat:Connect(function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if getgenv().Config.AutoFling and not IsAttacking and root then
        if IdleAtt0.Parent ~= root then
            IdleAtt0.Parent = root
            IdleAlign.Attachment0 = IdleAtt0
            IdleAlign.Parent = root
        end
        IdleAlign.Enabled = true
        root.AssemblyLinearVelocity = Vector3.zero
        IdleAlign.Position = Vector3.new(root.Position.X, getgenv().Config.IdleHeight, root.Position.Z)
    else
        IdleAlign.Enabled = false
    end
end)

Rayfield:LoadConfiguration()
