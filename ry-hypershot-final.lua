-- ═══════════════════════════════════════════════════════════════
--   RY ULTIMATE HYPERshot — v9.6 FULL
--   By: ry-zeen | UI: Rayfield Gen 2 | Game: Hypershot
--   
--   FIX v9.6:
--   ✅ Aim Type dropdown (Camera/Mouse)
--   ✅ ESP Position dropdown works
--   ✅ Box Type dropdown works (2D/3D/Corner)
--   ✅ ESP Size sliders works
--   ✅ Config load disabled (biar gak nimpa)
--   ✅ Debug print di callback
--   ✅ Semua fitur v9.5.2 tetap ada
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TeleportSvc = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local Network = RS:WaitForChild("Network", 10)
local Remotes = Network and Network:WaitForChild("Remotes", 10)
local Shoot = Remotes and Remotes:FindFirstChild("Shoot")
local UseAbility = Remotes and Remotes:FindFirstChild("UseAbility")

local weaponTables = {}
local weaponOriginals = {}
local CDTables = {}
local bringOffsets = {}
local lockedSingleTarget = nil
local origSizes = {}
local espCache = {}
local rejoinAttempts = 0
local origNamecall = nil

local BLOCKED_REMOTES = {
    ReportPlayer = true,
    ReportIsPhone = true,
    BanWeaponVote = true,
    BanAbilityVote = true,
    RunAdminPanelCommand = true,
}

-- Hapus config lama (biar gak bug)
pcall(function()
    if delfile then
        for _, n in ipairs({"ry_ultimate_v91","ry_ultimate_v92","ry_ultimate_v93","ry_ultimate_v94","ry_ultimate_v95","ry_ultimate_v951","ry_ultimate_hypershot"}) do
            pcall(delfile, n)
        end
    end
end)

local CFG = {
    Protection = { Bypass=false, AntiKick=false, AntiFling=true, AntiDetect=false, AntiDataSend=false, AntiAFK=true },
    Performance = { BoostFPS=false, SetFPS=0, ShowFPSPing=false, RemoveParticle=false, RemoveShadow=false, RemoveEffect=false },
    Visual = {
        ESPPosition="Top", ESPMaxRadius=1000,
        ESPLine=false, ESPBox=false, ESPName=false, ESPHealth=false, ESPDistance=false,
        LineThickness=2, BoxThickness=2, ESPBoxType="2D", CornerLength=20,
        NameSize=14, DistanceSize=12, HealthBarWidth=6, HealthTextSize=12, DotRadius=3,
        PT_LineColor=Color3.fromRGB(0,170,255), PE_LineColor=Color3.fromRGB(255,60,60),
        BT_LineColor=Color3.fromRGB(0,255,100), BE_LineColor=Color3.fromRGB(255,220,0),
        BoxColor=Color3.fromRGB(255,150,200), NameColor=Color3.fromRGB(255,255,255),
        HealthColor=Color3.fromRGB(0,255,0), HealthColorMid=Color3.fromRGB(255,200,0),
        HealthColorLow=Color3.fromRGB(255,60,60), DistanceColor=Color3.fromRGB(255,255,255),
        Fullbright=false, Brightness=2, RemoveFog=false, FOV=70,
    },
    Combat = {
        Aimbot=false, Smoothness=5, AimTarget="AllEnemy", AimPart="Head", AimType="Camera",
        POVRadius=150, ShowPOV=false, POVColor=Color3.fromRGB(0,170,255),
        RageBot=false, AutoShoot=false, TeamCheck=true, WallCheck=false,
    },
    Player = {
        FastRegen=false, AntiVoid=false, AntiFling=true, AntiAFK=true,
        NoCooldown=false, CooldownValue=0, AbilitySpam=false,
        SelectedAbility="UseAbility (Universal)", SpamDelay=0.5, SpamTarget="All",
        SpeedHack=false, SpeedValue=25, JumpHack=false, JumpValue=60, InfiniteJump=false,
        NoClip=false, FlyHack=false, FlySpeed=50, Spinbot=false, SpinSpeed=500,
    },
    Weapon = {
        InfiniteAmmo=false, AmmoValue=0, RapidFire=false, FireRateMult=5,
        NoRecoil=false, NoSpread=false, DamageHack=false, DamageValue=999,
        RainbowBullets=false, BrightBullets=false, FatBullets=false,
    },
    Farm = {
        TpToPlayerBot=false, TpTarget="All", TpPosition="Depan", TpJarak=5, TpDelay=1,
        BringPlayerBot=false, BringMode="All", BringPart="Head Only", BringTarget="All",
        BringJarak=7, BringSpread=3, BringTeam=false, AnchorEnemy=false,
        HitboxExpander=false, HitboxSize=3, HitboxPart="All", HitboxTarget="AllEnemy",
    },
}

local ABILITY_LIST = {
    "UseAbility (Universal)","Reaper Dash","Energy Ward","Infinity Edge","StrongPunch",
    "Bouncepad","JumpPad","ThrowingDagger","Blast Grenade","Regen Splash","Sentry",
    "Smoke Orb","Ice Barrier","Geopillar","Gravity Well","Inferno Tornado",
    "Lightning Bolt","Photon Shield","Overdrive","Grappler","Glider","Dance Bomb",
    "Exploding Peels","Transcend","Rewind","Updraft","Tailwind","Arcane Fist","Volt Orb",
}

local function GetTeam(p) return p and p:GetAttribute("Team") end
local function GetCharTeam(c) return c and c:GetAttribute("Team") end

local function IsAlive(char)
    if not char or not char.Parent then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function IsEnemy(p)
    if p == LP then return false end
    if not p.Character or not IsAlive(p.Character) then return false end
    if CFG.Combat.TeamCheck then
        local mt = GetCharTeam(LP.Character) or GetTeam(LP)
        local tt = GetCharTeam(p.Character) or GetTeam(p)
        if mt ~= -1 and mt == tt then return false end
    end
    return true
end

local function GetBots()
    local l = {}
    for _, fn in ipairs({"Mobs","IgnoreThese","Enemies","NPCs","Bots"}) do
        local f = workspace:FindFirstChild(fn)
        if f then
            for _, b in ipairs(f:GetChildren()) do
                if IsAlive(b) then table.insert(l, b) end
            end
        end
    end
    return l
end

local function GetPart(inst, name)
    if not inst then return nil end
    local map = {Head="Head", Body="UpperTorso", Foot="LeftFoot", HumanoidRootPart="HumanoidRootPart", UpperTorso="UpperTorso"}
    local actual = map[name] or name
    local part = inst:FindFirstChild(actual)
    if part then return part end
    if name == "Body" then
        part = inst:FindFirstChild("Torso") or inst:FindFirstChild("UpperTorso")
    elseif name == "Foot" then
        part = inst:FindFirstChild("RightFoot") or inst:FindFirstChild("LeftFoot")
    end
    return part or inst:FindFirstChild("Head") or inst:FindFirstChild("HumanoidRootPart")
end

local function WallCheck(part)
    if not CFG.Combat.WallCheck then return true end
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {LP.Character, Camera}
    local r = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, p)
    return r == nil or r.Instance:IsDescendantOf(part.Parent)
end

local function GetAllTargets()
    local l = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and IsAlive(p.Character) then
            table.insert(l, {inst=p.Character, plr=p, isPlayer=true, isEnemy=IsEnemy(p)})
        end
    end
    for _, b in ipairs(GetBots()) do
        table.insert(l, {inst=b, plr=nil, isPlayer=false, isEnemy=true})
    end
    return l
end

local function GetHealthColor(r)
    if r > 0.6 then return CFG.Visual.HealthColor
    elseif r > 0.3 then return CFG.Visual.HealthColorMid
    else return CFG.Visual.HealthColorLow end
end

local Connections = {}
local function AddConn(c) table.insert(Connections, c); return c end

-- ═══ LOAD RAYFIELD ═══
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "RY ULTIMATE HYPERshot",
    subtitle = "v9.6 | by ry-zeen",
    sidebarLayout = true,
    configurationSaving = { enabled = false },  -- DISABLED biar gak bug
})

local function Notify(t, c, d) Rayfield:Notify({ title=t, content=c, duration=d or 5 }) end
local function Debug(t) print("[RY-DEBUG] " .. t) end

-- ═══ TAB 1: PROTECTION ═══
local ProtTab = Window:CreateTab({ name = "Protection", icon = "shield" })
ProtTab:CreateSection("Safe")
ProtTab:CreateToggle({ name="Bypass", currentValue=false, flag="P1",
    callback = function(v) CFG.Protection.Bypass=v end })
ProtTab:CreateToggle({ name="Anti Kick", currentValue=false, flag="P2",
    callback = function(v) CFG.Protection.AntiKick=v; if v then rejoinAttempts=0 end end })
