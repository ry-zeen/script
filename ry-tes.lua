-- ==================================================
-- RY ULTIMATE v5.1 — FULL EXPANDED VERSION
-- UI: Orion | Game: Gun Grounds FFA
-- Fix: Hitbox Infinite Loop & Farm Tab (Bring/Telekill)
-- ==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local WeaponTables = {}
local WeaponOriginals = {}
local ESPObjects = {}
local OriginalSizes = {}

local Config = {
    Combat = {
        Aimbot = false,
        A_Smooth = 5,
        A_Part = "Head",
        A_POV = 150,
        ShowA_POV = false,
        A_POVColor = Color3.fromRGB(0, 170, 255),
        WallCheck = false,
        
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
        Ammo = false,
        Rapid = false,
        Rate = 5,
        Recoil = false,
        Spread = false,
        FastReload = false,
        ReloadSpeed = 0.1,
    },
    Player = {
        Regen = false,
        RegenSpeed = 10,
        SpeedHack = false,
        SpeedVal = 30,
        JumpHack = false,
        JumpVal = 60,
        NoClip = false,
    },
    Farm = {
        -- Bring
        BringPlayer = false,
        BringType = "SinglePlayerOnly",
        BringStund = 0.5,
        
        -- Telekill
        Telekill = false,
        TpManual = "",
        TpPos = "Depan",
        TpDelay = 0.5,
    }
}

-- ==================================================
-- HELPER FUNCTIONS
-- ==================================================
local function IsAlive(character)
    if not character or not character.Parent then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function IsEnemy(player)
    if player == LocalPlayer then
        return false
    end
    if not player.Character or not IsAlive(player.Character) then
        return false
    end
    return true
end

local function GetBots()
    local bots = {}
    local folders = {"Mobs", "IgnoreThese"}
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
    if not character then
        return nil
    end
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "Body" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif partName == "Foot" then
        return character:FindFirstChild("LeftFoot") or character:FindFirstChild("RightFoot") or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild(partName) or character:FindFirstChild("Head")
end

local function WallCheck(part, ignoreWall)
    if ignoreWall then
        return true
    end
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
    Name = "RY ULTIMATE v5.1",
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

CombatTab:AddSection({ Name = "Aimbot" })
CombatTab:AddToggle({
    Name = "Enable Aimbot",
    Default = false,
    Flag = "ab_en",
    Callback = function(value)
        Config.Combat.Aimbot = value
    end
})

CombatTab:AddSlider({
    Name = "Aim Smoothness",
    Min = 1,
    Max = 20,
    Default = 5,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 1,
    ValueName = "x",
    Flag = "ab_s",
    Callback = function(value)
        Config.Combat.A_Smooth = value
    end
})

CombatTab:AddDropdown({
    Name = "A Part",
    Default = "Head",
    Options = {"Head", "Body", "Foot"},
    Flag = "ab_p",
    Callback = function(value)
        Config.Combat.A_Part = value
    end
})

CombatTab:AddSlider({
    Name = "A POV Radius",
    Min = 50,
    Max = 500,
    Default = 150,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 10,
    ValueName = "px",
    Flag = "ab_pov",
    Callback = function(value)
        Config.Combat.A_POV = value
    end
})

CombatTab:AddToggle({
    Name = "Show A POV",
    Default = false,
    Flag = "ab_spov",
    Callback = function(value)
        Config.Combat.ShowA_POV = value
    end
})

CombatTab:AddColorpicker({
    Name = "A POV Color",
    Default = Color3.fromRGB(0, 170, 255),
    Flag = "ab_povc",
    Callback = function(value)
        Config.Combat.A_POVColor = value
    end
})

CombatTab:AddToggle({
    Name = "Wall Check",
    Default = false,
    Flag = "ab_wc",
    Callback = function(value)
        Config.Combat.WallCheck = value
    end
})

