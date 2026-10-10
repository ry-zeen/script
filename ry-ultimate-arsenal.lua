-- ══════════════════════════════════════════════════════════
-- RENXX ARSENAL v2.8 — Rayfield Gen 2
-- FULL FIX — By: DEEP & RENXX
-- ══════════════════════════════════════════════════════════

-- ═══════════ SINGLETON GUARD ═══════════
if getgenv().__RENXX_ARSENAL_LOADED == true then
    warn("[RENXX Arsenal] Already running! Unloading old...")
    if getgenv().RenxxArsenal_Unload then
        pcall(getgenv().RenxxArsenal_Unload)
    end
    task.wait(0.3)
end
getgenv().__RENXX_ARSENAL_LOADED = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- ═══════════ SERVICES ═══════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════ HITBOX SCOPE ═══════════
local HitboxOriginal = {}
local HitboxParts = {"Head", "UpperTorso"}

-- ═══════════ STATE ═══════════
local State = {
    ActiveESP = false,
    Tracers = false,
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPBox = false,
    ESPAmmoBox = false,
    TracersPlayerColor = Color3.fromRGB(255, 0, 0),
    ESPNameColor = Color3.fromRGB(255, 255, 255),
    ESPHealthColor = Color3.fromRGB(0, 255, 0),
    ESPDistanceColor = Color3.fromRGB(255, 255, 0),
    ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPAmmoBoxColor = Color3.fromRGB(255, 165, 0),
    Aimbot = false,
    AimPart = "Head",
    AimSmooth = 0.05,
    POVRadius = 100,
    ShowPOV = false,
    POVColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = false,
    WallCheck = false,
    InfAmmoV1 = false,
    InfAmmoV2 = false,
    FastReload = false,
    RapidFire = false,
    NoRecoil = false,
    NoSpread = false,
    SpeedHack = false,
    SpeedValue = 16,
    SpeedMethod = "Velocity",
    JumpHack = false,
    JumpValue = 50,
    Fly = false,
    FlySpeed = 50,
    AntiAim = false,
    SpinSpeed = 10,
    InfJump = false,
    NoClip = false,
    AutoCollect = false,
    CollectObject = "All",
    Hitbox = false,
    HitboxSize = 10,
    HitboxTransparency = 5,
    HitboxTeamCheck = "FFA",
    AutoFarm = false,
    AutoFarmRadius = 50,
    AutoFarmPosition = "Belakang",
    AutoFarmTeamFilter = "TeamBased",
    Triggerbot = false,
    TriggerbotTeamCheck = "FFA",
    TriggerbotDelay = 0.1,
    FPSBoost = false,
    AntiLag = false,
    FullBright = false,
}

-- ═══════════ WINDOW ═══════════
local Window = Rayfield:CreateWindow({
    name = "RENXX Arsenal v2.8",
    subtitle = "By DEEP & RENXX",
    sidebarLayout = true,
    configuration = { autoSave = false, autoLoad = false, fileName = "RENXX_Arsenal_Config" },
})

local function Notify(t, c, d)
    Window:Notify({ title = t, content = c, duration = d or 3 })
end

-- ═══════════ CURSOR FIX ═══════════
local function FixCursor()
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseDeltaSensitivity = 1
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        FixCursor()
    end
end)

-- ══════════════════════════════════════════════════════════
-- ■ TAB 1: VISUAL
-- ══════════════════════════════════════════════════════════
local VisualTab = Window:CreateTab({ name = "Visual" })

VisualTab:CreateSection({ name = "ESP" })

VisualTab:CreateToggle({ name = "Active ESP", currentValue = false, flag = "ActiveESP",
    callback = function(v) State.ActiveESP = v end })

VisualTab:CreateToggle({ name = "ESP Tracers", currentValue = false, flag = "ESPTracers",
    callback = function(v) State.Tracers = v end })

VisualTab:CreateToggle({ name = "ESP Name", currentValue = false, flag = "ESPName",
    callback = function(v) State.ESPName = v end })

VisualTab:CreateToggle({ name = "ESP Health", currentValue = false, flag = "ESPHealth",
    callback = function(v) State.ESPHealth = v end })

VisualTab:CreateToggle({ name = "ESP Distance", currentValue = false, flag = "ESPDistance",
    callback = function(v) State.ESPDistance = v end })

VisualTab:CreateToggle({ name = "ESP Box", currentValue = false, flag = "ESPBox",
    callback = function(v) State.ESPBox = v end })