ProtTab:CreateToggle({ name="Anti Fling", currentValue=true, flag="P3",
    callback = function(v) CFG.Protection.AntiFling=v end })
ProtTab:CreateToggle({ name="Anti Detect", currentValue=false, flag="P4",
    callback = function(v) CFG.Protection.AntiDetect=v end })
ProtTab:CreateToggle({ name="Anti Data Send", currentValue=false, flag="P5",
    callback = function(v) CFG.Protection.AntiDataSend=v end })
ProtTab:CreateToggle({ name="Anti AFK", currentValue=true, flag="P6",
    callback = function(v) CFG.Protection.AntiAFK=v end })

-- ═══ TAB 2: PERFORMANCE ═══
local PerfTab = Window:CreateTab({ name = "Performance", icon = "zap" })
PerfTab:CreateSection("Boost")
PerfTab:CreateToggle({ name="Boost FPS", currentValue=false, flag="E1",
    callback = function(v)
        CFG.Performance.BoostFPS=v
        if v then
            Lighting.GlobalShadows=false
            Lighting.FogEnd=9e9
            for _,o in ipairs(Lighting:GetChildren()) do
                if o:IsA("PostEffect") or o:IsA("Atmosphere") or o:IsA("Sky") then o.Enabled=false end
            end
        end
    end })
PerfTab:CreateDropdown({ name="Set FPS Cap", options={"Off","30","60","90","120","144"}, currentOption={"Off"}, flag="E2",
    callback = function(o)
        if o[1]=="Off" then
            CFG.Performance.SetFPS=0
            if setfpscap then pcall(setfpscap, 9999) end
        else
            local c=tonumber(o[1]) or 60
            CFG.Performance.SetFPS=c
            if setfpscap then pcall(setfpscap, c) end
        end
        Debug("FPS Cap: " .. o[1])
    end })
PerfTab:CreateToggle({ name="Show FPS & PING", currentValue=false, flag="E4",
    callback = function(v)
        CFG.Performance.ShowFPSPing=v
        if not v and _G.RY_LABEL then _G.RY_LABEL:Remove(); _G.RY_LABEL=nil end
    end })
PerfTab:CreateSection("Remove")
PerfTab:CreateToggle({ name="Remove Particle", currentValue=false, flag="E5",
    callback = function(v) CFG.Performance.RemoveParticle=v end })
PerfTab:CreateToggle({ name="Remove Shadow", currentValue=false, flag="E6",
    callback = function(v) CFG.Performance.RemoveShadow=v end })
PerfTab:CreateToggle({ name="Remove Effect", currentValue=false, flag="E7",
    callback = function(v) CFG.Performance.RemoveEffect=v end })

-- ═══ TAB 3: VISUAL ═══
local VisTab = Window:CreateTab({ name = "Visual", icon = "eye" })

VisTab:CreateSection("ESP-Manager")
VisTab:CreateDropdown({ name="ESP Position", options={"Top","Center","Bottom"}, currentOption={"Top"}, flag="V1",
    callback = function(o) 
        CFG.Visual.ESPPosition=o[1]
        Debug("ESP Position changed: " .. o[1])
        Notify("ESP Position", o[1], 3)
    end })
VisTab:CreateSlider({ name="ESP Max Radius", range={0,10000}, increment=100, suffix="m", currentValue=1000, flag="V2",
    callback = function(v) CFG.Visual.ESPMaxRadius=v; Debug("ESP Radius: " .. v) end })

VisTab:CreateSection("ESP-Master")
VisTab:CreateToggle({ name="ESP Line", currentValue=false, flag="V3", 
    callback=function(v) CFG.Visual.ESPLine=v; Debug("ESP Line: " .. tostring(v)) end })
VisTab:CreateToggle({ name="ESP Box", currentValue=false, flag="V4", 
    callback=function(v) CFG.Visual.ESPBox=v; Debug("ESP Box: " .. tostring(v)) end })
VisTab:CreateToggle({ name="ESP Name", currentValue=false, flag="V5", 
    callback=function(v) CFG.Visual.ESPName=v end })
VisTab:CreateToggle({ name="ESP Health", currentValue=false, flag="V6", 
    callback=function(v) CFG.Visual.ESPHealth=v end })
VisTab:CreateToggle({ name="ESP Distance", currentValue=false, flag="V7", 
    callback=function(v) CFG.Visual.ESPDistance=v end })

VisTab:CreateSection("ESP-Setting")
VisTab:CreateSlider({ name="Line Thickness", range={1,10}, increment=1, suffix="px", currentValue=2, flag="V8",
    callback=function(v) CFG.Visual.LineThickness=v; Debug("Line Thickness: " .. v) end })
VisTab:CreateSlider({ name="Box Thickness", range={1,10}, increment=1, suffix="px", currentValue=2, flag="V9",
    callback=function(v) CFG.Visual.BoxThickness=v; Debug("Box Thickness: " .. v) end })
VisTab:CreateDropdown({ name="Box Type", options={"2D","3D","Corner"}, currentOption={"2D"}, flag="V10",
    callback=function(o) 
        CFG.Visual.ESPBoxType=o[1]
        Debug("Box Type changed: " .. o[1])
        Notify("Box Type", o[1], 3)
    end })
VisTab:CreateSlider({ name="Corner Length", range={5,50}, increment=1, suffix="px", currentValue=20, flag="V11",
    callback=function(v) CFG.Visual.CornerLength=v end })
VisTab:CreateSlider({ name="Name Size", range={10,30}, increment=1, suffix="pt", currentValue=14, flag="V12",
    callback=function(v) CFG.Visual.NameSize=v; Debug("Name Size: " .. v) end })
VisTab:CreateSlider({ name="Distance Size", range={10,30}, increment=1, suffix="pt", currentValue=12, flag="V13",
    callback=function(v) CFG.Visual.DistanceSize=v; Debug("Distance Size: " .. v) end })
VisTab:CreateSlider({ name="Health Bar Width", range={3,15}, increment=1, suffix="px", currentValue=6, flag="V14",
    callback=function(v) CFG.Visual.HealthBarWidth=v end })
VisTab:CreateSlider({ name="Health Text Size", range={8,20}, increment=1, suffix="pt", currentValue=12, flag="V15",
    callback=function(v) CFG.Visual.HealthTextSize=v end })
VisTab:CreateSlider({ name="Dot Radius", range={1,10}, increment=1, suffix="px", currentValue=3, flag="V16",
    callback=function(v) CFG.Visual.DotRadius=v end })

VisTab:CreateSection("ESP-Color")
VisTab:CreateColorPicker({ name="Player Team Line", color=Color3.fromRGB(0,170,255), flag="V17",
    callback=function(c) CFG.Visual.PT_LineColor=c end })
VisTab:CreateColorPicker({ name="Player Enemy Line", color=Color3.fromRGB(255,60,60), flag="V18",
    callback=function(c) CFG.Visual.PE_LineColor=c end })
VisTab:CreateColorPicker({ name="Bot Team Line", color=Color3.fromRGB(0,255,100), flag="V19",
    callback=function(c) CFG.Visual.BT_LineColor=c end })
VisTab:CreateColorPicker({ name="Bot Enemy Line", color=Color3.fromRGB(255,220,0), flag="V20",
    callback=function(c) CFG.Visual.BE_LineColor=c end })
VisTab:CreateColorPicker({ name="Box Color", color=Color3.fromRGB(255,150,200), flag="V21",
    callback=function(c) CFG.Visual.BoxColor=c end })
VisTab:CreateColorPicker({ name="Name Color", color=Color3.fromRGB(255,255,255), flag="V22",
    callback=function(c) CFG.Visual.NameColor=c end })
VisTab:CreateColorPicker({ name="Health Color (High)", color=Color3.fromRGB(0,255,0), flag="V23",
    callback=function(c) CFG.Visual.HealthColor=c end })
VisTab:CreateColorPicker({ name="Health Color (Mid)", color=Color3.fromRGB(255,200,0), flag="V24",
    callback=function(c) CFG.Visual.HealthColorMid=c end })
VisTab:CreateColorPicker({ name="Health Color (Low)", color=Color3.fromRGB(255,60,60), flag="V25",
    callback=function(c) CFG.Visual.HealthColorLow=c end })
VisTab:CreateColorPicker({ name="Distance Color", color=Color3.fromRGB(255,255,255), flag="V26",
    callback=function(c) CFG.Visual.DistanceColor=c end })

VisTab:CreateSection("World")
VisTab:CreateToggle({ name="Fullbright", currentValue=false, flag="V27",
    callback=function(v)
        CFG.Visual.Fullbright=v
        if v then Lighting.ClockTime=12; Lighting.GlobalShadows=false
        else Lighting.GlobalShadows=true end
    end })