CombatTab:AddSection({ Name = "Hitbox" })
CombatTab:AddToggle({
    Name = "Hitbox Expander",
    Default = false,
    Flag = "hb_en",
    Callback = function(value)
        Config.Combat.Hitbox = value
        if not value then
            -- Balikin ukuran asli pas dimatiin
            for part, originalSize in pairs(OriginalSizes) do
                if part and part.Parent then
                    part.Size = originalSize
                end
            end
            OriginalSizes = {}
        end
    end
})

CombatTab:AddSlider({
    Name = "Hitbox Size",
    Min = 1,
    Max = 10,
    Default = 2,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 1,
    ValueName = "x",
    Flag = "hb_s",
    Callback = function(value)
        Config.Combat.HitboxSize = value
    end
})

-- ==================================================
-- TAB: VISUAL
-- ==================================================
local VisualTab = Window:MakeTab({ Name = "Visual", Icon = "rbxassetid://4483362458" })

VisualTab:AddSection({ Name = "ESP Master" })
VisualTab:AddToggle({ Name = "ESP Box", Default = false, Flag = "v_eb", Callback = function(value) Config.Visual.ESP_Box = value end })
VisualTab:AddToggle({ Name = "ESP Name", Default = false, Flag = "v_en", Callback = function(value) Config.Visual.ESP_Name = value end })
VisualTab:AddToggle({ Name = "ESP Health", Default = false, Flag = "v_eh", Callback = function(value) Config.Visual.ESP_Health = value end })
VisualTab:AddToggle({ Name = "ESP Tracers", Default = false, Flag = "v_et", Callback = function(value) Config.Visual.ESP_Tracer = value end })
VisualTab:AddToggle({ Name = "ESP Skeleton (R6/R15)", Default = false, Flag = "v_esk", Callback = function(value) Config.Visual.ESP_Skeleton = value end })

VisualTab:AddSection({ Name = "ESP Colors" })
VisualTab:AddColorpicker({ Name = "Box Color", Default = Color3.fromRGB(255, 60, 60), Flag = "v_cb", Callback = function(value) Config.Visual.Color_Box = value end })
VisualTab:AddColorpicker({ Name = "Text Color", Default = Color3.fromRGB(255, 255, 255), Flag = "v_ct", Callback = function(value) Config.Visual.Color_Text = value end })
VisualTab:AddColorpicker({ Name = "Health Bar Color", Default = Color3.fromRGB(0, 255, 0), Flag = "v_ch", Callback = function(value) Config.Visual.Color_Health = value end })
VisualTab:AddColorpicker({ Name = "Tracers Color", Default = Color3.fromRGB(255, 0, 0), Flag = "v_ctr", Callback = function(value) Config.Visual.Color_Tracer = value end })
VisualTab:AddColorpicker({ Name = "Skeleton Color", Default = Color3.fromRGB(255, 255, 0), Flag = "v_csk", Callback = function(value) Config.Visual.Color_Skeleton = value end })

-- ==================================================
-- TAB: WEAPON
-- ==================================================
local WeaponTab = Window:MakeTab({ Name = "Weapon", Icon = "rbxassetid://4483362458" })

WeaponTab:AddSection({ Name = "Weapon Mods" })
WeaponTab:AddToggle({ Name = "Infinite Ammo", Default = false, Flag = "w_ia", Callback = function(value) Config.Weapon.Ammo = value end })
WeaponTab:AddToggle({ Name = "Rapid Fire", Default = false, Flag = "w_rf", Callback = function(value) Config.Weapon.Rapid = value end })
WeaponTab:AddSlider({ Name = "Rate Fire", Min = 1, Max = 1000, Default = 5, Color = Color3.fromRGB(0, 170, 255), Increment = 5, ValueName = "x", Flag = "w_fr", Callback = function(value) Config.Weapon.Rate = value end })
WeaponTab:AddToggle({ Name = "No Recoil", Default = false, Flag = "w_nr", Callback = function(value) Config.Weapon.Recoil = value end })
WeaponTab:AddToggle({ Name = "No Spread", Default = false, Flag = "w_ns", Callback = function(value) Config.Weapon.Spread = value end })
WeaponTab:AddToggle({ Name = "Fast Reload", Default = false, Flag = "w_frl", Callback = function(value) Config.Weapon.FastReload = value end })
WeaponTab:AddSlider({ Name = "Reload Speed", Min = 0.1, Max = 2, Default = 0.1, Color = Color3.fromRGB(0, 170, 255), Increment = 0.1, ValueName = "s", Flag = "w_rs", Callback = function(value) Config.Weapon.ReloadSpeed = value end })

