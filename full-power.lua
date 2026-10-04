-- =======================================
-- RENXX HUB v3.0 | Hypershot
-- By: DEEP & RENXX
-- Library: Rayfield
-- All Features Working + Fast Reload (Tebakan)
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
    print("[RENXX] Remote Shoot loaded.")
else
    warn("[RENXX] Remote Shoot NOT FOUND.")
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
    AntiFling = true,
    AntiAFK = true,
    -- Combat
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
    ESPDistance = false,
    ESPBox = false,
    ESPTeamColor = Color3.fromRGB(0, 255, 0),
    ESPEnemyColor = Color3.fromRGB(255, 0, 0),
    ESPBotColor = Color3.fromRGB(255, 255, 0),
    ESPTextColor = Color3.fromRGB(255, 255, 255),
    ESPBoxColor = Color3.fromRGB(255, 0, 0),
    -- Weapon
    InfAmmo = false,
    RapidFire = false,
    FireRate = 0.01,
    NoRecoil = false,
    NoSpread = false,
    FastReload = false,
    ReloadMultiplier = 10,
    DamageHack = false,
    DamageValue = 999,
    -- Movement
    SpeedHack = false,
    SpeedValue = 30,
    JumpPower = false,
    JumpValue = 50,
    InfJump = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 50,
}

-- ==================== STATE ====================
local aimTarget = nil
local aimTargetPart = nil
local flyBV = nil
local flyBG = nil
local espData = {}
local botESP = {}
local originalNamecall = nil
local weaponCache = {}

-- ==================== HELPER ====================
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
    if not Config.WallCheck then return true end
    local ok, result = pcall(function()
        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin)
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
        return hit == nil or hit:IsDescendantOf(part.Parent)
    end)
    return ok and result or true
end

local function getBlaster()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("Blaster") or char:FindFirstChildOfClass("Tool")
end

-- ==================== AUTO-DETECT BOT ====================
local function getAllBots()
    local bots = {}
    local playerChars = {}
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            playerChars[p.Character] = true
        end
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not playerChars[obj] then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = obj:FindFirstChild("Head")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if head and hrp then
                    table.insert(bots, obj)
                end
            end
        end
    end
    
    return bots
end

-- ==================== WEAPON SCANNER ====================
local function findWeaponTables()
    if not hasGC then return {} end
    local found = {}
    pcall(function()
        for _, v in next, getgc(true) do
            if typeof(v) == "table" then
                if rawget(v, "FireInterval") or rawget(v, "BaseSpread") 
                   or rawget(v, "DirectDamage") or rawget(v, "MaxRotRecoil")
                   or rawget(v, "FillAmmo") or rawget(v, "ShootDelay") then
                    table.insert(found, v)
                end
            end
        end
    end)
    return found
end

