-- ═══════════════════════════════════════════════════════════════
--   RY SIMPLE v1.1 (FULL)
--   By: ry-zeen | UI: Orion Library | Game: Hypershot
--   
--   FITUR:
--   [COMBAT]  Aimbot, Aim Smoothness, Aim Target, Aim Part,
--             POV, Show POV, POV Color, Team Check, Wall Check
--   [PLAYER]  Fast Regen, No Cooldown, Cooldown Value
--   [WEAPON]  Infinite Ammo, Rapid Fire, Fire Rate,
--             No Recoil, No Spread
--   [VISUAL]  ESP Box Player Team/Enemy, Bot Team/Enemy + Color
-- ═══════════════════════════════════════════════════════════════

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local IsMobile     = UIS.TouchEnabled and not UIS.KeyboardEnabled

local Network = RS:WaitForChild("Network", 10)
local Remotes = Network and Network:WaitForChild("Remotes", 10)
local Shoot   = Remotes and Remotes:FindFirstChild("Shoot")

-- FORWARD DECLARATIONS
local weaponTables = {}
local weaponOriginals = {}
local CDTables = {}
local espCache = {}

-- ═══════════════════════════════════════════════════════════════
--   CONFIG
-- ═══════════════════════════════════════════════════════════════
local CFG = {
    Combat = {
        Aimbot = false,
        Smoothness = 5,
        AimTarget = "AllEnemy",
        AimPart = "Head",
        POVRadius = 150,
        ShowPOV = false,
        POVColor = Color3.fromRGB(0, 170, 255),
        TeamCheck = true,
        WallCheck = false,
    },
    Player = {
        FastRegen = false,
        NoCooldown = false,
        CooldownValue = 0,
    },
    Weapon = {
        InfiniteAmmo = false,
        RapidFire = false,
        FireRateValue = 5,
        NoRecoil = false,
        NoSpread = false,
    },
    Visual = {
        ESPBoxPlayerTeam = false,
        BoxColorPlayerTeam = Color3.fromRGB(0, 170, 255),
        ESPBoxPlayerEnemy = false,
        BoxColorPlayerEnemy = Color3.fromRGB(255, 60, 60),
        ESPBoxBotTeam = false,
        BoxColorBotTeam = Color3.fromRGB(0, 255, 100),
        ESPBoxBotEnemy = false,
        BoxColorBotEnemy = Color3.fromRGB(255, 220, 0),
    },
}

-- ═══════════════════════════════════════════════════════════════
--   HELPERS
-- ═══════════════════════════════════════════════════════════════
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

local function IsTeam(p)
    if p == LP then return false end
    if not p.Character or not IsAlive(p.Character) then return false end
    local mt = GetCharTeam(LP.Character) or GetTeam(LP)
    local tt = GetCharTeam(p.Character) or GetTeam(p)
    return mt ~= -1 and mt == tt
end

local function GetBots()
    local l = {}
    for _, fn in ipairs({"Mobs", "IgnoreThese"}) do
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
    if name == "Head" then return inst:FindFirstChild("Head") end
    if name == "Body" then
        return inst:FindFirstChild("UpperTorso") or inst:FindFirstChild("Torso") or inst:FindFirstChild("HumanoidRootPart")
    end
    if name == "Foot" then
        return inst:FindFirstChild("LeftFoot") or inst:FindFirstChild("RightFoot") or inst:FindFirstChild("HumanoidRootPart")
    end
    return inst:FindFirstChild(name) or inst:FindFirstChild("Head") or inst:FindFirstChild("HumanoidRootPart")
end

local function WallCheck(part)
    if not CFG.Combat.WallCheck then return true end
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {LP.Character, Camera}
    local r = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, p)
    return r == nil or r.Instance:IsDescendantOf(part.Parent)
end

local Connections = {}
local function AddConn(c) table.insert(Connections, c); return c end

-- ═══════════════════════════════════════════════════════════════
--   LOAD ORION UI
-- ═══════════════════════════════════════════════════════════════
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local Window = OrionLib:MakeWindow({
    Name = "RY SIMPLE v1.1",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "RY_Simple",
    IntroEnabled = true,
    IntroText = "RY SIMPLE",
    IntroIcon = "rbxassetid://4483362458",
    Icon = "rbxassetid://4483362458",
})

-- ═══════════════════════════════════════════════════════════════
--   TAB 1: COMBAT
-- ═══════════════════════════════════════════════════════════════
local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false,
})

