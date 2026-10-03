--[[
    ═══════════════════════════════════════════════
    RENXX HUB v4.2 | FPS One Tap (FIXED)
    By: RENXX | Depy is God
    ═══════════════════════════════════════════════
    Hook: Vodka (raycast) - Silent Aim
    Changelog v4.2:
    - FIX: Fly delay 0.5s → instant
    - FIX: Fly nggak stop pas mati
    - FIX: saveSettings debounce (1 detik)
    - FIX: Camera auto-update
    - FIX: Hook handle FindPartOnRay
    - FIX: Raycast preserve length
    - FIX: ESP MaxDistance slider
    - FIX: BOT ESP (auto-hapus pas mati)
    - FIX: Warna load dari Settings
    - FIX: Toggle sinkron Settings
    - FIX: Noclip balikin collide
    - FIX: Title auto-scale
    ═══════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════ GUARDS ═══════════════
local hasHook = pcall(function()
    return hookmetamethod and getrawmetatable and setreadonly
end)

local hasDrawing = pcall(function()
    local d = Drawing.new("Text")
    d:Remove()
end)

local newcclosure = newcclosure or function(f) return f end
local getnamecallmethod = getnamecallmethod or function() return "" end

if not hasDrawing then
    warn("[RENXX v4.2] Executor nggak support Drawing API!")
end

-- ═══════════════ SETTINGS ═══════════════
local Settings = {
    -- Visual
    ESP_Name = true, ESP_Health = true, ESP_Skeleton = true,
    ESP_Distance = true, ESP_Box = true,
    ESP_LinePlayer = false, ESP_LineBOT = false,
    MaxDistance = 1000,
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    SkeletonColor = Color3.fromRGB(255, 255, 0),
    BoxColor = Color3.fromRGB(255, 0, 0),
    LinePlayerColor = Color3.fromRGB(0, 255, 0),
    LineBOTColor = Color3.fromRGB(255, 255, 0),

    -- Combat
    SilentAim = true, POV = 100, ShowPOV = true,
    POVColor = Color3.fromRGB(255, 255, 255),
    SnapLine = true, SnapLineColor = Color3.fromRGB(0, 255, 0),
    AimPart = "Head", TeamCheck = true, WallCheck = true,

    -- Player
    SpeedValue = 16,
    JumpValue = 50,
    InfiniteJump = false, Noclip = false,
    Fly = false, FlySpeed = 50,

    -- Menu
    MenuPosition = UDim2.new(1, -80, 1, -80),
}

-- ═══════════════ SAVE/LOAD (FIX #3: debounce) ═══════════════
local lastSave = 0
local function saveSettings()
    if os.clock() - lastSave < 1 then return end
    lastSave = os.clock()
    pcall(function()
        LocalPlayer:SetAttribute("RENXXSettings", HttpService:JSONEncode(Settings))
    end)
end

local function loadSettings()
    pcall(function()
        local data = LocalPlayer:GetAttribute("RENXXSettings")
        if data then
            local loaded = HttpService:JSONDecode(data)
            for k, v in pairs(loaded) do
                if Settings[k] ~= nil then
                    if typeof(Settings[k]) == "Color3" and typeof(v) == "table" then
                        Settings[k] = Color3.new(v.R or v[1], v.G or v[2], v.B or v[3])
                    else
                        Settings[k] = v
                    end
                end
            end
        end
    end)
end
loadSettings()

-- ═══════════════ CAMERA AUTO-UPDATE (FIX #4) ═══════════════
task.spawn(function()
    while task.wait(1) do
        if Camera ~= workspace.CurrentCamera then
            Camera = workspace.CurrentCamera
        end
    end
end)

-- ═══════════════ HELPERS ═══════════════
local function isSameTeam(player)
    if not Settings.TeamCheck then return false end
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function isVisible(part)
    if not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ig = {}
    if LocalPlayer.Character then table.insert(ig, LocalPlayer.Character) end
    table.insert(ig, Camera)
    params.FilterDescendantsInstances = ig
    local r = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    if not r then return true end
    return r.Instance == part or r.Instance:IsDescendantOf(part.Parent)
end

local function fovToRadius(fov)
    return math.tan(math.rad(fov / 2)) * (Camera.ViewportSize.Y / 2)
end

local function getBotFolder()
    local gameFolder = workspace:FindFirstChild("Game")
    if gameFolder then
        return gameFolder:FindFirstChild("__ServerBotCharacters")
    end
    return nil
end

-- ═══════════════ DRAWINGS ═══════════════
local snapLine, povCircle
if hasDrawing then
    pcall(function()
        snapLine = Drawing.new("Line")
        snapLine.Thickness = 2
        snapLine.Visible = false

        povCircle = Drawing.new("Circle")
        povCircle.Thickness = 2
        povCircle.NumSides = 64
        povCircle.Filled = false
        povCircle.Visible = false
    end)
end

-- ═══════════════ ESP SETUP ═══════════════
local ESPData = {}
local botESPData = {}

local function createESPContainer(container, key)
    if not hasDrawing then return end
    if container[key] then return end
    pcall(function()
        container[key] = {
            Line = Drawing.new("Line"),
            Name = Drawing.new("Text"),
            HealthBG = Drawing.new("Square"),
            HealthBar = Drawing.new("Square"),
            Distance = Drawing.new("Text"),
            Box = Drawing.new("Square"),
            Skeleton = {},
        }
        local d = container[key]
        d.Line.Thickness = 1; d.Line.Visible = false
        d.Name.Size = 14; d.Name.Center = true; d.Name.Outline = true; d.Name.Font = 2; d.Name.Visible = false
        d.Distance.Size = 12; d.Distance.Center = true; d.Distance.Outline = true; d.Distance.Font = 2; d.Distance.Visible = false
        d.HealthBG.Filled = true; d.HealthBG.Color = Color3.fromRGB(0, 0, 0); d.HealthBG.Visible = false
        d.HealthBar.Filled = true; d.HealthBar.Visible = false
        d.Box.Thickness = 1; d.Box.Filled = false; d.Box.Visible = false
        for i = 1, 14 do
            local l = Drawing.new("Line")
            l.Thickness = 1
            l.Visible = false
            table.insert(d.Skeleton, l)
        end
    end)
end

local function destroyESPContainer(container, key)
    if container[key] then
        pcall(function()
            container[key].Line:Remove()
            container[key].Name:Remove()
            container[key].HealthBG:Remove()
            container[key].HealthBar:Remove()
            container[key].Distance:Remove()
            container[key].Box:Remove()
            for _, l in pairs(container[key].Skeleton) do l:Remove() end
        end)
        container[key] = nil
    end
end

-- Bones
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

local function renderSkeleton(d, char, color)
    local useBones = bonesR15
    if char:FindFirstChild("Torso") and not char:FindFirstChild("UpperTorso") then
        useBones = bonesR6
    end
    for i, bone in pairs(useBones) do
        if d.Skeleton[i] then
            local p1 = char:FindFirstChild(bone[1])
            local p2 = char:FindFirstChild(bone[2])
            if p1 and p2 then
                local sp1, on1 = Camera:WorldToViewportPoint(p1.Position)
                local sp2, on2 = Camera:WorldToViewportPoint(p2.Position)
                if on1 and on2 then
                    d.Skeleton[i].Visible = true
                    d.Skeleton[i].From = Vector2.new(sp1.X, sp1.Y)
                    d.Skeleton[i].To = Vector2.new(sp2.X, sp2.Y)
                    d.Skeleton[i].Color = color
                else
                    d.Skeleton[i].Visible = false
                end
            else
                d.Skeleton[i].Visible = false
            end
        end
    end
end

-- ═══════════════ ESP RENDER (Player) ═══════════════
local function renderESPContainer(d, char, hrp, hum, name, isBot)
    local sp, on = Camera:WorldToViewportPoint(hrp.Position)
    if not on then
        d.Line.Visible = false
        d.Name.Visible = false
        d.HealthBG.Visible = false
        d.HealthBar.Visible = false
        d.Distance.Visible = false
        d.Box.Visible = false
        for _, s in ipairs(d.Skeleton) do s.Visible = false end
        return
    end

    -- Line
    local lineEnabled = isBot and Settings.ESP_LineBOT or (not isBot and Settings.ESP_LinePlayer)
    if lineEnabled then
        d.Line.Visible = true
        d.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        d.Line.To = Vector2.new(sp.X, sp.Y)
        d.Line.Color = isBot and Settings.LineBOTColor or Settings.LinePlayerColor
    else
        d.Line.Visible = false
    end

    -- Name
    if Settings.ESP_Name then
        d.Name.Visible = true
        d.Name.Text = isBot and (name .. " [BOT]") or name
        d.Name.Position = Vector2.new(sp.X, sp.Y - 50)
        d.Name.Color = Settings.NameColor
    else d.Name.Visible = false end

    -- Health
    if Settings.ESP_Health then
        local hp = hum.Health / hum.MaxHealth
        d.HealthBG.Visible = true
        d.HealthBG.Size = Vector2.new(4, 40)
        d.HealthBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
        d.HealthBar.Visible = true
        d.HealthBar.Size = Vector2.new(4, 40 * hp)
        d.HealthBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hp)))
        d.HealthBar.Color = Settings.HealthColor:Lerp(Color3.fromRGB(255, 0, 0), 1 - hp)
    else
        d.HealthBG.Visible = false
        d.HealthBar.Visible = false
    end

    -- Distance
    if Settings.ESP_Distance then
        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
        d.Distance.Visible = true
        d.Distance.Text = math.floor(dist) .. "m"
        d.Distance.Position = Vector2.new(sp.X, sp.Y + 30)
        d.Distance.Color = Settings.NameColor
    else d.Distance.Visible = false end

    -- Box
    if Settings.ESP_Box then
        d.Box.Visible = true
        d.Box.Size = Vector2.new(50, 80)
        d.Box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
        d.Box.Color = Settings.BoxColor
    else d.Box.Visible = false end

    -- Skeleton
    if Settings.ESP_Skeleton then
        renderSkeleton(d, char, Settings.SkeletonColor)
    else
        for _, s in ipairs(d.Skeleton) do s.Visible = false end
    end
end

local function updateESP()
    if not hasDrawing then return end

    -- Player ESP
    for player, d in pairs(ESPData) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hum and hrp and hum.Health > 0) then
            d.Line.Visible = false
            d.Name.Visible = false
            d.HealthBG.Visible = false
            d.HealthBar.Visible = false
            d.Distance.Visible = false
            d.Box.Visible = false
            for _, s in ipairs(d.Skeleton) do s.Visible = false end
        else
            local dist3D = (hrp.Position - Camera.CFrame.Position).Magnitude
            if dist3D <= Settings.MaxDistance then
                renderESPContainer(d, char, hrp, hum, player.Name, false)
            else
                d.Line.Visible = false
                d.Name.Visible = false
                d.HealthBG.Visible = false
                d.HealthBar.Visible = false
                d.Distance.Visible = false
                d.Box.Visible = false
                for _, s in ipairs(d.Skeleton) do s.Visible = false end
            end
        end
    end

    -- BOT ESP (FIX #8)
    local toRemove = {}
    for botChar, d in pairs(botESPData) do
        if not botChar.Parent then
            table.insert(toRemove, botChar)
        else
            local hum = botChar:FindFirstChildOfClass("Humanoid")
            local hrp = botChar:FindFirstChild("HumanoidRootPart")
            if not (hum and hrp and hum.Health > 0) then
                d.Line.Visible = false
                d.Name.Visible = false
                d.HealthBG.Visible = false
                d.HealthBar.Visible = false
                d.Distance.Visible = false
                d.Box.Visible = false
                for _, s in ipairs(d.Skeleton) do s.Visible = false end
            else
                local dist3D = (hrp.Position - Camera.CFrame.Position).Magnitude
                if dist3D <= Settings.MaxDistance then
                    renderESPContainer(d, botChar, hrp, hum, botChar.Name, true)
                else
                    d.Line.Visible = false
                    d.Name.Visible = false
                    d.HealthBG.Visible = false
                    d.HealthBar.Visible = false
                    d.Distance.Visible = false
                    d.Box.Visible = false
                    for _, s in ipairs(d.Skeleton) do s.Visible = false end
                end
            end
        end
    end
    for _, botChar in ipairs(toRemove) do
        destroyESPContainer(botESPData, botChar)
    end
end

-- Player handling
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    createESPContainer(ESPData, player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        destroyESPContainer(ESPData, player)
        createESPContainer(ESPData, player)
    end)
end

for _, player in pairs(Players:GetPlayers()) do onPlayerAdded(player) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p) destroyESPContainer(ESPData, p) end)

