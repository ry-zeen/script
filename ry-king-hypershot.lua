-- =======================================
-- RENXX HUB v2.5 | Hypershot
-- By: DEEP & RENXX
-- Library: Rayfield
-- =======================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== EXECUTOR CHECK ====================
local hasDrawing = pcall(function()
    local d = Drawing.new("Text")
    d:Remove()
end)

local hasHook = pcall(function()
    return hookmetamethod and getrawmetatable and setreadonly and newcclosure and getnamecallmethod
end)

local hasGC = pcall(function()
    return type(getgc(true)) == "table"
end)

-- ==================== HYPERSHOT REMOTE ====================
local Shoot = nil
pcall(function()
    local blaster = ReplicatedStorage:WaitForChild("Blaster", 10)
    if blaster then
        local remotes = blaster:WaitForChild("Remotes", 5)
        if remotes then
            Shoot = remotes:WaitForChild("Shoot", 5)
        end
    end
end)

if Shoot then
    print("[RENXX] Remote 'Shoot' loaded.")
else
    warn("[RENXX] Remote 'Shoot' NOT FOUND. Silent Aim disabled.")
end

-- ==================== ANTI-BAN STATS ====================
local AntiBan = {
    BlockedKick = 0,
    BlockedTeleport = 0,
    BlockedRemote = 0,
    BlockedDataSend = 0,
    BlockedCrash = 0,
    RateLimited = 0,
    SilentAimHit = 0,
}

-- ==================== CONFIG ====================
local Config = {
    -- Protection
    AntiKick = true,
    AntiTeleportVoid = true,
    AntiDetect = true,
    AntiDataSend = true,
    AntiCrash = true,
    RateLimiter = true,
    RandomizeSpeed = true,
    RandomizeAim = true,
    StealthMode = false,
    StealthReady = true,
    AntiFling = true,
    AntiAFK = true,
    -- Combat
    KillAll = false,
    FireDelay = 150,
    SilentAim = false,
    AimSmooth = 5,
    POV = 90,
    ShowPOV = false,
    POVColor = Color3.fromRGB(255, 0, 100),
    AimPart = "Head",
    SnapLine = false,
    SnapLineColor = Color3.fromRGB(255, 0, 100),
    TeamCheck = true,
    WallCheck = false,
    -- Visual
    ESPLine = false,
    ESPName = false,
    ESPHealth = false,
    ESPSkeleton = false,
    ESPDistance = false,
    ESPBox = false,
    ESPTeamColor = Color3.fromRGB(0, 255, 0),
    ESPEnemyColor = Color3.fromRGB(255, 0, 0),
    ESPBotColor = Color3.fromRGB(255, 255, 0),
    ESPTextColor = Color3.fromRGB(255, 255, 255),
    ESPSkeletonColor = Color3.fromRGB(0, 255, 255),
    -- Movement
    SpeedHack = false,
    SpeedValue = 30,
    JumpPower = false,
    JumpValue = 50,
    InfJump = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 50,
    -- Weapon
    InfAmmo = false,
    RapidFire = false,
    NoRecoil = false,
    NoSpread = false,
    FastReload = false,
}

-- ==================== STATE ====================
local aimTarget = nil
local aimTargetPart = nil
local flyBV = nil
local flyBG = nil
local lastShot = 0
local targetIndex = 1
local espData = {}
local originalNamecall = nil
local weaponCache = {}
local randomSpeedOffset = 0
local randomAimPart = "Head"

-- FIX #3: Fire counters terpisah
local fireCountSilent = 0
local fireCountKillAll = 0
local lastFireResetSilent = tick()
local lastFireResetKillAll = tick()

-- ==================== STEALTH MODE FUNCTION ====================
local function startStealthMode()
    if not Config.StealthMode then
        Config.StealthReady = true
        return
    end
    Config.StealthReady = false
    task.spawn(function()
        task.wait(30)
        if Config.StealthMode then
            Config.StealthReady = true
            pcall(function()
                Rayfield:Notify({
                    Title = "RENXX",
                    Content = "Stealth mode ready. Full features unlocked.",
                    Duration = 5,
                })
            end)
        end
    end)
end

-- ==================== RANDOM SPEED ====================
task.spawn(function()
    while task.wait(1) do
        if Config.RandomizeSpeed and Config.SpeedHack then
            randomSpeedOffset = math.random(-3, 3)
        end
    end
end)

