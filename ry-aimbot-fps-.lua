-- ═══════════════════════════════════════
--  RENXX — AIMBOT FPS v2.2
--  By: DEEP & RENXX
--  Library: Rayfield
-- ═══════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- ==================== CONFIG ====================
local C = {
    -- COMBAT
    KillAll = false,
    FireDelay = 50,
    Aimbot = false,
    AimSmooth = 5,
    POV = 90,
    ShowPOV = false,
    POVColor = Color3.fromRGB(255, 0, 100),
    AimPart = "Head",
    WallCheck = false,
    AliveCheck = true,
    -- VISUAL
    ESP_LinePlayer = false,
    ESP_LineBOT = false,
    ESP_Name = false,
    ESP_Health = false,
    ESP_Distance = false,
    ESP_Box = false,
    ESP_LinePlayerColor = Color3.fromRGB(0, 255, 0),
    ESP_LineBOTColor = Color3.fromRGB(255, 255, 0),
    ESP_TextColor = Color3.fromRGB(255, 255, 255),
    ESP_BoxColor = Color3.fromRGB(255, 0, 0),
    -- PLAYER
    GodMode = false,
    SpeedHack = false,
    SpeedValue = 50,
    JumpHack = false,
    JumpValue = 50,
    InfJump = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 50,
    -- SHOP
    AutoHack = false,
    TargetValue = 999999999,
    ScanInterval = 1,
    -- EXTRA
    Teleport = false,
    TeleportSet = "Behind",
    TeleportRadius = 2,
    TeleportDelay = 5,
}

-- ==================== STATE ====================
local lastShot = 0
local lastTeleport = 0
local lastScan = 0
local targetIndex = 1
local flyBV = nil
local flyBG = nil
local currentTarget = nil
-- ✅ FIX #1: Cache dipisah
local espCachePlayers = {}
local espCacheBots = {}

-- ==================== HELPER ====================
local function getBlaster()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChild("Blaster") or char:FindFirstChildOfClass("Tool")
end

-- ✅ FIX #4: WallCheck & AliveCheck logic
local function hasLineOfSight(targetPart)
    if not C.WallCheck then return true end
    local ok, result = pcall(function()
        local origin = Cam.CFrame.Position
        local direction = (targetPart.Position - origin)
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, Cam})
        return hit == nil or hit:IsDescendantOf(targetPart.Parent)
    end)
    return ok and result or true
end

local function isTargetAlive(hum)
    if not C.AliveCheck then return true end
    return hum and hum.Health > 0
end

local function getAllTargets()
    local targets = {}
    local seen = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not seen[h] then
                seen[h] = true
                table.insert(targets, {hum = h, isBot = false})
            end
        end
    end

    local botFolder = Workspace:FindFirstChild("Game")
    if botFolder then
        botFolder = botFolder:FindFirstChild("__ServerBotCharacters")
    end
    if botFolder then
        for _, botChar in ipairs(botFolder:GetChildren()) do
            local h = botChar:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not seen[h] then
                seen[h] = true
                table.insert(targets, {hum = h, isBot = true})
            end
        end
    end

    return targets
end

local function getNearestTarget()
    local targets = getAllTargets()
    local myChar = LP.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local nearest = nil
    local shortest = math.huge
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local fovRadius = math.tan(math.rad(C.POV / 2)) * (Cam.ViewportSize.Y / 2)

    for _, data in ipairs(targets) do
        local hum = data.hum
        if isTargetAlive(hum) then
            local char = hum.Parent
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local part = char:FindFirstChild(C.AimPart) or char:FindFirstChild("Head")
            
            if hrp and part and hasLineOfSight(part) then
                local sp, onScreen = Cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist <= fovRadius and dist < shortest then
                        shortest = dist
                        nearest = hum
                    end
                end
            end
        end
    end

    return nearest
end

-- ==================== KILL ALL ====================
local Shoot = nil
pcall(function()
    Shoot = ReplicatedStorage:WaitForChild("Blaster"):WaitForChild("Remotes"):WaitForChild("Shoot")
end)

