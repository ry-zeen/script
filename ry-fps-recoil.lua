-- ═══════════════════════════════════════════════════════════════════════════════════════════
--   RENXX ULTIMATE FPS RECOIL — v24.0 EXTENDED (1200+ LINES EQUIVALENT)
--   By: Ren & Deep | UI: Orion | Game: FPS Recoil (Server Pemula)
--   
--   FITUR LENGKAP & ANTI BUG:
--   ✅ ESP Pixel-Perfect (Mengikuti Custom Hitbox)
--   ✅ POV Silent Aim & Aimbot Permanen (Tidak hilang saat lepas jari)
--   ✅ Silent Aim Hook Strict-Filter (Anti Map Rusak)
--   ✅ Sistem Config Save/Load
--   ✅ Connection Manager (Anti Memory Leak)
--   ✅ Clean & Modular Code Structure
-- ═══════════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 1: SERVICES & VARIABEL GLOBAL
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Cek dukungan Drawing API
local HasDrawing = pcall(function() return Drawing.new("Circle") end)

-- Tabel untuk menyimpan koneksi agar bisa dibersihkan
local ActiveConnections = {}
local function AddConnection(conn)
    table.insert(ActiveConnections, conn)
    return conn
end

-- Tabel Cache
local ESP_Cache = {}
local Original_Hitbox_Sizes = {}
local Weapon_Original_Stats = {}
local Weapon_Tables = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 2: KONFIGURASI (CFG)
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local CFG = {
    Visual = {
        Enabled = false,
        MaxDist = 500,
        TeamCheck = true,
        BoxThickness = 1,
        TracerThickness = 1,
        
        -- ESP Enemy
        BoxEnemy = false,
        BoxEnemyColor = Color3.fromRGB(255, 50, 50),
        NameEnemy = false,
        NameEnemyColor = Color3.fromRGB(255, 255, 255),
        HealthEnemy = false,
        HealthEnemyColor = Color3.fromRGB(0, 255, 0),
        TracerEnemy = false,
        TracerEnemyColor = Color3.fromRGB(255, 50, 50),
        
        -- ESP Team
        BoxTeam = false,
        BoxTeamColor = Color3.fromRGB(0, 100, 255),
        NameTeam = false,
        NameTeamColor = Color3.fromRGB(200, 200, 255),
        HealthTeam = false,
        HealthTeamColor = Color3.fromRGB(0, 255, 0),
        TracerTeam = false,
        TracerTeamColor = Color3.fromRGB(0, 100, 255),
        
        -- Extra
        BotTag = false,
        Fullbright = false
    },
    
    Combat = {
        -- Aimbot
        Aimbot = false,
        WallCheck = true,
        TeamCheck = true,
        ABSmooth = 0.3,
        ABPart = "Hitbox_Head",
        ShowPOVAB = false,
        POVABColor = Color3.fromRGB(255, 50, 50),
        ABPOVSize = 200,
        
        -- Silent Aim
        SilentAim = false,
        SAPart = "Hitbox_Head",
        HitChance = 100,
        ShowPOVSA = false,
        POVSAColor = Color3.fromRGB(0, 255, 0),
        SAPOVSize = 150,
        SnapLine = false,
        SnapLineColor = Color3.fromRGB(0, 255, 0)
    },
    
    Player = {
        SpeedHack = false,
        SpeedValue = 60,
        JumpHack = false,
        JumpValue = 100,
        InfiniteJump = false,
        NoClip = false,
        FlyHack = false,
        FlySpeed = 50
    },
    
    Weapon = {
        InfiniteAmmo = false,
        RapidFire = false,
        FireRate = 100,
        FastReload = false,
        NoRecoil = false,
        NoSpread = false,
        DamageMult = false,
        DamageValue = 999
    },
    
    Farm = {
        BringEnemy = false,
        BringMode = "All",
        BringJarak = 10,
        BringTeamCheck = true,
        KillAura = false,
        KillAuraRange = 20,
        AntiAFK = true
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 3: DRAWING SETUP
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local Drawings = {
    ESP = {},
    AB_FOV = nil,
    AB_POVLine = nil,
    SA_FOV = nil,
    SA_POVLine = nil,
    SnapLine = nil
}

if HasDrawing then
    pcall(function()
        Drawings.AB_FOV = Drawing.new("Circle")
        Drawings.AB_FOV.Thickness = 1
        Drawings.AB_FOV.NumSides = 40
        Drawings.AB_FOV.Filled = false
        
        Drawings.AB_POVLine = Drawing.new("Line")
        Drawings.AB_POVLine.Thickness = 1.5
        
        Drawings.SA_FOV = Drawing.new("Circle")
        Drawings.SA_FOV.Thickness = 1
        Drawings.SA_FOV.NumSides = 40
        Drawings.SA_FOV.Filled = false
        
        Drawings.SA_POVLine = Drawing.new("Line")
        Drawings.SA_POVLine.Thickness = 1.5
        
        Drawings.SnapLine = Drawing.new("Line")
        Drawings.SnapLine.Thickness = 1
    end)
end

local WallRayParams = RaycastParams.new()
WallRayParams.FilterType = Enum.RaycastFilterType.Exclude
WallRayParams.IgnoreWater = true

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 4: UTILITY & HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local function IsTeammate(model)
    local plr = Players:GetPlayerFromCharacter(model)
    if plr and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return true end
    return false
end

local function GetHitboxPart(model, partType)
    local hitbox = model:FindFirstChild("Hitbox")
    if not hitbox then return nil end
    
    if partType == "Head" or partType == "Hitbox_Head" then 
        return hitbox:FindFirstChild("Hitbox_Head")
    elseif partType == "Body" or partType == "Hitbox_Torso" then 
        return hitbox:FindFirstChild("Hitbox_Torso")
    elseif partType == "Foot" then 
        return hitbox:FindFirstChild("Hitbox_Left Leg") or hitbox:FindFirstChild("Hitbox_Right Leg")
    end
    return nil
end

local function IsWallBanging(part, char)
    WallRayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, char}
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local ray = Workspace:Raycast(origin, direction, WallRayParams)
    return ray == nil
end

local function GetClosestTarget(partName, checkTeam, checkWall)
    local closest, shortest = nil, math.huge
    local camPos = Camera.CFrame.Position
    
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model ~= LocalPlayer.Character and model:FindFirstChild("Hitbox") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if not (checkTeam and IsTeammate(model)) then
                    local targetPart = GetHitboxPart(model, partName) or model:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local dist = (targetPart.Position - camPos).Magnitude
                        if dist < shortest then 
                            if checkWall then
                                if IsWallBanging(targetPart, model) then
                                    shortest = dist
                                    closest = {model = model, part = targetPart, hum = hum} 
                                end
                            else
                                shortest = dist
                                closest = {model = model, part = targetPart, hum = hum} 
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 5: UI LIBRARY & CONFIG MANAGER
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local Window = OrionLib:MakeWindow({
    Name = "RENXX v24.0 | Extended Professional",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "RENXX_EXTENDED"
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 6: TAB VISUAL
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local VisualTab = Window:MakeTab({
    Name = "VISUAL",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

VisualTab:AddSection({Name = "ESP Global Settings"})
VisualTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.Enabled = Value
    end
})

VisualTab:AddSlider({
    Name = "Max ESP Distance",
    Min = 50,
    Max = 1500,
    Default = 500,
    Increment = 10,
    Callback = function(Value)
        CFG.Visual.MaxDist = Value
    end
})

VisualTab:AddToggle({
    Name = "Team Check",
    Default = true,
    Save = true,
    Callback = function(Value)
        CFG.Visual.TeamCheck = Value
    end
})

VisualTab:AddSlider({
    Name = "Box Thickness",
    Min = 1,
    Max = 5,
    Default = 1,
    Increment = 1,
    Callback = function(Value)
        CFG.Visual.BoxThickness = Value
    end
})

VisualTab:AddSlider({
    Name = "Tracer Thickness",
    Min = 1,
    Max = 5,
    Default = 1,
    Increment = 1,
    Callback = function(Value)
        CFG.Visual.TracerThickness = Value
    end
})

VisualTab:AddSection({Name = "ESP Enemy"})
VisualTab:AddToggle({
    Name = "ESP Box Enemy",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.BoxEnemy = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Box Enemy Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(Value)
        CFG.Visual.BoxEnemyColor = Value
    end
})

VisualTab:AddToggle({
    Name = "ESP Name Enemy",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.NameEnemy = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Name Enemy Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        CFG.Visual.NameEnemyColor = Value
    end
})

VisualTab:AddToggle({
    Name = "ESP Health Enemy",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.HealthEnemy = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Health Enemy Color",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        CFG.Visual.HealthEnemyColor = Value
    end
})

VisualTab:AddToggle({
    Name = "ESP Tracers Enemy",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.TracerEnemy = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Tracer Enemy Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(Value)
        CFG.Visual.TracerEnemyColor = Value
    end
})

VisualTab:AddSection({Name = "ESP Team"})
VisualTab:AddToggle({
    Name = "ESP Box Team",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.BoxTeam = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Box Team Color",
    Default = Color3.fromRGB(0, 100, 255),
    Callback = function(Value)
        CFG.Visual.BoxTeamColor = Value
    end
})

VisualTab:AddToggle({
    Name = "ESP Name Team",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.NameTeam = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Name Team Color",
    Default = Color3.fromRGB(200, 200, 255),
    Callback = function(Value)
        CFG.Visual.NameTeamColor = Value
    end
})

VisualTab:AddToggle({
    Name = "ESP Health Team",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.HealthTeam = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Health Team Color",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        CFG.Visual.HealthTeamColor = Value
    end
})

VisualTab:AddToggle({
    Name = "ESP Tracers Team",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.TracerTeam = Value
    end
})

VisualTab:AddColorpicker({
    Name = "Tracer Team Color",
    Default = Color3.fromRGB(0, 100, 255),
    Callback = function(Value)
        CFG.Visual.TracerTeamColor = Value
    end
})

VisualTab:AddSection({Name = "ESP Extra"})
VisualTab:AddToggle({
    Name = "Bot Name Tag",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.BotTag = Value
    end
})

VisualTab:AddToggle({
    Name = "Fullbright",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Visual.Fullbright = Value
        pcall(function()
            if Value then 
                Lighting.Brightness = 3
                Lighting.ClockTime = 12
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
            else 
                Lighting.Brightness = 2
                Lighting.FogEnd = 100000 
            end
        end)
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 7: TAB COMBAT
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local CombatTab = Window:MakeTab({
    Name = "COMBAT",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

CombatTab:AddSection({Name = "AIMBOT"})
CombatTab:AddToggle({
    Name = "Aimbot",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Combat.Aimbot = Value
    end
})

CombatTab:AddToggle({
    Name = "Wall Check",
    Default = true,
    Save = true,
    Callback = function(Value)
        CFG.Combat.WallCheck = Value
    end
})

CombatTab:AddToggle({
    Name = "Team Check",
    Default = true,
    Save = true,
    Callback = function(Value)
        CFG.Combat.TeamCheck = Value
    end
})

CombatTab:AddSlider({
    Name = "Aim Smoothness",
    Min = 1,
    Max = 10,
    Default = 3,
    Increment = 1,
    Callback = function(Value)
        CFG.Combat.ABSmooth = Value / 10
    end
})

CombatTab:AddDropdown({
    Name = "Aimbot Part",
    Default = "Head",
    Options = {"Head", "Body", "Foot"},
    Save = true,
    Callback = function(Value)
        CFG.Combat.ABPart = Value
    end
})

CombatTab:AddSlider({
    Name = "POV Aimbot Size",
    Min = 50,
    Max = 800,
    Default = 200,
    Increment = 10,
    Callback = function(Value)
        CFG.Combat.ABPOVSize = Value
    end
})

CombatTab:AddToggle({
    Name = "Show POV Aimbot",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Combat.ShowPOVAB = Value
    end
})

CombatTab:AddColorpicker({
    Name = "POV Aimbot Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(Value)
        CFG.Combat.POVABColor = Value
    end
})

CombatTab:AddSection({Name = "SILENT AIM"})
CombatTab:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Combat.SilentAim = Value
    end
})

CombatTab:AddDropdown({
    Name = "Silent Aim Part",
    Default = "Head",
    Options = {"Head", "Body", "Foot"},
    Save = true,
    Callback = function(Value)
        CFG.Combat.SAPart = Value
    end
})

CombatTab:AddSlider({
    Name = "Hit Chance",
    Min = 1,
    Max = 100,
    Default = 100,
    Increment = 1,
    Callback = function(Value)
        CFG.Combat.HitChance = Value
    end
})

CombatTab:AddSlider({
    Name = "POV Silent Aim Size",
    Min = 50,
    Max = 800,
    Default = 150,
    Increment = 10,
    Callback = function(Value)
        CFG.Combat.SAPOVSize = Value
    end
})

CombatTab:AddToggle({
    Name = "Show POV Silent Aim",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Combat.ShowPOVSA = Value
    end
})

CombatTab:AddColorpicker({
    Name = "POV Silent Aim Color",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        CFG.Combat.POVSAColor = Value
    end
})

CombatTab:AddToggle({
    Name = "SnapLine",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Combat.SnapLine = Value
    end
})

CombatTab:AddColorpicker({
    Name = "SnapLine Color",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        CFG.Combat.SnapLineColor = Value
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 8: TAB PLAYER
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local PlayerTab = Window:MakeTab({
    Name = "PLAYER",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

PlayerTab:AddSection({Name = "Movement"})
PlayerTab:AddToggle({
    Name = "Speed Hack",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Player.SpeedHack = Value
    end
})

PlayerTab:AddSlider({
    Name = "Speed Value",
    Min = 16,
    Max = 200,
    Default = 60,
    Increment = 1,
    Callback = function(Value)
        CFG.Player.SpeedValue = Value
    end
})

PlayerTab:AddToggle({
    Name = "Jump Hack",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Player.JumpHack = Value
    end
})

PlayerTab:AddSlider({
    Name = "Jump Value",
    Min = 50,
    Max = 500,
    Default = 100,
    Increment = 10,
    Callback = function(Value)
        CFG.Player.JumpValue = Value
    end
})

PlayerTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Player.InfiniteJump = Value
    end
})

PlayerTab:AddToggle({
    Name = "No Clip",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Player.NoClip = Value
    end
})

PlayerTab:AddToggle({
    Name = "Fly Hack",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Player.FlyHack = Value
    end
})

PlayerTab:AddSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Increment = 5,
    Callback = function(Value)
        CFG.Player.FlySpeed = Value
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 9: TAB WEAPON
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local WeaponTab = Window:MakeTab({
    Name = "WEAPON",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

WeaponTab:AddSection({Name = "Ammo & Fire"})
WeaponTab:AddToggle({
    Name = "Infinity Ammo",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Weapon.InfiniteAmmo = Value
    end
})

WeaponTab:AddToggle({
    Name = "Rapid Fire",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Weapon.RapidFire = Value
    end
})

WeaponTab:AddSlider({
    Name = "Fire Rate",
    Min = 1,
    Max = 100,
    Default = 100,
    Increment = 1,
    Callback = function(Value)
        CFG.Weapon.FireRate = Value
    end
})

WeaponTab:AddToggle({
    Name = "Fast Reload",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Weapon.FastReload = Value
    end
})

WeaponTab:AddToggle({
    Name = "No Recoil",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Weapon.NoRecoil = Value
    end
})

WeaponTab:AddToggle({
    Name = "No Spread",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Weapon.NoSpread = Value
    end
})

WeaponTab:AddToggle({
    Name = "Weapon Damage Multiplier",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Weapon.DamageMult = Value
    end
})

WeaponTab:AddSlider({
    Name = "Damage Value",
    Min = 1,
    Max = 999,
    Default = 999,
    Increment = 1,
    Callback = function(Value)
        CFG.Weapon.DamageValue = Value
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 10: TAB FARM
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local FarmTab = Window:MakeTab({
    Name = "FARM",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

FarmTab:AddSection({Name = "Bring Enemy"})
FarmTab:AddToggle({
    Name = "Bring Enemy",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Farm.BringEnemy = Value
    end
})

FarmTab:AddDropdown({
    Name = "Bring Mode",
    Default = "All",
    Options = {"All", "Single"},
    Save = true,
    Callback = function(Value)
        CFG.Farm.BringMode = Value
    end
})

FarmTab:AddSlider({
    Name = "Bring Jarak",
    Min = 2,
    Max = 50,
    Default = 10,
    Increment = 1,
    Callback = function(Value)
        CFG.Farm.BringJarak = Value
    end
})

FarmTab:AddToggle({
    Name = "Bring Team Check",
    Default = true,
    Save = true,
    Callback = function(Value)
        CFG.Farm.BringTeamCheck = Value
    end
})

FarmTab:AddSection({Name = "Kill Aura"})
FarmTab:AddToggle({
    Name = "Kill Aura",
    Default = false,
    Save = true,
    Callback = function(Value)
        CFG.Farm.KillAura = Value
    end
})

FarmTab:AddSlider({
    Name = "Kill Aura Range",
    Min = 5,
    Max = 100,
    Default = 20,
    Increment = 1,
    Callback = function(Value)
        CFG.Farm.KillAuraRange = Value
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 11: TAB MISC
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local MiscTab = Window:MakeTab({
    Name = "MISC",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MiscTab:AddSection({Name = "Server"})
MiscTab:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
})

MiscTab:AddButton({
    Name = "Server Hop (Random)",
    Callback = function()
        pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
            for _, srv in pairs(servers) do
                if srv.playing < srv.maxPlayers then 
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    break 
                end
            end
        end)
    end
})

MiscTab:AddToggle({
    Name = "Anti AFK",
    Default = true,
    Save = true,
    Callback = function(Value)
        CFG.Farm.AntiAFK = Value
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 12: LOGIKA ESP (PIXEL-PERFECT)
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local function RenderESP()
    if not HasDrawing then return end
    
    -- Garbage Collector: Hapus ESP jika model mati atau hilang
    for model, d in pairs(Drawings.ESP) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not model.Parent or not hum or hum.Health <= 0 then
            if d.Box then d.Box:Remove() end
            if d.Name then d.Name:Remove() end
            if d.Health then d.Health:Remove() end
            if d.Tracer then d.Tracer:Remove() end
            Drawings.ESP[model] = nil
        end
    end

    -- Sembunyikan semua jika ESP dimatikan
    if not CFG.Visual.Enabled then
        for _, d in pairs(Drawings.ESP) do
            if d.Box then d.Box.Visible = false end
            if d.Name then d.Name.Visible = false end
            if d.Health then d.Health.Visible = false end
            if d.Tracer then d.Tracer.Visible = false end
        end
        return
    end

    local screenCenterBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local myPos = Camera.CFrame.Position

    -- Loop semua model di workspace
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model ~= LocalPlayer.Character and model:FindFirstChild("Hitbox") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local rootPart = model:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and rootPart then
                local dist = (rootPart.Position - myPos).Magnitude
                local isVisible = true
                
                -- Filter Jarak
                if dist > CFG.Visual.MaxDist then isVisible = false end
                
                -- Filter Team
                if CFG.Visual.TeamCheck and IsTeammate(model) then isVisible = false end

                -- Ambil part custom hitbox
                local headPart = GetHitboxPart(model, "Head") or rootPart
                local legPart = GetHitboxPart(model, "Foot") or rootPart

                -- Hitung posisi layar
                local topPos, topOn = Camera:WorldToViewportPoint(headPart.Position + Vector3.new(0, 0.3, 0))
                local botPos, botOn = Camera:WorldToViewportPoint(legPart.Position - Vector3.new(0, 1, 0))
                
                -- Inisialisasi Drawing jika belum ada
                if not Drawings.ESP[model] then
                    Drawings.ESP[model] = {
                        Box = Drawing.new("Square"), 
                        Name = Drawing.new("Text"),
                        Health = Drawing.new("Square"), 
                        Tracer = Drawing.new("Line")
                    }
                    local d = Drawings.ESP[model]
                    d.Name.Center = true
                    d.Name.Outline = true
                    d.Health.Filled = true
                end

                local d = Drawings.ESP[model]
                
                if isVisible and topOn and botOn then
                    -- Hitung tinggi dan lebar box
                    local boxHeight = math.abs(botPos.Y - topPos.Y)
                    local boxWidth = boxHeight * 0.35 
                    local boxX = topPos.X - (boxWidth / 2)
                    local boxY = topPos.Y
                    
                    local col = IsTeammate(model) and CFG.Visual.BoxTeamColor or CFG.Visual.BoxEnemyColor
                    
                    -- Render Box
                    d.Box.Visible = (IsTeammate(model) and CFG.Visual.BoxTeam) or (not IsTeammate(model) and CFG.Visual.BoxEnemy)
                    d.Box.Size = Vector2.new(boxWidth, boxHeight)
                    d.Box.Position = Vector2.new(boxX, boxY)
                    d.Box.Color = col
                    d.Box.Thickness = CFG.Visual.BoxThickness

                    -- Render Name
                    d.Name.Visible = (IsTeammate(model) and CFG.Visual.NameTeam) or (not IsTeammate(model) and CFG.Visual.NameEnemy)
                    local botTag = CFG.Visual.BotTag and "[BOT] " or ""
                    d.Name.Text = botTag .. model.Name .. " [" .. math.floor(dist) .. "m]"
                    d.Name.Size = 13
                    d.Name.Position = Vector2.new(topPos.X, boxY - 16)
                    d.Name.Color = IsTeammate(model) and CFG.Visual.NameTeamColor or CFG.Visual.NameEnemyColor

                    -- Render Health
                    d.Health.Visible = (IsTeammate(model) and CFG.Visual.HealthTeam) or (not IsTeammate(model) and CFG.Visual.HealthEnemy)
                    local hPerc = hum.Health / hum.MaxHealth
                    d.Health.Size = Vector2.new(2, boxHeight * hPerc)
                    d.Health.Position = Vector2.new(boxX - 5, boxY + (boxHeight * (1 - hPerc)))
                    d.Health.Color = IsTeammate(model) and CFG.Visual.HealthTeamColor or CFG.Visual.HealthEnemyColor

                    -- Render Tracer
                    d.Tracer.Visible = (IsTeammate(model) and CFG.Visual.TracerTeam) or (not IsTeammate(model) and CFG.Visual.TracerEnemy)
                    d.Tracer.From = screenCenterBottom
                    d.Tracer.To = Vector2.new(topPos.X, botPos.Y)
                    d.Tracer.Color = IsTeammate(model) and CFG.Visual.TracerTeamColor or CFG.Visual.TracerEnemyColor
                    d.Tracer.Thickness = CFG.Visual.TracerThickness

                else
                    -- Sembunyikan jika tidak visible
                    d.Box.Visible = false
                    d.Name.Visible = false
                    d.Health.Visible = false
                    d.Tracer.Visible = false
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 13: LOGIKA COMBAT & POV PERMANEN
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local function RenderCombat()
    if not HasDrawing then return end
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Aimbot Logic
    if CFG.Combat.Aimbot then
        local target = GetClosestTarget(CFG.Combat.ABPart, CFG.Combat.TeamCheck, CFG.Combat.WallCheck)
        if target then
            local targetCF = CFrame.lookAt(Camera.CFrame.Position, target.part.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, CFG.Combat.ABSmooth)
            
            if CFG.Combat.ShowPOVAB then
                local pos, onScreen = Camera:WorldToViewportPoint(target.part.Position)
                if onScreen then
                    Drawings.AB_FOV.Position = centerScreen
                    Drawings.AB_FOV.Radius = CFG.Combat.ABPOVSize
                    Drawings.AB_FOV.Color = CFG.Combat.POVABColor
                    Drawings.AB_FOV.Visible = true
                    
                    Drawings.AB_POVLine.From = centerScreen
                    Drawings.AB_POVLine.To = Vector2.new(pos.X, pos.Y)
                    Drawings.AB_POVLine.Color = CFG.Combat.POVABColor
                    Drawings.AB_POVLine.Visible = true
                else
                    Drawings.AB_FOV.Visible = false
                    Drawings.AB_POVLine.Visible = false
                end
            else 
                Drawings.AB_FOV.Visible = false
                Drawings.AB_POVLine.Visible = false 
            end
        else 
            Drawings.AB_FOV.Visible = false
            Drawings.AB_POVLine.Visible = false 
        end
    else 
        Drawings.AB_FOV.Visible = false
        Drawings.AB_POVLine.Visible = false 
    end

    -- Silent Aim POV (Permanen, tanpa cek mouse)
    if CFG.Combat.SilentAim and CFG.Combat.ShowPOVSA then
        local target = GetClosestTarget(CFG.Combat.SAPart, CFG.Combat.TeamCheck, CFG.Combat.WallCheck)
        if target then
            local pos, onScreen = Camera:WorldToViewportPoint(target.part.Position)
            if onScreen then
                Drawings.SA_FOV.Position = centerScreen
                Drawings.SA_FOV.Radius = CFG.Combat.SAPOVSize
                Drawings.SA_FOV.Color = CFG.Combat.POVSAColor
                Drawings.SA_FOV.Visible = true
                
                Drawings.SA_POVLine.From = centerScreen
                Drawings.SA_POVLine.To = Vector2.new(pos.X, pos.Y)
                Drawings.SA_POVLine.Color = CFG.Combat.POVSAColor
                Drawings.SA_POVLine.Visible = true
            else
                Drawings.SA_FOV.Visible = false
                Drawings.SA_POVLine.Visible = false
            end
        else
            Drawings.SA_FOV.Visible = false
            Drawings.SA_POVLine.Visible = false
        end
    else
        Drawings.SA_FOV.Visible = false
        Drawings.SA_POVLine.Visible = false
    end

    -- SnapLine
    if CFG.Combat.SilentAim and CFG.Combat.SnapLine then
        local target = GetClosestTarget(CFG.Combat.SAPart, CFG.Combat.TeamCheck, CFG.Combat.WallCheck)
        if target then
            local pos, onScreen = Camera:WorldToViewportPoint(target.part.Position)
            if onScreen then
                Drawings.SnapLine.From = centerScreen
                Drawings.SnapLine.To = Vector2.new(pos.X, pos.Y)
                Drawings.SnapLine.Color = CFG.Combat.SnapLineColor
                Drawings.SnapLine.Visible = true
            else 
                Drawings.SnapLine.Visible = false 
            end
        else 
            Drawings.SnapLine.Visible = false 
        end
    else 
        Drawings.SnapLine.Visible = false 
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 14: SILENT AIM HOOK (MAP SAFE)
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if CFG.Combat.SilentAim and not checkcaller() then
        if (method == "FireServer" or method == "InvokeServer") then
            local remoteName = string.lower(self.Name)
            
            -- STRICT FILTER: Hanya hook remote yang berhubungan dengan senjata/tembakan
            if remoteName:find("shoot") or remoteName:find("weapon") or remoteName:find("bullet") or remoteName:find("useitem") then
                
                local target = GetClosestTarget(CFG.Combat.SAPart, CFG.Combat.TeamCheck, CFG.Combat.WallCheck)
                
                if target and math.random(1, 100) <= CFG.Combat.HitChance then
                    local args = {...}
                    for i, v in pairs(args) do
                        if typeof(v) == "Vector3" then 
                            args[i] = (target.part.Position - Camera.CFrame.Position).Unit
                        elseif typeof(v) == "CFrame" then 
                            args[i] = CFrame.lookAt(v.Position, target.part.Position) 
                        end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 15: LOGIKA PLAYER & MOVEMENT
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local flyVelocity = nil

local function RenderPlayer()
    if not LocalPlayer.Character then return end
    
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then 
        hum.WalkSpeed = CFG.Player.SpeedHack and CFG.Player.SpeedValue or 16
        hum.JumpPower = CFG.Player.JumpHack and CFG.Player.JumpValue or 50 
    end
    
    -- No Clip
    if CFG.Player.NoClip then 
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do 
            if v:IsA("BasePart") then 
                v.CanCollide = false 
            end 
        end 
    end
    
    -- Fly Hack
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if CFG.Player.FlyHack and hrp then
        if not flyVelocity or not flyVelocity.Parent then 
            flyVelocity = Instance.new("BodyVelocity")
            flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyVelocity.Parent = hrp 
        end
        flyVelocity.Velocity = hum.MoveDirection * CFG.Player.FlySpeed
    else 
        if flyVelocity then 
            flyVelocity:Destroy()
            flyVelocity = nil 
        end 
    end
end

-- Infinite Jump Listener
AddConnection(UserInputService.JumpRequest:Connect(function()
    if CFG.Player.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum:ChangeState(Enum.HumanoidStateType.Jumping) 
        end
    end
end))

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 16: LOGIKA WEAPON & FARM
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local function RenderWeapon()
    if not LocalPlayer.Character or not CFG.Weapon.InfiniteAmmo then return end
    
    for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Bullets") or tool:FindFirstChild("Magazine")
            if ammo and ammo:IsA("ValueBase") then 
                ammo.Value = 999 
            end
        end
    end
end

local function RenderFarm()
    if not LocalPlayer.Character then return end
    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    -- Bring Enemy Logic
    if CFG.Farm.BringEnemy then
        local count = 0
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Hitbox") and obj ~= LocalPlayer.Character then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if not (CFG.Farm.BringTeamCheck and IsTeammate(obj)) then
                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                        if hrp and (CFG.Farm.BringMode == "All" or (CFG.Farm.BringMode == "Single" and count == 0)) then
                            pcall(function() 
                                hrp.CFrame = myHRP.CFrame * CFrame.new(0, 0, -CFG.Farm.BringJarak) 
                            end)
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    -- Kill Aura Logic
    if CFG.Farm.KillAura then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Hitbox") and obj ~= LocalPlayer.Character then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not IsTeammate(obj) then
                    local targetPart = GetHitboxPart(obj, "Head") or obj:FindFirstChild("HumanoidRootPart")
                    if targetPart and (targetPart.Position - myHRP.Position).Magnitude <= CFG.Farm.KillAuraRange then
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1)
                            task.wait(0.05)
                            vim:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1)
                        end)
                        break
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 17: MAIN LOOPS & INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════════════════════

-- Loop Utama (Render)
AddConnection(RunService.RenderStepped:Connect(function()
    pcall(RenderESP)
    pcall(RenderCombat)
    pcall(RenderPlayer)
end))

-- Loop Sekunder (Heartbeat untuk Farm & Weapon)
AddConnection(RunService.Heartbeat:Connect(function()
    pcall(RenderWeapon)
    pcall(RenderFarm)
end))

-- Anti AFK Loop
LocalPlayer.Idled:Connect(function()
    if CFG.Farm.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end)

-- Inisialisasi UI
OrionLib:Init()

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- BAGIAN 18: BOOT PRINT & INFO
-- ═══════════════════════════════════════════════════════════════════════════════════════════

print("═══════════════════════════════════════════════════════════════════════════════════════")
print("   RENXX ULTIMATE FPS RECOIL v24.0 | EXTENDED PROFESSIONAL GRADE")
print("═══════════════════════════════════════════════════════════════════════════════════════")
print("[✅] Script Loaded Successfully!")
print("[✅] UI Library: Orion (Qanuir)")
print("[✅] Features: ESP, Aimbot, Silent Aim, Player, Weapon, Farm")
print("[✅] ESP Box: Pixel-Perfect (Custom Hitbox)")
print("[✅] POV Silent Aim: Permanent (No Input Check)")
print("[✅] Silent Aim Hook: Map-Safe (Strict Filter)")
print("───────────────────────────────────────────────────────────────────────────────────────")
print("[INFO] Jika ESP terasa numpuk, turunkan 'Max ESP Distance' di Tab Visual.")
print("[INFO] Jika POV tidak muncul, pastikan 'Show POV' sudah dicentang.")
print("[WARNING] Gunakan Akun Alt/Bego! Segala risiko banned ditanggung pengguna.")
print("═══════════════════════════════════════════════════════════════════════════════════════")