-- ==================== RANDOM AIM PART ====================
task.spawn(function()
    while task.wait(0.5) do
        if Config.RandomizeAim and Config.SilentAim then
            local parts = {"Head", "UpperTorso", "LowerTorso"}
            randomAimPart = parts[math.random(1, #parts)]
        end
    end
end)

-- ==================== RATE LIMITER (FIX #3) ====================
local function canFire(source)
    if not Config.RateLimiter then return true end
    source = source or "silent"
    
    local now = tick()
    local count, resetTime
    
    if source == "killall" then
        count = fireCountKillAll
        resetTime = lastFireResetKillAll
    else
        count = fireCountSilent
        resetTime = lastFireResetSilent
    end
    
    if now - resetTime >= 1 then
        count = 0
        if source == "killall" then
            lastFireResetKillAll = now
        else
            lastFireResetSilent = now
        end
    end
    
    if count >= 8 then
        AntiBan.RateLimited = AntiBan.RateLimited + 1
        return false
    end
    
    count = count + 1
    if source == "killall" then
        fireCountKillAll = count
    else
        fireCountSilent = count
    end
    return true
end

-- ==================== HELPER ====================
local function getBlaster()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("Blaster") or char:FindFirstChildOfClass("Tool")
end

local function getAllTargets()
    local targets = {}
    local seen = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not seen[h] then
                seen[h] = true
                table.insert(targets, h)
            end
        end
    end
    local gameFolder = workspace:FindFirstChild("Game")
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

local function fovToRadius(fovDeg)
    return math.tan(math.rad(fovDeg / 2)) * (Camera.ViewportSize.Y / 2)
end

local function isSameTeam(player)
    local ok, result = pcall(function()
        if not LocalPlayer.Team or not player.Team then return false end
        return player.Team == LocalPlayer.Team
    end)
    return ok and result or false
end

local function hasLineOfSight(part)
    local ok, result = pcall(function()
        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin)
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
        return hit == nil or hit:IsDescendantOf(part.Parent)
    end)
    return ok and result or true
end

-- ==================== WEAPON SCANNER ====================
local function findWeaponTables()
    if not hasGC then return {} end
    local found = {}
    pcall(function()
        for _, v in next, getgc(true) do
            if typeof(v) == "table" then
                if rawget(v, "FireRate") or rawget(v, "Spread") 
                   or rawget(v, "MaxAmmo") or rawget(v, "Recoil")
                   or rawget(v, "BaseSpread") or rawget(v, "ReloadTime") then
                    table.insert(found, v)
                end
            end
        end
    end)
    return found
end

task.spawn(function()
    task.wait(5)
    weaponCache = findWeaponTables()
    while task.wait(10) do
        weaponCache = findWeaponTables()
    end
end)

local function applyWeaponMods()
    if not hasGC then return end
    for _, weapon in ipairs(weaponCache) do
        pcall(function()
            if Config.InfAmmo then
                if rawget(weapon, "MaxAmmo") then rawset(weapon, "MaxAmmo", 99999) end
                if rawget(weapon, "AmmoPerMag") then rawset(weapon, "AmmoPerMag", 9999) end
            end
            if Config.RapidFire then
                if rawget(weapon, "FireRate") then rawset(weapon, "FireRate", 0.05) end
            end
            if Config.NoRecoil then
                if rawget(weapon, "Recoil") then rawset(weapon, "Recoil", Vector3.zero) end
            end
            if Config.NoSpread then
                if rawget(weapon, "Spread") then rawset(weapon, "Spread", 0) end
                if rawget(weapon, "BaseSpread") then rawset(weapon, "BaseSpread", 0) end
            end
            if Config.FastReload then
                if rawget(weapon, "ReloadTime") then rawset(weapon, "ReloadTime", 0.1) end
            end
        end)
    end
end

-- ==================== GET TARGET ====================
local function getClosestTarget()
    if not (Config.SilentAim or Config.KillAll) then return nil, nil end
    if Config.StealthMode and not Config.StealthReady then return nil, nil end
    
    local closest = nil
    local closestPart = nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovRadius = fovToRadius(Config.POV)
    local aimPartName = Config.RandomizeAim and randomAimPart or Config.AimPart

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not (Config.TeamCheck and isSameTeam(player)) then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local part = player.Character:FindFirstChild(aimPartName) 
                    or player.Character:FindFirstChild("Head")
                    or player.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and part then
                    if not Config.WallCheck or hasLineOfSight(part) then
                        local sp, on = Camera:WorldToViewportPoint(part.Position)
                        if on then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d <= fovRadius and d < shortest then
                                shortest = d
                                closest = hum
                                closestPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    return closest, closestPart
end

-- ==================== KILL ALL ====================
local function killAll()
    if not Shoot then return end
    if Config.StealthMode and not Config.StealthReady then return end
    if not canFire("killall") then return end
    local blaster = getBlaster()
    if not blaster then return end
    local targets = getAllTargets()
    if #targets == 0 then return end
    if targetIndex > #targets then targetIndex = 1 end
    local target = targets[targetIndex]
    targetIndex = targetIndex + 1
    if not target or target.Health <= 0 then return end
    
    local useHeadshot = (randomAimPart == "Head") or (not Config.RandomizeAim)
    
    pcall(function()
        Shoot:FireServer(
            workspace:GetServerTimeNow(),
            blaster,
            Camera.CFrame,
            { ["1"] = target },
            { ["1"] = useHeadshot },
            { isQuickscope = false, isNoscope = true }
        )
    end)
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
    if move.Magnitude > 0 then move = move.Unit * Config.FlySpeed end
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

-- ==================== WINDOW ====================
local Window = Rayfield:CreateWindow({
    Name = "RENXX HUB v2.5 | Hypershot",
    LoadingTitle = "Loading RENXX HUB...",
    LoadingSubtitle = "By DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================== TAB 1: PROTECTION ====================
local ProtTab = Window:CreateTab("PROTECTION", 4483362458)

ProtTab:CreateSection("Core Anti-Ban")

ProtTab:CreateToggle({
    Name = "Anti Kick",
    CurrentValue = true,
    Callback = function(v)
        Config.AntiKick = v
        Rayfield:Notify({Title="RENXX", Content="Anti Kick: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

ProtTab:CreateToggle({
    Name = "Anti Teleport Void",
    CurrentValue = true,
    Callback = function(v) Config.AntiTeleportVoid = v end,
})

ProtTab:CreateToggle({
    Name = "Anti Detect",
    CurrentValue = true,
    Callback = function(v) Config.AntiDetect = v end,
})

ProtTab:CreateToggle({
    Name = "Anti Data Send",
    CurrentValue = true,
    Callback = function(v) Config.AntiDataSend = v end,
})

ProtTab:CreateToggle({
    Name = "Anti Crash",
    CurrentValue = true,
    Callback = function(v) Config.AntiCrash = v end,
})

ProtTab:CreateSection("Stealth")

ProtTab:CreateToggle({
    Name = "Rate Limiter",
    CurrentValue = true,
    Callback = function(v) Config.RateLimiter = v end,
})

ProtTab:CreateToggle({
    Name = "Randomize Speed",
    CurrentValue = true,
    Callback = function(v) Config.RandomizeSpeed = v end,
})

ProtTab:CreateToggle({
    Name = "Randomize Aim Part",
    CurrentValue = true,
    Callback = function(v) Config.RandomizeAim = v end,
})

-- FIX #1: Toggle Stealth Mode
ProtTab:CreateToggle({
    Name = "Stealth Mode (30s delay)",
    CurrentValue = false,
    Callback = function(v)
        Config.StealthMode = v
        if v then
            startStealthMode()
            Rayfield:Notify({Title="RENXX", Content="Stealth ON - 30s delay", Duration=3})
        else
            Config.StealthReady = true
            Rayfield:Notify({Title="RENXX", Content="Stealth OFF", Duration=2})
        end
    end,
})

ProtTab:CreateSection("Misc")

ProtTab:CreateToggle({
    Name = "Anti Fling",
    CurrentValue = true,
    Callback = function(v) Config.AntiFling = v end,
})

ProtTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Callback = function(v) Config.AntiAFK = v end,
})

ProtTab:CreateSection("Stats")

ProtTab:CreateButton({
    Name = "Show Protection Stats",
    Callback = function()
        Rayfield:Notify({
            Title = "Protection Stats",
            Content = string.format("Kick: %d | Remote: %d | Data: %d | Rate: %d | SilentAim: %d",
                AntiBan.BlockedKick, AntiBan.BlockedRemote, AntiBan.BlockedDataSend, 
                AntiBan.RateLimited, AntiBan.SilentAimHit),
            Duration = 5,
        })
    end,
})

-- ==================== TAB 2: COMBAT ====================
local CombatTab = Window:CreateTab("COMBAT", 4483362458)

CombatTab:CreateSection("Auto Kill")

CombatTab:CreateToggle({
    Name = "Kill All",
    CurrentValue = false,
    Callback = function(v)
        Config.KillAll = v
        Rayfield:Notify({Title="RENXX", Content="Kill All: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

CombatTab:CreateSlider({
    Name = "Fire Delay (ms)",
    Range = {50, 500}, Increment = 10, Suffix = "ms", CurrentValue = 150,
    Callback = function(v) Config.FireDelay = v end,
})

CombatTab:CreateSection("Silent Aim")

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(v)
        Config.SilentAim = v
        Rayfield:Notify({Title="RENXX", Content="Silent Aim: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

CombatTab:CreateSlider({
    Name = "Aim Smoothness (Camera)",
    Range = {1, 15}, Increment = 1, Suffix = "x", CurrentValue = 5,
    Callback = function(v) Config.AimSmooth = v end,
})

CombatTab:CreateSlider({
    Name = "FOV",
    Range = {30, 360}, Increment = 1, Suffix = "deg", CurrentValue = 90,
    Callback = function(v) Config.POV = v end,
})

CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Callback = function(v) Config.ShowPOV = v end,
})

CombatTab:CreateColorPicker({
    Name = "FOV Color",
    Color = Color3.fromRGB(255, 0, 100),
    Callback = function(c) Config.POVColor = c end,
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(o)
        if type(o) == "table" then Config.AimPart = o[1] else Config.AimPart = o end
    end,
})

CombatTab:CreateSection("Snap Line")

CombatTab:CreateToggle({
    Name = "Snap Line",
    CurrentValue = false,
    Callback = function(v) Config.SnapLine = v end,
})

CombatTab:CreateColorPicker({
    Name = "Snap Line Color",
    Color = Color3.fromRGB(255, 0, 100),
    Callback = function(c) Config.SnapLineColor = c end,
})

CombatTab:CreateSection("Filter")

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.TeamCheck = v end,
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Callback = function(v) Config.WallCheck = v end,
})

-- ==================== TAB 3: VISUAL ====================
local VisualTab = Window:CreateTab("VISUAL", 4483362458)

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({Name = "ESP Line", CurrentValue = false, Callback = function(v) Config.ESPLine = v end})
VisualTab:CreateToggle({Name = "ESP Name", CurrentValue = false, Callback = function(v) Config.ESPName = v end})
VisualTab:CreateToggle({Name = "ESP Health", CurrentValue = false, Callback = function(v) Config.ESPHealth = v end})
VisualTab:CreateToggle({Name = "ESP Skeleton", CurrentValue = false, Callback = function(v) Config.ESPSkeleton = v end})
VisualTab:CreateToggle({Name = "ESP Distance", CurrentValue = false, Callback = function(v) Config.ESPDistance = v end})
VisualTab:CreateToggle({Name = "ESP Box", CurrentValue = false, Callback = function(v) Config.ESPBox = v end})

VisualTab:CreateSection("Colors")

VisualTab:CreateColorPicker({Name = "Team Color", Color = Color3.fromRGB(0, 255, 0), Callback = function(c) Config.ESPTeamColor = c end})
VisualTab:CreateColorPicker({Name = "Enemy Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(c) Config.ESPEnemyColor = c end})
VisualTab:CreateColorPicker({Name = "BOT Color", Color = Color3.fromRGB(255, 255, 0), Callback = function(c) Config.ESPBotColor = c end})
VisualTab:CreateColorPicker({Name = "Text Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(c) Config.ESPTextColor = c end})
VisualTab:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(0, 255, 255), Callback = function(c) Config.ESPSkeletonColor = c end})

-- ==================== TAB 4: MOVEMENT ====================
local MoveTab = Window:CreateTab("MOVEMENT", 4483362458)

MoveTab:CreateSection("Speed")

MoveTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Callback = function(v) Config.SpeedHack = v end,
})

MoveTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 60}, Increment = 1, Suffix = "", CurrentValue = 30,
    Callback = function(v) Config.SpeedValue = v end,
})

MoveTab:CreateSection("Jump")

MoveTab:CreateToggle({Name = "Jump Power", CurrentValue = false, Callback = function(v) Config.JumpPower = v end})
MoveTab:CreateSlider({Name = "Jump Value", Range = {50, 200}, Increment = 5, Suffix = "", CurrentValue = 50, Callback = function(v) Config.JumpValue = v end})
MoveTab:CreateToggle({Name = "Infinity Jump", CurrentValue = false, Callback = function(v) Config.InfJump = v end})

MoveTab:CreateSection("Fly")

MoveTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        Config.Fly = v
        if v then startFly() else stopFly() end
    end,
})

MoveTab:CreateSlider({Name = "Fly Speed", Range = {10, 200}, Increment = 5, Suffix = "", CurrentValue = 50, Callback = function(v) Config.FlySpeed = v end})

MoveTab:CreateSection("Misc")

MoveTab:CreateToggle({Name = "No Clip", CurrentValue = false, Callback = function(v) Config.NoClip = v end})

-- ==================== TAB 5: WEAPON ====================
local WeaponTab = Window:CreateTab("WEAPON", 4483362458)

WeaponTab:CreateSection("Ammo")

WeaponTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Callback = function(v) Config.InfAmmo = v end,
})

WeaponTab:CreateToggle({
    Name = "Rapid Fire",
    CurrentValue = false,
    Callback = function(v) Config.RapidFire = v end,
})

WeaponTab:CreateToggle({Name = "Fast Reload", CurrentValue = false, Callback = function(v) Config.FastReload = v end})

WeaponTab:CreateSection("Accuracy")

WeaponTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Callback = function(v) Config.NoRecoil = v end,
})

WeaponTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
    Callback = function(v) Config.NoSpread = v end,
})

-- ==================== DRAWINGS ====================
local povCircle, snapLine
if hasDrawing then
    pcall(function()
        povCircle = Drawing.new("Circle")
        povCircle.Visible = false
        povCircle.Thickness = 2
        povCircle.NumSides = 64
        povCircle.Filled = false
        povCircle.Transparency = 1

        snapLine = Drawing.new("Line")
        snapLine.Visible = false
        snapLine.Thickness = 2
        snapLine.Color = Config.SnapLineColor
    end)
end

-- ==================== ESP DRAWINGS ====================
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
            skeleton = {},
        }
    end)
    if not ok then return nil end
    for i = 1, 14 do
        d.skeleton[i] = Drawing.new("Line")
    end
    return d
end

local function destroyESP(d)
    if not d then return end
    for k, v in pairs(d) do
        if k == "skeleton" then
            for _, s in pairs(v) do pcall(function() s:Remove() end) end
        else
            pcall(function() v:Remove() end)
        end
    end
end

local function hideESP(d)
    if not d then return end
    for k, v in pairs(d) do
        if k == "skeleton" then
            for _, s in pairs(v) do pcall(function() s.Visible = false end) end
        else
            pcall(function() v.Visible = false end)
        end
    end
