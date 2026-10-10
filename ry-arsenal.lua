-- ==================================================
-- RENXX ARSENAL v2.2 — Rayfield Gen 2
-- Full Script — Rapi Per Tab
-- By: DEEP & RENXX
-- ==================================================

-- ==================================================
-- SINGLETON GUARD
-- ==================================================
if getgenv().__RENXX_ARSENAL_LOADED == true then
    warn("[RENXX Arsenal] Already running! Unloading old...")
    if getgenv().RenxxArsenal_Unload then
        pcall(getgenv().RenxxArsenal_Unload)
    end
    task.wait(0.3)
end
getgenv().__RENXX_ARSENAL_LOADED = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- ==================================================
-- SERVICES
-- ==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==================================================
-- STATE
-- ==================================================
local State = {
    -- Visual
    ActiveESP = false,
    Tracers = false,
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPBox = false,
    ESPAmmoBox = false,

    -- ESP Colors
    TracersPlayerColor = Color3.fromRGB(255, 0, 0),
    TracersBotColor = Color3.fromRGB(255, 255, 0),
    ESPNameColor = Color3.fromRGB(255, 255, 255),
    ESPHealthColor = Color3.fromRGB(0, 255, 0),
    ESPDistanceColor = Color3.fromRGB(255, 255, 0),
    ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPAmmoBoxColor = Color3.fromRGB(255, 165, 0),

    -- Combat
    Aimbot = false,
    AimPart = "Head",
    AimSmooth = 0.05,
    POVRadius = 100,
    ShowPOV = false,
    POVColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = false,
    WallCheck = false,

    -- Weapon
    InfAmmoV1 = false,
    InfAmmoV2 = false,
    FastReload = false,
    RapidFire = false,
    NoRecoil = false,
    NoSpread = false,

    -- Player
    SpeedHack = false,
    SpeedValue = 16,
    SpeedMethod = "Velocity",
    JumpHack = false,
    JumpValue = 50,
    JumpMethod = "Velocity",
    Fly = false,
    FlySpeed = 50,
    AntiAim = false,
    SpinSpeed = 10,
    InfJump = false,
    NoClip = false,
    AutoCollect = false,
    CollectObject = "All",

    -- Farm
    Hitbox = false,
    HitboxSize = 10,
    HitboxTransparency = 5,
    HitboxTeamCheck = "FFA",
    AutoFarm = false,
    Triggerbot = false,
    TriggerbotTeamCheck = "FFA",
    TriggerbotDelay = 0.1,

    -- Server
    FPSBoost = false,
    AntiLag = false,
    FullBright = false,
}

-- ==================================================
-- WINDOW
-- ==================================================
local Window = Rayfield:CreateWindow({
    Name = "RENXX Arsenal v2.2",
    LoadingTitle = "Loading RENXX...",
    LoadingSubtitle = "by DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================================================
-- ==================================================
-- TAB 1: VISUAL
-- ==================================================
-- ==================================================
local VisualTab = Window:CreateTab("Visual", 4483362458)

-- ===== ESP TOGGLES =====
VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "Active ESP",
    CurrentValue = false,
    Flag = "ActiveESP",
    Callback = function(Value)
        State.ActiveESP = Value
    end,
})

VisualTab:CreateToggle({
    Name = "ESP Tracers",
    CurrentValue = false,
    Flag = "ESPTracers",
    Callback = function(Value)
        State.Tracers = Value
    end,
})

VisualTab:CreateToggle({
    Name = "ESP Name",
    CurrentValue = false,
    Flag = "ESPName",
    Callback = function(Value)
        State.ESPName = Value
    end,
})

VisualTab:CreateToggle({
    Name = "ESP Health",
    CurrentValue = false,
    Flag = "ESPHealth",
    Callback = function(Value)
        State.ESPHealth = Value
    end,
})

VisualTab:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = false,
    Flag = "ESPDistance",
    Callback = function(Value)
        State.ESPDistance = Value
    end,
})

VisualTab:CreateToggle({
    Name = "ESP Box",
    CurrentValue = false,
    Flag = "ESPBox",
    Callback = function(Value)
        State.ESPBox = Value
    end,
})

VisualTab:CreateToggle({
    Name = "ESP Ammo Box",
    CurrentValue = false,
    Flag = "ESPAmmoBox",
    Callback = function(Value)
        State.ESPAmmoBox = Value
    end,
})

-- ===== ESP MANAGER =====
VisualTab:CreateSection("ESP Manager")

