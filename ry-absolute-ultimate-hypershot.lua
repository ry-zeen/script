-- =======================================
-- RENXX HUB v4.0 [ULTIMATE] | Hypershot
-- By: DEEP & RENXX
-- Library: Rayfield
-- Absolute Hacking
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

-- ==================== CLEANUP OLD LOOP ====================
if _G.RENXX_SCANNER_V37 then _G.RENXX_SCANNER_V37 = false task.wait(0.1) end
if _G.RENXX_SCANNER_V38 then _G.RENXX_SCANNER_V38 = false task.wait(0.1) end
if _G.RENXX_SCANNER_V39 then _G.RENXX_SCANNER_V39 = false task.wait(0.1) end
_G.RENXX_SCANNER_V40 = true

-- ==================== ANTI-BAN STATS ====================
local AntiBan = {
    BlockedKick = 0,
    BlockedTeleport = 0,
    BlockedRemote = 0,
    BlockedDataSend = 0,
    BlockedCrash = 0,
}

-- ==================== CONFIG ====================
local Config_Protection = {
    AntiKick = true,
    AntiTeleportVoid = true,
    AntiDetect = true,
    AntiDataSend = true,
    AntiCrash = true,
    AntiFling = true,
    AntiAFK = true,
}

local Config_Combat = {
    Aimbot = false,
    AimSmooth = 5,
    POV = 90,
    ShowPOV = false,
    POVColor = Color3.fromRGB(255, 0, 100),
    AimPart = "Head",
    SnapLine = false,
    SnapLineColor = Color3.fromRGB(255, 0, 100),
    TeamCheck = true,
    WallCheck = false,
}

local Config_Visual = {
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
}

local Config_Weapon = {
    InfAmmo = false,
    RapidFire = false,
    FireRate = 0,
    NoRecoil = false,
    NoSpread = false,
    DamageHack = false,
    DamageValue = 999999,
}

local Config_Movement = {
    NoCooldown = false,
    SpeedHack = false,
    SpeedValue = 30,
    SpeedRandomize = true,
    JumpPower = false,
    JumpValue = 50,
    InfJump = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 50,
}

local Config_Teleport = {
    AutoTP = false,
    TPPosition = "Above",
    TPDistance = 5,
    TPDelay = 0.5,
    TPPriority = "Nearest",
    InputTPCooldown = 1,
    TPAllPlayers = false,
    TPAllDelay = 0.5,
}

local Config_Misc = {
    ScanInterval = 15,
    SafePositionRayDepth = 50,
    BotCacheTime = 1,
}

-- ==================== COMBINED CONFIG ====================
local Config = {}
for _, tbl in ipairs({Config_Protection, Config_Combat, Config_Visual, Config_Weapon, Config_Movement, Config_Teleport, Config_Misc}) do
    for k, v in pairs(tbl) do
        Config[k] = v
    end
end

-- ==================== STATE ====================
local aimTarget = nil
local aimTargetPart = nil
local flyBV = nil
local flyBG = nil
local espData = {}
local botESP = {}
local originalNamecall = nil
local weaponCache = {}
local cooldownTables = {}
local currentTPTarget = nil
local lastTPTime = 0
local inputTPCooldowns = {}
local botCache = {}
local lastBotScan = 0

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

-- ==================== AUTO-DETECT BOT ====================
local function getAllBots()
    local now = tick()
    if now - lastBotScan < Config.BotCacheTime then
        return botCache
    end
    lastBotScan = now
    
    local bots = {}
    local playerChars = {}
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            playerChars[p.Character] = true
        end
    end
    
    local function checkContainer(container, depth)
        if depth > 3 then return end
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Model") and not playerChars[obj] then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local head = obj:FindFirstChild("Head")
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if head and hrp then
                        table.insert(bots, obj)
                    end
                end
            elseif obj:IsA("Folder") then
                checkContainer(obj, depth + 1)
            end
        end
    end
    
    checkContainer(workspace, 0)
    botCache = bots
    return bots
end

