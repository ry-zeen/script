-- ==================================================
-- RY ULTIMATE v2.1 — FULL RELEASE
-- UI: Orion | Game: Gun Grounds FFA
-- Features: Silent Aim, Aimbot, ESP, Weapon Mods, Telekill
-- ==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================================================
-- CONFIGURATION & STATE
-- ==================================================
local Config = {
    Combat = {
        SilentAim = false,
        S_Part = "Head",
        HitChance = 80,
        Prediction = false,
        PredictionAmount = 0.1,
        PingBuffer = 20,
        S_POV = 200,
        ShowS_POV = false,
        S_POVColor = Color3.fromRGB(255, 0, 0),
        Snapline = false,
        SnapLineColor = Color3.fromRGB(255, 255, 255),

        Aimbot = false,
        A_Smooth = 5,
        A_Part = "Head",
        A_POV = 150,
        ShowA_POV = false,
        A_POVColor = Color3.fromRGB(0, 170, 255),

        Hitbox = false,
        HitboxSize = 2,
    },
    Visual = {
        ESP_Box = false,
        ESP_Name = false,
        ESP_Health = false,
        ESP_Tracer = false,
        ESP_Skeleton = false,
        
        Color_Box = Color3.fromRGB(255, 60, 60),
        Color_Text = Color3.fromRGB(255, 255, 255),
        Color_Health = Color3.fromRGB(0, 255, 0),
        Color_Tracer = Color3.fromRGB(255, 0, 0),
        Color_Skeleton = Color3.fromRGB(255, 255, 0),
    },
    Weapon = {
        InfAmmo = false,
        RapidFire = false,
        RateFire = 5,
        NoRecoil = false,
        NoSpread = false,
        FastReload = false,
        ReloadSpeed = 0.1,
    },
    Player = {
        FastRegen = false,
        RegenSpeed = 10,
        SpeedHack = false,
        SpeedVal = 30,
        JumpHack = false,
        JumpVal = 60,
        NoClip = false,
        
        Telekill = false,
        TpManual = "",
        TpPos = "Depan",
        TpDelay = 0.5,
    }
}

local WeaponTables = {}
local WeaponOriginals = {}
local ESPObjects = {}
local CurrentTelekillTarget = nil

-- ==================================================
-- HELPER FUNCTIONS
-- ==================================================
local function IsAlive(character)
    if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function IsEnemy(player)
    if player == LocalPlayer then return false end
    if not player.Character or not IsAlive(player.Character) then return false end
    return true
end