VisTab:CreateSlider({ name="Brightness", range={0,10}, increment=0.5, suffix="x", currentValue=2, flag="V28",
    callback=function(v) CFG.Visual.Brightness=v; Lighting.Brightness=v end })
VisTab:CreateToggle({ name="Remove Fog", currentValue=false, flag="V29",
    callback=function(v) CFG.Visual.RemoveFog=v; Lighting.FogEnd=v and 9e9 or 100000 end })
VisTab:CreateSlider({ name="FOV Changer", range={70,120}, increment=5, suffix="", currentValue=70, flag="V30",
    callback=function(v) CFG.Visual.FOV=v; Camera.FieldOfView=v end })

-- ═══ TAB 4: COMBAT ═══
local ComTab = Window:CreateTab({ name = "Combat", icon = "sword" })

ComTab:CreateSection("Aimbot")
ComTab:CreateToggle({ name="Aimbot", currentValue=false, flag="C1", 
    callback=function(v) CFG.Combat.Aimbot=v end })
ComTab:CreateSlider({ name="Aim Smoothness", range={0,20}, increment=1, suffix="x", currentValue=5, flag="C2",
    callback=function(v) CFG.Combat.Smoothness=v end })

-- FIX: AIM TYPE DROPDOWN
ComTab:CreateDropdown({ name="Aim Type", options={"Camera","Mouse"}, currentOption={"Camera"}, flag="C_AimType",
    callback=function(o) 
        CFG.Combat.AimType = o[1]
        Debug("Aim Type: " .. o[1])
        Notify("Aim Type", o[1], 3)
    end })

ComTab:CreateDropdown({ name="Aim Target", options={"AllEnemy","PlayerEnemy","BotEnemy"}, currentOption={"AllEnemy"}, flag="C3",
    callback=function(o) CFG.Combat.AimTarget=o[1] end })
ComTab:CreateDropdown({ name="Aim Part", options={"Head","Body","Foot"}, currentOption={"Head"}, flag="C4",
    callback=function(o) CFG.Combat.AimPart=o[1]; Debug("Aim Part: " .. o[1]) end })

ComTab:CreateSection("POV Circle")
ComTab:CreateSlider({ name="POV Radius", range={50,500}, increment=10, suffix="px", currentValue=150, flag="C5",
    callback=function(v) CFG.Combat.POVRadius=v end })
ComTab:CreateToggle({ name="Show POV", currentValue=false, flag="C6", 
    callback=function(v) CFG.Combat.ShowPOV=v end })
ComTab:CreateColorPicker({ name="POV Color", color=Color3.fromRGB(0,170,255), flag="C7",
    callback=function(c) CFG.Combat.POVColor=c end })

ComTab:CreateSection("Rage Mode")
ComTab:CreateToggle({ name="RageBot (Brutal)", currentValue=false, flag="C8", 
    callback=function(v) CFG.Combat.RageBot=v end })
ComTab:CreateToggle({ name="Auto Shoot", currentValue=false, flag="C9", 
    callback=function(v) CFG.Combat.AutoShoot=v end })

ComTab:CreateSection("Filter")
ComTab:CreateToggle({ name="Team Check", currentValue=true, flag="C10", 
    callback=function(v) CFG.Combat.TeamCheck=v end })
ComTab:CreateToggle({ name="Wall Check", currentValue=false, flag="C11", 
    callback=function(v) CFG.Combat.WallCheck=v end })

-- ═══ TAB 5: PLAYER ═══
local PlrTab = Window:CreateTab({ name = "Player", icon = "user" })

PlrTab:CreateSection("Survival")
PlrTab:CreateToggle({ name="Fast Regen", currentValue=false, flag="A1", 
    callback=function(v) CFG.Player.FastRegen=v end })
PlrTab:CreateToggle({ name="Anti Void", currentValue=false, flag="A2", 
    callback=function(v) CFG.Player.AntiVoid=v end })
PlrTab:CreateToggle({ name="Anti Fling", currentValue=true, flag="A3", 
    callback=function(v) CFG.Player.AntiFling=v end })
PlrTab:CreateToggle({ name="Anti AFK", currentValue=true, flag="A4", 
    callback=function(v) CFG.Player.AntiAFK=v end })

PlrTab:CreateSection("Ability")
PlrTab:CreateToggle({ name="No Cooldown", currentValue=false, flag="A5",
    callback=function(v) CFG.Player.NoCooldown=v; if v then Notify("Ability", "No CD ON", 3) end end })
PlrTab:CreateSlider({ name="Cooldown Value", range={0,100}, increment=1, suffix="", currentValue=0, flag="A6",
    callback=function(v) CFG.Player.CooldownValue=v end })
PlrTab:CreateToggle({ name="Ability Spam", currentValue=false, flag="A7",
    callback=function(v) CFG.Player.AbilitySpam=v; if v then Notify("Ability", "Spam ON", 3) end end })
PlrTab:CreateDropdown({ name="Ability Selector", options=ABILITY_LIST, currentOption={"UseAbility (Universal)"}, flag="A8",
    callback=function(o) CFG.Player.SelectedAbility=o[1]; Debug("Ability: " .. o[1]); Notify("Ability", o[1], 3) end })
PlrTab:CreateSlider({ name="Spam Delay", range={0.5,5}, increment=0.1, suffix="s", currentValue=0.5, flag="A9",
    callback=function(v) CFG.Player.SpamDelay=v end })
PlrTab:CreateDropdown({ name="Spam Target", options={"All","PlayerOnly","BotOnly","Self"}, currentOption={"All"}, flag="A10",
    callback=function(o) CFG.Player.SpamTarget=o[1] end })

PlrTab:CreateSection("Speed")
PlrTab:CreateToggle({ name="Speed Hack", currentValue=false, flag="A11",
    callback=function(v)
        CFG.Player.SpeedHack=v
        if LP.Character then
            local h=LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=v and CFG.Player.SpeedValue or 16 end
        end
    end })
PlrTab:CreateSlider({ name="Speed Value", range={16,100}, increment=1, suffix=" spd", currentValue=25, flag="A12",
    callback=function(v)
        CFG.Player.SpeedValue=v
        if CFG.Player.SpeedHack and LP.Character then
            local h=LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=v end
        end
    end })

PlrTab:CreateSection("Jump")
PlrTab:CreateToggle({ name="Jump Hack", currentValue=false, flag="A13",
    callback=function(v)
        CFG.Player.JumpHack=v
        if LP.Character then
            local h=LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower=true; h.JumpPower=v and CFG.Player.JumpValue or 50 end
        end
    end })
PlrTab:CreateSlider({ name="Jump Value", range={50,300}, increment=5, suffix=" jp", currentValue=60, flag="A14",
    callback=function(v)
        CFG.Player.JumpValue=v
        if CFG.Player.JumpHack and LP.Character then
            local h=LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower=true; h.JumpPower=v end
        end
    end })
PlrTab:CreateToggle({ name="Infinity Jump", currentValue=false, flag="A15", 
    callback=function(v) CFG.Player.InfiniteJump=v end })

PlrTab:CreateSection("Movement")
PlrTab:CreateToggle({ name="No Clip", currentValue=false, flag="A16", 
    callback=function(v) CFG.Player.NoClip=v end })
PlrTab:CreateToggle({ name="Fly Hack", currentValue=false, flag="A17", 
    callback=function(v) CFG.Player.FlyHack=v end })
PlrTab:CreateSlider({ name="Fly Speed", range={10,200}, increment=5, suffix=" spd", currentValue=50, flag="A18",
    callback=function(v) CFG.Player.FlySpeed=v end })
PlrTab:CreateToggle({ name="Spinbot", currentValue=false, flag="A19", 
    callback=function(v) CFG.Player.Spinbot=v end })
PlrTab:CreateSlider({ name="Spin Speed", range={100,1000}, increment=10, suffix=" spd", currentValue=500, flag="A20",
    callback=function(v) CFG.Player.SpinSpeed=v end })

-- ═══ TAB 6: WEAPON ═══
local WepTab = Window:CreateTab({ name = "Weapon", icon = "crosshair" })

WepTab:CreateSection("Ammo")
WepTab:CreateToggle({ name="Infinite Ammo", currentValue=false, flag="W1", 
    callback=function(v) CFG.Weapon.InfiniteAmmo=v end })
WepTab:CreateSlider({ name="Ammo Value", range={0,5677865}, increment=100, suffix="", currentValue=0, flag="W2",
    callback=function(v) CFG.Weapon.AmmoValue=v end })

WepTab:CreateSection("Fire Rate")
WepTab:CreateToggle({ name="Rapid Fire", currentValue=false, flag="W3", 
    callback=function(v) CFG.Weapon.RapidFire=v end })
