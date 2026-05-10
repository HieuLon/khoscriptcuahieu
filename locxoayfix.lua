--[[ 
    PHANTOM WALKFLING
    - Hoạt động ngầm: Đi bộ bình thường, không dùng BodyMovers.
    - Kỹ thuật: Spike Angular Velocity (Bơm lực xoay 1 frame khi có va chạm).
    - An toàn: Buff Mass (Density 100), xóa ma sát, Smart Noclip.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local WalkFlingEnabled = true -- Đổi thành false để tắt
local FlingRadius = 3.5 -- Bán kính kích hoạt (studs)
local FlingForce = Vector3.new(50000, 50000, 50000) -- Lực xoay cực đại

-- Biến lưu trữ trạng thái vật lý gốc để trả lại khi tắt
local OriginalProperties = {}

----------------------------------------------------------------
-- BƯỚC 4: CHỐNG TỰ HỦY (MASS & SMART NOCLIP)
----------------------------------------------------------------
local function OptimizePhysics()
    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        -- Lưu lại thuộc tính gốc nếu chưa lưu
        if not OriginalProperties[root] then
            OriginalProperties[root] = root.CustomPhysicalProperties or PhysicalProperties.new(root.Material)
        end
        -- Tăng Density lên tối đa (100) để nặng như tạ, ma sát = 0
        root.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 0, 0)
    end

    -- Smart Noclip: Tắt va chạm Tay, Chân, Đầu. Giữ lại Torso và HRP
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local isCorePart = part.Name == "HumanoidRootPart" or string.find(part.Name, "Torso")
            if not isCorePart then
                part.CanCollide = false
            end
        end
    end
end

----------------------------------------------------------------
-- BƯỚC 2: SPIKE VELOCITY (GIA TỐC CHỚP NHOÁNG)
----------------------------------------------------------------
local function CheckAndFling()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local targetFound = false

    -- Quét các người chơi khác
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (myRoot.Position - targetRoot.Position).Magnitude
                
                -- Nếu đối phương lọt vào bán kính
                if distance <= FlingRadius then
                    targetFound = true
                    break -- Chỉ cần 1 mục tiêu là đủ kích hoạt lực xoay
                end
            end
        end
    end

    if targetFound then
        -- Bơm Lực Xoay Khổng Lồ (AssemblyAngularVelocity) trong 1 frame
        -- Dùng lực xoay an toàn hơn lực đẩy thẳng (Linear), tránh việc bạn bị giật lùi xuyên tường
        myRoot.AssemblyAngularVelocity = FlingForce
    else
        -- Ngay khi không có ai, hoặc sau 1 frame va chạm, reset lực về 0 ngay lập tức
        -- Giúp bạn không bị văng đi và giữ hoạt ảnh đi bộ bình thường
        if myRoot.AssemblyAngularVelocity.Magnitude > 50 then
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

----------------------------------------------------------------
-- KHỞI CHẠY VÒNG LẶP (HEARTBEAT)
----------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    if WalkFlingEnabled then
        OptimizePhysics() -- Liên tục ép Noclip để tránh bị game override lại
        CheckAndFling()   -- Quét và Fling
    end
end)

print("Phantom Walkfling Loaded! Cứ đi bộ đâm vào người khác để xem ảo thuật.")
