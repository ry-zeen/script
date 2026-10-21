-- ========================================================
-- RENXX HUB v5.0 - PREMIUM EDITION
-- By: Ryzeen & Renxx
-- Game: Weird Gun Game
-- ========================================================

pcall(function() delfile("RENXXHUB/WGG_v4.0.json") end)
pcall(function() delfile("RENXXHUB/WGG_v4.1.json") end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- [ CONFIGURATION ]
local Config = {
    EspEnabled = false, EspMaxDist = 500, ShowNpcTag = true, EspLinePosition = "Bottom",
    EspStyle = "Full", -- Full / Corner
    
    EnemyBox = false, EnemyBoxColor = Color3.fromRGB(255, 50, 50),
    EnemyLine = false, EnemyLineColor = Color3.fromRGB(255, 50, 50),
    EnemyName = false, EnemyNameColor = Color3.fromRGB(255, 255, 255),
    EnemyHealth = false,
    EnemySkeleton = false, EnemySkeletonColor = Color3.fromRGB(255, 100, 100),
    EnemyDot = false,
    
    TeamBox = false, TeamBoxColor = Color3.fromRGB(0, 255, 255),
    TeamLine = false, TeamLineColor = Color3.fromRGB(0, 255, 255),
    TeamName = false, TeamNameColor = Color3.fromRGB(0, 255, 255),
    TeamHealth = false,
    TeamSkeleton = false, TeamSkeletonColor = Color3.fromRGB(100, 255, 255),
    TeamDot = false,
    
    AimbotEnabled = false, AimSmoothness = 5, AimTarget = "AllEnemy", AimPart = "Head", AimFOV = 90, ShowFOV = false,
    TeamCheckAim = true, WallCheckAim = false,
    HitboxEnabled = false, HitboxSize = 10,
    
    CameraFOV = 70, ThirdPerson = false,
    AntiFling = false, AntiVoid = false, AntiAFK = false,
    FastRegen = false, RegenSpeed = 10,
    SpeedHack = false, SpeedValue = 50,
    JumpHack = false, JumpValue = 100,
    InfJump = false, NoClip = false,
    Fly = false, FlySpeed = 50,
    
    InfAmmo = false, InfGrenade = false, NoRecoil = false, NoSpread = false,
    RapidFire = false, FireRate = 100000, FastReload = false, ReloadSpeed = 0,
    DamageHack = false, DamageBoost = 100,
    
    BringToggle = false, BringTarget = "AllEnemy", BringDistance = 3,
    TelekillPro = false, TelekillTarget = "AllEnemy", TelekillPosition = "Front", TelekillDistance = 3
}

-- [ STATE ]
local ESPCache = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false

local cachedBots = {}
local lastBotScan = 0

-- ========================================================
-- [ UI BUILD ]
-- ========================================================
local Window = Rayfield:CreateWindow({
    Name = "RENXX HUB | v5.0 Premium",
    LoadingTitle = "RENXX HUB Premium...",
    LoadingSubtitle = "By Ryzeen & Renxx",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- ═══ TAB VISUAL ═══
local VisualTab = Window:CreateTab("Visual", 4483362458)
VisualTab:CreateSection("ESP Manager")
VisualTab:CreateToggle({Name = "ESP Master", CurrentValue = false, Callback = function(v) Config.EspEnabled = v end})
VisualTab:CreateSlider({Name = "ESP Max Distance", Range = {100, 1500}, Increment = 50, CurrentValue = 500, Callback = function(v) Config.EspMaxDist = v end})
VisualTab:CreateDropdown({Name = "ESP Line Position", Options = {"Top", "Center", "Bottom"}, CurrentOption = {"Bottom"}, Callback = function(opt) Config.EspLinePosition = opt[1] end})
VisualTab:CreateDropdown({Name = "ESP Style", Options = {"Full", "Corner"}, CurrentOption = {"Full"}, Callback = function(opt) Config.EspStyle = opt[1] end})
VisualTab:CreateToggle({Name = "Show [BOT] Tag", CurrentValue = true, Callback = function(v) Config.ShowNpcTag = v end})
VisualTab:CreateButton({Name = "🚨 PANIC RESET ESP", Callback = function()
    for char, objs in pairs(ESPCache) do
        for _, obj in pairs(objs) do
            pcall(function()
                if typeof(obj) == "table" then for _, line in pairs(obj) do line:Remove() end
                else obj:Remove() end
            end)
        end
    end
    ESPCache = {}
    Rayfield:Notify({Title="Panic", Content="ESP Cache Cleared!", Duration=3})
end})

VisualTab:CreateSection("ESP Enemy")
VisualTab:CreateToggle({Name = "Enemy Box", CurrentValue = false, Callback = function(v) Config.EnemyBox = v end})
VisualTab:CreateColorPicker({Name = "Enemy Box Color", Color = Config.EnemyBoxColor, Callback = function(v) Config.EnemyBoxColor = v end})
VisualTab:CreateToggle({Name = "Enemy Line", CurrentValue = false, Callback = function(v) Config.EnemyLine = v end})
VisualTab:CreateColorPicker({Name = "Enemy Line Color", Color = Config.EnemyLineColor, Callback = function(v) Config.EnemyLineColor = v end})
VisualTab:CreateToggle({Name = "Enemy Dot", CurrentValue = false, Callback = function(v) Config.EnemyDot = v end})
VisualTab:CreateToggle({Name = "Enemy Name + HP%", CurrentValue = false, Callback = function(v) Config.EnemyName = v end})
VisualTab:CreateColorPicker({Name = "Enemy Name Color", Color = Config.EnemyNameColor, Callback = function(v) Config.EnemyNameColor = v end})
VisualTab:CreateToggle({Name = "Enemy Health Bar", CurrentValue = false, Callback = function(v) Config.EnemyHealth = v end})
VisualTab:CreateToggle({Name = "Enemy Skeleton", CurrentValue = false, Callback = function(v) Config.EnemySkeleton = v end})
VisualTab:CreateColorPicker({Name = "Enemy Skeleton Color", Color = Config.EnemySkeletonColor, Callback = function(v) Config.EnemySkeletonColor = v end})

VisualTab:CreateSection("ESP Team")
VisualTab:CreateToggle({Name = "Team Box", CurrentValue = false, Callback = function(v) Config.TeamBox = v end})
VisualTab:CreateColorPicker({Name = "Team Box Color", Color = Config.TeamBoxColor, Callback = function(v) Config.TeamBoxColor = v end})
VisualTab:CreateToggle({Name = "Team Line", CurrentValue = false, Callback = function(v) Config.TeamLine = v end})
VisualTab:CreateColorPicker({Name = "Team Line Color", Color = Config.TeamLineColor, Callback = function(v) Config.TeamLineColor = v end})
VisualTab:CreateToggle({Name = "Team Dot", CurrentValue = false, Callback = function(v) Config.TeamDot = v end})
VisualTab:CreateToggle({Name = "Team Name + HP%", CurrentValue = false, Callback = function(v) Config.TeamName = v end})
VisualTab:CreateColorPicker({Name = "Team Name Color", Color = Config.TeamNameColor, Callback = function(v) Config.TeamNameColor = v end})
VisualTab:CreateToggle({Name = "Team Health Bar", CurrentValue = false, Callback = function(v) Config.TeamHealth = v end})
VisualTab:CreateToggle({Name = "Team Skeleton", CurrentValue = false, Callback = function(v) Config.TeamSkeleton = v end})
VisualTab:CreateColorPicker({Name = "Team Skeleton Color", Color = Config.TeamSkeletonColor, Callback = function(v) Config.TeamSkeletonColor = v end})

VisualTab:CreateSection("World Map")
VisualTab:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Lighting.Brightness = v and 3 or 1 Lighting.GlobalShadows = not v end})
VisualTab:CreateToggle({Name = "No Fog", CurrentValue = false, Callback = function(v) Lighting.FogEnd = v and 100000 or 1000 end})

-- ═══ TAB COMBAT ═══
local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = false, Callback = function(v) Config.AimbotEnabled = v end})
CombatTab:CreateSlider({Name = "Aim Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) Config.AimSmoothness = v end})
CombatTab:CreateDropdown({Name = "Aim Target", Options = {"AllEnemy", "PlayerEnemy", "BotEnemy"}, CurrentOption = {"AllEnemy"}, Callback = function(opt) Config.AimTarget = opt[1] end})
CombatTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "Body", "Foot"}, CurrentOption = {"Head"}, Callback = function(opt) Config.AimPart = opt[1] end})
CombatTab:CreateSlider({Name = "Aim FOV", Range = {0, 360}, Increment = 10, CurrentValue = 90, Callback = function(v) Config.AimFOV = v end})
CombatTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Callback = function(v) Config.ShowFOV = v end})
CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Config.TeamCheckAim = v end})
CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = false, Callback = function(v) Config.WallCheckAim = v end})

