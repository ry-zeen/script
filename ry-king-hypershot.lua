-- =======================================
-- RENXX | HYPERshot EDITION
-- By: DEEP & RENXX
-- 6 Tab | Config Separated | Fire Rate Multiplier
-- =======================================

if _G.RENXX then _G.RENXX = false; task.wait(0.3) end
_G.RENXX = true

-- CLEANUP UI LAMA
pcall(function()
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name:lower():find("renxx") or gui.Name:lower():find("rayfield") then
            gui:Destroy()
        end
    end
end)

task.wait(0.3)
print("==============================")
print(" RENXX LOADING...")
print("==============================")

-- LOAD RAYFIELD
local Rayfield
local urls = {'https://sirius.menu/rayfield', 'https://raw.githubusercontent.com/SirMallard/Rayfield/main/source.lua'}
for _, url in ipairs(urls) do
    local ok, result = pcall(function() return loadstring(game:HttpGet(url))() end)
    if ok and result then Rayfield = result print("[OK] Rayfield loaded") break end
end
if not Rayfield then warn("[ERROR] Rayfield gagal!") return end

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== CAPABILITY ====================
local Cap = {
    Drawing = false, Hook = false, GC = false,
    MouseMoveRel = false, Mouse1Click = false, Mouse1Press = false,
    CameraWrite = false, Settings = false,
    IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
}
pcall(function() local d = Drawing.new("Text") d:Remove() Cap.Drawing = true end)
pcall(function() Cap.Hook = hookmetamethod and getrawmetatable and setreadonly and newcclosure and getnamecallmethod end)
pcall(function() Cap.GC = type(getgc(true)) == "table" end)
Cap.MouseMoveRel = (type(mousemoverel) == "function")
Cap.Mouse1Click = (type(mouse1click) == "function")
Cap.Mouse1Press = (type(mouse1press) == "function") and (type(mouse1release) == "function")
pcall(function()
    local old = Camera.CFrame
    Camera.CFrame = old * CFrame.Angles(0, math.rad(0.001), 0)
    Camera.CFrame = old
    Cap.CameraWrite = true
end)
pcall(function() Cap.Settings = (type(settings) == "function") end)

-- ==================== ANTI-BAN STATS ====================
local AntiBan = {
    BlockedKick = 0, BlockedTeleport = 0, BlockedRemote = 0,
    BlockedDataSend = 0, BlockedCrash = 0,
}

-- ==================== CONFIG ====================
-- PROTECTION
local Config_Protection = {
    AntiKick = true, AntiTeleportVoid = true, AntiDetect = true,
    AntiDataSend = true, AntiCrash = true, AntiFling = true,
    AntiFlingThreshold = 500, AntiAFK = true,
    RateLimiter = true, SafeMode = false, MaxRemotePerSec = 5,
    BoostFPS = false, SetFPS = 120, LowPing = false, SetPing = 60, ShowStats = false,
}

-- COMBAT
local Config_Combat = {
    Aimbot = false, AutoShoot = false,
    AimSmooth = 3, SwitchSpeed = 1,
    POV = 90, ShowPOV = false, POVColor = Color3.fromRGB(255, 0, 100),
    AimPart = "Head", TeamCheck = true, WallCheck = false,
    AimMode = "Mouse", HitboxExpander = false, HitboxSize = 5,
}

-- VISUAL
local Config_Visual = {
    ESPPosition = "Bottom",
    ESPLinePlayer = false, ESPLineBOT = false, ESPName = false,
    ESPHealth = false, ESPDistance = false, ESPBox = false,
    ESPTextColor = Color3.fromRGB(255, 255, 255),
    ESPBoxColor = Color3.fromRGB(255, 0, 0),
    LinePlayerTeamColor = Color3.fromRGB(0, 100, 255),
    LinePlayerEnemyColor = Color3.fromRGB(255, 0, 0),
    LineBOTTeamColor = Color3.fromRGB(0, 255, 0),
    LineBOTEnemyColor = Color3.fromRGB(255, 255, 0),
}

-- PLAYER
local Config_Player = {
    GodMode = false, FastRegen = false, AntiFall = false, AntiVoid = false,
    SpeedHack = false, SpeedValue = 30, SpeedRandomize = true,
    JumpHack = false, JumpValue = 50, InfJump = false,
    NoClip = false, Fly = false, FlySpeed = 50,
}

-- WEAPON
local Config_Weapon = {
    InfAmmo = false, NoReload = false,
    NoRecoil = false, NoSpread = false,
    RapidFire = false, FireRateMultiplier = 1,
    AutoMode = false,
    DamageHack = false, DamageValue = 999,
    SentryGod = false, SentryCD = false, NoStrafe = false,
    RainbowBullets = false, BrightBullets = false, FatBullets = false,
}

-- FARM
local Config_Farm = {
    AutoTP = false, TPPosition = "Above", TPDistance = 5,
    TPPriority = "TP to All Enemy",
    TPAllBOT = false, TPAllDelay = 0.1,
}

-- MISC
local Config_Misc = {
    ScanInterval = 15, BotCacheTime = 1.5,
}

-- MERGE CONFIG
local Config = {}
for _, tbl in ipairs({Config_Protection, Config_Combat, Config_Visual, Config_Player, Config_Weapon, Config_Farm, Config_Misc}) do
    for k, v in pairs(tbl) do Config[k] = v end
end

-- ==================== STATE ====================
local aimTargetPart = nil
local lastAimTarget = nil
local switchCooldown = 0
local flyBV, flyBG = nil, nil
local espData, botESP = {}, {}
local weaponCache = {}
local originalWeaponData = {}
local currentTPTarget = nil
local lastShootTime = 0
local lastSpeedChange = 0
local lastMouseMove = 0
local botCache, lastBotScan = {}, 0
local originalHitboxData = {}
local originalCollide = {}
local originalTransparency = {}
local fpsCounter, pingCounter = nil, nil
local frameCount, currentFPS = 0, 0
local originalLightingSaved = false
local originalLightingData = {}

-- ==================== HELPERS ====================
local function fovToRadius(fovDeg)
    return math.tan(math.rad(fovDeg / 2)) * (Camera.ViewportSize.Y / 2)
end

local function getTeamFromObject(obj)
    if not obj then return nil end
    if obj.Team then return obj.Team end
    local a = obj:GetAttribute("Team")
    if a then return a end
    local tc = obj:FindFirstChild("Team")
    if tc then return tc end
    return nil
end

local function isSameTeam(player)
    if not player then return false end
    local myTeam = getTeamFromObject(LocalPlayer)
    local theirTeam = getTeamFromObject(player)
    if not myTeam or not theirTeam then return false end
    return tostring(myTeam) == tostring(theirTeam)
end

local function isBotSameTeam(botChar)
    if not botChar then return false end
    local myTeam = getTeamFromObject(LocalPlayer)
    if not myTeam then return false end
    local botTeam = botChar:GetAttribute("Team") or botChar:GetAttribute("team") or (botChar.Parent and botChar.Parent:GetAttribute("Team"))
    if not botTeam then
        local tc = botChar:FindFirstChild("Team")
        if tc then botTeam = tc.Value or tc.Name end
    end
    if not botTeam then return false end
    return tostring(botTeam) == tostring(myTeam)
end