VisualTab:CreateToggle({ name = "ESP Ammo Box", currentValue = false, flag = "ESPAmmoBox",
    callback = function(v) State.ESPAmmoBox = v end })

VisualTab:CreateSection({ name = "ESP Manager" })

VisualTab:CreateColorPicker({ name = "ESP Tracers Player Color", default = Color3.fromRGB(255, 0, 0), flag = "TracersPlayerColor",
    callback = function(c) State.TracersPlayerColor = c end })

VisualTab:CreateColorPicker({ name = "ESP Name Color", default = Color3.fromRGB(255, 255, 255), flag = "ESPNameColor",
    callback = function(c) State.ESPNameColor = c end })

VisualTab:CreateColorPicker({ name = "ESP Health Color", default = Color3.fromRGB(0, 255, 0), flag = "ESPHealthColor",
    callback = function(c) State.ESPHealthColor = c end })

VisualTab:CreateColorPicker({ name = "ESP Distance Color", default = Color3.fromRGB(255, 255, 0), flag = "ESPDistanceColor",
    callback = function(c) State.ESPDistanceColor = c end })

VisualTab:CreateColorPicker({ name = "ESP Box Color", default = Color3.fromRGB(255, 255, 255), flag = "ESPBoxColor",
    callback = function(c) State.ESPBoxColor = c end })

VisualTab:CreateColorPicker({ name = "ESP Ammo Box Color", default = Color3.fromRGB(255, 165, 0), flag = "ESPAmmoBoxColor",
    callback = function(c) State.ESPAmmoBoxColor = c end })

-- ══════════════════════════════════════════════════════════
-- ■ TAB 2: COMBAT
-- ══════════════════════════════════════════════════════════
local CombatTab = Window:CreateTab({ name = "Combat" })

CombatTab:CreateSection({ name = "Aimbot" })

CombatTab:CreateToggle({ name = "Aimbot (Camera Lock)", currentValue = false, flag = "Aimbot",
    callback = function(v) State.Aimbot = v end })

CombatTab:CreateDropdown({ name = "AIM Part", options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"},
    currentValue = {"Head"}, flag = "AimPart",
    callback = function(o)
        if type(o) == "table" then State.AimPart = o[1] else State.AimPart = o end
    end })

CombatTab:CreateSlider({ name = "AIM Smoothed", range = {0, 20}, increment = 1, suffix = "x",
    currentValue = 5, flag = "AimSmooth",
    callback = function(v) State.AimSmooth = v / 100 end })

CombatTab:CreateSection({ name = "POV" })

CombatTab:CreateSlider({ name = "POV Radius", range = {0, 360}, increment = 5, suffix = "deg",
    currentValue = 100, flag = "POVRadius",
    callback = function(v) State.POVRadius = v end })

CombatTab:CreateToggle({ name = "Show POV", currentValue = false, flag = "ShowPOV",
    callback = function(v) State.ShowPOV = v end })

CombatTab:CreateColorPicker({ name = "POV Color", default = Color3.fromRGB(255, 0, 0), flag = "POVColor",
    callback = function(c) State.POVColor = c end })

CombatTab:CreateSection({ name = "Filter" })

CombatTab:CreateToggle({ name = "Team Check", currentValue = false, flag = "TeamCheck",
    callback = function(v) State.TeamCheck = v end })

CombatTab:CreateToggle({ name = "Wall Check", currentValue = false, flag = "WallCheck",
    callback = function(v) State.WallCheck = v end })

-- ══════════════════════════════════════════════════════════
-- ■ TAB 3: WEAPON
-- ══════════════════════════════════════════════════════════
local WeaponTab = Window:CreateTab({ name = "Weapon" })

WeaponTab:CreateSection({ name = "Ammo" })

WeaponTab:CreateToggle({ name = "Infinite Ammo V1", currentValue = false, flag = "InfAmmoV1",
    callback = function(v)
        State.InfAmmoV1 = v
        local wkspc = ReplicatedStorage:FindFirstChild("wkspc")
        if wkspc and wkspc:FindFirstChild("CurrentCurse") then
            wkspc.CurrentCurse.Value = v and "Infinite Ammo" or ""
        end
    end })

WeaponTab:CreateToggle({ name = "Infinite Ammo V2", currentValue = false, flag = "InfAmmoV2",
    callback = function(v) State.InfAmmoV2 = v end })