end

if hasDrawing then
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then espData[p] = createESP() end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then espData[p] = createESP() end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if espData[p] then destroyESP(espData[p]) espData[p] = nil end
    end)
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

-- ==================== TARGET UPDATE ====================
task.spawn(function()
    while task.wait(0.1) do
        aimTarget, aimTargetPart = getClosestTarget()
    end
end)

-- ==================== RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    if povCircle then
        pcall(function()
            if Config.ShowPOV and Config.SilentAim then
                povCircle.Visible = true
                povCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                povCircle.Radius = fovToRadius(Config.POV)
                povCircle.Color = Config.POVColor
            else
                povCircle.Visible = false
            end
        end)
    end

    if snapLine then
        pcall(function()
            if Config.SnapLine and aimTargetPart and aimTargetPart.Parent then
                local sp, on = Camera:WorldToViewportPoint(aimTargetPart.Position)
                if on then
                    snapLine.Visible = true
                    snapLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    snapLine.To = Vector2.new(sp.X, sp.Y)
                    snapLine.Color = Config.SnapLineColor
                else
                    snapLine.Visible = false
                end
            else
                snapLine.Visible = false
            end
        end)
    end

    if Config.SilentAim and aimTargetPart and aimTargetPart.Parent and Config.AimSmooth > 1 then
        local targetCF = CFrame.new(Camera.CFrame.Position, aimTargetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(1, Config.AimSmooth))
    end

    if hasDrawing then
        local espActive = Config.ESPLine or Config.ESPName or Config.ESPHealth 
            or Config.ESPSkeleton or Config.ESPDistance or Config.ESPBox
        if not espActive then
            for _, d in pairs(espData) do hideESP(d) end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and espData[p] then
                    local d = espData[p]
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local sp, on = Camera:WorldToViewportPoint(hrp.Position)
                        if on then
                            local isTeam = isSameTeam(p)
                            local lineColor = isTeam and Config.ESPTeamColor or Config.ESPEnemyColor

                            if Config.ESPLine then
                                d.line.Visible = true
                                d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                d.line.To = Vector2.new(sp.X, sp.Y)
                                d.line.Color = lineColor
                                d.line.Thickness = 1
                            else d.line.Visible = false end

                            if Config.ESPName then
                                d.name.Visible = true
                                d.name.Text = p.Name
                                d.name.Position = Vector2.new(sp.X, sp.Y - 50)
                                d.name.Color = Config.ESPTextColor
                                d.name.Size = 14
                                d.name.Center = true
                                d.name.Outline = true
                            else d.name.Visible = false end

                            if Config.ESPHealth then
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

                            if Config.ESPDistance then
                                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                d.dist.Visible = true
                                d.dist.Text = math.floor(dist) .. "m"
                                d.dist.Position = Vector2.new(sp.X, sp.Y + 25)
                                d.dist.Color = Config.ESPTextColor
                                d.dist.Size = 12
                                d.dist.Center = true
                                d.dist.Outline = true
                            else d.dist.Visible = false end

                            if Config.ESPBox then
                                d.box.Visible = true
                                d.box.Size = Vector2.new(50, 80)
                                d.box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                                d.box.Color = lineColor
                                d.box.Thickness = 1
                                d.box.Filled = false
                            else d.box.Visible = false end

                            if Config.ESPSkeleton then
                                local useBones = bonesR15
                                if p.Character:FindFirstChild("Torso") and not p.Character:FindFirstChild("UpperTorso") then
                                    useBones = bonesR6
                                end
                                for i, bone in pairs(useBones) do
                                    local p1 = p.Character:FindFirstChild(bone[1])
                                    local p2 = p.Character:FindFirstChild(bone[2])
                                    if p1 and p2 and d.skeleton[i] then
                                        local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                                        local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                                        if on1 and on2 then
                                            d.skeleton[i].Visible = true
                                            d.skeleton[i].From = Vector2.new(pos1.X, pos1.Y)
                                            d.skeleton[i].To = Vector2.new(pos2.X, pos2.Y)
                                            d.skeleton[i].Color = Config.ESPSkeletonColor
                                            d.skeleton[i].Thickness = 1
                                        else
                                            d.skeleton[i].Visible = false
                                        end
                                    else
                                        if d.skeleton[i] then d.skeleton[i].Visible = false end
                                    end
                                end
                            else
                                for _, s in pairs(d.skeleton) do s.Visible = false end
                            end
                        else
                            hideESP(d)
                        end
                    else
                        hideESP(d)
                    end
                end
            end
        end
    end