VisualTab:CreateColorPicker({
    Name = "ESP Tracers Player Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "TracersPlayerColor",
    Callback = function(Color)
        State.TracersPlayerColor = Color
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Tracers BOT Color",
    Color = Color3.fromRGB(255, 255, 0),
    Flag = "TracersBotColor",
    Callback = function(Color)
        State.TracersBotColor = Color
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Name Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPNameColor",
    Callback = function(Color)
        State.ESPNameColor = Color
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Health Color",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "ESPHealthColor",
    Callback = function(Color)
        State.ESPHealthColor = Color
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Distance Color",
    Color = Color3.fromRGB(255, 255, 0),
    Flag = "ESPDistanceColor",
    Callback = function(Color)
        State.ESPDistanceColor = Color
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Box Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPBoxColor",
    Callback = function(Color)
        State.ESPBoxColor = Color
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Ammo Box Color",
    Color = Color3.fromRGB(255, 165, 0),
    Flag = "ESPAmmoBoxColor",
    Callback = function(Color)
        State.ESPAmmoBoxColor = Color
    end,
})

-- ==================================================
-- ==================================================
-- TAB 2: COMBAT
-- ==================================================
-- ==================================================
local CombatTab = Window:CreateTab("Combat", 4483362458)

-- ===== AIMBOT =====
CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot (Camera Lock)",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(Value)
        State.Aimbot = Value
    end,
})

CombatTab:CreateDropdown({
    Name = "AIM Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"},
    CurrentOption = {"Head"},
    Flag = "AimPart",
    Callback = function(Option)
        State.AimPart = Option[1]
    end,
})

CombatTab:CreateSlider({
    Name = "AIM Smoothed",
    Range = {0, 20},
    Increment = 1,
    Suffix = "×",
    CurrentValue = 5,
    Flag = "AimSmooth",
    Callback = function(Value)
        State.AimSmooth = Value / 100
    end,
})

-- ===== POV =====
CombatTab:CreateSection("POV")

CombatTab:CreateSlider({
    Name = "POV Radius",
    Range = {0, 360},
    Increment = 5,
    Suffix = "°",
    CurrentValue = 100,
    Flag = "POVRadius",
    Callback = function(Value)
        State.POVRadius = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Show POV",
    CurrentValue = false,
    Flag = "ShowPOV",
    Callback = function(Value)
        State.ShowPOV = Value
    end,
})

CombatTab:CreateColorPicker({
    Name = "POV Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "POVColor",
    Callback = function(Color)
        State.POVColor = Color
    end,
})

-- ===== FILTER =====
CombatTab:CreateSection("Filter")

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(Value)
        State.TeamCheck = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheck",
    Callback = function(Value)
        State.WallCheck = Value
    end,
})

-- ==================================================
-- ==================================================
-- TAB 3: WEAPON
-- ==================================================
-- ==================================================
local WeaponTab = Window:CreateTab("Weapon", 4483362458)

-- ===== AMMO =====
WeaponTab:CreateSection("Ammo")

WeaponTab:CreateToggle({
    Name = "Infinite Ammo V1",
    CurrentValue = false,
    Flag = "InfAmmoV1",
    Callback = function(Value)
        State.InfAmmoV1 = Value
        local wkspc = ReplicatedStorage:FindFirstChild("wkspc")
        if wkspc and wkspc:FindFirstChild("CurrentCurse") then
            wkspc.CurrentCurse.Value = Value and "Infinite Ammo" or ""
        end
    end,
})

WeaponTab:CreateToggle({
    Name = "Infinite Ammo V2",
    CurrentValue = false,
    Flag = "InfAmmoV2",
    Callback = function(Value)
        State.InfAmmoV2 = Value
    end,
})

-- ===== GUN MODS =====
WeaponTab:CreateSection("Gun Mods")

WeaponTab:CreateToggle({
    Name = "Fast Reload",
    CurrentValue = false,
    Flag = "FastReload",
    Callback = function(Value)
        State.FastReload = Value
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, weapon in ipairs(weapons:GetChildren()) do
            for _, name in ipairs({"ReloadTime", "EReloadTime"}) do
                local val = weapon:FindFirstChild(name)
                if val and val:IsA("NumberValue") then
                    val.Value = Value and 0.01 or 0.8
                end
            end
        end
    end,
})

WeaponTab:CreateToggle({
    Name = "Rapid Fire",
    CurrentValue = false,
    Flag = "RapidFire",
    Callback = function(Value)
        State.RapidFire = Value
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, item in ipairs(weapons:GetDescendants()) do
            if item.Name == "FireRate" or item.Name == "BFireRate" then
                if item:IsA("NumberValue") then
                    item.Value = Value and 0.03 or 0.8
                end
            end
        end
    end,
})

WeaponTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Flag = "NoRecoil",
    Callback = function(Value)
        State.NoRecoil = Value
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, item in ipairs(weapons:GetDescendants()) do
            if item.Name == "RecoilControl" or item.Name == "Recoil" then
                if item:IsA("NumberValue") then
                    item.Value = Value and 0 or 1
                end
            end
        end
    end,
})

WeaponTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
    Flag = "NoSpread",
    Callback = function(Value)
        State.NoSpread = Value
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, item in ipairs(weapons:GetDescendants()) do
            if item.Name == "MaxSpread" or item.Name == "Spread" or item.Name == "SpreadControl" then
                if item:IsA("NumberValue") then
                    item.Value = Value and 0 or 1
                end
            end
        end
    end,
})

-- ==================================================
-- ==================================================
-- TAB 4: PLAYER
-- ==================================================
-- ==================================================
local PlayerTab = Window:CreateTab("Player", 4483362458)

-- ===== SPEED =====
PlayerTab:CreateSection("Speed")

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(Value)
        State.SpeedHack = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "Speed Value",
    Range = {0, 100},
    Increment = 1,
    Suffix = "×",
    CurrentValue = 16,
    Flag = "SpeedValue",
    Callback = function(Value)
        State.SpeedValue = Value
    end,
})

PlayerTab:CreateDropdown({
    Name = "Speed Method",
    Options = {"Velocity", "Vector", "CFrame"},
    CurrentOption = {"Velocity"},
    Flag = "SpeedMethod",
    Callback = function(Option)
        State.SpeedMethod = Option[1]
    end,
})

-- ===== JUMP =====
PlayerTab:CreateSection("Jump")

PlayerTab:CreateToggle({
    Name = "Jump Hack",
    CurrentValue = false,
    Flag = "JumpHack",
    Callback = function(Value)
        State.JumpHack = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Value",
    Range = {0, 100},
    Increment = 1,
    Suffix = "×",
    CurrentValue = 50,
    Flag = "JumpValue",
    Callback = function(Value)
        State.JumpValue = Value
    end,
})

PlayerTab:CreateDropdown({
    Name = "Jump Method",
    Options = {"Velocity", "Vector", "CFrame"},
    CurrentOption = {"Velocity"},
    Flag = "JumpMethod",
    Callback = function(Option)
        State.JumpMethod = Option[1]
    end,
})

-- ===== FLY =====
PlayerTab:CreateSection("Fly")

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(Value)
        State.Fly = Value
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = character.HumanoidRootPart
        local oldBv = hrp:FindFirstChild("RENXXFlyBV")
        local oldBg = hrp:FindFirstChild("RENXXFlyBG")
        if oldBv then oldBv:Destroy() end
        if oldBg then oldBg:Destroy() end
        if Value then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RENXXFlyBV"
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
            local bg = Instance.new("BodyGyro")
            bg.Name = "RENXXFlyBG"
            bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bg.P = 1000
            bg.Parent = hrp
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {0, 100},
    Increment = 1,
    Suffix = "×",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        State.FlySpeed = Value
    end,
})

-- ===== ANTI-AIM =====
PlayerTab:CreateSection("Anti-Aim")

PlayerTab:CreateToggle({
    Name = "Anti-Aim V1",
    CurrentValue = false,
    Flag = "AntiAim",
    Callback = function(Value)
        State.AntiAim = Value
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = character.HumanoidRootPart
        local oldSpin = hrp:FindFirstChild("RENXXAntiSpin")
        local oldGyro = hrp:FindFirstChild("RENXXAntiGyro")
        if oldSpin then oldSpin:Destroy() end
        if oldGyro then oldGyro:Destroy() end
        if Value then
            local spin = Instance.new("BodyAngularVelocity")
            spin.Name = "RENXXAntiSpin"
            spin.AngularVelocity = Vector3.new(0, State.SpinSpeed, 0)
            spin.MaxTorque = Vector3.new(0, math.huge, 0)
            spin.P = 500000
            spin.Parent = hrp
            local gyro = Instance.new("BodyGyro")
            gyro.Name = "RENXXAntiGyro"
            gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            gyro.CFrame = hrp.CFrame
            gyro.P = 3000
            gyro.Parent = hrp
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Spin Speed",
    Range = {0, 1000},
    Increment = 10,
    Suffix = "×",
    CurrentValue = 10,
    Flag = "SpinSpeed",
    Callback = function(Value)
        State.SpinSpeed = Value
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local spin = character.HumanoidRootPart:FindFirstChild("RENXXAntiSpin")
            if spin then
                spin.AngularVelocity = Vector3.new(0, Value, 0)
            end
        end
    end,
})

-- ===== MOVEMENT =====
PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        State.InfJump = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(Value)
        State.NoClip = Value
    end,
})

-- ===== AUTO COLLECT =====
PlayerTab:CreateSection("Auto Collect")

PlayerTab:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(Value)
        State.AutoCollect = Value
    end,
})

PlayerTab:CreateDropdown({
    Name = "Object",
    Options = {"All", "DeadHP Only", "DeadAmmo Only"},
    CurrentOption = {"All"},
    Flag = "CollectObject",
    Callback = function(Option)
        State.CollectObject = Option[1]
    end,
})

-- ==================================================
-- ==================================================
-- TAB 5: FARM
-- ==================================================
-- ==================================================
local FarmTab = Window:CreateTab("Farm", 4483362458)