local function getHealthPercent(hum)
    if not hum or not hum.MaxHealth or hum.MaxHealth <= 0 then return 0 end
    return math.clamp(hum.Health / hum.MaxHealth, 0, 1)
end

local function hasLineOfSight(part, targetChar)
    if not Config.WallCheck then return true end
    local ok, result = pcall(function()
        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local el = {LocalPlayer.Character}
        if targetChar then table.insert(el, targetChar) end
        rp.FilterDescendantsInstances = el
        rp.IgnoreWater = true
        local rr = workspace:Raycast(origin, direction, rp)
        if not rr then return true end
        return rr.Instance:IsDescendantOf(part.Parent)
    end)
    return ok and result or true
end

local function getAllBots()
    local now = tick()
    if now - lastBotScan < Config.BotCacheTime then return botCache end
    lastBotScan = now
    local bots, playerChars = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end
    local function scan(c, depth)
        if depth > 4 then return end
        for _, obj in ipairs(c:GetChildren()) do
            if obj:IsA("Model") and not playerChars[obj] then
                local h = obj:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 and obj:FindFirstChild("Head") and obj:FindFirstChild("HumanoidRootPart") then
                    table.insert(bots, obj)
                end
            elseif obj:IsA("Folder") then
                scan(obj, depth + 1)
            end
        end
    end
    scan(workspace, 0)
    botCache = bots
    return bots
end

local function findWeaponTables()
    if not Cap.GC then return {} end
    local found = {}
    pcall(function()
        for _, v in next, getgc(true) do
            if typeof(v) == "table" then
                if rawget(v, "FireInterval") or rawget(v, "BaseSpread") or rawget(v, "DirectDamage") or rawget(v, "MaxRotRecoil") or rawget(v, "FillAmmo") or rawget(v, "ShootDelay") then
                    table.insert(found, v)
                end
            end
        end
    end)
    return found
end