local function GetBots()
    local bots = {}
    local folders = {"Mobs", "IgnoreThese", "Enemies", "NPCs", "Bots"}
    for _, folderName in ipairs(folders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, bot in ipairs(folder:GetChildren()) do
                if IsAlive(bot) then
                    table.insert(bots, bot)
                end
            end
        end
    end
    return bots
end

local function GetPart(character, partName)
    if not character then return nil end
    if partName == "Head" then return character:FindFirstChild("Head") end
    if partName == "Body" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") end
    if partName == "Foot" then return character:FindFirstChild("LeftFoot") or character:FindFirstChild("RightFoot") or character:FindFirstChild("HumanoidRootPart") end
    return character:FindFirstChild(partName) or character:FindFirstChild("Head")
end

local function WallCheck(part)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local rayResult = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
    return rayResult == nil or rayResult.Instance:IsDescendantOf(part.Parent)
end

-- ==================================================
-- LOAD ORION UI
-- ==================================================
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()
local Window = OrionLib:MakeWindow({
    Name = "RY ULTIMATE v2.1",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "RY_Config",
    IntroEnabled = true,
    IntroText = "RY ULTIMATE",
    IntroIcon = "rbxassetid://4483362458",
    Icon = "rbxassetid://4483362458"
})

-- ==================================================
-- TAB: COMBAT
-- ==================================================
local CombatTab = Window:MakeTab({ Name = "Combat", Icon = "rbxassetid://4483362458" })

CombatTab:AddSection({ Name = "Silent Aim (Hook)" })
CombatTab:AddToggle({ Name = "Enable Silent Aim", Default = false, Flag = "sa_enable", Callback = function(v) Config.Combat.SilentAim = v end })
CombatTab:AddDropdown({ Name = "S Part", Default = "Head", Options = {"Head", "Body", "Foot"}, Flag = "sa_part", Callback = function(v) Config.Combat.S_Part = v end })
CombatTab:AddSlider({ Name = "Hit Chance", Min = 10, Max = 100, Default = 80, Color = Color3.fromRGB(0, 255, 100), Increment = 5, ValueName = "%", Flag = "sa_hc", Callback = function(v) Config.Combat.HitChance = v end })
CombatTab:AddToggle({ Name = "Prediction", Default = false, Flag = "sa_pred", Callback = function(v) Config.Combat.Prediction = v end })
CombatTab:AddSlider({ Name = "Prediction Amount", Min = 0.05, Max = 0.5, Default = 0.1, Color = Color3.fromRGB(0, 255, 100), Increment = 0.05, ValueName = "s", Flag = "sa_preda", Callback = function(v) Config.Combat.PredictionAmount = v end })
CombatTab:AddSlider({ Name = "Ping Buffer", Min = 0, Max = 200, Default = 20, Color = Color3.fromRGB(0, 255, 100), Increment = 5, ValueName = "ms", Flag = "sa_pb", Callback = function(v) Config.Combat.PingBuffer = v end })
CombatTab:AddSlider({ Name = "S POV Radius", Min = 50, Max = 500, Default = 200, Color = Color3.fromRGB(255, 0, 0), Increment = 10, ValueName = "px", Flag = "sa_pov", Callback = function(v) Config.Combat.S_POV = v end })
CombatTab:AddToggle({ Name = "Show S POV", Default = false, Flag = "sa_showpov", Callback = function(v) Config.Combat.ShowS_POV = v end })
CombatTab:AddColorpicker({ Name = "S POV Color", Default = Color3.fromRGB(255, 0, 0), Flag = "sa_povc", Callback = function(v) Config.Combat.S_POVColor = v end })
CombatTab:AddToggle({ Name = "Snapline", Default = false, Flag = "sa_snap", Callback = function(v) Config.Combat.Snapline = v end })
CombatTab:AddColorpicker({ Name = "Snapline Color", Default = Color3.fromRGB(255, 255, 255), Flag = "sa_snapc", Callback = function(v) Config.Combat.SnapLineColor = v end })

CombatTab:AddSection({ Name = "Aimbot (Camera)" })
CombatTab:AddToggle({ Name = "Enable Aimbot", Default = false, Flag = "ab_enable", Callback = function(v) Config.Combat.Aimbot = v end })
CombatTab:AddSlider({ Name = "Aim Smoothness", Min = 1, Max = 20, Default = 5, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "x", Flag = "ab_smooth", Callback = function(v) Config.Combat.A_Smooth = v end })
CombatTab:AddDropdown({ Name = "A Part", Default = "Head", Options = {"Head", "Body", "Foot"}, Flag = "ab_part", Callback = function(v) Config.Combat.A_Part = v end })
CombatTab:AddSlider({ Name = "A POV Radius", Min = 50, Max = 500, Default = 150, Color = Color3.fromRGB(0, 170, 255), Increment = 10, ValueName = "px", Flag = "ab_pov", Callback = function(v) Config.Combat.A_POV = v end })
CombatTab:AddToggle({ Name = "Show A POV", Default = false, Flag = "ab_showpov", Callback = function(v) Config.Combat.ShowA_POV = v end })
CombatTab:AddColorpicker({ Name = "A POV Color", Default = Color3.fromRGB(0, 170, 255), Flag = "ab_povc", Callback = function(v) Config.Combat.A_POVColor = v end })

CombatTab:AddSection({ Name = "Hitbox" })
CombatTab:AddToggle({ Name = "Hitbox Expander", Default = false, Flag = "hb_enable", Callback = function(v) Config.Combat.Hitbox = v end })
CombatTab:AddSlider({ Name = "Hitbox Size", Min = 1, Max = 10, Default = 2, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "x", Flag = "hb_size", Callback = function(v) Config.Combat.HitboxSize = v end })

-- ==================================================
-- TAB: VISUAL
-- ==================================================
local VisualTab = Window:MakeTab({ Name = "Visual", Icon = "rbxassetid://4483362458" })

VisualTab:AddSection({ Name = "ESP Master" })
VisualTab:AddToggle({ Name = "ESP Box", Default = false, Flag = "esp_box", Callback = function(v) Config.Visual.ESP_Box = v end })
VisualTab:AddToggle({ Name = "ESP Name", Default = false, Flag = "esp_name", Callback = function(v) Config.Visual.ESP_Name = v end })
VisualTab:AddToggle({ Name = "ESP Health", Default = false, Flag = "esp_health", Callback = function(v) Config.Visual.ESP_Health = v end })
VisualTab:AddToggle({ Name = "ESP Tracers", Default = false, Flag = "esp_tracer", Callback = function(v) Config.Visual.ESP_Tracer = v end })
VisualTab:AddToggle({ Name = "ESP Skeleton (R6)", Default = false, Flag = "esp_skel", Callback = function(v) Config.Visual.ESP_Skeleton = v end })

VisualTab:AddSection({ Name = "ESP Colors" })
VisualTab:AddColorpicker({ Name = "Box Color", Default = Color3.fromRGB(255, 60, 60), Flag = "c_box", Callback = function(v) Config.Visual.Color_Box = v end })
VisualTab:AddColorpicker({ Name = "Text Color", Default = Color3.fromRGB(255, 255, 255), Flag = "c_text", Callback = function(v) Config.Visual.Color_Text = v end })
VisualTab:AddColorpicker({ Name = "Health Bar Color", Default = Color3.fromRGB(0, 255, 0), Flag = "c_health", Callback = function(v) Config.Visual.Color_Health = v end })
VisualTab:AddColorpicker({ Name = "Tracers Color", Default = Color3.fromRGB(255, 0, 0), Flag = "c_tracer", Callback = function(v) Config.Visual.Color_Tracer = v end })
VisualTab:AddColorpicker({ Name = "Skeleton Color", Default = Color3.fromRGB(255, 255, 0), Flag = "c_skel", Callback = function(v) Config.Visual.Color_Skeleton = v end })

-- ==================================================
-- TAB: WEAPON
-- ==================================================
local WeaponTab = Window:MakeTab({ Name = "Weapon", Icon = "rbxassetid://4483362458" })

WeaponTab:AddSection({ Name = "Weapon Mods (GetGC)" })
WeaponTab:AddToggle({ Name = "Infinite Ammo", Default = false, Flag = "w_ammo", Callback = function(v) Config.Weapon.InfAmmo = v end })
WeaponTab:AddToggle({ Name = "Rapid Fire", Default = false, Flag = "w_rapid", Callback = function(v) Config.Weapon.RapidFire = v end })
WeaponTab:AddSlider({ Name = "Rate Fire", Min = 1, Max = 1000, Default = 5, Color = Color3.fromRGB(0, 170, 255), Increment = 5, ValueName = "x", Flag = "w_rate", Callback = function(v) Config.Weapon.RateFire = v end })
WeaponTab:AddToggle({ Name = "No Recoil", Default = false, Flag = "w_recoil", Callback = function(v) Config.Weapon.NoRecoil = v end })
WeaponTab:AddToggle({ Name = "No Spread", Default = false, Flag = "w_spread", Callback = function(v) Config.Weapon.NoSpread = v end })
WeaponTab:AddToggle({ Name = "Fast Reload", Default = false, Flag = "w_reload", Callback = function(v) Config.Weapon.FastReload = v end })
WeaponTab:AddSlider({ Name = "Reload Speed", Min = 0.1, Max = 2, Default = 0.1, Color = Color3.fromRGB(0, 170, 255), Increment = 0.1, ValueName = "s", Flag = "w_reloads", Callback = function(v) Config.Weapon.ReloadSpeed = v end })

-- ==================================================
-- TAB: PLAYER
-- ==================================================
local PlayerTab = Window:MakeTab({ Name = "Player", Icon = "rbxassetid://4483362458" })

PlayerTab:AddSection({ Name = "Survival & Movement" })
PlayerTab:AddToggle({ Name = "Fast Regen", Default = false, Flag = "p_regen", Callback = function(v) Config.Player.FastRegen = v end })
PlayerTab:AddSlider({ Name = "Regen Speed", Min = 1, Max = 100, Default = 10, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "HP", Flag = "p_regens", Callback = function(v) Config.Player.RegenSpeed = v end })
PlayerTab:AddToggle({ Name = "Speed Hack", Default = false, Flag = "p_speed", Callback = function(v) Config.Player.SpeedHack = v end })
PlayerTab:AddSlider({ Name = "Speed Value", Min = 16, Max = 100, Default = 30, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "spd", Flag = "p_speedv", Callback = function(v) Config.Player.SpeedVal = v end })
PlayerTab:AddToggle({ Name = "Jump Hack", Default = false, Flag = "p_jump", Callback = function(v) Config.Player.JumpHack = v end })
PlayerTab:AddSlider({ Name = "Jump Value", Min = 50, Max = 300, Default = 60, Color = Color3.fromRGB(0, 170, 255), Increment = 5, ValueName = "pow", Flag = "p_jumpv", Callback = function(v) Config.Player.JumpVal = v end })
PlayerTab:AddToggle({ Name = "No Clip", Default = false, Flag = "p_noclip", Callback = function(v) Config.Player.NoClip = v end })

PlayerTab:AddSection({ Name = "Telekill" })
PlayerTab:AddToggle({ Name = "Telekill (Auto Target)", Default = false, Flag = "tk_enable", Callback = function(v) Config.Player.Telekill = v end })
PlayerTab:AddTextbox({ Name = "Tp Manual (Nama Player)", Default = "", TextDisappear = false, Flag = "tk_manual", Callback = function(v) Config.Player.TpManual = v end })
PlayerTab:AddDropdown({ Name = "Tp Position", Default = "Depan", Options = {"Depan", "Belakang", "Atas", "Bawah"}, Flag = "tk_pos", Callback = function(v) Config.Player.TpPos = v end })
PlayerTab:AddSlider({ Name = "Tp Stund (Delay)", Min = 0.1, Max = 2, Default = 0.5, Color = Color3.fromRGB(0, 170, 255), Increment = 0.1, ValueName = "s", Flag = "tk_delay", Callback = function(v) Config.Player.TpDelay = v end })

-- ==================================================
-- DRAWING OBJECTS
-- ==================================================
local S_POV_Circle = Drawing.new("Circle")
S_POV_Circle.Thickness = 1
S_POV_Circle.NumSides = 64
S_POV_Circle.Filled = false
S_POV_Circle.Transparency = 1

local A_POV_Circle = Drawing.new("Circle")
A_POV_Circle.Thickness = 1
A_POV_Circle.NumSides = 64
A_POV_Circle.Filled = false
A_POV_Circle.Transparency = 1

local SnapLine_Draw = Drawing.new("Line")
SnapLine_Draw.Thickness = 1
SnapLine_Draw.Transparency = 1

-- ==================================================
-- CORE FUNCTIONS
-- ==================================================
local function GetClosestTarget(fov, partName)
    local closestTarget = nil
    local shortestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if IsEnemy(player) then
            local part = GetPart(player.Character, partName)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distance < fov and distance < shortestDistance and WallCheck(part) then
                        shortestDistance = distance
                        closestTarget = { character = player.Character, part = part }
                    end
                end
            end
        end
    end
    
    for _, bot in ipairs(GetBots()) do
        local part = GetPart(bot, partName)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if distance < fov and distance < shortestDistance and WallCheck(part) then
                    shortestDistance = distance
                    closestTarget = { character = bot, part = part }
                end
            end
        end
    end

    return closestTarget
end

local function GetPredictedPosition(part)
    if not Config.Combat.Prediction or not part then return part.Position end
    local character = part.Parent
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local totalTime = Config.Combat.PredictionAmount + (Config.Combat.PingBuffer / 1000)
        return part.Position + (hrp.AssemblyLinearVelocity * totalTime)
    end
    return part.Position
end

-- ==================================================
-- SILENT AIM HOOK (NAMECALL)
-- ==================================================
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if Config.Combat.SilentAim and method == "FireServer" and self and self.Name then
        if self.Name == "GunShot" or self.Name == "Shoot" or self.Name == "CheckShot" or self.Name == "ProjectileRender" then
            if math.random(1, 100) <= Config.Combat.HitChance then
                local target = GetClosestTarget(Config.Combat.S_POV, Config.Combat.S_Part)
                if target and target.part then
                    local finalPosition = GetPredictedPosition(target.part)
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = finalPosition
                        elseif typeof(v) == "CFrame" then
                            args[i] = CFrame.lookAt(Camera.CFrame.Position, finalPosition)
                        end
                    end
                    return oldNamecall(self, table.unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- ==================================================
-- MAIN RENDER LOOP
-- ==================================================
RunService.RenderStepped:Connect(function()
    -- POV Circles & Snapline
    S_POV_Circle.Radius = Config.Combat.S_POV
    S_POV_Circle.Color = Config.Combat.S_POVColor
    S_POV_Circle.Visible = Config.Combat.ShowS_POV
    S_POV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    A_POV_Circle.Radius = Config.Combat.A_POV
    A_POV_Circle.Color = Config.Combat.A_POVColor
    A_POV_Circle.Visible = Config.Combat.ShowA_POV
    A_POV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local snapTarget = GetClosestTarget(Config.Combat.S_POV, Config.Combat.S_Part)
    if Config.Combat.Snapline and snapTarget and snapTarget.part then
        local screenPos = Camera:WorldToViewportPoint(snapTarget.part.Position)
        SnapLine_Draw.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        SnapLine_Draw.To = Vector2.new(screenPos.X, screenPos.Y)
        SnapLine_Draw.Color = Config.Combat.SnapLineColor
        SnapLine_Draw.Visible = true
    else
        SnapLine_Draw.Visible = false
    end

    -- Aimbot Logic
    if Config.Combat.Aimbot then
        local aimTarget = GetClosestTarget(Config.Combat.A_POV, Config.Combat.A_Part)
        if aimTarget and aimTarget.part then
            local smooth = Config.Combat.A_Smooth > 0 and Config.Combat.A_Smooth or 1
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimTarget.part.Position), 1 / smooth)
        end
    end

    -- Hitbox Expander
    if Config.Combat.Hitbox then
        for _, player in ipairs(Players:GetPlayers()) do
            if IsEnemy(player) then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Size = part.Size:Lerp(Vector3.new(part.Size.X * Config.Combat.HitboxSize, part.Size.Y * Config.Combat.HitboxSize, part.Size.Z * Config.Combat.HitboxSize), 0.5)
                        part.Transparency = 0.5
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- ==================================================
-- ESP RENDER LOOP
-- ==================================================
local function CreateESPObject(character)
    if ESPObjects[character] then return ESPObjects[character] end
    local obj = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBg = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Skeleton = {}
    }
    for i = 1, 5 do obj.Skeleton[i] = Drawing.new("Line") end
    for _, v in pairs(obj) do
        if typeof(v) == "table" then
            for _, line in pairs(v) do line.Thickness = 1 line.Visible = false end
        else
            v.Thickness = 1
            v.Visible = false
        end
    end
    ESPObjects[character] = obj
    return obj