-- ==================== NO COOLDOWN SCANNER ====================
local function findCooldownTables()
    if not hasGC then return {} end
    local found = {}
    for _, v in next, getgc(true) do
        if typeof(v) == "table" then
            pcall(function()
                local hasWeaponProp = rawget(v, "FireInterval") 
                    or rawget(v, "DirectDamage") 
                    or rawget(v, "BaseSpread")
                    or rawget(v, "MaxRotRecoil")
                    or rawget(v, "FillAmmo")
                    or rawget(v, "ShootDelay")
                
                if hasWeaponProp then
                    for k, val in pairs(v) do
                        if typeof(val) == "number" then
                            local keyLower = tostring(k):lower()
                            if keyLower == "cd" 
                               or keyLower:find("cooldown")
                               or keyLower:find("recharge")
                               or keyLower:find("casttime")
                               or keyLower:find("channeltime")
                               or keyLower:find("duration") then
                                if val > 1 and val < 100 then
                                    table.insert(found, {table = v, key = k})
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return found
end

task.spawn(function()
    task.wait(5)
    if not _G.RENXX_SCANNER_V40 then return end
    cooldownTables = findCooldownTables()
    while _G.RENXX_SCANNER_V40 do
        task.wait(Config.ScanInterval)
        if not _G.RENXX_SCANNER_V40 then break end
        cooldownTables = findCooldownTables()
    end
end)

local function applyNoCooldown()
    if not Config.NoCooldown then return end
    for _, data in ipairs(cooldownTables) do
        pcall(function()
            if data.table then
                if rawget(data.table, data.key) then
                    rawset(data.table, data.key, 0)
                end
                if rawget(data.table, "Debounce") then
                    rawset(data.table, "Debounce", 0)
                end
                if rawget(data.table, "Cooldown") then
                    rawset(data.table, "Cooldown", 0)
                end
                if rawget(data.table, "CD") then
                    rawset(data.table, "CD", 0)
                end
            end
        end)
    end
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
    if not _G.RENXX_SCANNER_V40 then return end
    weaponCache = findWeaponTables()
    while _G.RENXX_SCANNER_V40 do
        task.wait(Config.ScanInterval)
        if not _G.RENXX_SCANNER_V40 then break end
        weaponCache = findWeaponTables()
    end
end)

local function applyWeaponMods()
    if not hasGC then return end
    for _, weapon in ipairs(weaponCache) do
        pcall(function()
            -- 1. INFINITE AMMO
            if Config.InfAmmo then
                rawset(weapon, "FillAmmo", 9999)
                rawset(weapon, "MaxAmmo", 99999)
                rawset(weapon, "AmmoPerMag", 9999)
                rawset(weapon, "Ammo", 9999)
            end
            
            -- 2. NO RECOIL
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
                if rawget(weapon, "RotRecoilDamping") then rawset(weapon, "RotRecoilDamping", 0) end
            end
            
            -- 3. NO SPREAD
            if Config.NoSpread then
                if rawget(weapon, "BaseSpread") then rawset(weapon, "BaseSpread", 0) end
                if rawget(weapon, "ScopeSpreadMultiplier") then rawset(weapon, "ScopeSpreadMultiplier", 0) end
            end
            
            -- 4. RAPID FIRE
            if Config.RapidFire then
                local rate = Config.FireRate
                if rawget(weapon, "FireInterval") then rawset(weapon, "FireInterval", rate) end
                if rawget(weapon, "ShootDelay") then rawset(weapon, "ShootDelay", rate) end
                if rawget(weapon, "AcquireDelay") then rawset(weapon, "AcquireDelay", rate) end
                if rawget(weapon, "CD") then rawset(weapon, "CD", 0) end
                if rawget(weapon, "Debounce") then rawset(weapon, "Debounce", 0) end
                if rawget(weapon, "Cooldown") then rawset(weapon, "Cooldown", 0) end
                if rawget(weapon, "FireRate") then rawset(weapon, "FireRate", rate) end
                if rawget(weapon, "FireDelay") then rawset(weapon, "FireDelay", rate) end
                if rawget(weapon, "DelayUntilLoop") then rawset(weapon, "DelayUntilLoop", 0) end
                if rawget(weapon, "ProjSpeed") then rawset(weapon, "ProjSpeed", 99999) end
                if rawget(weapon, "ShootCooldown") then rawset(weapon, "ShootCooldown", 0) end
                if rawget(weapon, "AttackSpeed") then rawset(weapon, "AttackSpeed", 999) end
                if rawget(weapon, "ReloadTime") then rawset(weapon, "ReloadTime", 0) end
                if rawget(weapon, "ReloadDelay") then rawset(weapon, "ReloadDelay", 0) end
            end
            
            -- 5. DAMAGE HACK
            if Config.DamageHack then
                local dmg = Config.DamageValue
                if rawget(weapon, "HeadDamage") then rawset(weapon, "HeadDamage", dmg) end
                if rawget(weapon, "DirectHeadDamage") then rawset(weapon, "DirectHeadDamage", dmg) end
                if rawget(weapon, "DirectDamage") then rawset(weapon, "DirectDamage", dmg) end
                if rawget(weapon, "AlternateDamage") then rawset(weapon, "AlternateDamage", dmg) end
                if rawget(weapon, "MobDamage") then rawset(weapon, "MobDamage", dmg) end
                if rawget(weapon, "ExplosiveDamage") then rawset(weapon, "ExplosiveDamage", dmg) end
                if rawget(weapon, "DamagePercent") then rawset(weapon, "DamagePercent", 0.99) end
                if rawget(weapon, "AlternateDamagePercent") then rawset(weapon, "AlternateDamagePercent", 0.99) end
            end
        end)
    end