CombatTab:AddSection({ Name = "Aimbot" })

CombatTab:AddToggle({
    Name = "Aimbot",
    Default = false,
    Flag = "Aimbot_Enabled",
    Save = false,
    Callback = function(Value)
        CFG.Combat.Aimbot = Value
    end,
})

CombatTab:AddSlider({
    Name = "Aim Smoothness",
    Min = 0,
    Max = 20,
    Default = 5,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 1,
    ValueName = "x",
    Flag = "Aimbot_Smoothness",
    Callback = function(Value)
        CFG.Combat.Smoothness = Value
    end,
})

CombatTab:AddDropdown({
    Name = "Aim Target",
    Default = "AllEnemy",
    Options = {"AllEnemy", "PlayerEnemy", "BotEnemy"},
    Flag = "Aimbot_Target",
    Callback = function(Value)
        CFG.Combat.AimTarget = Value
    end,
})

CombatTab:AddDropdown({
    Name = "Aim Part",
    Default = "Head",
    Options = {"Head", "Body", "Foot"},
    Flag = "Aimbot_Part",
    Callback = function(Value)
        CFG.Combat.AimPart = Value
    end,
})

CombatTab:AddSection({ Name = "POV Circle" })

CombatTab:AddSlider({
    Name = "POV Radius",
    Min = 50,
    Max = 500,
    Default = 150,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 10,
    ValueName = "px",
    Flag = "POV_Radius",
    Callback = function(Value)
        CFG.Combat.POVRadius = Value
    end,
})

CombatTab:AddToggle({
    Name = "Show POV",
    Default = false,
    Flag = "POV_Show",
    Callback = function(Value)
        CFG.Combat.ShowPOV = Value
    end,
})

CombatTab:AddColorpicker({
    Name = "POV Color",
    Default = Color3.fromRGB(0, 170, 255),
    Flag = "POV_Color",
    Callback = function(Value)
        CFG.Combat.POVColor = Value
    end,
})

CombatTab:AddSection({ Name = "Filter" })

CombatTab:AddToggle({
    Name = "Team Check",
    Default = true,
    Flag = "Filter_Team",
    Callback = function(Value)
        CFG.Combat.TeamCheck = Value
    end,
})

CombatTab:AddToggle({
    Name = "Wall Check",
    Default = false,
    Flag = "Filter_Wall",
    Callback = function(Value)
        CFG.Combat.WallCheck = Value
    end,
})

-- ═══════════════════════════════════════════════════════════════
--   TAB 2: PLAYER
-- ═══════════════════════════════════════════════════════════════
local PlayerTab = Window:MakeTab({
    Name = "Player",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false,
})

PlayerTab:AddSection({ Name = "Survival" })

PlayerTab:AddToggle({
    Name = "Fast Regen",
    Default = false,
    Flag = "Player_FastRegen",
    Callback = function(Value)
        CFG.Player.FastRegen = Value
    end,
})

PlayerTab:AddSection({ Name = "Ability" })

PlayerTab:AddToggle({
    Name = "No Cooldown Ability",
    Default = false,
    Flag = "Ability_NoCD",
    Callback = function(Value)
        CFG.Player.NoCooldown = Value
    end,
})

PlayerTab:AddSlider({
    Name = "Cooldown Value",
    Min = 0,
    Max = 100,
    Default = 0,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 1,
    ValueName = "s",
    Flag = "Ability_CDValue",
    Callback = function(Value)
        CFG.Player.CooldownValue = Value
    end,
})

-- ═══════════════════════════════════════════════════════════════
--   TAB 3: WEAPON
-- ═══════════════════════════════════════════════════════════════
local WeaponTab = Window:MakeTab({
    Name = "Weapon",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false,
})

WeaponTab:AddSection({ Name = "Ammo" })

WeaponTab:AddToggle({
    Name = "Infinite Ammo",
    Default = false,
    Flag = "Weapon_InfAmmo",
    Callback = function(Value)
        CFG.Weapon.InfiniteAmmo = Value
    end,
})

WeaponTab:AddSection({ Name = "Fire Rate" })

WeaponTab:AddToggle({
    Name = "Rapid Fire",
    Default = false,
    Flag = "Weapon_RapidFire",
    Callback = function(Value)
        CFG.Weapon.RapidFire = Value
    end,
})