-- ===== HITBOX =====
FarmTab:CreateSection("Hitbox")

local HitboxOriginal = {}
local HitboxParts = {"Head", "UpperTorso"}

local function RestoreHitbox(player)
    if not player.Character then return end
    for _, partName in ipairs(HitboxParts) do
        local part = player.Character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local key = tostring(player.UserId) .. "_" .. partName
            if HitboxOriginal[key] then
                part.Size = HitboxOriginal[key].Size
                part.CanCollide = HitboxOriginal[key].CanCollide
                part.Transparency = HitboxOriginal[key].Transparency
                HitboxOriginal[key] = nil
            end
        end
    end
end

FarmTab:CreateToggle({
    Name = "Hitbox",
    CurrentValue = false,
    Flag = "Hitbox",
    Callback = function(Value)
        State.Hitbox = Value
        if not Value then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    pcall(RestoreHitbox, player)
                end
            end
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {0, 15},
    Increment = 1,
    Suffix = "×",
    CurrentValue = 10,
    Flag = "HitboxSize",
    Callback = function(Value)
        State.HitboxSize = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {1, 10},
    Increment = 1,
    Suffix = "×",
    CurrentValue = 5,
    Flag = "HitboxTransparency",
    Callback = function(Value)
        State.HitboxTransparency = Value
    end,
})

FarmTab:CreateDropdown({
    Name = "Team Check (Hitbox)",
    Options = {"FFA", "TeamBased", "Everyone"},
    CurrentOption = {"FFA"},
    Flag = "HitboxTeamCheck",
    Callback = function(Option)
        State.HitboxTeamCheck = Option[1]
    end,
})

-- ===== AUTO FARM =====
FarmTab:CreateSection("Auto Farm")

FarmTab:CreateToggle({
    Name = "Auto Farm (Teleport + Auto Shoot)",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        State.AutoFarm = Value
        local wkspc = ReplicatedStorage:FindFirstChild("wkspc")
        if wkspc and wkspc:FindFirstChild("TimeScale") then
            wkspc.TimeScale.Value = Value and 12 or 1
        end
    end,
})

-- ===== TRIGGERBOT =====
FarmTab:CreateSection("Triggerbot")

FarmTab:CreateToggle({
    Name = "Triggerbot (Mouse Target)",
    CurrentValue = false,
    Flag = "Triggerbot",
    Callback = function(Value)
        State.Triggerbot = Value
    end,
})

FarmTab:CreateDropdown({
    Name = "Team Check (Triggerbot)",
    Options = {"FFA", "TeamBased", "Everyone"},
    CurrentOption = {"FFA"},
    Flag = "TriggerbotTeamCheck",
    Callback = function(Option)
        State.TriggerbotTeamCheck = Option[1]
    end,
})

FarmTab:CreateSlider({
    Name = "Shot Delay",
    Range = {1, 10},
    Increment = 1,
    Suffix = " (x0.1s)",
    CurrentValue = 1,
    Flag = "TriggerbotDelay",
    Callback = function(Value)
        State.TriggerbotDelay = Value / 10
    end,
})

-- ==================================================
-- ==================================================
-- TAB 6: EXTRA
-- ==================================================
-- ==================================================
local ExtraTab = Window:CreateTab("Extra", 4483362458)

-- ===== VISUAL STATS =====
ExtraTab:CreateSection("Visual Stats")

ExtraTab:CreateToggle({
    Name = "Change Name",
    CurrentValue = false,
    Flag = "ChangeName",
    Callback = function(Value)
        pcall(function()
            local gui = LocalPlayer.PlayerGui
            if gui.Menew_Main and gui.Menew_Main.Container then
                gui.Menew_Main.Container.PlrName.Text = Value and "RENXX" or LocalPlayer.Name
                gui.Menew_Main.Container.PlrName2.Text = Value and "RENXX" or LocalPlayer.Name
            end
        end)
    end,
})

ExtraTab:CreateToggle({
    Name = "Max Level",
    CurrentValue = false,
    Flag = "MaxLevel",
    Callback = function(Value)
        pcall(function()
            local stats = LocalPlayer.CareerStatsCache
            if Value then
                stats.Score.Value = 1e18
                stats.Kills.Value = 1e14
            else
                stats.Score.Value = 0
                stats.Kills.Value = 0
            end
        end)
    end,
})

-- ===== TAGS =====
ExtraTab:CreateSection("Tags")

local function ToggleTag(tagName, value)
    local tag = LocalPlayer:FindFirstChild(tagName)
    if tag then tag:Destroy() end
    if value then
        local newTag = Instance.new("IntValue")
        newTag.Name = tagName
        newTag.Parent = LocalPlayer
    end
end

ExtraTab:CreateToggle({
    Name = "IsChad",
    CurrentValue = false,
    Flag = "IsChad",
    Callback = function(Value)
        ToggleTag("IsChad", Value)
    end,
})

