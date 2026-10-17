-- ==================================================
-- RY ULTIMATE v4.0 — FULL FIXED & COMPLETE
-- Weapon Logic: 100% Copied from RY SIMPLE v1.1
-- ==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local C = workspace.CurrentCamera

local W = {}
local WO = {}
local EC = {}

local F = {
    Combat = {
        SilentAim = false,
        S_Part = "Head",
        HitChance = 100,
        Prediction = false,
        PredictionAmount = 0.1,
        PingBuffer = 20,
        S_POV = 200,
        ShowS_POV = false,
        S_POVColor = Color3.fromRGB(255, 0, 0),
        Snapline = false,
        SnapLineColor = Color3.fromRGB(255, 255, 255),
        WallBang = false,

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
        
        Telekill = false,
        TpManual = "",
        TpPos = "Depan",
        TpDelay = 0.5,
    }
}

local function IsAlive(char)
    if not char or not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function IsEnemy(p)
    if p == LP then return false end
    if not p.Character or not IsAlive(p.Character) then return false end
    return true
end

local function GetBots()
    local bots = {}
    for _, folderName in ipairs({"Mobs", "IgnoreThese"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, b in ipairs(folder:GetChildren()) do
                if IsAlive(b) then table.insert(bots, b) end
            end
        end
    end
    return bots
end

local function GetPart(char, partName)
    if not char then return nil end
    if partName == "Head" then return char:FindFirstChild("Head") end
    if partName == "Body" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") end
    if partName == "Foot" then return char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightFoot") or char:FindFirstChild("HumanoidRootPart") end
    return char:FindFirstChild(partName) or char:FindFirstChild("Head")
end

local function WallCheck(part, ignoreWall)
    if ignoreWall then return true end
    local r = RaycastParams.new()
    r.FilterType = Enum.RaycastFilterType.Exclude
    r.FilterDescendantsInstances = {LP.Character, C}
    local res = workspace:Raycast(C.CFrame.Position, part.Position - C.CFrame.Position, r)
    return res == nil or res.Instance:IsDescendantOf(part.Parent)
end

-- ==================== LOAD ORION UI ====================
local O = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()
local Win = O:MakeWindow({
    Name = "RY ULTIMATE v4.0",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "RY",
    IntroEnabled = true,
    IntroText = "RY ULTIMATE",
    IntroIcon = "rbxassetid://4483362458",
    Icon = "rbxassetid://4483362458"
})

-- ==================== TAB: COMBAT ====================
local CombatTab = Win:MakeTab({ Name = "Combat", Icon = "rbxassetid://4483362458" })

CombatTab:AddSection({ Name = "Silent Aim" })
CombatTab:AddToggle({ Name = "Enable Silent Aim", Default = false, Flag = "sa_en", Callback = function(v) F.Combat.SilentAim = v end })
CombatTab:AddDropdown({ Name = "S Part", Default = "Head", Options = {"Head", "Body", "Foot"}, Flag = "sa_p", Callback = function(v) F.Combat.S_Part = v end })
CombatTab:AddSlider({ Name = "Hit Chance", Min = 10, Max = 100, Default = 100, Color = Color3.fromRGB(0, 255, 100), Increment = 5, ValueName = "%", Flag = "sa_hc", Callback = function(v) F.Combat.HitChance = v end })
CombatTab:AddToggle({ Name = "Prediction", Default = false, Flag = "sa_pred", Callback = function(v) F.Combat.Prediction = v end })
CombatTab:AddSlider({ Name = "Prediction Amount", Min = 0.05, Max = 0.5, Default = 0.1, Color = Color3.fromRGB(0, 255, 100), Increment = 0.05, ValueName = "s", Flag = "sa_pa", Callback = function(v) F.Combat.PredictionAmount = v end })
CombatTab:AddSlider({ Name = "Ping Buffer", Min = 0, Max = 200, Default = 20, Color = Color3.fromRGB(0, 255, 100), Increment = 5, ValueName = "ms", Flag = "sa_pb", Callback = function(v) F.Combat.PingBuffer = v end })
CombatTab:AddSlider({ Name = "S POV Radius", Min = 50, Max = 500, Default = 200, Color = Color3.fromRGB(255, 0, 0), Increment = 10, ValueName = "px", Flag = "sa_pov", Callback = function(v) F.Combat.S_POV = v end })
CombatTab:AddToggle({ Name = "Show S POV", Default = false, Flag = "sa_spov", Callback = function(v) F.Combat.ShowS_POV = v end })
CombatTab:AddColorpicker({ Name = "S POV Color", Default = Color3.fromRGB(255, 0, 0), Flag = "sa_povc", Callback = function(v) F.Combat.S_POVColor = v end })
CombatTab:AddToggle({ Name = "Snapline (Crosshair)", Default = false, Flag = "sa_snap", Callback = function(v) F.Combat.Snapline = v end })
CombatTab:AddColorpicker({ Name = "Snapline Color", Default = Color3.fromRGB(255, 255, 255), Flag = "sa_snapc", Callback = function(v) F.Combat.SnapLineColor = v end })
CombatTab:AddToggle({ Name = "Wall Bang", Default = false, Flag = "sa_wb", Callback = function(v) F.Combat.WallBang = v end })

CombatTab:AddSection({ Name = "Aimbot" })
CombatTab:AddToggle({ Name = "Enable Aimbot", Default = false, Flag = "ab_en", Callback = function(v) F.Combat.Aimbot = v end })
CombatTab:AddSlider({ Name = "Aim Smoothness", Min = 1, Max = 20, Default = 5, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "x", Flag = "ab_s", Callback = function(v) F.Combat.A_Smooth = v end })
CombatTab:AddDropdown({ Name = "A Part", Default = "Head", Options = {"Head", "Body", "Foot"}, Flag = "ab_p", Callback = function(v) F.Combat.A_Part = v end })
CombatTab:AddSlider({ Name = "A POV Radius", Min = 50, Max = 500, Default = 150, Color = Color3.fromRGB(0, 170, 255), Increment = 10, ValueName = "px", Flag = "ab_pov", Callback = function(v) F.Combat.A_POV = v end })
CombatTab:AddToggle({ Name = "Show A POV", Default = false, Flag = "ab_spov", Callback = function(v) F.Combat.ShowA_POV = v end })
CombatTab:AddColorpicker({ Name = "A POV Color", Default = Color3.fromRGB(0, 170, 255), Flag = "ab_povc", Callback = function(v) F.Combat.A_POVColor = v end })
CombatTab:AddToggle({ Name = "Wall Check", Default = false, Flag = "ab_wc", Callback = function(v) F.Combat.WallCheck = v end })

CombatTab:AddSection({ Name = "Hitbox" })
CombatTab:AddToggle({ Name = "Hitbox Expander", Default = false, Flag = "hb_en", Callback = function(v) F.Combat.Hitbox = v end })
CombatTab:AddSlider({ Name = "Hitbox Size", Min = 1, Max = 10, Default = 2, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "x", Flag = "hb_s", Callback = function(v) F.Combat.HitboxSize = v end })

-- ==================== TAB: VISUAL ====================
local VisualTab = Win:MakeTab({ Name = "Visual", Icon = "rbxassetid://4483362458" })
VisualTab:AddSection({ Name = "ESP Master" })
VisualTab:AddToggle({ Name = "ESP Box", Default = false, Flag = "v_eb", Callback = function(v) F.Visual.ESP_Box = v end })
VisualTab:AddToggle({ Name = "ESP Name", Default = false, Flag = "v_en", Callback = function(v) F.Visual.ESP_Name = v end })
VisualTab:AddToggle({ Name = "ESP Health", Default = false, Flag = "v_eh", Callback = function(v) F.Visual.ESP_Health = v end })
VisualTab:AddToggle({ Name = "ESP Tracers", Default = false, Flag = "v_et", Callback = function(v) F.Visual.ESP_Tracer = v end })
VisualTab:AddToggle({ Name = "ESP Skeleton (R6/R15)", Default = false, Flag = "v_esk", Callback = function(v) F.Visual.ESP_Skeleton = v end })

VisualTab:AddSection({ Name = "ESP Colors" })
VisualTab:AddColorpicker({ Name = "Box Color", Default = Color3.fromRGB(255, 60, 60), Flag = "v_cb", Callback = function(v) F.Visual.Color_Box = v end })
VisualTab:AddColorpicker({ Name = "Text Color", Default = Color3.fromRGB(255, 255, 255), Flag = "v_ct", Callback = function(v) F.Visual.Color_Text = v end })
VisualTab:AddColorpicker({ Name = "Health Bar Color", Default = Color3.fromRGB(0, 255, 0), Flag = "v_ch", Callback = function(v) F.Visual.Color_Health = v end })
VisualTab:AddColorpicker({ Name = "Tracers Color", Default = Color3.fromRGB(255, 0, 0), Flag = "v_ctr", Callback = function(v) F.Visual.Color_Tracer = v end })
VisualTab:AddColorpicker({ Name = "Skeleton Color", Default = Color3.fromRGB(255, 255, 0), Flag = "v_csk", Callback = function(v) F.Visual.Color_Skeleton = v end })

-- ==================== TAB: WEAPON ====================
local WeaponTab = Win:MakeTab({ Name = "Weapon", Icon = "rbxassetid://4483362458" })
WeaponTab:AddSection({ Name = "Weapon Mods" })
WeaponTab:AddToggle({ Name = "Infinite Ammo", Default = false, Flag = "w_ia", Callback = function(v) F.Weapon.Ammo = v end })
WeaponTab:AddToggle({ Name = "Rapid Fire", Default = false, Flag = "w_rf", Callback = function(v) F.Weapon.Rapid = v end })
WeaponTab:AddSlider({ Name = "Rate Fire", Min = 1, Max = 1000, Default = 5, Color = Color3.fromRGB(0, 170, 255), Increment = 5, ValueName = "x", Flag = "w_fr", Callback = function(v) F.Weapon.Rate = v end })
WeaponTab:AddToggle({ Name = "No Recoil", Default = false, Flag = "w_nr", Callback = function(v) F.Weapon.Recoil = v end })
WeaponTab:AddToggle({ Name = "No Spread", Default = false, Flag = "w_ns", Callback = function(v) F.Weapon.Spread = v end })
WeaponTab:AddToggle({ Name = "Fast Reload", Default = false, Flag = "w_frl", Callback = function(v) F.Weapon.FastReload = v end })
WeaponTab:AddSlider({ Name = "Reload Speed", Min = 0.1, Max = 2, Default = 0.1, Color = Color3.fromRGB(0, 170, 255), Increment = 0.1, ValueName = "s", Flag = "w_rs", Callback = function(v) F.Weapon.ReloadSpeed = v end })

-- ==================== TAB: PLAYER ====================
local PlayerTab = Win:MakeTab({ Name = "Player", Icon = "rbxassetid://4483362458" })
PlayerTab:AddSection({ Name = "Survival & Movement" })
PlayerTab:AddToggle({ Name = "Fast Regen", Default = false, Flag = "p_fr", Callback = function(v) F.Player.Regen = v end })
PlayerTab:AddSlider({ Name = "Regen Speed", Min = 1, Max = 100, Default = 10, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "HP", Flag = "p_rs", Callback = function(v) F.Player.RegenSpeed = v end })
PlayerTab:AddToggle({ Name = "Speed Hack", Default = false, Flag = "p_sh", Callback = function(v) F.Player.SpeedHack = v end })
PlayerTab:AddSlider({ Name = "Speed Value", Min = 16, Max = 100, Default = 30, Color = Color3.fromRGB(0, 170, 255), Increment = 1, ValueName = "spd", Flag = "p_sv", Callback = function(v) F.Player.SpeedVal = v end })
PlayerTab:AddToggle({ Name = "Jump Hack", Default = false, Flag = "p_jh", Callback = function(v) F.Player.JumpHack = v end })
PlayerTab:AddSlider({ Name = "Jump Value", Min = 50, Max = 300, Default = 60, Color = Color3.fromRGB(0, 170, 255), Increment = 5, ValueName = "pow", Flag = "p_jv", Callback = function(v) F.Player.JumpVal = v end })
PlayerTab:AddToggle({ Name = "No Clip", Default = false, Flag = "p_nc", Callback = function(v) F.Player.NoClip = v end })

PlayerTab:AddSection({ Name = "Telekill" })
PlayerTab:AddToggle({ Name = "Telekill (Auto Target)", Default = false, Flag = "t_ek", Callback = function(v) F.Player.Telekill = v end })
PlayerTab:AddTextbox({ Name = "Tp Manual (Nama Player)", Default = "", TextDisappear = false, Flag = "t_tm", Callback = function(v) F.Player.TpManual = v end })
PlayerTab:AddDropdown({ Name = "Tp Position", Default = "Depan", Options = {"Depan", "Belakang", "Atas", "Bawah"}, Flag = "t_tp", Callback = function(v) F.Player.TpPos = v end })
PlayerTab:AddSlider({ Name = "Tp Stund (Delay)", Min = 0.1, Max = 2, Default = 0.5, Color = Color3.fromRGB(0, 170, 255), Increment = 0.1, ValueName = "s", Flag = "t_td", Callback = function(v) F.Player.TpDelay = v end })

-- ==================== DRAWINGS ====================
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

-- ==================== TARGET LOGIC ====================
local function GetClosestTarget(fov, partName, ignoreWall)
    local closest, shortest = nil, math.huge
    local center = Vector2.new(C.ViewportSize.X / 2, C.ViewportSize.Y / 2)
    local function check(char)
        local part = GetPart(char, partName)
        if part then
            local sp, onScr = C:WorldToViewportPoint(part.Position)
            if onScr then
                local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if dist < fov and dist < shortest and WallCheck(part, ignoreWall) then
                    shortest = dist
                    closest = { char = char, part = part }
                end
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do if IsEnemy(p) then check(p.Character) end end
    for _, b in ipairs(GetBots()) do check(b) end
    return closest
end

local function GetPredictedPosition(part)
    if not F.Combat.Prediction or not part then return part.Position end
    local hrp = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
    if hrp then
        local totalTime = F.Combat.PredictionAmount + (F.Combat.PingBuffer / 1000)
        return part.Position + (hrp.AssemblyLinearVelocity * totalTime)
    end
    return part.Position
end

-- ==================== SILENT AIM HOOK ====================
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    
    if F.Combat.SilentAim and method == "FireServer" and self and self.Name then
        if self.Name == "GunShot" or self.Name == "Shoot" or self.Name == "CheckShot" or self.Name == "ProjectileRender" then
            if math.random(1, 100) <= F.Combat.HitChance then
                local target = GetClosestTarget(F.Combat.S_POV, F.Combat.S_Part, F.Combat.WallBang)
                if target and target.part then
                    local finalPos = GetPredictedPosition(target.part)
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = (finalPos - C.CFrame.Position).Unit
                        elseif typeof(v) == "CFrame" then
                            args[i] = CFrame.lookAt(C.CFrame.Position, finalPos)
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

-- ==================== MAIN RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    S_POV_Circle.Radius = F.Combat.S_POV
    S_POV_Circle.Color = F.Combat.S_POVColor
    S_POV_Circle.Visible = F.Combat.ShowS_POV
    S_POV_Circle.Position = Vector2.new(C.ViewportSize.X / 2, C.ViewportSize.Y / 2)

    A_POV_Circle.Radius = F.Combat.A_POV
    A_POV_Circle.Color = F.Combat.A_POVColor
    A_POV_Circle.Visible = F.Combat.ShowA_POV
    A_POV_Circle.Position = Vector2.new(C.ViewportSize.X / 2, C.ViewportSize.Y / 2)

    local snapTarget = GetClosestTarget(F.Combat.S_POV, F.Combat.S_Part, F.Combat.WallBang)
    if F.Combat.Snapline and snapTarget and snapTarget.part then
        local sp = C:WorldToViewportPoint(snapTarget.part.Position)
        SnapLine_Draw.From = Vector2.new(C.ViewportSize.X / 2, C.ViewportSize.Y / 2)
        SnapLine_Draw.To = Vector2.new(sp.X, sp.Y)
        SnapLine_Draw.Color = F.Combat.SnapLineColor
        SnapLine_Draw.Visible = true
    else
        SnapLine_Draw.Visible = false
    end

    if F.Combat.Aimbot then
        local aimTarget = GetClosestTarget(F.Combat.A_POV, F.Combat.A_Part, not F.Combat.WallCheck)
        if aimTarget and aimTarget.part then
            local smooth = F.Combat.A_Smooth > 0 and F.Combat.A_Smooth or 1
            C.CFrame = C.CFrame:Lerp(CFrame.new(C.CFrame.Position, aimTarget.part.Position), 1 / smooth)
        end
    end

    if F.Combat.Hitbox then
        for _, p in ipairs(Players:GetPlayers()) do
            if IsEnemy(p) then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Size = part.Size:Lerp(Vector3.new(part.Size.X * F.Combat.HitboxSize, part.Size.Y * F.Combat.HitboxSize, part.Size.Z * F.Combat.HitboxSize), 0.5)
                        part.Transparency = 0.5
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- ==================== ESP RENDER LOOP ====================
local function CreateESPObject(character)
    if EC[character] then return EC[character] end
    local obj = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBg = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Skeleton = {}
    }
    for i = 1, 12 do obj.Skeleton[i] = Drawing.new("Line") end
    for _, v in pairs(obj) do
        if typeof(v) == "table" then
            for _, line in pairs(v) do line.Thickness = 1 line.Visible = false end
        else
            v.Thickness = 1
            v.Visible = false
        end
    end
    EC[character] = obj
    return obj
end

local function RemoveESPObject(character)
    local obj = EC[character]
    if obj then
        for _, v in pairs(obj) do
            if typeof(v) == "table" then
                for _, line in pairs(v) do pcall(function() line:Remove() end) end
            else
                pcall(function() v:Remove() end)
            end
        end
        EC[character] = nil
    end
end

RunService.RenderStepped:Connect(function()
    for character in pairs(EC) do
        if not character or not character.Parent or not IsAlive(character) then
            RemoveESPObject(character)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if IsEnemy(p) then
            local char = p.Character
            local obj = CreateESPObject(char)
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")

            if hrp and head and hum then
                local hPos, onScr = C:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local fPos = C:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                if onScr then
                    local height = math.abs(hPos.Y - fPos.Y)
                    local width = height * 0.6

                    obj.Box.Visible = F.Visual.ESP_Box
                    if F.Visual.ESP_Box then
                        obj.Box.Color = F.Visual.Color_Box
                        obj.Box.Size = Vector2.new(width, height)
                        obj.Box.Position = Vector2.new(hPos.X - width / 2, hPos.Y)
                    end

                    obj.Name.Visible = F.Visual.ESP_Name
                    if F.Visual.ESP_Name then
                        obj.Name.Text = p.Name
                        obj.Name.Color = F.Visual.Color_Text
                        obj.Name.Size = 14
                        obj.Name.Center = true
                        obj.Name.Outline = true
                        obj.Name.Position = Vector2.new(hPos.X, hPos.Y - 20)
                    end

                    obj.HealthBg.Visible = F.Visual.ESP_Health
                    obj.HealthBar.Visible = F.Visual.ESP_Health
                    if F.Visual.ESP_Health then
                        local hp = hum.Health / hum.MaxHealth
                        obj.HealthBg.Color = Color3.new(0, 0, 0)
                        obj.HealthBg.Filled = true
                        obj.HealthBg.Size = Vector2.new(4, height)
                        obj.HealthBg.Position = Vector2.new(hPos.X - width / 2 - 6, hPos.Y)
                        
                        obj.HealthBar.Color = F.Visual.Color_Health
                        obj.HealthBar.Filled = true
                        obj.HealthBar.Size = Vector2.new(4, height * hp)
                        obj.HealthBar.Position = Vector2.new(hPos.X - width / 2 - 6, hPos.Y + (height - height * hp))
                    end

                    obj.Tracer.Visible = F.Visual.ESP_Tracer
                    if F.Visual.ESP_Tracer then
                        obj.Tracer.Color = F.Visual.Color_Tracer
                        obj.Tracer.From = Vector2.new(C.ViewportSize.X / 2, C.ViewportSize.Y)
                        obj.Tracer.To = Vector2.new(hPos.X, hPos.Y)
                    end

                    if F.Visual.ESP_Skeleton then
                        local isR15 = char:FindFirstChild("UpperTorso") ~= nil
                        local pts = {}
                        local partsToDraw = isR15 and {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"} or {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
                        
                        for _, name in ipairs(partsToDraw) do
                            local pt = char:FindFirstChild(name)
                            if pt then
                                local s, _ = C:WorldToViewportPoint(pt.Position)
                                pts[name] = s
                            end
                        end

                        local function drawLine(index, p1, p2)
                            if pts[p1] and pts[p2] then
                                obj.Skeleton[index].Color = F.Visual.Color_Skeleton
                                obj.Skeleton[index].From = Vector2.new(pts[p1].X, pts[p1].Y)
                                obj.Skeleton[index].To = Vector2.new(pts[p2].X, pts[p2].Y)
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

-- ==================== WEAPON MODS (100% COPIED FROM RY SIMPLE) ====================
local PF = {"Debounce", "FireInterval", "ShootDelay", "AcquireDelay", "FireRate", "DelayUntilLoop"}
local PR = {"MaxRotRecoil", "MinRotRecoil", "MaxCamRecoil", "MinCamRecoil", "MaxTransRecoil", "MinTransRecoil", "RotRecoilConstant", "CamRecoilConstant", "TransRecoilConstant", "RotRecoilDamping"}
local PS = {"BaseSpread", "Spread", "ScopeSpreadMultiplier"}
local PA = {"FillAmmo", "Ammo"}

local function SW()
    local f = {}
    for _, v in next, getgc(true) do 
        if type(v) == "table" then 
            local isW = rawget(v, "FireInterval") or rawget(v, "BaseSpread") or rawget(v, "HeadDamage") or rawget(v, "MaxRotRecoil") or rawget(v, "FillAmmo") or rawget(v, "Debounce") or rawget(v, "Ammo")
            if isW then 
                table.insert(f, v)
                if WO[v] == nil then 
                    local c = {}
                    for _, l in ipairs({PF, PR, PS, PA}) do 
                        for _, k in ipairs(l) do 
                            c[k] = rawget(v, k) 
                        end 
                    end 
                    c["reloadTime"] = rawget(v, "reloadTime") -- Tambahan buat Fast Reload
                    WO[v] = c 
                end 
            end 
        end 
    end 
    W = f 
end

SW()
task.spawn(function() 
    while task.wait(5) do 
        SW() 
    end 
end)

local lw = 0
RunService.Heartbeat:Connect(function()
    local n = tick()
    if n - lw < 0.1 then return end 
    lw = n 
    
    local act = F.Weapon.Recoil or F.Weapon.Spread or F.Weapon.Ammo or F.Weapon.Rapid or F.Weapon.FastReload
    if not act then return end 
    
    for _, t in ipairs(W) do 
        local o = WO[t]
        if o then 
            if F.Weapon.Recoil then 
                for _, k in ipairs(PR) do 
                    if o[k] ~= nil then 
                        if typeof(o[k]) == "Vector3" then 
                            pcall(function() rawset(t, k, Vector3.zero) end) 
                        else 
                            pcall(function() rawset(t, k, 0) end) 
                        end 
                    end 
                end 
            end 
            if F.Weapon.Spread then 
                for _, k in ipairs(PS) do 
                    if o[k] ~= nil then 
                        pcall(function() rawset(t, k, 0) end) 
                    end 
                end 
            end 
            if F.Weapon.Ammo then 
                if o.FillAmmo and type(o.FillAmmo) == "number" then 
                    pcall(function() rawset(t, "FillAmmo", o.FillAmmo) end) 
                end 
                if o.Ammo and type(o.Ammo) == "number" then 
                    pcall(function() rawset(t, "Ammo", o.Ammo) end) 
                end 
            end 
            if F.Weapon.Rapid then 
                local m = F.Weapon.Rate 
                for _, k in ipairs(PF) do 
                    local v = o[k]
                    if v and type(v) == "number" and v > 0 then 
                        pcall(function() rawset(t, k, math.max(v/m, 0.001)) end) 
                    end 
                end 
            end 
            if F.Weapon.FastReload then
                if o["reloadTime"] then
                    pcall(function() rawset(t, "reloadTime", F.Weapon.ReloadSpeed) end)
                end
            end
        end 
    end 
end)

-- ==================== PLAYER & TELEKILL LOOPS ====================
RunService.Heartbeat:Connect(function()
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if F.Player.SpeedHack then hum.WalkSpeed = F.Player.SpeedVal end
            if F.Player.JumpHack then hum.UseJumpPower = true hum.JumpPower = F.Player.JumpVal end
            if F.Player.Regen and hum.Health < hum.MaxHealth then
                hum.Health = math.min(hum.Health + F.Player.RegenSpeed, hum.MaxHealth)
            end
        end
        if F.Player.NoClip then
            for _, v in ipairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

-- Telekill Loop (FIXED DELAY)
local lastTP = 0
local CurrentTelekillTarget = nil
task.spawn(function()
    while task.wait(0.1) do
        if F.Player.Telekill and LP.Character then
            local mH = LP.Character:FindFirstChild("HumanoidRootPart")
            if mH then
                if tick() - lastTP >= F.Player.TpDelay then
                    lastTP = tick()
                    if not CurrentTelekillTarget or not CurrentTelekillTarget.Parent or not IsAlive(CurrentTelekillTarget) then
                        local cl, d = nil, math.huge
                        for _, p in ipairs(Players:GetPlayers()) do
                            if IsEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                local dd = (p.Character.HumanoidRootPart.Position - mH.Position).Magnitude
                                if dd < d then d = dd cl = p.Character end
                            end
                        end
                        CurrentTelekillTarget = cl
                    end
                    if CurrentTelekillTarget and CurrentTelekillTarget:FindFirstChild("HumanoidRootPart") then
                        local tH = CurrentTelekillTarget.HumanoidRootPart
                        local off = Vector3.new(0,0,0)
                        if F.Player.TpPos == "Depan" then off = tH.CFrame.LookVector * 3
                        elseif F.Player.TpPos == "Belakang" then off = -tH.CFrame.LookVector * 3
                        elseif F.Player.TpPos == "Atas" then off = Vector3.new(0,5,0)
                        elseif F.Player.TpPos == "Bawah" then off = Vector3.new(0,-5,0) end
                        mH.CFrame = CFrame.new(tH.Position + off)
                    end
                end
            end
        end
    end
end)

-- TP Manual Loop
task.spawn(function()
    while task.wait(1) do
        if F.Player.TpManual ~= "" and not F.Player.Telekill then
            local t = Players:FindFirstChild(F.Player.TpManual)
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                local mH = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if mH then
                    local tH = t.Character.HumanoidRootPart
                    local off = Vector3.new(0,0,0)
                    if F.Player.TpPos == "Depan" then off = tH.CFrame.LookVector * 3
                    elseif F.Player.TpPos == "Belakang" then off = -tH.CFrame.LookVector * 3
                    elseif F.Player.TpPos == "Atas" then off = Vector3.new(0,5,0)
                    elseif F.Player.TpPos == "Bawah" then off = Vector3.new(0,-5,0) end
                    mH.CFrame = CFrame.new(tH.Position + off)
                end
            end
        end
    end
end)

-- ==================== INITIALIZATION ====================
O:Init()
O:MakeNotification({
    Name = "RY ULTIMATE v4.0",
    Content = "Full Features Loaded!",
    Image = "rbxassetid://4483362458",
    Time = 5
})
print("RY ULTIMATE v4.0 | RY Weapon Logic Applied")
