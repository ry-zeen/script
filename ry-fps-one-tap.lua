-- ═══════════════════════════════════════
-- RENXX — FPS ONE TAP v1.1
-- By: DEEP & RENXX
-- Library: Custom UI
-- ✅ 8 Bugs Fixed
-- ═══════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== EXECUTOR CHECK ====================
-- ✅ BUG #1 & #2 FIX: Cek support hookmetamethod & Drawing
local hasHook = (hookmetamethod ~= nil and newcclosure ~= nil and getnamecallmethod ~= nil)
local hasDrawing = pcall(function()
    local d = Drawing.new("Line")
    d:Remove()
end)

if not hasDrawing then
    warn("[RENXX] Executor gak support Drawing API. ESP visual akan dinonaktifkan.")
end
if not hasHook then
    warn("[RENXX] Executor gak support hookmetamethod. Silent Aim akan dinonaktifkan.")
end

-- ==================== SETTINGS ====================
local Settings = {
    MenuPosition = UDim2.new(0.02, 0, 0.83, 0),
    -- COMBAT
    SilentAim = true,
    Snapline = true,
    FOV = 100,
    AimbotCamera = false,
    AimSmooth = 5,
    AutoHeadshot = true,
    KillAll = false,
    FireDelay = 50,
    WallCheck = false,
    AliveCheck = true,
    -- VISUAL
    ESPLine = false,
    ESPName = true,
    ESPHealth = false,
    ESPSkeleton = true,
    ESPDistance = false,
    ESPBox = false,
    ESPTeamColor = Color3.fromRGB(0, 255, 0),
    ESPEnemyColor = Color3.fromRGB(255, 0, 0),
    ESPTextColor = Color3.fromRGB(255, 255, 255),
    ESPSkeletonColor = Color3.fromRGB(0, 255, 255),
    -- PLAYER
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    Fly = false,
    FlySpeed = 50,
    NoClip = false,
    GodMode = false,
    AntiFling = false,
    -- EXTRA
    Teleport = false,
    TeleportDelay = 5,  -- ✅ BUG #5 FIX: Setting buat delay
    AntiAFK = true,
}

-- ==================== SAVE/LOAD ====================
local function saveSettings()
    pcall(function()
        -- Konversi Color3 ke tabel biar bisa di-encode
        local toSave = {}
        for k, v in pairs(Settings) do
            if typeof(v) == "Color3" then
                toSave[k] = {_c3 = true, r = v.R, g = v.G, b = v.B}
            elseif typeof(v) == "UDim2" then
                toSave[k] = {_udim = true, xs = v.X.Scale, xo = v.X.Offset, ys = v.Y.Scale, yo = v.Y.Offset}
            else
                toSave[k] = v
            end
        end
        LocalPlayer:SetAttribute("RENXXSettings", HttpService:JSONEncode(toSave))
    end)
end

local function loadSettings()
    pcall(function()
        local data = LocalPlayer:GetAttribute("RENXXSettings")
        if data then
            local loaded = HttpService:JSONDecode(data)
            for k, v in pairs(loaded) do
                if type(v) == "table" then
                    if v._c3 then
                        Settings[k] = Color3.new(v.r, v.g, v.b)
                    elseif v._udim then
                        Settings[k] = UDim2.new(v.xs, v.xo, v.ys, v.yo)
                    else
                        Settings[k] = v
                    end
                else
                    Settings[k] = v
                end
            end
        end
    end)
end
loadSettings()

-- ==================== STATE ====================
local menuOpen = false
local target = { enabled = true, position = nil }
local lastShot = 0
local flyBV = nil
local flyBG = nil
local currentTarget = nil
local lastTeleport = 0
local VERTICAL_OFFSET = 40

-- ==================== FOV CIRCLE ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RENXXUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local circleFrame = Instance.new("Frame")
circleFrame.Parent = screenGui
circleFrame.BackgroundTransparency = 1
circleFrame.BorderSizePixel = 0
circleFrame.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
circleFrame.Position = UDim2.new(0.5, -Settings.FOV, 0.5, -Settings.FOV - VERTICAL_OFFSET)
circleFrame.Active = false
circleFrame.Selectable = false
circleFrame.Visible = true