WeaponTab:AddSlider({
    Name = "Fire Rate Value",
    Min = 1,
    Max = 100,
    Default = 5,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 1,
    ValueName = "x",
    Flag = "Weapon_FireRate",
    Callback = function(Value)
        CFG.Weapon.FireRateValue = Value
    end,
})

WeaponTab:AddSection({ Name = "Accuracy" })

WeaponTab:AddToggle({
    Name = "No Recoil",
    Default = false,
    Flag = "Weapon_NoRecoil",
    Callback = function(Value)
        CFG.Weapon.NoRecoil = Value
    end,
})

WeaponTab:AddToggle({
    Name = "No Spread",
    Default = false,
    Flag = "Weapon_NoSpread",
    Callback = function(Value)
        CFG.Weapon.NoSpread = Value
    end,
})

-- ═══════════════════════════════════════════════════════════════
--   TAB 4: VISUAL
-- ═══════════════════════════════════════════════════════════════
local VisualTab = Window:MakeTab({
    Name = "Visual",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false,
})

-- ═══ ESP Box Player Team ═══
VisualTab:AddSection({ Name = "ESP Box Player Team" })

VisualTab:AddToggle({
    Name = "ESP Box Player Team",
    Default = false,
    Flag = "ESP_BoxPlayerTeam",
    Callback = function(Value)
        CFG.Visual.ESPBoxPlayerTeam = Value
    end,
})

VisualTab:AddColorpicker({
    Name = "Box Player Team Color",
    Default = Color3.fromRGB(0, 170, 255),
    Flag = "ESP_BoxColorPlayerTeam",
    Callback = function(Value)
        CFG.Visual.BoxColorPlayerTeam = Value
    end,
})

-- ═══ ESP Box Player Enemy ═══
VisualTab:AddSection({ Name = "ESP Box Player Enemy" })

VisualTab:AddToggle({
    Name = "ESP Box Player Enemy",
    Default = false,
    Flag = "ESP_BoxPlayerEnemy",
    Callback = function(Value)
        CFG.Visual.ESPBoxPlayerEnemy = Value
    end,
})

VisualTab:AddColorpicker({
    Name = "Box Player Enemy Color",
    Default = Color3.fromRGB(255, 60, 60),
    Flag = "ESP_BoxColorPlayerEnemy",
    Callback = function(Value)
        CFG.Visual.BoxColorPlayerEnemy = Value
    end,
})

-- ═══ ESP Box Bot Team ═══
VisualTab:AddSection({ Name = "ESP Box Bot Team" })

VisualTab:AddToggle({
    Name = "ESP Box Bot Team",
    Default = false,
    Flag = "ESP_BoxBotTeam",
    Callback = function(Value)
        CFG.Visual.ESPBoxBotTeam = Value
    end,
})

VisualTab:AddColorpicker({
    Name = "Box Bot Team Color",
    Default = Color3.fromRGB(0, 255, 100),
    Flag = "ESP_BoxColorBotTeam",
    Callback = function(Value)
        CFG.Visual.BoxColorBotTeam = Value
    end,
})

-- ═══ ESP Box Bot Enemy ═══
VisualTab:AddSection({ Name = "ESP Box Bot Enemy" })

VisualTab:AddToggle({
    Name = "ESP Box Bot Enemy",
    Default = false,
    Flag = "ESP_BoxBotEnemy",
    Callback = function(Value)
        CFG.Visual.ESPBoxBotEnemy = Value
    end,
})

VisualTab:AddColorpicker({
    Name = "Box Bot Enemy Color",
    Default = Color3.fromRGB(255, 220, 0),
    Flag = "ESP_BoxColorBotEnemy",
    Callback = function(Value)
        CFG.Visual.BoxColorBotEnemy = Value
    end,
})

-- ═══════════════════════════════════════════════════════════════
--   CORE LOGIC
-- ═══════════════════════════════════════════════════════════════

-- ═══ POV CIRCLE ═══
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

-- ═══ AIMBOT ═══
local function GetAimTargets()
    local l = {}
    if CFG.Combat.AimTarget == "AllEnemy" or CFG.Combat.AimTarget == "PlayerEnemy" then
        for _, p in ipairs(Players:GetPlayers()) do
            if IsEnemy(p) then table.insert(l, {inst = p.Character, isPlayer = true}) end
        end
    end
    if CFG.Combat.AimTarget == "AllEnemy" or CFG.Combat.AimTarget == "BotEnemy" then
        for _, b in ipairs(GetBots()) do
            if IsAlive(b) then table.insert(l, {inst = b, isPlayer = false}) end
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
    if not CFG.Combat.Aimbot then return end
    local t = FindClosest()
    if not t then return end
    if not IsAlive(t.inst) then return end
    local p = GetPart(t.inst, CFG.Combat.AimPart)
    if not p or not p.Parent then return end
    local s = CFG.Combat.Smoothness > 0 and CFG.Combat.Smoothness or 1
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, p.Position), 1/s)
end))