ExtraTab:CreateToggle({
    Name = "VIP",
    CurrentValue = false,
    Flag = "VIP",
    Callback = function(Value)
        ToggleTag("VIP", Value)
    end,
})

ExtraTab:CreateToggle({
    Name = "OldVIP",
    CurrentValue = false,
    Flag = "OldVIP",
    Callback = function(Value)
        ToggleTag("OldVIP", Value)
    end,
})

ExtraTab:CreateToggle({
    Name = "Romin",
    CurrentValue = false,
    Flag = "Romin",
    Callback = function(Value)
        ToggleTag("Romin", Value)
    end,
})

ExtraTab:CreateToggle({
    Name = "IsAdmin",
    CurrentValue = false,
    Flag = "IsAdmin",
    Callback = function(Value)
        ToggleTag("IsAdmin", Value)
    end,
})

-- ==================================================
-- ==================================================
-- TAB 7: SERVER
-- ==================================================
-- ==================================================
local ServerTab = Window:CreateTab("Server", 4483362458)

-- ===== PERFORMANCE =====
ServerTab:CreateSection("Performance")

local FPSOriginal = {
    Materials = {},
    Lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
    },
    Effects = {},
}

ServerTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(Value)
        State.FPSBoost = Value
        if Value then
            FPSOriginal.Lighting.GlobalShadows = Lighting.GlobalShadows
            FPSOriginal.Lighting.FogEnd = Lighting.FogEnd
            FPSOriginal.Lighting.Brightness = Lighting.Brightness
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            Lighting.Brightness = 1

            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
                    FPSOriginal.Effects[effect] = effect.Enabled
                    effect.Enabled = false
                end
            end

            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    FPSOriginal.Materials[part] = part.Material
                    part.Material = Enum.Material.SmoothPlastic
                end
            end

            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        else
            for part, mat in pairs(FPSOriginal.Materials) do
                if part and part.Parent then part.Material = mat end
            end
            FPSOriginal.Materials = {}

            Lighting.GlobalShadows = FPSOriginal.Lighting.GlobalShadows
            Lighting.FogEnd = FPSOriginal.Lighting.FogEnd
            Lighting.Brightness = FPSOriginal.Lighting.Brightness

            for effect, enabled in pairs(FPSOriginal.Effects) do
                if effect and effect.Parent then effect.Enabled = enabled end
            end
            FPSOriginal.Effects = {}

            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            end)
        end
    end,
})

local AntiLagOriginal = {}

ServerTab:CreateToggle({
    Name = "Anti Lag",
    CurrentValue = false,
    Flag = "AntiLag",
    Callback = function(Value)
        State.AntiLag = Value
        if Value then
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part.Parent:FindFirstChild("Humanoid") then
                    if not AntiLagOriginal[part] then
                        AntiLagOriginal[part] = part.Material
                    end
                    part.Material = Enum.Material.SmoothPlastic
                end
            end
        else
            for part, mat in pairs(AntiLagOriginal) do
                if part and part.Parent then part.Material = mat end
            end
            AntiLagOriginal = {}
        end
    end,
})

ServerTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(Value)
        State.FullBright = Value
        if Value then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = 100000
            Lighting.Brightness = 3
        else
            Lighting.Ambient = Color3.fromRGB(70, 70, 70)
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.FogEnd = 100000
            Lighting.Brightness = 1
        end
    end,
})

-- ===== SERVER =====
ServerTab:CreateSection("Server")

ServerTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local req = request or http_request or syn.request
        if not req then
            Rayfield:Notify({
                Title = "Gagal",
                Content = "Executor gak support request",
                Duration = 3,
            })
            return
        end
        local success, response = pcall(function()
            return req({
                Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                Method = "GET",
            }).Body
        end)
        if success and response then
            local data = HttpService:JSONDecode(response)
            for _, server in pairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    break
                end
            end
        end
    end,
})

ServerTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

-- ==================================================
-- ==================================================
-- DRAWING OBJECTS
-- ==================================================
-- ==================================================

local POVCircle = Drawing.new("Circle")
POVCircle.Visible = false
POVCircle.Thickness = 1
POVCircle.NumSides = 60
POVCircle.Filled = false
POVCircle.Transparency = 1

local ESPObjects = {}

local function CreateESP(player)
    if ESPObjects[player] then return end
    ESPObjects[player] = {
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Box = Drawing.new("Square"),
    }
    for _, obj in pairs(ESPObjects[player]) do
        obj.Visible = false
        obj.Transparency = 1
        if obj.Thickness then obj.Thickness = 1 end
    end
    ESPObjects[player].Name.Size = 14
    ESPObjects[player].Name.Center = true
    ESPObjects[player].Name.Outline = true
    ESPObjects[player].Health.Size = 14
    ESPObjects[player].Health.Center = true
    ESPObjects[player].Health.Outline = true
    ESPObjects[player].Distance.Size = 14
    ESPObjects[player].Distance.Center = true
    ESPObjects[player].Distance.Outline = true
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then CreateESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- ==================================================
-- AMMO ESP (EVENT-BASED)
-- ==================================================
local AmmoESP = {}