WepTab:CreateSlider({ name="Fire Rate Multiplier", range={1,100}, increment=1, suffix="x", currentValue=5, flag="W4",
    callback=function(v) CFG.Weapon.FireRateMult=v end })

WepTab:CreateSection("Accuracy")
WepTab:CreateToggle({ name="No Recoil", currentValue=false, flag="W5", 
    callback=function(v) CFG.Weapon.NoRecoil=v end })
WepTab:CreateToggle({ name="No Spread", currentValue=false, flag="W6", 
    callback=function(v) CFG.Weapon.NoSpread=v end })

WepTab:CreateSection("Damage")
WepTab:CreateToggle({ name="Damage Hack", currentValue=false, flag="W7", 
    callback=function(v) CFG.Weapon.DamageHack=v end })
WepTab:CreateSlider({ name="Damage Value (HeadDamage)", range={100,99999}, increment=100, suffix=" dmg", currentValue=999, flag="W8",
    callback=function(v) CFG.Weapon.DamageValue=v end })

WepTab:CreateSection("Bullet Visual")
WepTab:CreateToggle({ name="Rainbow Bullets", currentValue=false, flag="W9", 
    callback=function(v) CFG.Weapon.RainbowBullets=v end })
WepTab:CreateToggle({ name="Bright Bullets", currentValue=false, flag="W10", 
    callback=function(v) CFG.Weapon.BrightBullets=v end })
WepTab:CreateToggle({ name="Fat Bullets", currentValue=false, flag="W11", 
    callback=function(v) CFG.Weapon.FatBullets=v end })

-- ═══ TAB 7: FARM ═══
local FarmTab = Window:CreateTab({ name = "Farm", icon = "target" })

FarmTab:CreateSection("Telekill")
FarmTab:CreateToggle({ name="Tp To Player & Bot", currentValue=false, flag="F1", 
    callback=function(v) CFG.Farm.TpToPlayerBot=v end })
FarmTab:CreateDropdown({ name="Tp Target", options={"All","PlayerOnly","BotOnly"}, currentOption={"All"}, flag="F2",
    callback=function(o) CFG.Farm.TpTarget=o[1] end })
FarmTab:CreateDropdown({ name="Tp Position", options={"Depan","Belakang","Atas","Bawah"}, currentOption={"Depan"}, flag="F3",
    callback=function(o) CFG.Farm.TpPosition=o[1] end })
FarmTab:CreateSlider({ name="Tp Jarak", range={0,100}, increment=1, suffix=" studs", currentValue=5, flag="F4",
    callback=function(v) CFG.Farm.TpJarak=v end })
FarmTab:CreateSlider({ name="Tp Delay", range={0,100}, increment=1, suffix="ms", currentValue=1, flag="F5",
    callback=function(v) CFG.Farm.TpDelay=v end })

FarmTab:CreateSection("Bring Player & Bot")
FarmTab:CreateToggle({ name="Bring Player & Bot", currentValue=false, flag="F6", 
    callback=function(v) CFG.Farm.BringPlayerBot=v end })
FarmTab:CreateDropdown({ name="Bring Mode", options={"All","Single"}, currentOption={"All"}, flag="F7",
    callback=function(o) CFG.Farm.BringMode=o[1]; lockedSingleTarget=nil; Notify("Bring Mode", o[1], 3) end })
FarmTab:CreateDropdown({ name="Bring Part", options={"Head Only","Full HRP","Both"}, currentOption={"Head Only"}, flag="F8",
    callback=function(o) CFG.Farm.BringPart=o[1] end })
FarmTab:CreateDropdown({ name="Bring Target", options={"All","PlayerOnly","BotOnly"}, currentOption={"All"}, flag="F9",
    callback=function(o) CFG.Farm.BringTarget=o[1] end })
FarmTab:CreateSlider({ name="Bring Jarak", range={0,100}, increment=1, suffix=" studs", currentValue=7, flag="F10",
    callback=function(v) CFG.Farm.BringJarak=v end })
FarmTab:CreateSlider({ name="Bring Spread", range={1,10}, increment=1, suffix="", currentValue=3, flag="F11",
    callback=function(v) CFG.Farm.BringSpread=v end })
FarmTab:CreateToggle({ name="Bring Team", currentValue=false, flag="F12", 
    callback=function(v) CFG.Farm.BringTeam=v end })
FarmTab:CreateToggle({ name="Anchor Enemy", currentValue=false, flag="F13",
    callback=function(v)
        CFG.Farm.AnchorEnemy=v
        if not v then
            for _, t in ipairs(GetAllTargets()) do
                local hrp=t.inst:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.Anchored=false end) end
            end
        end
    end })

FarmTab:CreateSection("Hitbox Expander")
FarmTab:CreateToggle({ name="Hitbox Expander", currentValue=false, flag="F14", 
    callback=function(v) CFG.Farm.HitboxExpander=v end })
FarmTab:CreateSlider({ name="Hitbox Size", range={1,10}, increment=1, suffix="x", currentValue=3, flag="F15",
    callback=function(v) CFG.Farm.HitboxSize=v end })
FarmTab:CreateDropdown({ name="Hitbox Part", options={"All","Head","Body","Foot"}, currentOption={"All"}, flag="F16",
    callback=function(o) CFG.Farm.HitboxPart=o[1] end })
FarmTab:CreateDropdown({ name="Hitbox Target", options={"AllEnemy","PlayerEnemy","BotEnemy"}, currentOption={"AllEnemy"}, flag="F17",
    callback=function(o) CFG.Farm.HitboxTarget=o[1] end })

-- ═══ TAB 8: SERVER ═══
local SrvTab = Window:CreateTab({ name = "Server", icon = "globe" })

SrvTab:CreateSection("Utility")
SrvTab:CreateButton({ name="Server Hop (Random)",
    callback=function()
        Notify("Server Hop", "Cari server baru...", 3)
        task.spawn(function()
            local ok, d = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
            end)
            if ok and d and d.data then
                local l = {}
                for _, s in ipairs(d.data) do
                    if s.playing<s.maxPlayers and s.id~=game.JobId then table.insert(l,s.id) end
                end
                if #l>0 then TeleportSvc:TeleportToPlaceInstance(game.PlaceId, l[math.random(1,#l)], LP)
                else Notify("Server Hop", "Nggak ada server", 4) end
            else Notify("Server Hop", "Gagal ambil list", 4) end
        end)
    end })
SrvTab:CreateButton({ name="Rejoin Server",
    callback=function() Notify("Rejoin", "Rejoining...", 3); TeleportSvc:Teleport(game.PlaceId, LP) end })
SrvTab:CreateButton({ name="Unload Script",
    callback=function()
        for _, t in ipairs(GetAllTargets()) do
            local hrp=t.inst:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.Anchored=false end) end
        end
        for _, v in ipairs(weaponTables) do
            local o=weaponOriginals[v]
            if o then
                pcall(function()
                    for k,val in pairs(o) do
                        if val~=nil then rawset(v,k,val) end
                    end
                end)
            end
        end
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        Connections = {}
        if _G.RY_LABEL then pcall(function() _G.RY_LABEL:Remove() end); _G.RY_LABEL=nil end
        pcall(function() Rayfield:Destroy() end)
    end })

-- ═══════════════════════════════════════════════════════════════
--   CORE LOGIC
-- ═══════════════════════════════════════════════════════════════

local pov
if Drawing then
    pov = Drawing.new("Circle")
    pov.Thickness=1; pov.NumSides=64; pov.Filled=false; pov.Transparency=1
end
AddConn(RunService.RenderStepped:Connect(function()
    if pov then
        pov.Radius=CFG.Combat.POVRadius
        pov.Color=CFG.Combat.POVColor
        pov.Visible=CFG.Combat.ShowPOV
        pov.Position=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end))

local lc = os.clock()
AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Performance.ShowFPSPing then return end
    if not Drawing then return end
    if not _G.RY_LABEL then
        local l = Drawing.new("Text")
        l.Size=16; l.Position=Vector2.new(10,30)
        l.Color=Color3.fromRGB(0,255,100); l.Outline=true; l.Visible=true
        _G.RY_LABEL=l
    end
    local n=os.clock()
    local d=n-lc
    lc=n
    local fps=d>0 and math.floor(1/d) or 0
    local ping=0
    pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    _G.RY_LABEL.Text=string.format("FPS: %d | PING: %dms", fps, ping)
end))

AddConn(LP.Idled:Connect(function()
    if CFG.Protection.AntiAFK or CFG.Player.AntiAFK then
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end)
    end
end))

