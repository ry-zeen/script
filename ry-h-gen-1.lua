-- ═══════════════════════════════════════════════════════════════
--   RY ULTIMATE HYPERshot — FINAL SCRIPT v4 (GEN 1 + AQUA)
--   By: ry-zeen | UI: Rayfield Gen 1 | Theme: Aqua
--   Game: Hypershot (PlaceId: 100040622766961)
-- ═══════════════════════════════════════════════════════════════

-- ============ SERVICES ============
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser  = game:GetService("VirtualUser")
local Lighting     = game:GetService("Lighting")
local Stats        = game:GetService("Stats")
local TeleportSvc  = game:GetService("TeleportService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============ DEVICE ============
local Device = {
    Touch    = UIS.TouchEnabled,
    Keyboard = UIS.KeyboardEnabled,
    Mouse    = UIS.MouseEnabled,
}
local IsMobile = Device.Touch and not Device.Keyboard

-- ============ REMOTES ============
local Network       = RS:WaitForChild("Network", 10)
local Remotes       = Network and Network:WaitForChild("Remotes", 10)
local ClientRemotes = Network and Network:WaitForChild("ClientRemotes", 10)
local Shoot         = Remotes and Remotes:FindFirstChild("Shoot")

-- ============ CONFIG ============
local CFG = {
    Protection = { Bypass = false, AntiKick = false, AntiFling = true, AntiAFK = true, AntiDetect = false, NoDataSend = false },
    Performance = { BoostFPS = false, LowPing = false, ShowFPSPing = false, RemoveParticle = false, RemoveShadow = false, RemoveEffect = false },
    Combat = {
        Aimbot = false, Smoothness = 5, AimType = "Camera", AimTarget = "AllEnemy", AimPart = "Head",
        POVRadius = 150, ShowPOV = false, POVColor = Color3.fromRGB(0, 170, 255),
        RageBot = false, AutoShoot = false, TeamCheck = true, WallCheck = false,
    },
    Visual = {
        MasterESP = false,
        LinePlayerTeamColor  = Color3.fromRGB(0, 170, 255),
        LineBotTeamColor     = Color3.fromRGB(0, 255, 100),
        LinePlayerEnemyColor = Color3.fromRGB(255, 60, 60),
        LineBotEnemyColor    = Color3.fromRGB(255, 220, 0),
        LinePlayerTeam = false, LineBotTeam = false, LinePlayerEnemy = false, LineBotEnemy = false,
        BoxPlayerTeam = false, BoxBotTeam = false, BoxPlayerEnemy = false, BoxBotEnemy = false,
        NamePlayerTeam = false, NameBotTeam = false, NamePlayerEnemy = false, NameBotEnemy = false,
        HealthPlayerTeam = false, HealthBotTeam = false, HealthPlayerEnemy = false, HealthBotEnemy = false,
    },
    Player = {
        FastRegen = false, AntiVoid = false, AntiFling = true, AntiAFK = true,
        NoCooldown = false, CooldownValue = 0,
        SpamEnabled = false, SpamDelay = 1, SpamTarget = "All",
        SpeedHack = false, SpeedValue = 25,
        JumpHack = false, JumpValue = 60, InfiniteJump = false,
        NoClip = false, FlyHack = false, FlySpeed = 50,
        Spinbot = false, SpinSpeed = 500,
    },
    Weapon = {
        InfiniteAmmo = false, RapidFire = false, RateFire = 1, NoDebounce = false,
        FastReload = false, InstantReload = false, ReloadSpeed = 1,
        NoRecoil = false, NoSpread = false,
        DamageHack = false, DamageValue = 999,
        RainbowBullets = false, BrightBullets = false, FatBullets = false,
    },
    Farm = {
        TpToPlayerBot = false, TpTarget = "All", TpPosition = "Depan", TpJarak = 5, TpDelay = 1,
        BringPlayerBot = false, BringTarget = "All", BringJarak = 7, BringSpread = 3,
        BringPart = "Head Only", BringMode = "All", AnchorEnemy = false,
        HitboxExpander = false, HitboxSize = 3, HitboxPart = "All", HitboxTarget = "AllEnemy",
    },
}

-- ============ HELPERS ============
local function GetTeam(plr) return plr and plr:GetAttribute("Team") end
local function GetCharTeam(char) return char and char:GetAttribute("Team") end
local function IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end
local function IsEnemy(plr)
    if plr == LP then return false end
    if not plr.Character or not IsAlive(plr.Character) then return false end
    if CFG.Combat.TeamCheck then
        local myTeam = GetCharTeam(LP.Character) or GetTeam(LP)
        local theirTeam = GetCharTeam(plr.Character) or GetTeam(plr)
        if myTeam ~= -1 and myTeam == theirTeam then return false end
    end
    return true
end
local function GetBots()
    local list = {}
    for _, fn in ipairs({"Mobs", "IgnoreThese"}) do
        local f = workspace:FindFirstChild(fn)
        if f then
            for _, b in ipairs(f:GetChildren()) do
                if IsAlive(b) then table.insert(list, b) end
            end
        end
    end
    return list
end
local function GetPart(inst, partName)
    if not inst then return nil end
    return inst:FindFirstChild(partName) or inst:FindFirstChild("Head") or inst:FindFirstChild("HumanoidRootPart")
end
local function WallCheck(part)
    if not CFG.Combat.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, Camera}
    local r = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return r == nil or r.Instance:IsDescendantOf(part.Parent)
end
local function GetAllTargets()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and IsAlive(p.Character) then
            table.insert(list, {inst = p.Character, plr = p, isPlayer = true, isEnemy = IsEnemy(p)})
        end
    end
    for _, b in ipairs(GetBots()) do
        table.insert(list, {inst = b, plr = nil, isPlayer = false, isEnemy = true})
    end
    return list
end

local Connections = {}
local function AddConn(c) table.insert(Connections, c); return c end

-- ============ LOAD RAYFIELD GEN 1 (AQUA THEME) ============
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "RY ULTIMATE HYPERshot",
    LoadingTitle = "RY Ultimate",
    LoadingSubtitle = "by ry-zeen",
    Theme = "Aqua",  -- 🩵 THEME AQUA
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RYUltimate",
        FileName = "RY_Hypershot"
    },
    KeySystem = false
})

local function Notify(title, content, duration)
    Rayfield:Notify({ Title = title, Content = content, Duration = duration or 5 })
end

-- ═══════════════════════════════════════════════════════════════
--   TAB 1: PROTECTION
-- ═══════════════════════════════════════════════════════════════
local ProtTab = Window:CreateTab("🛡️ Protection", 4483362458)
ProtTab:CreateSection("Main")
ProtTab:CreateToggle({ Name = "Bypass", CurrentValue = false, Flag = "Prot_Bypass",
    Callback = function(v) CFG.Protection.Bypass = v end })