local function ClearAmmoESP()
    for obj, gui in pairs(AmmoESP) do
        pcall(function() gui:Destroy() end)
        AmmoESP[obj] = nil
    end
end

local function AddAmmoESP(item)
    if not State.ESPAmmoBox then return end
    if AmmoESP[item] then return end
    if not item:IsA("BasePart") then return end
    if item.Name ~= "DeadAmmo" and item.Name ~= "DeadHP" then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RENXX_AmmoESP"
    billboard.Adornee = item
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 80, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = item

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = item.Name == "DeadAmmo" and "AMMO" or "HP"
    label.TextColor3 = State.ESPAmmoBoxColor
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard

    AmmoESP[item] = billboard
end

local function RefreshAmmoESP()
    if not State.ESPAmmoBox then
        ClearAmmoESP()
        return
    end
    for obj, gui in pairs(AmmoESP) do
        if not obj or not obj.Parent then
            pcall(function() gui:Destroy() end)
            AmmoESP[obj] = nil
        else
            local label = gui:FindFirstChildOfClass("TextLabel")
            if label then label.TextColor3 = State.ESPAmmoBoxColor end
        end
    end
end

task.spawn(function()
    local DebrisFolder = Workspace:WaitForChild("Debris", 15)
    if not DebrisFolder then return end
    DebrisFolder.ChildAdded:Connect(AddAmmoESP)
    DebrisFolder.ChildRemoved:Connect(function(child)
        if AmmoESP[child] then
            pcall(function() AmmoESP[child]:Destroy() end)
            AmmoESP[child] = nil
        end
    end)
    for _, item in ipairs(DebrisFolder:GetChildren()) do
        AddAmmoESP(item)
    end
end)

-- ==================================================
-- HELPER FUNCTIONS
-- ==================================================
local function IsEnemy(player)
    if player == LocalPlayer then return false end
    if State.TeamCheck then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function GetTarget()
    local closest, shortest = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if not IsEnemy(player) then continue end
        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        local part = character:FindFirstChild(State.AimPart)
        if not part then continue end
        if State.WallCheck then
            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500)
            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
            if hit and not hit:IsDescendantOf(character) then continue end
        end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if distance < shortest then
            shortest = distance
            closest = player
        end
    end
    return closest
end

local function ApplyHitbox(player)
    if not State.Hitbox then return end
    if not player.Character then return end
    if player == LocalPlayer then return end
    if State.HitboxTeamCheck == "TeamBased" and player.Team == LocalPlayer.Team then return end
    for _, partName in ipairs(HitboxParts) do
        local part = player.Character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local key = tostring(player.UserId) .. "_" .. partName
            if not HitboxOriginal[key] then
                HitboxOriginal[key] = {
                    Size = part.Size,
                    CanCollide = part.CanCollide,
                    Transparency = part.Transparency,
                }
            end
            part.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
            part.CanCollide = false
            part.Transparency = State.HitboxTransparency / 10
        end
    end
end

local function GetFarmTarget()
    local closest, shortest = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if State.TriggerbotTeamCheck == "TeamBased" and player.Team == LocalPlayer.Team then continue end
        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp or humanoid.Health <= 0 then continue end
        local myCharacter = LocalPlayer.Character
        if not myCharacter or not myCharacter:FindFirstChild("HumanoidRootPart") then continue end
        local distance = (myCharacter.HumanoidRootPart.Position - hrp.Position).Magnitude
        if distance < shortest then
            shortest = distance
            closest = player
        end
    end
    return closest
end

local function IsTriggerbotEnemy(targetPlayer)
    if targetPlayer == LocalPlayer then return false end
    if State.TriggerbotTeamCheck == "FFA" then return true end
    if State.TriggerbotTeamCheck == "Everyone" then return targetPlayer ~= LocalPlayer end
    if State.TriggerbotTeamCheck == "TeamBased" then
        return targetPlayer.Team ~= LocalPlayer.Team
    end
    return false
end