-- ==================================================
-- TAB: PLAYER
-- ==================================================
local PlayerTab = Window:MakeTab({ Name = "Player", Icon = "rbxassetid://4483362458" })

PlayerTab:AddSection({ Name = "Survival & Movement" })
PlayerTab:AddToggle({ Name = "Fast Regen", Default = false, Flag = "p_fr", Callback = function(value) Config.Player.Regen = value end })
PlayerTab:AddSlider({ Name = "Regen Speed", Min = 1, Max = 100, Default = 10, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "HP", Flag = "p_rs", Callback = function(value) Config.Player.RegenSpeed = value end })
PlayerTab:AddToggle({ Name = "Speed Hack", Default = false, Flag = "p_sh", Callback = function(value) Config.Player.SpeedHack = value end })
PlayerTab:AddSlider({ Name = "Speed Value", Min = 16, Max = 100, Default = 30, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "spd", Flag = "p_sv", Callback = function(value) Config.Player.SpeedVal = value end })
PlayerTab:AddToggle({ Name = "Jump Hack", Default = false, Flag = "p_jh", Callback = function(value) Config.Player.JumpHack = value end })
PlayerTab:AddSlider({ Name = "Jump Value", Min = 50, Max = 300, Default = 60, Color = Color3.fromRGB(0, 170, 255), Increment = 5, ValueName = "pow", Flag = "p_jv", Callback = function(value) Config.Player.JumpVal = value end })
PlayerTab:AddToggle({ Name = "No Clip", Default = false, Flag = "p_nc", Callback = function(value) Config.Player.NoClip = value end })

-- ==================================================
-- TAB: FARM
-- ==================================================
local FarmTab = Window:MakeTab({ Name = "Farm", Icon = "rbxassetid://4483362458" })

FarmTab:AddSection({ Name = "Bring" })
FarmTab:AddToggle({ Name = "Bring Player", Default = false, Flag = "f_bp", Callback = function(value) Config.Farm.BringPlayer = value end })
FarmTab:AddDropdown({ Name = "Bring Type", Default = "SinglePlayerOnly", Options = {"SinglePlayerOnly", "AllPlayer"}, Flag = "f_bt", Callback = function(value) Config.Farm.BringType = value end })
FarmTab:AddSlider({ Name = "Bring Stund", Min = 0.1, Max = 2, Default = 0.5, Color = Color3.fromRGB(0, 170, 255), Increment = 0.1, ValueName = "s", Flag = "f_bs", Callback = function(value) Config.Farm.BringStund = value end })

FarmTab:AddSection({ Name = "Telekill" })
FarmTab:AddToggle({ Name = "Telekill (Auto Target)", Default = false, Flag = "f_tk", Callback = function(value) Config.Farm.Telekill = value end })
FarmTab:AddTextbox({ Name = "Tp Manual (Nama Player)", Default = "", TextDisappear = false, Flag = "f_tm", Callback = function(value) Config.Farm.TpManual = value end })
FarmTab:AddDropdown({ Name = "Tp Position", Default = "Depan", Options = {"Depan", "Belakang", "Atas", "Bawah"}, Flag = "f_tp", Callback = function(value) Config.Farm.TpPos = value end })
FarmTab:AddSlider({ Name = "Tp Stund (Delay)", Min = 0.1, Max = 2, Default = 0.5, Color = Color3.fromRGB(0, 170, 255), Increment = 0.1, ValueName = "s", Flag = "f_td", Callback = function(value) Config.Farm.TpDelay = value end })