local corner = Instance.new("UICorner")
corner.Parent = circleFrame
corner.CornerRadius = UDim.new(1, 0)

local stroke = Instance.new("UIStroke")
stroke.Parent = circleFrame
stroke.Color = Color3.fromRGB(255, 50, 50)
stroke.Thickness = 2
stroke.Transparency = 0.2

-- ==================== SNAPLINE ====================
local line
if hasDrawing then
    line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = Color3.fromRGB(255, 50, 50)
    line.Transparency = 0.4
    line.Visible = false
    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- ==================== SKELETON BONES ====================
local bonesR15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local bonesR6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local ESPData = {}

-- ✅ BUG #2 FIX: Semua drawing dibungkus cek
local function createLines()
    if not hasDrawing then return {} end
    local lines = {}
    for i = 1, 14 do
        local l = Drawing.new("Line")
        l.Thickness = 2
        l.Visible = false
        table.insert(lines, l)
    end
    return lines
end

local function createNameText()
    if not hasDrawing then return nil end
    local t = Drawing.new("Text")
    t.Size = 14
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Visible = false
    t.Font = 2
    return t
end

local function createBox()
    if not hasDrawing then return nil end
    local b = Drawing.new("Square")
    b.Thickness = 1
    b.Filled = false
    b.Visible = false
    return b
end

local function createHPBar()
    if not hasDrawing then return nil, nil end
    local bg = Drawing.new("Square")
    bg.Thickness = 1
    bg.Filled = true
    bg.Color = Color3.fromRGB(0, 0, 0)
    bg.Visible = false
    local bar = Drawing.new("Square")
    bar.Thickness = 1
    bar.Filled = true
    bar.Visible = false
    return bg, bar
end

local function createDistText()
    if not hasDrawing then return nil end
    local t = Drawing.new("Text")
    t.Size = 12
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Visible = false
    t.Font = 2
    return t
end

local function createLine()
    if not hasDrawing then return nil end
    local l = Drawing.new("Line")
    l.Thickness = 1
    l.Visible = false
    return l
end

local function createESP(player)
    if player == LocalPlayer or ESPData[player] then return end
    if not hasDrawing then return end
    local hpBG, hpBar = createHPBar()
    ESPData[player] = {
        Lines = createLines(),
        Name = createNameText(),
        Line = createLine(),
        Box = createBox(),
        HPBG = hpBG,
        HPBar = hpBar,
        Dist = createDistText(),
    }
end

