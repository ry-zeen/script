-- ═══════════════════════════════════════════════════════════════════════════════════════════
--   RENXX ULTIMATE FPS RECOIL — v26.0 | NO FEATURE REMOVED & FIXED
--   By: Ren & Deep | UI: Orion | Game: FPS Recoil
--   
--   FITUR LENGKAP:
--   ✅ FIXED: Kamera macet (Aimbot Smoothing dirombak)
--   ✅ FIXED: Semua Fitur Weapon (Ammo Boost, Reload Speed, No Recoil, dll) 
--   ✅ FIXED: POV Silent Aim & Aimbot permanen
--   ✅ ADDED: ESP Skeleton, Health Bar, Team Check
-- ═══════════════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local HasDrawing = pcall(function() return Drawing.new("Circle") end)

-- ═══ CONFIGURATION ═══
local CFG = {
    Visual = {
        Enabled = false, MaxDist = 500, TeamCheck = true, BoxThick = 1, TracerThick = 1,
        BoxEnemy = false, BoxEnemyColor = Color3.fromRGB(255, 50, 50),
        NameEnemy = false, NameEnemyColor = Color3.fromRGB(255, 255, 255),
        HealthEnemy = false, HealthEnemyColor = Color3.fromRGB(0, 255, 0),
        TracerEnemy = false, TracerEnemyColor = Color3.fromRGB(255, 50, 50),
        BoxTeam = false, BoxTeamColor = Color3.fromRGB(0, 100, 255),
        NameTeam = false, NameTeamColor = Color3.fromRGB(200, 200, 255),
        HealthTeam = false, HealthTeamColor = Color3.fromRGB(0, 255, 0),
        TracerTeam = false, TracerTeamColor = Color3.fromRGB(0, 100, 255),
        Skeleton = false, SkeletonColor = Color3.fromRGB(255, 255, 255),
        BotTag = false, Fullbright = false
    },
    Combat = {
        Aimbot = false, ABSmooth = 0.3, ABPart = "Hitbox_Head", WallCheck = true, TeamCheck = true,
        ABKey = "Always", 
        ShowPOVAB = false, POVABColor = Color3.fromRGB(255, 50, 50), ABPOVSize = 200,
        
        SilentAim = false, SAPart = "Hitbox_Head", HitChance = 100,
        ShowPOVSA = false, POVSAColor = Color3.fromRGB(0, 255, 0), SAPOVSize = 150,
        SnapLine = false, SnapLineColor = Color3.fromRGB(0, 255, 0)
    },
    Player = {
        SpeedHack = false, SpeedValue = 60, JumpHack = false, JumpValue = 100,
        InfiniteJump = false, NoClip = false, FlyHack = false, FlySpeed = 50
    },
    Weapon = {
        InfAmmo = false, AmmoReserveBoost = false, RapidFire = false, FireRate = 100,
        FastReload = false, ReloadSpeed = 100, NoRecoil = false, NoSpread = false,
        DamageMult = false, DamageValue = 999
    },
    Farm = {
        BringEnemy = false, BringMode = "All", BringJarak = 10, BringTeamCheck = true,
        KillAura = false, KillAuraRange = 20, AntiAFK = true
    }
}

-- ═══ DRAWING SETUP ═══
local Drawings = { ESP = {}, Skeleton = {}, AB_FOV = nil, AB_POVLine = nil, SA_FOV = nil, SA_POVLine = nil, SnapLine = nil }

if HasDrawing then
    pcall(function()
        Drawings.AB_FOV = Drawing.new("Circle")
        Drawings.AB_FOV.Thickness = 1; Drawings.AB_FOV.NumSides = 40; Drawings.AB_FOV.Filled = false
        Drawings.AB_POVLine = Drawing.new("Line"); Drawings.AB_POVLine.Thickness = 1.5
        
        Drawings.SA_FOV = Drawing.new("Circle")
        Drawings.SA_FOV.Thickness = 1; Drawings.SA_FOV.NumSides = 40; Drawings.SA_FOV.Filled = false
        Drawings.SA_POVLine = Drawing.new("Line"); Drawings.SA_POVLine.Thickness = 1.5
        
        Drawings.SnapLine = Drawing.new("Line"); Drawings.SnapLine.Thickness = 1
    end)