local function killAll()
    if not Shoot then return end
    local blaster = getBlaster()
    if not blaster then return end
    local targets = getAllTargets()
    if #targets == 0 then return end
    if targetIndex > #targets then targetIndex = 1 end
    local data = targets[targetIndex]
    targetIndex = targetIndex + 1

    local hits = { ["1"] = data.hum }
    local headshots = { ["1"] = true }

    Shoot:FireServer(
        Workspace:GetServerTimeNow(),
        blaster,
        Cam.CFrame,
        hits,
        headshots,
        { isQuickscope = false, isNoscope = true }
    )
end

-- ==================== FLY ====================
local function getMoveDirection()
    local camCF = Cam.CFrame
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
    if move.Magnitude > 0 then move = move.Unit * C.FlySpeed end
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
    flyBG.CFrame = Cam.CFrame
    flyBG.Parent = root
end

local function stopFly()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    flyBV = nil
    flyBG = nil
end

-- ==================== TELEPORT ====================
local function getTeleportPosition(targetHRP, mode, radius)
    local targetPos = targetHRP.Position
    local targetCF = targetHRP.CFrame
    local dist = radius or 2
    
    if mode == "Behind" then
        return targetPos - (targetCF.LookVector * dist) + Vector3.new(0, 3, 0)
    elseif mode == "Front" then
        return targetPos + (targetCF.LookVector * dist) + Vector3.new(0, 3, 0)
    elseif mode == "Above" then
        return targetPos + Vector3.new(0, dist + 3, 0)
    elseif mode == "Below" then
        return targetPos - Vector3.new(0, dist, 0)
    elseif mode == "Left" then
        return targetPos - (targetCF.RightVector * dist) + Vector3.new(0, 3, 0)
    elseif mode == "Right" then
        return targetPos + (targetCF.RightVector * dist) + Vector3.new(0, 3, 0)
    end
    return targetPos - (targetCF.LookVector * dist) + Vector3.new(0, 3, 0)
end

local function teleportToTarget()
    if not C.Teleport then return end
    
    local now = tick()  -- ✅ FIX #3
    if now - lastTeleport < C.TeleportDelay then return end
    
    -- ✅ FIX #4: Reset target kalau mati/hilang
    if currentTarget and currentTarget.Parent then
        local hum = currentTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return end
        currentTarget = nil
    else
        currentTarget = nil
    end
    
    local target = getNearestTarget()
    if not target then return end
    
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetHRP = target.Parent:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local pos = getTeleportPosition(targetHRP, C.TeleportSet, C.TeleportRadius)
    hrp.CFrame = CFrame.new(pos, targetHRP.Position)
    currentTarget = target
    lastTeleport = now
end

-- ==================== SHOP HACK ====================
local function scanAndHack()
    if not C.AutoHack then return end
    for _, obj in pairs(LP:GetDescendants()) do
        pcall(function()
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                local n = obj.Name:lower()
                if n:find("ruby") or n:find("money") or n:find("gem") 
                   or n:find("cash") or n:find("coin") then
                    if obj.Value < C.TargetValue then
                        obj.Value = C.TargetValue
                    end
                end
            end
        end)
    end
end

-- ==================== ESP DRAWING ====================
local hasDrawing = pcall(function()
    local d = Drawing.new("Text")
    d:Remove()
end)

local function createESP()
    if not hasDrawing then return nil end
    local ok, d = pcall(function()
        return {
            line = Drawing.new("Line"),
            name = Drawing.new("Text"),
            hpBG = Drawing.new("Square"),
            hpBar = Drawing.new("Square"),
            dist = Drawing.new("Text"),
            box = Drawing.new("Square"),
        }
    end)
    if not ok then return nil end
    for _, v in pairs(d) do v.Visible = false end
    return d
end

local function destroyESP(d)
    if not d then return end
    for _, v in pairs(d) do pcall(function() v:Remove() end) end
end

local function hideESP(d)
    if not d then return end
    for _, v in pairs(d) do pcall(function() v.Visible = false end) end
end

-- ✅ FIX #1: Cache player & bot terpisah
local function getOrCreatePlayerESP(player)
    if not espCachePlayers[player] then
        espCachePlayers[player] = createESP()
    end
    return espCachePlayers[player]
end