WeaponTab:CreateSection({ name = "Gun Mods" })

WeaponTab:CreateToggle({ name = "Fast Reload", currentValue = false, flag = "FastReload",
    callback = function(v)
        State.FastReload = v
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, weapon in ipairs(weapons:GetChildren()) do
            for _, name in ipairs({"ReloadTime", "EReloadTime"}) do
                local val = weapon:FindFirstChild(name)
                if val and val:IsA("NumberValue") then
                    val.Value = v and 0.01 or 0.8
                end
            end
        end
    end })

WeaponTab:CreateToggle({ name = "Rapid Fire", currentValue = false, flag = "RapidFire",
    callback = function(v)
        State.RapidFire = v
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, item in ipairs(weapons:GetDescendants()) do
            if item.Name == "FireRate" or item.Name == "BFireRate" then
                if item:IsA("NumberValue") then
                    item.Value = v and 0.03 or 0.8
                end
            end
        end
    end })

WeaponTab:CreateToggle({ name = "No Recoil", currentValue = false, flag = "NoRecoil",
    callback = function(v)
        State.NoRecoil = v
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, item in ipairs(weapons:GetDescendants()) do
            if item.Name == "RecoilControl" or item.Name == "Recoil" then
                if item:IsA("NumberValue") then
                    item.Value = v and 0 or 1
                end
            end
        end
    end })

WeaponTab:CreateToggle({ name = "No Spread", currentValue = false, flag = "NoSpread",
    callback = function(v)
        State.NoSpread = v
        local weapons = ReplicatedStorage:FindFirstChild("Weapons")
        if not weapons then return end
        for _, item in ipairs(weapons:GetDescendants()) do
            if item.Name == "MaxSpread" or item.Name == "Spread" or item.Name == "SpreadControl" then
                if item:IsA("NumberValue") then
                    item.Value = v and 0 or 1
                end
            end
        end
    end })

-- ══════════════════════════════════════════════════════════
-- ■ TAB 4: PLAYER
-- ══════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab({ name = "Player" })

PlayerTab:CreateSection({ name = "Speed" })

PlayerTab:CreateToggle({ name = "Speed Hack", currentValue = false, flag = "SpeedHack",
    callback = function(v) State.SpeedHack = v end })

PlayerTab:CreateSlider({ name = "Speed Value", range = {0, 100}, increment = 1, suffix = "x",
    currentValue = 16, flag = "SpeedValue",
    callback = function(v) State.SpeedValue = v end })

PlayerTab:CreateDropdown({ name = "Speed Method", options = {"Velocity", "Vector", "CFrame"},
    currentValue = {"Velocity"}, flag = "SpeedMethod",
    callback = function(o)
        if type(o) == "table" then State.SpeedMethod = o[1] else State.SpeedMethod = o end
    end })

PlayerTab:CreateSection({ name = "Jump" })

PlayerTab:CreateToggle({ name = "Jump Hack", currentValue = false, flag = "JumpHack",
    callback = function(v) State.JumpHack = v end })

PlayerTab:CreateSlider({ name = "Jump Value", range = {0, 100}, increment = 1, suffix = "x",
    currentValue = 50, flag = "JumpValue",
    callback = function(v) State.JumpValue = v end })

PlayerTab:CreateSection({ name = "Fly" })

PlayerTab:CreateToggle({ name = "Fly", currentValue = false, flag = "Fly",
    callback = function(v)
        State.Fly = v
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = character.HumanoidRootPart
        local oldBv = hrp:FindFirstChild("RENXXFlyBV")
        local oldBg = hrp:FindFirstChild("RENXXFlyBG")
        if oldBv then oldBv:Destroy() end
        if oldBg then oldBg:Destroy() end
        if v then
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
    end })

PlayerTab:CreateSlider({ name = "Fly Speed", range = {0, 100}, increment = 1, suffix = "x",
    currentValue = 50, flag = "FlySpeed",
    callback = function(v) State.FlySpeed = v end })

PlayerTab:CreateSection({ name = "Anti-Aim" })

PlayerTab:CreateToggle({ name = "Anti-Aim V1", currentValue = false, flag = "AntiAim",
    callback = function(v)
        State.AntiAim = v
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = character.HumanoidRootPart
        local oldSpin = hrp:FindFirstChild("RENXXAntiSpin")
        local oldGyro = hrp:FindFirstChild("RENXXAntiGyro")
        if oldSpin then oldSpin:Destroy() end
        if oldGyro then oldGyro:Destroy() end
        if v then
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
    end })