task.spawn(function()
    task.wait(3)
    if not _G.RENXX then return end
    weaponCache = findWeaponTables()
    print("[RENXX] " .. #weaponCache .. " weapon tables")
    while _G.RENXX do
        task.wait(Config.ScanInterval)
        if not _G.RENXX then break end
        weaponCache = findWeaponTables()
    end
end)

-- ==================== APPLY WEAPON MODS ====================
local function applyMods()
    if not Cap.GC then return end
    for _, w in ipairs(weaponCache) do
        pcall(function()
            -- AMMO
            if Config.InfAmmo then
                if rawget(w, "FillAmmo") then rawset(w, "FillAmmo", 9999) end
                if rawget(w, "MaxAmmo") then rawset(w, "MaxAmmo", 99999) end
                if rawget(w, "AmmoPerMag") then rawset(w, "AmmoPerMag", 9999) end
                if rawget(w, "Ammo") then rawset(w, "Ammo", 9999) end
            end
            if Config.NoReload then
                if rawget(w, "NoReloadOnNoAmmo") then rawset(w, "NoReloadOnNoAmmo", true) end
                if rawget(w, "ReloadsOnDoneAmmo") then rawset(w, "ReloadsOnDoneAmmo", false) end
            end
            
            -- RECOIL
            if Config.NoRecoil then
                for _, k in ipairs({"MaxRotRecoil","MinRotRecoil","MaxCamRecoil","MinCamRecoil","MaxTransRecoil","MinTransRecoil"}) do
                    if rawget(w, k) then rawset(w, k, Vector3.zero) end
                end
                for _, k in ipairs({"RotRecoilConstant","CamRecoilConstant","TransRecoilConstant","RotRecoilDamping"}) do
                    if rawget(w, k) then rawset(w, k, 0) end
                end
            end
            
            -- SPREAD
            if Config.NoSpread then
                if rawget(w, "BaseSpread") then rawset(w, "BaseSpread", 0) end
                if rawget(w, "ScopeSpreadMultiplier") then rawset(w, "ScopeSpreadMultiplier", 0) end
                if rawget(w, "FullAccuracySpeed") then rawset(w, "FullAccuracySpeed", 0) end
            end
            
            -- AUTO MODE
            if Config.AutoMode then
                if rawget(w, "Auto") ~= nil then rawset(w, "Auto", true) end
            end
            
            -- RAPID FIRE (MULTIPLIER)
            if Config.RapidFire and Config.FireRateMultiplier > 0 then
                if not originalWeaponData[w] then
                    originalWeaponData[w] = {
                        FireInterval = rawget(w, "FireInterval"),
                        ShootDelay = rawget(w, "ShootDelay"),
                        AcquireDelay = rawget(w, "AcquireDelay"),
                        Debounce = rawget(w, "Debounce"),
                        FireRate = rawget(w, "FireRate"),
                        FireDelay = rawget(w, "FireDelay"),
                        Cooldown = rawget(w, "Cooldown"),
                    }
                end
                local orig = originalWeaponData[w]
                local mult = Config.FireRateMultiplier
                if orig.FireInterval and orig.FireInterval > 0 then rawset(w, "FireInterval", orig.FireInterval / mult) end
                if orig.ShootDelay and orig.ShootDelay > 0 then rawset(w, "ShootDelay", orig.ShootDelay / mult) end
                if orig.AcquireDelay and orig.AcquireDelay > 0 then rawset(w, "AcquireDelay", orig.AcquireDelay / mult) end
                if orig.Debounce and orig.Debounce > 0 then rawset(w, "Debounce", orig.Debounce / mult) end
                if orig.FireRate and orig.FireRate > 0 then rawset(w, "FireRate", orig.FireRate / mult) end
                if orig.FireDelay and orig.FireDelay > 0 then rawset(w, "FireDelay", orig.FireDelay / mult) end
                if orig.Cooldown and orig.Cooldown > 0 then rawset(w, "Cooldown", orig.Cooldown / mult) end
                if rawget(w, "DelayUntilLoop") then rawset(w, "DelayUntilLoop", 0) end
            end
            
            -- DAMAGE
            if Config.DamageHack then
                for _, k in ipairs({"DirectDamage","HeadDamage","DirectHeadDamage","AlternateDamage","ExplosiveDamage","MobDamage"}) do
                    if rawget(w, k) then rawset(w, k, Config.DamageValue) end
                end
            end
            
            -- SENTRY
            if Config.SentryGod and rawget(w, "Health") and rawget(w, "Name") == "Sentry" then
                rawset(w, "Health", 99999)
            end
            if Config.SentryCD and rawget(w, "CD") and rawget(w, "Name") == "Sentry" then
                rawset(w, "CD", 0.1)
            end
            if Config.NoStrafe and rawget(w, "StrafePenaltySpeed") then
                rawset(w, "StrafePenaltySpeed", 0)
            end
            
            -- BULLET VISUAL
            if Config.RainbowBullets and rawget(w, "RainbowBullets") ~= nil then rawset(w, "RainbowBullets", true) end
            if Config.BrightBullets and rawget(w, "BulletBrightness") then rawset(w, "BulletBrightness", 10) end
            if Config.FatBullets and rawget(w, "BulletWidth") then rawset(w, "BulletWidth", 20) end
        end)
    end
end

task.spawn(function()
    while task.wait(0.1) do
        if not _G.RENXX then break end
        if Config.InfAmmo or Config.NoRecoil or Config.NoSpread or Config.RapidFire or Config.DamageHack or Config.AutoMode or Config.NoReload or Config.SentryGod or Config.SentryCD or Config.NoStrafe or Config.RainbowBullets or Config.BrightBullets or Config.FatBullets then
            applyMods()
        end
    end
end)

-- ==================== HITBOX EXPANDER ====================
local function applyHitboxExpander()
    local size = Config.HitboxSize
    local parts = {"Head","Torso","UpperTorso","LowerTorso","LeftArm","RightArm","LeftLeg","RightLeg"}
    local function expand(char)
        for _, pn in ipairs(parts) do
            local p = char:FindFirstChild(pn)
            if p and p:IsA("BasePart") then
                pcall(function()
                    if not originalHitboxData[p] then
                        originalHitboxData[p] = {Size = p.Size, Transparency = p.Transparency, CanCollide = p.CanCollide}
                    end
                    p.Size = Vector3.new(size, size, size)
                    p.Transparency = 0.5
                    p.CanCollide = false
                end)
            end
        end
    end
    if Config.HitboxExpander then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not (Config.TeamCheck and isSameTeam(p)) then
                expand(p.Character)
            end
        end
        for _, b in ipairs(getAllBots()) do
            if not (Config.TeamCheck and isBotSameTeam(b)) then
                expand(b)
            end
        end
    else
        for p, data in pairs(originalHitboxData) do
            if p and p.Parent then
                pcall(function()
                    p.Size = data.Size
                    p.Transparency = data.Transparency
                    p.CanCollide = data.CanCollide
                end)
            end
        end
        if next(originalHitboxData) then originalHitboxData = {} end
    end
end

task.spawn(function()
    while task.wait(0.2) do
        if not _G.RENXX then break end
        applyHitboxExpander()
    end
end)

-- ==================== AIMBOT ====================
local function getClosestTarget()
    if not Config.Aimbot then return nil end
    local closest, shortest = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovRadius = fovToRadius(Config.POV)
    local aimName = Config.AimPart
    local myChar = LocalPlayer.Character
    local function check(char)
        if not char or char == myChar then return end
        local h = char:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then return end
        local part = char:FindFirstChild(aimName) or char:FindFirstChild("Head")
        if not part then return end
        if Config.WallCheck and not hasLineOfSight(part, char) then return end
        local ok, sp, on = pcall(function() return Camera:WorldToViewportPoint(part.Position) end)
        if not ok or not sp or not on or sp.Z <= 0 then return end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d <= fovRadius and d < shortest then
            shortest = d
            closest = part
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and not (Config.TeamCheck and isSameTeam(p)) then
            check(p.Character)
        end
    end
    for _, b in ipairs(getAllBots()) do
        if not (Config.TeamCheck and isBotSameTeam(b)) then
            check(b)
        end
    end
    return closest
end

local function applyAimbot()
    if not Config.Aimbot or not aimTargetPart or not aimTargetPart.Parent then return end
    local hum = aimTargetPart.Parent:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        aimTargetPart = nil
        return
    end
    local mode = Config.AimMode
    if mode == "Auto" then
        if Cap.MouseMoveRel and Cap.IsMobile then mode = "Mouse"
        elseif Cap.CameraWrite then mode = "Camera"
        elseif Cap.MouseMoveRel then mode = "Mouse" end
    end
    local isNewTarget = (lastAimTarget ~= aimTargetPart)
    local smoothValue = math.max(1, Config.AimSmooth)
    if isNewTarget then
        smoothValue = math.max(1, Config.SwitchSpeed or 1)
        lastAimTarget = aimTargetPart
        switchCooldown = tick() + 0.15
    elseif tick() < switchCooldown then
        smoothValue = math.max(1, Config.SwitchSpeed or 1)
    else
        smoothValue = math.max(1, Config.AimSmooth)
    end
    if mode == "Camera" and Cap.CameraWrite then
        local targetCF = CFrame.new(Camera.CFrame.Position, aimTargetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / smoothValue)
    end
    if mode == "Mouse" and Cap.MouseMoveRel then
        local now = tick()
        if now - lastMouseMove > 0.008 then
            lastMouseMove = now
            local ok, sp, on = pcall(function() return Camera:WorldToViewportPoint(aimTargetPart.Position) end)
            if ok and sp and on and sp.Z > 0 then
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local deltaX = (sp.X - center.X) / smoothValue
                local deltaY = (sp.Y - center.Y) / smoothValue
                pcall(function() mousemoverel(deltaX, deltaY) end)
            end
        end
    end
end

-- ==================== TELEPORT ====================
local function calculateTPCFrame(hrp)
    local d = Config.TPDistance
    if Config.TPPosition == "Above" then return hrp.CFrame + Vector3.new(0, d, 0)
    elseif Config.TPPosition == "Behind" then return hrp.CFrame * CFrame.new(0, 3, d)
    elseif Config.TPPosition == "Front" then return hrp.CFrame * CFrame.new(0, 3, -d)
    elseif Config.TPPosition == "Side" then return hrp.CFrame * CFrame.new(d, 3, 0) end
    return hrp.CFrame + Vector3.new(0, d, 0)
end

local function findNearest(list)
    if #list == 0 then return nil end
    local nearest, shortest = nil, math.huge
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return list[1] end
    for _, e in ipairs(list) do
        local hrp = e:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - myHRP.Position).Magnitude
            if d < shortest then shortest = d nearest = e end
        end
    end
    return nearest or list[1]
end