-- ==================================================
-- DRAWINGS (POV)
-- ==================================================
local A_POV_Circle = Drawing.new("Circle")
A_POV_Circle.Thickness = 1
A_POV_Circle.NumSides = 64
A_POV_Circle.Filled = false
A_POV_Circle.Transparency = 1

-- ==================================================
-- AIMBOT TARGETING LOGIC
-- ==================================================
local function GetClosestTarget(fov, partName, ignoreWall)
    local closest = nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    local function checkCharacter(character)
        local part = GetPart(character, partName)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if distance < fov and distance < shortest and WallCheck(part, ignoreWall) then
                    shortest = distance
                    closest = { char = character, part = part }
                end
            end
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsEnemy(player) then
            checkCharacter(player.Character)
        end
    end
    
    for _, bot in ipairs(GetBots()) do
        checkCharacter(bot)
    end
    
    return closest
end

-- ==================================================
-- MAIN RENDER LOOP (AIMBOT & HITBOX)
-- ==================================================
RunService.RenderStepped:Connect(function()
    -- Update POV Circle
    A_POV_Circle.Radius = Config.Combat.A_POV
    A_POV_Circle.Color = Config.Combat.A_POVColor
    A_POV_Circle.Visible = Config.Combat.ShowA_POV
    A_POV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Aimbot Logic
    if Config.Combat.Aimbot then
        local aimTarget = GetClosestTarget(Config.Combat.A_POV, Config.Combat.A_Part, not Config.Combat.WallCheck)
        if aimTarget and aimTarget.part then
            local smooth = Config.Combat.A_Smooth > 0 and Config.Combat.A_Smooth or 1
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimTarget.part.Position), 1 / smooth)
        end
    end

    -- Hitbox Logic (FIXED BUG)
    if Config.Combat.Hitbox then
        for _, player in ipairs(Players:GetPlayers()) do
            if IsEnemy(player) then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if not OriginalSizes[part] then
                            OriginalSizes[part] = part.Size
                        end
                        part.Size = OriginalSizes[part] * Config.Combat.HitboxSize
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
    if ESPObjects[character] then
        return ESPObjects[character]
    end
    local obj = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBg = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Skeleton = {}
    }
    for i = 1, 12 do
        obj.Skeleton[i] = Drawing.new("Line")
    end
    for _, v in pairs(obj) do
        if typeof(v) == "table" then
            for _, line in pairs(v) do
                line.Thickness = 1
                line.Visible = false
            end
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
                for _, line in pairs(v) do
                    pcall(function() line:Remove() end)
                end
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
                local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                if onScreen then
                    local height = math.abs(headPos.Y - feetPos.Y)
                    local width = height * 0.6

                    -- Box
                    obj.Box.Visible = Config.Visual.ESP_Box
                    if Config.Visual.ESP_Box then
                        obj.Box.Color = Config.Visual.Color_Box
                        obj.Box.Size = Vector2.new(width, height)
                        obj.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
                    end

                    -- Name
                    obj.Name.Visible = Config.Visual.ESP_Name
                    if Config.Visual.ESP_Name then
                        obj.Name.Text = player.Name
                        obj.Name.Color = Config.Visual.Color_Text
                        obj.Name.Size = 14
                        obj.Name.Center = true
                        obj.Name.Outline = true
                        obj.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
                    end

                    -- Health
                    obj.HealthBg.Visible = Config.Visual.ESP_Health
                    obj.HealthBar.Visible = Config.Visual.ESP_Health
                    if Config.Visual.ESP_Health then
                        local hpPercent = hum.Health / hum.MaxHealth
                        obj.HealthBg.Color = Color3.new(0, 0, 0)
                        obj.HealthBg.Filled = true
                        obj.HealthBg.Size = Vector2.new(4, height)
                        obj.HealthBg.Position = Vector2.new(headPos.X - width / 2 - 6, headPos.Y)
                        
                        obj.HealthBar.Color = Config.Visual.Color_Health
                        obj.HealthBar.Filled = true
                        obj.HealthBar.Size = Vector2.new(4, height * hpPercent)
                        obj.HealthBar.Position = Vector2.new(headPos.X - width / 2 - 6, headPos.Y + (height - height * hpPercent))
                    end

                    -- Tracer
                    obj.Tracer.Visible = Config.Visual.ESP_Tracer
                    if Config.Visual.ESP_Tracer then
                        obj.Tracer.Color = Config.Visual.Color_Tracer
                        obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        obj.Tracer.To = Vector2.new(headPos.X, headPos.Y)
                    end

                    -- Skeleton
                    if Config.Visual.ESP_Skeleton then
                        local isR15 = character:FindFirstChild("UpperTorso") ~= nil
                        local points = {}
                        local partsToDraw = isR15 and {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"} or {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
                        
                        for _, partName in ipairs(partsToDraw) do
                            local part = character:FindFirstChild(partName)
                            if part then
                                local screenPoint = Camera:WorldToViewportPoint(part.Position)
                                points[partName] = screenPoint
                            end
                        end

                        local function drawLine(index, p1, p2)
                            if points[p1] and points[p2] then
                                obj.Skeleton[index].Color = Config.Visual.Color_Skeleton
                                obj.Skeleton[index].From = Vector2.new(points[p1].X, points[p1].Y)
                                obj.Skeleton[index].To = Vector2.new(points[p2].X, points[p2].Y)
                                obj.Skeleton[index].Visible = true
                            else
                                obj.Skeleton[index].Visible = false
                            end
                        end

                        if isR15 then
                            drawLine(1, "Head", "UpperTorso")
                            drawLine(2, "UpperTorso", "LowerTorso")
                            drawLine(3, "UpperTorso", "LeftUpperArm")
                            drawLine(4, "LeftUpperArm", "LeftLowerArm")
                            drawLine(5, "UpperTorso", "RightUpperArm")
                            drawLine(6, "RightUpperArm", "RightLowerArm")
                            drawLine(7, "LowerTorso", "LeftUpperLeg")
                            drawLine(8, "LowerTorso", "RightUpperLeg")
                            for i = 9, 12 do obj.Skeleton[i].Visible = false end
                        else
                            drawLine(1, "Head", "Torso")
                            drawLine(2, "Torso", "Left Arm")
                            drawLine(3, "Torso", "Right Arm")
                            drawLine(4, "Torso", "Left Leg")
                            drawLine(5, "Torso", "Right Leg")
                            for i = 6, 12 do obj.Skeleton[i].Visible = false end
                        end
                    else
                        for i = 1, 12 do obj.Skeleton[i].Visible = false end
                    end
                else
                    obj.Box.Visible = false
                    obj.Name.Visible = false
                    obj.HealthBg.Visible = false
                    obj.HealthBar.Visible = false
                    obj.Tracer.Visible = false
                    for i = 1, 12 do obj.Skeleton[i].Visible = false end
                end
            end
        end
    end
end)

