--[[
    ═══════════════════════════════════════════════
    RENXX HUB | FPS One Tap (FIXED)
    By: RENXX | Depy is God
    ═══════════════════════════════════════════════
    Hook: Vodka (raycast) - Silent Aim
    Changelog v4.1:
    - pack you 
    ═══════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
    warn("[RENXX v4.1] Executor nggak support Drawing API! ESP & Silent Aim nggak jalan.")
end

-- ═══════════════ SETTINGS ═══════════════
local Settings = {
    -- Visual
    ESP_Name = true, ESP_Health = true, ESP_Skeleton = true,
    ESP_Distance = true, ESP_Box = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    SkeletonColor = Color3.fromRGB(255, 255, 0),
    BoxColor = Color3.fromRGB(255, 0, 0),

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
    MenuPosition = UDim2.new(1, -80, 1, -80), -- Kanan bawah
}

local HttpService = game:GetService("HttpService")

local function saveSettings()
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

-- ESP per player
local ESPData = {}

local function createESP(player)
    if not hasDrawing then return end
    if player == LocalPlayer or ESPData[player] then return end
    pcall(function()
        ESPData[player] = {
            Name = Drawing.new("Text"),
            HealthBG = Drawing.new("Square"),
            HealthBar = Drawing.new("Square"),
            Distance = Drawing.new("Text"),
            Box = Drawing.new("Square"),
            Skeleton = {},
        }
        ESPData[player].Name.Size = 14
        ESPData[player].Name.Center = true
        ESPData[player].Name.Outline = true
        ESPData[player].Name.Font = 2
        ESPData[player].Name.Visible = false

        ESPData[player].Distance.Size = 12
        ESPData[player].Distance.Center = true
        ESPData[player].Distance.Outline = true
        ESPData[player].Distance.Font = 2
        ESPData[player].Distance.Visible = false

        ESPData[player].HealthBG.Filled = true
        ESPData[player].HealthBG.Color = Color3.fromRGB(0, 0, 0)
        ESPData[player].HealthBG.Visible = false

        ESPData[player].HealthBar.Filled = true
        ESPData[player].HealthBar.Visible = false

        ESPData[player].Box.Thickness = 1
        ESPData[player].Box.Filled = false
        ESPData[player].Box.Visible = false

        for i = 1, 14 do
            local l = Drawing.new("Line")
            l.Thickness = 1
            l.Visible = false
            table.insert(ESPData[player].Skeleton, l)
        end
    end)
end

local function destroyESP(player)
    if ESPData[player] then
        pcall(function()
            ESPData[player].Name:Remove()
            ESPData[player].HealthBG:Remove()
            ESPData[player].HealthBar:Remove()
            ESPData[player].Distance:Remove()
            ESPData[player].Box:Remove()
            for _, l in pairs(ESPData[player].Skeleton) do l:Remove() end
        end)
        ESPData[player] = nil
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

local function updateESP()
    if not hasDrawing then return end
    for player, data in pairs(ESPData) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not (char and hum and hrp and hum.Health > 0) then
            data.Name.Visible = false
            data.HealthBG.Visible = false
            data.HealthBar.Visible = false
            data.Distance.Visible = false
            data.Box.Visible = false
            for _, l in pairs(data.Skeleton) do l.Visible = false end
        else
            local dist3D = (hrp.Position - Camera.CFrame.Position).Magnitude
            local headPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen and dist3D <= 1000 then
                -- Name
                if Settings.ESP_Name then
                    data.Name.Visible = true
                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(headPos.X, headPos.Y - 50)
                    data.Name.Color = Settings.NameColor
                else data.Name.Visible = false end

                -- Health Bar
                if Settings.ESP_Health then
                    local hp = hum.Health / hum.MaxHealth
                    data.HealthBG.Visible = true
                    data.HealthBG.Size = Vector2.new(4, 40)
                    data.HealthBG.Position = Vector2.new(headPos.X - 35, headPos.Y - 20)

                    data.HealthBar.Visible = true
                    data.HealthBar.Size = Vector2.new(4, 40 * hp)
                    data.HealthBar.Position = Vector2.new(headPos.X - 35, headPos.Y - 20 + (40 * (1 - hp)))
                    data.HealthBar.Color = Settings.HealthColor:Lerp(Color3.fromRGB(255, 0, 0), 1 - hp)
                else
                    data.HealthBG.Visible = false
                    data.HealthBar.Visible = false
                end

                -- Distance
                if Settings.ESP_Distance then
                    data.Distance.Visible = true
                    data.Distance.Text = math.floor(dist3D) .. "m"
                    data.Distance.Position = Vector2.new(headPos.X, headPos.Y + 30)
                    data.Distance.Color = Settings.NameColor
                else data.Distance.Visible = false end

                -- Box
                if Settings.ESP_Box then
                    data.Box.Visible = true
                    data.Box.Size = Vector2.new(50, 80)
                    data.Box.Position = Vector2.new(headPos.X - 25, headPos.Y - 40)
                    data.Box.Color = Settings.BoxColor
                else data.Box.Visible = false end

                -- Skeleton
                if Settings.ESP_Skeleton then
                    local useBones = bonesR15
                    if char:FindFirstChild("Torso") and not char:FindFirstChild("UpperTorso") then
                        useBones = bonesR6
                    end
                    for i, bone in pairs(useBones) do
                        local p1 = char:FindFirstChild(bone[1])
                        local p2 = char:FindFirstChild(bone[2])
                        if p1 and p2 and data.Skeleton[i] then
                            local sp1, on1 = Camera:WorldToViewportPoint(p1.Position)
                            local sp2, on2 = Camera:WorldToViewportPoint(p2.Position)
                            if on1 and on2 then
                                data.Skeleton[i].From = Vector2.new(sp1.X, sp1.Y)
                                data.Skeleton[i].To = Vector2.new(sp2.X, sp2.Y)
                                data.Skeleton[i].Color = Settings.SkeletonColor
                                data.Skeleton[i].Visible = true
                            else data.Skeleton[i].Visible = false end
                        end
                    end
                else
                    for _, l in pairs(data.Skeleton) do l.Visible = false end
                end
            else
                data.Name.Visible = false
                data.HealthBG.Visible = false
                data.HealthBar.Visible = false
                data.Distance.Visible = false
                data.Box.Visible = false
                for _, l in pairs(data.Skeleton) do l.Visible = false end
            end
        end
    end
end

-- Player handling
local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    createESP(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        destroyESP(player)
        createESP(player)
    end)
end

for _, player in pairs(Players:GetPlayers()) do onPlayerAdded(player) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(destroyESP)

-- ═══════════════ SILENT AIM (VODKA HOOK) ═══════════════
local target = { position = nil }

local function getAimPart(char)
    if Settings.AimPart == "Head" then
        return char:FindFirstChild("Head")
    elseif Settings.AimPart == "Body" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    elseif Settings.AimPart == "Foot" then
        return char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg") or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("Head")
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
    return bestPos
end

-- ═══════════════ VODKA HOOK (FIXED RECURSION) ═══════════════
if hasHook and hasDrawing then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = { ... }
        local method = getnamecallmethod()
        if method then method = method:lower() end

        -- Silent Aim: Hook Raycast
        if Settings.SilentAim and target.position and method == "raycast" and typeof(self) == "Instance" and self.Name == "Workspace" then
            args[2] = (target.position - Camera.CFrame.Position).Unit * 200
            return oldNamecall(self, table.unpack(args))
        end

        return oldNamecall(self, ...)
    end))