ProtTab:CreateToggle({ Name = "Anti Kick", CurrentValue = false, Flag = "Prot_AntiKick",
    Callback = function(v) CFG.Protection.AntiKick = v end })
ProtTab:CreateToggle({ Name = "Anti Fling", CurrentValue = true, Flag = "Prot_AntiFling",
    Callback = function(v) CFG.Protection.AntiFling = v end })
ProtTab:CreateToggle({ Name = "Anti AFK", CurrentValue = true, Flag = "Prot_AntiAFK",
    Callback = function(v) CFG.Protection.AntiAFK = v end })
ProtTab:CreateToggle({ Name = "Anti Detect", CurrentValue = false, Flag = "Prot_AntiDetect",
    Callback = function(v) CFG.Protection.AntiDetect = v end })
ProtTab:CreateToggle({ Name = "No Data Send", CurrentValue = false, Flag = "Prot_NoDataSend",
    Callback = function(v) CFG.Protection.NoDataSend = v end })

-- ═══════════════════════════════════════════════════════════════
--   TAB 2: PERFORMANCE
-- ═══════════════════════════════════════════════════════════════
local PerfTab = Window:CreateTab("⚡ Performance", 6031094749)
PerfTab:CreateSection("Boost")
PerfTab:CreateToggle({ Name = "Boost FPS", CurrentValue = false, Flag = "Perf_BoostFPS",
    Callback = function(v)
        CFG.Performance.BoostFPS = v
        if v then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
                    obj.Enabled = false
                end
            end
        else
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 100000
            Lighting.Brightness = 2
        end
    end })
PerfTab:CreateToggle({ Name = "Low Ping", CurrentValue = false, Flag = "Perf_LowPing",
    Callback = function(v) CFG.Performance.LowPing = v end })
PerfTab:CreateToggle({ Name = "Show FPS & PING", CurrentValue = false, Flag = "Perf_ShowFPSPing",
    Callback = function(v)
        CFG.Performance.ShowFPSPing = v
        if not v and _G.RY_FPS_LABEL then
            _G.RY_FPS_LABEL:Remove()
            _G.RY_FPS_LABEL = nil
        end
    end })
PerfTab:CreateSection("Remove")
PerfTab:CreateToggle({ Name = "Remove Particle", CurrentValue = false, Flag = "Perf_RemoveParticle",
    Callback = function(v) CFG.Performance.RemoveParticle = v end })
PerfTab:CreateToggle({ Name = "Remove Shadow", CurrentValue = false, Flag = "Perf_RemoveShadow",
    Callback = function(v) CFG.Performance.RemoveShadow = v end })
PerfTab:CreateToggle({ Name = "Remove Effect", CurrentValue = false, Flag = "Perf_RemoveEffect",
    Callback = function(v) CFG.Performance.RemoveEffect = v end })

-- ═══════════════════════════════════════════════════════════════
--   TAB 3: COMBAT
-- ═══════════════════════════════════════════════════════════════
local CombatTab = Window:CreateTab("⚔️ Combat", 6034684930)
CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({ Name = "Aimbot", CurrentValue = false, Flag = "Combat_Aimbot",
    Callback = function(v) CFG.Combat.Aimbot = v end })
CombatTab:CreateSlider({ Name = "Aim Smoothness", Range = {0, 20}, Increment = 1, Suffix = "", CurrentValue = 5, Flag = "Combat_Smooth",
    Callback = function(v) CFG.Combat.Smoothness = v end })
CombatTab:CreateDropdown({ Name = "Aim Type", Options = {"Camera", "Mouse"}, CurrentOption = {"Camera"}, Flag = "Combat_AimType",
    Callback = function(o) CFG.Combat.AimType = o[1] end })
CombatTab:CreateDropdown({ Name = "Aim Target", Options = {"AllEnemy", "PlayerEnemy", "BotEnemy"}, CurrentOption = {"AllEnemy"}, Flag = "Combat_AimTarget",
    Callback = function(o) CFG.Combat.AimTarget = o[1] end })
CombatTab:CreateDropdown({ Name = "Aim Part", Options = {"Head", "HumanoidRootPart", "UpperTorso"}, CurrentOption = {"Head"}, Flag = "Combat_AimPart",
    Callback = function(o) CFG.Combat.AimPart = o[1] end })
CombatTab:CreateSection("POV Circle")
CombatTab:CreateSlider({ Name = "POV Radius", Range = {50, 500}, Increment = 10, Suffix = "px", CurrentValue = 150, Flag = "Combat_POVRadius",
    Callback = function(v) CFG.Combat.POVRadius = v end })
CombatTab:CreateToggle({ Name = "Show POV", CurrentValue = false, Flag = "Combat_ShowPOV",
    Callback = function(v) CFG.Combat.ShowPOV = v end })
CombatTab:CreateColorPicker({ Name = "POV Color", Color = Color3.fromRGB(0, 170, 255), Flag = "Combat_POVColor",
    Callback = function(c) CFG.Combat.POVColor = c end })
CombatTab:CreateSection("Rage Mode")
CombatTab:CreateToggle({ Name = "RageBot (Brutal)", CurrentValue = false, Flag = "Combat_RageBot",
    Callback = function(v) CFG.Combat.RageBot = v end })
CombatTab:CreateToggle({ Name = "Auto Shoot", CurrentValue = false, Flag = "Combat_AutoShoot",
    Callback = function(v) CFG.Combat.AutoShoot = v end })
CombatTab:CreateSection("Filter")
CombatTab:CreateToggle({ Name = "Team Check", CurrentValue = true, Flag = "Combat_TeamCheck",
    Callback = function(v) CFG.Combat.TeamCheck = v end })
CombatTab:CreateToggle({ Name = "Wall Check", CurrentValue = false, Flag = "Combat_WallCheck",
    Callback = function(v) CFG.Combat.WallCheck = v end })

-- ═══════════════════════════════════════════════════════════════
--   TAB 4: VISUAL
-- ═══════════════════════════════════════════════════════════════
local VisualTab = Window:CreateTab("👁️ Visual", 6031075938)
VisualTab:CreateSection("ESP Master")
VisualTab:CreateToggle({ Name = "Master ESP", CurrentValue = false, Flag = "Visual_MasterESP",
    Callback = function(v) CFG.Visual.MasterESP = v end })
VisualTab:CreateSection("ESP Team")
VisualTab:CreateToggle({ Name = "ESP Line Player Team", CurrentValue = false, Flag = "Visual_LinePlayerTeam",
    Callback = function(v) CFG.Visual.LinePlayerTeam = v end })
VisualTab:CreateColorPicker({ Name = "Line Player Team Color", Color = Color3.fromRGB(0, 170, 255), Flag = "Visual_LinePlayerTeamColor",
    Callback = function(c) CFG.Visual.LinePlayerTeamColor = c end })
VisualTab:CreateToggle({ Name = "ESP Line Bot Team", CurrentValue = false, Flag = "Visual_LineBotTeam",
    Callback = function(v) CFG.Visual.LineBotTeam = v end })
