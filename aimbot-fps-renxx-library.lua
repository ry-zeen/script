-- ========================================
-- RENXX AIMBOT FPS v2
-- Powered by RENXX UI
-- 15 Fitur: Combat + Visual + Movement + Misc
-- ========================================

local RENXX = loadstring(game:HttpGet("https://raw.githubusercontent.com/ry-zeen/menu/main/rx-library-v1.0.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================================
-- SAFE REMOTE LOAD
-- ========================================
local Shoot
pcall(function()
    local blaster = ReplicatedStorage:WaitForChild("Blaster", 10)
    if blaster then
        local remotes = blaster:WaitForChild("Remotes", 5)
        if remotes then
            Shoot = remotes:WaitForChild("Shoot", 5)
        end
    end
end)

if not Shoot then
    warn("[RENXX] Remote 'Shoot' gak ketemu. Fitur Tag All mungkin gak jalan.")
end

-- ========================================
-- STATE (15 FITUR)
-- ========================================
local S = {
    -- COMBAT
    TagAll = false,           -- 1
    FireDelay = 50,           -- 2
    Aimbot = false,           -- 3
    AimSmooth = 5,            -- 4
    AimFOV = 90,              -- 5
    AimPart = "Head",         -- 6
    -- VISUAL
    ShowFOV = false,          -- 7
    FOVColor = Color3.fromRGB(235, 60, 100), -- 8
    ESPBox = false,           -- 9
    ESPName = false,          -- 10
    ESPDistance = false,      -- 11
    -- MOVEMENT
    Fly = false,              -- 12
    FlySpeed = 50,            -- 13
    -- MISC
    Fullbright = false,       -- 14
    AntiAfk = true,           -- 15
}

local lastShot = 0
local targetIndex = 1
local flyBV, flyBG
local origBrightness, origAmbient, origOutdoor

-- ========================================
-- HELPER
-- ========================================
local function getBlaster()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChild("Blaster") or char:FindFirstChildOfClass("Tool")
end

local function getAllTargets()
    local targets = {}
    local seen = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not seen[h] then
                seen[h] = true
                table.insert(targets, h)
            end
        end
    end
    local gameFolder = Workspace:FindFirstChild("Game")
    if gameFolder then
        local botFolder = gameFolder:FindFirstChild("__ServerBotCharacters")
        if botFolder then
            for _, botChar in ipairs(botFolder:GetChildren()) do
                local h = botChar:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 and not seen[h] then
                    seen[h] = true
                    table.insert(targets, h)
                end
            end
        end
    end
    return targets
end

local function getPart(char, partName)
    if not char then return nil end
    if partName == "Head" then
        return char:FindFirstChild("Head")
    elseif partName == "Body" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    elseif partName == "Nearest" then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("Head")
end

-- ========================================
-- FITUR 1-2: TAG ALL + FIRE DELAY
-- ========================================
local function tagEveryone()
    if not Shoot then return end
    local blaster = getBlaster()
    if not blaster then return end
    local targets = getAllTargets()
    if #targets == 0 then return end
    if targetIndex > #targets then targetIndex = 1 end
    local currentTarget = targets[targetIndex]
    targetIndex += 1
    if not currentTarget or currentTarget.Health <= 0 then return end
    local hits = { ["1"] = currentTarget }
    local headshots = { ["1"] = true }
    pcall(function()
        Shoot:FireServer(Workspace:GetServerTimeNow(), blaster, Camera.CFrame, hits, headshots, {
            isQuickscope = false, isNoscope = true
        })
    end)
end

-- ========================================
-- FITUR 3-6: AIMBOT
-- ========================================
local function getClosestTarget()
    local closest, closestDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = getPart(char, S.AimPart)
        if not part then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < S.AimFOV and dist < closestDist then
            closest = part
            closestDist = dist
        end
    end
    return closest
end

-- ========================================
-- FITUR 7-8: FOV CIRCLE
-- ========================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Transparency = 1
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    if not fovCircle then return end
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = S.ShowFOV
    fovCircle.Color = S.FOVColor
    fovCircle.Radius = math.tan(math.rad(S.AimFOV / 2)) * (Camera.ViewportSize.Y / 2) / math.tan(math.rad(Camera.FieldOfView / 2))
end)

-- ========================================
-- FITUR 9-11: ESP
-- ========================================
local ESP = {}

local function createESP(player)
    if player == LP then return end
    if ESP[player] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1.5 box.Filled = false box.Visible = false
    local name = Drawing.new("Text")
    name.Size = 14 name.Center = true name.Outline = true name.Visible = false
    local dist = Drawing.new("Text")
    dist.Size = 12 dist.Center = true dist.Outline = true dist.Visible = false
    ESP[player] = {box = box, name = name, dist = dist}
end

local function removeESP(player)
    local e = ESP[player]
    if e then
        for _, obj in pairs(e) do pcall(function() obj:Remove() end) end
        ESP[player] = nil
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.5) createESP(p) end)
end)
Players.PlayerRemoving:Connect(removeESP)
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end