local function getOrCreateBotESP(botChar)
    if not espCacheBots[botChar] then
        espCacheBots[botChar] = createESP()
    end
    return espCacheBots[botChar]
end

-- Setup player ESP
if hasDrawing then
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then getOrCreatePlayerESP(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LP then getOrCreatePlayerESP(p) end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if espCachePlayers[p] then
            destroyESP(espCachePlayers[p])
            espCachePlayers[p] = nil
        end
    end)
end

-- ✅ FIX #2: Bot ESP Cleanup
task.spawn(function()
    while task.wait(2) do
        -- Cleanup Player
        for p, d in pairs(espCachePlayers) do
            if not p.Parent then
                destroyESP(d)
                espCachePlayers[p] = nil
            end
        end
        -- Cleanup Bot
        for char, d in pairs(espCacheBots) do
            if not char.Parent then
                destroyESP(d)
                espCacheBots[char] = nil
            else
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then
                    destroyESP(d)
                    espCacheBots[char] = nil
                end
            end
        end
    end
end)

-- ==================== WINDOW ====================
local Window = Rayfield:CreateWindow({
    Name = "RENXX — AIMBOT FPS v2.2",
    LoadingTitle = "Loading RENXX...",
    LoadingSubtitle = "By DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================== TAB 1: COMBAT ====================
local CombatTab = Window:CreateTab("COMBAT", 4483362458)

CombatTab:CreateSection("Auto Kill")

CombatTab:CreateToggle({
    Name = "Kill All",
    CurrentValue = false,
    Callback = function(v)
        C.KillAll = v
        Rayfield:Notify({Title="RENXX", Content="Kill All: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

CombatTab:CreateSlider({
    Name = "Fire Delay (ms)",
    Range = {1, 200}, Increment = 1, Suffix = "ms", CurrentValue = 50,
    Callback = function(v) C.FireDelay = v end,
})

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(v)
        C.Aimbot = v
        Rayfield:Notify({Title="RENXX", Content="Aimbot: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

CombatTab:CreateSlider({
    Name = "Aim Smoothness (1-15×)",
    Range = {1, 15}, Increment = 1, Suffix = "×", CurrentValue = 5,
    Callback = function(v) C.AimSmooth = v end,
})

CombatTab:CreateSlider({
    Name = "POV (0-360°)",
    Range = {0, 360}, Increment = 1, Suffix = "°", CurrentValue = 90,
    Callback = function(v) C.POV = v end,
})

CombatTab:CreateToggle({
    Name = "Show POV",
    CurrentValue = false,
    Callback = function(v) C.ShowPOV = v end,
})

CombatTab:CreateColorPicker({
    Name = "POV Color",
    Color = Color3.fromRGB(255, 0, 100),
    Callback = function(c) C.POVColor = c end,
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "UpperTorso", "LowerTorso", "LeftFoot", "RightFoot"},
    CurrentOption = "Head",
    Callback = function(o)
        if type(o) == "table" then C.AimPart = o[1] else C.AimPart = o end
    end,
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Callback = function(v) C.WallCheck = v end,
})

CombatTab:CreateToggle({
    Name = "Alive Check",
    CurrentValue = true,
    Callback = function(v) C.AliveCheck = v end,
})

-- ==================== TAB 2: VISUAL ====================
local VisualTab = Window:CreateTab("VISUAL", 4483362458)

VisualTab:CreateSection("ESP Toggle")

VisualTab:CreateToggle({
    Name = "ESP Line Player",
    CurrentValue = false,
    Callback = function(v) C.ESP_LinePlayer = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Line BOT",
    CurrentValue = false,
    Callback = function(v) C.ESP_LineBOT = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Name",
    CurrentValue = false,
    Callback = function(v) C.ESP_Name = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Health",
    CurrentValue = false,
    Callback = function(v) C.ESP_Health = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = false,
    Callback = function(v) C.ESP_Distance = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Box",
    CurrentValue = false,
    Callback = function(v) C.ESP_Box = v end,
})

VisualTab:CreateSection("ESP Colors")

VisualTab:CreateColorPicker({
    Name = "Line Player Color",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(c) C.ESP_LinePlayerColor = c end,
})

VisualTab:CreateColorPicker({
    Name = "Line BOT Color",
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(c) C.ESP_LineBOTColor = c end,
})

VisualTab:CreateColorPicker({
    Name = "Text Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(c) C.ESP_TextColor = c end,
})

VisualTab:CreateColorPicker({
    Name = "Box Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(c) C.ESP_BoxColor = c end,
})

-- ==================== TAB 3: PLAYER ====================
local PlayerTab = Window:CreateTab("PLAYER", 4483362458)

PlayerTab:CreateSection("Health")

PlayerTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(v) C.GodMode = v end,
})

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Callback = function(v) C.SpeedHack = v end,
})

PlayerTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 200}, Increment = 1, Suffix = "", CurrentValue = 50,
    Callback = function(v) C.SpeedValue = v end,
})