VisualTab:CreateColorPicker({ Name = "Line Bot Team Color", Color = Color3.fromRGB(0, 255, 100), Flag = "Visual_LineBotTeamColor",
    Callback = function(c) CFG.Visual.LineBotTeamColor = c end })
VisualTab:CreateToggle({ Name = "ESP Box Team Player/Bot", CurrentValue = false, Flag = "Visual_BoxTeam",
    Callback = function(v) CFG.Visual.BoxPlayerTeam = v; CFG.Visual.BoxBotTeam = v end })
VisualTab:CreateToggle({ Name = "ESP Name Team Player/Bot", CurrentValue = false, Flag = "Visual_NameTeam",
    Callback = function(v) CFG.Visual.NamePlayerTeam = v; CFG.Visual.NameBotTeam = v end })
VisualTab:CreateToggle({ Name = "ESP Health Team Player/Bot", CurrentValue = false, Flag = "Visual_HealthTeam",
    Callback = function(v) CFG.Visual.HealthPlayerTeam = v; CFG.Visual.HealthBotTeam = v end })
VisualTab:CreateSection("ESP Enemy")
VisualTab:CreateToggle({ Name = "ESP Line Player Enemy", CurrentValue = false, Flag = "Visual_LinePlayerEnemy",
    Callback = function(v) CFG.Visual.LinePlayerEnemy = v end })
VisualTab:CreateColorPicker({ Name = "Line Player Enemy Color", Color = Color3.fromRGB(255, 60, 60), Flag = "Visual_LinePlayerEnemyColor",
    Callback = function(c) CFG.Visual.LinePlayerEnemyColor = c end })
VisualTab:CreateToggle({ Name = "ESP Line Bot Enemy", CurrentValue = false, Flag = "Visual_LineBotEnemy",
    Callback = function(v) CFG.Visual.LineBotEnemy = v end })
VisualTab:CreateColorPicker({ Name = "Line Bot Enemy Color", Color = Color3.fromRGB(255, 220, 0), Flag = "Visual_LineBotEnemyColor",
    Callback = function(c) CFG.Visual.LineBotEnemyColor = c end })
VisualTab:CreateToggle({ Name = "ESP Box Enemy Player/Bot", CurrentValue = false, Flag = "Visual_BoxEnemy",
    Callback = function(v) CFG.Visual.BoxPlayerEnemy = v; CFG.Visual.BoxBotEnemy = v end })
VisualTab:CreateToggle({ Name = "ESP Name Enemy Player/Bot", CurrentValue = false, Flag = "Visual_NameEnemy",
    Callback = function(v) CFG.Visual.NamePlayerEnemy = v; CFG.Visual.NameBotEnemy = v end })
VisualTab:CreateToggle({ Name = "ESP Health Enemy Player/Bot", CurrentValue = false, Flag = "Visual_HealthEnemy",
    Callback = function(v) CFG.Visual.HealthPlayerEnemy = v; CFG.Visual.HealthBotEnemy = v end })

-- ═══════════════════════════════════════════════════════════════
--   TAB 5: PLAYER
-- ═══════════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("👤 Player", 6031075938)

PlayerTab:CreateSection("Survival")
PlayerTab:CreateToggle({ Name = "Fast Regen", CurrentValue = false, Flag = "Player_FastRegen",
    Callback = function(v) CFG.Player.FastRegen = v end })
PlayerTab:CreateToggle({ Name = "Anti Void", CurrentValue = false, Flag = "Player_AntiVoid",
    Callback = function(v) CFG.Player.AntiVoid = v end })
PlayerTab:CreateToggle({ Name = "Anti Fling", CurrentValue = true, Flag = "Player_AntiFling",
    Callback = function(v) CFG.Player.AntiFling = v end })
PlayerTab:CreateToggle({ Name = "Anti AFK", CurrentValue = true, Flag = "Player_AntiAFK",
    Callback = function(v) CFG.Player.AntiAFK = v end })

PlayerTab:CreateSection("Ability")
PlayerTab:CreateToggle({ Name = "No Cooldown", CurrentValue = false, Flag = "Player_NoCD",
    Callback = function(v) CFG.Player.NoCooldown = v; if v then Notify("Ability", "No Cooldown ON", 3) end end })
PlayerTab:CreateSlider({ Name = "Cooldown Value", Range = {0, 100}, Increment = 1, Suffix = "", CurrentValue = 0, Flag = "Player_CDVal",
    Callback = function(v) CFG.Player.CooldownValue = v end })
PlayerTab:CreateToggle({ Name = "Ability Spam", CurrentValue = false, Flag = "Player_AbilitySpam",
    Callback = function(v) CFG.Player.SpamEnabled = v; if v then Notify("Ability", "Spam ON", 3) end end })
PlayerTab:CreateSlider({ Name = "Spam Delay (s)", Range = {0.1, 5}, Increment = 0.1, Suffix = "s", CurrentValue = 1, Flag = "Player_SpamDelay",
    Callback = function(v) CFG.Player.SpamDelay = v end })
PlayerTab:CreateDropdown({ Name = "Spam Target", Options = {"All", "PlayerOnly", "BotOnly", "Self"}, CurrentOption = {"All"}, Flag = "Player_SpamTarget",
    Callback = function(o) CFG.Player.SpamTarget = o[1] end })