CombatTab:CreateSection("Hitbox Expander")
CombatTab:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) Config.HitboxEnabled = v end})
CombatTab:CreateSlider({Name = "Hitbox Size", Range = {0, 50}, Increment = 1, CurrentValue = 10, Callback = function(v) Config.HitboxSize = v end})

-- ═══ TAB PLAYER ═══
local PlayerTab = Window:CreateTab("Player", 4483362458)
PlayerTab:CreateSection("Camera")
PlayerTab:CreateSlider({Name = "Camera FOV", Range = {50, 120}, Increment = 1, CurrentValue = 70, Callback = function(v) Config.CameraFOV = v end})
PlayerTab:CreateToggle({Name = "Third Person", CurrentValue = false, Callback = function(v) if v then LP.CameraMode = Enum.CameraMode.Classic LP.CameraMaxZoomDistance = 20 else LP.CameraMode = Enum.CameraMode.LockFirstPerson end end})

PlayerTab:CreateSection("Anti-Cheat")
PlayerTab:CreateToggle({Name = "Anti Fling", CurrentValue = false, Callback = function(v) Config.AntiFling = v end})
PlayerTab:CreateToggle({Name = "Anti Void", CurrentValue = false, Callback = function(v) Config.AntiVoid = v end})
PlayerTab:CreateToggle({Name = "Anti AFK", CurrentValue = false, Callback = function(v) Config.AntiAFK = v end})