end

local function RemoveESPObject(character)
    local obj = ESPObjects[character]
    if obj then
        for _, v in pairs(obj) do
            if typeof(v) == "table" then
                for _, line in pairs(v) do pcall(function() line:Remove() end) end
            else
                pcall(function() v:Remove() end)
            end
        end
        ESPObjects[character] = nil
    end
end

RunService.RenderStepped:Connect(function()
    for character in pairs(ESPObjects) do
        if not character or not character.Parent or not IsAlive(character) then
            RemoveESPObject(character)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if IsEnemy(player) then
            local character = player.Character
            local obj = CreateESPObject(character)
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local hum = character:FindFirstChildOfClass("Humanoid")

            if hrp and head and hum then
                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local rootPos = Camera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    local height = math.abs(headPos.Y - rootPos.Y) * 2
                    local width = height / 2

                    -- Box
                    obj.Box.Visible = Config.Visual.ESP_Box
                    if Config.Visual.ESP_Box then
                        obj.Box.Color = Config.Visual.Color_Box
                        obj.Box.Size = Vector2.new(width, height)
                        obj.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y - height / 2)
                    end

                    -- Name
                    obj.Name.Visible = Config.Visual.ESP_Name
                    if Config.Visual.ESP_Name then
                        obj.Name.Text = player.Name
                        obj.Name.Color = Config.Visual.Color_Text
                        obj.Name.Size = 14
                        obj.Name.Center = true
                        obj.Name.Outline = true
                        obj.Name.Position = Vector2.new(headPos.X, headPos.Y - height / 2 - 20)
                    end

                    -- Health
                    obj.HealthBg.Visible = Config.Visual.ESP_Health
                    obj.HealthBar.Visible = Config.Visual.ESP_Health
                    if Config.Visual.ESP_Health then
                        local healthPct = hum.Health / hum.MaxHealth
                        obj.HealthBg.Color = Color3.new(0, 0, 0)
                        obj.HealthBg.Filled = true
                        obj.HealthBg.Size = Vector2.new(4, height)
                        obj.HealthBg.Position = Vector2.new(headPos.X - width / 2 - 6, headPos.Y - height / 2)
                        
                        obj.HealthBar.Color = Config.Visual.Color_Health
                        obj.HealthBar.Filled = true
                        obj.HealthBar.Size = Vector2.new(4, height * healthPct)
                        obj.HealthBar.Position = Vector2.new(headPos.X - width / 2 - 6, headPos.Y - height / 2 + (height - height * healthPct))
                    end

                    -- Tracer
                    obj.Tracer.Visible = Config.Visual.ESP_Tracer
                    if Config.Visual.ESP_Tracer then
                        obj.Tracer.Color = Config.Visual.Color_Tracer
                        obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        obj.Tracer.To = Vector2.new(headPos.X, headPos.Y)
                    end

                    -- Skeleton (R6)
                    if Config.Visual.ESP_Skeleton then
                        local parts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
                        local pPos = {}
                        for _, name in ipairs(parts) do
                            local pt = character:FindFirstChild(name)
                            if pt then
                                local s, _ = Camera:WorldToViewportPoint(pt.Position)
                                pPos[name] = s
                            end
                        end

                        local function drawLine(index, p1, p2)
                            if pPos[p1] and pPos[p2] then
                                obj.Skeleton[index].Color = Config.Visual.Color_Skeleton
                                obj.Skeleton[index].From = Vector2.new(pPos[p1].X, pPos[p1].Y)
                                obj.Skeleton[index].To = Vector2.new(pPos[p2].X, pPos[p2].Y)
                                obj.Skeleton[index].Visible = true
                            else
                                obj.Skeleton[index].Visible = false
                            end
                        end

                        drawLine(1, "Head", "Torso")
                        drawLine(2, "Torso", "Left Arm")
                        drawLine(3, "Torso", "Right Arm")
                        drawLine(4, "Torso", "Left Leg")
                        drawLine(5, "Torso", "Right Leg")
                    else
                        for i = 1, 5 do obj.Skeleton[i].Visible = false end
                    end
                else
                    obj.Box.Visible = false
                    obj.Name.Visible = false
                    obj.HealthBg.Visible = false
                    obj.HealthBar.Visible = false
                    obj.Tracer.Visible = false
                    for i = 1, 5 do obj.Skeleton[i].Visible = false end
                end
            end
        end
    end