end

-- ==================== AIMBOT ====================
local function getClosestTarget()
    if not Config.Aimbot then return nil, nil end
    local closest, closestPart = nil, nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovRadius = fovToRadius(Config.POV)
    local aimPartName = Config.AimPart

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

-- ==================== TELEPORT ====================
local function findTargetByPriority()
    local all = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(all, {char = p.Character, isBot = false})
            end
        end
    end
    local bots = getAllBots()
    for _, bot in ipairs(bots) do
        table.insert(all, {char = bot, isBot = true})
    end
    if #all == 0 then return nil end
    
    if Config.TPPriority == "Player First" then
        for _, data in ipairs(all) do
            if not data.isBot then return data.char end
        end
        return all[1].char
    elseif Config.TPPriority == "Bot First" then
        for _, data in ipairs(all) do
            if data.isBot then return data.char end
        end
        return all[1].char
    elseif Config.TPPriority == "Random" then
        return all[math.random(1, #all)].char
    else
        local nearest = nil
        local shortest = math.huge
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        for _, data in ipairs(all) do
            local hrp = data.char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < shortest then
                    shortest = d
                    nearest = data.char
                end
            end
        end
        return nearest
    end
end

local function calculateTPCFrame(targetHRP)
    local dist = Config.TPDistance
    if Config.TPPosition == "Above" then
        return targetHRP.CFrame + Vector3.new(0, dist, 0)
    elseif Config.TPPosition == "Behind" then
        return targetHRP.CFrame * CFrame.new(0, 3, dist)
    elseif Config.TPPosition == "Front" then
        return targetHRP.CFrame * CFrame.new(0, 3, -dist)
    elseif Config.TPPosition == "Side" then
        return targetHRP.CFrame * CFrame.new(dist, 3, 0)
    end
    return targetHRP.CFrame + Vector3.new(0, dist, 0)
end

local function isSafePosition(pos)
    local ok, result = pcall(function()
        local rayDown = Ray.new(pos, Vector3.new(0, -Config.SafePositionRayDepth, 0))
        local hitDown = workspace:FindPartOnRayWithIgnoreList(rayDown, {LocalPlayer.Character})
        if not hitDown then return false end
        local rayUp = Ray.new(pos + Vector3.new(0, 2, 0), Vector3.new(0, 2, 0))
        local hitUp = workspace:FindPartOnRayWithIgnoreList(rayUp, {LocalPlayer.Character})
        if hitUp then return false end
        return true
    end)
    return ok and result or false
end

local function teleportToTarget()
    if not Config.AutoTP then return end
    if Config.Fly then return end
    local now = tick()
    if now - lastTPTime < Config.TPDelay then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    if currentTPTarget and currentTPTarget.Parent then
        local hum = currentTPTarget:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local hrp = currentTPTarget:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist > Config.TPDistance + 5 then
                    local tpCF = calculateTPCFrame(hrp)
                    if isSafePosition(tpCF.Position) then
                        myHRP.CFrame = tpCF
                        lastTPTime = now
                    end
                end
            end
            return
        end
        currentTPTarget = nil
    else
        currentTPTarget = nil
    end
    
    local newTarget = findTargetByPriority()
    if newTarget then
        local hrp = newTarget:FindFirstChild("HumanoidRootPart")
        if hrp then
            local tpCF = calculateTPCFrame(hrp)
            if isSafePosition(tpCF.Position) then
                myHRP.CFrame = tpCF
                currentTPTarget = newTarget
                lastTPTime = now
            end
        end
    end
end

local function teleportToAllPlayers()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local tpCF = calculateTPCFrame(hrp)
                if isSafePosition(tpCF.Position) then
                    myHRP.CFrame = tpCF
                    task.wait(0.05)
                end
            end
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
    Name = "RENXX HUB v4.0 [ULTIMATE] | Hypershot",
    LoadingTitle = "Loading RENXX v4.0...",
    LoadingSubtitle = "ULTIMATE EDITION — By DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================== TAB 1: PROTECTION ====================
local ProtTab = Window:CreateTab("PROTECTION", 4483362458)

ProtTab:CreateSection("Anti Features")
ProtTab:CreateToggle({Name = "Anti Kick", CurrentValue = true, Callback = function(v) Config.AntiKick = v end})
ProtTab:CreateToggle({Name = "Anti Teleport Void", CurrentValue = true, Callback = function(v) Config.AntiTeleportVoid = v end})
ProtTab:CreateToggle({Name = "Anti Detect", CurrentValue = true, Callback = function(v) Config.AntiDetect = v end})
ProtTab:CreateToggle({Name = "Anti Data Send", CurrentValue = true, Callback = function(v) Config.AntiDataSend = v end})
ProtTab:CreateToggle({Name = "Anti Crash", CurrentValue = true, Callback = function(v) Config.AntiCrash = v end})
ProtTab:CreateToggle({Name = "Anti Fling", CurrentValue = true, Callback = function(v) Config.AntiFling = v end})
ProtTab:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) Config.AntiAFK = v end})