PlayerTab:CreateSection("Movement Buff")
PlayerTab:CreateToggle({Name = "Fast Regen", CurrentValue = false, Callback = function(v) Config.FastRegen = v end})
PlayerTab:CreateSlider({Name = "Regen Speed", Range = {1, 100}, Increment = 1, CurrentValue = 10, Callback = function(v) Config.RegenSpeed = v end})
PlayerTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Config.SpeedHack = v end})
PlayerTab:CreateSlider({Name = "Speed Value", Range = {16, 300}, Increment = 1, CurrentValue = 50, Callback = function(v) Config.SpeedValue = v end})
PlayerTab:CreateToggle({Name = "Jump Hack", CurrentValue = false, Callback = function(v) Config.JumpHack = v end})
PlayerTab:CreateSlider({Name = "Jump Value", Range = {50, 300}, Increment = 1, CurrentValue = 100, Callback = function(v) Config.JumpValue = v end})
PlayerTab:CreateToggle({Name = "Infinity Jump", CurrentValue = false, Callback = function(v) Config.InfJump = v end})
PlayerTab:CreateToggle({Name = "No Clip", CurrentValue = false, Callback = function(v) Config.NoClip = v end})
PlayerTab:CreateToggle({Name = "Fly", CurrentValue = false, Callback = function(v) Config.Fly = v end})
PlayerTab:CreateSlider({Name = "Fly Speed", Range = {10, 200}, Increment = 1, CurrentValue = 50, Callback = function(v) Config.FlySpeed = v end})

-- ═══ TAB WEAPON ═══
local WeaponTab = Window:CreateTab("Weapon", 4483362458)
WeaponTab:CreateSection("Weapon Mods")
WeaponTab:CreateToggle({Name = "Infinity Ammo", CurrentValue = false, Callback = function(v) Config.InfAmmo = v end})
WeaponTab:CreateToggle({Name = "Infinity Grenade", CurrentValue = false, Callback = function(v) Config.InfGrenade = v end})
WeaponTab:CreateToggle({Name = "No Recoil", CurrentValue = false, Callback = function(v) Config.NoRecoil = v end})
WeaponTab:CreateToggle({Name = "No Spread", CurrentValue = false, Callback = function(v) Config.NoSpread = v end})
WeaponTab:CreateToggle({Name = "Rapid Fire (EXTREME)", CurrentValue = false, Callback = function(v) Config.RapidFire = v end})
WeaponTab:CreateSlider({Name = "Fire Rate", Range = {1000, 1000000}, Increment = 1000, CurrentValue = 100000, Callback = function(v) Config.FireRate = v end})
WeaponTab:CreateToggle({Name = "Fast Reload", CurrentValue = false, Callback = function(v) Config.FastReload = v end})
WeaponTab:CreateSlider({Name = "Reload Speed (s)", Range = {0, 10}, Increment = 0.1, CurrentValue = 0, Callback = function(v) Config.ReloadSpeed = v end})
WeaponTab:CreateToggle({Name = "Damage Hack", CurrentValue = false, Callback = function(v) Config.DamageHack = v end})
WeaponTab:CreateSlider({Name = "Damage Boost", Range = {1, 99999999}, Increment = 1000, CurrentValue = 100, Callback = function(v) Config.DamageBoost = v end})