local function updateESP()
    if not hasDrawing then return end
    for player, data in pairs(ESPData) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not hum or hum.Health <= 0 then
            for _, l in pairs(data.Lines or {}) do l.Visible = false end
            if data.Name then data.Name.Visible = false end
            if data.Line then data.Line.Visible = false end
            if data.Box then data.Box.Visible = false end
            if data.HPBG then data.HPBG.Visible = false end
            if data.HPBar then data.HPBar.Visible = false end
            if data.Dist then data.Dist.Visible = false end
        else
            local isTeam = player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
            local lineBoxColor = isTeam and Settings.ESPTeamColor or Settings.ESPEnemyColor

            -- SKELETON
            if Settings.ESPSkeleton then
                local useBones = bonesR15
                if char:FindFirstChild("Torso") and not char:FindFirstChild("UpperTorso") then
                    useBones = bonesR6
                end
                for i, bone in pairs(useBones) do
                    local p1 = char:FindFirstChild(bone[1])
                    local p2 = char:FindFirstChild(bone[2])
                    if p1 and p2 and data.Lines[i] then
                        local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                        if on1 and on2 then
                            data.Lines[i].From = Vector2.new(pos1.X, pos1.Y)
                            data.Lines[i].To = Vector2.new(pos2.X, pos2.Y)
                            data.Lines[i].Color = Settings.ESPSkeletonColor
                            data.Lines[i].Visible = true
                        else
                            data.Lines[i].Visible = false
                        end
                    else
                        if data.Lines[i] then data.Lines[i].Visible = false end
                    end
                end
            else
                for _, l in pairs(data.Lines or {}) do l.Visible = false end
            end

            -- NAME
            if Settings.ESPName and data.Name then
                local head = char:FindFirstChild("Head")
                if head then
                    local pos, on = Camera:WorldToViewportPoint(head.Position)
                    if on then
                        data.Name.Text = player.Name
                        data.Name.Position = Vector2.new(pos.X, pos.Y - 35)
                        data.Name.Color = Settings.ESPTextColor
                        data.Name.Visible = true
                    else
                        data.Name.Visible = false
                    end
                else
                    data.Name.Visible = false
                end
            elseif data.Name then
                data.Name.Visible = false
            end

            -- LINE + BOX + HP + DIST
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sp, on = Camera:WorldToViewportPoint(hrp.Position)
                if on then
                    if Settings.ESPLine and data.Line then
                        data.Line.Visible = true
                        data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        data.Line.To = Vector2.new(sp.X, sp.Y)
                        data.Line.Color = lineBoxColor
                    elseif data.Line then
                        data.Line.Visible = false
                    end

                    if Settings.ESPBox and data.Box then
                        data.Box.Visible = true
                        data.Box.Size = Vector2.new(50, 80)
                        data.Box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                        data.Box.Color = lineBoxColor
                    elseif data.Box then
                        data.Box.Visible = false
                    end

                    if Settings.ESPHealth and data.HPBG and data.HPBar then
                        local hpP = hum.Health / hum.MaxHealth
                        data.HPBG.Visible = true
                        data.HPBG.Size = Vector2.new(4, 40)
                        data.HPBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
                        data.HPBG.Filled = true
                        data.HPBar.Visible = true
                        data.HPBar.Size = Vector2.new(4, 40 * hpP)
                        data.HPBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hpP)))
                        data.HPBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hpP)
                        data.HPBar.Filled = true
                    else
                        if data.HPBG then data.HPBG.Visible = false end
                        if data.HPBar then data.HPBar.Visible = false end
                    end

                    if Settings.ESPDistance and data.Dist then
                        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                        data.Dist.Visible = true
                        data.Dist.Text = math.floor(dist) .. "m"
                        data.Dist.Position = Vector2.new(sp.X, sp.Y + 25)
                        data.Dist.Color = Settings.ESPTextColor
                    elseif data.Dist then
                        data.Dist.Visible = false
                    end
                else
                    if data.Line then data.Line.Visible = false end
                    if data.Box then data.Box.Visible = false end
                    if data.HPBG then data.HPBG.Visible = false end
                    if data.HPBar then data.HPBar.Visible = false end
                    if data.Dist then data.Dist.Visible = false end
                end
            end
        end
    end
end

local function removeESP(player)
    if ESPData[player] then
        for _, l in pairs(ESPData[player].Lines or {}) do pcall(function() l:Remove() end) end
        if ESPData[player].Name then pcall(function() ESPData[player].Name:Remove() end) end
        if ESPData[player].Line then pcall(function() ESPData[player].Line:Remove() end) end
        if ESPData[player].Box then pcall(function() ESPData[player].Box:Remove() end) end
        if ESPData[player].HPBG then pcall(function() ESPData[player].HPBG:Remove() end) end
        if ESPData[player].HPBar then pcall(function() ESPData[player].HPBar:Remove() end) end
        if ESPData[player].Dist then pcall(function() ESPData[player].Dist:Remove() end) end
        ESPData[player] = nil
    end
end

-- ==================== PLAYER MODS ====================
local function applyPlayerMods()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if hum.WalkSpeed ~= Settings.WalkSpeed then
        hum.WalkSpeed = Settings.WalkSpeed
    end
    if Settings.JumpPower ~= 50 then
        hum.UseJumpPower = true
        hum.JumpPower = Settings.JumpPower
    end
    if Settings.GodMode and hum.Parent and hum.Health > 0 then
        pcall(function()
            hum.MaxHealth = 99999
            hum.Health = 99999
        end)
    end
    if Settings.NoClip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end

-- ==================== FLY ====================
local function getMoveDirection()
    local camCF = Camera.CFrame
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
    if move.Magnitude > 0 then move = move.Unit * Settings.FlySpeed end
    return move