-- BOT ESP binding (FIX #8: auto-hapus pas mati)
local botBound = false
local botConns = {}
local botHealthConns = {}

local function bindBotESP(botChar)
    createESPContainer(botESPData, botChar)
    local hum = botChar:FindFirstChildOfClass("Humanoid")
    if hum then
        local conn
        conn = hum.HealthChanged:Connect(function(hp)
            if hp <= 0 then
                task.wait(0.5)
                destroyESPContainer(botESPData, botChar)
                if conn then conn:Disconnect() end
                botHealthConns[botChar] = nil
            end
        end)
        botHealthConns[botChar] = conn
    end
end

local function unbindBotESP(botChar)
    destroyESPContainer(botESPData, botChar)
    if botHealthConns[botChar] then
        pcall(function() botHealthConns[botChar]:Disconnect() end)
        botHealthConns[botChar] = nil
    end
end

task.spawn(function()
    while task.wait(2) do
        local botFolder = getBotFolder()
        if botFolder and not botBound then
            botBound = true
            for _, botChar in ipairs(botFolder:GetChildren()) do
                bindBotESP(botChar)
            end
            table.insert(botConns, botFolder.ChildAdded:Connect(function(botChar)
                task.wait(0.2)
                bindBotESP(botChar)
            end))
            table.insert(botConns, botFolder.ChildRemoved:Connect(function(botChar)
                unbindBotESP(botChar)
            end))
        elseif not botFolder and botBound then
            botBound = false
            for _, c in ipairs(botConns) do
                pcall(function() c:Disconnect() end)
            end
            botConns = {}
            for botChar, _ in pairs(botESPData) do
                destroyESPContainer(botESPData, botChar)
            end
            for botChar, c in pairs(botHealthConns) do
                pcall(function() c:Disconnect() end)
            end
            botHealthConns = {}
        end
    end
end)

-- ═══════════════ SILENT AIM ═══════════════
local target = { position = nil }

local function getAimPart(char)
    if not char then return nil end
    if Settings.AimPart == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    elseif Settings.AimPart == "Body" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    elseif Settings.AimPart == "Foot" then
        return char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg") or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function getClosestTarget()
    if not Settings.SilentAim then return nil end
    local bestPos, bestDist = nil, Settings.POV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not isSameTeam(player) then
                local char = player.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                local part = getAimPart(char)
                if hum and hum.Health > 0 and part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestDist then
                            if not Settings.WallCheck or isVisible(part) then
                                bestDist = d
                                bestPos = part.Position
                            end
                        end
                    end
                end
            end
        end
    end

    local botFolder = getBotFolder()
    if botFolder then
        for _, botChar in ipairs(botFolder:GetChildren()) do
            local hum = botChar:FindFirstChildOfClass("Humanoid")
            local part = getAimPart(botChar)
            if hum and hum.Health > 0 and part then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then
                        if not Settings.WallCheck or isVisible(part) then
                            bestDist = d
                            bestPos = part.Position
                        end
                    end
                end
            end
        end
    end
    return bestPos
end

-- ═══════════════ VODKA HOOK (FIX #5, #6) ═══════════════
if hasHook and hasDrawing then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = { ... }
        local method = getnamecallmethod()
        if method then method = method:lower() end

        if Settings.SilentAim and target.position and typeof(self) == "Instance" and self.Name == "Workspace" then
            if method == "raycast" or method == "findpartonray" then
                -- FIX #6: preserve length asli
                local originalLength = 200
                if typeof(args[2]) == "Vector3" then
                    originalLength = args[2].Magnitude
                    if originalLength < 1 then originalLength = 200 end
                end
                args[2] = (target.position - Camera.CFrame.Position).Unit * originalLength
                return oldNamecall(self, table.unpack(args))
            end
        end

        return oldNamecall(self, ...)
    end))
