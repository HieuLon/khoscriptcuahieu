--[[ 
    CINEMA FLING V21: OPTIMIZED ARCHITECTURE
    Refactored by Senior Luau Engineer
    Core: Hybrid System, Memory Safe, Physics Constraints
]]

if getgenv().PhantomLoaded then return end
getgenv().PhantomLoaded = true

----------------------------------------------------------------
-- 1. SERVICES & REFERENCES
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- 2. STATE & CONFIGURATION
----------------------------------------------------------------
getgenv().FlingConfig = getgenv().FlingConfig or {
    AutoFling = false,
    AfkAura = false,
    DragHeight = 1000,
    IdleHeight = 100,
    Whitelist = {},
    TargetSelect = ""
}

local Config = getgenv().FlingConfig
local State = {
    IsAttacking = false,
    CurrentTarget = nil,
    Connections = {},     -- Maid for runtime loops
    PhysicsCache = {},    -- Maid for physics instances
    IdleInstances = {}    -- Maid for AFK/Idle constraints
}

local CONSTANTS = {
    SPIN_POWER = 10000,
    MAX_FORCE = math.huge,
    PREDICT_TIME = 0.15,
    ATTACK_TIMEOUT = 4,
    MOVE_THRESHOLD = 5
}

----------------------------------------------------------------
-- 3. UTILITIES & CLEANUP MANAGERS (MAID PATTERN)
----------------------------------------------------------------
local function CleanTable(targetTable)
    for _, item in ipairs(targetTable) do
        if typeof(item) == "RBXScriptConnection" and item.Connected then
            item:Disconnect()
        elseif typeof(item) == "Instance" and item.Parent then
            item:Destroy()
        elseif type(item) == "function" then
            pcall(item)
        end
    end
    table.clear(targetTable)
end

local function IsWhitelisted(playerName)
    return table.find(Config.Whitelist, playerName) ~= nil
end

local function GetValidTarget(player)
    if not player or player == LocalPlayer or IsWhitelisted(player.Name) then return nil end
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum or hum.Health <= 0 then return nil end
    return char, root, hum
end

local function IsMoving(velocity)
    return velocity.Magnitude > CONSTANTS.MOVE_THRESHOLD
end

local function RestoreCharacterState()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    
    if root then
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end
    if hum then
        hum.PlatformStand = false
    end
end

----------------------------------------------------------------
-- 4. PHYSICS MODULES
----------------------------------------------------------------
-- [Idle & AFK]: Sử dụng Constraint để Game Engine tự tính toán (0% Loop Overhead)
local function ToggleConstraintAura(enable, mode)
    CleanTable(State.IdleInstances)
    if not enable then 
        RestoreCharacterState()
        return 
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    char.Humanoid.PlatformStand = true

    local att = Instance.new("Attachment")
    att.Parent = root
    table.insert(State.IdleInstances, att)

    -- Ghim vị trí (Không bị trôi dạt)
    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = att
    alignPos.Position = mode == "IDLE" and Vector3.new(0, Config.IdleHeight, 0) or root.Position
    alignPos.MaxForce = CONSTANTS.MAX_FORCE
    alignPos.MaxVelocity = CONSTANTS.MAX_FORCE
    alignPos.Responsiveness = 200
    alignPos.Parent = root
    table.insert(State.IdleInstances, alignPos)

    -- Aura xoay (AFK Mode)
    if mode == "AFK" then
        local angVel = Instance.new("AngularVelocity")
        angVel.Attachment0 = att
        angVel.MaxTorque = CONSTANTS.MAX_FORCE
        angVel.AngularVelocity = Vector3.new(0, CONSTANTS.SPIN_POWER, 0)
        angVel.Parent = root
        table.insert(State.IdleInstances, angVel)
    end
end

-- [Active Attack]: Direct Manipulation
local function SetupAttackPhysics(root)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(CONSTANTS.MAX_FORCE, CONSTANTS.MAX_FORCE, CONSTANTS.MAX_FORCE)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    
    local bav = Instance.new("BodyAngularVelocity")
    bav.MaxTorque = Vector3.new(CONSTANTS.MAX_FORCE, CONSTANTS.MAX_FORCE, CONSTANTS.MAX_FORCE)
    bav.AngularVelocity = Vector3.new(0, CONSTANTS.SPIN_POWER, 0)
    bav.Parent = root

    table.insert(State.PhysicsCache, bv)
    table.insert(State.PhysicsCache, bav)
    return bv, bav
end

local function ExecuteAttack(target)
    local tChar, tRoot, tHum = GetValidTarget(target)
    if not tChar then return end

    -- Cleanup previous state
    State.IsAttacking = true
    CleanTable(State.Connections)
    CleanTable(State.PhysicsCache)
    ToggleConstraintAura(false) 

    local char = LocalPlayer.Character
    local root = char.HumanoidRootPart
    local hum = char.Humanoid
    
    hum.PlatformStand = true
    local bv, bav = SetupAttackPhysics(root)

    -- Noclip bypass
    table.insert(State.Connections, RunService.Stepped:Connect(function()
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end))

    local startTime = tick()

    -- Main logic loop
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        if not tRoot.Parent or tRoot.Position.Y > Config.DragHeight or tick() - startTime > CONSTANTS.ATTACK_TIMEOUT then
            State.IsAttacking = false
            CleanTable(State.Connections)
            CleanTable(State.PhysicsCache)
            RestoreCharacterState()
            
            -- Revert to Idle/AFK if toggles are still on
            if Config.AFK_Aura then ToggleConstraintAura(true, "AFK")
            elseif Config.AutoFling then ToggleConstraintAura(true, "IDLE") end
            return
        end

        local isMoving = IsMoving(tRoot.Velocity)
        bav.AngularVelocity = isMoving and Vector3.new(CONSTANTS.SPIN_POWER, CONSTANTS.SPIN_POWER, CONSTANTS.SPIN_POWER) or Vector3.new(0, CONSTANTS.SPIN_POWER, 0)

        if isMoving then
            -- Prediction
            local predictedPos = tRoot.Position + (tRoot.Velocity * CONSTANTS.PREDICT_TIME)
            root.CFrame = CFrame.new(predictedPos) * CFrame.Angles(math.random(-3,3), math.random(-3,3), math.random(-3,3))
            root.Velocity = Vector3.new(CONSTANTS.SPIN_POWER, CONSTANTS.SPIN_POWER, CONSTANTS.SPIN_POWER)
        else
            -- Skyhook
            root.CFrame = tRoot.CFrame * CFrame.new(0, -1.2, 0)
            root.Velocity = Vector3.new(0, CONSTANTS.SPIN_POWER, 0)
        end
    end))