local function findTargetByPriority()
    local pe, be, ae = {}, {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not isSameTeam(p) then
                table.insert(pe, p.Character)
                table.insert(ae, p.Character)
            end
        end
    end
    for _, b in ipairs(getAllBots()) do
        if not isBotSameTeam(b) then
            table.insert(be, b)
            table.insert(ae, b)
        end
    end
    if Config.TPPriority == "TP to Player Enemy Only" then return findNearest(pe)
    elseif Config.TPPriority == "TP to Bot Enemy Only" then return findNearest(be) end
    return findNearest(ae)
end

local function teleportToTarget()
    if not Config.AutoTP or Config.Fly then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    if currentTPTarget and currentTPTarget.Parent then
        local h = currentTPTarget:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            local tp = Players:GetPlayerFromCharacter(currentTPTarget)
            if tp and isSameTeam(tp) then currentTPTarget = nil return end
            local hrp = currentTPTarget:FindFirstChild("HumanoidRootPart")
            if hrp then
                myHRP.CFrame = calculateTPCFrame(hrp)
                myHRP.Velocity = Vector3.zero
                return
            end
        end
        currentTPTarget = nil
    else
        currentTPTarget = nil
    end
    local nt = findTargetByPriority()
    if nt then
        local tp = Players:GetPlayerFromCharacter(nt)
        if tp and isSameTeam(tp) then return end
        local hrp = nt:FindFirstChild("HumanoidRootPart")
        if hrp then
            myHRP.CFrame = calculateTPCFrame(hrp)
            myHRP.Velocity = Vector3.zero
            currentTPTarget = nt
        end
    end
end

local function teleportToAllBots()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _, b in ipairs(getAllBots()) do
        if not isBotSameTeam(b) then
            local hrp = b:FindFirstChild("HumanoidRootPart")
            local h = b:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then myHRP.CFrame = calculateTPCFrame(hrp) end
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

-- ==================== SURVIVAL ====================
local function survivalLoop()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if Config.GodMode and hum then
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        pcall(function() char:SetAttribute("GodMode", true) end)
    end
    if Config.FastRegen and hum and not Config.GodMode then
        if hum.Health < hum.MaxHealth then
            hum.Health = math.min(hum.Health + 5, hum.MaxHealth)
        end
    end
    if Config.AntiFall and hrp then
        if hrp.Position.Y < -20 and hrp.Position.Y > -200 then
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = {char}
            local ray = workspace:Raycast(Vector3.new(hrp.Position.X, 100, hrp.Position.Z), Vector3.new(0, -500, 0), rp)
            if ray then hrp.CFrame = CFrame.new(ray.Position + Vector3.new(0, 5, 0)) end
        end
    end
    if Config.AntiVoid and hrp then
        if hrp.Position.Y < -500 then
            local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
            if spawn then hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            else hrp.CFrame = CFrame.new(0, 50, 0) end
        end
    end
end

-- ==================== PERFORMANCE ====================
local fpsBoostActive = false
local hiddenObjects = {}

local function enableFPSBoost()
    if fpsBoostActive then return end
    fpsBoostActive = true
    pcall(function()
        if not originalLightingSaved then
            originalLightingData.GlobalShadows = Lighting.GlobalShadows
            originalLightingData.FogEnd = Lighting.FogEnd
            originalLightingData.Brightness = Lighting.Brightness
            originalLightingSaved = true
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    end)
    task.spawn(function()
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not _G.RENXX then break end
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    if obj.Enabled then obj.Enabled = false table.insert(hiddenObjects, obj) end
                end
                if obj:IsA("BasePart") and obj.CastShadow then obj.CastShadow = false end
            end
        end)
    end)
end

local function disableFPSBoost()
    if not fpsBoostActive then return end
    fpsBoostActive = false
    pcall(function()
        if originalLightingSaved then
            Lighting.GlobalShadows = originalLightingData.GlobalShadows
            Lighting.FogEnd = originalLightingData.FogEnd
            Lighting.Brightness = originalLightingData.Brightness
        end
    end)
    for _, obj in ipairs(hiddenObjects) do pcall(function() obj.Enabled = true end) end
    hiddenObjects = {}
end

local function enableLowPing()
    if not Cap.Settings then return end
    pcall(function() settings().Network.IncomingReplicationLag = 0 end)
end

local function disableLowPing()
    if not Cap.Settings then return end
    pcall(function() settings().Network.IncomingReplicationLag = 0 end)
end

local function createStatsDisplay()
    if not Cap.Drawing then return end
    pcall(function()
        if not fpsCounter then
            fpsCounter = Drawing.new("Text")
            fpsCounter.Size = 16
            fpsCounter.Outline = true
            fpsCounter.OutlineColor = Color3.new(0, 0, 0)
            fpsCounter.Color = Color3.fromRGB(0, 255, 100)
            fpsCounter.Position = Vector2.new(15, 15)
            fpsCounter.Text = "FPS: 0"
            fpsCounter.Visible = true
        end
        if not pingCounter then
            pingCounter = Drawing.new("Text")
            pingCounter.Size = 16
            pingCounter.Outline = true
            pingCounter.OutlineColor = Color3.new(0, 0, 0)
            pingCounter.Color = Color3.fromRGB(100, 200, 255)
            pingCounter.Position = Vector2.new(15, 35)
            pingCounter.Text = "PING: 0 ms"
            pingCounter.Visible = true
        end
    end)
end

local function destroyStatsDisplay()
    if fpsCounter then pcall(function() fpsCounter:Remove() end) fpsCounter = nil end
    if pingCounter then pcall(function() pingCounter:Remove() end) pingCounter = nil end
end

-- ==================== WINDOW ====================
local Window = Rayfield:CreateWindow({
    Name = "RENXX | HYPERshot",
    LoadingTitle = "Loading RENXX...",
    LoadingSubtitle = "By DEEP & RENXX",
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
ProtTab:CreateSlider({Name = "Anti-Fling Threshold", Range = {100, 1000}, Increment = 50, CurrentValue = 500, Callback = function(v) Config.AntiFlingThreshold = v end})
ProtTab:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) Config.AntiAFK = v end})

ProtTab:CreateSection("Anti-Ban")
ProtTab:CreateToggle({Name = "Rate Limiter", CurrentValue = true, Callback = function(v) Config.RateLimiter = v end})
ProtTab:CreateToggle({Name = "Safe Mode", CurrentValue = false, Callback = function(v) Config.SafeMode = v end})
ProtTab:CreateSlider({Name = "Max Remote/Second", Range = {1, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) Config.MaxRemotePerSec = v end})
ProtTab:CreateButton({Name = "Show Anti-Ban Stats", Callback = function()
    Rayfield:Notify({Title = "Anti-Ban Stats", Content = string.format("Kick: %d | Remote: %d | Data: %d | Crash: %d", AntiBan.BlockedKick, AntiBan.BlockedRemote, AntiBan.BlockedDataSend, AntiBan.BlockedCrash), Duration = 6})
end})

ProtTab:CreateSection("Performance")
ProtTab:CreateToggle({Name = "Boost FPS", CurrentValue = false, Callback = function(v)
    Config.BoostFPS = v
    if v then enableFPSBoost() else disableFPSBoost() end
    Rayfield:Notify({Title="RENXX", Content="Boost FPS: " .. (v and "ON" or "OFF"), Duration=2})
end})
ProtTab:CreateDropdown({Name = "Set FPS", Options = {"30","60","90","120","<120"}, CurrentOption = "<120", Callback = function(o)
    local val = type(o) == "table" and o[1] or o
    if val == "<120" then
        Config.SetFPS = 999
        if Cap.Settings then pcall(function() settings().Rendering.FramerateCap = 999 end) end
    else
        Config.SetFPS = tonumber(val) or 120
        if Cap.Settings then pcall(function() settings().Rendering.FramerateCap = Config.SetFPS end) end
    end
    Rayfield:Notify({Title="RENXX", Content="FPS Cap: " .. val, Duration=2})
end})
ProtTab:CreateToggle({Name = "Low Ping", CurrentValue = false, Callback = function(v)
    Config.LowPing = v
    if v then enableLowPing() else disableLowPing() end
end})
ProtTab:CreateDropdown({Name = "Set Ping", Options = {"100","70","60","30","15"}, CurrentOption = "60", Callback = function(o)
    local val = tonumber(type(o) == "table" and o[1] or o) or 60
    Config.SetPing = val
    if Cap.Settings then pcall(function() settings().Network.IncomingReplicationLag = val / 1000 end) end
    Rayfield:Notify({Title="RENXX", Content="Target Ping: " .. val .. "ms", Duration=2})
end})
ProtTab:CreateToggle({Name = "Show FPS + Ping", CurrentValue = false, Callback = function(v)
    Config.ShowStats = v
    if v then createStatsDisplay() else destroyStatsDisplay() end
end})