end

local WallRayParams = RaycastParams.new()
WallRayParams.FilterType = Enum.RaycastFilterType.Exclude
WallRayParams.IgnoreWater = true

-- ═══ HELPER FUNCTIONS ═══
local function IsTeammate(model)
    local plr = Players:GetPlayerFromCharacter(model)
    if plr and LP.Team and plr.Team == LP.Team then return true end
    return false
end

local function GetHitboxPart(model, partType)
    local hitbox = model:FindFirstChild("Hitbox")
    if not hitbox then return nil end
    if partType == "Head" or partType == "Hitbox_Head" then return hitbox:FindFirstChild("Hitbox_Head")
    elseif partType == "Body" or partType == "Hitbox_Torso" then return hitbox:FindFirstChild("Hitbox_Torso")
    elseif partType == "Foot" then return hitbox:FindFirstChild("Hitbox_Left Leg") or hitbox:FindFirstChild("Hitbox_Right Leg")
    end
    return nil
end

local function IsWallBanging(part, char)
    if not CFG.Combat.WallCheck then return true end
    WallRayParams.FilterDescendantsInstances = {LP.Character, Camera, char}
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local ray = Workspace:Raycast(origin, direction, WallRayParams)
    return ray == nil
end

local function GetClosestTarget(partName, checkTeam, checkWall)
    local closest, shortest = nil, math.huge
    local camPos = Camera.CFrame.Position
    
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model ~= LP.Character and model:FindFirstChild("Hitbox") then
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

-- ═══ UI INITIALIZATION ═══
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()
local Window = OrionLib:MakeWindow({Name = "RENXX v26.0 | Ultimate Fix", HidePremium = false, SaveConfig = true, ConfigFolder = "RENXX_ULTIMATE"})

-- [ TAB VISUAL ]
local VisualTab = Window:MakeTab({Name = "VISUAL", Icon = "rbxassetid://4483345998"})
VisualTab:AddSection({Name = "ESP Global Settings"})
VisualTab:AddToggle({Name = "Enable ESP", Default = false, Save = true, Callback = function(s) CFG.Visual.Enabled = s end})
VisualTab:AddSlider({Name = "Max Distance", Min = 100, Max = 1000, Default = 500, Increment = 50, Callback = function(v) CFG.Visual.MaxDist = v end})
VisualTab:AddToggle({Name = "Team Check", Default = true, Save = true, Callback = function(s) CFG.Visual.TeamCheck = s end})
VisualTab:AddSlider({Name = "Box Thickness", Min = 1, Max = 5, Default = 1, Increment = 1, Callback = function(v) CFG.Visual.BoxThick = v end})
VisualTab:AddSlider({Name = "Tracer Thickness", Min = 1, Max = 5, Default = 1, Increment = 1, Callback = function(v) CFG.Visual.TracerThick = v end})