-- ==================================================
-- WEAPON MODS LOOP (EXACT COPY FROM RY SIMPLE v1.1)
-- ==================================================
local PF = {"Debounce", "FireInterval", "ShootDelay", "AcquireDelay", "FireRate", "DelayUntilLoop"}
local PR = {"MaxRotRecoil", "MinRotRecoil", "MaxCamRecoil", "MinCamRecoil", "MaxTransRecoil", "MinTransRecoil", "RotRecoilConstant", "CamRecoilConstant", "TransRecoilConstant", "RotRecoilDamping"}
local PS = {"BaseSpread", "Spread", "ScopeSpreadMultiplier"}
local PA = {"FillAmmo", "Ammo"}

local function ScanWeapons()
    local found = {}
    for _, v in next, getgc(true) do 
        if type(v) == "table" then 
            local isWeapon = rawget(v, "FireInterval") or rawget(v, "BaseSpread") or rawget(v, "HeadDamage") or rawget(v, "MaxRotRecoil") or rawget(v, "FillAmmo") or rawget(v, "Debounce") or rawget(v, "Ammo")
            if isWeapon then 
                table.insert(found, v)
                if WeaponOriginals[v] == nil then 
                    local cache = {}
                    for _, list in ipairs({PF, PR, PS, PA}) do 
                        for _, k in ipairs(list) do 
                            cache[k] = rawget(v, k) 
                        end 
                    end 
                    cache["reloadTime"] = rawget(v, "reloadTime")
                    WeaponOriginals[v] = cache 
                end 
            end 
        end 
    end 
    WeaponTables = found 