ProtTab:CreateSection("Debug")
ProtTab:CreateButton({Name = "Print Capability", Callback = function()
    print("--- CAPABILITY ---")
    print("Drawing:", Cap.Drawing, "| Hook:", Cap.Hook, "| GC:", Cap.GC)
    print("mousemoverel:", Cap.MouseMoveRel, "| CameraWrite:", Cap.CameraWrite)
    print("Settings:", Cap.Settings, "| Mobile:", Cap.IsMobile)
end})
ProtTab:CreateButton({Name = "Test Team Detection", Callback = function()
    print("--- TEAM TEST ---")
    print("Your Team:", LocalPlayer.Team and LocalPlayer.Team.Name or "NONE")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            print(p.Name, "| Team:", p.Team and p.Team.Name or "NONE", "| Same:", isSameTeam(p))
        end
    end
end})

-- ==================== TAB 2: COMBAT ====================
local CombatTab = Window:CreateTab("COMBAT", 4483362458)
CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({Name = "Aimbot (Player + Bot)", CurrentValue = false, Callback = function(v)
    Config.Aimbot = v
    Rayfield:Notify({Title="RENXX", Content="Aimbot: " .. (v and "ON" or "OFF"), Duration=2})
end})
CombatTab:CreateToggle({Name = "Auto Shoot", CurrentValue = false, Callback = function(v) Config.AutoShoot = v end})
CombatTab:CreateSlider({Name = "Aim Smoothness", Range = {1, 15}, Increment = 1, Suffix = "x", CurrentValue = 3, Callback = function(v) Config.AimSmooth = v end})
CombatTab:CreateSlider({Name = "Switch Speed", Range = {1, 10}, Increment = 1, Suffix = "x", CurrentValue = 1, Callback = function(v) Config.SwitchSpeed = v end})
CombatTab:CreateSlider({Name = "FOV", Range = {30, 360}, Increment = 1, Suffix = "deg", CurrentValue = 90, Callback = function(v) Config.POV = v end})
CombatTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Callback = function(v) Config.ShowPOV = v end})
CombatTab:CreateColorPicker({Name = "FOV Color", Color = Color3.fromRGB(255, 0, 100), Callback = function(c) Config.POVColor = c end})
CombatTab:CreateDropdown({Name = "Aim Mode", Options = {"Auto","Camera","Mouse"}, CurrentOption = "Mouse",
    Callback = function(o) if type(o) == "table" then Config.AimMode = o[1] else Config.AimMode = o end end})
CombatTab:CreateDropdown({Name = "Aim Part", Options = {"Head","UpperTorso","LowerTorso","HumanoidRootPart"}, CurrentOption = "Head",
    Callback = function(o) if type(o) == "table" then Config.AimPart = o[1] else Config.AimPart = o end end})

CombatTab:CreateSection("Filter")
CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Config.TeamCheck = v end})
CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = false, Callback = function(v) Config.WallCheck = v end})

CombatTab:CreateSection("Hitbox Expander")
CombatTab:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) Config.HitboxExpander = v end})
CombatTab:CreateSlider({Name = "Hitbox Size", Range = {1, 20}, Increment = 1, Suffix = " studs", CurrentValue = 5, Callback = function(v) Config.HitboxSize = v end})

-- ==================== TAB 3: VISUAL ====================
local VisualTab = Window:CreateTab("VISUAL", 4483362458)
VisualTab:CreateSection("ESP")
VisualTab:CreateDropdown({Name = "ESP Position", Options = {"Top","Center","Bottom"}, CurrentOption = "Bottom",
    Callback = function(o) if type(o) == "table" then Config.ESPPosition = o[1] else Config.ESPPosition = o end end})
VisualTab:CreateToggle({Name = "ESP Line Player", CurrentValue = false, Callback = function(v) Config.ESPLinePlayer = v end})
VisualTab:CreateToggle({Name = "ESP Line BOT", CurrentValue = false, Callback = function(v) Config.ESPLineBOT = v end})
VisualTab:CreateToggle({Name = "ESP Name", CurrentValue = false, Callback = function(v) Config.ESPName = v end})
VisualTab:CreateToggle({Name = "ESP Health", CurrentValue = false, Callback = function(v) Config.ESPHealth = v end})
VisualTab:CreateToggle({Name = "ESP Distance", CurrentValue = false, Callback = function(v) Config.ESPDistance = v end})
VisualTab:CreateToggle({Name = "ESP BOX", CurrentValue = false, Callback = function(v) Config.ESPBox = v end})