-- ==================================================
-- MAIN LOOP
-- ==================================================
RunService.RenderStepped:Connect(function(dt)

    -- ===== SPEED HACK =====
    if State.SpeedHack then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp and humanoid.MoveDirection.Magnitude > 0 then
                if State.SpeedMethod == "Velocity" then
                    local v = humanoid.MoveDirection * State.SpeedValue
                    hrp.Velocity = Vector3.new(v.X, hrp.Velocity.Y, v.Z)
                elseif State.SpeedMethod == "Vector" then
                    hrp.CFrame = hrp.CFrame + humanoid.MoveDirection * (State.SpeedValue * dt * 2)
                elseif State.SpeedMethod == "CFrame" then
                    hrp.CFrame = hrp.CFrame + humanoid.MoveDirection * (State.SpeedValue * dt * 5)
                end
            end
        end
    end

    -- ===== JUMP HACK =====
    if State.JumpHack then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.UseJumpPower = true
            character.Humanoid.JumpPower = State.JumpValue
        end
    end

    -- ===== FLY =====
    if State.Fly then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local bv = character.HumanoidRootPart:FindFirstChild("RENXXFlyBV")
            local bg = character.HumanoidRootPart:FindFirstChild("RENXXFlyBG")
            if bv and bg then
                local move = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                bv.Velocity = move * State.FlySpeed
                bg.CFrame = Camera.CFrame
            end
        end
    end

    -- ===== NO CLIP =====
    if State.NoClip then
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    -- ===== AUTO COLLECT =====
    if State.AutoCollect then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, item in ipairs(debris:GetChildren()) do
                    local match = false
                    if State.CollectObject == "All" then
                        match = true
                    elseif State.CollectObject == "DeadHP Only" and item.Name == "DeadHP" then
                        match = true
                    elseif State.CollectObject == "DeadAmmo Only" and item.Name == "DeadAmmo" then
                        match = true
                    end
                    if match and item:IsA("BasePart") then
                        item.CFrame = hrp.CFrame * CFrame.new(0, 0.2, 0)
                    end
                end
            end
        end
    end

    -- ===== INFINITE AMMO V2 =====
    if State.InfAmmoV2 then
        pcall(function()
            local gui = LocalPlayer.PlayerGui
            if gui.GUI and gui.GUI.Client and gui.GUI.Client.Variables then
                gui.GUI.Client.Variables.ammocount.Value = 99
                gui.GUI.Client.Variables.ammocount2.Value = 99
            end
        end)
    end

    -- ===== HITBOX =====
    if State.Hitbox then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ApplyHitbox(player)
            end
        end
    end

    -- ===== AUTO FARM =====
    if State.AutoFarm then
        local target = GetFarmTarget()
        local character = LocalPlayer.Character
        if target and target.Character and character and character:FindFirstChild("HumanoidRootPart") then
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHrp then
                local behind = targetHrp.Position + targetHrp.CFrame.LookVector * 3 + Vector3.new(0, 2, 0)
                character.HumanoidRootPart.CFrame = CFrame.new(behind, targetHrp.Position)
                local head = target.Character:FindFirstChild("Head")
                if head then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                end
                pcall(function() mouse1press() end)
                task.wait(0.1)
                pcall(function() mouse1release() end)
            end
        end
    end

    -- ===== TRIGGERBOT =====
    if State.Triggerbot then
        local now = tick()
        if now - (getgenv().__RenxxTrigCD or 0) >= State.TriggerbotDelay then
            local mouse = LocalPlayer:GetMouse()
            local target = mouse.Target
            if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
                local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
                if targetPlayer and IsTriggerbotEnemy(targetPlayer) then
                    getgenv().__RenxxTrigCD = now
                    pcall(function() mouse1press() end)
                    task.delay(State.TriggerbotDelay, function()
                        pcall(function() mouse1release() end)
                    end)
                end
            end
        end
    end

    -- ===== AIMBOT =====
    if State.Aimbot then
        local target = GetTarget()
        if target and target.Character then
            local part = target.Character:FindFirstChild(State.AimPart)
            if part then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - State.AimSmooth)
            end
        end
    end

    -- ===== POV CIRCLE =====
    if State.ShowPOV then
        POVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        POVCircle.Radius = State.POVRadius
        POVCircle.Color = State.POVColor
        POVCircle.Visible = true
    else
        POVCircle.Visible = false
    end

    -- ===== ESP LOOP =====
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESPObjects[player] then CreateESP(player) end
        local objects = ESPObjects[player]
        local character = player.Character

        local skip = false
        if not State.ActiveESP then skip = true end
        if not character or not character:FindFirstChild("HumanoidRootPart") then skip = true end
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health <= 0 then skip = true end
        if State.TeamCheck and player.Team == LocalPlayer.Team then skip = true end

        if skip then
            for _, obj in pairs(objects) do obj.Visible = false end
            continue
        end

        local hrp = character.HumanoidRootPart
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
        local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

        if not onScreen then
            for _, obj in pairs(objects) do obj.Visible = false end
            continue
        end

        local boxHeight = math.abs(headPos.Y - feetPos.Y)
        local boxWidth = boxHeight * 0.6
        local boxY = headPos.Y
        local boxX = rootPos.X - boxWidth / 2
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

        -- Tracer
        if State.Tracers then
            objects.Tracer.From = screenCenter
            objects.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            objects.Tracer.Color = State.TracersPlayerColor
            objects.Tracer.Visible = true
        else
            objects.Tracer.Visible = false
        end

        -- Name
        if State.ESPName then
            objects.Name.Text = player.Name
            objects.Name.Position = Vector2.new(rootPos.X, boxY - 38)
            objects.Name.Color = State.ESPNameColor
            objects.Name.Visible = true
        else
            objects.Name.Visible = false
        end

        -- Health
        if State.ESPHealth and humanoid then
            objects.Health.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
            objects.Health.Position = Vector2.new(rootPos.X, boxY - 20)
            objects.Health.Color = State.ESPHealthColor
            objects.Health.Visible = true
        else
            objects.Health.Visible = false
        end

        -- Distance
        if State.ESPDistance then
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local distance = math.floor((myChar.HumanoidRootPart.Position - hrp.Position).Magnitude)
                objects.Distance.Text = "[" .. distance .. "m]"
                objects.Distance.Position = Vector2.new(rootPos.X, boxY + boxHeight + 5)
                objects.Distance.Color = State.ESPDistanceColor
                objects.Distance.Visible = true
            else
                objects.Distance.Visible = false
            end
        else
            objects.Distance.Visible = false
        end

        -- Box
        if State.ESPBox then
            objects.Box.Size = Vector2.new(boxWidth, boxHeight)
            objects.Box.Position = Vector2.new(boxX, boxY)
            objects.Box.Color = State.ESPBoxColor
            objects.Box.Visible = true
        else
            objects.Box.Visible = false
        end
    end

    -- ===== REFRESH AMMO ESP =====
    if tick() - (getgenv().__RenxxLastAmmoRefresh or 0) > 0.5 then
        getgenv().__RenxxLastAmmoRefresh = tick()
        RefreshAmmoESP()
    end