else
    warn("[RENXX v4.2] Hook nggak aktif!")
end

-- ═══════════════ PLAYER FEATURES ═══════════════
local originalCollide = {}

local function applyMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.WalkSpeed ~= Settings.SpeedValue then hum.WalkSpeed = Settings.SpeedValue end
        if hum.UseJumpPower then
            if hum.JumpPower ~= Settings.JumpValue then hum.JumpPower = Settings.JumpValue end
        else
            if hum.JumpHeight ~= Settings.JumpValue then hum.JumpHeight = Settings.JumpValue end
        end
    end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- Noclip (FIX #12: balikin collide)
local function applyNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if Settings.Noclip then
                if originalCollide[part] == nil then
                    originalCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            else
                if originalCollide[part] ~= nil then
                    part.CanCollide = originalCollide[part]
                    originalCollide[part] = nil
                end
            end
        end
    end
end

-- Fly (FIX #1, #2)
local flyBodyVel, flyBodyGyro, flyConn
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyBodyVel then flyBodyVel:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    if flyConn then flyConn:Disconnect() end

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVel.Velocity = Vector3.new(0, 0, 0)
    flyBodyVel.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.P = 1000
    flyBodyGyro.D = 50
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp

    flyConn = RunService.RenderStepped:Connect(function()
        if not Settings.Fly or not hrp.Parent then
            if flyBodyVel then flyBodyVel:Destroy() end
            if flyBodyGyro then flyBodyGyro:Destroy() end
            if flyConn then flyConn:Disconnect() end
            flyBodyVel, flyBodyGyro, flyConn = nil, nil, nil
            return
        end
        local camCF = Camera.CFrame
        local move = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end

        if move.Magnitude > 0 then move = move.Unit end
        flyBodyVel.Velocity = move * Settings.FlySpeed
        flyBodyGyro.CFrame = camCF
    end)
end

local function stopFly()
    if flyBodyVel then flyBodyVel:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    if flyConn then flyConn:Disconnect() end
    flyBodyVel, flyBodyGyro, flyConn = nil, nil, nil
end

-- FIX #2: Cleanup pas mati
LocalPlayer.CharacterRemoving:Connect(function()
    if flyConn then stopFly() end
    originalCollide = {}
end)

-- ═══════════════ RENDER LOOP ═══════════════
RunService.Heartbeat:Connect(function()
    if Settings.SilentAim then
        local pos = getClosestTarget()
        target.position = pos
        if pos and Settings.SnapLine and snapLine then
            local sp, on = Camera:WorldToViewportPoint(pos)
            if on then
                snapLine.Visible = true
                snapLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                snapLine.To = Vector2.new(sp.X, sp.Y)
                snapLine.Color = Settings.SnapLineColor
            else snapLine.Visible = false end
        elseif snapLine then
            snapLine.Visible = false
        end
    else
        target.position = nil
        if snapLine then snapLine.Visible = false end
    end

    if povCircle then
        if Settings.ShowPOV and Settings.SilentAim then
            povCircle.Visible = true
            povCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            povCircle.Radius = fovToRadius(Settings.POV)
            povCircle.Color = Settings.POVColor
        else povCircle.Visible = false end
    end

    applyMovement()
    if Settings.Noclip then applyNoclip() end
end)

RunService.RenderStepped:Connect(updateESP)

-- ═══════════════ UI ═══════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RENXXUI"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = screenGui
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
toggleBtn.Position = Settings.MenuPosition
toggleBtn.Text = "🎯"
toggleBtn.TextColor3 = Color3.fromRGB(255, 200, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 38
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.fromRGB(255, 200, 255)
toggleBtn.Active = true
toggleBtn.Draggable = true

local btnCorner = Instance.new("UICorner")
btnCorner.Parent = toggleBtn
btnCorner.CornerRadius = UDim.new(1, 0)

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 500, 0, 420)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 255)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.Parent = mainFrame
mainCorner.CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, -70, 0, 40)
title.Position = UDim2.new(0, 10, 0, 5)
title.Text = "🎯 RENXX HUB v4.2 | FPS One Tap"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Center

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = mainFrame
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundTransparency = 1
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Tabs
local tabFrame = Instance.new("Frame")
tabFrame.Parent = mainFrame
tabFrame.Size = UDim2.new(1, -20, 0, 35)
tabFrame.Position = UDim2.new(0.025, 0, 0, 48)
tabFrame.BackgroundTransparency = 1