end

local function startFly()
    local char = LocalPlayer.Character
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
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    flyBV = nil
    flyBG = nil
end

-- ==================== WALL CHECK ====================
local function hasLineOfSight(targetPart)
    if not Settings.WallCheck then return true end
    local ok, result = pcall(function()
        local origin = Camera.CFrame.Position
        local direction = (targetPart.Position - origin)
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
        return hit == nil or hit:IsDescendantOf(targetPart.Parent)
    end)
    return ok and result or true
end

-- ==================== SILENT AIM ====================
-- ✅ BUG #4 FIX: Loop players, gak loop workspace
-- ✅ BUG #3 FIX: Support raycast & Raycast
-- ✅ BUG #6 FIX: AliveCheck dipakai
local function getClosestTarget()
    if not (Settings.SilentAim or Settings.AimbotCamera) then return nil end
    local bestPos = nil
    local bestDist = Settings.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2 - VERTICAL_OFFSET)

    -- Loop player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local part = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
            if hum and part then
                if not Settings.AliveCheck or hum.Health > 0 then
                    if hasLineOfSight(part) then
                        local sp, on = Camera:WorldToViewportPoint(part.Position)
                        if on then
                            local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                bestPos = part.Position
                            end
                        end
                    end
                end
            end
        end
    end

    -- Loop bot
    local botFolder = workspace:FindFirstChild("Game")
    if botFolder then botFolder = botFolder:FindFirstChild("__ServerBotCharacters") end
    if botFolder then
        for _, botChar in ipairs(botFolder:GetChildren()) do
            local hum = botChar:FindFirstChildOfClass("Humanoid")
            local part = botChar:FindFirstChild("Head") or botChar:FindFirstChild("HumanoidRootPart")
            if hum and part then
                if not Settings.AliveCheck or hum.Health > 0 then
                    if hasLineOfSight(part) then
                        local sp, on = Camera:WorldToViewportPoint(part.Position)
                        if on then
                            local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                bestPos = part.Position
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPos
end

-- ==================== KILL ALL ====================
local Shoot = nil
pcall(function()
    Shoot = ReplicatedStorage:WaitForChild("Blaster"):WaitForChild("Remotes"):WaitForChild("Shoot")
end)

local function getAllTargets()
    local targets = {}
    local seen = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h and (not Settings.AliveCheck or h.Health > 0) and not seen[h] then
                seen[h] = true
                table.insert(targets, h)
            end
        end
    end
    local botFolder = workspace:FindFirstChild("Game")
    if botFolder then botFolder = botFolder:FindFirstChild("__ServerBotCharacters") end
    if botFolder then
        for _, botChar in ipairs(botFolder:GetChildren()) do
            local h = botChar:FindFirstChildOfClass("Humanoid")
            if h and (not Settings.AliveCheck or h.Health > 0) and not seen[h] then
                seen[h] = true
                table.insert(targets, h)
            end
        end
    end
    return targets
end

local killAllIndex = 1
local function killAll()
    if not Shoot then return end
    local char = LocalPlayer.Character
    if not char then return end
    local blaster = char:FindFirstChild("Blaster") or char:FindFirstChildOfClass("Tool")
    if not blaster then return end
    local targets = getAllTargets()
    if #targets == 0 then return end
    if killAllIndex > #targets then killAllIndex = 1 end
    local t = targets[killAllIndex]
    killAllIndex = killAllIndex + 1

    pcall(function()
        Shoot:FireServer(workspace:GetServerTimeNow(), blaster, Camera.CFrame,
            { ["1"] = t }, { ["1"] = Settings.AutoHeadshot },
            { isQuickscope = false, isNoscope = true })
    end)
end

-- ==================== TELEPORT ====================
-- ✅ BUG #5 FIX: Pakai Settings.TeleportDelay
local function teleportToPlayer()
    if not Settings.Teleport then return end
    local now = tick()
    if now - lastTeleport < Settings.TeleportDelay then return end
    if currentTarget and currentTarget.Parent then
        local hum = currentTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return end
        currentTarget = nil
    else
        currentTarget = nil
    end
    local closest, shortest = nil, math.huge
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < shortest then
                    shortest = d
                    closest = p
                end
            end
        end
    end
    if closest and closest.Character then
        local targetHRP = closest.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
            currentTarget = closest
            lastTeleport = now
        end
    end