AddConn(RunService.Stepped:Connect(function()
    if not CFG.Protection.AntiFling and not CFG.Player.AntiFling then return end
    if not LP.Character then return end
    local hrp=LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.AssemblyLinearVelocity.Magnitude>200 then
        hrp.AssemblyLinearVelocity=Vector3.zero
        hrp.AssemblyAngularVelocity=Vector3.zero
    end
end))

AddConn(Players.PlayerRemoving:Connect(function(p)
    if p~=LP or not CFG.Protection.AntiKick then return end
    if rejoinAttempts>=3 then Notify("Anti Kick","Gagal 3x.",10); return end
    rejoinAttempts=rejoinAttempts+1
    Notify("Anti Kick","Rejoin "..rejoinAttempts.."/3",5)
    task.wait(5)
    pcall(function() TeleportSvc:Teleport(game.PlaceId, LP) end)
end))

-- Anti Detect
task.spawn(function()
    while task.wait(2) do
        if not CFG.Protection.AntiDetect then continue end
        pcall(function()
            local parent = (gethui and gethui()) or CoreGui
            for _, v in ipairs(parent:GetChildren()) do
                if v:IsA("ScreenGui") and v.Name:lower():find("rayfield") then v.Name="Settings" end
            end
        end)
    end
end)

-- Anti Data Send
task.spawn(function()
    while task.wait(2) do
        if not CFG.Protection.AntiDataSend then continue end
        pcall(function()
            if not origNamecall and hookmetamethod then
                origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    if getnamecallmethod()=="FireServer" and typeof(self)=="Instance" then
                        if BLOCKED_REMOTES[self.Name] then return end
                    end
                    return origNamecall(self, ...)
                end)
            end
        end)
    end
end)

-- Remove Particle/Shadow/Effect
task.spawn(function()
    while task.wait(5) do
        if CFG.Performance.RemoveParticle then
            pcall(function()
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled=false end
                end
            end)
        end
        if CFG.Performance.RemoveShadow then
            pcall(function()
                Lighting.GlobalShadows=false
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then v.CastShadow=false end
                end
            end)
        end
        if CFG.Performance.RemoveEffect then
            pcall(function()
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("Beam") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end
                end
            end)
        end
    end
end)

-- Aimbot
local function GetAimTargets()
    local l = {}
    if CFG.Combat.AimTarget=="AllEnemy" or CFG.Combat.AimTarget=="PlayerEnemy" then
        for _, p in ipairs(Players:GetPlayers()) do
            if IsEnemy(p) then table.insert(l, {inst=p.Character, isPlayer=true}) end
        end
    end
    if CFG.Combat.AimTarget=="AllEnemy" or CFG.Combat.AimTarget=="BotEnemy" then
        for _, b in ipairs(GetBots()) do
            if IsAlive(b) then table.insert(l, {inst=b, isPlayer=false}) end
        end
    end
    return l
end

local function FindClosest()
    local cl, dist = nil, math.huge
    local ctr = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, t in ipairs(GetAimTargets()) do
        if IsAlive(t.inst) then
            local p = GetPart(t.inst, CFG.Combat.AimPart)
            if p and p.Parent then
                local sp, on = Camera:WorldToViewportPoint(p.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - ctr).Magnitude
                    if d < CFG.Combat.POVRadius and d < dist and WallCheck(p) then
                        cl, dist = t, d
                    end
                end
            end
        end
    end
    return cl
end

AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Combat.Aimbot and not CFG.Combat.RageBot then return end
    local t = FindClosest()
    if not t then return end
    if not IsAlive(t.inst) then return end
    local p = GetPart(t.inst, CFG.Combat.AimPart)
    if not p or not p.Parent then return end
    if CFG.Combat.RageBot then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, p.Position)
        if CFG.Combat.AutoShoot and Shoot then pcall(function() Shoot:FireServer(p) end) end
    else
        local s = CFG.Combat.Smoothness>0 and CFG.Combat.Smoothness or 1
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, p.Position), 1/s)
    end
end))

-- ═══ ESP RENDER v9.6 ═══
local function CreateESP(inst)
    if espCache[inst] then return espCache[inst] end
    local d = {}
    if Drawing then
        d.line=Drawing.new("Line")
        d.line.Thickness=2; d.line.Transparency=1; d.line.Visible=false
        d.dot=Drawing.new("Circle")
        d.dot.Thickness=1; d.dot.Filled=true; d.dot.NumSides=12
        d.dot.Radius=3; d.dot.Transparency=1; d.dot.Visible=false
        d.box=Drawing.new("Square")
        d.box.Thickness=2; d.box.Filled=false; d.box.Transparency=1; d.box.Visible=false
        d.sep1=Drawing.new("Line")
        d.sep1.Thickness=2; d.sep1.Transparency=1; d.sep1.Visible=false
        d.sep2=Drawing.new("Line")
        d.sep2.Thickness=2; d.sep2.Transparency=1; d.sep2.Visible=false
        d.name=Drawing.new("Text")
        d.name.Size=14; d.name.Center=true; d.name.Outline=true
        d.name.Transparency=1; d.name.Visible=false
        d.dist=Drawing.new("Text")
        d.dist.Size=12; d.dist.Center=true; d.dist.Outline=true
        d.dist.Transparency=1; d.dist.Visible=false
        d.hBG=Drawing.new("Square")
        d.hBG.Thickness=0; d.hBG.Filled=true
        d.hBG.Transparency=0.7; d.hBG.Visible=false
        d.hBG.Color=Color3.fromRGB(50,50,50)
        d.hBar=Drawing.new("Square")
        d.hBar.Thickness=0; d.hBar.Filled=true
        d.hBar.Transparency=1; d.hBar.Visible=false
        d.hTxt=Drawing.new("Text")
        d.hTxt.Size=12; d.hTxt.Center=true; d.hTxt.Outline=true
        d.hTxt.Transparency=1; d.hTxt.Visible=false
        d.b3D={}
        for i=1,12 do
            local e=Drawing.new("Line")
            e.Thickness=1; e.Transparency=1; e.Visible=false
            d.b3D[i]=e
        end
        d.cor={}
        for i=1,8 do
            local e=Drawing.new("Line")
            e.Thickness=2; e.Transparency=1; e.Visible=false
            d.cor[i]=e
        end
    end
    espCache[inst]=d
    return d
end

local function RemoveESP(inst)
    local d = espCache[inst]
    if d then
        for _, o in pairs(d) do
            if typeof(o)=="userdata" then pcall(function() o.Visible=false; o:Remove() end)
            elseif type(o)=="table" then
                for _, s in pairs(o) do
                    if typeof(s)=="userdata" then pcall(function() s.Visible=false; s:Remove() end) end
                end
            end
        end
        espCache[inst]=nil
    end
end

local function HideESP(inst)
    local d = espCache[inst]
    if d then
        for _, o in pairs(d) do
            if typeof(o)=="userdata" then pcall(function() o.Visible=false end)
            elseif type(o)=="table" then
                for _, s in pairs(o) do if typeof(s)=="userdata" then pcall(function() s.Visible=false end) end end
            end
        end
    end
end