-- ═══ TAB FARM ═══
local FarmTab = Window:CreateTab("Farm", 4483362458)
FarmTab:CreateSection("Bring Enemy")
FarmTab:CreateToggle({Name = "Bring Enemy", CurrentValue = false, Callback = function(v) Config.BringToggle = v end})
FarmTab:CreateDropdown({Name = "Bring Target", Options = {"AllEnemy", "PlayerEnemy", "BotEnemy"}, CurrentOption = {"AllEnemy"}, Callback = function(opt) Config.BringTarget = opt[1] end})
FarmTab:CreateSlider({Name = "Bring Distance", Range = {1, 100}, Increment = 1, CurrentValue = 3, Callback = function(v) Config.BringDistance = v end})

FarmTab:CreateSection("Telekill Pro")
FarmTab:CreateToggle({Name = "Telekill Pro", CurrentValue = false, Callback = function(v) Config.TelekillPro = v end})
FarmTab:CreateDropdown({Name = "Telekill Target", Options = {"AllEnemy", "PlayerEnemy", "BotEnemy"}, CurrentOption = {"AllEnemy"}, Callback = function(opt) Config.TelekillTarget = opt[1] end})
FarmTab:CreateDropdown({Name = "Telekill Position", Options = {"Front", "Behind", "Above", "Below"}, CurrentOption = {"Front"}, Callback = function(opt) Config.TelekillPosition = opt[1] end})
FarmTab:CreateSlider({Name = "Telekill Distance", Range = {1, 100}, Increment = 1, CurrentValue = 3, Callback = function(v) Config.TelekillDistance = v end})

-- ========================================================
-- [ HELPER FUNCTIONS ]
-- ========================================================
local function IsEnemy(plr)
    if plr == LP then return false end
    if plr.Team and LP.Team and plr.Team == LP.Team then return false end
    return true
end

local function CheckBotStatus(botModel)
    local botTeam = botModel:GetAttribute("BotTeam")
    if LP.Team and botTeam and tostring(botTeam) == tostring(LP.Team.Name) then
        return false
    end
    return true
end

local function GetValidTargets()
    local targets = {}
    
    -- Player
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(targets, {char = plr.Character, isBot = false, name = plr.Name, isEnemy = IsEnemy(plr)})
            end
        end
    end
    
    -- Bot (Cache tiap 1 detik)
    if tick() - lastBotScan > 1 then
        cachedBots = {}
        local botFolders = {Workspace:FindFirstChild("ServerBots"), Workspace:FindFirstChild("Bots")}
        for _, folder in pairs(botFolders) do
            if folder then
                for _, obj in pairs(folder:GetChildren()) do
                    if obj:IsA("Model") and obj:GetAttribute("IsBot") and obj:FindFirstChild("HumanoidRootPart") then
                        table.insert(cachedBots, obj)
                    end
                end
            end
        end
        if #cachedBots == 0 then
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj:GetAttribute("IsBot") and obj:FindFirstChild("HumanoidRootPart") then
                    table.insert(cachedBots, obj)
                end
            end
        end
        lastBotScan = tick()
    end
    
    for _, bot in pairs(cachedBots) do
        if bot.Parent and bot:FindFirstChild("HumanoidRootPart") then
            local hum = bot:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(targets, {char = bot, isBot = true, name = bot.Name, isEnemy = CheckBotStatus(bot)})
            end
        end
    end
    
    return targets
end