end)

-- ==================================================
-- WEAPON MODS LOOP (GETGC)
-- ==================================================
local Prop_Fire = {"Debounce", "FireInterval", "ShootDelay", "AcquireDelay", "FireRate", "DelayUntilLoop"}
local Prop_Recoil = {"MaxRotRecoil", "MinRotRecoil", "MaxCamRecoil", "MinCamRecoil", "MaxTransRecoil", "MinTransRecoil", "RotRecoilConstant", "CamRecoilConstant", "TransRecoilConstant", "RotRecoilDamping"}
local Prop_Spread = {"BaseSpread", "Spread", "ScopeSpreadMultiplier"}
local Prop_Ammo = {"FillAmmo", "Ammo"}

local function ScanWeapons()
    local found = {}
    for _, v in next, getgc(true) do
        if type(v) == "table" then
            local isWeapon = rawget(v, "FireInterval") or rawget(v, "BaseSpread") or rawget(v, "HeadDamage") or rawget(v, "MaxRotRecoil") or rawget(v, "FillAmmo") or rawget(v, "Debounce") or rawget(v, "Ammo")
            if isWeapon then
                table.insert(found, v)
                if WeaponOriginals[v] == nil then
                    local cache = {}
                    for _, list in ipairs({Prop_Fire, Prop_Recoil, Prop_Spread, Prop_Ammo}) do
                        for _, k in ipairs(list) do cache[k] = rawget(v, k) end
                    end
                    WeaponOriginals[v] = cache
                end
            end
        end
    end
    WeaponTables = found