-- ═══ FAST REGEN ═══
task.spawn(function()
    while task.wait(0.5) do
        if not CFG.Player.FastRegen then continue end
        if not LP.Character then continue end
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end
end)

-- ═══ NO COOLDOWN ═══
task.spawn(function()
    while task.wait(3) do
        local l = {}
        for _, v in next, getgc(true) do
            if type(v) == "table" and (rawget(v, "CD") or rawget(v, "Cooldown")) then
                table.insert(l, v)
            end
        end
        CDTables = l
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if not CFG.Player.NoCooldown then continue end
        local cdVal = CFG.Player.CooldownValue
        for _, t in ipairs(CDTables) do
            if rawget(t, "CD") and type(rawget(t, "CD")) == "number" and rawget(t, "CD") > 0 then
                rawset(t, "CD", cdVal)
            end
            if rawget(t, "Cooldown") and type(rawget(t, "Cooldown")) == "number" and rawget(t, "Cooldown") > 0 then
                rawset(t, "Cooldown", cdVal)
            end
            local cc = rawget(t, "CastCondition")
            if type(cc) == "function" then
                pcall(function() rawset(t, "CastCondition", function(...) return true end) end)
            end
        end
    end
end)

-- ═══ WEAPON LOGIC ═══
local P_FIRE   = {"Debounce", "FireInterval", "ShootDelay", "AcquireDelay", "FireRate", "DelayUntilLoop"}
local P_RECOIL = {"MaxRotRecoil", "MinRotRecoil", "MaxCamRecoil", "MinCamRecoil",
                  "MaxTransRecoil", "MinTransRecoil", "RotRecoilConstant", "CamRecoilConstant",
                  "TransRecoilConstant", "RotRecoilDamping"}
local P_SPREAD = {"BaseSpread", "Spread", "ScopeSpreadMultiplier"}
local P_AMMO   = {"FillAmmo", "Ammo"}

local function ScanWeapons()
    local f = {}
    for _, v in next, getgc(true) do
        if type(v) == "table" then
            local isW = rawget(v, "FireInterval") or rawget(v, "BaseSpread")
                or rawget(v, "HeadDamage") or rawget(v, "MaxRotRecoil")
                or rawget(v, "FillAmmo") or rawget(v, "Debounce") or rawget(v, "Ammo")
            if isW then
                table.insert(f, v)
                if weaponOriginals[v] == nil then
                    local c = {}
                    for _, list in ipairs({P_FIRE, P_RECOIL, P_SPREAD, P_AMMO}) do
                        for _, k in ipairs(list) do
                            c[k] = rawget(v, k)
                        end
                    end
                    weaponOriginals[v] = c
                end
            end
        end
    end
    weaponTables = f
end
ScanWeapons()
task.spawn(function() while task.wait(5) do ScanWeapons() end end)

local lwU = 0
AddConn(RunService.Heartbeat:Connect(function()
    local n = tick()
    if n - lwU < 0.1 then return end
    lwU = n

    local anyActive = CFG.Weapon.NoRecoil or CFG.Weapon.NoSpread
        or CFG.Weapon.InfiniteAmmo or CFG.Weapon.RapidFire
    if not anyActive then return end

    for _, t in ipairs(weaponTables) do
        local o = weaponOriginals[t]
        if not o then continue end

        if CFG.Weapon.NoRecoil then
            for _, k in ipairs(P_RECOIL) do
                if o[k] ~= nil then
                    if typeof(o[k]) == "Vector3" then
                        pcall(function() rawset(t, k, Vector3.zero) end)
                    else
                        pcall(function() rawset(t, k, 0) end)
                    end
                end
            end
        end

        if CFG.Weapon.NoSpread then
            for _, k in ipairs(P_SPREAD) do
                if o[k] ~= nil then pcall(function() rawset(t, k, 0) end) end
            end
        end

        if CFG.Weapon.InfiniteAmmo then
            if o.FillAmmo ~= nil and type(o.FillAmmo) == "number" then
                pcall(function() rawset(t, "FillAmmo", o.FillAmmo) end)
            end
            if o.Ammo ~= nil and type(o.Ammo) == "number" then
                pcall(function() rawset(t, "Ammo", o.Ammo) end)
            end
        end

        if CFG.Weapon.RapidFire then
            local m = CFG.Weapon.FireRateValue
            for _, k in ipairs(P_FIRE) do
                local v = o[k]
                if v ~= nil and type(v) == "number" and v > 0 then
                    pcall(function() rawset(t, k, math.max(v/m, 0.001)) end)
                end
            end
        end
    end
end))