local function GetBones(char)
    local bones = {}
    if char:FindFirstChild("UpperTorso") then
        local H = char:FindFirstChild("Head")
        local UT = char:FindFirstChild("UpperTorso")
        local LT = char:FindFirstChild("LowerTorso")
        local LUA = char:FindFirstChild("LeftUpperArm")
        local RUA = char:FindFirstChild("RightUpperArm")
        local LUL = char:FindFirstChild("LeftUpperLeg")
        local RUL = char:FindFirstChild("RightUpperLeg")
        if H and UT then table.insert(bones, {H, UT}) end
        if UT and LUA then table.insert(bones, {UT, LUA}) end
        if UT and RUA then table.insert(bones, {UT, RUA}) end
        if LT and LUL then table.insert(bones, {LT, LUL}) end
        if LT and RUL then table.insert(bones, {LT, RUL}) end
    elseif char:FindFirstChild("Torso") then
        local H = char:FindFirstChild("Head")
        local T = char:FindFirstChild("Torso")
        local LA = char:FindFirstChild("Left Arm")
        local RA = char:FindFirstChild("Right Arm")
        local LL = char:FindFirstChild("Left Leg")
        local RL = char:FindFirstChild("Right Leg")
        if H and T then table.insert(bones, {H, T}) end
        if T and LA then table.insert(bones, {T, LA}) end
        if T and RA then table.insert(bones, {T, RA}) end
        if T and LL then table.insert(bones, {T, LL}) end
        if T and RL then table.insert(bones, {T, RL}) end
    end
    return bones
end

local function GetHealthColor(hp)
    if hp > 0.6 then
        return Color3.fromRGB(0, 255, 100)
    elseif hp > 0.3 then
        return Color3.fromRGB(255, 200, 0)
    else
        return Color3.fromRGB(255, 50, 50)
    end
end

-- ========================================================
-- [ AIMBOT ]
-- ========================================================
local function GetAimbotTarget()
    local closest, dist = nil, Config.AimFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    for _, data in ipairs(GetValidTargets()) do
        if (Config.AimTarget == "AllEnemy" and data.isEnemy) or 
           (Config.AimTarget == "PlayerEnemy" and not data.isBot and data.isEnemy) or 
           (Config.AimTarget == "BotEnemy" and data.isBot and data.isEnemy) then
            
            local char = data.char
            local part = Config.AimPart == "Head" and char:FindFirstChild("Head") or 
                         (Config.AimPart == "Foot" and (char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg"))) or 
                         char.HumanoidRootPart
            
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if d < dist then 
                        local canShoot = true
                        if Config.WallCheckAim then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterDescendantsInstances = {LP.Character, Camera}
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            local ray = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
                            if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then 
                                canShoot = false 
                            end
                        end
                        if canShoot then
                            dist = d 
                            closest = part 
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService:BindToRenderStep("RENXX_Aimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not Config.AimbotEnabled then return end
    local target = GetAimbotTarget()
    if target then
        local smooth = 1 / math.max(1, Config.AimSmoothness)
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), smooth)
    end
end)

-- ========================================================
-- [ PREMIUM ESP RENDER ]
-- ========================================================
local function CreateESP(instance)
    if ESPCache[instance] then return ESPCache[instance] end
    local ok, result = pcall(function()
        return {
            Box = Drawing.new("Square"),
            Line = Drawing.new("Line"),
            Dot = Drawing.new("Circle"),
            Name = Drawing.new("Text"),
            HealthBar = Drawing.new("Square"),
            Skel = {
                Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), 
                Drawing.new("Line"), Drawing.new("Line")
            }
        }
    end)
    if ok and result then
        result.Box.Thickness = 1.5
        result.Box.Filled = false
        result.Line.Thickness = 1.5
        result.Dot.Thickness = 1
        result.Dot.Filled = true
        result.Dot.NumSides = 12
        result.Dot.Radius = 4
        result.Name.Center = true
        result.Name.Outline = true
        result.Name.Size = 13
        result.Name.Font = 2
        result.HealthBar.Filled = true
        ESPCache[instance] = result
        return result
    end
    return nil
end