end)

-- ==================================================
-- INFINITE JUMP
-- ==================================================
UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ==================================================
-- RESPAWN HANDLER
-- ==================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

    -- Fly re-apply
    if State.Fly then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local oldBv = hrp:FindFirstChild("RENXXFlyBV")
            local oldBg = hrp:FindFirstChild("RENXXFlyBG")
            if oldBv then oldBv:Destroy() end
            if oldBg then oldBg:Destroy() end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RENXXFlyBV"
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
            local bg = Instance.new("BodyGyro")
            bg.Name = "RENXXFlyBG"
            bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bg.P = 1000
            bg.Parent = hrp
        end
    end

    -- Anti-Aim re-apply
    if State.AntiAim then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local oldSpin = hrp:FindFirstChild("RENXXAntiSpin")
            local oldGyro = hrp:FindFirstChild("RENXXAntiGyro")
            if oldSpin then oldSpin:Destroy() end
            if oldGyro then oldGyro:Destroy() end
            local spin = Instance.new("BodyAngularVelocity")
            spin.Name = "RENXXAntiSpin"
            spin.AngularVelocity = Vector3.new(0, State.SpinSpeed, 0)
            spin.MaxTorque = Vector3.new(0, math.huge, 0)
            spin.P = 500000
            spin.Parent = hrp
            local gyro = Instance.new("BodyGyro")
            gyro.Name = "RENXXAntiGyro"
            gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            gyro.CFrame = hrp.CFrame
            gyro.P = 3000
            gyro.Parent = hrp
        end
    end
end)

-- ==================================================
-- UNLOAD FUNCTION
-- ==================================================
getgenv().RenxxArsenal_Unload = function()
    for player, objs in pairs(ESPObjects) do
        for _, obj in pairs(objs) do
            pcall(function() obj:Remove() end)
        end
    end
    ESPObjects = {}

    for obj, gui in pairs(AmmoESP) do
        pcall(function() gui:Destroy() end)
    end
    AmmoESP = {}

    pcall(function() POVCircle:Remove() end)

    getgenv().__RENXX_ARSENAL_LOADED = nil

    pcall(function()
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui.Name:find("Rayfield") or gui.Name:find("RENXX") then
                gui:Destroy()
            end
        end
    end)

    print("[RENXX Arsenal] Unloaded.")
end

-- ==================================================
-- CLEANUP
-- ==================================================
game:BindToClose(function()
    getgenv().__RENXX_ARSENAL_LOADED = nil
end)

-- ==================================================
-- NOTIFICATION
-- ==================================================
Rayfield:Notify({
    Title = "RENXX Arsenal v2.2 Loaded!",
    Content = "7 Tab | Full Script | By DEEP & RENXX",
    Duration = 5,
})

-- ==================================================
-- PRINT
-- ==================================================
print("========================================")
print("RENXX ARSENAL v2.2 — FULL SCRIPT")
print("Status: LOADED")
print("Tabs:")
print("  [1] Visual")
print("  [2] Combat")
print("  [3] Weapon")
print("  [4] Player")
print("  [5] Farm")
print("  [6] Extra")
print("  [7] Server")
print("Unload: getgenv().RenxxArsenal_Unload()")
print("By: DEEP & RENXX")
print("========================================")