local function RenderESP(inst, isPlayer, isTeammate, isEnemy)
    if not Drawing then return end
    if not IsAlive(inst) then RemoveESP(inst); return end
    local d = CreateESP(inst)
    local hrp=inst:FindFirstChild("HumanoidRootPart")
    local head=inst:FindFirstChild("Head")
    local hum=inst:FindFirstChildOfClass("Humanoid")
    if not hrp or not head or not hum then HideESP(inst); return end

    -- ESP Max Radius
    local refPos = (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character:FindFirstChild("HumanoidRootPart").Position) or Camera.CFrame.Position
    local dd = (hrp.Position - refPos).Magnitude
    if CFG.Visual.ESPMaxRadius > 0 and dd > CFG.Visual.ESPMaxRadius then HideESP(inst); return end

    local hp, on = Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
    local rp = Camera:WorldToViewportPoint(hrp.Position)
    if not on then HideESP(inst); return end

    local bH=math.abs(hp.Y-rp.Y)*2
    local bW=bH/2
    local bT=hp.Y
    local bB=hp.Y+bH
    local bL=hp.X-bW/2
    local bR=hp.X+bW/2

    local lc
    if isPlayer and isTeammate then lc=CFG.Visual.PT_LineColor
    elseif not isPlayer and isTeammate then lc=CFG.Visual.BT_LineColor
    elseif isPlayer and isEnemy then lc=CFG.Visual.PE_LineColor
    else lc=CFG.Visual.BE_LineColor end

    -- LINE
    if d.line then
        if CFG.Visual.ESPLine then
            local oX=Camera.ViewportSize.X/2
            local oY
            -- Baca CFG tiap frame (biar dropdown works)
            local pos = CFG.Visual.ESPPosition
            if pos=="Top" then oY=0
            elseif pos=="Center" then oY=Camera.ViewportSize.Y/2
            else oY=Camera.ViewportSize.Y end
            d.line.Visible=true
            d.line.Color=lc
            d.line.Thickness=CFG.Visual.LineThickness
            d.line.From=Vector2.new(oX,oY)
            d.line.To=Vector2.new(hp.X,bT)
        else d.line.Visible=false end
    end

    -- DOT
    if d.dot then
        if CFG.Visual.ESPLine then
            d.dot.Visible=true
            d.dot.Color=CFG.Visual.BoxColor
            d.dot.Radius=CFG.Visual.DotRadius
            d.dot.Position=Vector2.new(hp.X,bT)
        else d.dot.Visible=false end
    end

    -- Reset all box types
    if d.box then d.box.Visible=false end
    if d.b3D then for i=1,12 do d.b3D[i].Visible=false end end
    if d.cor then for i=1,8 do d.cor[i].Visible=false end end

    -- BOX
    if CFG.Visual.ESPBox then
        local bt = CFG.Visual.ESPBoxType
        if bt=="2D" and d.box then
            d.box.Visible=true
            d.box.Color=CFG.Visual.BoxColor
            d.box.Thickness=CFG.Visual.BoxThickness
            d.box.Size=Vector2.new(bW,bH)
            d.box.Position=Vector2.new(bL,bT)
        elseif bt=="3D" then
            local cf=hrp.CFrame
            local rv=cf.RightVector
            local lv=cf.LookVector
            local t3=head.Position.Y+0.5
            local b3=hrp.Position.Y-2.5
            local h3=t3-b3
            local hh=h3/2
            local hw=1.5
            local hd=1.0
            local cc=Vector3.new(hrp.Position.X,(t3+b3)/2,hrp.Position.Z)
            local cs={
                cc-rv*hw-lv*hd-Vector3.new(0,hh,0),
                cc+rv*hw-lv*hd-Vector3.new(0,hh,0),
                cc+rv*hw+lv*hd-Vector3.new(0,hh,0),
                cc-rv*hw+lv*hd-Vector3.new(0,hh,0),
                cc-rv*hw-lv*hd+Vector3.new(0,hh,0),
                cc+rv*hw-lv*hd+Vector3.new(0,hh,0),
                cc+rv*hw+lv*hd+Vector3.new(0,hh,0),
                cc-rv*hw+lv*hd+Vector3.new(0,hh,0),
            }
            local pr={}
            local visible={}
            for i,w in ipairs(cs) do
                local camSpace = Camera.CFrame:PointToObjectSpace(w)
                if camSpace.Z < 0 then
                    local sp = Camera:WorldToViewportPoint(w)
                    pr[i]=Vector2.new(sp.X,sp.Y)
                    visible[i]=true
                else visible[i]=false end
            end
            local ed={
                {1,2},{2,3},{3,4},{4,1},
                {5,6},{6,7},{7,8},{8,5},
                {1,5},{2,6},{3,7},{4,8},
            }
            for i,e in ipairs(ed) do
                local l=d.b3D[i]
                if l then
                    if visible[e[1]] and visible[e[2]] then
                        l.Visible=true
                        l.Color=CFG.Visual.BoxColor
                        l.Thickness=CFG.Visual.BoxThickness
                        l.From=pr[e[1]]
                        l.To=pr[e[2]]
                    else l.Visible=false end
                end
            end
        elseif bt=="Corner" then
            local len=math.min(CFG.Visual.CornerLength,bW/3,bH/3)
            local cs={
                {f=Vector2.new(bL,bT),t=Vector2.new(bL+len,bT)},
                {f=Vector2.new(bL,bT),t=Vector2.new(bL,bT+len)},
                {f=Vector2.new(bR-len,bT),t=Vector2.new(bR,bT)},
                {f=Vector2.new(bR,bT),t=Vector2.new(bR,bT+len)},
                {f=Vector2.new(bL,bB-len),t=Vector2.new(bL,bB)},
                {f=Vector2.new(bL,bB),t=Vector2.new(bL+len,bB)},
                {f=Vector2.new(bR,bB-len),t=Vector2.new(bR,bB)},
                {f=Vector2.new(bR-len,bB),t=Vector2.new(bR,bB)},
            }
            for i,c in ipairs(cs) do
                local l=d.cor[i]
                if l then
                    l.Visible=true
                    l.Color=CFG.Visual.BoxColor
                    l.Thickness=CFG.Visual.BoxThickness
                    l.From=c.f
                    l.To=c.t
                end
            end
        end
    end

    -- NAME
    local hh=CFG.Visual.NameSize+6
    local s1y=bT+hh
    if d.name then
        if CFG.Visual.ESPName and CFG.Visual.ESPBox then
            d.name.Visible=true
            d.name.Color=CFG.Visual.NameColor
            d.name.Size=CFG.Visual.NameSize
            d.name.Text=inst.Name
            d.name.Position=Vector2.new(hp.X,bT+4)
        else d.name.Visible=false end
    end
    if d.sep1 then
        if CFG.Visual.ESPBox and CFG.Visual.ESPName then
            d.sep1.Visible=true
            d.sep1.Color=CFG.Visual.BoxColor
            d.sep1.Thickness=CFG.Visual.BoxThickness
            d.sep1.From=Vector2.new(bL,s1y)
            d.sep1.To=Vector2.new(bR,s1y)
        else d.sep1.Visible=false end
    end

    -- DISTANCE
    local fh=CFG.Visual.DistanceSize+6
    local s2y=bB-fh
    if d.sep2 then
        if CFG.Visual.ESPBox and CFG.Visual.ESPDistance then
            d.sep2.Visible=true
            d.sep2.Color=CFG.Visual.BoxColor
            d.sep2.Thickness=CFG.Visual.BoxThickness
            d.sep2.From=Vector2.new(bL,s2y)
            d.sep2.To=Vector2.new(bR,s2y)
        else d.sep2.Visible=false end
    end
    if d.dist then
        if CFG.Visual.ESPDistance and CFG.Visual.ESPBox then
            d.dist.Visible=true
            d.dist.Color=CFG.Visual.DistanceColor
            d.dist.Size=CFG.Visual.DistanceSize
            d.dist.Text=string.format("%dm", math.floor(dd))
            d.dist.Position=Vector2.new(hp.X,s2y+3)
        else d.dist.Visible=false end
    end

    -- HEALTH
    local hr=math.clamp(hum.Health/hum.MaxHealth,0,1)
    local dc=GetHealthColor(hr)
    if d.hBG and d.hBar then
        if CFG.Visual.ESPHealth and CFG.Visual.ESPBox then
            local bwd=CFG.Visual.HealthBarWidth
            local bx=bL-bwd-3
            local by=bT
            local bh=bH
            d.hBG.Visible=true
            d.hBG.Size=Vector2.new(bwd,bh)
            d.hBG.Position=Vector2.new(bx,by)
            local fH=bh*hr
            d.hBar.Visible=true
            d.hBar.Color=dc
            d.hBar.Size=Vector2.new(bwd,fH)
            d.hBar.Position=Vector2.new(bx,by+bh-fH)
        else d.hBG.Visible=false; d.hBar.Visible=false end
    end
    if d.hTxt then
        if CFG.Visual.ESPHealth and CFG.Visual.ESPBox then
            d.hTxt.Visible=true
            d.hTxt.Color=dc
            d.hTxt.Size=CFG.Visual.HealthTextSize
            d.hTxt.Text=tostring(math.floor(hum.Health))
            d.hTxt.Position=Vector2.new(bL-(CFG.Visual.HealthBarWidth/2)-3, bT-CFG.Visual.HealthTextSize-2)
        else d.hTxt.Visible=false end
    end
end

AddConn(RunService.RenderStepped:Connect(function()
    if not Drawing then return end
    local tr={}
    for inst in pairs(espCache) do
        if not inst or not inst.Parent or not IsAlive(inst) then table.insert(tr,inst) end
    end
    for _,i in ipairs(tr) do RemoveESP(i) end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local mt=GetCharTeam(LP.Character) or GetTeam(LP)
            local tt=GetCharTeam(p.Character) or GetTeam(p)
            local isT=mt~=-1 and mt==tt
            RenderESP(p.Character, true, isT, not isT)
        end
    end
    for _,b in ipairs(GetBots()) do RenderESP(b, false, false, true) end
end))

local function OnChar(char)
    local h=char:WaitForChild("Humanoid",5)
    if not h then return end
    if CFG.Player.SpeedHack then h.WalkSpeed=CFG.Player.SpeedValue end
    if CFG.Player.JumpHack then h.UseJumpPower=true; h.JumpPower=CFG.Player.JumpValue end
end
if LP.Character then OnChar(LP.Character) end
AddConn(LP.CharacterAdded:Connect(OnChar))