PlayerTab:CreateSlider({ name = "Spin Speed", range = {1, 50}, increment = 1, suffix = "x",
    currentValue = 10, flag = "SpinSpeed",
    callback = function(v)
        State.SpinSpeed = v
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local spin = character.HumanoidRootPart:FindFirstChild("RENXXAntiSpin")
            if spin then spin.AngularVelocity = Vector3.new(0, v, 0) end
        end
    end })

PlayerTab:CreateSection({ name = "Movement" })

PlayerTab:CreateToggle({ name = "Infinite Jump", currentValue = false, flag = "InfJump",
    callback = function(v) State.InfJump = v end })

PlayerTab:CreateToggle({ name = "No Clip", currentValue = false, flag = "NoClip",
    callback = function(v) State.NoClip = v end })

PlayerTab:CreateSection({ name = "Auto Collect" })

PlayerTab:CreateToggle({ name = "Auto Collect", currentValue = false, flag = "AutoCollect",
    callback = function(v) State.AutoCollect = v end })

PlayerTab:CreateDropdown({ name = "Object", options = {"All", "DeadHP Only", "DeadAmmo Only"},
    currentValue = {"All"}, flag = "CollectObject",
    callback = function(o)
        if type(o) == "table" then State.CollectObject = o[1] else State.CollectObject = o end
    end })

-- ══════════════════════════════════════════════════════════
-- ■ TAB 5: FARM
-- ══════════════════════════════════════════════════════════
local FarmTab = Window:CreateTab({ name = "Farm" })

FarmTab:CreateSection({ name = "Hitbox" })

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

FarmTab:CreateToggle({ name = "Hitbox", currentValue = false, flag = "Hitbox",
    callback = function(v)
        State.Hitbox = v
        if not v then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    pcall(RestoreHitbox, player)
                end
            end
        end
    end })

FarmTab:CreateSlider({ name = "Hitbox Size", range = {0, 15}, increment = 1, suffix = "x",
    currentValue = 10, flag = "HitboxSize",
    callback = function(v) State.HitboxSize = v end })

FarmTab:CreateSlider({ name = "Hitbox Transparency", range = {1, 10}, increment = 1, suffix = "x",
    currentValue = 5, flag = "HitboxTransparency",
    callback = function(v) State.HitboxTransparency = v end })

FarmTab:CreateDropdown({ name = "Team Check (Hitbox)", options = {"FFA", "TeamBased", "Everyone"},
    currentValue = {"FFA"}, flag = "HitboxTeamCheck",
    callback = function(o)
        if type(o) == "table" then State.HitboxTeamCheck = o[1] else State.HitboxTeamCheck = o end
    end })

FarmTab:CreateSection({ name = "Auto Farm" })

FarmTab:CreateToggle({ name = "Auto Farm (Teleport + Auto Shoot)", currentValue = false, flag = "AutoFarm",
    callback = function(v)
        State.AutoFarm = v
        local wkspc = ReplicatedStorage:FindFirstChild("wkspc")
        if wkspc and wkspc:FindFirstChild("TimeScale") then
            wkspc.TimeScale.Value = v and 2 or 1
        end
    end })

FarmTab:CreateSlider({ name = "Auto Farm Radius", range = {5, 200}, increment = 5, suffix = "m",
    currentValue = 50, flag = "AutoFarmRadius",
    callback = function(v) State.AutoFarmRadius = v end })

FarmTab:CreateDropdown({ name = "Auto Farm Position",
    options = {"Belakang", "Depan", "Atas", "Bawah", "Samping Kiri", "Samping Kanan"},
    currentValue = {"Belakang"}, flag = "AutoFarmPosition",
    callback = function(o)
        if type(o) == "table" then State.AutoFarmPosition = o[1] else State.AutoFarmPosition = o end
    end })

FarmTab:CreateSection({ name = "Triggerbot" })

FarmTab:CreateToggle({ name = "Triggerbot (Mouse Target)", currentValue = false, flag = "Triggerbot",
    callback = function(v) State.Triggerbot = v end })

FarmTab:CreateDropdown({ name = "Team Check (Triggerbot)", options = {"FFA", "TeamBased", "Everyone"},
    currentValue = {"FFA"}, flag = "TriggerbotTeamCheck",
    callback = function(o)
        if type(o) == "table" then State.TriggerbotTeamCheck = o[1] else State.TriggerbotTeamCheck = o end
    end })