PlayerTab:CreateButton({ Name = "🔍 Scan Ability Remotes",
    Callback = function()
        local keywords = {"Dash", "Ward", "Orb", "Edge", "Dagger", "Punch", "Bounce", "Jump", "Ability", "Skill", "Cast", "Use"}
        local found = {}
        for _, r in ipairs(Remotes:GetChildren()) do
            if r:IsA("RemoteEvent") then
                for _, kw in ipairs(keywords) do
                    if string.find(r.Name, kw, 1, true) then
                        table.insert(found, r.Name); break
                    end
                end
            end
        end
        Notify("Ability Remotes", "Found " .. #found .. " remotes:\n" .. table.concat(found, ", "), 8)
    end })
PlayerTab:CreateButton({ Name = "🔍 Count CD Tables",
    Callback = function() Notify("CD Tables", "Found: " .. #CDTables .. " tables", 5) end })

PlayerTab:CreateSection("Speed")
PlayerTab:CreateToggle({ Name = "Speed Hack", CurrentValue = false, Flag = "Player_SpeedHack",
    Callback = function(v)
        CFG.Player.SpeedHack = v
        if LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v and CFG.Player.SpeedValue or 16 end
        end
    end })
PlayerTab:CreateSlider({ Name = "Speed Value", Range = {0, 100}, Increment = 1, Suffix = "x", CurrentValue = 25, Flag = "Player_SpeedValue",
    Callback = function(v)
        CFG.Player.SpeedValue = v
        if CFG.Player.SpeedHack and LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end
    end })

PlayerTab:CreateSection("Jump")
PlayerTab:CreateToggle({ Name = "Jump Hack", CurrentValue = false, Flag = "Player_JumpHack",
    Callback = function(v)
        CFG.Player.JumpHack = v
        if LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true; h.JumpPower = v and CFG.Player.JumpValue or 50 end
        end
    end })
PlayerTab:CreateSlider({ Name = "Jump Value", Range = {0, 100}, Increment = 1, Suffix = "x", CurrentValue = 60, Flag = "Player_JumpValue",
    Callback = function(v)
        CFG.Player.JumpValue = v
        if CFG.Player.JumpHack and LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true; h.JumpPower = v end
        end
    end })
PlayerTab:CreateToggle({ Name = "Infinity Jump", CurrentValue = false, Flag = "Player_InfJump",
    Callback = function(v) CFG.Player.InfiniteJump = v end })

PlayerTab:CreateSection("Movement")
PlayerTab:CreateToggle({ Name = "No Clip", CurrentValue = false, Flag = "Player_NoClip",
    Callback = function(v) CFG.Player.NoClip = v end })
PlayerTab:CreateToggle({ Name = "Fly Hack", CurrentValue = false, Flag = "Player_FlyHack",
    Callback = function(v) CFG.Player.FlyHack = v end })
PlayerTab:CreateSlider({ Name = "Fly Speed", Range = {0, 100}, Increment = 1, Suffix = "x", CurrentValue = 50, Flag = "Player_FlySpeed",
    Callback = function(v) CFG.Player.FlySpeed = v end })
PlayerTab:CreateToggle({ Name = "Spinbot", CurrentValue = false, Flag = "Player_Spinbot",
    Callback = function(v) CFG.Player.Spinbot = v end })
PlayerTab:CreateSlider({ Name = "Spin Speed", Range = {0, 1000}, Increment = 10, Suffix = "x", CurrentValue = 500, Flag = "Player_SpinSpeed",
    Callback = function(v) CFG.Player.SpinSpeed = v end })

-- ═══════════════════════════════════════════════════════════════
--   TAB 6: WEAPON
-- ═══════════════════════════════════════════════════════════════
local WeaponTab = Window:CreateTab("🔫 Weapon", 6031280882)
WeaponTab:CreateSection("Ammo")
WeaponTab:CreateToggle({ Name = "Infinite Ammo", CurrentValue = false, Flag = "Weapon_InfAmmo",
    Callback = function(v) CFG.Weapon.InfiniteAmmo = v end })
WeaponTab:CreateSection("Fire Rate")
WeaponTab:CreateToggle({ Name = "Rapid Fire", CurrentValue = false, Flag = "Weapon_RapidFire",
    Callback = function(v) CFG.Weapon.RapidFire = v end })
WeaponTab:CreateSlider({ Name = "Rate Fire", Range = {0, 100000}, Increment = 1, Suffix = "", CurrentValue = 1, Flag = "Weapon_RateFire",
    Callback = function(v) CFG.Weapon.RateFire = v end })
WeaponTab:CreateToggle({ Name = "No Debounce", CurrentValue = false, Flag = "Weapon_NoDebounce",
    Callback = function(v) CFG.Weapon.NoDebounce = v end })
WeaponTab:CreateSection("Reload")
WeaponTab:CreateToggle({ Name = "Fast Reload", CurrentValue = false, Flag = "Weapon_FastReload",
    Callback = function(v) CFG.Weapon.FastReload = v end })
WeaponTab:CreateToggle({ Name = "Instant Reload", CurrentValue = false, Flag = "Weapon_InstantReload",
    Callback = function(v) CFG.Weapon.InstantReload = v end })
WeaponTab:CreateSlider({ Name = "Reload Speed", Range = {1, 100}, Increment = 1, Suffix = "x", CurrentValue = 1, Flag = "Weapon_ReloadSpeed",
    Callback = function(v) CFG.Weapon.ReloadSpeed = v end })
WeaponTab:CreateSection("Accuracy")
WeaponTab:CreateToggle({ Name = "No Recoil", CurrentValue = false, Flag = "Weapon_NoRecoil",
    Callback = function(v) CFG.Weapon.NoRecoil = v end })
WeaponTab:CreateToggle({ Name = "No Spread", CurrentValue = false, Flag = "Weapon_NoSpread",
    Callback = function(v) CFG.Weapon.NoSpread = v end })
WeaponTab:CreateSection("Damage")
WeaponTab:CreateToggle({ Name = "Damage Hack", CurrentValue = false, Flag = "Weapon_Damage",
    Callback = function(v) CFG.Weapon.DamageHack = v end })
WeaponTab:CreateSlider({ Name = "Damage Value", Range = {100, 99999}, Increment = 1, Suffix = "", CurrentValue = 999, Flag = "Weapon_DamageVal",
    Callback = function(v) CFG.Weapon.DamageValue = v end })
WeaponTab:CreateSection("Bullet Visual")
WeaponTab:CreateToggle({ Name = "Rainbow Bullets", CurrentValue = false, Flag = "Weapon_Rainbow",
    Callback = function(v) CFG.Weapon.RainbowBullets = v end })
WeaponTab:CreateToggle({ Name = "Bright Bullets", CurrentValue = false, Flag = "Weapon_Bright",
    Callback = function(v) CFG.Weapon.BrightBullets = v end })
WeaponTab:CreateToggle({ Name = "Fat Bullets", CurrentValue = false, Flag = "Weapon_Fat",
    Callback = function(v) CFG.Weapon.FatBullets = v end })
WeaponTab:CreateSection("Debug")
WeaponTab:CreateButton({ Name = "🔍 Count Weapon Tables",
    Callback = function() Notify("Weapon Tables", "Found: " .. #weaponTables .. " tables", 5) end })

-- ═══════════════════════════════════════════════════════════════
--   TAB 7: FARM
-- ═══════════════════════════════════════════════════════════════
local FarmTab = Window:CreateTab("🌾 Farm", 4483362458)
FarmTab:CreateSection("Tp To Player & Bot")
FarmTab:CreateToggle({ Name = "Tp To Player & Bot", CurrentValue = false, Flag = "Farm_Tp",
    Callback = function(v) CFG.Farm.TpToPlayerBot = v end })
FarmTab:CreateDropdown({ Name = "Tp Target", Options = {"All", "PlayerOnly", "BotOnly"}, CurrentOption = {"All"}, Flag = "Farm_TpTarget",
    Callback = function(o) CFG.Farm.TpTarget = o[1] end })
FarmTab:CreateDropdown({ Name = "Tp Position", Options = {"Depan", "Belakang", "Atas", "Bawah"}, CurrentOption = {"Depan"}, Flag = "Farm_TpPos",
    Callback = function(o) CFG.Farm.TpPosition = o[1] end })
FarmTab:CreateSlider({ Name = "Tp Jarak", Range = {0, 100}, Increment = 1, Suffix = " studs", CurrentValue = 5, Flag = "Farm_TpJarak",
    Callback = function(v) CFG.Farm.TpJarak = v end })
FarmTab:CreateSlider({ Name = "Tp Delay", Range = {0, 100}, Increment = 1, Suffix = "ms", CurrentValue = 1, Flag = "Farm_TpDelay",
    Callback = function(v) CFG.Farm.TpDelay = v end })

FarmTab:CreateSection("Bring Player & Bot")
FarmTab:CreateToggle({ Name = "Bring Player & Bot", CurrentValue = false, Flag = "Farm_Bring",
    Callback = function(v) CFG.Farm.BringPlayerBot = v end })
FarmTab:CreateDropdown({ Name = "Bring Mode", Options = {"All", "Single"}, CurrentOption = {"All"}, Flag = "Farm_BringMode",
    Callback = function(o) CFG.Farm.BringMode = o[1]; Notify("Bring Mode", "Mode: " .. o[1], 3) end })
FarmTab:CreateDropdown({ Name = "Bring Part", Options = {"Head Only", "Full HRP", "Both"}, CurrentOption = {"Head Only"}, Flag = "Farm_BringPart",
    Callback = function(o) CFG.Farm.BringPart = o[1] end })
FarmTab:CreateDropdown({ Name = "Bring Target", Options = {"All", "PlayerOnly", "BotOnly"}, CurrentOption = {"All"}, Flag = "Farm_BringTarget",
    Callback = function(o) CFG.Farm.BringTarget = o[1] end })
FarmTab:CreateSlider({ Name = "Bring Jarak", Range = {0, 100}, Increment = 1, Suffix = " studs", CurrentValue = 7, Flag = "Farm_BringJarak",
    Callback = function(v) CFG.Farm.BringJarak = v end })
FarmTab:CreateSlider({ Name = "Bring Spread", Range = {1, 10}, Increment = 1, Suffix = "", CurrentValue = 3, Flag = "Farm_BringSpread",
    Callback = function(v) CFG.Farm.BringSpread = v end })
FarmTab:CreateToggle({ Name = "Anchor Enemy", CurrentValue = false, Flag = "Farm_Anchor",
    Callback = function(v)
        CFG.Farm.AnchorEnemy = v
        if not v then
            for _, t in ipairs(GetAllTargets()) do
                local hrp = t.inst:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.Anchored = false end) end
            end
        end
    end })

FarmTab:CreateSection("Hitbox Expander")
FarmTab:CreateToggle({ Name = "Hitbox Expander", CurrentValue = false, Flag = "Farm_Hitbox",
    Callback = function(v) CFG.Farm.HitboxExpander = v end })
FarmTab:CreateSlider({ Name = "Hitbox Size", Range = {1, 10}, Increment = 1, Suffix = "x", CurrentValue = 3, Flag = "Farm_HitboxSize",
    Callback = function(v) CFG.Farm.HitboxSize = v end })
FarmTab:CreateDropdown({ Name = "Hitbox Part", Options = {"All", "Head", "Body", "Foot"}, CurrentOption = {"All"}, Flag = "Farm_HitboxPart",
    Callback = function(o) CFG.Farm.HitboxPart = o[1] end })
FarmTab:CreateDropdown({ Name = "Hitbox Target", Options = {"AllEnemy", "PlayerEnemy", "BotEnemy"}, CurrentOption = {"AllEnemy"}, Flag = "Farm_HitboxTarget",
    Callback = function(o) CFG.Farm.HitboxTarget = o[1] end })

-- ═══════════════════════════════════════════════════════════════
--   TAB 8: UNLOAD
-- ═══════════════════════════════════════════════════════════════
local UnloadTab = Window:CreateTab("💥 Unload", 6031094749)
UnloadTab:CreateSection("Cleanup")
UnloadTab:CreateButton({ Name = "💥 UNLOAD SCRIPT",
    Callback = function()
        for _, t in ipairs(GetAllTargets()) do
            local hrp = t.inst:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.Anchored = false end) end
        end
        for _, v in ipairs(weaponTables) do
            local orig = weaponOriginals[v]
            if orig then
                pcall(function()
                    if orig.Reload then rawset(v, "Reload", orig.Reload) end
                    if orig.FireInterval then rawset(v, "FireInterval", orig.FireInterval) end
                    if orig.BaseSpread then rawset(v, "BaseSpread", orig.BaseSpread) end
                    if orig.Spread then rawset(v, "Spread", orig.Spread) end
                end)
            end
        end
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        Connections = {}
        if Rayfield and Rayfield.Destroy then pcall(function() Rayfield:Destroy() end) end
        print("[RY] Unloaded.")
    end })
UnloadTab:CreateButton({ Name = "🔄 Rejoin Game",
    Callback = function() TeleportSvc:Teleport(game.PlaceId, LP) end })

-- ═══════════════════════════════════════════════════════════════
--   CORE LOGIC
-- ═══════════════════════════════════════════════════════════════

-- POV Circle
local povCircle
if Drawing then
    povCircle = Drawing.new("Circle")
    povCircle.Thickness = 1
    povCircle.NumSides = 64
    povCircle.Filled = false
    povCircle.Transparency = 1
end
AddConn(RunService.RenderStepped:Connect(function()
    if povCircle then
        povCircle.Radius = CFG.Combat.POVRadius
        povCircle.Color = CFG.Combat.POVColor
        povCircle.Visible = CFG.Combat.ShowPOV
        povCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end))

-- FPS / PING
local lastClock = os.clock()
AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Performance.ShowFPSPing then return end
    if not Drawing then return end
    if not _G.RY_FPS_LABEL then
        local lbl = Drawing.new("Text")
        lbl.Size = 16; lbl.Position = Vector2.new(10, 30)
        lbl.Color = Color3.fromRGB(0, 255, 100); lbl.Outline = true; lbl.Visible = true
        _G.RY_FPS_LABEL = lbl
    end
    local now = os.clock()
    local delta = now - lastClock
    lastClock = now
    local fps = delta > 0 and math.floor(1 / delta) or 0
    local ping = 0
    pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    _G.RY_FPS_LABEL.Text = string.format("FPS: %d | PING: %dms", fps, ping)
end))

-- Aimbot
local function GetAimTargets()
    local list = {}
    if CFG.Combat.AimTarget == "AllEnemy" or CFG.Combat.AimTarget == "PlayerEnemy" then
        for _, p in ipairs(Players:GetPlayers()) do
            if IsEnemy(p) then table.insert(list, {inst = p.Character, isPlayer = true}) end
        end
    end
    if CFG.Combat.AimTarget == "AllEnemy" or CFG.Combat.AimTarget == "BotEnemy" then
        for _, b in ipairs(GetBots()) do table.insert(list, {inst = b, isPlayer = false}) end
    end
    return list
end
local function FindClosest()
    local closest, dist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, t in ipairs(GetAimTargets()) do
        local part = GetPart(t.inst, CFG.Combat.AimPart)
        if part then
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d < CFG.Combat.POVRadius and d < dist and WallCheck(part) then
                    closest, dist = t, d
                end
            end
        end
    end
    return closest
end
AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Combat.Aimbot and not CFG.Combat.RageBot then return end
    local target = FindClosest()
    if not target then return end
    local part = GetPart(target.inst, CFG.Combat.AimPart)
    if not part then return end
    if CFG.Combat.RageBot then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
        if CFG.Combat.AutoShoot and Shoot then pcall(function() Shoot:FireServer(part) end) end
    else
        local smooth = CFG.Combat.Smoothness > 0 and CFG.Combat.Smoothness or 1
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), 1/smooth)
    end
end))