end

ScanWeapons()
task.spawn(function() 
    while task.wait(5) do 
        ScanWeapons() 
    end 
end)

local lastWeaponUpdate = 0
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastWeaponUpdate < 0.1 then return end 
    lastWeaponUpdate = now 
    
    local anyActive = Config.Weapon.Recoil or Config.Weapon.Spread or Config.Weapon.Ammo or Config.Weapon.Rapid or Config.Weapon.FastReload
    if not anyActive then return end 
    
    for _, t in ipairs(WeaponTables) do 
        local orig = WeaponOriginals[t]
        if orig then 
            if Config.Weapon.Recoil then 
                for _, k in ipairs(PR) do 
                    if orig[k] ~= nil then 
                        if typeof(orig[k]) == "Vector3" then 
                            pcall(function() rawset(t, k, Vector3.zero) end) 
                        else 
                            pcall(function() rawset(t, k, 0) end) 
                        end 
                    end 
                end 
            end 
            
            if Config.Weapon.Spread then 
                for _, k in ipairs(PS) do 
                    if orig[k] ~= nil then 
                        pcall(function() rawset(t, k, 0) end) 
                    end 
                end 
            end 
            
            if Config.Weapon.Ammo then 
                if orig.FillAmmo and type(orig.FillAmmo) == "number" then 
                    pcall(function() rawset(t, "FillAmmo", orig.FillAmmo) end) 
                end 
                if orig.Ammo and type(orig.Ammo) == "number" then 
                    pcall(function() rawset(t, "Ammo", orig.Ammo) end) 
                end 
            end 
            
            if Config.Weapon.Rapid then 
                local mult = Config.Weapon.Rate 
                for _, k in ipairs(PF) do 
                    local v = orig[k]
                    if v and type(v) == "number" and v > 0 then 
                        pcall(function() rawset(t, k, math.max(v / mult, 0.001)) end) 
                    end 
                end 
            end 
            
            if Config.Weapon.FastReload then
                if orig["reloadTime"] then
                    pcall(function() rawset(t, "reloadTime", Config.Weapon.ReloadSpeed) end)
                end
            end
        end 
    end 
end)

-- ==================================================
-- PLAYER LOOP (Movement & Regen)
-- ==================================================
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.Player.SpeedHack then 
                hum.WalkSpeed = Config.Player.SpeedVal 
            end
            if Config.Player.JumpHack then 
                hum.UseJumpPower = true 
                hum.JumpPower = Config.Player.JumpVal 
            end
            if Config.Player.Regen and hum.Health < hum.MaxHealth then
                hum.Health = math.min(hum.Health + Config.Player.RegenSpeed, hum.MaxHealth)
            end
        end
        if Config.Player.NoClip then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.CanCollide = false 
                end
            end
        end
    end
end)

-- ==================================================
-- FARM LOOP (Telekill & Bring)
-- ==================================================
local lastTeleport = 0
local CurrentTelekillTarget = nil
local CurrentBringTarget = nil
local lastBring = 0