FarmTab:CreateSlider({ name = "Shot Delay", range = {1, 10}, increment = 1, suffix = " (x0.1s)",
    currentValue = 1, flag = "TriggerbotDelay",
    callback = function(v) State.TriggerbotDelay = v / 10 end })

-- ══════════════════════════════════════════════════════════
-- ■ TAB 6: EXTRA
-- ══════════════════════════════════════════════════════════
local ExtraTab = Window:CreateTab({ name = "Extra" })

ExtraTab:CreateSection({ name = "Visual Stats" })

ExtraTab:CreateToggle({ name = "Change Name", currentValue = false, flag = "ChangeName",
    callback = function(v)
        pcall(function()
            local gui = LocalPlayer.PlayerGui
            if gui.Menew_Main and gui.Menew_Main.Container then
                gui.Menew_Main.Container.PlrName.Text = v and "RENXX" or LocalPlayer.Name
                gui.Menew_Main.Container.PlrName2.Text = v and "RENXX" or LocalPlayer.Name
            end
        end)
    end })

ExtraTab:CreateToggle({ name = "Max Level", currentValue = false, flag = "MaxLevel",
    callback = function(v)
        pcall(function()
            local stats = LocalPlayer.CareerStatsCache
            if v then
                stats.Score.Value = 1e18
                stats.Kills.Value = 1e14
            else
                stats.Score.Value = 0
                stats.Kills.Value = 0
            end
        end)
    end })

ExtraTab:CreateSection({ name = "Tags" })

local function ToggleTag(tagName, value)
    local tag = LocalPlayer:FindFirstChild(tagName)
    if tag then tag:Destroy() end
    if value then
        local newTag = Instance.new("IntValue")
        newTag.Name = tagName
        newTag.Parent = LocalPlayer
    end
end

ExtraTab:CreateToggle({ name = "IsChad", currentValue = false, flag = "IsChad",
    callback = function(v) ToggleTag("IsChad", v) end })

ExtraTab:CreateToggle({ name = "VIP", currentValue = false, flag = "VIP",
    callback = function(v) ToggleTag("VIP", v) end })

ExtraTab:CreateToggle({ name = "OldVIP", currentValue = false, flag = "OldVIP",
    callback = function(v) ToggleTag("OldVIP", v) end })

ExtraTab:CreateToggle({ name = "Romin", currentValue = false, flag = "Romin",
    callback = function(v) ToggleTag("Romin", v) end })

ExtraTab:CreateToggle({ name = "IsAdmin", currentValue = false, flag = "IsAdmin",
    callback = function(v) ToggleTag("IsAdmin", v) end })

-- ══════════════════════════════════════════════════════════
-- ■ TAB 7: SERVER
-- ══════════════════════════════════════════════════════════
local ServerTab = Window:CreateTab({ name = "Server" })

ServerTab:CreateSection({ name = "Performance" })

local FPSOriginal = {
    Materials = {},
    Lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
    },
    Effects = {},
}

ServerTab:CreateToggle({ name = "FPS Boost", currentValue = false, flag = "FPSBoost",
    callback = function(v)
        State.FPSBoost = v
        if v then
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
    end })

local AntiLagOriginal = {}

ServerTab:CreateToggle({ name = "Anti Lag", currentValue = false, flag = "AntiLag",
    callback = function(v)
        State.AntiLag = v
        if v then
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
    end })

ServerTab:CreateToggle({ name = "FullBright", currentValue = false, flag = "FullBright",
    callback = function(v)
        State.FullBright = v
        if v then
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
    end })

ServerTab:CreateSection({ name = "Server" })

ServerTab:CreateButton({ name = "Server Hop",
    callback = function()
        local req = request or http_request or syn.request
        if not req then
            Notify("Gagal", "Executor gak support request")
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
    end })

ServerTab:CreateButton({ name = "Rejoin Server",
    callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end })

-- ══════════════════════════════════════════════════════════
-- DRAWING OBJECTS
-- ══════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════
-- AMMO ESP
-- ══════════════════════════════════════════════════════════
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
    if not State.ESPAmmoBox then ClearAmmoESP(); return end
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
    for _, item in ipairs(DebrisFolder:GetChildren()) do AddAmmoESP(item) end
end)