local function RemoveESP(instance)
    if ESPCache[instance] then
        for _, obj in pairs(ESPCache[instance]) do
            pcall(function()
                if typeof(obj) == "table" then 
                    for _, line in pairs(obj) do line:Remove() end
                else obj:Remove() end
            end)
        end
        ESPCache[instance] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Visible = Config.AimbotEnabled and Config.ShowFOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = (Camera.ViewportSize.Y / 2) * (Config.AimFOV / 180)
    end

    for char, objs in pairs(ESPCache) do
        if not char or not char.Parent or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            RemoveESP(char)
        end
    end

    if not Config.EspEnabled then return end

    for _, target in ipairs(GetValidTargets()) do
        local char = target.char
        if char and char.Parent then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local head = char:FindFirstChild("Head") or hrp
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if dist <= Config.EspMaxDist and onScreen then
                        local objs = CreateESP(char)
                        if objs then
                            local enemy = target.isEnemy
                            local isBot = target.isBot
                            local hrpPos = Camera:WorldToViewportPoint(hrp.Position)
                            local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg") or hrp
                            local footPos = Camera:WorldToViewportPoint(foot.Position)
                            
                            local boxH = math.abs(headPos.Y - footPos.Y)
                            local boxW = boxH / 2
                            local boxX = headPos.X - (boxW / 2)
                            local boxY = headPos.Y
                            
                            -- 1. BOX (Full atau Corner)
                            local boxEnabled = (enemy and Config.EnemyBox) or (not enemy and Config.TeamBox)
                            local boxColor = enemy and Config.EnemyBoxColor or Config.TeamBoxColor
                            
                            if boxEnabled and Config.EspStyle == "Full" then
                                objs.Box.Visible = true
                                objs.Box.Color = boxColor
                                objs.Box.Thickness = 1.5
                                objs.Box.Size = Vector2.new(boxW, boxH)
                                objs.Box.Position = Vector2.new(boxX, boxY)
                            elseif boxEnabled and Config.EspStyle == "Corner" then
                                -- Corner style: pakai 4 garis tipis di sudut
                                -- (Skip untuk hemat object, pakai Full box aja)
                                objs.Box.Visible = true
                                objs.Box.Color = boxColor
                                objs.Box.Thickness = 1.5
                                objs.Box.Size = Vector2.new(boxW, boxH)
                                objs.Box.Position = Vector2.new(boxX, boxY)
                            else 
                                objs.Box.Visible = false 
                            end
                            
                            -- 2. LINE + DOT
                            local lineEnabled = (enemy and Config.EnemyLine) or (not enemy and Config.TeamLine)
                            local dotEnabled = (enemy and Config.EnemyDot) or (not enemy and Config.TeamDot)
                            local lineColor = enemy and Config.EnemyLineColor or Config.TeamLineColor
                            
                            if lineEnabled then
                                objs.Line.Visible = true
                                objs.Line.Color = lineColor
                                local startX = Camera.ViewportSize.X / 2
                                local startY = Camera.ViewportSize.Y
                                if Config.EspLinePosition == "Top" then startY = 0
                                elseif Config.EspLinePosition == "Center" then startY = Camera.ViewportSize.Y / 2 end
                                
                                local endX = boxX + (boxW/2)
                                local endY = boxY + boxH
                                
                                objs.Line.From = Vector2.new(startX, startY)
                                objs.Line.To = Vector2.new(endX, endY)
                                
                                if dotEnabled then
                                    objs.Dot.Visible = true
                                    objs.Dot.Color = lineColor
                                    objs.Dot.Position = Vector2.new(endX, endY)
                                else
                                    objs.Dot.Visible = false
                                end
                            else 
                                objs.Line.Visible = false 
                                objs.Dot.Visible = false
                            end
                            
                            -- 3. NAME + HP%
                            local nameEnabled = (enemy and Config.EnemyName) or (not enemy and Config.TeamName)
                            if nameEnabled then
                                objs.Name.Visible = true
                                local tag = (Config.ShowNpcTag and isBot and "[BOT] ") or ""
                                local hpPercent = math.floor((hum.Health / hum.MaxHealth) * 100)
                                objs.Name.Text = tag .. target.name .. " [" .. hpPercent .. "%]"
                                objs.Name.Position = Vector2.new(boxX + (boxW / 2), boxY - 16)
                                objs.Name.Color = enemy and Config.EnemyNameColor or Config.TeamNameColor
                            else objs.Name.Visible = false end
                            
                            -- 4. HEALTH BAR (Gradient)
                            local healthEnabled = (enemy and Config.EnemyHealth) or (not enemy and Config.TeamHealth)
                            if healthEnabled then
                                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                objs.HealthBar.Visible = true
                                objs.HealthBar.Size = Vector2.new(boxW * hpPercent, 3)
                                objs.HealthBar.Position = Vector2.new(boxX, boxY + boxH + 3)
                                objs.HealthBar.Color = GetHealthColor(hpPercent)
                            else objs.HealthBar.Visible = false end

                            -- 5. SKELETON
                            local skelEnabled = (enemy and Config.EnemySkeleton) or (not enemy and Config.TeamSkeleton)
                            if skelEnabled then
                                local bones = GetBones(char)
                                local skelColor = enemy and Config.EnemySkeletonColor or Config.TeamSkeletonColor
                                for i = 1, 5 do
                                    local line = objs.Skel[i]
                                    if line and bones[i] and bones[i][1] and bones[i][2] then
                                        local s1, o1 = Camera:WorldToViewportPoint(bones[i][1].Position)
                                        local s2, o2 = Camera:WorldToViewportPoint(bones[i][2].Position)
                                        if o1 and o2 then
                                            line.Visible = true
                                            line.From = Vector2.new(s1.X, s1.Y)
                                            line.To = Vector2.new(s2.X, s2.Y)
                                            line.Color = skelColor
                                            line.Thickness = 1
                                        else line.Visible = false end
                                    elseif line then line.Visible = false end
                                end
                            else
                                for _, line in pairs(objs.Skel) do if line then line.Visible = false end end
                            end
                        end
                    else
                        local objs = ESPCache[char]
                        if objs then
                            objs.Box.Visible = false; objs.Line.Visible = false
                            objs.Dot.Visible = false; objs.Name.Visible = false
                            objs.HealthBar.Visible = false
                            for _, line in pairs(objs.Skel) do if line then line.Visible = false end end
                        end
                    end
                end
            end
        end
    end