task.spawn(function()
    while task.wait(0.1) do
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if myHrp then
            -- ===== TELEKILL =====
            if Config.Farm.Telekill then
                if tick() - lastTeleport >= Config.Farm.TpDelay then
                    lastTeleport = tick()
                    
                    if not CurrentTelekillTarget or not CurrentTelekillTarget.Parent or not IsAlive(CurrentTelekillTarget) then
                        local closestChar = nil
                        local shortestDist = math.huge
                        
                        for _, player in ipairs(Players:GetPlayers()) do
                            if IsEnemy(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                local distance = (player.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                                if distance < shortestDist then 
                                    shortestDist = distance 
                                    closestChar = player.Character 
                                end
                            end
                        end
                        CurrentTelekillTarget = closestChar
                    end
                    
                    if CurrentTelekillTarget and CurrentTelekillTarget:FindFirstChild("HumanoidRootPart") then
                        local targetHrp = CurrentTelekillTarget.HumanoidRootPart
                        local offset = Vector3.new(0, 0, 0)
                        
                        if Config.Farm.TpPos == "Depan" then 
                            offset = targetHrp.CFrame.LookVector * 3
                        elseif Config.Farm.TpPos == "Belakang" then 
                            offset = -targetHrp.CFrame.LookVector * 3
                        elseif Config.Farm.TpPos == "Atas" then 
                            offset = Vector3.new(0, 5, 0)
                        elseif Config.Farm.TpPos == "Bawah" then 
                            offset = Vector3.new(0, -5, 0) 
                        end
                        
                        myHrp.CFrame = CFrame.new(targetHrp.Position + offset)
                    end
                end
            end

            -- ===== TP MANUAL =====
            if Config.Farm.TpManual ~= "" and not Config.Farm.Telekill then
                local targetPlayer = Players:FindFirstChild(Config.Farm.TpManual)
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHrp = targetPlayer.Character.HumanoidRootPart
                    local offset = Vector3.new(0, 0, 0)
                    
                    if Config.Farm.TpPos == "Depan" then 
                        offset = targetHrp.CFrame.LookVector * 3
                    elseif Config.Farm.TpPos == "Belakang" then 
                        offset = -targetHrp.CFrame.LookVector * 3
                    elseif Config.Farm.TpPos == "Atas" then 
                        offset = Vector3.new(0, 5, 0)
                    elseif Config.Farm.TpPos == "Bawah" then 
                        offset = Vector3.new(0, -5, 0) 
                    end
                    
                    myHrp.CFrame = CFrame.new(targetHrp.Position + offset)
                end
            end

            -- ===== BRING PLAYER =====
            if Config.Farm.BringPlayer then
                if tick() - lastBring >= Config.Farm.BringStund then
                    lastBring = tick()
                    
                    if Config.Farm.BringType == "SinglePlayerOnly" then
                        -- Nempel 1 Target (Kalau mati ganti target)
                        if not CurrentBringTarget or not CurrentBringTarget.Parent or not IsAlive(CurrentBringTarget) then
                            local closestChar = nil
                            local shortestDist = math.huge
                            
                            for _, player in ipairs(Players:GetPlayers()) do
                                if IsEnemy(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                    local distance = (player.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                                    if distance < shortestDist then 
                                        shortestDist = distance 
                                        closestChar = player.Character 
                                    end
                                end
                            end
                            CurrentBringTarget = closestChar
                        end
                        
                        if CurrentBringTarget and CurrentBringTarget:FindFirstChild("HumanoidRootPart") then
                            -- Tarik musuh tepat ke depan muka kita
                            CurrentBringTarget.HumanoidRootPart.CFrame = myHrp.CFrame * CFrame.new(0, 0, -3)
                        end
                    else
                        -- Tarik semua player
                        for _, player in ipairs(Players:GetPlayers()) do
                            if IsEnemy(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                local randomX = math.random(-3, 3)
                                local randomZ = math.random(-3, -1)
                                player.Character.HumanoidRootPart.CFrame = myHrp.CFrame * CFrame.new(randomX, 0, randomZ)
                            end
                        end
                    end
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
    Name = "RY ULTIMATE v5.1",
    Content = "Full Expanded Script Loaded!",
    Image = "rbxassetid://4483362458",
    Time = 5
})

print("RY ULTIMATE v5.1 | Loaded Without Errors")