-- ========================================
-- FITUR 12-13: FLY
-- ========================================
local function getMoveDirection()
    local camCF = Camera.CFrame
    local move = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
    if move.Magnitude > 0 then move = move.Unit * S.FlySpeed end
    return move
end

local function startFly()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.P = 1e5
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 1e5
    flyBG.CFrame = Camera.CFrame
    flyBG.Parent = root
end

local function stopFly()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

-- ========================================
-- WINDOW
-- ========================================
local Win = RENXX:CreateWindow({
    Name = "RENXX Aimbot FPS v2",
    Badge = "15 FITUR",
    Accent = Color3.fromRGB(235, 60, 100),
})

-- ========================================
-- TAB COMBAT (6 fitur)
-- ========================================
local CombatTab = Win:CreateTab("COMBAT", "⚔")

CombatTab:CreateSection("Auto Tag")

CombatTab:CreateToggle({
    Name = "1. Tag All (Auto Shoot)",
    Default = false,
    Flag = "tag_all",
    Callback = function(v) S.TagAll = v end,
})

CombatTab:CreateSlider({
    Name = "2. Fire Delay",
    Min = 1, Max = 200, Default = 50,
    Suffix = "ms",
    Flag = "fire_delay",
    Callback = function(v) S.FireDelay = v end,
})

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "3. Aimbot (Hold Right Click)",
    Default = false,
    Flag = "aimbot",
    Callback = function(v) S.Aimbot = v end,
})

CombatTab:CreateSlider({
    Name = "4. Aim Smoothness",
    Min = 0, Max = 15, Default = 5,
    Suffix = "×",
    Flag = "aim_smooth",
    Callback = function(v) S.AimSmooth = v end,
})

CombatTab:CreateSlider({
    Name = "5. Aim FOV",
    Min = 10, Max = 360, Default = 90,
    Suffix = "°",
    Flag = "aim_fov",
    Callback = function(v) S.AimFOV = v end,
})

CombatTab:CreateDropdown({
    Name = "6. Aim Part",
    Options = {"Head", "Body", "Nearest"},
    Default = "Head",
    Flag = "aim_part",
    Callback = function(v) S.AimPart = v end,
})

-- ========================================
-- TAB VISUAL (5 fitur)
-- ========================================
local VisualTab = Win:CreateTab("VISUAL", "👁")

VisualTab:CreateSection("FOV Circle")

VisualTab:CreateToggle({
    Name = "7. Show FOV Circle",
    Default = false,
    Flag = "show_fov",
    Callback = function(v) S.ShowFOV = v end,
})

VisualTab:CreateColorPicker({
    Name = "8. FOV Color",
    Default = Color3.fromRGB(235, 60, 100),
    Flag = "fov_color",
    Callback = function(c) S.FOVColor = c end,
})

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "9. ESP Box",
    Default = false,
    Flag = "esp_box",
    Callback = function(v) S.ESPBox = v end,
})

VisualTab:CreateToggle({
    Name = "10. ESP Name",
    Default = false,
    Flag = "esp_name",
    Callback = function(v) S.ESPName = v end,
})

VisualTab:CreateToggle({
    Name = "11. ESP Distance",
    Default = false,
    Flag = "esp_dist",
    Callback = function(v) S.ESPDistance = v end,
})

-- ========================================
-- TAB MOVEMENT (2 fitur)
-- ========================================
local MoveTab = Win:CreateTab("MOVEMENT", "🏃")

MoveTab:CreateSection("Fly")

MoveTab:CreateToggle({
    Name = "12. Noclip Fly",
    Default = false,
    Flag = "fly",
    Callback = function(v)
        S.Fly = v
        if v then startFly() else stopFly() end
    end,
})

MoveTab:CreateSlider({
    Name = "13. Fly Speed",
    Min = 10, Max = 300, Default = 50,
    Flag = "fly_speed",
    Callback = function(v) S.FlySpeed = v end,
})

