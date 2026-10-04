-- ==================================
-- RENXX WEAPON v5.0
-- By: DEEP & RENXX
-- Library: Rayfield
-- Head + Body Damage Split
-- ==================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==================== EXECUTOR CHECK ====================
local hasGC = pcall(function()
    return type(getgc(true)) == "table"
end)

-- ==================== CLEANUP ====================
if _G.RENXX_WEAPON_V5 then
    _G.RENXX_WEAPON_V5 = false
    task.wait(0.2)
end
_G.RENXX_WEAPON_V5 = true

-- ==================== CONFIG ====================
local Config = {
    -- Ammo
    InfAmmo = false,
    MaxAmmoValue = 99999,
    FillAmmoValue = 9999,
    
    -- Accuracy
    NoRecoil = false,
    NoSpread = false,
    
    -- Fire Rate
    RapidFire = false,
    FireRate = 0,
    
    -- Damage Head
    DamageHead = false,
    DamageHeadValue = 999999,
    
    -- Damage Body
    DamageBody = false,
    DamageBodyValue = 999999,
}

-- ==================== STATE ====================
local weaponCache = {}

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
    if not _G.RENXX_WEAPON_V5 then return end
    weaponCache = findWeaponTables()
    while _G.RENXX_WEAPON_V5 do
        task.wait(15)
        if not _G.RENXX_WEAPON_V5 then break end
        weaponCache = findWeaponTables()
    end
end)

-- ==================== APPLY MODS ====================
local function applyWeaponMods()
    if not hasGC then return end
    for _, weapon in ipairs(weaponCache) do
        pcall(function()
            -- 1. INFINITY AMMO
            if Config.InfAmmo then
                rawset(weapon, "FillAmmo", Config.FillAmmoValue)
                rawset(weapon, "MaxAmmo", Config.MaxAmmoValue)
                rawset(weapon, "AmmoPerMag", Config.FillAmmoValue)
                rawset(weapon, "Ammo", Config.FillAmmoValue)
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
            
            -- 5. DAMAGE HEAD (TERPISAH)
            if Config.DamageHead then
                local dmg = Config.DamageHeadValue
                rawset(weapon, "HeadDamage", dmg)
                rawset(weapon, "DirectHeadDamage", dmg)
                if rawget(weapon, "HeadshotDamage") then rawset(weapon, "HeadshotDamage", dmg) end
                if rawget(weapon, "CriticalDamage") then rawset(weapon, "CriticalDamage", dmg) end
            end
            
            -- 6. DAMAGE BODY (TERPISAH)
            if Config.DamageBody then
                local dmg = Config.DamageBodyValue
                rawset(weapon, "DirectDamage", dmg)
                rawset(weapon, "AlternateDamage", dmg)
                rawset(weapon, "MobDamage", dmg)
                rawset(weapon, "ExplosiveDamage", dmg)
                if rawget(weapon, "BodyDamage") then rawset(weapon, "BodyDamage", dmg) end
                if rawget(weapon, "BaseDamage") then rawset(weapon, "BaseDamage", dmg) end
                if rawget(weapon, "MaxDamage") then rawset(weapon, "MaxDamage", dmg) end
                if rawget(weapon, "MinDamage") then rawset(weapon, "MinDamage", dmg) end
                if rawget(weapon, "TorsoDamage") then rawset(weapon, "TorsoDamage", dmg) end
                if rawget(weapon, "LimbDamage") then rawset(weapon, "LimbDamage", dmg) end
                if rawget(weapon, "HitboxDamage") then rawset(weapon, "HitboxDamage", dmg) end
                if rawget(weapon, "PelletDamage") then rawset(weapon, "PelletDamage", dmg) end
                if rawget(weapon, "ImpactDamage") then rawset(weapon, "ImpactDamage", dmg) end
            end
            
            -- PERCENT (biar gak dipotong)
            if Config.DamageHead or Config.DamageBody then
                rawset(weapon, "DamagePercent", 1)
                rawset(weapon, "AlternateDamagePercent", 1)
                if rawget(weapon, "DamageMultiplier") then rawset(weapon, "DamageMultiplier", 1) end
                if rawget(weapon, "HeadshotMultiplier") then rawset(weapon, "HeadshotMultiplier", 1) end
            end
        end)
    end
end

-- ==================== LOOP AGRESIF ====================
task.spawn(function()
    while task.wait(0.01) do
        if not _G.RENXX_WEAPON_V5 then break end
        if Config.InfAmmo or Config.RapidFire or Config.NoRecoil 
           or Config.NoSpread or Config.DamageHead or Config.DamageBody then
            applyWeaponMods()
        end
    end
end)