end

----------------------------------------------------------------
-- 5. RUNTIME CONTROLLERS
----------------------------------------------------------------
-- Auto Hunter Thread
task.spawn(function()
    while task.wait(0.2) do
        if Config.AutoFling and not State.IsAttacking then
            for _, player in ipairs(Players:GetPlayers()) do
                if not Config.AutoFling then break end
                local tChar, tRoot = GetValidTarget(player)
                if tChar and tRoot.Position.Y < 300 then
                    ExecuteAttack(player)
                    break -- Lock on until resolved
                end
            end
            
            -- Nếu đang Auto mà không đánh ai -> Bật Idle Aura lơ lửng trên trời
            if not State.IsAttacking and #State.IdleInstances == 0 then
                ToggleConstraintAura(true, "IDLE")
            end
        end
    end
end)

----------------------------------------------------------------
-- 6. UI & BINDINGS
----------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Cinema Fling V21: Zenith",
   LoadingTitle = "Initializing Physics...",
   LoadingSubtitle = "Optimized by Engineering",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false,
})

local function SendNotify(title, content)
    Rayfield:Notify({Title = title, Content = content, Duration = 2})
end

local Tab = Window:CreateTab("Bảng Điều Khiển", 4483362458)
local TargetTab = Window:CreateTab("Hất Mục Tiêu", 4483362458)
local WhitelistTab = Window:CreateTab("Whitelist", 4483362458)

-- Control Tab
Tab:CreateToggle({
   Name = "BẬT AUTO FLING (Hunter Mode)",
   CurrentValue = false,
   Callback = function(Value)
       Config.AutoFling = Value
       if Value then
           Config.AFK_Aura = false
       else
           State.IsAttacking = false
           CleanTable(State.Connections)
           CleanTable(State.PhysicsCache)
           ToggleConstraintAura(false)
       end
   end,
})

Tab:CreateToggle({
   Name = "BẬT AFK AURA (Passive Fling)",
   CurrentValue = false,
   Callback = function(Value)
       Config.AFK_Aura = Value
       if Value then
           Config.AutoFling = false
           ToggleConstraintAura(true, "AFK")
           SendNotify("Aura Enabled", "Bạn đã được neo vị trí và trở thành máy xay.")
       else
           ToggleConstraintAura(false)
           SendNotify("Aura Disabled", "Trở lại bình thường.")
       end
   end,
})

Tab:CreateSlider({
   Name = "Độ Cao Cắt Hất (Studs)",
   Range = {100, 5000}, Increment = 100, CurrentValue = 1000,
   Callback = function(V) Config.DragHeight = V end,
})

-- Target Tab
local TargetOptions = {}
local TargetDropdown = TargetTab:CreateDropdown({
    Name = "Chọn Mục Tiêu", Options = {"..."}, CurrentOption = "...",
    Callback = function(Option)
        if Option[1] then Config.TargetSelect = Option[1]:match("@(.*)%)") end
    end,
})

local function RefreshDropdown(dropdown, excludeWl)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then 
            table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    dropdown:Refresh(list)
end

TargetTab:CreateButton({Name = "Làm Mới Danh Sách", Callback = function() RefreshDropdown(TargetDropdown) end})
TargetTab:CreateButton({
    Name = ">>> KẾT LIỄU MỤC TIÊU <<<",
    Callback = function()
        local target = Players:FindFirstChild(Config.TargetSelect or "")
        if target then
            SendNotify("Targeting", "Đang truy sát: " .. target.Name)
            ExecuteAttack(target)
        else
            SendNotify("Error", "Mục tiêu không hợp lệ!")
        end
    end,
})

-- Whitelist Tab
local WLDropdown = WhitelistTab:CreateDropdown({
   Name = "Chọn Người Né", Options = {"..."}, CurrentOption = "...",
   Callback = function(Option)
       if Option[1] then Config.SelectedWL = Option[1]:match("@(.*)%)") end
   end,
})

WhitelistTab:CreateButton({Name = "Làm Mới Danh Sách", Callback = function() RefreshDropdown(WLDropdown) end})
WhitelistTab:CreateButton({
   Name = "THÊM VÀO WHITELIST",
   Callback = function()
       local name = Config.SelectedWL
       if name and not IsWhitelisted(name) then
           table.insert(Config.Whitelist, name)
           SendNotify("Safe", "Đã bảo vệ: " .. name)
       end
   end,
})

WhitelistTab:CreateButton({
   Name = "Xóa Sạch Whitelist",
   Callback = function()
       table.clear(Config.Whitelist)
       SendNotify("Reset", "Đã xóa toàn bộ whitelist.")
   end
})

RefreshDropdown(TargetDropdown)
RefreshDropdown(WLDropdown)
Rayfield:LoadConfiguration()