local tabData = {}
local function createTab(text, icon, position)
    local btn = Instance.new("TextButton")
    btn.Parent = tabFrame
    btn.Size = UDim2.new(0.22, 0, 1, 0)
    btn.Position = UDim2.new(position, 0, 0, 0)
    btn.Text = icon .. " " .. text
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.BackgroundTransparency = 0.4
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.Parent = btn
    corner.CornerRadius = UDim.new(0, 8)

    local underline = Instance.new("Frame")
    underline.Parent = btn
    underline.Size = UDim2.new(0.6, 0, 0, 2)
    underline.Position = UDim2.new(0.2, 0, 1, -2)
    underline.BackgroundColor3 = Color3.fromRGB(200, 200, 255)
    underline.BackgroundTransparency = 1
    underline.Visible = false

    tabData[btn] = underline
    return btn
end

local tabCombat = createTab("Combat", "⚔️", 0.02)
local tabVisuals = createTab("Visuals", "👁️", 0.26)
local tabPlayer = createTab("Player", "🏃", 0.50)
local tabInfo = createTab("Info", "ℹ️", 0.74)

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
scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 200)

local combatContent = Instance.new("Frame")
combatContent.Parent = scroll
combatContent.Size = UDim2.new(1, 0, 0, 700)
combatContent.BackgroundTransparency = 1
combatContent.Visible = true