end

-- ==================== LOOPS ====================
RunService.RenderStepped:Connect(applyPlayerMods)
RunService.Heartbeat:Connect(applyPlayerMods)
RunService.RenderStepped:Connect(updateESP)

RunService.Heartbeat:Connect(function()
    -- FOV CIRCLE
    local radius = Settings.FOV
    circleFrame.Size = UDim2.new(0, radius * 2, 0, radius * 2)
    circleFrame.Position = UDim2.new(0.5, -radius, 0.5, -radius - VERTICAL_OFFSET)
    circleFrame.Visible = Settings.SilentAim or Settings.AimbotCamera
    if line then line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) end

    -- SILENT AIM
    if Settings.SilentAim then
        local pos = getClosestTarget()
        if pos then
            target.position = pos
            if Settings.Snapline and line then
                local sp, on = Camera:WorldToViewportPoint(pos)
                if on then
                    line.Visible = true
                    line.To = Vector2.new(sp.X, sp.Y)
                else
                    line.Visible = false
                end
            elseif line then
                line.Visible = false
            end
        else
            target.position = nil
            if line then line.Visible = false end
        end
    else
        target.position = nil
        if line then line.Visible = false end
    end

    -- AIMBOT CAMERA
    if Settings.AimbotCamera then
        local pos = getClosestTarget()
        if pos then
            local targetCF = CFrame.new(Camera.CFrame.Position, pos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(1, Settings.AimSmooth))
        end
    end

    -- KILL ALL
    if Settings.KillAll and tick() - lastShot >= (Settings.FireDelay / 1000) then
        killAll()
        lastShot = tick()
    end

    -- FLY
    if Settings.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then flyBG.CFrame = Camera.CFrame end
    end

    -- TELEPORT
    if Settings.Teleport then teleportToPlayer() end
end)

-- ==================== INFINITY JUMP ====================
UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==================== ANTI FLING ====================
RunService.Heartbeat:Connect(function()
    if Settings.AntiFling and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Velocity.Magnitude > 200 then hrp.Velocity = Vector3.zero end
    end
end)

-- ==================== ANTI AFK ====================
LocalPlayer.Idled:Connect(function()
    if Settings.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ==================== CHARACTER ADDED ====================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    flyBV = nil
    flyBG = nil
    currentTarget = nil
    if Settings.Fly then startFly() end
end)

-- ==================== SILENT AIM HOOK ====================
-- ✅ BUG #1 FIX: pcall + cek support
-- ✅ BUG #3 FIX: Support raycast & Raycast
local Hooks = {}
if hasHook then
    local ok, err = pcall(function()
        Hooks.Raycast = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            local methodLower = method:lower()
            if Settings.SilentAim and target.position and methodLower == "raycast" and self.Name == "Workspace" then
                local dir = (target.position - Camera.CFrame.Position).Unit * 200
                args[2] = dir
                return Hooks.Raycast(self, table.unpack(args))
            end
            return Hooks.Raycast(self, ...)
        end))
    end)
    if not ok then
        warn("[RENXX] Gagal hook __namecall: " .. tostring(err))
    end
end

-- ==================== PLAYER HANDLING ====================
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    createESP(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        removeESP(player)
        createESP(player)
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(removeESP)

-- ==================== UI ====================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = screenGui
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
toggleBtn.Position = Settings.MenuPosition
toggleBtn.Text = "R"
toggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 38
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.fromRGB(255, 50, 50)

local btnCorner = Instance.new("UICorner")
btnCorner.Parent = toggleBtn
btnCorner.CornerRadius = UDim.new(1, 0)

local dragging = false
local dragStart, startPos = nil, nil

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
    end
end)

toggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        Settings.MenuPosition = toggleBtn.Position
        saveSettings()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(
            math.clamp(startPos.X.Scale + delta.X / toggleBtn.Parent.AbsoluteSize.X, 0, 1 - 0.08), 0,
            math.clamp(startPos.Y.Scale + delta.Y / toggleBtn.Parent.AbsoluteSize.Y, 0, 1 - 0.08), 0)
    end
end)

-- ==================== MAIN FRAME ====================
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 300, 0, 420)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.Parent = mainFrame
mainCorner.CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 5)
title.Text = "RENXX"
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = mainFrame
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundTransparency = 1
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    menuOpen = false
end)

-- ==================== TABS ====================
local tabFrame = Instance.new("Frame")
tabFrame.Parent = mainFrame
tabFrame.Size = UDim2.new(1, -20, 0, 35)
tabFrame.Position = UDim2.new(0.025, 0, 0, 48)
tabFrame.BackgroundTransparency = 1

local function createTab(text, position)
    local btn = Instance.new("TextButton")
    btn.Parent = tabFrame
    btn.Size = UDim2.new(0.24, 0, 1, 0)
    btn.Position = UDim2.new(position, 0, 0, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.BackgroundTransparency = 0.4
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.Parent = btn
    c.CornerRadius = UDim.new(0, 8)
    return btn
end

local tabCombat = createTab("COMBAT", 0)
local tabVisual = createTab("VISUAL", 0.26)
local tabPlayer = createTab("PLAYER", 0.52)
local tabExtra = createTab("EXTRA", 0.78)

-- ==================== CONTENT ====================
local contentFrame = Instance.new("Frame")
contentFrame.Parent = mainFrame
contentFrame.Size = UDim2.new(1, -20, 1, -105)
contentFrame.Position = UDim2.new(0.025, 0, 0, 88)
contentFrame.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame")
scroll.Parent = contentFrame
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 500)
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50)

local combatContent = Instance.new("Frame")
combatContent.Parent = scroll
combatContent.Size = UDim2.new(1, 0, 0, 500)
combatContent.BackgroundTransparency = 1

local visualContent = Instance.new("Frame")
visualContent.Parent = scroll
visualContent.Size = UDim2.new(1, 0, 0, 500)
visualContent.BackgroundTransparency = 1
visualContent.Visible = false

local playerContent = Instance.new("Frame")
playerContent.Parent = scroll
playerContent.Size = UDim2.new(1, 0, 0, 500)
playerContent.BackgroundTransparency = 1
playerContent.Visible = false

local extraContent = Instance.new("Frame")
extraContent.Parent = scroll
extraContent.Size = UDim2.new(1, 0, 0, 500)
extraContent.BackgroundTransparency = 1
extraContent.Visible = false

-- ==================== UI HELPERS ====================
local function makeToggle(parent, text, y, key, default)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Size = UDim2.new(0.18, 0, 0.75, 0)
    btn.Position = UDim2.new(0.8, 0, 0.125, 0)
    btn.Text = default and "ON" or "OFF"
    btn.BackgroundColor3 = default and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(60, 60, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.Parent = btn
    c.CornerRadius = UDim.new(0, 12)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(60, 60, 70)
        Settings[key] = state
        saveSettings()
    end)
end

local function makeSlider(parent, text, y, key, default, min, max)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local slider = Instance.new("Frame")
    slider.Parent = frame
    slider.Size = UDim2.new(1, 0, 0, 6)
    slider.Position = UDim2.new(0, 0, 0, 28)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    slider.BorderSizePixel = 0

    local fill = Instance.new("Frame")
    fill.Parent = slider
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    fill.BorderSizePixel = 0

    local handle = Instance.new("TextButton")
    handle.Parent = slider
    handle.Size = UDim2.new(0, 22, 0, 22)
    handle.Position = UDim2.new((default - min) / (max - min), -11, -0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.Text = ""
    handle.BorderSizePixel = 0
    local hc = Instance.new("UICorner")
    hc.Parent = handle
    hc.CornerRadius = UDim.new(1, 0)

    local value = default
    local dragging2 = false

    local function update(posX)
        local relX = posX - slider.AbsolutePosition.X
        local width = slider.AbsoluteSize.X
        if width == 0 then return end
        local pos = math.clamp(relX / width, 0, 1)
        value = min + (max - min) * pos
        value = math.floor(value * 10) / 10
        fill.Size = UDim2.new(pos, 0, 1, 0)
        handle.Position = UDim2.new(pos, -11, -0.5, -8)
        label.Text = text .. ": " .. tostring(value)
        Settings[key] = value
        saveSettings()
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging2 = true
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging2 = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            update(input.Position.X)
        end
    end)