VisualTab:AddSection({Name = "ESP Enemy"})
VisualTab:AddToggle({Name = "Box Enemy", Default = false, Save = true, Callback = function(s) CFG.Visual.BoxEnemy = s end})
VisualTab:AddColorpicker({Name = "Box Color", Default = Color3.fromRGB(255, 50, 50), Callback = function(c) CFG.Visual.BoxEnemyColor = c end})
VisualTab:AddToggle({Name = "Name Enemy", Default = false, Save = true, Callback = function(s) CFG.Visual.NameEnemy = s end})
VisualTab:AddColorpicker({Name = "Name Color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) CFG.Visual.NameEnemyColor = c end})
VisualTab:AddToggle({Name = "Health Enemy", Default = false, Save = true, Callback = function(s) CFG.Visual.HealthEnemy = s end})
VisualTab:AddColorpicker({Name = "Health Color", Default = Color3.fromRGB(0, 255, 0), Callback = function(c) CFG.Visual.HealthEnemyColor = c end})
VisualTab:AddToggle({Name = "Tracers Enemy", Default = false, Save = true, Callback = function(s) CFG.Visual.TracerEnemy = s end})
VisualTab:AddColorpicker({Name = "Tracer Color", Default = Color3.fromRGB(255, 50, 50), Callback = function(c) CFG.Visual.TracerEnemyColor = c end})

VisualTab:AddSection({Name = "ESP Team"})
VisualTab:AddToggle({Name = "Box Team", Default = false, Save = true, Callback = function(s) CFG.Visual.BoxTeam = s end})
VisualTab:AddColorpicker({Name = "Box Color", Default = Color3.fromRGB(0, 100, 255), Callback = function(c) CFG.Visual.BoxTeamColor = c end})
VisualTab:AddToggle({Name = "Name Team", Default = false, Save = true, Callback = function(s) CFG.Visual.NameTeam = s end})
VisualTab:AddColorpicker({Name = "Name Color", Default = Color3.fromRGB(200, 200, 255), Callback = function(c) CFG.Visual.NameTeamColor = c end})
VisualTab:AddToggle({Name = "Health Team", Default = false, Save = true, Callback = function(s) CFG.Visual.HealthTeam = s end})
VisualTab:AddColorpicker({Name = "Health Color", Default = Color3.fromRGB(0, 255, 0), Callback = function(c) CFG.Visual.HealthTeamColor = c end})
VisualTab:AddToggle({Name = "Tracers Team", Default = false, Save = true, Callback = function(s) CFG.Visual.TracerTeam = s end})
VisualTab:AddColorpicker({Name = "Tracer Color", Default = Color3.fromRGB(0, 100, 255), Callback = function(c) CFG.Visual.TracerTeamColor = c end})

VisualTab:AddSection({Name = "ESP Skeleton & Extra"})
VisualTab:AddToggle({Name = "ESP Skeleton", Default = false, Save = true, Callback = function(s) CFG.Visual.Skeleton = s end})
VisualTab:AddColorpicker({Name = "Skeleton Color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) CFG.Visual.SkeletonColor = c end})
VisualTab:AddToggle({Name = "Bot Name Tag", Default = false, Save = true, Callback = function(s) CFG.Visual.BotTag = s end})
VisualTab:AddToggle({Name = "Fullbright", Default = false, Save = true, Callback = function(s)
    if s then Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    else Lighting.Brightness = 2; Lighting.FogEnd = 100000 end
end})

-- [ TAB COMBAT ]
local CombatTab = Window:MakeTab({Name = "COMBAT", Icon = "rbxassetid://4483345998"})
CombatTab:AddSection({Name = "AIMBOT"})
CombatTab:AddToggle({Name = "Aimbot", Default = false, Save = true, Callback = function(s) CFG.Combat.Aimbot = s end})
CombatTab:AddDropdown({Name = "Aimbot Mode", Default = "Always", Options = {"Always", "Hold (Right Click)"}, Save = true, Callback = function(v) CFG.Combat.ABKey = v end})
CombatTab:AddToggle({Name = "Wall Check", Default = true, Save = true, Callback = function(s) CFG.Combat.WallCheck = s end})
CombatTab:AddToggle({Name = "Team Check", Default = true, Save = true, Callback = function(s) CFG.Combat.TeamCheck = s end})
CombatTab:AddSlider({Name = "Aim Smoothness", Min = 1, Max = 10, Default = 3, Increment = 1, Callback = function(v) CFG.Combat.ABSmooth = v/10 end})
CombatTab:AddDropdown({Name = "Aimbot Part", Default = "Head", Options = {"Head", "Body", "Foot"}, Save = true, Callback = function(v) CFG.Combat.ABPart = v end})
CombatTab:AddSlider({Name = "POV Size", Min = 50, Max = 800, Default = 200, Increment = 10, Callback = function(v) CFG.Combat.ABPOVSize = v end})
CombatTab:AddToggle({Name = "Show POV", Default = false, Save = true, Callback = function(s) CFG.Combat.ShowPOVAB = s end})
CombatTab:AddColorpicker({Name = "POV Color", Default = Color3.fromRGB(255, 50, 50), Callback = function(c) CFG.Combat.POVABColor = c end})

CombatTab:AddSection({Name = "SILENT AIM"})
CombatTab:AddToggle({Name = "Silent Aim", Default = false, Save = true, Callback = function(s) CFG.Combat.SilentAim = s end})
CombatTab:AddDropdown({Name = "Silent Aim Part", Default = "Head", Options = {"Head", "Body", "Foot"}, Save = true, Callback = function(v) CFG.Combat.SAPart = v end})
CombatTab:AddSlider({Name = "Hit Chance", Min = 1, Max = 100, Default = 100, Increment = 1, Callback = function(v) CFG.Combat.HitChance = v end})
CombatTab:AddSlider({Name = "POV SA Size", Min = 50, Max = 800, Default = 150, Increment = 10, Callback = function(v) CFG.Combat.SAPOVSize = v end})
CombatTab:AddToggle({Name = "Show POV SA", Default = false, Save = true, Callback = function(s) CFG.Combat.ShowPOVSA = s end})
CombatTab:AddColorpicker({Name = "POV SA Color", Default = Color3.fromRGB(0, 255, 0), Callback = function(c) CFG.Combat.POVSAColor = c end})
CombatTab:AddToggle({Name = "SnapLine", Default = false, Save = true, Callback = function(s) CFG.Combat.SnapLine = s end})
CombatTab:AddColorpicker({Name = "SnapLine Color", Default = Color3.fromRGB(0, 255, 0), Callback = function(c) CFG.Combat.SnapLineColor = c end})

-- [ TAB PLAYER ]
local PlayerTab = Window:MakeTab({Name = "PLAYER", Icon = "rbxassetid://4483345998"})
PlayerTab:AddToggle({Name = "Speed Hack", Default = false, Save = true, Callback = function(s) CFG.Player.SpeedHack = s end})
PlayerTab:AddSlider({Name = "Speed Value", Min = 16, Max = 200, Default = 60, Increment = 1, Callback = function(v) CFG.Player.SpeedValue = v end})
PlayerTab:AddToggle({Name = "Jump Hack", Default = false, Save = true, Callback = function(s) CFG.Player.JumpHack = s end})
PlayerTab:AddSlider({Name = "Jump Value", Min = 50, Max = 500, Default = 100, Increment = 10, Callback = function(v) CFG.Player.JumpValue = v end})
PlayerTab:AddToggle({Name = "Infinite Jump", Default = false, Save = true, Callback = function(s) CFG.Player.InfiniteJump = s end})
PlayerTab:AddToggle({Name = "No Clip", Default = false, Save = true, Callback = function(s) CFG.Player.NoClip = s end})
PlayerTab:AddToggle({Name = "Fly Hack", Default = false, Save = true, Callback = function(s) CFG.Player.FlyHack = s end})
PlayerTab:AddSlider({Name = "Fly Speed", Min = 10, Max = 200, Default = 50, Increment = 5, Callback = function(v) CFG.Player.FlySpeed = v end})

-- [ TAB WEAPON ]
local WeaponTab = Window:MakeTab({Name = "WEAPON", Icon = "rbxassetid://4483345998"})
WeaponTab:AddSection({Name = "Ammo & Fire"})
WeaponTab:AddToggle({Name = "Infinity Ammo", Default = false, Save = true, Callback = function(s) CFG.Weapon.InfAmmo = s end})
WeaponTab:AddToggle({Name = "Ammo Reserve Boost", Default = false, Save = true, Callback = function(s) CFG.Weapon.AmmoReserveBoost = s end})
WeaponTab:AddToggle({Name = "Rapid Fire", Default = false, Save = true, Callback = function(s) CFG.Weapon.RapidFire = s end})
WeaponTab:AddSlider({Name = "Fire Rate", Min = 1, Max = 100, Default = 100, Increment = 1, Callback = function(v) CFG.Weapon.FireRate = v end})
WeaponTab:AddToggle({Name = "Fast Reload", Default = false, Save = true, Callback = function(s) CFG.Weapon.FastReload = s end})
WeaponTab:AddSlider({Name = "Reload Speed", Min = 1, Max = 100, Default = 100, Increment = 1, Callback = function(v) CFG.Weapon.ReloadSpeed = v end})
WeaponTab:AddToggle({Name = "No Recoil", Default = false, Save = true, Callback = function(s) CFG.Weapon.NoRecoil = s end})
WeaponTab:AddToggle({Name = "No Spread", Default = false, Save = true, Callback = function(s) CFG.Weapon.NoSpread = s end})
WeaponTab:AddToggle({Name = "Damage Multiplier", Default = false, Save = true, Callback = function(s) CFG.Weapon.DamageMult = s end})
WeaponTab:AddSlider({Name = "Damage Value", Min = 1, Max = 999, Default = 999, Increment = 1, Callback = function(v) CFG.Weapon.DamageValue = v end})

-- [ TAB FARM ]
local FarmTab = Window:MakeTab({Name = "FARM", Icon = "rbxassetid://4483345998"})
FarmTab:AddToggle({Name = "Bring Enemy", Default = false, Save = true, Callback = function(s) CFG.Farm.BringEnemy = s end})
FarmTab:AddDropdown({Name = "Bring Mode", Default = "All", Options = {"All", "Single"}, Save = true, Callback = function(v) CFG.Farm.BringMode = v end})
FarmTab:AddSlider({Name = "Bring Jarak", Min = 2, Max = 50, Default = 10, Increment = 1, Callback = function(v) CFG.Farm.BringJarak = v end})
FarmTab:AddToggle({Name = "Kill Aura", Default = false, Save = true, Callback = function(s) CFG.Farm.KillAura = s end})
FarmTab:AddSlider({Name = "Kill Aura Range", Min = 5, Max = 100, Default = 20, Increment = 1, Callback = function(v) CFG.Farm.KillAuraRange = v end})

-- [ TAB MISC ]
local MiscTab = Window:MakeTab({Name = "MISC", Icon = "rbxassetid://4483345998"})
MiscTab:AddButton({Name = "Rejoin Server", Callback = function() pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end})
MiscTab:AddButton({Name = "Server Hop", Callback = function()
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, srv in pairs(servers) do
            if srv.playing < srv.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP); break end
        end
    end)
end})
MiscTab:AddToggle({Name = "Anti AFK", Default = true, Save = true, Callback = function(s) CFG.Farm.AntiAFK = s end})

-- ═══ CORE LOGIC & LOOPS ═══

-- 1. ESP RENDER (LENGKAP)
RunService.RenderStepped:Connect(function()
    if not HasDrawing then return end
    
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
    for model, skel in pairs(Drawings.Skeleton) do
        if not model.Parent then
            for _, line in pairs(skel) do line:Remove() end
            Drawings.Skeleton[model] = nil
        end
    end

    if not CFG.Visual.Enabled then
        for _, d in pairs(Drawings.ESP) do
            if d.Box then d.Box.Visible = false end
            if d.Name then d.Name.Visible = false end
            if d.Health then d.Health.Visible = false end
            if d.Tracer then d.Tracer.Visible = false end
        end
        for _, skel in pairs(Drawings.Skeleton) do for _, line in pairs(skel) do line.Visible = false end end
        return
    end

    local screenCenterBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local myPos = Camera.CFrame.Position

    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model ~= LP.Character and model:FindFirstChild("Hitbox") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local rootPart = model:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and rootPart then
                local dist = (rootPart.Position - myPos).Magnitude
                local isVisible = true
                
                if dist > CFG.Visual.MaxDist then isVisible = false end
                if CFG.Visual.TeamCheck and IsTeammate(model) then isVisible = false end

                local headPart = GetHitboxPart(model, "Head") or rootPart
                local legPart = GetHitboxPart(model, "Foot") or rootPart

                local topPos, topOn = Camera:WorldToViewportPoint(headPart.Position + Vector3.new(0, 0.3, 0))
                local botPos, botOn = Camera:WorldToViewportPoint(legPart.Position - Vector3.new(0, 1, 0))
                
                if not Drawings.ESP[model] then
                    Drawings.ESP[model] = {
                        Box = Drawing.new("Square"), Name = Drawing.new("Text"),
                        Health = Drawing.new("Square"), Tracer = Drawing.new("Line")
                    }
                    local d = Drawings.ESP[model]
                    d.Name.Center = true; d.Name.Outline = true; d.Health.Filled = true
                end

                local d = Drawings.ESP[model]
                
                if isVisible and topOn and botOn then
                    local boxHeight = math.abs(botPos.Y - topPos.Y)
                    local boxWidth = boxHeight * 0.35 
                    local boxX = topPos.X - (boxWidth / 2)
                    local boxY = topPos.Y
                    
                    local col = IsTeammate(model) and CFG.Visual.BoxTeamColor or CFG.Visual.BoxEnemyColor
                    
                    d.Box.Visible = (IsTeammate(model) and CFG.Visual.BoxTeam) or (not IsTeammate(model) and CFG.Visual.BoxEnemy)
                    d.Box.Size = Vector2.new(boxWidth, boxHeight)
                    d.Box.Position = Vector2.new(boxX, boxY)
                    d.Box.Color = col
                    d.Box.Thickness = CFG.Visual.BoxThick

                    d.Name.Visible = (IsTeammate(model) and CFG.Visual.NameTeam) or (not IsTeammate(model) and CFG.Visual.NameEnemy)
                    local botTag = CFG.Visual.BotTag and "[BOT] " or ""
                    d.Name.Text = botTag .. model.Name .. " [" .. math.floor(dist) .. "m]"
                    d.Name.Size = 13
                    d.Name.Position = Vector2.new(topPos.X, boxY - 16)
                    d.Name.Color = IsTeammate(model) and CFG.Visual.NameTeamColor or CFG.Visual.NameEnemyColor

                    d.Health.Visible = (IsTeammate(model) and CFG.Visual.HealthTeam) or (not IsTeammate(model) and CFG.Visual.HealthEnemy)
                    local hPerc = hum.Health / hum.MaxHealth
                    d.Health.Size = Vector2.new(2, boxHeight * hPerc)
                    d.Health.Position = Vector2.new(boxX - 5, boxY + (boxHeight * (1 - hPerc)))
                    d.Health.Color = IsTeammate(model) and CFG.Visual.HealthTeamColor or CFG.Visual.HealthEnemyColor

                    d.Tracer.Visible = (IsTeammate(model) and CFG.Visual.TracerTeam) or (not IsTeammate(model) and CFG.Visual.TracerEnemy)
                    d.Tracer.From = screenCenterBottom
                    d.Tracer.To = Vector2.new(topPos.X, botPos.Y)
                    d.Tracer.Color = IsTeammate(model) and CFG.Visual.TracerTeamColor or CFG.Visual.TracerEnemyColor
                    d.Tracer.Thickness = CFG.Visual.TracerThick

                    -- Skeleton
                    if CFG.Visual.Skeleton then
                        local hitbox = model:FindFirstChild("Hitbox")
                        if hitbox then
                            if not Drawings.Skeleton[model] then
                                Drawings.Skeleton[model] = {
                                    HeadToTorso = Drawing.new("Line"), TorsoToLArm = Drawing.new("Line"),
                                    TorsoToRArm = Drawing.new("Line"), TorsoToLLeg = Drawing.new("Line"), TorsoToRLeg = Drawing.new("Line")
                                }
                            end
                            local skel = Drawings.Skeleton[model]
                            local function updateLine(line, p1, p2)
                                if p1 and p2 then
                                    local v1, o1 = Camera:WorldToViewportPoint(p1.Position); local v2, o2 = Camera:WorldToViewportPoint(p2.Position)
                                    if o1 and o2 then line.From = Vector2.new(v1.X, v1.Y); line.To = Vector2.new(v2.X, v2.Y); line.Color = CFG.Visual.SkeletonColor; line.Visible = true
                                    else line.Visible = false end
                                else line.Visible = false end
                            end
                            updateLine(skel.HeadToTorso, hitbox:FindFirstChild("Hitbox_Head"), hitbox:FindFirstChild("Hitbox_Torso"))
                            updateLine(skel.TorsoToLArm, hitbox:FindFirstChild("Hitbox_Torso"), hitbox:FindFirstChild("Hitbox_Left Arm"))
                            updateLine(skel.TorsoToRArm, hitbox:FindFirstChild("Hitbox_Torso"), hitbox:FindFirstChild("Hitbox_Right Arm"))
                            updateLine(skel.TorsoToLLeg, hitbox:FindFirstChild("Hitbox_Torso"), hitbox:FindFirstChild("Hitbox_Left Leg"))
                            updateLine(skel.TorsoToRLeg, hitbox:FindFirstChild("Hitbox_Torso"), hitbox:FindFirstChild("Hitbox_Right Leg"))
                        end
                    end

                else
                    d.Box.Visible = false; d.Name.Visible = false; d.Health.Visible = false; d.Tracer.Visible = false
                    if Drawings.Skeleton[model] then for _, line in pairs(Drawings.Skeleton[model]) do line.Visible = false end end
                end
            end
        end
    end
end)

-- 2. COMBAT RENDER (POV FIXED)
local isHoldingRightClick = false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then isHoldingRightClick = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then isHoldingRightClick = false end
end)

RunService.RenderStepped:Connect(function()
    if not HasDrawing then return end
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Aimbot
    if CFG.Combat.Aimbot then
        local canAim = false
        if CFG.Combat.ABKey == "Always" then canAim = true
        elseif CFG.Combat.ABKey == "Hold (Right Click)" then canAim = isHoldingRightClick end

        if canAim then
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
                    end
                else Drawings.AB_FOV.Visible = false; Drawings.AB_POVLine.Visible = false end
            else Drawings.AB_FOV.Visible = false; Drawings.AB_POVLine.Visible = false end
        else Drawings.AB_FOV.Visible = false; Drawings.AB_POVLine.Visible = false end
    else Drawings.AB_FOV.Visible = false; Drawings.AB_POVLine.Visible = false end

    -- Silent Aim POV (Selalu Nempel)
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
                Drawings.SA_FOV.Visible = false; Drawings.SA_POVLine.Visible = false
            end
        else
            Drawings.SA_FOV.Visible = false; Drawings.SA_POVLine.Visible = false
        end
    else
        Drawings.SA_FOV.Visible = false; Drawings.SA_POVLine.Visible = false
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
            else Drawings.SnapLine.Visible = false end
        else Drawings.SnapLine.Visible = false end
    else Drawings.SnapLine.Visible = false end
end)

-- 3. SILENT AIM HOOK
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if CFG.Combat.SilentAim and not checkcaller() then
        if (method == "FireServer" or method == "InvokeServer") then
            local name = string.lower(self.Name)
            if name:find("shoot") or name:find("weapon") or name:find("bullet") or name:find("useitem") then
                local target = GetClosestTarget(CFG.Combat.SAPart, CFG.Combat.TeamCheck, CFG.Combat.WallCheck)
                if target and math.random(1,100) <= CFG.Combat.HitChance then
                    local args = {...}
                    for i, v in pairs(args) do
                        if typeof(v) == "Vector3" then args[i] = (target.part.Position - Camera.CFrame.Position).Unit
                        elseif typeof(v) == "CFrame" then args[i] = CFrame.lookAt(v.Position, target.part.Position) end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- 4. PLAYER LOGIC
local flyVel = nil
RunService.RenderStepped:Connect(function()
    if not LP.Character then return end
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    
    if hum then 
        hum.WalkSpeed = CFG.Player.SpeedHack and CFG.Player.SpeedValue or 16
        hum.JumpPower = CFG.Player.JumpHack and CFG.Player.JumpValue or 50 
    end
    
    if CFG.Player.NoClip then 
        for _, v in ipairs(LP.Character:GetDescendants()) do 
            if v:IsA("BasePart") then v.CanCollide = false end 
        end 
    end
    
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if CFG.Player.FlyHack and hrp then
        if not flyVel or not flyVel.Parent then 
            flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5); flyVel.Parent = hrp 
        end
        flyVel.Velocity = hum.MoveDirection * CFG.Player.FlySpeed
    else 
        if flyVel then flyVel:Destroy(); flyVel = nil end 
    end
end)