local visualContent = Instance.new("Frame")
visualContent.Parent = scroll
visualContent.Size = UDim2.new(1, 0, 0, 700)
visualContent.BackgroundTransparency = 1
visualContent.Visible = false

local playerContent = Instance.new("Frame")
playerContent.Parent = scroll
playerContent.Size = UDim2.new(1, 0, 0, 700)
playerContent.BackgroundTransparency = 1
playerContent.Visible = false

local infoContent = Instance.new("Frame")
infoContent.Parent = scroll
infoContent.Size = UDim2.new(1, 0, 0, 700)
infoContent.BackgroundTransparency = 1
infoContent.Visible = false

local function switchTab(selectedBtn)
    for btn, underline in pairs(tabData) do
        if btn == selectedBtn then
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            btn.BackgroundTransparency = 0.2
            underline.Visible = true
            underline.BackgroundTransparency = 0
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            btn.BackgroundTransparency = 0.4
            underline.Visible = false
        end
    end
    combatContent.Visible = (selectedBtn == tabCombat)
    visualContent.Visible = (selectedBtn == tabVisuals)
    playerContent.Visible = (selectedBtn == tabPlayer)
    infoContent.Visible = (selectedBtn == tabInfo)
end

tabCombat.MouseButton1Click:Connect(function() switchTab(tabCombat) end)
tabVisuals.MouseButton1Click:Connect(function() switchTab(tabVisuals) end)
tabPlayer.MouseButton1Click:Connect(function() switchTab(tabPlayer) end)
tabInfo.MouseButton1Click:Connect(function() switchTab(tabInfo) end)
switchTab(tabCombat)