PlayerTab:CreateToggle({
    Name = "Jump Hack",
    CurrentValue = false,
    Callback = function(v) C.JumpHack = v end,
})

PlayerTab:CreateSlider({
    Name = "Jump Value",
    Range = {50, 300}, Increment = 5, Suffix = "", CurrentValue = 50,
    Callback = function(v) C.JumpValue = v end,
})

PlayerTab:CreateToggle({
    Name = "Infinity Jump",
    CurrentValue = false,
    Callback = function(v) C.InfJump = v end,
})

PlayerTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Callback = function(v) C.NoClip = v end,
})

PlayerTab:CreateSection("Fly")

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        C.Fly = v
        if v then startFly() else stopFly() end
    end,
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300}, Increment = 5, Suffix = "", CurrentValue = 50,
    Callback = function(v) C.FlySpeed = v end,
})

-- ==================== TAB 4: SHOP ====================
local ShopTab = Window:CreateTab("SHOP", 4483362458)

ShopTab:CreateSection("Auto Hack")

ShopTab:CreateToggle({
    Name = "Auto Hack Ruby & Money",
    CurrentValue = false,
    Callback = function(v)
        C.AutoHack = v
        Rayfield:Notify({Title="RENXX", Content="Auto Hack: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

ShopTab:CreateSlider({
    Name = "Target Value",
    Range = {9999, 9999999999}, Increment = 1, Suffix = "", CurrentValue = 999999999,
    Callback = function(v) C.TargetValue = v end,
})

ShopTab:CreateSlider({
    Name = "Scan Interval (detik)",
    Range = {0.1, 5}, Increment = 0.1, Suffix = "s", CurrentValue = 1,
    Callback = function(v) C.ScanInterval = v end,
})

ShopTab:CreateSection("Manual")

ShopTab:CreateButton({
    Name = "💎 Hack Ruby & Money Sekarang",
    Callback = function()
        scanAndHack()
        Rayfield:Notify({Title="RENXX", Content="Hack done!", Duration=2})
    end,
})

-- ==================== TAB 5: EXTRA ====================
local ExtraTab = Window:CreateTab("EXTRA", 4483362458)

ExtraTab:CreateSection("Teleport")

ExtraTab:CreateToggle({
    Name = "Teleport To Player/BOT",
    CurrentValue = false,
    Callback = function(v)
        C.Teleport = v
        Rayfield:Notify({Title="RENXX", Content="Teleport: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

ExtraTab:CreateDropdown({
    Name = "Teleport Set",
    Options = {"Behind", "Front", "Above", "Below", "Left", "Right"},
    CurrentOption = "Behind",
    Callback = function(o)
        if type(o) == "table" then C.TeleportSet = o[1] else C.TeleportSet = o end
    end,
})

ExtraTab:CreateSlider({
    Name = "Teleport Radius (0-10m)",
    Range = {0, 10}, Increment = 1, Suffix = "m", CurrentValue = 2,
    Callback = function(v) C.TeleportRadius = v end,
})

ExtraTab:CreateSlider({
    Name = "Teleport Delay (0-30 detik)",
    Range = {0, 30}, Increment = 1, Suffix = "s", CurrentValue = 5,
    Callback = function(v) C.TeleportDelay = v end,
})

-- ==================== POV CIRCLE ====================
local povCircle
if hasDrawing then
    pcall(function()
        povCircle = Drawing.new("Circle")
        povCircle.Visible = false
        povCircle.Thickness = 2
        povCircle.NumSides = 64
        povCircle.Filled = false
        povCircle.Transparency = 1
    end)
end

-- ==================== RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    -- POV Circle
    if povCircle then
        pcall(function()
            if C.ShowPOV and C.Aimbot then
                povCircle.Visible = true
                povCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
                povCircle.Radius = math.tan(math.rad(C.POV / 2)) * (Cam.ViewportSize.Y / 2)
                povCircle.Color = C.POVColor
            else
                povCircle.Visible = false
            end
        end)
    end

    -- Aimbot
    if C.Aimbot then
        local target = getNearestTarget()
        if target then
            local char = target.Parent
            local part = char:FindFirstChild(C.AimPart) or char:FindFirstChild("Head")
            if part then
                local targetCF = CFrame.new(Cam.CFrame.Position, part.Position)
                Cam.CFrame = Cam.CFrame:Lerp(targetCF, 1 / math.max(1, C.AimSmooth))
            end
        end
    end

    -- ESP Render
    if hasDrawing then
        local espActive = C.ESP_LinePlayer or C.ESP_LineBOT or C.ESP_Name 
                          or C.ESP_Health or C.ESP_Distance or C.ESP_Box
        if not espActive then
            for _, d in pairs(espCachePlayers) do hideESP(d) end
            for _, d in pairs(espCacheBots) do hideESP(d) end
        else
            -- PLAYER ESP
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and espCachePlayers[p] then
                    local d = espCachePlayers[p]
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local sp, on = Cam:WorldToViewportPoint(hrp.Position)
                        if on then
                            if C.ESP_LinePlayer then
                                d.line.Visible = true
                                d.line.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
                                d.line.To = Vector2.new(sp.X, sp.Y)
                                d.line.Color = C.ESP_LinePlayerColor
                                d.line.Thickness = 1
                            else d.line.Visible = false end

                            if C.ESP_Name then
                                d.name.Visible = true
                                d.name.Text = p.Name
                                d.name.Position = Vector2.new(sp.X, sp.Y - 50)
                                d.name.Color = C.ESP_TextColor
                                d.name.Size = 14
                                d.name.Center = true
                                d.name.Outline = true
                            else d.name.Visible = false end

                            if C.ESP_Health then
                                local hpP = hum.Health / hum.MaxHealth
                                d.hpBG.Visible = true
                                d.hpBG.Size = Vector2.new(4, 40)
                                d.hpBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
                                d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                d.hpBG.Filled = true
                                d.hpBar.Visible = true
                                d.hpBar.Size = Vector2.new(4, 40 * hpP)
                                d.hpBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hpP)))
                                d.hpBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hpP)
                                d.hpBar.Filled = true
                            else
                                d.hpBG.Visible = false
                                d.hpBar.Visible = false
                            end

                            if C.ESP_Distance then
                                local dist = (hrp.Position - Cam.CFrame.Position).Magnitude
                                d.dist.Visible = true
                                d.dist.Text = math.floor(dist) .. "m"
                                d.dist.Position = Vector2.new(sp.X, sp.Y + 25)
                                d.dist.Color = C.ESP_TextColor
                                d.dist.Size = 12
                                d.dist.Center = true
                                d.dist.Outline = true
                            else d.dist.Visible = false end

                            if C.ESP_Box then
                                d.box.Visible = true
                                d.box.Size = Vector2.new(50, 80)
                                d.box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                                d.box.Color = C.ESP_BoxColor
                                d.box.Thickness = 1
                                d.box.Filled = false
                            else d.box.Visible = false end
                        else hideESP(d) end
                    else hideESP(d) end
                end
            end

            -- BOT ESP
            local botFolder = Workspace:FindFirstChild("Game")
            if botFolder then
                botFolder = botFolder:FindFirstChild("__ServerBotCharacters")
            end
            if botFolder then
                for _, botChar in ipairs(botFolder:GetChildren()) do
                    local hum = botChar:FindFirstChildOfClass("Humanoid")
                    local hrp = botChar:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        local d = getOrCreateBotESP(botChar)
                        if d then
                            local sp, on = Cam:WorldToViewportPoint(hrp.Position)
                            if on then
                                if C.ESP_LineBOT then
                                    d.line.Visible = true
                                    d.line.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
                                    d.line.To = Vector2.new(sp.X, sp.Y)
                                    d.line.Color = C.ESP_LineBOTColor
                                    d.line.Thickness = 1
                                else d.line.Visible = false end

                                if C.ESP_Name then
                                    d.name.Visible = true
                                    d.name.Text = "[BOT] " .. botChar.Name
                                    d.name.Position = Vector2.new(sp.X, sp.Y - 50)
                                    d.name.Color = C.ESP_TextColor
                                    d.name.Size = 14
                                    d.name.Center = true
                                    d.name.Outline = true
                                else d.name.Visible = false end

                                if C.ESP_Health then
                                    local hpP = hum.Health / hum.MaxHealth
                                    d.hpBG.Visible = true
                                    d.hpBG.Size = Vector2.new(4, 40)
                                    d.hpBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
                                    d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                    d.hpBG.Filled = true
                                    d.hpBar.Visible = true
                                    d.hpBar.Size = Vector2.new(4, 40 * hpP)
                                    d.hpBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hpP)))
                                    d.hpBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hpP)
                                    d.hpBar.Filled = true
                                else
                                    d.hpBG.Visible = false
                                    d.hpBar.Visible = false
                                end

                                if C.ESP_Distance then
                                    local dist = (hrp.Position - Cam.CFrame.Position).Magnitude
                                    d.dist.Visible = true
                                    d.dist.Text = math.floor(dist) .. "m"
                                    d.dist.Position = Vector2.new(sp.X, sp.Y + 25)
                                    d.dist.Color = C.ESP_TextColor
                                    d.dist.Size = 12
                                    d.dist.Center = true
                                    d.dist.Outline = true
                                else d.dist.Visible = false end

                                if C.ESP_Box then
                                    d.box.Visible = true
                                    d.box.Size = Vector2.new(50, 80)
                                    d.box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                                    d.box.Color = C.ESP_BoxColor
                                    d.box.Thickness = 1
                                    d.box.Filled = false
                                else d.box.Visible = false end
                            else hideESP(d) end
                        end
                    end
                end
            end
        end
    end