end)

-- ========================================================
-- [ HITBOX EXPANDER ]
-- ========================================================
local origSizes = {}
task.spawn(function()
    while task.wait(0.5) do
        if Config.HitboxEnabled then
            for _, data in ipairs(GetValidTargets()) do
                local char = data.char
                local head = char:FindFirstChild("Head")
                if head then
                    if not origSizes[head] then origSizes[head] = head.Size end
                    head.Size = origSizes[head] * Config.HitboxSize
                    head.Transparency = 0.5
                    head.CanCollide = false
                end
            end
        else
            for head, size in pairs(origSizes) do
                if head and head.Parent then
                    head.Size = size
                    head.Transparency = 0
                    head.CanCollide = true
                end
            end
            origSizes = {}
        end
    end
end)

-- ========================================================
-- [ WEAPON MODS ]
-- ========================================================
local function ApplyMods(tool)
    if not tool:IsA("Tool") then return end
    if Config.InfGrenade then
        local n = string.lower(tool.Name)
        if string.find(n, "grenade") or string.find(n, "frag") or string.find(n, "throw") then
            pcall(function() tool:SetAttribute("ammo", math.huge) end)
            pcall(function() tool:SetAttribute("count", math.huge) end)
        end
    end
    if string.find(tool.Name, "CustomGun") then
        if Config.InfAmmo then pcall(function() tool:SetAttribute("magazineSize", math.huge) end) end
        if Config.NoRecoil then pcall(function() tool:SetAttribute("recoilMin", Vector2.new(0,0)) tool:SetAttribute("recoilMax", Vector2.new(0,0)) end) end
        if Config.NoSpread then pcall(function() tool:SetAttribute("spread", 0) end) end
        if Config.DamageHack then pcall(function() tool:SetAttribute("damage", Config.DamageBoost) end) end
        if Config.RapidFire then pcall(function() tool:SetAttribute("rateOfFire", Config.FireRate) end) end
        if Config.FastReload then pcall(function() tool:SetAttribute("reloadTime", Config.ReloadSpeed) end) end
    end
end

task.spawn(function()
    while task.wait(0.1) do
        local char = LP.Character
        if char then
            local equipped = char:FindFirstChildOfClass("Tool")
            if equipped then pcall(function() ApplyMods(equipped) end) end
            local backpack = LP:FindFirstChild("Backpack")
            if backpack then
                for _, tool in pairs(backpack:GetChildren()) do
                    pcall(function() ApplyMods(tool) end)
                end
            end
        end
    end
end)