-- ESP Render
local espCache = {}
local function CreateESP(inst)
    if espCache[inst] then return espCache[inst] end
    local data = {}
    if Drawing then
        data.line = Drawing.new("Line"); data.line.Thickness = 1; data.line.Transparency = 1; data.line.Visible = false
        data.box = Drawing.new("Square"); data.box.Thickness = 1; data.box.Filled = false; data.box.Transparency = 1; data.box.Visible = false
        data.name = Drawing.new("Text"); data.name.Size = 13; data.name.Center = true; data.name.Outline = true; data.name.Transparency = 1; data.name.Visible = false
        data.health = Drawing.new("Text"); data.health.Size = 12; data.health.Center = true; data.health.Outline = true; data.health.Transparency = 1; data.health.Visible = false
    end
    espCache[inst] = data
    return data
end
local function RemoveESP(inst)
    local d = espCache[inst]
    if d then
        for _, o in pairs(d) do
            if typeof(o) == "userdata" then pcall(function() o:Remove() end) end
        end
        espCache[inst] = nil
    end
end
local function IsValidESP(inst)
    if not inst or not inst.Parent then return false end
    local hum = inst:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end
local function RenderESP(inst, isPlayer, isTeammate, isEnemy)
    if not Drawing then return end
    if not IsValidESP(inst) then
        local d = espCache[inst]
        if d then
            if d.line then d.line.Visible = false end
            if d.box then d.box.Visible = false end
            if d.name then d.name.Visible = false end
            if d.health then d.health.Visible = false end
        end
        return
    end
    local d = CreateESP(inst)
    local hrp = inst:FindFirstChild("HumanoidRootPart")
    local head = inst:FindFirstChild("Head")
    local hum = inst:FindFirstChildOfClass("Humanoid")
    if not hrp or not head or not hum then return end
    local headPos, on = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local rootPos = Camera:WorldToViewportPoint(hrp.Position)
    if not on then
        if d.line then d.line.Visible = false end
        if d.box then d.box.Visible = false end
        if d.name then d.name.Visible = false end
        if d.health then d.health.Visible = false end
        return
    end
    local h = math.abs(headPos.Y - rootPos.Y) * 2
    local w = h / 2
    local lineColor, boxTgl, nameTgl, healthTgl, lineTgl
    if isPlayer and isTeammate then
        lineColor = CFG.Visual.LinePlayerTeamColor; lineTgl = CFG.Visual.LinePlayerTeam
        boxTgl = CFG.Visual.BoxPlayerTeam; nameTgl = CFG.Visual.NamePlayerTeam; healthTgl = CFG.Visual.HealthPlayerTeam
    elseif not isPlayer and isTeammate then
        lineColor = CFG.Visual.LineBotTeamColor; lineTgl = CFG.Visual.LineBotTeam
        boxTgl = CFG.Visual.BoxBotTeam; nameTgl = CFG.Visual.NameBotTeam; healthTgl = CFG.Visual.HealthBotTeam
    elseif isPlayer and isEnemy then
        lineColor = CFG.Visual.LinePlayerEnemyColor; lineTgl = CFG.Visual.LinePlayerEnemy
        boxTgl = CFG.Visual.BoxPlayerEnemy; nameTgl = CFG.Visual.NamePlayerEnemy; healthTgl = CFG.Visual.HealthPlayerEnemy
    else
        lineColor = CFG.Visual.LineBotEnemyColor; lineTgl = CFG.Visual.LineBotEnemy
        boxTgl = CFG.Visual.BoxBotEnemy; nameTgl = CFG.Visual.NameBotEnemy; healthTgl = CFG.Visual.HealthBotEnemy
    end
    local masterOn = CFG.Visual.MasterESP
    if d.line then
        if masterOn and lineTgl then
            d.line.Visible = true; d.line.Color = lineColor
            d.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            d.line.To = Vector2.new(headPos.X, headPos.Y)
        else d.line.Visible = false end
    end
    if d.box then
        if masterOn and boxTgl then
            d.box.Visible = true; d.box.Color = lineColor
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(headPos.X - w/2, headPos.Y - h/2)
        else d.box.Visible = false end
    end
    if d.name then
        if masterOn and nameTgl then
            d.name.Visible = true; d.name.Color = lineColor
            d.name.Text = inst.Name; d.name.Position = Vector2.new(headPos.X, headPos.Y - 18)
        else d.name.Visible = false end
    end
    if d.health then
        if masterOn and healthTgl then
            d.health.Visible = true; d.health.Color = lineColor
            d.health.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
            d.health.Position = Vector2.new(headPos.X, headPos.Y + h - 4)
        else d.health.Visible = false end
    end