-- ═══════════════════════════════════════════════════════════════
--   ESP BOX RENDER
-- ═══════════════════════════════════════════════════════════════
local function CreateESP(inst)
    if espCache[inst] then return espCache[inst] end
    local data = {}
    if Drawing then
        data.box = Drawing.new("Square")
        data.box.Thickness = 2
        data.box.Filled = false
        data.box.Transparency = 1
        data.box.Visible = false
    end
    espCache[inst] = data
    return data
end

local function RemoveESP(inst)
    local d = espCache[inst]
    if d then
        if d.box then pcall(function() d.box:Remove() end) end
        espCache[inst] = nil
    end
end

local function RenderESP(inst, isPlayer, isTeammate, isEnemy)
    if not Drawing then return end
    if not IsAlive(inst) then RemoveESP(inst); return end
    
    local d = CreateESP(inst)
    local hrp = inst:FindFirstChild("HumanoidRootPart")
    local head = inst:FindFirstChild("Head")
    if not hrp or not head then
        if d.box then d.box.Visible = false end
        return
    end
    
    local headPos, on = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local rootPos = Camera:WorldToViewportPoint(hrp.Position)
    if not on then
        if d.box then d.box.Visible = false end
        return
    end
    
    local h = math.abs(headPos.Y - rootPos.Y) * 2
    local w = h / 2
    
    -- Tentukan toggle & color berdasarkan tipe
    local boxTgl, boxColor
    if isPlayer and isTeammate then
        boxTgl = CFG.Visual.ESPBoxPlayerTeam
        boxColor = CFG.Visual.BoxColorPlayerTeam
    elseif isPlayer and isEnemy then
        boxTgl = CFG.Visual.ESPBoxPlayerEnemy
        boxColor = CFG.Visual.BoxColorPlayerEnemy
    elseif not isPlayer and isTeammate then
        boxTgl = CFG.Visual.ESPBoxBotTeam
        boxColor = CFG.Visual.BoxColorBotTeam
    else
        boxTgl = CFG.Visual.ESPBoxBotEnemy
        boxColor = CFG.Visual.BoxColorBotEnemy
    end
    
    if d.box then
        if boxTgl then
            d.box.Visible = true
            d.box.Color = boxColor
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(headPos.X - w/2, headPos.Y - h/2)
        else
            d.box.Visible = false
        end
    end
end

AddConn(RunService.RenderStepped:Connect(function()
    if not Drawing then return end
    
    -- Cleanup cache
    for inst in pairs(espCache) do
        if not inst or not inst.Parent or not IsAlive(inst) then
            RemoveESP(inst)
        end
    end
    
    -- Render Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local mt = GetCharTeam(LP.Character) or GetTeam(LP)
            local tt = GetCharTeam(p.Character) or GetTeam(p)
            local isTeam = mt ~= -1 and mt == tt
            RenderESP(p.Character, true, isTeam, not isTeam)
        end
    end
    
    -- Render Bots
    for _, b in ipairs(GetBots()) do
        RenderESP(b, false, false, true)
    end
end))

-- ═══════════════════════════════════════════════════════════════
--   ORION INIT (WAJIB!)
-- ═══════════════════════════════════════════════════════════════
OrionLib:Init()

-- ═══════════════════════════════════════════════════════════════
--   BOOT NOTIF
-- ═══════════════════════════════════════════════════════════════
OrionLib:MakeNotification({
    Name = "RY SIMPLE v1.1",
    Content = "Loaded! | Team: " .. tostring(GetTeam(LP)) .. " | Bots: " .. #GetBots(),
    Image = "rbxassetid://4483362458",
    Time = 5,
})

print("━━━ RY SIMPLE v1.1 — Orion UI ━━━")
print("Loaded | Team:", GetTeam(LP), "| Bots:", #GetBots())
print("Tabs: Combat, Player, Weapon, Visual")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