ProtTab:CreateSection("Stats")
ProtTab:CreateButton({
    Name = "Show Protection Stats",
    Callback = function()
        Rayfield:Notify({
            Title = "Protection Stats",
            Content = string.format("Kick: %d | Remote: %d | Data: %d | Crash: %d",
                AntiBan.BlockedKick, AntiBan.BlockedRemote, 
                AntiBan.BlockedDataSend, AntiBan.BlockedCrash),
            Duration = 5,
        })
    end,
})

-- ==================== TAB 2: COMBAT ====================
local CombatTab = Window:CreateTab("COMBAT", 4483362458)

CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({
    Name = "Aimbot (Player + Bot)",
    CurrentValue = false,
    Callback = function(v)
        Config.Aimbot = v
        Rayfield:Notify({Title="RENXX", Content="Aimbot: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})
CombatTab:CreateSlider({Name = "Aim Smoothness", Range = {1, 15}, Increment = 1, Suffix = "x", CurrentValue = 5, Callback = function(v) Config.AimSmooth = v end})
CombatTab:CreateSlider({Name = "FOV", Range = {30, 360}, Increment = 1, Suffix = "deg", CurrentValue = 90, Callback = function(v) Config.POV = v end})
CombatTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Callback = function(v) Config.ShowPOV = v end})
CombatTab:CreateColorPicker({Name = "FOV Color", Color = Color3.fromRGB(255, 0, 100), Callback = function(c) Config.POVColor = c end})
CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    CurrentOption = "Head",
    Callback = function(o) if type(o) == "table" then Config.AimPart = o[1] else Config.AimPart = o end end,
})

CombatTab:CreateSection("Snap Line")
CombatTab:CreateToggle({Name = "Snap Line", CurrentValue = false, Callback = function(v) Config.SnapLine = v end})
CombatTab:CreateColorPicker({Name = "Snap Line Color", Color = Color3.fromRGB(255, 0, 100), Callback = function(c) Config.SnapLineColor = c end})