task.spawn(function()
    while task.wait(0.5) do
        if not CFG.Player.FastRegen then continue end
        if not LP.Character then continue end
        local h=LP.Character:FindFirstChildOfClass("Humanoid")
        if h and h.Health<h.MaxHealth then h.Health=h.MaxHealth end
    end
end)

AddConn(UIS.JumpRequest:Connect(function()
    if CFG.Player.InfiniteJump and LP.Character then
        local h=LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

task.spawn(function()
    while task.wait(0.2) do
        if not CFG.Player.NoClip then continue end
        if not LP.Character then continue end
        for _,v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not CFG.Player.AntiVoid then continue end
        if not LP.Character then continue end
        local hrp=LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y<-50 then hrp.CFrame=CFrame.new(0,50,0) end
    end
end)

-- Fly
local flyBV, flyBG
local function StartFly()
    local c=LP.Character; if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    flyBV=Instance.new("BodyVelocity")
    flyBV.MaxForce=Vector3.new(9e9,9e9,9e9); flyBV.Velocity=Vector3.zero; flyBV.Parent=hrp
    flyBG=Instance.new("BodyGyro")
    flyBG.MaxTorque=Vector3.new(9e9,9e9,9e9); flyBG.P=1000; flyBG.Parent=hrp
end
local function StopFly()
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
end
AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Player.FlyHack then
        if flyBV then StopFly() end
        return
    end
    if not flyBV then StartFly() end
    if not flyBV or not LP.Character then return end
    local hrp=LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir=Vector3.zero
    if IsMobile then
        local h=LP.Character:FindFirstChildOfClass("Humanoid")
        if h and h.MoveDirection.Magnitude>0 then dir=h.MoveDirection end
    else
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.E) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then dir=dir-Vector3.new(0,1,0) end
    end
    flyBV.Velocity=dir.Magnitude>0 and dir.Unit*CFG.Player.FlySpeed or Vector3.zero
    local lookDir=Camera.CFrame.LookVector
    local flatLook=Vector3.new(lookDir.X,0,lookDir.Z)
    if flatLook.Magnitude>0.01 then
        flatLook=flatLook.Unit
        flyBG.CFrame=CFrame.new(hrp.Position, hrp.Position+flatLook)
    else
        flyBG.CFrame=CFrame.new(hrp.Position, hrp.Position+Vector3.new(0,0,-1))
    end
end))

local spinA=0
AddConn(RunService.RenderStepped:Connect(function()
    if not CFG.Player.Spinbot then return end
    if not LP.Character then return end
    local hrp=LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    spinA=spinA+(CFG.Player.SpinSpeed/100)
    if spinA>360 then spinA=spinA-360 end
    hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,math.rad(spinA),0)
end))

-- Weapon Logic
local P_FIRE={"Debounce","FireInterval","ShootDelay","AcquireDelay","FireRate","DelayUntilLoop"}
local P_RECOIL={"MaxRotRecoil","MinRotRecoil","MaxCamRecoil","MinCamRecoil","MaxTransRecoil","MinTransRecoil","RotRecoilConstant","CamRecoilConstant","TransRecoilConstant","RotRecoilDamping"}
local P_SPREAD={"BaseSpread","Spread","ScopeSpreadMultiplier"}
local P_AMMO={"FillAmmo","Ammo"}
local P_DMG={"HeadDamage","DirectHeadDamage","AlternateDamage","ExplosiveDamage","MobDamage"}

local function ScanWeapons()
    local f={}
    for _,v in next, getgc(true) do
        if type(v)=="table" then
            local isW=rawget(v,"FireInterval") or rawget(v,"BaseSpread") or rawget(v,"HeadDamage")
                or rawget(v,"MaxRotRecoil") or rawget(v,"FillAmmo") or rawget(v,"Debounce") or rawget(v,"Ammo")
            if isW then
                table.insert(f,v)
                if weaponOriginals[v]==nil then
                    local c={}
                    for _,l in ipairs({P_FIRE,P_RECOIL,P_SPREAD,P_AMMO,P_DMG}) do
                        for _,k in ipairs(l) do c[k]=rawget(v,k) end
                    end
                    weaponOriginals[v]=c
                end
            end
        end
    end
    weaponTables=f
end
ScanWeapons()
task.spawn(function() while task.wait(3) do ScanWeapons() end end)

local lwU=0
AddConn(RunService.Heartbeat:Connect(function()
    local n=tick()
    if n-lwU<0.1 then return end
    lwU=n
    for _,t in ipairs(weaponTables) do
        local o=weaponOriginals[t]; if not o then continue end
        if CFG.Weapon.NoRecoil then
            for _,k in ipairs(P_RECOIL) do
                if o[k]~=nil then
                    if typeof(o[k])=="Vector3" then pcall(function() rawset(t,k,Vector3.zero) end)
                    else pcall(function() rawset(t,k,0) end) end
                end
            end
        else
            for _,k in ipairs(P_RECOIL) do if o[k]~=nil then pcall(function() rawset(t,k,o[k]) end) end end
        end
        if CFG.Weapon.NoSpread then
            for _,k in ipairs(P_SPREAD) do if o[k]~=nil then pcall(function() rawset(t,k,0) end) end end
        else
            for _,k in ipairs(P_SPREAD) do if o[k]~=nil then pcall(function() rawset(t,k,o[k]) end) end end
        end
        if CFG.Weapon.InfiniteAmmo then
            if o.FillAmmo~=nil then pcall(function() rawset(t,"FillAmmo",9999) end) end
            if o.Ammo~=nil then pcall(function() rawset(t,"Ammo",9999) end) end
        elseif CFG.Weapon.AmmoValue>0 then
            if o.FillAmmo~=nil then pcall(function() rawset(t,"FillAmmo",CFG.Weapon.AmmoValue) end) end
            if o.Ammo~=nil then pcall(function() rawset(t,"Ammo",CFG.Weapon.AmmoValue) end) end
        else
            if o.FillAmmo~=nil then pcall(function() rawset(t,"FillAmmo",o.FillAmmo) end) end
            if o.Ammo~=nil then pcall(function() rawset(t,"Ammo",o.Ammo) end) end
        end
        if CFG.Weapon.DamageHack then
            for _,k in ipairs(P_DMG) do if o[k]~=nil then pcall(function() rawset(t,k,CFG.Weapon.DamageValue) end) end end
        else
            for _,k in ipairs(P_DMG) do if o[k]~=nil then pcall(function() rawset(t,k,o[k]) end) end end
        end
        if CFG.Weapon.RapidFire then
            local m=CFG.Weapon.FireRateMult
            for _,k in ipairs(P_FIRE) do
                local v=o[k]
                if v~=nil and type(v)=="number" and v>0 then pcall(function() rawset(t,k,v/m) end) end
            end
        else
            for _,k in ipairs(P_FIRE) do if o[k]~=nil then pcall(function() rawset(t,k,o[k]) end) end end
        end
        if CFG.Weapon.RainbowBullets then pcall(function() rawset(t,"RainbowBullets",true) end) end
        if CFG.Weapon.BrightBullets then pcall(function() rawset(t,"BulletBrightness",5) end) end
        if CFG.Weapon.FatBullets then pcall(function() rawset(t,"BulletWidth",5) end) end
    end
end))

-- Ability Logic
task.spawn(function()
    while task.wait(3) do
        local l={}
        for _,v in next, getgc(true) do
            if type(v)=="table" and (rawget(v,"CD") or rawget(v,"Cooldown")) then table.insert(l,v) end
        end
        CDTables=l
    end
end)
task.spawn(function()
    while task.wait(0.2) do
        if not CFG.Player.NoCooldown then continue end
        for _,t in ipairs(CDTables) do
            if rawget(t,"CD") and type(rawget(t,"CD"))=="number" and rawget(t,"CD")>0 then rawset(t,"CD",CFG.Player.CooldownValue) end
            if rawget(t,"Cooldown") and type(rawget(t,"Cooldown"))=="number" and rawget(t,"Cooldown")>0 then rawset(t,"Cooldown",CFG.Player.CooldownValue) end
            local cc=rawget(t,"CastCondition")
            if type(cc)=="function" then pcall(function() rawset(t,"CastCondition",function(...) return true end) end) end
        end
    end
end)

local function GetAbilityTarget()
    if CFG.Player.SpamTarget=="Self" then return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
    local cl,dist=nil,math.huge
    local mp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not mp then return nil end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character and IsAlive(p.Character) then
            if CFG.Player.SpamTarget=="All" or CFG.Player.SpamTarget=="PlayerOnly" then
                local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then local d=(hrp.Position-mp.Position).Magnitude; if d<dist then cl,dist=hrp,d end end
            end
        end
    end
    if CFG.Player.SpamTarget=="All" or CFG.Player.SpamTarget=="BotOnly" then
        for _,b in ipairs(GetBots()) do
            local hrp=b:FindFirstChild("HumanoidRootPart")
            if hrp then local d=(hrp.Position-mp.Position).Magnitude; if d<dist then cl,dist=hrp,d end end
        end
    end
    return cl