end
AddConn(RunService.RenderStepped:Connect(function()
    if not Drawing then return end
    for inst, _ in pairs(espCache) do
        if not inst or not inst.Parent then RemoveESP(inst) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local isTeam = GetTeam(p) == GetTeam(LP)
            RenderESP(p.Character, true, isTeam, not isTeam)
        end
    end
    for _, b in ipairs(GetBots()) do RenderESP(b, false, false, true) end
end))

-- Player Logic
AddConn(LP.Idled:Connect(function()
    if CFG.Protection.AntiAFK or CFG.Player.AntiAFK then
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end)
    end
end))
AddConn(RunService.Stepped:Connect(function()
    if not CFG.Protection.AntiFling and not CFG.Player.AntiFling then return end
    if not LP.Character then return end
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.AssemblyLinearVelocity.Magnitude > 200 then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end))
local function OnChar(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    if CFG.Player.SpeedHack then hum.WalkSpeed = CFG.Player.SpeedValue end
    if CFG.Player.JumpHack then hum.UseJumpPower = true; hum.JumpPower = CFG.Player.JumpValue end
end
if LP.Character then OnChar(LP.Character) end
AddConn(LP.CharacterAdded:Connect(OnChar))
AddConn(RunService.Heartbeat:Connect(function()
    if CFG.Player.FastRegen and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end
end))
AddConn(UIS.JumpRequest:Connect(function()
    if CFG.Player.InfiniteJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))
AddConn(RunService.Stepped:Connect(function()
    if CFG.Player.NoClip and LP.Character then
        for _, v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end))
AddConn(RunService.Heartbeat:Connect(function()
    if CFG.Player.AntiVoid and LP.Character then
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 50, 0) end
    end
end))