end)

-- ==================== HEARTBEAT LOOP ====================
RunService.Heartbeat:Connect(function()
    if Config.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then flyBG.CFrame = Camera.CFrame end
    end

    if Config.KillAll and tick() - lastShot >= (Config.FireDelay / 1000) then
        killAll()
        lastShot = tick()
    end

    if Config.InfAmmo or Config.RapidFire or Config.NoRecoil or Config.NoSpread or Config.FastReload then
        applyWeaponMods()
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.SpeedHack then
                local speed = Config.SpeedValue
                if Config.RandomizeSpeed then
                    speed = speed + randomSpeedOffset
                end
                hum.WalkSpeed = math.clamp(speed, 16, 60)
            end
            if Config.JumpPower then
                hum.UseJumpPower = true
                hum.JumpPower = Config.JumpValue
            end
            if Config.NoClip then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end
end)

-- ==================== INFINITY JUMP ====================
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==================== ANTI FLING ====================
RunService.Heartbeat:Connect(function()
    if Config.AntiFling and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Velocity.Magnitude > 200 then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

-- ==================== ANTI AFK ====================
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ==================== SILENT AIM HOOK ====================
if hasHook and Shoot then
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        originalNamecall = mt.__namecall
        local newc = newcclosure or function(f) return f end

        mt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if not method then return originalNamecall(self, ...) end

            if Config.AntiKick and method == "Kick" and self == LocalPlayer then
                AntiBan.BlockedKick = AntiBan.BlockedKick + 1
                return nil
            end

            -- FIX #2: Anti Teleport Void (logika baru)
            if Config.AntiTeleportVoid and (method == "FireServer" or method == "InvokeServer") 
               and typeof(self) == "Instance" then
                local n = self.Name:lower()
                if n:find("void") or n:find("sendtovoid") or n:find("kicktovoid") 
                   or n:find("teleportvoid") or n:find("sendback") then
                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local myPos = myHRP and myHRP.Position
                    
                    for i = 1, #args do
                        local pos = nil
                        if typeof(args[i]) == "CFrame" then
                            pos = args[i].Position
                        elseif typeof(args[i]) == "Vector3" then
                            pos = args[i]
                        end
                        
                        if pos then
                            local isVoidY = pos.Y < -100 or pos.Y > 50000
                            local isFarFromPlayer = false
                            if myPos then
                                isFarFromPlayer = (pos - myPos).Magnitude > 5000
                            end
                            
                            if isVoidY or isFarFromPlayer then
                                AntiBan.BlockedTeleport = AntiBan.BlockedTeleport + 1
                                return nil
                            end
                        end
                    end
                end
            end

            if (Config.AntiDetect or Config.AntiDataSend) 
               and (method == "FireServer" or method == "InvokeServer")
               and typeof(self) == "Instance" then
                local n = self.Name:lower()
                if Config.AntiDetect then
                    if n:find("detect") or n:find("anticheat") or n:find("flag") 
                       or n:find("report") or n:find("log") then
                        AntiBan.BlockedRemote = AntiBan.BlockedRemote + 1
                        return nil
                    end
                end
                if Config.AntiDataSend then
                    if n:find("watch") or n:find("monitor") or n:find("trace") 
                       or n:find("capture") then
                        AntiBan.BlockedDataSend = AntiBan.BlockedDataSend + 1
                        return nil
                    end
                end
            end

            if Config.AntiCrash and method == "FireServer" and typeof(self) == "Instance" then
                local n = self.Name:lower()
                if n:find("crash") or n:find("disconnect") then
                    AntiBan.BlockedCrash = AntiBan.BlockedCrash + 1
                    return nil
                end
            end

            -- FIX #4: Silent Aim dengan typeof(self) check
            if Config.SilentAim and aimTarget and aimTarget.Parent 
               and method == "FireServer" 
               and typeof(self) == "Instance"
               and self == Shoot then
                
                if Config.StealthMode and not Config.StealthReady then
                    return originalNamecall(self, table.unpack(args))
                end
                
                if not canFire("silent") then
                    return nil
                end
                
                local part = aimTarget.Parent:FindFirstChild(Config.AimPart)
                    or aimTarget.Parent:FindFirstChild("Head")
                    or aimTarget.Parent:FindFirstChild("HumanoidRootPart")
                
                if part then
                    local aimCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                    local aimVector = part.Position
                    
                    for i = 1, #args do
                        local arg = args[i]
                        local argType = typeof(arg)
                        
                        if argType == "CFrame" then
                            args[i] = aimCFrame
                        elseif argType == "Vector3" then
                            args[i] = aimVector
                        elseif argType == "Instance" and arg:IsA("BasePart") then
                            args[i] = part
                        elseif argType == "table" then
                            for k, v in pairs(arg) do
                                local vt = typeof(v)
                                if vt == "CFrame" then
                                    arg[k] = aimCFrame
                                elseif vt == "Vector3" then
                                    arg[k] = aimVector
                                elseif vt == "Instance" and v:IsA("BasePart") then
                                    arg[k] = part
                                end
                            end
                        end
                    end
                    
                    AntiBan.SilentAimHit = AntiBan.SilentAimHit + 1
                end
            end

            return originalNamecall(self, table.unpack(args))
        end)
        setreadonly(mt, true)
    end)
    
    print("[RENXX] Silent Aim hook AKTIF.")
else
    warn("[RENXX] Executor gak support hook. Silent Aim DISABLED.")
end

-- ==================== CHARACTER ADDED ====================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    flyBV = nil
    flyBG = nil
    if Config.Fly then startFly() end
end)

-- ==================== NOTIFIKASI ====================
Rayfield:Notify({
    Title = "RENXX HUB v2.5",
    Content = "Loaded! Silent Aim + Anti-Ban Active",
    Duration = 5,
})

print("RENXX HUB v2.5")
print("Silent Aim: " .. (hasHook and Shoot and "READY" or "DISABLED"))
print("By DEEP & RENXX")