task.spawn(function()
    task.wait(3)
    weaponCache = findWeaponTables()
    print("[RENXX] Weapon tables: " .. #weaponCache)
    while task.wait(10) do
        weaponCache = findWeaponTables()
    end
end)

local function applyWeaponMods()
    if not hasGC then return end
    for _, weapon in ipairs(weaponCache) do
        pcall(function()
            -- INF AMMO
            if Config.InfAmmo then
                if rawget(weapon, "FillAmmo") then rawset(weapon, "FillAmmo", 9999) end
                if rawget(weapon, "MaxAmmo") then rawset(weapon, "MaxAmmo", 99999) end
                if rawget(weapon, "AmmoPerMag") then rawset(weapon, "AmmoPerMag", 9999) end
            end
            
            -- NO RECOIL
            if Config.NoRecoil then
                if rawget(weapon, "MaxRotRecoil") then rawset(weapon, "MaxRotRecoil", Vector3.zero) end
                if rawget(weapon, "MinRotRecoil") then rawset(weapon, "MinRotRecoil", Vector3.zero) end
                if rawget(weapon, "MaxCamRecoil") then rawset(weapon, "MaxCamRecoil", Vector3.zero) end
                if rawget(weapon, "MinCamRecoil") then rawset(weapon, "MinCamRecoil", Vector3.zero) end
                if rawget(weapon, "MaxTransRecoil") then rawset(weapon, "MaxTransRecoil", Vector3.zero) end
                if rawget(weapon, "MinTransRecoil") then rawset(weapon, "MinTransRecoil", Vector3.zero) end
                if rawget(weapon, "RotRecoilConstant") then rawset(weapon, "RotRecoilConstant", 0) end
                if rawget(weapon, "CamRecoilConstant") then rawset(weapon, "CamRecoilConstant", 0) end
                if rawget(weapon, "TransRecoilConstant") then rawset(weapon, "TransRecoilConstant", 0) end
            end
            
            -- NO SPREAD
            if Config.NoSpread then
                if rawget(weapon, "BaseSpread") then rawset(weapon, "BaseSpread", 0) end
                if rawget(weapon, "ScopeSpreadMultiplier") then rawset(weapon, "ScopeSpreadMultiplier", 0) end
            end
            
            -- RAPID FIRE
            if Config.RapidFire then
                local rate = Config.FireRate
                if rawget(weapon, "FireInterval") then rawset(weapon, "FireInterval", rate) end
                if rawget(weapon, "ShootDelay") then rawset(weapon, "ShootDelay", rate) end
                if rawget(weapon, "AcquireDelay") then rawset(weapon, "AcquireDelay", rate) end
                if rawget(weapon, "Debounce") then rawset(weapon, "Debounce", rate) end
                if rawget(weapon, "FireRate") then rawset(weapon, "FireRate", rate) end
                if rawget(weapon, "FireDelay") then rawset(weapon, "FireDelay", rate) end
                if rawget(weapon, "Cooldown") then rawset(weapon, "Cooldown", rate) end
                if rawget(weapon, "DelayUntilLoop") then rawset(weapon, "DelayUntilLoop", 0) end
                if rawget(weapon, "ProjSpeed") and rawget(weapon, "ProjSpeed") > 100 then
                    rawset(weapon, "ProjSpeed", 9999)
                end
            end
            
            -- DAMAGE HACK
            if Config.DamageHack then
                local dmg = Config.DamageValue
                if rawget(weapon, "DirectDamage") then rawset(weapon, "DirectDamage", dmg) end
                if rawget(weapon, "HeadDamage") then rawset(weapon, "HeadDamage", dmg) end
                if rawget(weapon, "DirectHeadDamage") then rawset(weapon, "DirectHeadDamage", dmg) end
                if rawget(weapon, "AlternateDamage") then rawset(weapon, "AlternateDamage", dmg) end
                if rawget(weapon, "ExplosiveDamage") then rawset(weapon, "ExplosiveDamage", dmg) end
            end
            
            -- FAST RELOAD (Tebakan)
            if Config.FastReload then
                local mult = Config.ReloadMultiplier
                if rawget(weapon, "ReloadTime") then rawset(weapon, "ReloadTime", 1 / mult) end
                if rawget(weapon, "ReloadSpeed") and typeof(rawget(weapon, "ReloadSpeed")) == "number" then
                    rawset(weapon, "ReloadSpeed", mult * 10)
                end
                if rawget(weapon, "ReloadDuration") then rawset(weapon, "ReloadDuration", 1 / mult) end
                if rawget(weapon, "ReloadDelay") then rawset(weapon, "ReloadDelay", 1 / mult) end
                if rawget(weapon, "CD") then rawset(weapon, "CD", 0.1) end
                if rawget(weapon, "ShotgunReloadPellets") then rawset(weapon, "ShotgunReloadPellets", 999) end
                
                local reloadTable = rawget(weapon, "Reload")
                if typeof(reloadTable) == "table" then
                    if rawget(reloadTable, "Time") then rawset(reloadTable, "Time", 1 / mult) end
                    if rawget(reloadTable, "Duration") then rawset(reloadTable, "Duration", 1 / mult) end
                    if rawget(reloadTable, "Speed") then rawset(reloadTable, "Speed", mult * 10) end
                    if rawget(reloadTable, "Delay") then rawset(reloadTable, "Delay", 1 / mult) end
                end
                
                -- Scan semua property yang namanya mirip "reload"
                for k, v in pairs(weapon) do
                    local keyLower = tostring(k):lower()
                    if keyLower:find("reload") and typeof(v) == "number" then
                        if v > 0.1 and v < 20 then
                            rawset(weapon, k, 1 / mult)
                        elseif v > 20 then
                            rawset(weapon, k, v * mult)
                        end
                    end
                end
            end
        end)
    end
end

-- ==================== GET TARGET (PLAYER + BOT) ====================
local function getClosestTarget()
    if not Config.SilentAim then return nil, nil end
    
    local closest, closestPart = nil, nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovRadius = fovToRadius(Config.POV)
    local aimPartName = Config.AimPart

    -- Loop PLAYER
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
    
    -- Loop BOT
    local bots = getAllBots()
    for _, botChar in ipairs(bots) do
        local hum = botChar:FindFirstChildOfClass("Humanoid")
        local part = botChar:FindFirstChild(aimPartName)
            or botChar:FindFirstChild("Head")
            or botChar:FindFirstChild("HumanoidRootPart")
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
    
    return closest, closestPart
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
    Name = "RENXX HUB v3.0 | Hypershot",
    LoadingTitle = "Loading RENXX...",
    LoadingSubtitle = "By DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================== TAB 1: PROTECTION ====================
local ProtTab = Window:CreateTab("PROTECTION", 4483362458)

ProtTab:CreateSection("Anti Features")

ProtTab:CreateToggle({
    Name = "Anti Kick",
    CurrentValue = true,
    Callback = function(v) Config.AntiKick = v end,
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
            Content = string.format("Kick: %d | Remote: %d | Data: %d | Rate: %d | Silent: %d",
                AntiBan.BlockedKick, AntiBan.BlockedRemote, AntiBan.BlockedDataSend, 
                AntiBan.RateLimited, AntiBan.SilentAimHit),
            Duration = 5,
        })
    end,
})