end)

-- ==================== HEARTBEAT LOOP ====================
RunService.Heartbeat:Connect(function()
    -- Fly
    if C.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then
            flyBG.CFrame = Cam.CFrame
        end
    end

    -- ✅ FIX #3: Kill All pakai tick()
    if C.KillAll and tick() - lastShot >= (C.FireDelay / 1000) then
        killAll()
        lastShot = tick()
    end

    -- Teleport
    if C.Teleport then
        teleportToTarget()
    end

    -- Player Mods
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            -- ✅ FIX #7: GodMode error handling
            if C.GodMode and hum.Parent and hum.Health > 0 then
                pcall(function()
                    hum.MaxHealth = 99999
                    hum.Health = 99999
                end)
            end
            if C.SpeedHack then hum.WalkSpeed = C.SpeedValue end
            if C.JumpHack then
                hum.UseJumpPower = true
                hum.JumpPower = C.JumpValue
            end
            if C.NoClip then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end

    -- Shop Hack Scan
    if C.AutoHack and tick() - lastScan >= C.ScanInterval then
        scanAndHack()
        lastScan = tick()
    end
end)

-- ==================== INFINITY JUMP ====================
UserInputService.JumpRequest:Connect(function()
    if C.InfJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==================== CHARACTER ADDED ====================
-- ✅ FIX #6: Reset currentTarget
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    flyBV = nil
    flyBG = nil
    currentTarget = nil
    if C.Fly then startFly() end
end)

-- ==================== ANTI AFK ====================
-- ✅ FIX #5: pcall
LP.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ==================== NOTIFIKASI ====================
Rayfield:Notify({
    Title = "RENXX — AIMBOT FPS v2.2",
    Content = "Loaded! 7 Bugs Fixed! 38+ Features!",
    Duration = 5,
})

print("========================================")
print("RENXX — AIMBOT FPS - Loaded!")
print("By DEEP & RENXX")
print("========================================")