-- ══════════════════════════════════════════════════════════
-- DEEP TEAM CHECK (4 LAPIS)
-- ══════════════════════════════════════════════════════════
local function IsSameTeam(player)
    if player == LocalPlayer then return true end

    -- Lapis 1: Roblox Team
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return true
    end

    -- Lapis 2: TeamColor
    if player.TeamColor and LocalPlayer.TeamColor and player.TeamColor == LocalPlayer.TeamColor then
        return true
    end

    -- Lapis 3: Attribute TeamID
    local pTeamID = player:GetAttribute("TeamID") or player:GetAttribute("Team") or player:GetAttribute("teamId")
    local myTeamID = LocalPlayer:GetAttribute("TeamID") or LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("teamId")
    if pTeamID and myTeamID and pTeamID == myTeamID then
        return true
    end

    -- Lapis 4: Attribute TeamName
    local pTeamName = player:GetAttribute("TeamName") or player:GetAttribute("teamName")
    local myTeamName = LocalPlayer:GetAttribute("TeamName") or LocalPlayer:GetAttribute("teamName")
    if pTeamName and myTeamName and pTeamName == myTeamName then
        return true
    end

    return false
end

-- ══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ══════════════════════════════════════════════════════════
local function IsEnemy(player)
    if player == LocalPlayer then return false end
    if State.TeamCheck then return not IsSameTeam(player) end
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
    if State.HitboxTeamCheck == "TeamBased" and IsSameTeam(player) then return end
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
    local myCharacter = LocalPlayer.Character
    if not myCharacter or not myCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local myHrp = myCharacter.HumanoidRootPart

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- ✅ DEEP TEAM CHECK — selalu aktif
        if IsSameTeam(player) then continue end

        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp or humanoid.Health <= 0 then continue end

        local distance = (myHrp.Position - hrp.Position).Magnitude

        -- Radius filter
        if distance > State.AutoFarmRadius then continue end

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
        return not IsSameTeam(targetPlayer)
    end
    return false
end