-- ==================== TAB 2: COMBAT ====================
local CombatTab = Window:CreateTab("COMBAT", 4483362458)

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
    Name = "Aim Smoothness",
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
VisualTab:CreateToggle({Name = "ESP Distance", CurrentValue = false, Callback = function(v) Config.ESPDistance = v end})
VisualTab:CreateToggle({Name = "ESP Box", CurrentValue = false, Callback = function(v) Config.ESPBox = v end})

VisualTab:CreateSection("Colors")

VisualTab:CreateColorPicker({Name = "Team Color", Color = Color3.fromRGB(0, 255, 0), Callback = function(c) Config.ESPTeamColor = c end})
VisualTab:CreateColorPicker({Name = "Enemy Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(c) Config.ESPEnemyColor = c end})
VisualTab:CreateColorPicker({Name = "BOT Color", Color = Color3.fromRGB(255, 255, 0), Callback = function(c) Config.ESPBotColor = c end})
VisualTab:CreateColorPicker({Name = "Text Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(c) Config.ESPTextColor = c end})
VisualTab:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(c) Config.ESPBoxColor = c end})

-- ==================== TAB 4: WEAPON ====================
local WeaponTab = Window:CreateTab("WEAPON", 4483362458)

WeaponTab:CreateSection("Ammo")

WeaponTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Callback = function(v)
        Config.InfAmmo = v
        Rayfield:Notify({Title="RENXX", Content="Inf Ammo: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

WeaponTab:CreateSection("Accuracy")

WeaponTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Callback = function(v)
        Config.NoRecoil = v
        Rayfield:Notify({Title="RENXX", Content="No Recoil: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

WeaponTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
    Callback = function(v)
        Config.NoSpread = v
        Rayfield:Notify({Title="RENXX", Content="No Spread: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

WeaponTab:CreateSection("Fire Rate")

WeaponTab:CreateToggle({
    Name = "Rapid Fire",
    CurrentValue = false,
    Callback = function(v)
        Config.RapidFire = v
        Rayfield:Notify({Title="RENXX", Content="Rapid Fire: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

WeaponTab:CreateSlider({
    Name = "Fire Rate Value",
    Range = {1, 100}, Increment = 1, Suffix = " (x0.01s)", CurrentValue = 1,
    Callback = function(v) Config.FireRate = v / 100 end,
})

WeaponTab:CreateSection("Reload")

WeaponTab:CreateToggle({
    Name = "Fast Reload",
    CurrentValue = false,
    Callback = function(v)
        Config.FastReload = v
        Rayfield:Notify({Title="RENXX", Content="Fast Reload: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

WeaponTab:CreateSlider({
    Name = "Reload Speed Multiplier",
    Range = {1, 100}, Increment = 1, Suffix = "x", CurrentValue = 10,
    Callback = function(v) Config.ReloadMultiplier = v end,
})

WeaponTab:CreateSection("Damage")

WeaponTab:CreateToggle({
    Name = "Damage Hack",
    CurrentValue = false,
    Callback = function(v)
        Config.DamageHack = v
        Rayfield:Notify({Title="RENXX", Content="Damage Hack: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

WeaponTab:CreateSlider({
    Name = "Damage Value",
    Range = {100, 99999}, Increment = 100, Suffix = " dmg", CurrentValue = 999,
    Callback = function(v) Config.DamageValue = v end,
})

-- ==================== TAB 5: MOVEMENT ====================
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
        }
    end)
    if not ok then return nil end
    return d
end

local function destroyESP(d)
    if not d then return end
    for k, v in pairs(d) do
        pcall(function() v:Remove() end)
    end
end

local function hideESP(d)
    if not d then return end
    for k, v in pairs(d) do
        pcall(function() v.Visible = false end)
    end
end

-- Player ESP init
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

-- Bot ESP cleanup
task.spawn(function()
    while task.wait(1.5) do
        for char, d in pairs(botESP) do
            if not char.Parent then
                destroyESP(d)
                botESP[char] = nil
            else
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then
                    destroyESP(d)
                    botESP[char] = nil
                end
            end
        end
    end
end)

-- ==================== TARGET UPDATE ====================
task.spawn(function()
    while task.wait(0.1) do
        aimTarget, aimTargetPart = getClosestTarget()
    end
end)

-- ==================== RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    -- POV Circle
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

    -- Snap Line
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

    -- Camera aim
    if Config.SilentAim and aimTargetPart and aimTargetPart.Parent and Config.AimSmooth > 1 then
        local targetCF = CFrame.new(Camera.CFrame.Position, aimTargetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(1, Config.AimSmooth))
    end

    -- ESP
    if hasDrawing then
        local espActive = Config.ESPLine or Config.ESPName or Config.ESPHealth 
            or Config.ESPDistance or Config.ESPBox
        if not espActive then
            for _, d in pairs(espData) do hideESP(d) end
            for _, d in pairs(botESP) do hideESP(d) end
        else
            -- PLAYER ESP
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

                            if Config.ESPLine then                                d.line.Visible = true
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
                                d.box.Color = Config.ESPBoxColor
                                d.box.Thickness = 1
                                d.box.Filled = false
                            else d.box.Visible = false end
                        else
                            hideESP(d)
                        end
                    else
                        hideESP(d)
                    end
                end
            end

            -- BOT ESP
            local bots = getAllBots()
            for _, botChar in ipairs(bots) do
                local hum = botChar:FindFirstChildOfClass("Humanoid")
                local hrp = botChar:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    if not botESP[botChar] then
                        botESP[botChar] = createESP()
                    end
                    local d = botESP[botChar]
                    if d then
                        local sp, on = Camera:WorldToViewportPoint(hrp.Position)
                        if on then
                            if Config.ESPLine then
                                d.line.Visible = true
                                d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                d.line.To = Vector2.new(sp.X, sp.Y)
                                d.line.Color = Config.ESPBotColor
                                d.line.Thickness = 1
                            else d.line.Visible = false end

                            if Config.ESPName then
                                d.name.Visible = true
                                d.name.Text = "[BOT] " .. botChar.Name
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
                                d.box.Color = Config.ESPBotColor
                                d.box.Thickness = 1
                                d.box.Filled = false
                            else d.box.Visible = false end
                        else
                            hideESP(d)
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
    if Config.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then flyBG.CFrame = Camera.CFrame end
    end

    -- Weapon Mods
    if Config.InfAmmo or Config.RapidFire or Config.NoRecoil or Config.NoSpread 
       or Config.FastReload or Config.DamageHack then
        applyWeaponMods()
    end

    -- Player Mods
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.SpeedHack then hum.WalkSpeed = Config.SpeedValue end
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

            -- Anti Kick
            if Config.AntiKick and method == "Kick" and self == LocalPlayer then
                AntiBan.BlockedKick = AntiBan.BlockedKick + 1
                return nil
            end

            -- Anti Teleport Void
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
                            local isFarFromPlayer = myPos and (pos - myPos).Magnitude > 5000
                            if isVoidY or isFarFromPlayer then
                                AntiBan.BlockedTeleport = AntiBan.BlockedTeleport + 1
                                return nil
                            end
                        end
                    end
                end
            end

            -- Anti Detect / Data Send
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

            -- Anti Crash
            if Config.AntiCrash and method == "FireServer" and typeof(self) == "Instance" then
                local n = self.Name:lower()
                if n:find("crash") or n:find("disconnect") then
                    AntiBan.BlockedCrash = AntiBan.BlockedCrash + 1
                    return nil
                end
            end

            -- SILENT AIM
            if Config.SilentAim and aimTarget and aimTarget.Parent 
               and method == "FireServer" 
               and typeof(self) == "Instance"
               and self == Shoot then
                
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
    warn("[RENXX] Executor gak support hook.")
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
    Title = "RENXX HUB v3.0",
    Content = "Loaded! All features ready.",
    Duration = 5,
})

print("═══════════════════════════════")
print("RENXX HUB v3.0 | Hypershot")
print("Silent Aim: " .. (hasHook and Shoot and "READY" or "DISABLED"))
print("Weapon Tables: " .. #weaponCache)
print("By DEEP & RENXX")
print("═══════════════════════════════")