-- Fly
local flyBV, flyBG
local function StartFly()
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9); flyBG.P = 1000; flyBG.Parent = hrp
end
local function StopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end
AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Player.FlyHack then
        if flyBV then StopFly() end
        return
    end
    if not flyBV then StartFly() end
    if not flyBV or not LP.Character then return end
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local dir = Vector3.zero
    if IsMobile then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then dir = hum.MoveDirection end
    else
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
    end
    flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.Player.FlySpeed or Vector3.zero
    flyBG.CFrame = Camera.CFrame
end))

-- Spinbot
local spinAngle = 0
AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Player.Spinbot then return end
    if not LP.Character then return end
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    spinAngle = spinAngle + (CFG.Player.SpinSpeed / 100)
    if spinAngle > 360 then spinAngle = spinAngle - 360 end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
end))

-- Weapon Logic
local weaponTables = {}
local weaponOriginals = {}
local function ScanWeapons()
    weaponTables = {}
    for _, v in next, getgc(true) do
        if type(v) == "table" and (rawget(v, "FireInterval") or rawget(v, "BaseSpread") or rawget(v, "DirectDamage") or rawget(v, "Reload")) then
            table.insert(weaponTables, v)
            if weaponOriginals[v] == nil then
                weaponOriginals[v] = {
                    Reload = rawget(v, "Reload"), FireInterval = rawget(v, "FireInterval"),
                    BaseSpread = rawget(v, "BaseSpread"), Spread = rawget(v, "Spread"),
                }
            end
        end
    end
end
ScanWeapons()
task.spawn(function() while task.wait(5) do ScanWeapons() end end)
AddConn(RunService.Heartbeat:Connect(function()
    for _, t in ipairs(weaponTables) do
        local orig = weaponOriginals[t] or {}
        if CFG.Weapon.NoRecoil then
            pcall(function()
                rawset(t, "MaxRotRecoil", Vector3.zero); rawset(t, "MinRotRecoil", Vector3.zero)
                rawset(t, "MaxCamRecoil", Vector3.zero); rawset(t, "MinCamRecoil", Vector3.zero)
                rawset(t, "MaxTransRecoil", Vector3.zero); rawset(t, "MinTransRecoil", Vector3.zero)
            end)
        end
        if CFG.Weapon.NoSpread then
            pcall(function() rawset(t, "BaseSpread", 0); rawset(t, "Spread", 0) end)
        else
            pcall(function()
                if orig.BaseSpread then rawset(t, "BaseSpread", orig.BaseSpread) end
                if orig.Spread then rawset(t, "Spread", orig.Spread) end
            end)
        end
        if CFG.Weapon.RapidFire then
            pcall(function() rawset(t, "FireInterval", CFG.Weapon.RateFire) end)
        else
            pcall(function() if orig.FireInterval then rawset(t, "FireInterval", orig.FireInterval) end end)
        end
        if CFG.Weapon.InfiniteAmmo then pcall(function() rawset(t, "FillAmmo", 9999); rawset(t, "DirectAmmoRefill", true) end) end
        if CFG.Weapon.NoDebounce then
            pcall(function() rawset(t, "Debounce", 0); rawset(t, "ShootDelay", 0); rawset(t, "AcquireDelay", 0) end)
        end
        if CFG.Weapon.DamageHack then
            pcall(function()
                rawset(t, "DirectDamage", CFG.Weapon.DamageValue)
                rawset(t, "HeadDamage", CFG.Weapon.DamageValue)
                rawset(t, "DirectHeadDamage", CFG.Weapon.DamageValue)
            end)
        end
        if CFG.Weapon.RainbowBullets then pcall(function() rawset(t, "RainbowBullets", true) end) end
        if CFG.Weapon.BrightBullets then pcall(function() rawset(t, "BulletBrightness", 5) end) end
        if CFG.Weapon.FatBullets then pcall(function() rawset(t, "BulletWidth", 5) end) end
        if CFG.Weapon.InstantReload then
            pcall(function() rawset(t, "Reload", 0); rawset(t, "ShotgunReloadPellets", 999) end)
        elseif CFG.Weapon.FastReload then
            pcall(function()
                if type(orig.Reload) == "number" and orig.Reload > 0 then
                    rawset(t, "Reload", orig.Reload / CFG.Weapon.ReloadSpeed)
                end
            end)
        else
            pcall(function() if type(orig.Reload) == "number" then rawset(t, "Reload", orig.Reload) end end)
        end
    end
end))

-- Ability Logic
local AbilityKeywords = {"Dash", "Ward", "Orb", "Edge", "Dagger", "Punch", "Bounce", "Jump", "Ability", "Skill", "Cast", "Use"}
local AbilityRemotes = {}
for _, remote in ipairs(Remotes:GetChildren()) do
    if remote:IsA("RemoteEvent") then
        for _, kw in ipairs(AbilityKeywords) do
            if string.find(remote.Name, kw, 1, true) then table.insert(AbilityRemotes, remote); break end
        end
    end
end

local CDTables = {}
task.spawn(function()
    while task.wait(5) do
        CDTables = {}
        for _, v in next, getgc(true) do
            if type(v) == "table" and (rawget(v, "CD") or rawget(v, "Cooldown") or rawget(v, "CastCondition")) then
                table.insert(CDTables, v)
            end
        end
    end
end)
AddConn(RunService.Heartbeat:Connect(function()
    if not CFG.Player.NoCooldown then return end
    for _, t in ipairs(CDTables) do
        if rawget(t, "CD") and type(rawget(t, "CD")) == "number" and rawget(t, "CD") > 0 then
            rawset(t, "CD", CFG.Player.CooldownValue)
        end
        if rawget(t, "Cooldown") and type(rawget(t, "Cooldown")) == "number" and rawget(t, "Cooldown") > 0 then
            rawset(t, "Cooldown", CFG.Player.CooldownValue)
        end
        local castCond = rawget(t, "CastCondition")
        if type(castCond) == "function" then
            pcall(function() rawset(t, "CastCondition", function(...) return true end) end)
        end
    end
end))

local function GetAbilityTarget()
    if CFG.Player.SpamTarget == "Self" then
        return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    end
    local closest, dist = nil, math.huge
    local myPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            if CFG.Player.SpamTarget == "All" or CFG.Player.SpamTarget == "PlayerOnly" then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - myPos.Position).Magnitude
                    if d < dist then closest, dist = hrp, d end
                end
            end
        end
    end
    if CFG.Player.SpamTarget == "All" or CFG.Player.SpamTarget == "BotOnly" then
        for _, b in ipairs(GetBots()) do
            local hrp = b:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myPos.Position).Magnitude
                if d < dist then closest, dist = hrp, d end
            end
        end
    end
    return closest
end