-- ══════════════════════════════════════════════════════════
-- MAIN LOOP
-- ══════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)

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

    if State.JumpHack then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.UseJumpPower = true
            character.Humanoid.JumpPower = State.JumpValue
        end
    end

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

    if State.AutoCollect then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, item in ipairs(debris:GetChildren()) do
                    local match = false
                    if State.CollectObject == "All" then match = true
                    elseif State.CollectObject == "DeadHP Only" and item.Name == "DeadHP" then match = true
                    elseif State.CollectObject == "DeadAmmo Only" and item.Name == "DeadAmmo" then match = true end
                    if match and item:IsA("BasePart") then
                        item.CFrame = hrp.CFrame * CFrame.new(0, 0.2, 0)
                    end
                end
            end
        end
    end

    if State.InfAmmoV2 then
        pcall(function()
            local gui = LocalPlayer.PlayerGui
            if gui.GUI and gui.GUI.Client and gui.GUI.Client.Variables then
                gui.GUI.Client.Variables.ammocount.Value = 99
                gui.GUI.Client.Variables.ammocount2.Value = 99
            end
        end)
    end

    if State.Hitbox then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then ApplyHitbox(player) end
        end
    end

    -- ═══════════ AUTO FARM ═══════════
    if State.AutoFarm then
        local now = tick()
        if now - (getgenv().__RenxxFarmCD or 0) >= 0.12 then
            getgenv().__RenxxFarmCD = now
            local target = GetFarmTarget()
            local character = LocalPlayer.Character
            if target and target.Character and character and character:FindFirstChild("HumanoidRootPart") then
                local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    local offset
                    local pos = State.AutoFarmPosition
                    if pos == "Belakang" then
                        offset = targetHrp.CFrame.LookVector * 3 + Vector3.new(0, 2, 0)
                    elseif pos == "Depan" then
                        offset = -targetHrp.CFrame.LookVector * 3 + Vector3.new(0, 2, 0)
                    elseif pos == "Atas" then
                        offset = Vector3.new(0, 8, 0)
                    elseif pos == "Bawah" then
                        offset = Vector3.new(0, -3, 0)
                    elseif pos == "Samping Kiri" then
                        offset = -targetHrp.CFrame.RightVector * 3 + Vector3.new(0, 2, 0)
                    elseif pos == "Samping Kanan" then
                        offset = targetHrp.CFrame.RightVector * 3 + Vector3.new(0, 2, 0)
                    else
                        offset = targetHrp.CFrame.LookVector * 3 + Vector3.new(0, 2, 0)
                    end

                    local newPos = targetHrp.Position + offset
                    character.HumanoidRootPart.CFrame = CFrame.new(newPos, targetHrp.Position)

                    local head = target.Character:FindFirstChild("Head")
                    if head then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    end

                    pcall(function()
                        VirtualUser:Button1Down(Vector2.new(0, 0))
                    end)
                    task.delay(0.05, function()
                        pcall(function()
                            VirtualUser:Button1Up(Vector2.new(0, 0))
                        end)
                    end)
                end
            end
        end
    end

    if State.Triggerbot then
        local now = tick()
        if now - (getgenv().__RenxxTrigCD or 0) >= State.TriggerbotDelay then
            local mouse = LocalPlayer:GetMouse()
            local target = mouse.Target
            if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
                local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
                if targetPlayer and IsTriggerbotEnemy(targetPlayer) then
                    getgenv().__RenxxTrigCD = now
                    pcall(function()
                        VirtualUser:Button1Down(Vector2.new(0, 0))
                    end)
                    task.delay(State.TriggerbotDelay, function()
                        pcall(function()
                            VirtualUser:Button1Up(Vector2.new(0, 0))
                        end)
                    end)
                end
            end
        end
    end

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

    if State.ShowPOV then
        POVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        POVCircle.Radius = State.POVRadius
        POVCircle.Color = State.POVColor
        POVCircle.Visible = true
    else
        POVCircle.Visible = false
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESPObjects[player] then CreateESP(player) end
        local objects = ESPObjects[player]
        local character = player.Character

        local skip = false
        if not State.ActiveESP then skip = true end
        if not character or not character:FindFirstChild("HumanoidRootPart") then skip = true end
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health <= 0 then skip = true end
        if State.TeamCheck and IsSameTeam(player) then skip = true end

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

        if State.Tracers then
            objects.Tracer.From = screenCenter
            objects.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            objects.Tracer.Color = State.TracersPlayerColor
            objects.Tracer.Visible = true
        else
            objects.Tracer.Visible = false
        end

        if State.ESPName then
            objects.Name.Text = player.Name
            objects.Name.Position = Vector2.new(rootPos.X, boxY - 38)
            objects.Name.Color = State.ESPNameColor
            objects.Name.Visible = true
        else
            objects.Name.Visible = false
        end

        if State.ESPHealth and humanoid then
            objects.Health.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
            objects.Health.Position = Vector2.new(rootPos.X, boxY - 20)
            objects.Health.Color = State.ESPHealthColor
            objects.Health.Visible = true
        else
            objects.Health.Visible = false
        end

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

        if State.ESPBox then
            objects.Box.Size = Vector2.new(boxWidth, boxHeight)
            objects.Box.Position = Vector2.new(boxX, boxY)
            objects.Box.Color = State.ESPBoxColor
            objects.Box.Visible = true
        else
            objects.Box.Visible = false
        end
    end

    if tick() - (getgenv().__RenxxLastAmmoRefresh or 0) > 0.5 then
        getgenv().__RenxxLastAmmoRefresh = tick()
        RefreshAmmoESP()
    end
end)

-- ══════════════════════════════════════════════════════════
-- INFINITE JUMP
-- ══════════════════════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- RESPAWN HANDLER
-- ══════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

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
end)

-- ══════════════════════════════════════════════════════════
-- UNLOAD FUNCTION
-- ══════════════════════════════════════════════════════════
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

    -- Reset anti-aim
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local spin = hrp:FindFirstChild("RENXXAntiSpin")
            local gyro = hrp:FindFirstChild("RENXXAntiGyro")
            if spin then spin:Destroy() end
            if gyro then gyro:Destroy() end
        end
    end)

    -- Restore hitbox
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then RestoreHitbox(player) end
        end
    end)

    -- Fix cursor
    FixCursor()

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

game:BindToClose(function()
    getgenv().__RENXX_ARSENAL_LOADED = nil
    FixCursor()
end)

-- ══════════════════════════════════════════════════════════
-- NOTIF LOAD
-- ══════════════════════════════════════════════════════════
Notify("RENXX Arsenal v2.8", "Loaded! Full Fix — All Bug Fixed", 5)

print("═══════════════════════════════════════")
print(" RENXX ARSENAL v2.8 - FULL FIX LOADED")
print(" By: DEEP & RENXX")
print("═══════════════════════════════════════")