else
    warn("[RENXX v4.1] Hook nggak aktif! Executor nggak support hookmetamethod atau Drawing.")
end

-- ═══════════════ PLAYER FEATURES ═══════════════
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

-- Noclip
local function applyNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            if Settings.Noclip then part.CanCollide = false end
        end
    end
end

-- Fly
local flyBodyVel, flyBodyGyro, flyConn
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

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

-- ═══════════════ RENDER LOOP ═══════════════
RunService.Heartbeat:Connect(function()
    -- Silent aim target
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

    -- POV circle
    if povCircle then
        if Settings.ShowPOV and Settings.SilentAim then
            povCircle.Visible = true
            povCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            povCircle.Radius = fovToRadius(Settings.POV)
            povCircle.Color = Settings.POVColor
        else povCircle.Visible = false end
    end

    -- Movement
    applyMovement()
    if Settings.Noclip then applyNoclip() end
end)

RunService.RenderStepped:Connect(updateESP)

-- Fly management
task.spawn(function()
    while task.wait(0.5) do
        if Settings.Fly and not flyConn then
            startFly()
        elseif not Settings.Fly and flyConn then
            if flyBodyVel then flyBodyVel:Destroy() end
            if flyBodyGyro then flyBodyGyro:Destroy() end
            flyConn:Disconnect()
            flyBodyVel, flyBodyGyro, flyConn = nil, nil, nil
        end
    end
end)

-- ═══════════════ UI ═══════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RENXXUI"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

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
toggleBtn.Draggable = true -- FIX: biar bisa di-drag

local btnCorner = Instance.new("UICorner")
btnCorner.Parent = toggleBtn
btnCorner.CornerRadius = UDim.new(1, 0)

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
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 5)
title.Text = "🎯 RENXX HUB v4.1 | FPS One Tap"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
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

-- ═══════════════ KEYBIND (FIX) ═══════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
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
    btn.Text = default and "ON" or "OFF"
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
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
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
        Settings[key] = state
        saveSettings()
    end)
end

local function makeSlider(parent, text, y, min, max, key, default)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundTransparency = 1

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
    valueLabel.Text = tostring(default)
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
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
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
    btn.BackgroundColor3 = default
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
    btn.Text = default
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.Parent = btn
    c.CornerRadius = UDim.new(0, 6)

    local idx = 1
    for i, v in ipairs(options) do if v == default then idx = i end end

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

makeLabel(visualContent, "═══ COLORS ═══", 224, 14)
makeColor(visualContent, "Name Color", 254, "NameColor", Settings.NameColor)
makeColor(visualContent, "Health Color", 290, "HealthColor", Settings.HealthColor)
makeColor(visualContent, "Skeleton Color", 326, "SkeletonColor", Settings.SkeletonColor)
makeColor(visualContent, "Box Color", 362, "BoxColor", Settings.BoxColor)

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
makeLabel(infoContent, "🎯 RENXX HUB v4.1", 10, 18)
makeLabel(infoContent, "FPS One Tap Edition", 40, 14)
makeLabel(infoContent, "By: RENXX", 70, 14)
makeLabel(infoContent, "Depy is God", 95, 14)
makeLabel(infoContent, "Hook: Vodka (raycast)", 125, 13)
makeLabel(infoContent, "UI: Custom", 145, 13)
makeLabel(infoContent, "Keybind: RightShift", 165, 13)

-- ═══════════════ INIT ═══════════════
print("═══════════════════════════════════════")
print("[RENXX HUB] FPS One Tap - LOADED!")
print("By: RENXX | Depy is God")
print("Silent Aim (Vodka Hook) | ESP | Movement")
print("═══════════════════════════════════════")