local lastAbilityFire = 0
task.spawn(function()
    while task.wait(CFG.Player.SpamDelay) do
        if not CFG.Player.SpamEnabled then continue end
        local now = tick()
        if now - lastAbilityFire < 0.05 then continue end
        lastAbilityFire = now
        local target = GetAbilityTarget()
        for _, remote in ipairs(AbilityRemotes) do
            pcall(function() remote:FireServer() end)
            if target then
                pcall(function() remote:FireServer(target) end)
                pcall(function() remote:FireServer(target.Position) end)
            end
        end
    end
end)

-- Farm Logic
local function GetFarmTargets(filter)
    local list = {}
    for _, t in ipairs(GetAllTargets()) do
        if filter == "All" then table.insert(list, t) end
        if filter == "PlayerOnly" and t.isPlayer then table.insert(list, t) end
        if filter == "BotOnly" and not t.isPlayer then table.insert(list, t) end
    end
    return list
end
local function GetClosestFarmTarget(filter)
    local list = GetFarmTargets(filter)
    local myPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    local closest, dist = nil, math.huge
    for _, t in ipairs(list) do
        local hrp = t.inst:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - myPos.Position).Magnitude
            if d < dist then closest, dist = t, d end
        end
    end
    return closest
end
local function GetBringList()
    if CFG.Farm.BringMode == "Single" then
        local closest = GetClosestFarmTarget(CFG.Farm.BringTarget)
        return closest and {closest} or {}
    else
        return GetFarmTargets(CFG.Farm.BringTarget)
    end
end

local lastTpTime = 0
AddConn(RunService.Heartbeat:Connect(function()
    if not CFG.Farm.TpToPlayerBot then return end
    if not LP.Character then return end
    local now = tick()
    if (now - lastTpTime) * 1000 < CFG.Farm.TpDelay then return end
    lastTpTime = now
    local myRoot = LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for _, t in ipairs(GetFarmTargets(CFG.Farm.TpTarget)) do
        local hrp = t.inst:FindFirstChild("HumanoidRootPart")
        if hrp then
            local offset
            if CFG.Farm.TpPosition == "Depan" then offset = hrp.CFrame.LookVector * CFG.Farm.TpJarak
            elseif CFG.Farm.TpPosition == "Belakang" then offset = -hrp.CFrame.LookVector * CFG.Farm.TpJarak
            elseif CFG.Farm.TpPosition == "Atas" then offset = Vector3.new(0, CFG.Farm.TpJarak, 0)
            elseif CFG.Farm.TpPosition == "Bawah" then offset = Vector3.new(0, -CFG.Farm.TpJarak, 0) end
            myRoot.CFrame = CFrame.new(hrp.Position + offset)
            break
        end
    end
end))

local bringOffsets = {}
task.spawn(function()
    while task.wait(0.1) do
        if not CFG.Farm.BringPlayerBot then continue end
        if not LP.Character then continue end
        local myRoot = LP.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end
        for _, t in ipairs(GetBringList()) do
            local inst = t.inst
            local hrp = inst:FindFirstChild("HumanoidRootPart")
            local head = inst:FindFirstChild("Head")
            if not hrp or not head then continue end
            if not bringOffsets[inst] then
                bringOffsets[inst] = {
                    x = math.random(-CFG.Farm.BringSpread, CFG.Farm.BringSpread),
                    z = math.random(-CFG.Farm.BringSpread, CFG.Farm.BringSpread),
                }
            end
            local off = bringOffsets[inst]
            if CFG.Farm.BringPart == "Head Only" then
                pcall(function() head.CFrame = CFrame.new(Camera.CFrame.Position + Camera.CFrame.LookVector * CFG.Farm.BringJarak) * head.CFrame.Rotation end)
            elseif CFG.Farm.BringPart == "Full HRP" then
                local targetCF = myRoot.CFrame * CFrame.new(off.x, 0, -CFG.Farm.BringJarak + off.z)
                pcall(function() hrp.CFrame = targetCF end)
            elseif CFG.Farm.BringPart == "Both" then
                local targetCF = myRoot.CFrame * CFrame.new(off.x, 0, -CFG.Farm.BringJarak + off.z)
                pcall(function()
                    hrp.CFrame = targetCF
                    head.CFrame = CFrame.new(Camera.CFrame.Position + Camera.CFrame.LookVector * CFG.Farm.BringJarak) * head.CFrame.Rotation
                end)
            end
        end
        for inst, _ in pairs(bringOffsets) do
            if not inst or not inst.Parent then bringOffsets[inst] = nil end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not CFG.Farm.AnchorEnemy then continue end
        for _, t in ipairs(GetBringList()) do
            local hrp = t.inst:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.Anchored = true end) end
        end
    end
end)

local origSizes = {}
AddConn(RunService.Heartbeat:Connect(function()
    local targets = {}
    for _, t in ipairs(GetAllTargets()) do
        if CFG.Farm.HitboxTarget == "AllEnemy" and t.isEnemy then table.insert(targets, t.inst) end
        if CFG.Farm.HitboxTarget == "PlayerEnemy" and t.isPlayer and t.isEnemy then table.insert(targets, t.inst) end
        if CFG.Farm.HitboxTarget == "BotEnemy" and not t.isPlayer then table.insert(targets, t.inst) end
    end
    for _, inst in ipairs(targets) do
        local parts = {}
        if CFG.Farm.HitboxPart == "All" then
            for _, v in ipairs(inst:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then table.insert(parts, v) end
            end
        elseif CFG.Farm.HitboxPart == "Head" then
            local p = inst:FindFirstChild("Head"); if p then table.insert(parts, p) end
        elseif CFG.Farm.HitboxPart == "Body" then
            local p = inst:FindFirstChild("UpperTorso") or inst:FindFirstChild("Torso"); if p then table.insert(parts, p) end
        elseif CFG.Farm.HitboxPart == "Foot" then
            local p = inst:FindFirstChild("LeftFoot") or inst:FindFirstChild("RightFoot"); if p then table.insert(parts, p) end
        end
        for _, part in ipairs(parts) do
            if not origSizes[part] then origSizes[part] = part.Size end
            if CFG.Farm.HitboxExpander then
                part.Size = origSizes[part] * CFG.Farm.HitboxSize
                part.Transparency = 0.5; part.Massless = true; part.CanCollide = false
            else
                part.Size = origSizes[part]
            end
        end
    end
end))
task.spawn(function()
    while task.wait(30) do
        for part, _ in pairs(origSizes) do
            if not part or not part.Parent then origSizes[part] = nil end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--   LOAD CONFIG + BOOT
-- ═══════════════════════════════════════════════════════════════
pcall(function() Rayfield:LoadConfiguration() end)

print("━━━ RY ULTIMATE HYPERshot v4 (Gen 1 + Aqua) ━━━")
print("✅ Loaded | Team:", GetTeam(LP), "| Bots:", #GetBots())
print("📋 Tabs: 8 | Fitur: ~96")
print("🩵 Theme: Aqua")
print("📡 Remotes:", #AbilityRemotes, "| 🔫 Weapon Tables:", #weaponTables)
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