end

local function makeColorPicker(parent, text, y, key, default)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local picker = Instance.new("TextButton")
    picker.Parent = frame
    picker.Size = UDim2.new(0.12, 0, 0.8, 0)
    picker.Position = UDim2.new(0.6, 0, 0.1, 0)
    picker.BackgroundColor3 = default
    picker.Text = ""
    picker.BorderSizePixel = 1
    picker.BorderColor3 = Color3.fromRGB(255, 255, 255)
    local pc = Instance.new("UICorner")
    pc.Parent = picker
    pc.CornerRadius = UDim.new(0, 4)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = frame
    nameLabel.Size = UDim2.new(0.25, 0, 1, 0)
    nameLabel.Position = UDim2.new(0.74, 0, 0, 0)
    nameLabel.Text = "Red"
    nameLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 11

    local colors = {
        Red = Color3.fromRGB(255, 0, 0),
        Green = Color3.fromRGB(0, 255, 0),
        Blue = Color3.fromRGB(0, 0, 255),
        Yellow = Color3.fromRGB(255, 255, 0),
        Purple = Color3.fromRGB(255, 0, 255),
        Cyan = Color3.fromRGB(0, 255, 255),
        White = Color3.fromRGB(255, 255, 255),
        Orange = Color3.fromRGB(255, 165, 0),
        Pink = Color3.fromRGB(255, 105, 180),
    }
    local colorNames = {"Red", "Green", "Blue", "Yellow", "Purple", "Cyan", "White", "Orange", "Pink"}
    local idx = 1
    for i, name in ipairs(colorNames) do
        if colors[name] == default then
            idx = i
            break
        end
    end
    nameLabel.Text = colorNames[idx]

    picker.MouseButton1Click:Connect(function()
        idx = idx % #colorNames + 1
        local name = colorNames[idx]
        picker.BackgroundColor3 = colors[name]
        nameLabel.Text = name
        Settings[key] = colors[name]
        saveSettings()
    end)
end

-- ==================== BUILD COMBAT TAB ====================
local cy = 5
makeToggle(combatContent, "Silent Aim", cy, "SilentAim", Settings.SilentAim); cy = cy + 38
makeToggle(combatContent, "Snapline", cy, "Snapline", Settings.Snapline); cy = cy + 38
makeToggle(combatContent, "Aimbot Camera", cy, "AimbotCamera", Settings.AimbotCamera); cy = cy + 38
makeToggle(combatContent, "Auto Headshot", cy, "AutoHeadshot", Settings.AutoHeadshot); cy = cy + 38
makeToggle(combatContent, "Kill All", cy, "KillAll", Settings.KillAll); cy = cy + 38
makeToggle(combatContent, "Wall Check", cy, "WallCheck", Settings.WallCheck); cy = cy + 38
makeToggle(combatContent, "Alive Check", cy, "AliveCheck", Settings.AliveCheck); cy = cy + 45
makeSlider(combatContent, "FOV", cy, "FOV", Settings.FOV, 30, 300); cy = cy + 55
makeSlider(combatContent, "Aim Smoothness", cy, "AimSmooth", Settings.AimSmooth, 1, 15); cy = cy + 55
makeSlider(combatContent, "Fire Delay (ms)", cy, "FireDelay", Settings.FireDelay, 1, 200); cy = cy + 55
combatContent.Size = UDim2.new(1, 0, 0, cy + 20)