-- ========================================================
-- [ MOVEMENT & FLY ]
-- ========================================================
local FlyBV, FlyBG
local function StopFly()
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end
    if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then LP.Character.Humanoid.PlatformStand = false end
end

RunService.Stepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    hum.WalkSpeed = Config.SpeedHack and Config.SpeedValue or 16
    if Config.JumpHack then hum.JumpHeight = Config.JumpValue end
    if Config.NoClip then
        for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    if Config.FastRegen and hum.Health < hum.MaxHealth then
        hum.Health = math.min(hum.MaxHealth, hum.Health + (Config.RegenSpeed * 0.5))
    end
    if Config.AntiFling then
        if hrp.AssemblyLinearVelocity.Magnitude > 500 or hrp.AssemblyAngularVelocity.Magnitude > 100 then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
    if Config.AntiVoid and hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 50, 0) end

    if Config.Fly then
        if not FlyBV then
            FlyBV = Instance.new("BodyVelocity", hrp)
            FlyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            FlyBV.Velocity = Vector3.zero
            FlyBG = Instance.new("BodyGyro", hrp)
            FlyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            FlyBG.P = 1000
            hum.PlatformStand = true
        end
        FlyBV.Velocity = hum.MoveDirection * Config.FlySpeed
        FlyBG.CFrame = Camera.CFrame
    else
        if FlyBV then StopFly() end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

LP.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ========================================================
-- [ FARM ]
-- ========================================================
local currentTelekillTarget = nil
task.spawn(function()
    while task.wait(0.1) do
        local char = LP.Character
        if not char then continue end
        local myHRP = char:FindFirstChild("HumanoidRootPart")
        if not myHRP then continue end

        local validTargets = GetValidTargets()

        if Config.BringToggle then
            for _, data in ipairs(validTargets) do
                local isValid = false
                if Config.BringTarget == "AllEnemy" and data.isEnemy then isValid = true
                elseif Config.BringTarget == "PlayerEnemy" and not data.isBot and data.isEnemy then isValid = true
                elseif Config.BringTarget == "BotEnemy" and data.isBot and data.isEnemy then isValid = true end
                if isValid then
                    pcall(function()
                        data.char.HumanoidRootPart.CFrame = myHRP.CFrame * CFrame.new(0, 0, -Config.BringDistance)
                    end)
                end
            end
        end

        if Config.TelekillPro then
            if not currentTelekillTarget or not currentTelekillTarget.Parent or not currentTelekillTarget.Parent:FindFirstChild("Humanoid") or currentTelekillTarget.Parent.Humanoid.Health <= 0 then
                currentTelekillTarget = nil
                local closestDist = math.huge
                for _, data in ipairs(validTargets) do
                    local isValid = false
                    if Config.TelekillTarget == "AllEnemy" and data.isEnemy then isValid = true
                    elseif Config.TelekillTarget == "PlayerEnemy" and not data.isBot and data.isEnemy then isValid = true
                    elseif Config.TelekillTarget == "BotEnemy" and data.isBot and data.isEnemy then isValid = true end
                    if isValid then
                        local d = (myHRP.Position - data.char.HumanoidRootPart.Position).Magnitude
                        if d < closestDist then closestDist = d currentTelekillTarget = data.char.HumanoidRootPart end
                    end
                end
            end
            if currentTelekillTarget then
                local offset = CFrame.new(0, 0, -Config.TelekillDistance)
                if Config.TelekillPosition == "Above" then offset = CFrame.new(0, Config.TelekillDistance, 0)
                elseif Config.TelekillPosition == "Below" then offset = CFrame.new(0, -Config.TelekillDistance, 0)
                elseif Config.TelekillPosition == "Behind" then offset = CFrame.new(0, 0, Config.TelekillDistance) end
                pcall(function()
                    myHRP.CFrame = currentTelekillTarget.CFrame * offset
                end)
            end
        end
    end
end)

-- ========================================================
-- [ BOOT ]
-- ========================================================
Rayfield:Notify({Title="RENXX HUB v5.0 Premium", Content="Loaded! ESP Premium Ready.", Duration=5})
print("===================================================")
print("RENXX HUB v5.0 - PREMIUM EDITION")
print("===================================================")
print("Premium ESP: Gradient Health, HP%, Dot Marker")
print("Nyalain 'ESP Master' + 'Enemy Box' + 'Enemy Line'")
print("===================================================")