CombatTab:CreateSection("Filter")
CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Config.TeamCheck = v end})
CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = false, Callback = function(v) Config.WallCheck = v end})

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

WeaponTab:CreateSection("Fire Rate 🔥")
WeaponTab:CreateToggle({
    Name = "Rapid Fire 🔥",
    CurrentValue = false,
    Callback = function(v)
        Config.RapidFire = v
        Rayfield:Notify({Title="RENXX", Content="Rapid Fire: " .. (v and "ON 🔥" or "OFF"), Duration=2})
    end,
})
WeaponTab:CreateSlider({
    Name = "Fire Rate Value",
    Range = {0, 100}, Increment = 1, Suffix = " (x0.01s)", CurrentValue = 0,
    Callback = function(v) Config.FireRate = v / 100 end,
})

WeaponTab:CreateSection("Damage 🔥")
WeaponTab:CreateToggle({
    Name = "Damage Hack 🔥",
    CurrentValue = false,
    Callback = function(v)
        Config.DamageHack = v
        Rayfield:Notify({Title="RENXX", Content="Damage Hack: " .. (v and "ON 🔥" or "OFF"), Duration=2})
    end,
})
WeaponTab:CreateSlider({
    Name = "Damage Value",
    Range = {100, 9999999}, Increment = 100, Suffix = " dmg", CurrentValue = 999999,
    Callback = function(v) Config.DamageValue = v end,
})