UserInputService.JumpRequest:Connect(function()
    if CFG.Player.InfiniteJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- 5. WEAPON SCANNER & PATCHER (Ammo Boost & Reload Speed Included)
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            for _, obj in pairs(getgc(true)) do
                if type(obj) == "table" then
                    local isWeapon = false
                    if rawget(obj, "firerate") and rawget(obj, "damage") then isWeapon = true
                    elseif rawget(obj, "ShootCooldown") or rawget(obj, "FireInterval") then isWeapon = true end
                    
                    if isWeapon then
                        if CFG.Weapon.NoRecoil then rawset(obj, "recoilFactor", 0); rawset(obj, "ShootRecoil", 0); rawset(obj, "MaxRotRecoil", 0); rawset(obj, "MinRotRecoil", 0) end
                        if CFG.Weapon.NoSpread then rawset(obj, "spread", Vector2.new(0, 0)); rawset(obj, "BaseSpread", 0) end
                        if CFG.Weapon.RapidFire then rawset(obj, "firerate", CFG.Weapon.FireRate); rawset(obj, "ShootCooldown", 0.01); rawset(obj, "FireInterval", 0.01) end
                        if CFG.Weapon.DamageMult then rawset(obj, "damage", CFG.Weapon.DamageValue); rawset(obj, "HeadDamage", CFG.Weapon.DamageValue) end
                        
                        -- AMO RESERVE BOOST & RELOAD SPEED
                        if CFG.Weapon.AmmoReserveBoost then 
                            rawset(obj, "MaxAmmoReserve", 9999)
                            rawset(obj, "AmmoReserve", 9999)
                        end
                        if CFG.Weapon.FastReload then 
                            rawset(obj, "ReloadTime", 0.01)
                            rawset(obj, "ReloadSpeed", CFG.Weapon.ReloadSpeed)
                            rawset(obj, "EmptyReloadLength", 0.01)
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not LP.Character or not CFG.Weapon.InfAmmo then continue end
        for _, tool in ipairs(LP.Character:GetChildren()) do
            if tool:IsA("Tool") then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Bullets") or tool:FindFirstChild("Magazine")
                if ammo and ammo:IsA("ValueBase") then ammo.Value = 999 end
            end
        end
    end
end)