-- ==================== BUILD VISUAL TAB ====================
local vy = 5
makeToggle(visualContent, "ESP Line", vy, "ESPLine", Settings.ESPLine); vy = vy + 38
makeToggle(visualContent, "ESP Name", vy, "ESPName", Settings.ESPName); vy = vy + 38
makeToggle(visualContent, "ESP Health", vy, "ESPHealth", Settings.ESPHealth); vy = vy + 38
makeToggle(visualContent, "ESP Skeleton", vy, "ESPSkeleton", Settings.ESPSkeleton); vy = vy + 38
makeToggle(visualContent, "ESP Distance", vy, "ESPDistance", Settings.ESPDistance); vy = vy + 38
makeToggle(visualContent, "ESP Box", vy, "ESPBox", Settings.ESPBox); vy = vy + 45
makeColorPicker(visualContent, "Line + Box Team Color", vy, "ESPTeamColor", Settings.ESPTeamColor); vy = vy + 38
makeColorPicker(visualContent, "Line + Box Enemy Color", vy, "ESPEnemyColor", Settings.ESPEnemyColor); vy = vy + 38
makeColorPicker(visualContent, "Text Color", vy, "ESPTextColor", Settings.ESPTextColor); vy = vy + 38
makeColorPicker(visualContent, "Skeleton Color", vy, "ESPSkeletonColor", Settings.ESPSkeletonColor); vy = vy + 45
visualContent.Size = UDim2.new(1, 0, 0, vy + 20)

-- ==================== BUILD PLAYER TAB ====================
local py = 5
makeSlider(playerContent, "Walk Speed", py, "WalkSpeed", Settings.WalkSpeed, 16, 100); py = py + 55
makeSlider(playerContent, "Jump Power", py, "JumpPower", Settings.JumpPower, 50, 300); py = py + 55
makeToggle(playerContent, "Infinity Jump", py, "InfJump", Settings.InfJump); py = py + 38
makeToggle(playerContent, "Fly", py, "Fly", Settings.Fly); py = py + 38
makeSlider(playerContent, "Fly Speed", py, "FlySpeed", Settings.FlySpeed, 10, 300); py = py + 55
makeToggle(playerContent, "No Clip", py, "NoClip", Settings.NoClip); py = py + 38
makeToggle(playerContent, "God Mode", py, "GodMode", Settings.GodMode); py = py + 38
makeToggle(playerContent, "Anti Fling", py, "AntiFling", Settings.AntiFling); py = py + 38
playerContent.Size = UDim2.new(1, 0, 0, py + 20)

-- ==================== BUILD EXTRA TAB ====================
local ey = 5
makeToggle(extraContent, "Teleport To Player", ey, "Teleport", Settings.Teleport); ey = ey + 38
makeSlider(extraContent, "Teleport Delay (s)", ey, "TeleportDelay", Settings.TeleportDelay, 1, 30); ey = ey + 55
makeToggle(extraContent, "Anti AFK", ey, "AntiAFK", Settings.AntiAFK); ey = ey + 38
extraContent.Size = UDim2.new(1, 0, 0, ey + 20)

-- ==================== TAB SWITCHING ====================
local function switchTab(activeTab, content)
    combatContent.Visible = false
    visualContent.Visible = false
    playerContent.Visible = false
    extraContent.Visible = false
    content.Visible = true

    tabCombat.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    tabVisual.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    tabPlayer.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    tabExtra.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    activeTab.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
end

tabCombat.MouseButton1Click:Connect(function() switchTab(tabCombat, combatContent) end)
tabVisual.MouseButton1Click:Connect(function() switchTab(tabVisual, visualContent) end)
tabPlayer.MouseButton1Click:Connect(function() switchTab(tabPlayer, playerContent) end)
tabExtra.MouseButton1Click:Connect(function() switchTab(tabExtra, extraContent) end)
switchTab(tabCombat, combatContent)

-- ==================== TOGGLE MENU ====================
toggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    mainFrame.Visible = menuOpen
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        menuOpen = not menuOpen
        mainFrame.Visible = menuOpen
    end
end)

-- ==================== NOTIFIKASI ====================
print("═══════════════════════════════════════")
print("RENXX — FPS ONE TAP v1.1")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Tabs: COMBAT | VISUAL | PLAYER | EXTRA")
print("By DEEP & RENXX")
print("═══════════════════════════════════════")