end

ScanWeapons()
task.spawn(function() while task.wait(5) do ScanWeapons() end end)

local lastWeaponUpdate = 0
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastWeaponUpdate < 0.1 then return end
    lastWeaponUpdate = now
    
    for _, t in ipairs(WeaponTables) do
        local orig = WeaponOriginals[t]
        if orig then
            if Config.Weapon.NoRecoil then
                for _, k in ipairs(Prop_Recoil) do
                    if orig[k] ~= nil then
                        if typeof(orig[k]) == "Vector3" then pcall(function() rawset(t, k, Vector3.zero) end)
                        else pcall(function() rawset(t, k, 0) end) end
                    end
                end
            end
            if Config.Weapon.NoSpread then
                for _, k in ipairs(Prop_Spread) do
                    if orig[k] ~= nil then pcall(function() rawset(t, k, 0) end) end
                end
            end
            if Config.Weapon.InfAmmo then
                if orig.FillAmmo then pcall(function() rawset(t, "FillAmmo", orig.FillAmmo) end) end
                if orig.Ammo then pcall(function() rawset(t, "Ammo", orig.Ammo) end) end
            end
            if Config.Weapon.RapidFire then
                local mult = Config.Weapon.RateFire
                for _, k in ipairs(Prop_Fire) do
                    local v = orig[k]
                    if v and type(v) == "number" and v > 0 then
                        pcall(function() rawset(t, k, math.max(v / mult, 0.001)) end)
                    end
                end
            end
            if Config.Weapon.FastReload then
                if orig.reloadTime then pcall(function() rawset(t, "reloadTime", Config.Weapon.ReloadSpeed) end) end
            end
        end
    end