-- ========================================
-- TAB MISC (2 fitur)
-- ========================================
local MiscTab = Win:CreateTab("MISC", "🔧")

MiscTab:CreateSection("Lighting")

MiscTab:CreateToggle({
    Name = "14. Fullbright",
    Default = false,
    Flag = "fullbright",
    Callback = function(v)
        S.Fullbright = v
        if v then
            origBrightness = origBrightness or Lighting.Brightness
            origAmbient = origAmbient or Lighting.Ambient
            origOutdoor = origOutdoor or Lighting.OutdoorAmbient
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(200,200,200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
        else
            if origBrightness then Lighting.Brightness = origBrightness end
            if origAmbient then Lighting.Ambient = origAmbient end
            if origOutdoor then Lighting.OutdoorAmbient = origOutdoor end
        end
    end,
})

MiscTab:CreateSection("Utility")

MiscTab:CreateToggle({
    Name = "15. Anti-AFK",
    Default = true,
    Flag = "antiafk",
    Callback = function(v) S.AntiAfk = v end,
})

-- ========================================
-- KEYBINDS
-- ========================================
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        S.TagAll = not S.TagAll
        RENXX:Notify({Title = "Tag All", Text = S.TagAll and "ON" or "OFF", Duration = 1.5})
    elseif input.KeyCode == Enum.KeyCode.G then
        S.Fly = not S.Fly
        if S.Fly then startFly() else stopFly() end
        RENXX:Notify({Title = "Fly", Text = S.Fly and "ON" or "OFF", Duration = 1.5})
    end
end)

-- ========================================
-- MAIN LOOPS
-- ========================================
RunService.Heartbeat:Connect(function()
    -- FLY
    if S.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then flyBG.CFrame = Camera.CFrame end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
    -- TAG ALL
    if S.TagAll and os.clock() - lastShot >= (S.FireDelay / 1000) then
        tagEveryone()
        lastShot = os.clock()
    end
    -- AIMBOT
    if S.Aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestTarget()
        if target then
            local targetCF = CFrame.new(Camera.CFrame.Position, target.Position)
            local smooth = S.AimSmooth > 0 and S.AimSmooth or 1
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / smooth)
        end
    end
end)

-- ========================================
-- ESP LOOP
-- ========================================
RunService.RenderStepped:Connect(function()
    for player, e in pairs(ESP) do
        local char = player.Character
        if not char then
            if e.box then e.box.Visible = false end
            if e.name then e.name.Visible = false end
            if e.dist then e.dist.Visible = false end
            continue
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            if e.box then e.box.Visible = false end
            if e.name then e.name.Visible = false end
            if e.dist then e.dist.Visible = false end
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local topPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
        local botPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        if onScreen and distance < 1000 then
            local boxHeight = botPos.Y - topPos.Y
            local boxWidth = boxHeight / 2.5
            if e.box then
                e.box.Visible = S.ESPBox
                e.box.Color = S.FOVColor
                e.box.Size = Vector2.new(boxWidth, boxHeight)
                e.box.Position = Vector2.new(pos.X - boxWidth/2, topPos.Y)
            end
            if e.name then
                e.name.Visible = S.ESPName
                e.name.Color = S.FOVColor
                e.name.Text = player.Name
                e.name.Position = Vector2.new(pos.X, topPos.Y - 18)
            end
            if e.dist then
                e.dist.Visible = S.ESPDistance
                e.dist.Color = S.FOVColor
                e.dist.Text = math.floor(distance) .. "m"
                e.dist.Position = Vector2.new(pos.X, botPos.Y + 8)
            end
        else
            if e.box then e.box.Visible = false end
            if e.name then e.name.Visible = false end
            if e.dist then e.dist.Visible = false end
        end
    end
end)

-- ========================================
-- ANTI-AFK LOOP
-- ========================================
LP.Idled:Connect(function()
    if S.AntiAfk then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

-- ========================================
-- RESPAWN HANDLER
-- ========================================
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    flyBV = nil
    flyBG = nil
    if S.Fly then startFly() end
end)

-- ========================================
-- NOTIF
-- ========================================
RENXX:Notify({
    Title = "RENXX Aimbot FPS v2",
    Text = "15 fitur loaded! RightShift buat buka menu.",
    Duration = 4,
})

print("[RENXX Aimbot FPS v2] Loaded! 15 fitur.")