-- ==================== WINDOW ====================
local Window = Rayfield:CreateWindow({
    Name = "RENXX WEAPON v5.0 | Hypershot",
    LoadingTitle = "Loading RENXX WEAPON...",
    LoadingSubtitle = "Weapon Mod v5.0 - By DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================== TAB 1: AMMO ====================
local AmmoTab = Window:CreateTab("AMMO", 4483362458)

AmmoTab:CreateSection("Ammo")

AmmoTab:CreateToggle({
    Name = "Infinity Ammo",
    CurrentValue = false,
    Callback = function(v)
        Config.InfAmmo = v
        Rayfield:Notify({Title="RENXX", Content="Infinity Ammo: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

AmmoTab:CreateSlider({
    Name = "Max Ammo Value",
    Range = {100, 999999}, Increment = 100, Suffix = " ammo", CurrentValue = 99999,
    Callback = function(v) Config.MaxAmmoValue = v end,
})

AmmoTab:CreateSlider({
    Name = "Fill Ammo Value",
    Range = {100, 99999}, Increment = 100, Suffix = " ammo", CurrentValue = 9999,
    Callback = function(v) Config.FillAmmoValue = v end,
})

-- ==================== TAB 2: ACCURACY ====================
local AccTab = Window:CreateTab("ACCURACY", 4483362458)

AccTab:CreateSection("Recoil")

AccTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Callback = function(v)
        Config.NoRecoil = v
        Rayfield:Notify({Title="RENXX", Content="No Recoil: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

AccTab:CreateSection("Spread")

AccTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
    Callback = function(v)
        Config.NoSpread = v
        Rayfield:Notify({Title="RENXX", Content="No Spread: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

-- ==================== TAB 3: FIRE RATE ====================
local FireTab = Window:CreateTab("FIRE RATE", 4483362458)

FireTab:CreateSection("Rapid Fire")

FireTab:CreateToggle({
    Name = "Rapid Fire",
    CurrentValue = false,
    Callback = function(v)
        Config.RapidFire = v
        Rayfield:Notify({Title="RENXX", Content="Rapid Fire: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

FireTab:CreateSlider({
    Name = "Fire Rate Value",
    Range = {0, 100}, Increment = 1, Suffix = " (x0.01s)", CurrentValue = 0,
    Callback = function(v) Config.FireRate = v / 100 end,
})

FireTab:CreateParagraph({
    Title = "Info",
    Content = "0 = INSTAN (paling cepat)\n1 = 0.01s\n100 = 1.00s (lambat)\n\nDefault: 0",
})

-- ==================== TAB 4: DAMAGE ====================
local DamageTab = Window:CreateTab("DAMAGE", 4483362458)

DamageTab:CreateSection("Damage Head")

DamageTab:CreateToggle({
    Name = "Damage Head",
    CurrentValue = false,
    Callback = function(v)
        Config.DamageHead = v
        Rayfield:Notify({Title="RENXX", Content="Damage Head: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

DamageTab:CreateSlider({
    Name = "Damage Head Value",
    Range = {100, 9999999}, Increment = 100, Suffix = " dmg", CurrentValue = 999999,
    Callback = function(v) Config.DamageHeadValue = v end,
})

DamageTab:CreateSection("Damage Body")

DamageTab:CreateToggle({
    Name = "Damage Body",
    CurrentValue = false,
    Callback = function(v)
        Config.DamageBody = v
        Rayfield:Notify({Title="RENXX", Content="Damage Body: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

DamageTab:CreateSlider({
    Name = "Damage Body Value",
    Range = {100, 9999999}, Increment = 100, Suffix = " dmg", CurrentValue = 999999,
    Callback = function(v) Config.DamageBodyValue = v end,
})

DamageTab:CreateParagraph({
    Title = "Info",
    Content = "Damage Head = damage ke kepala\nDamage Body = damage ke badan\n\nBisa di-ON terpisah:\n- Cuma Head = headshot doang gede\n- Cuma Body = body doang gede\n- Dua-duanya = semua gede",
})

-- ==================== TAB 5: DEBUG ====================
local DebugTab = Window:CreateTab("DEBUG", 4483362458)

DebugTab:CreateSection("Debug")

DebugTab:CreateButton({
    Name = "Count Weapon Tables",
    Callback = function()
        weaponCache = findWeaponTables()
        Rayfield:Notify({
            Title = "Weapon Tables",
            Content = "Found: " .. #weaponCache .. " tables",
            Duration = 3,
        })
    end,
})

DebugTab:CreateButton({
    Name = "Show Weapon Properties (Head + Body)",
    Callback = function()
        if #weaponCache == 0 then
            Rayfield:Notify({Title = "RENXX", Content = "No weapons found. Equip a weapon first!", Duration = 4})
            return
        end
        
        local lines = {}
        local weapon = weaponCache[1]
        table.insert(lines, "=== WEAPON PROPERTIES ===")
        for k, v in pairs(weapon) do
            local kLower = tostring(k):lower()
            if kLower:find("damage") or kLower:find("head") 
               or kLower:find("body") or kLower:find("torso")
               or kLower:find("limb") or kLower:find("percent") then
                table.insert(lines, tostring(k) .. " = " .. tostring(v))
            end
        end
        
        Rayfield:Notify({
            Title = "RENXX DEBUG",
            Content = "Total weapon: "..#weaponCache.." | Cek console F9",
            Duration = 4,
        })
        
        for _, line in ipairs(lines) do
            print(line)
        end
    end,
})

-- ==================== NOTIFIKASI ====================
Rayfield:Notify({
    Title = "RENXX WEAPON v5.0",
    Content = "Loaded! Head + Body Split - By DEEP & RENXX",
    Duration = 4,
})

-- ==================== PRINT ====================
print("v5.0 - WEAPON MODE | READY")
print("[AMMO] [ACCURACY] [FIRE RATE] [DAMAGE] [DEBUG]")
print("[+] Head + Body Damage Split")
print("[+] "..#weaponCache.." weapon tables loaded")
print("RENXX")
print("═══════════════════════════════")