end)

-- ==================================================
-- PLAYER & TELEKILL LOOP
-- ==================================================
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.Player.SpeedHack then hum.WalkSpeed = Config.Player.SpeedVal end
            if Config.Player.JumpHack then hum.UseJumpPower = true hum.JumpPower = Config.Player.JumpVal end
            if Config.Player.FastRegen and hum.Health < hum.MaxHealth then
                hum.Health = math.min(hum.Health + Config.Player.RegenSpeed, hum.MaxHealth)
            end
        end
        if Config.Player.NoClip then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(Config.Player.TpDelay) do
        if Config.Player.Telekill and LocalPlayer.Character then
            local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then
                if not CurrentTelekillTarget or not CurrentTelekillTarget.Parent or not IsAlive(CurrentTelekillTarget) then
                    local closest = nil
                    local dist = math.huge
                    for _, p in ipairs(Players:GetPlayers()) do
                        if IsEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (p.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                            if d < dist then dist = d closest = p.Character end
                        end
                    end
                    CurrentTelekillTarget = closest
                end
                
                if CurrentTelekillTarget and CurrentTelekillTarget:FindFirstChild("HumanoidRootPart") then
                    local targetHrp = CurrentTelekillTarget.HumanoidRootPart
                    local offset = Vector3.new(0, 0, 0)
                    if Config.Player.TpPos == "Depan" then offset = targetHrp.CFrame.LookVector * 3
                    elseif Config.Player.TpPos == "Belakang" then offset = -targetHrp.CFrame.LookVector * 3
                    elseif Config.Player.TpPos == "Atas" then offset = Vector3.new(0, 5, 0)
                    elseif Config.Player.TpPos == "Bawah" then offset = Vector3.new(0, -5, 0) end
                    myHrp.CFrame = CFrame.new(targetHrp.Position + offset)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.Player.TpManual ~= "" and Config.Player.Telekill == false then
            local target = Players:FindFirstChild(Config.Player.TpManual)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local tHrp = target.Character.HumanoidRootPart
                    local offset = Vector3.new(0, 0, 0)
                    if Config.Player.TpPos == "Depan" then offset = tHrp.CFrame.LookVector * 3
                    elseif Config.Player.TpPos == "Belakang" then offset = -tHrp.CFrame.LookVector * 3
                    elseif Config.Player.TpPos == "Atas" then offset = Vector3.new(0, 5, 0)
                    elseif Config.Player.TpPos == "Bawah" then offset = Vector3.new(0, -5, 0) end
                    myHrp.CFrame = CFrame.new(tHrp.Position + offset)
                end
            end
        end
    end
end)

-- ==================================================
-- INITIALIZATION
-- ==================================================
OrionLib:Init()
OrionLib:MakeNotification({
    Name = "RY ULTIMATE v2.1",
    Content = "Full Script Loaded!",
    Image = "rbxassetid://4483362458",
    Time = 5
})

print("========================================")
print("RY ULTIMATE v2.1 — FULL RELEASE")
print("Status: LOADED")
print("Features: Silent Aim, Aimbot, ESP, Skeleton, Telekill")
print("========================================")