end

local lAF=0
task.spawn(function()
    while task.wait(CFG.Player.SpamDelay) do
        if not CFG.Player.AbilitySpam then continue end
        local n=tick()
        if n-lAF<CFG.Player.SpamDelay then continue end
        lAF=n
        local tgt = GetAbilityTarget()
        local tgtPos = tgt and tgt.Position or nil
        local abName = CFG.Player.SelectedAbility
        local function FireAbility(rmt)
            if not rmt then return end
            pcall(function() rmt:FireServer() end)
            if tgt then
                pcall(function() rmt:FireServer(tgt) end)
                pcall(function() rmt:FireServer(tgtPos) end)
            end
        end
        if abName == "UseAbility (Universal)" then
            FireAbility(UseAbility)
        else
            local rmt = Remotes:FindFirstChild(abName)
            if rmt then FireAbility(rmt) else FireAbility(UseAbility) end
        end
    end
end)

-- Farm Logic
local function GetFarmTargets(filter)
    local l={}
    for _,t in ipairs(GetAllTargets()) do
        if not t.isEnemy and not CFG.Farm.BringTeam then continue end
        if filter=="All" then table.insert(l,t) end
        if filter=="PlayerOnly" and t.isPlayer then table.insert(l,t) end
        if filter=="BotOnly" and not t.isPlayer then table.insert(l,t) end
    end
    return l
end
local function GetClosestFarmTarget(filter)
    local l=GetFarmTargets(filter)
    local mp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not mp then return nil end
    local cl,dist=nil,math.huge
    for _,t in ipairs(l) do
        local hrp=t.inst:FindFirstChild("HumanoidRootPart")
        if hrp then local d=(hrp.Position-mp.Position).Magnitude; if d<dist then cl,dist=t,d end end
    end
    return cl
end
local function GetBringList()
    if CFG.Farm.BringMode=="Single" then
        if lockedSingleTarget and lockedSingleTarget.Parent and IsAlive(lockedSingleTarget) then
            return {{inst=lockedSingleTarget, isPlayer=false, isEnemy=true}}
        end
        local c=GetClosestFarmTarget(CFG.Farm.BringTarget)
        if c then lockedSingleTarget=c.inst; return {c} else lockedSingleTarget=nil; return {} end
    else return GetFarmTargets(CFG.Farm.BringTarget) end
end

task.spawn(function()
    local lT=0
    while task.wait(0.1) do
        if not CFG.Farm.TpToPlayerBot then continue end
        if not LP.Character then continue end
        local n=tick()
        if (n-lT)*1000<CFG.Farm.TpDelay then continue end
        lT=n
        local mr=LP.Character:FindFirstChild("HumanoidRootPart"); if not mr then continue end
        for _,t in ipairs(GetFarmTargets(CFG.Farm.TpTarget)) do
            local hrp=t.inst:FindFirstChild("HumanoidRootPart")
            if hrp then
                local off
                if CFG.Farm.TpPosition=="Depan" then off=hrp.CFrame.LookVector*CFG.Farm.TpJarak
                elseif CFG.Farm.TpPosition=="Belakang" then off=-hrp.CFrame.LookVector*CFG.Farm.TpJarak
                elseif CFG.Farm.TpPosition=="Atas" then off=Vector3.new(0,CFG.Farm.TpJarak,0)
                elseif CFG.Farm.TpPosition=="Bawah" then off=Vector3.new(0,-CFG.Farm.TpJarak,0) end
                mr.CFrame=CFrame.new(hrp.Position+off); break
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if not CFG.Farm.BringPlayerBot then
            for inst in pairs(bringOffsets) do
                if inst and inst.Parent then
                    local hrp=inst:FindFirstChild("HumanoidRootPart")
                    if hrp then pcall(function() hrp.Anchored=false end) end
                end
            end
            bringOffsets={}; lockedSingleTarget=nil
            continue
        end
        if not LP.Character then continue end
        local mr=LP.Character:FindFirstChild("HumanoidRootPart"); if not mr then continue end
        local cl=GetBringList()
        local ci={}
        for _,t in ipairs(cl) do
            local inst=t.inst
            if not IsAlive(inst) then continue end
            ci[inst]=true
            local hrp=inst:FindFirstChild("HumanoidRootPart")
            local hd=inst:FindFirstChild("Head")
            if not hrp or not hd then continue end
            if not bringOffsets[inst] then
                bringOffsets[inst]={x=math.random(-CFG.Farm.BringSpread,CFG.Farm.BringSpread),z=math.random(-CFG.Farm.BringSpread,CFG.Farm.BringSpread)}
            end
            local o=bringOffsets[inst]
            if CFG.Farm.BringPart=="Head Only" then
                pcall(function() hd.CFrame=CFrame.new(Camera.CFrame.Position+Camera.CFrame.LookVector*CFG.Farm.BringJarak)*hd.CFrame.Rotation end)
            elseif CFG.Farm.BringPart=="Full HRP" then
                local tc=mr.CFrame*CFrame.new(o.x,0,-CFG.Farm.BringJarak+o.z)
                pcall(function() hrp.CFrame=tc end)
            elseif CFG.Farm.BringPart=="Both" then
                local tc=mr.CFrame*CFrame.new(o.x,0,-CFG.Farm.BringJarak+o.z)
                pcall(function()
                    hrp.CFrame=tc
                    hd.CFrame=CFrame.new(Camera.CFrame.Position+Camera.CFrame.LookVector*CFG.Farm.BringJarak)*hd.CFrame.Rotation
                end)
            end
        end
        for inst in pairs(bringOffsets) do
            if not ci[inst] then
                if inst and inst.Parent then
                    local hrp=inst:FindFirstChild("HumanoidRootPart")
                    if hrp then pcall(function() hrp.Anchored=false end) end
                end
                bringOffsets[inst]=nil
            elseif not inst or not inst.Parent then bringOffsets[inst]=nil end
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if not CFG.Farm.AnchorEnemy then continue end
        for _,t in ipairs(GetBringList()) do
            if not IsAlive(t.inst) then continue end
            local hrp=t.inst:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.Anchored=true end) end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not CFG.Farm.HitboxExpander then
            for p,o in pairs(origSizes) do
                if p and p.Parent then pcall(function() p.Size=o end) end
            end
            continue
        end
        local tg={}
        for _,t in ipairs(GetAllTargets()) do
            if not IsAlive(t.inst) then continue end
            if CFG.Farm.HitboxTarget=="AllEnemy" and t.isEnemy then table.insert(tg,t.inst) end
            if CFG.Farm.HitboxTarget=="PlayerEnemy" and t.isPlayer and t.isEnemy then table.insert(tg,t.inst) end
            if CFG.Farm.HitboxTarget=="BotEnemy" and not t.isPlayer then table.insert(tg,t.inst) end
        end
        for _,inst in ipairs(tg) do
            local ps={}
            if CFG.Farm.HitboxPart=="All" then
                for _,v in ipairs(inst:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name~="HumanoidRootPart" then table.insert(ps,v) end
                end
            elseif CFG.Farm.HitboxPart=="Head" then
                local p=inst:FindFirstChild("Head"); if p then table.insert(ps,p) end
            elseif CFG.Farm.HitboxPart=="Body" then
                local p=inst:FindFirstChild("UpperTorso") or inst:FindFirstChild("Torso"); if p then table.insert(ps,p) end
            elseif CFG.Farm.HitboxPart=="Foot" then
                local p=inst:FindFirstChild("LeftFoot") or inst:FindFirstChild("RightFoot"); if p then table.insert(ps,p) end
            end
            for _,p in ipairs(ps) do
                if not origSizes[p] then origSizes[p]=p.Size end
                p.Size=origSizes[p]*CFG.Farm.HitboxSize
                p.Transparency=0.5; p.Massless=true; p.CanCollide=false
            end
        end
    end
end)

task.spawn(function()
    while task.wait(30) do
        for p in pairs(origSizes) do if not p or not p.Parent then origSizes[p]=nil end end
    end
end)

print("━━━ RY ULTIMATE HYPERshot v9.6 ━━━")
print("✅ Loaded | Team:", GetTeam(LP), "| Bots:", #GetBots())
print("📋 Tabs: 8 | Weapon Tables:", #weaponTables)
print("🔧 FIX: Aim Type, ESP Position, Box Type, ESP Size")
print("⚠️ Config saving DISABLED (biar gak nimpa setting)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