-- UI Helpers
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
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Size = UDim2.new(0.18, 0, 0.75, 0)
    btn.Position = UDim2.new(0.8, 0, 0.125, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.Parent = btn
    c.CornerRadius = UDim.new(0, 12)

    -- FIX #11: Sinkron dari Settings
    local state = Settings[key]
    if state == nil then state = default end
    btn.Text = state and "ON" or "OFF"
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
        Settings[key] = state
        -- FIX #1: Fly instant
        if key == "Fly" then
            if state then startFly() else stopFly() end
        end
        saveSettings()
    end)
end

local function makeSlider(parent, text, y, min, max, key, default)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundTransparency = 1

    local current = Settings[key]
    if current == nil then current = default end

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.6, 0, 0, 16)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Size = UDim2.new(0.4, 0, 0, 16)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.Text = tostring(current)
    valueLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local sliderBg = Instance.new("Frame")
    sliderBg.Parent = frame
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0, 24)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderBg.BorderSizePixel = 0

    local bgc = Instance.new("UICorner")
    bgc.Parent = sliderBg
    bgc.CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderBg
    sliderFill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
    sliderFill.BorderSizePixel = 0

    local fc = Instance.new("UICorner")
    fc.Parent = sliderFill
    fc.CornerRadius = UDim.new(1, 0)

    local dragging = false
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Parent = sliderBg
    sliderBtn.Size = UDim2.new(1, 0, 2, 0)
    sliderBtn.Position = UDim2.new(0, 0, -0.5, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""

    local function update(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(value)
        Settings[key] = value
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            saveSettings()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

local function makeColor(parent, text, y, key, default)
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
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Size = UDim2.new(0.18, 0, 0.75, 0)
    btn.Position = UDim2.new(0.8, 0, 0.125, 0)
    btn.Text = ""
    -- FIX #10: Load dari Settings
    btn.BackgroundColor3 = Settings[key] or default
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.Parent = btn
    c.CornerRadius = UDim.new(0, 12)

    local presets = {
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 150, 255), Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 165, 0), Color3.fromRGB(150, 150, 150),
    }
    local idx = 1
    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #presets then idx = 1 end
        btn.BackgroundColor3 = presets[idx]
        Settings[key] = presets[idx]
        saveSettings()
    end)