-- 6. FARM LOGIC
RunService.Heartbeat:Connect(function()
    if not LP.Character then return end
    local myHRP = LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    if CFG.Farm.BringEnemy then
        local count = 0
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Hitbox") and obj ~= LP.Character then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if not (CFG.Farm.BringTeamCheck and IsTeammate(obj)) then
                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                        if hrp and (CFG.Farm.BringMode == "All" or (CFG.Farm.BringMode == "Single" and count == 0)) then
                            pcall(function() hrp.CFrame = myHRP.CFrame * CFrame.new(0, 0, -CFG.Farm.BringJarak) end)
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    if CFG.Farm.KillAura then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Hitbox") and obj ~= LP.Character then
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
end)

-- 7. ANTI AFK
LP.Idled:Connect(function()
    if CFG.Farm.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end)

OrionLib:Init()

-- ═══ BOOT PRINT ═══
print("═══════════════════════════════════════════════════════════════")
print("   RENXX v26.0 | NO FEATURE REMOVED & FIXED")
print("═══════════════════════════════════════════════════════════════")
print("[✅] Script Loaded Successfully!")
print("[✅] Ammo Reserve Boost & Reload Speed: ADDED")
print("[✅] Camera Stuck Bug: FIXED")
print("[✅] POV Silent Aim & Aimbot: NO FLICKER")
print("═══════════════════════════════════════════════════════════════")