VisualTab:CreateSection("Colors")
VisualTab:CreateColorPicker({Name = "Text Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(c) Config.ESPTextColor = c end})
VisualTab:CreateColorPicker({Name = "BOX Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(c) Config.ESPBoxColor = c end})
VisualTab:CreateColorPicker({Name = "Line Player Team Color", Color = Color3.fromRGB(0, 100, 255), Callback = function(c) Config.LinePlayerTeamColor = c end})
VisualTab:CreateColorPicker({Name = "Line Player Enemy Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(c) Config.LinePlayerEnemyColor = c end})
VisualTab:CreateColorPicker({Name = "Line BOT Team Color", Color = Color3.fromRGB(0, 255, 0), Callback = function(c) Config.LineBOTTeamColor = c end})
VisualTab:CreateColorPicker({Name = "Line BOT Enemy Color", Color = Color3.fromRGB(255, 255, 0), Callback = function(c) Config.LineBOTEnemyColor = c end})

-- ==================== TAB 4: PLAYER ====================
local PlayerTab = Window:CreateTab("PLAYER", 4483362458)
PlayerTab:CreateSection("Survival")
PlayerTab:CreateToggle({Name = "God Mode", CurrentValue = false, Callback = function(v)
    Config.GodMode = v
    Rayfield:Notify({Title="RENXX", Content="God Mode: " .. (v and "ON" or "OFF"), Duration=2})
end})
PlayerTab:CreateToggle({Name = "Fast Regen", CurrentValue = false, Callback = function(v)
    Config.FastRegen = v
    Rayfield:Notify({Title="RENXX", Content="Fast Regen: " .. (v and "ON" or "OFF"), Duration=2})
end})
PlayerTab:CreateToggle({Name = "Anti Fall", CurrentValue = false, Callback = function(v) Config.AntiFall = v end})
PlayerTab:CreateToggle({Name = "Anti Void", CurrentValue = false, Callback = function(v) Config.AntiVoid = v end})

PlayerTab:CreateSection("Speed")
PlayerTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Config.SpeedHack = v end})
PlayerTab:CreateSlider({Name = "Speed Value", Range = {0, 100}, Increment = 1, Suffix = "x", CurrentValue = 30, Callback = function(v) Config.SpeedValue = v end})
PlayerTab:CreateToggle({Name = "Speed Randomize", CurrentValue = true, Callback = function(v) Config.SpeedRandomize = v end})

PlayerTab:CreateSection("Jump")
PlayerTab:CreateToggle({Name = "Jump Hack", CurrentValue = false, Callback = function(v) Config.JumpHack = v end})
PlayerTab:CreateSlider({Name = "Jump Value", Range = {0, 100}, Increment = 1, CurrentValue = 50, Callback = function(v) Config.JumpValue = v end})
PlayerTab:CreateToggle({Name = "Infinity Jump", CurrentValue = false, Callback = function(v) Config.InfJump = v end})

PlayerTab:CreateSection("Movement")
PlayerTab:CreateToggle({Name = "No Clip", CurrentValue = false, Callback = function(v) Config.NoClip = v end})
PlayerTab:CreateToggle({Name = "Fly", CurrentValue = false, Callback = function(v)
    Config.Fly = v
    if v then
        if Config.AutoTP then Config.AutoTP = false end
        if Config.TPAllBOT then Config.TPAllBOT = false end
        startFly()
    else
        stopFly()
    end
end})
PlayerTab:CreateSlider({Name = "Fly Speed", Range = {0, 1000}, Increment = 10, CurrentValue = 50, Callback = function(v) Config.FlySpeed = v end})

-- ==================== TAB 5: WEAPON ====================
local WeaponTab = Window:CreateTab("WEAPON", 4483362458)
WeaponTab:CreateSection("Ammo")
WeaponTab:CreateToggle({Name = "Infinite Ammo", CurrentValue = false, Callback = function(v) Config.InfAmmo = v end})
WeaponTab:CreateToggle({Name = "No Reload", CurrentValue = false, Callback = function(v) Config.NoReload = v end})

WeaponTab:CreateSection("Accuracy")
WeaponTab:CreateToggle({Name = "No Recoil", CurrentValue = false, Callback = function(v) Config.NoRecoil = v end})
WeaponTab:CreateToggle({Name = "No Spread", CurrentValue = false, Callback = function(v) Config.NoSpread = v end})

WeaponTab:CreateSection("Fire Rate")
WeaponTab:CreateToggle({Name = "Rapid Fire", CurrentValue = false, Callback = function(v)
    Config.RapidFire = v
    if not v then
        for w, orig in pairs(originalWeaponData) do
            pcall(function()
                if orig.FireInterval then rawset(w, "FireInterval", orig.FireInterval) end
                if orig.ShootDelay then rawset(w, "ShootDelay", orig.ShootDelay) end
                if orig.AcquireDelay then rawset(w, "AcquireDelay", orig.AcquireDelay) end
                if orig.Debounce then rawset(w, "Debounce", orig.Debounce) end
                if orig.FireRate then rawset(w, "FireRate", orig.FireRate) end
                if orig.FireDelay then rawset(w, "FireDelay", orig.FireDelay) end
                if orig.Cooldown then rawset(w, "Cooldown", orig.Cooldown) end
            end)
        end
        originalWeaponData = {}
    end
end})
WeaponTab:CreateSlider({
    Name = "Fire Rate Multiplier",
    Range = {1, 100},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Callback = function(v) Config.FireRateMultiplier = v end,
})
WeaponTab:CreateToggle({Name = "Auto Mode", CurrentValue = false, Callback = function(v) Config.AutoMode = v end})

WeaponTab:CreateSection("Damage")
WeaponTab:CreateToggle({Name = "Damage Hack", CurrentValue = false, Callback = function(v) Config.DamageHack = v end})
WeaponTab:CreateSlider({Name = "Damage Value", Range = {100, 99999}, Increment = 100, Suffix = " dmg", CurrentValue = 999, Callback = function(v) Config.DamageValue = v end})

WeaponTab:CreateSection("Sentry Mods")
WeaponTab:CreateToggle({Name = "Sentry God Mode", CurrentValue = false, Callback = function(v) Config.SentryGod = v end})
WeaponTab:CreateToggle({Name = "Sentry Fast Cooldown", CurrentValue = false, Callback = function(v) Config.SentryCD = v end})
WeaponTab:CreateToggle({Name = "No Strafe Penalty", CurrentValue = false, Callback = function(v) Config.NoStrafe = v end})

WeaponTab:CreateSection("Bullet Visual")
WeaponTab:CreateToggle({Name = "Rainbow Bullets", CurrentValue = false, Callback = function(v) Config.RainbowBullets = v end})
WeaponTab:CreateToggle({Name = "Bright Bullets", CurrentValue = false, Callback = function(v) Config.BrightBullets = v end})
WeaponTab:CreateToggle({Name = "Fat Bullets", CurrentValue = false, Callback = function(v) Config.FatBullets = v end})

WeaponTab:CreateSection("Debug")
WeaponTab:CreateButton({Name = "Count Weapon Tables", Callback = function()
    weaponCache = findWeaponTables()
    Rayfield:Notify({Title = "Weapon Tables", Content = "Found: " .. #weaponCache, Duration = 3})
end})

-- ==================== TAB 6: FARM ====================
local FarmTab = Window:CreateTab("FARM", 4483362458)
FarmTab:CreateSection("Auto TP")
FarmTab:CreateToggle({Name = "Auto TP to Target", CurrentValue = false, Callback = function(v)
    Config.AutoTP = v
    if v and Config.Fly then
        Config.Fly = false
        stopFly()
    end
    Rayfield:Notify({Title="RENXX", Content="Auto TP: " .. (v and "ON" or "OFF"), Duration=2})
end})
FarmTab:CreateDropdown({Name = "TP Position", Options = {"Above","Behind","Front","Side"}, CurrentOption = "Above",
    Callback = function(o) if type(o) == "table" then Config.TPPosition = o[1] else Config.TPPosition = o end end})
FarmTab:CreateSlider({Name = "TP Distance", Range = {1, 20}, Increment = 1, Suffix = " studs", CurrentValue = 5, Callback = function(v) Config.TPDistance = v end})
FarmTab:CreateDropdown({Name = "Target Priority", Options = {"TP to All Enemy","TP to Player Enemy Only","TP to Bot Enemy Only"}, CurrentOption = "TP to All Enemy",
    Callback = function(o) if type(o) == "table" then Config.TPPriority = o[1] else Config.TPPriority = o end end})

FarmTab:CreateSection("Manual TP")
FarmTab:CreateInput({Name = "TP to Player Name", PlaceholderText = "Enter player name...", RemoveTextAfterFocusLost = false,
    Callback = function(text)
        if text and text ~= "" then
            local target = Players:FindFirstChild(text)
            if target and target.Character then
                if isSameTeam(target) then
                    Rayfield:Notify({Title="RENXX", Content="Target is teammate! Skip.", Duration=2})
                    return
                end
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and myHRP then
                    myHRP.CFrame = calculateTPCFrame(hrp)
                    Rayfield:Notify({Title="RENXX", Content="TP to " .. text, Duration=2})
                end
            else
                Rayfield:Notify({Title="RENXX", Content="Player not found", Duration=2})
            end
        end
    end})

FarmTab:CreateSection("Aura Farming")
FarmTab:CreateToggle({Name = "TP All BOT", CurrentValue = false, Callback = function(v)
    Config.TPAllBOT = v
    if v and Config.Fly then
        Config.Fly = false
        stopFly()
    end
end})
FarmTab:CreateSlider({Name = "TP All Delay", Range = {10, 500}, Increment = 10, Suffix = " (x0.01s)", CurrentValue = 50, Callback = function(v) Config.TPAllDelay = v / 100 end})

-- ==================== DRAWINGS ====================
local povCircle
if Cap.Drawing then
    pcall(function()
        povCircle = Drawing.new("Circle")
        povCircle.Visible = false
        povCircle.Thickness = 2
        povCircle.NumSides = 64
        povCircle.Filled = false
        povCircle.Transparency = 1
    end)
end

local function createESP()
    if not Cap.Drawing then return nil end
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
    for _, v in pairs(d) do pcall(function() v:Remove() end) end
end

local function hideESP(d)
    if not d then return end
    for _, v in pairs(d) do pcall(function() v.Visible = false end) end
end

if Cap.Drawing then
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

-- ==================== LOOPS ====================
task.spawn(function()
    while task.wait(0.05) do
        if not _G.RENXX then break end
        if Config.Aimbot then
            local t = getClosestTarget()
            aimTargetPart = (t and t.Parent) and t or nil
        else aimTargetPart = nil end
    end
end)

task.spawn(function()
    while task.wait(Config.TPAllDelay or 0.1) do
        if not _G.RENXX then break end
        if Config.TPAllBOT and not Config.Fly then teleportToAllBots() end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not _G.RENXX then break end
        local bots = getAllBots()
        local botSet = {}
        for _, b in ipairs(bots) do botSet[b] = true end
        for char, d in pairs(botESP) do
            if not botSet[char] or not char.Parent then
                destroyESP(d)
                botESP[char] = nil
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if not _G.RENXX then break end
        if Config.AutoShoot and aimTargetPart and aimTargetPart.Parent then
            local h = aimTargetPart.Parent:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local now = tick()
                if now - lastShootTime > 0.05 then
                    lastShootTime = now
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new(0, 0))
                    end)
                    if Cap.Mouse1Click then pcall(function() mouse1click() end) end
                    if Cap.Mouse1Press then
                        pcall(function()
                            mouse1press()
                            task.wait(0.01)
                            mouse1release()
                        end)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not _G.RENXX then break end
        survivalLoop()
    end
end)

task.spawn(function()
    while _G.RENXX do
        task.wait(1)
        currentFPS = frameCount
        frameCount = 0
    end
end)

task.spawn(function()
    while _G.RENXX do
        task.wait(1)
        if Config.ShowStats and fpsCounter and pingCounter then
            local ping = 0
            pcall(function()
                local s = Stats.Network.ServerStatsItem["Data Ping"]
                if s then ping = math.floor(s:GetValue()) end
            end)
            pcall(function()
                fpsCounter.Text = "FPS: " .. tostring(currentFPS)
                pingCounter.Text = "PING: " .. tostring(ping) .. " ms"
                if ping < 60 then pingCounter.Color = Color3.fromRGB(0, 255, 100)
                elseif ping < 100 then pingCounter.Color = Color3.fromRGB(255, 200, 0)
                else pingCounter.Color = Color3.fromRGB(255, 50, 50) end
            end)
        end
    end
end)

-- ==================== RENDER ====================
RunService.RenderStepped:Connect(function()
    if not _G.RENXX then return end
    frameCount = frameCount + 1
    
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
    
    applyAimbot()
    
    if Cap.Drawing then
        local active = Config.ESPLinePlayer or Config.ESPLineBOT or Config.ESPName or Config.ESPHealth or Config.ESPDistance or Config.ESPBox
        if not active then
            for _, d in pairs(espData) do hideESP(d) end
            for _, d in pairs(botESP) do hideESP(d) end
        else
            local vpX, vpY = Camera.ViewportSize.X, Camera.ViewportSize.Y
            local lineFrom
            if Config.ESPPosition == "Top" then lineFrom = Vector2.new(vpX / 2, 0)
            elseif Config.ESPPosition == "Center" then lineFrom = Vector2.new(vpX / 2, vpY / 2)
            else lineFrom = Vector2.new(vpX / 2, vpY) end
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and espData[p] then
                    local d = espData[p]
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local head = p.Character:FindFirstChild("Head")
                    if hrp and hum and head and hum.Health > 0 then
                        local spT, onT = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                        local spB, onB = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        if onT and onB and spT.Z > 0 and spB.Z > 0 then
                            local tX = math.clamp(spT.X, -vpX, vpX * 2)
                            local tY = math.clamp(spT.Y, -vpY, vpY * 2)
                            local bY = math.clamp(spB.Y, -vpY, vpY * 2)
                            local bX = math.clamp(spB.X, -vpX, vpX * 2)
                            local isT = isSameTeam(p)
                            local lC = isT and Config.LinePlayerTeamColor or Config.LinePlayerEnemyColor
                            local bC = isT and Config.LinePlayerTeamColor or Config.ESPBoxColor
                            local bH = math.abs(bY - tY)
                            local bW = bH * 0.6
                            local bXo = tX - bW / 2
                            local bYo = tY
                            
                            if Config.ESPLinePlayer then
                                d.line.Visible = true
                                d.line.From = lineFrom
                                d.line.To = Vector2.new(tX, bY)
                                d.line.Color = lC
                                d.line.Thickness = 1.5
                            else d.line.Visible = false end
                            
                            if Config.ESPName then
                                d.name.Visible = true
                                d.name.Text = p.Name
                                d.name.Position = Vector2.new(tX, bYo - 16)
                                d.name.Color = Config.ESPTextColor
                                d.name.Size = 14
                                d.name.Center = true
                                d.name.Outline = true
                                d.name.OutlineColor = Color3.new(0, 0, 0)
                            else d.name.Visible = false end
                            
                            if Config.ESPHealth then
                                local hpP = getHealthPercent(hum)
                                d.hpBG.Visible = true
                                d.hpBG.Size = Vector2.new(4, bH)
                                d.hpBG.Position = Vector2.new(bXo - 8, bYo)
                                d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                d.hpBG.Filled = true
                                d.hpBar.Visible = true
                                d.hpBar.Size = Vector2.new(4, bH * hpP)
                                d.hpBar.Position = Vector2.new(bXo - 8, bYo + (bH * (1 - hpP)))
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
                                d.dist.Position = Vector2.new(bX, bY + 5)
                                d.dist.Color = Config.ESPTextColor
                                d.dist.Size = 12
                                d.dist.Center = true
                                d.dist.Outline = true
                                d.dist.OutlineColor = Color3.new(0, 0, 0)
                            else d.dist.Visible = false end
                            
                            if Config.ESPBox then
                                d.box.Visible = true
                                d.box.Size = Vector2.new(bW, bH)
                                d.box.Position = Vector2.new(bXo, bYo)
                                d.box.Color = bC
                                d.box.Thickness = 1.5
                                d.box.Filled = false
                            else d.box.Visible = false end
                        else hideESP(d) end
                    else hideESP(d) end
                end
            end
            
            for _, botChar in ipairs(getAllBots()) do
                local hum = botChar:FindFirstChildOfClass("Humanoid")
                local hrp = botChar:FindFirstChild("HumanoidRootPart")
                local head = botChar:FindFirstChild("Head")
                if not hum or not hrp or not head or hum.Health <= 0 then
                    if botESP[botChar] then destroyESP(botESP[botChar]) botESP[botChar] = nil end
                else
                    if not botESP[botChar] then botESP[botChar] = createESP() end
                    local d = botESP[botChar]
                    if d then
                        local spT, onT = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                        local spB, onB = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        if onT and onB and spT.Z > 0 and spB.Z > 0 then
                            local tX = math.clamp(spT.X, -vpX, vpX * 2)
                            local tY = math.clamp(spT.Y, -vpY, vpY * 2)
                            local bY = math.clamp(spB.Y, -vpY, vpY * 2)
                            local bX = math.clamp(spB.X, -vpX, vpX * 2)
                            local bIsT = isBotSameTeam(botChar)
                            local bColor = bIsT and Config.LineBOTTeamColor or Config.LineBOTEnemyColor
                            local bH = math.abs(bY - tY)
                            local bW = bH * 0.6
                            local bXo = tX - bW / 2
                            local bYo = tY
                            
                            if Config.ESPLineBOT then
                                d.line.Visible = true
                                d.line.From = lineFrom
                                d.line.To = Vector2.new(tX, bY)
                                d.line.Color = bColor
                                d.line.Thickness = 1.5
                            else d.line.Visible = false end
                            
                            if Config.ESPName then
                                d.name.Visible = true
                                d.name.Text = "[BOT] " .. botChar.Name
                                d.name.Position = Vector2.new(tX, bYo - 16)
                                d.name.Color = Config.ESPTextColor
                                d.name.Size = 14
                                d.name.Center = true
                                d.name.Outline = true
                                d.name.OutlineColor = Color3.new(0, 0, 0)
                            else d.name.Visible = false end
                            
                            if Config.ESPHealth then
                                local hpP = getHealthPercent(hum)
                                d.hpBG.Visible = true
                                d.hpBG.Size = Vector2.new(4, bH)
                                d.hpBG.Position = Vector2.new(bXo - 8, bYo)
                                d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                d.hpBG.Filled = true
                                d.hpBar.Visible = true
                                d.hpBar.Size = Vector2.new(4, bH * hpP)
                                d.hpBar.Position = Vector2.new(bXo - 8, bYo + (bH * (1 - hpP)))
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
                                d.dist.Position = Vector2.new(bX, bY + 5)
                                d.dist.Color = Config.ESPTextColor
                                d.dist.Size = 12
                                d.dist.Center = true
                                d.dist.Outline = true
                                d.dist.OutlineColor = Color3.new(0, 0, 0)
                            else d.dist.Visible = false end
                            
                            if Config.ESPBox then
                                d.box.Visible = true
                                d.box.Size = Vector2.new(bW, bH)
                                d.box.Position = Vector2.new(bXo, bYo)
                                d.box.Color = bColor
                                d.box.Thickness = 1.5
                                d.box.Filled = false
                            else d.box.Visible = false end
                        else hideESP(d) end
                    end
                end
            end
        end
    end
end)

-- ==================== HEARTBEAT ====================
RunService.Heartbeat:Connect(function()
    if not _G.RENXX then return end
    if Config.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then flyBG.CFrame = Camera.CFrame end
    end
    if Config.AutoTP then teleportToTarget() end
    if Config.AntiFling and not Config.Fly and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Velocity.Magnitude > Config.AntiFlingThreshold then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.SpeedHack then
                if Config.SpeedRandomize then
                    if tick() - lastSpeedChange > 1 then
                        lastSpeedChange = tick()
                        hum.WalkSpeed = Config.SpeedValue + math.random(-2, 2)
                    end
                else
                    hum.WalkSpeed = Config.SpeedValue
                end
            end
            if Config.JumpHack then
                hum.UseJumpPower = true
                hum.JumpPower = Config.JumpValue
            end
            if Config.NoClip then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        if originalCollide[p] == nil then
                            originalCollide[p] = p.CanCollide
                            originalTransparency[p] = p.Transparency
                        end
                        p.CanCollide = false
                    end
                end
            else
                if next(originalCollide) then
                    for p, c in pairs(originalCollide) do
                        if p and p.Parent then
                            pcall(function()
                                p.CanCollide = c
                                if originalTransparency[p] ~= nil then p.Transparency = originalTransparency[p] end
                            end)
                        end
                    end
                    originalCollide = {}
                    originalTransparency = {}
                end
            end
        end
    end
end)

-- ==================== INF JUMP ====================
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==================== ANTI AFK ====================
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
        if Cap.Mouse1Click then pcall(function() mouse1click() end) end
    end
end)

-- ==================== PROTECTION HOOK ====================
if Cap.Hook then
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldNC = mt.__namecall
        local newc = newcclosure or function(f) return f end
        mt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if not method then return oldNC(self, ...) end
            local ml = method:lower()
            
            if Config.AntiKick and (ml == "kick" or ml == "ban") then
                if self == LocalPlayer then
                    AntiBan.BlockedKick = AntiBan.BlockedKick + 1
                    return nil
                end
            end
            
            if Config.AntiTeleportVoid and (ml == "fireserver" or ml == "invokeserver") and typeof(self) == "Instance" then
                local n = self.Name:lower()
                for _, kw in ipairs({"sendtovoid","teleportvoid","kicktovoid","voidteleport","voidkick","voidtrap"}) do
                    if n:find(kw) then
                        AntiBan.BlockedTeleport = AntiBan.BlockedTeleport + 1
                        return nil
                    end
                end
            end
            
            if (Config.AntiDetect or Config.AntiDataSend) and (ml == "fireserver" or ml == "invokeserver") and typeof(self) == "Instance" then
                local n = self.Name:lower()
                if Config.AntiDetect and (n:find("detect") or n:find("anticheat") or n:find("flag") or n:find("report")) then
                    AntiBan.BlockedRemote = AntiBan.BlockedRemote + 1
                    return nil
                end
                if Config.AntiDataSend and (n:find("watch") or n:find("monitor") or n:find("trace")) then
                    AntiBan.BlockedDataSend = AntiBan.BlockedDataSend + 1
                    return nil
                end
            end
            
            if Config.AntiCrash and ml == "fireserver" and typeof(self) == "Instance" then
                local n = self.Name:lower()
                if n:find("crash") or n:find("disconnect") then
                    AntiBan.BlockedCrash = AntiBan.BlockedCrash + 1
                    return nil
                end
            end
            
            return oldNC(self, table.unpack(args))
        end)
        setreadonly(mt, true)
    end)
end

-- ==================== CHARACTER ADDED ====================
LocalPlayer.CharacterAdded:Connect(function()
    repeat task.wait(0.1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    flyBV = nil
    flyBG = nil
    currentTPTarget = nil
    originalCollide = {}
    originalTransparency = {}
    if Config.Fly then startFly() end
end)

-- ==================== NOTIF ====================
Rayfield:Notify({
    Title = "RENXX",
    Content = "6 Tab | Config Separated | Fire Rate Multiplier",
    Duration = 6,
})

-- ==================== PRINT ====================
print("==========================================================")
print("  RENXX | HYPERshot")
print("==========================================================")
print("  PROTECTION  : Anti Kick, Anti-Ban, Performance")
print("  COMBAT      : Aimbot (Mouse), Auto Shoot, Hitbox")
print("  VISUAL      : ESP Line, Name, HP, Distance, Box")
print("  PLAYER      : Survival, Speed, Jump, Fly")
print("  WEAPON      : Inf Ammo, No Recoil, Rapid Fire")
print("  FARM        : Auto TP, Aura, Manual TP")
print("==========================================================")
print("  Status      : LOADED")
print("  Weapon      : " .. #weaponCache .. " tables")
print("  Mobile      : " .. (Cap.IsMobile and "YES" or "NO"))
print("==========================================================")
print("  By: DEEP & RENXX")
print("==========================================================")