end

local function makeDropdown(parent, text, y, key, options, default)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundTransparency = 1

    local current = Settings[key] or default

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.6, 0, 0, 16)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.Position = UDim2.new(0, 0, 0, 20)
    btn.Text = current
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.Parent = btn
    c.CornerRadius = UDim.new(0, 6)

    local idx = 1
    for i, v in ipairs(options) do if v == current then idx = i end end

    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        btn.Text = options[idx]
        Settings[key] = options[idx]
        saveSettings()
    end)
end

local function makeLabel(parent, text, y, size)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.Size = UDim2.new(1, 0, 0, 24)
    label.Position = UDim2.new(0, 0, 0, y)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = size or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
end

-- ═══════════════ TAB: VISUAL ═══════════════
makeLabel(visualContent, "═══ ESP FEATURES ═══", 0, 14)
makeToggle(visualContent, "ESP Name", 30, "ESP_Name", Settings.ESP_Name)
makeToggle(visualContent, "ESP Health Bar", 66, "ESP_Health", Settings.ESP_Health)
makeToggle(visualContent, "ESP Skeleton", 102, "ESP_Skeleton", Settings.ESP_Skeleton)
makeToggle(visualContent, "ESP Distance", 138, "ESP_Distance", Settings.ESP_Distance)
makeToggle(visualContent, "ESP Box", 174, "ESP_Box", Settings.ESP_Box)
makeToggle(visualContent, "ESP Line Player", 210, "ESP_LinePlayer", Settings.ESP_LinePlayer)
makeToggle(visualContent, "ESP Line BOT", 246, "ESP_LineBOT", Settings.ESP_LineBOT)
makeSlider(visualContent, "Max Distance", 282, 100, 5000, "MaxDistance", Settings.MaxDistance)