WeaponTab:CreateSection("Debug")
WeaponTab:CreateButton({
    Name = "Count Weapon Tables",
    Callback = function()
        weaponCache = findWeaponTables()
        Rayfield:Notify({Title = "Weapon Tables", Content = "Found: " .. #weaponCache, Duration = 3})
    end,
})

-- ==================== TAB 5: MOVEMENT ====================
local MoveTab = Window:CreateTab("MOVEMENT", 4483362458)

MoveTab:CreateSection("Skill")
MoveTab:CreateToggle({
    Name = "No Cooldown Skill",
    CurrentValue = false,
    Callback = function(v)
        Config.NoCooldown = v
        Rayfield:Notify({Title="RENXX", Content="No Cooldown: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})
MoveTab:CreateButton({
    Name = "Count Cooldown Tables",
    Callback = function()
        cooldownTables = findCooldownTables()
        Rayfield:Notify({Title = "Cooldown Tables", Content = "Found: " .. #cooldownTables, Duration = 3})
    end,
})

MoveTab:CreateSection("Speed")
MoveTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Config.SpeedHack = v end})
MoveTab:CreateSlider({Name = "Speed Value", Range = {16, 60}, Increment = 1, CurrentValue = 30, Callback = function(v) Config.SpeedValue = v end})
MoveTab:CreateToggle({Name = "Speed Randomize (Anti-Detect)", CurrentValue = true, Callback = function(v) Config.SpeedRandomize = v end})

MoveTab:CreateSection("Jump")
MoveTab:CreateToggle({Name = "Jump Power", CurrentValue = false, Callback = function(v) Config.JumpPower = v end})
MoveTab:CreateSlider({Name = "Jump Value", Range = {50, 200}, Increment = 5, CurrentValue = 50, Callback = function(v) Config.JumpValue = v end})
MoveTab:CreateToggle({Name = "Infinity Jump", CurrentValue = false, Callback = function(v) Config.InfJump = v end})

MoveTab:CreateSection("Fly")
MoveTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        Config.Fly = v
        if v then 
            if Config.AutoTP then
                Config.AutoTP = false
                Rayfield:Notify({Title="RENXX", Content="Auto TP auto-disabled", Duration=2})
            end
            if Config.TPAllPlayers then
                Config.TPAllPlayers = false
                Rayfield:Notify({Title="RENXX", Content="TP All auto-disabled", Duration=2})
            end
            startFly() 
        else 
            stopFly() 
        end
    end,
})
MoveTab:CreateSlider({Name = "Fly Speed", Range = {10, 200}, Increment = 5, CurrentValue = 50, Callback = function(v) Config.FlySpeed = v end})

MoveTab:CreateSection("Misc")
MoveTab:CreateToggle({Name = "No Clip", CurrentValue = false, Callback = function(v) Config.NoClip = v end})

MoveTab:CreateSection("Teleport")

MoveTab:CreateToggle({
    Name = "Auto TP to Target (Player + Bot)",
    CurrentValue = false,
    Callback = function(v)
        Config.AutoTP = v
        if v and Config.Fly then
            Config.Fly = false
            stopFly()
            Rayfield:Notify({Title="RENXX", Content="Fly auto-disabled", Duration=2})
        end
        if v and Config.Aimbot then
            Rayfield:Notify({Title = "WARNING", Content = "Aimbot + Auto TP bisa konflik!", Duration = 4})
        end
        Rayfield:Notify({Title="RENXX", Content="Auto TP: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

MoveTab:CreateDropdown({
    Name = "TP Position",
    Options = {"Above", "Behind", "Front", "Side"},
    CurrentOption = "Above",
    Callback = function(o) if type(o) == "table" then Config.TPPosition = o[1] else Config.TPPosition = o end end,
})

MoveTab:CreateSlider({Name = "TP Distance", Range = {1, 20}, Increment = 1, Suffix = " studs", CurrentValue = 5, Callback = function(v) Config.TPDistance = v end})
MoveTab:CreateSlider({Name = "TP Delay", Range = {10, 300}, Increment = 10, Suffix = " (x0.01s)", CurrentValue = 50, Callback = function(v) Config.TPDelay = v / 100 end})

MoveTab:CreateDropdown({
    Name = "Target Priority",
    Options = {"Nearest", "Player First", "Bot First", "Random"},
    CurrentOption = "Nearest",
    Callback = function(o) if type(o) == "table" then Config.TPPriority = o[1] else Config.TPPriority = o end end,
})

MoveTab:CreateSection("Aura Farming 🔥")

MoveTab:CreateToggle({
    Name = "TP All Players (Aura Farming)",
    CurrentValue = false,
    Callback = function(v)
        Config.TPAllPlayers = v
        if v and Config.Fly then
            Config.Fly = false
            stopFly()
            Rayfield:Notify({Title="RENXX", Content="Fly auto-disabled", Duration=2})
        end
        if v then
            Rayfield:Notify({Title="RENXX", Content="TP All ON — Aura Farming", Duration=3})
            task.wait(2)
        else
            Rayfield:Notify({Title="RENXX", Content="TP All: OFF", Duration=2})
        end
    end,
})

MoveTab:CreateSlider({
    Name = "TP All Delay",
    Range = {10, 500}, Increment = 10, Suffix = " (x0.01s)", CurrentValue = 50,
    Callback = function(v) Config.TPAllDelay = v / 100 end,
})

MoveTab:CreateSection("Manual TP")

MoveTab:CreateInput({
    Name = "TP to Player Name",
    PlaceholderText = "Enter player name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        if text and text ~= "" then
            local now = tick()
            local key = "tp_player"
            local lastTime = inputTPCooldowns[key] or 0
            if now - lastTime < Config.InputTPCooldown then return end
            inputTPCooldowns[key] = now
            
            local target = Players:FindFirstChild(text)
            if target and target.Character then
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and myHRP then
                    local tpCF = calculateTPCFrame(hrp)
                    if isSafePosition(tpCF.Position) then
                        myHRP.CFrame = tpCF
                        Rayfield:Notify({Title="RENXX", Content="TP to " .. text, Duration=2})
                    else
                        Rayfield:Notify({Title="RENXX", Content="Position not safe", Duration=2})
                    end
                end
            else
                Rayfield:Notify({Title="RENXX", Content="Player not found", Duration=2})
            end
        end
    end,
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

task.spawn(function()
    while task.wait(0.1) do
        if Config.TPAllPlayers and not Config.Fly then
            teleportToAllPlayers()
            task.wait(Config.TPAllDelay)
        end
    end
end)

-- ==================== RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    if povCircle then
        pcall(function()
            if Config.ShowPOV and Config.Aimbot then
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

    if Config.Aimbot and not Config.AutoTP and aimTargetPart and aimTargetPart.Parent then
        local targetCF = CFrame.new(Camera.CFrame.Position, aimTargetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(1, Config.AimSmooth))
    end

    if hasDrawing then
        local espActive = Config.ESPLine or Config.ESPName or Config.ESPHealth 
            or Config.ESPDistance or Config.ESPBox
        if not espActive then
            for _, d in pairs(espData) do hideESP(d) end
            for _, d in pairs(botESP) do hideESP(d) end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and espData[p] then
                    local d = espData[p]
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local head = p.Character:FindFirstChild("Head")
                    
                    if hrp and hum and head and hum.Health > 0 then
                        local spTop, onTop = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                        local spBot, onBot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        
                        if onTop and onBot then
                            local isTeam = isSameTeam(p)
                            local lineColor = isTeam and Config.ESPTeamColor or Config.ESPEnemyColor
                            local boxHeight = math.abs(spBot.Y - spTop.Y)
                            local boxWidth = boxHeight * 0.6
                            local boxX = spTop.X - boxWidth / 2
                            local boxY = spTop.Y

                            if Config.ESPLine then
                                d.line.Visible = true
                                d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                d.line.To = Vector2.new(hrp.Position.X, spTop.Y)
                                d.line.Color = lineColor
                                d.line.Thickness = 1.5
                            else d.line.Visible = false end

                            if Config.ESPName then
                                d.name.Visible = true
                                d.name.Text = p.Name
                                d.name.Position = Vector2.new(spTop.X, boxY - 16)
                                d.name.Color = Config.ESPTextColor
                                d.name.Size = 14
                                d.name.Center = true
                                d.name.Outline = true
                                d.name.OutlineColor = Color3.new(0, 0, 0)
                            else d.name.Visible = false end

                            if Config.ESPHealth then
                                local hpP = hum.Health / hum.MaxHealth
                                d.hpBG.Visible = true
                                d.hpBG.Size = Vector2.new(4, boxHeight)
                                d.hpBG.Position = Vector2.new(boxX - 8, boxY)
                                d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                d.hpBG.Filled = true
                                d.hpBar.Visible = true
                                d.hpBar.Size = Vector2.new(4, boxHeight * hpP)
                                d.hpBar.Position = Vector2.new(boxX - 8, boxY + (boxHeight * (1 - hpP)))
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
                                d.dist.Position = Vector2.new(spBot.X, spBot.Y + 5)
                                d.dist.Color = Config.ESPTextColor
                                d.dist.Size = 12
                                d.dist.Center = true
                                d.dist.Outline = true
                                d.dist.OutlineColor = Color3.new(0, 0, 0)
                            else d.dist.Visible = false end

                            if Config.ESPBox then
                                d.box.Visible = true
                                d.box.Size = Vector2.new(boxWidth, boxHeight)
                                d.box.Position = Vector2.new(boxX, boxY)
                                d.box.Color = isTeam and Config.ESPTeamColor or Config.ESPBoxColor
                                d.box.Thickness = 1.5
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

            local bots = getAllBots()
            for _, botChar in ipairs(bots) do
                local hum = botChar:FindFirstChildOfClass("Humanoid")
                local hrp = botChar:FindFirstChild("HumanoidRootPart")
                local head = botChar:FindFirstChild("Head")
                if hum and hrp and head and hum.Health > 0 then
                    if not botESP[botChar] then
                        botESP[botChar] = createESP()
                    end
                    local d = botESP[botChar]
                    if d then
                        local spTop, onTop = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                        local spBot, onBot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        
                        if onTop and onBot then
                            local boxHeight = math.abs(spBot.Y - spTop.Y)
                            local boxWidth = boxHeight * 0.6
                            local boxX = spTop.X - boxWidth / 2
                            local boxY = spTop.Y

                            if Config.ESPLine then
                                d.line.Visible = true
                                d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                d.line.To = Vector2.new(hrp.Position.X, spTop.Y)
                                d.line.Color = Config.ESPBotColor
                                d.line.Thickness = 1.5
                            else d.line.Visible = false end

                            if Config.ESPName then
                                d.name.Visible = true
                                d.name.Text = "[BOT] " .. botChar.Name
                                d.name.Position = Vector2.new(spTop.X, boxY - 16)
                                d.name.Color = Config.ESPTextColor
                                d.name.Size = 14
                                d.name.Center = true
                                d.name.Outline = true
                                d.name.OutlineColor = Color3.new(0, 0, 0)
                            else d.name.Visible = false end

                            if Config.ESPHealth then
                                local hpP = hum.Health / hum.MaxHealth
                                d.hpBG.Visible = true
                                d.hpBG.Size = Vector2.new(4, boxHeight)
                                d.hpBG.Position = Vector2.new(boxX - 8, boxY)
                                d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                d.hpBG.Filled = true
                                d.hpBar.Visible = true
                                d.hpBar.Size = Vector2.new(4, boxHeight * hpP)
                                d.hpBar.Position = Vector2.new(boxX - 8, boxY + (boxHeight * (1 - hpP)))
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
                                d.dist.Position = Vector2.new(spBot.X, spBot.Y + 5)
                                d.dist.Color = Config.ESPTextColor
                                d.dist.Size = 12
                                d.dist.Center = true
                                d.dist.Outline = true
                                d.dist.OutlineColor = Color3.new(0, 0, 0)
                            else d.dist.Visible = false end

                            if Config.ESPBox then
                                d.box.Visible = true
                                d.box.Size = Vector2.new(boxWidth, boxHeight)
                                d.box.Position = Vector2.new(boxX, boxY)
                                d.box.Color = Config.ESPBotColor
                                d.box.Thickness = 1.5
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
    if Config.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then flyBG.CFrame = Camera.CFrame end
    end

    if Config.InfAmmo or Config.RapidFire or Config.NoRecoil or Config.NoSpread or Config.DamageHack then
        applyWeaponMods()
    end

    if Config.NoCooldown then
        applyNoCooldown()
    end

    if Config.AutoTP then
        teleportToTarget()
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.SpeedHack then
                local speed = Config.SpeedValue
                if Config.SpeedRandomize then
                    speed = speed + math.random(-2, 2)
                end
                hum.WalkSpeed = speed
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

-- ==================== PROTECTION HOOK ====================
if hasHook then
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        originalNamecall = mt.__namecall
        local newc = newcclosure or function(f) return f end

        mt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if not method then return originalNamecall(self, ...) end
            local methodLower = method:lower()

            if Config.AntiKick and methodLower == "kick" and self == LocalPlayer then
                AntiBan.BlockedKick = AntiBan.BlockedKick + 1
                return nil
            end

            if Config.AntiTeleportVoid and (methodLower == "fireserver" or methodLower == "invokeserver") 
               and typeof(self) == "Instance" then
                local n = self.Name:lower()
                local suspiciousVoid = {"sendtovoid", "teleportvoid", "kicktovoid", "voidteleport", "voidkick"}
                local isVoidRemote = false
                for _, keyword in ipairs(suspiciousVoid) do
                    if n:find(keyword) then
                        isVoidRemote = true
                        break
                    end
                end
                
                if isVoidRemote then
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

            if (Config.AntiDetect or Config.AntiDataSend) 
               and (methodLower == "fireserver" or methodLower == "invokeserver")
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

            if Config.AntiCrash and methodLower == "fireserver" and typeof(self) == "instance" then
                local n = self.Name:lower()
                if n:find("crash") or n:find("disconnect") then
                    AntiBan.BlockedCrash = AntiBan.BlockedCrash + 1
                    return nil
                end
            end

            return originalNamecall(self, table.unpack(args))
        end)
        setreadonly(mt, true)
    end)
end

-- ==================== CHARACTER ADDED ====================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    flyBV = nil
    flyBG = nil
    currentTPTarget = nil
    if Config.Fly then startFly() end
end)

-- ==================== NOTIFIKASI ====================
Rayfield:Notify({
    Title = "RENXX HUB v4.0 [ULTIMATE]",
    Content = " Loaded! By DEEP & RENXX",
    Duration = 4,
})

-- ==================== PRINT (FINAL) ====================
print("v4.0 — HYPERSHOT | READY")
print("[PROTECTION] [COMBAT] [VISUAL] [WEAPON] [MOVEMENT]")
print("[+] "..#weaponCache.." weapon | "..#cooldownTables.." cd | 4 Fixes Applied")
print("RENXX")
print("═══════════════════════════════")