makeLabel(visualContent, "═══ COLORS ═══", 340, 14)
makeColor(visualContent, "Name Color", 370, "NameColor", Settings.NameColor)
makeColor(visualContent, "Health Color", 406, "HealthColor", Settings.HealthColor)
makeColor(visualContent, "Skeleton Color", 442, "SkeletonColor", Settings.SkeletonColor)
makeColor(visualContent, "Box Color", 478, "BoxColor", Settings.BoxColor)
makeColor(visualContent, "Line Player Color", 514, "LinePlayerColor", Settings.LinePlayerColor)
makeColor(visualContent, "Line BOT Color", 550, "LineBOTColor", Settings.LineBOTColor)

-- ═══════════════ TAB: COMBAT ═══════════════
makeLabel(combatContent, "═══ SILENT AIM ═══", 0, 14)
makeToggle(combatContent, "Silent Aim", 30, "SilentAim", Settings.SilentAim)
makeSlider(combatContent, "POV (0-360°)", 76, 0, 360, "POV", Settings.POV)
makeToggle(combatContent, "Show POV", 122, "ShowPOV", Settings.ShowPOV)
makeColor(combatContent, "POV Color", 158, "POVColor", Settings.POVColor)
makeToggle(combatContent, "Snap Line", 194, "SnapLine", Settings.SnapLine)
makeColor(combatContent, "Snap Line Color", 230, "SnapLineColor", Settings.SnapLineColor)
makeDropdown(combatContent, "Aim Part", 266, "AimPart", {"Head", "Body", "Foot"}, Settings.AimPart)
makeToggle(combatContent, "Team Check", 324, "TeamCheck", Settings.TeamCheck)
makeToggle(combatContent, "Wall Check", 360, "WallCheck", Settings.WallCheck)

-- ═══════════════ TAB: PLAYER ═══════════════
makeLabel(playerContent, "═══ MOVEMENT ═══", 0, 14)
makeSlider(playerContent, "WalkSpeed Value", 30, 16, 500, "SpeedValue", Settings.SpeedValue)
makeSlider(playerContent, "Jump Power Value", 76, 50, 500, "JumpValue", Settings.JumpValue)
makeToggle(playerContent, "Infinite Jump", 122, "InfiniteJump", Settings.InfiniteJump)
makeToggle(playerContent, "No Clip", 158, "Noclip", Settings.Noclip)
makeToggle(playerContent, "Fly", 194, "Fly", Settings.Fly)
makeSlider(playerContent, "Fly Speed", 240, 10, 500, "FlySpeed", Settings.FlySpeed)

-- ═══════════════ TAB: INFO ═══════════════
makeLabel(infoContent, "🎯 RENXX HUB v4.2", 10, 18)
makeLabel(infoContent, "FPS One Tap Edition", 40, 14)
makeLabel(infoContent, "By: RENXX", 70, 14)
makeLabel(infoContent, "Depy is God", 95, 14)
makeLabel(infoContent, "Hook: Vodka (raycast)", 125, 13)
makeLabel(infoContent, "UI: Custom", 145, 13)
makeLabel(infoContent, "Keybind: RightShift", 165, 13)

-- ═══════════════ INIT ═══════════════
print("═══════════════════════════════════════")
print("[RENXX HUB v4.2] FPS One Tap - LOADED!")
print("By: RENXX | Depy is God")
print("Silent Aim | ESP | BOT ESP | Movement")
print("FIXED: 13 bugs")
print("═══════════════════════════════════════")
