-- =====================================================
--  RENXX HUB v10.3 | BUG FIX ULTIMATE
--  Fix: Snapline, Aimbot WallCheck, ESP Box Alignment
--  UI: Rayfield | Made by: Ren & Deep
-- =====================================================

local StarterGui = game:GetService("StarterGui")
local function DebugMsg(msg, color)
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[RENXX] " .. tostring(msg),
            Color = color or Color3.fromRGB(100, 255, 150),
            Font = Enum.Font.SourceSansBold,
            TextSize = 18
        })
    end)
end
local function DebugOK(msg) DebugMsg(msg, Color3.fromRGB(100, 255, 150)) end
local function DebugWarn(msg) DebugMsg(msg, Color3.fromRGB(255, 200, 100)) end

DebugOK("Loading RENXX v10.3...")

local successRay, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not successRay or not Rayfield then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =====================================================
-- SETTINGS
-- =====================================================
getgenv().RENXX = getgenv().RENXX or {}
getgenv().RENXX.S = {
    -- Visual
    ESPPlayerEnemy = true, ColorPlayerEnemy = Color3.fromRGB(255, 50, 50),
    ESPPlayerTeam = false, ColorPlayerTeam = Color3.fromRGB(50, 255, 50),
    ESPBotEnemy = true, ColorBotEnemy = Color3.fromRGB(255, 165, 0),
    ESPBotTeam = false, ColorBotTeam = Color3.fromRGB(0, 255, 255),
    ESPName = true, ColorName = Color3.fromRGB(255, 255, 255),
    ESPHealth = true, ColorHealth = Color3.fromRGB(0, 255, 0),
    
    -- Combat
    Aimbot = false, AimSmooth = 3, AimTarget = "All", AimPart = "Head",
    ShowPOV = true, POVRadius = 150, POVColor = Color3.fromRGB(255, 0, 0),
    SnapLine = true, SnapLineColor = Color3.fromRGB(255, 50, 50), -- BUG FIX: Independen
    TeamCheck = true, WallCheck = true,
    Hitbox = false, HitboxSize = 5,
    
    -- Player
    SpeedHack = false, SpeedValue = 32,
    JumpHack = false, JumpValue = 50,
    InfJump = false, NoClip = false,
    
    -- Farm
    KillAllEnabled = false, KillAllDelay = 0.04, KillAllTargetPart = "Head",
    BringEnemy = false, BringType = "SingleEnemy", BringTarget = "All", BringStuds = 5
}
local S = getgenv().RENXX.S

-- =====================================================
-- CORE REFERENCES
-- =====================================================
local DeagleController = nil
local DeagleShared = nil

pcall(function()
    local PS = LocalPlayer:WaitForChild("PlayerScripts", 10)
    if PS then
        local ML = PS:WaitForChild("ModuleLoader", 10)
        if ML then DeagleController = require(ML:WaitForChild("DeagleController", 10)) end
    end
end)

pcall(function()
    local Mods = ReplicatedStorage:WaitForChild("Modules", 10)
    if Mods then
        local Shared = Mods:WaitForChild("Shared", 10)
        if Shared then DeagleShared = require(Shared:WaitForChild("DeagleShared", 10)) end
    end
end)

-- =====================================================
-- HELPERS
-- =====================================================
local function IsAlive(char)
    if not char or not char.Parent then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function IsEnemy(char)
    if not S.TeamCheck then return true end
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myTeam = myChar:GetAttribute("GamemodeTeam")
    local targetTeam = char:GetAttribute("GamemodeTeam")
    if myTeam and targetTeam then return myTeam ~= targetTeam end
    return true
end

local function GetTargetPart(char, partName)
    if partName == "Head" then return char:FindFirstChild("Head") end
    if partName == "Body" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") end
    if partName == "Foot" then return char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftLeg") or char:FindFirstChild("RightLeg") end
    return char:FindFirstChild("Head")
end

local function GetPredictedPosition(part)
    local char = part.Parent
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if root then
        return part.Position + (root.AssemblyLinearVelocity * ((LocalPlayer:GetNetworkPing() or 0.03) * 1.85))
    end
    return part.Position
end

-- Fungsi Raycast buat ngecek tembok
local function IsWallBlocking(char, targetPart)
    if not S.WallCheck then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    local ray = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, params)
    
    if ray then
        -- Kalo kena sesuatu, cek apakah itu bagian dari musuh
        return not ray.Instance:IsDescendantOf(char)
    end
    return false -- Gak kena tembok
end

local function GetTargets(targetType)
    local list = {}
    if targetType == "All" or targetType == "PlayerOnly" or targetType == "PlayerEnemy" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
                if targetType == "PlayerEnemy" then
                    if IsEnemy(p.Character) then table.insert(list, p.Character) end
                else
                    table.insert(list, p.Character)
                end
            end
        end
    end
    if targetType == "All" or targetType == "BotOnly" or targetType == "BotEnemy" then
        for _, m in ipairs(workspace:GetChildren()) do
            if m:IsA("Model") and m:GetAttribute("IsBot") == true and IsAlive(m) then
                if targetType == "BotEnemy" then
                    if IsEnemy(m) then table.insert(list, m) end
                else
                    table.insert(list, m)
                end
            end
        end
    end
    return list
end

-- =====================================================
-- KILL ALL LOGIC
-- =====================================================
_G.KillAllSettings = { FireRateDelay = 0.04, TargetPart = "Head", PanicHealthThreshold = 40 }
local CurrentShotTargets = {}

local function ExecuteAutomatedSweep()
    if not S.KillAllEnabled then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    local myHum = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
    if not myChar or not myRoot or not myHum or not DeagleController then return end
    
    if typeof(DeagleController) == "table" then
        DeagleController.ShootCooldownUntil = 0
        DeagleController.CanShoot = true
        DeagleController.CurrentSpread = 0
        if DeagleController.WeaponStats then DeagleController.WeaponStats.Spread = 0 end
    end
    
    table.clear(CurrentShotTargets)
    local activePool = GetTargets("All")
    local enemies = {}
    for _, char in ipairs(activePool) do
        if IsEnemy(char) and IsAlive(char) then table.insert(enemies, char) end
    end

    for _, child in ipairs(enemies) do
        local targetPart = child:FindFirstChild(_G.KillAllSettings.TargetPart) or child:FindFirstChild("Head")
        if targetPart then
            CurrentShotTargets[targetPart] = true
            local aimPosition = GetPredictedPosition(targetPart)
            pcall(function()
                if typeof(DeagleController.Shoot) == "function" then DeagleController.Shoot(aimPosition)
                elseif typeof(DeagleController.Fire) == "function" then DeagleController.Fire(aimPosition) end
            end)
        end
    end
end

if DeagleShared and DeagleShared.Raycast then
    local oldRaycast = DeagleShared.Raycast
    DeagleShared.Raycast = function(p1, p2, p3, ...)
        if S.KillAllEnabled then
            for targetPart, _ in pairs(CurrentShotTargets) do
                if targetPart and targetPart.Parent and IsAlive(targetPart.Parent) then
                    return { Instance = targetPart, Position = GetPredictedPosition(targetPart), Normal = Vector3.new(0, 1, 0), Material = Enum.Material.Plastic }
                end
            end
        end
        return oldRaycast(p1, p2, p3, ...)
    end
end

task.spawn(function()
    while true do
        task.wait(_G.KillAllSettings.FireRateDelay)
        pcall(ExecuteAutomatedSweep)
    end
end)

-- =====================================================
-- AIMBOT & SNAPLINE (FIX: Wallcheck & Independen)
-- =====================================================
local aimTarget = nil
local snapTarget = nil

task.spawn(function()
    while task.wait() do
        local center = Camera.ViewportSize / 2
        local closestAimDist = S.POVRadius
        local closestSnapDist = S.POVRadius
        aimTarget = nil
        snapTarget = nil

        -- Scan semua target
        for _, char in ipairs(GetTargets(S.AimTarget)) do
            if IsEnemy(char) then
                local part = GetTargetPart(char, S.AimPart)
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        
                        -- Logic Aimbot (Wajib Visible)
                        if S.Aimbot and dist < closestAimDist then
                            if not IsWallBlocking(char, part) then
                                closestAimDist = dist
                                aimTarget = part
                            end
                        end
                        
                        -- Logic Snapline (Bisa tembus pandang atau gak, bebas)
                        if S.SnapLine and dist < closestSnapDist then
                            closestSnapDist = dist
                            snapTarget = part
                        end
                    end
                end
            end
        end
        
        -- Eksekusi Aimbot
        if S.Aimbot and aimTarget then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, aimTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / S.AimSmooth)
        end
    end
end)

-- =====================================================
-- DRAWING ESP, POV, & SNAPLINE
-- =====================================================
local Drawing = Drawing
local espCache = {}
local fovCircle, snapLine = nil, nil

if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1 fovCircle.NumSides = 60 fovCircle.Filled = false
    
    snapLine = Drawing.new("Line")
    snapLine.Thickness = 1
end

task.spawn(function()
    while task.wait() do
        local center = Camera.ViewportSize / 2
        
        -- POV
        if fovCircle then
            fovCircle.Position = center
            fovCircle.Radius = S.POVRadius
            fovCircle.Color = S.POVColor
            fovCircle.Visible = S.ShowPOV
        end
        
        -- Snapline (FIX: Narik dari snapTarget yang independen)
        if snapLine then
            if S.SnapLine and snapTarget then
                local pos, onScreen = Camera:WorldToViewportPoint(snapTarget.Position)
                if onScreen then
                    snapLine.From = center
                    snapLine.To = Vector2.new(pos.X, pos.Y)
                    snapLine.Color = S.SnapLineColor
                    snapLine.Visible = true
                else snapLine.Visible = false end
            else snapLine.Visible = false end
        end

        -- ESP Box (FIX: Pake HumanoidRootPart & Head)
        local active = {}
        local allTargets = GetTargets("All")
        
        for _, char in ipairs(allTargets) do
            if IsAlive(char) then
                local isBot = char:GetAttribute("IsBot") == true
                local isEnemy = IsEnemy(char)
                
                local showBox = false
                local boxColor = Color3.new(1,1,1)
                
                if isBot then
                    showBox = (isEnemy and S.ESPBotEnemy) or (not isEnemy and S.ESPBotTeam)
                    boxColor = isEnemy and S.ColorBotEnemy or S.ColorBotTeam
                else
                    showBox = (isEnemy and S.ESPPlayerEnemy) or (not isEnemy and S.ESPPlayerTeam)
                    boxColor = isEnemy and S.ColorPlayerEnemy or S.ColorPlayerTeam
                end
                
                if showBox or S.ESPName or S.ESPHealth then
                    active[char] = true
                    if not espCache[char] then
                        espCache[char] = {
                            Box = Drawing.new("Square"),
                            Name = Drawing.new("Text"),
                            HealthBg = Drawing.new("Square"),
                            HealthBar = Drawing.new("Square")
                        }
                        espCache[char].Box.Thickness = 1
                        espCache[char].Box.Filled = false
                        espCache[char].Name.Size = 14
                        espCache[char].Name.Center = true
                        espCache[char].Name.Outline = true
                    end
                    
                    local o = espCache[char]
                    local head = char:FindFirstChild("Head")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    
                    if head and hrp and hum then
                        -- FIX: Kalkulasi Box pake perbandingan titik teratas (Head) dan terbawah (HRP)
                        local topPos, onScreen1 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local bottomPos, onScreen2 = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
                        
                        if onScreen1 and onScreen2 and topPos.Z > 0 then
                            local h = math.abs(bottomPos.Y - topPos.Y)
                            local w = h * 0.45 -- Lebar proporsional
                            local x = topPos.X - w / 2
                            local y = topPos.Y
                            
                            if showBox then
                                o.Box.Visible = true 
                                o.Box.Size = Vector2.new(w, h) 
                                o.Box.Position = Vector2.new(x, y)
                                o.Box.Color = boxColor
                            else o.Box.Visible = false end
                            
                            if S.ESPName then
                                local pName = isBot and "[BOT] " .. char.Name or char.Name
                                o.Name.Visible = true o.Name.Text = pName o.Name.Position = Vector2.new(topPos.X, y - 18) o.Name.Color = S.ColorName
                            else o.Name.Visible = false end
                            
                            if S.ESPHealth then
                                local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                local bw = 2
                                local bh = h * pct
                                local bx = x - bw - 3
                                o.HealthBg.Visible = true o.HealthBg.Size = Vector2.new(bw, h) o.HealthBg.Position = Vector2.new(bx, y)
                                o.HealthBar.Visible = true o.HealthBar.Size = Vector2.new(bw, bh) o.HealthBar.Position = Vector2.new(bx, y + (h - bh)) o.HealthBar.Color = S.ColorHealth
                            else o.HealthBg.Visible = false o.HealthBar.Visible = false end
                        else
                            o.Box.Visible = false o.Name.Visible = false o.HealthBg.Visible = false o.HealthBar.Visible = false
                        end
                    end
                end
            end
        end
        
        for char, o in pairs(espCache) do
            if not active[char] then
                pcall(function() o.Box:Remove() end) pcall(function() o.Name:Remove() end)
                pcall(function() o.HealthBg:Remove() end) pcall(function() o.HealthBar:Remove() end)
                espCache[char] = nil
            end
        end
    end
end)

-- =====================================================
-- PLAYER, HITBOX, & BRING
-- =====================================================
task.spawn(function()
    while task.wait(0.2) do
        if S.Hitbox then
            for _, char in ipairs(GetTargets("All")) do
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and IsEnemy(char) then
                    hrp.Size = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
                    hrp.Transparency = 0.5 hrp.CanCollide = false
                end
            end
        end
        
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = S.SpeedHack and S.SpeedValue or 16
                hum.UseJumpPower = true
                hum.JumpPower = S.JumpHack and S.JumpValue or 50
            end
            if S.NoClip then
                for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if S.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if S.BringEnemy then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local targetsToBring = GetTargets(S.BringTarget)
                for _, char in ipairs(targetsToBring) do
                    if IsEnemy(char) then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local targetCFrame = myRoot.CFrame * CFrame.new(0, 0, -S.BringStuds)
                            targetCFrame = CFrame.new(targetCFrame.Position, myRoot.Position)
                            hrp.CFrame = targetCFrame
                            if S.BringType == "SingleEnemy" then break end
                        end
                    end
                end
            end
        end
    end
end)

-- =====================================================
-- UI SETUP (RAYFIELD)
-- =====================================================
local Window = Rayfield:CreateWindow({
    Name = "RENXX Hub v10.3 | Ultimate",
    LoadingTitle = "RENXX Hub",
    LoadingSubtitle = "by Ren & Deep",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

local Visual = Window:CreateTab("Visual", 4483345998)
Visual:CreateSection("PLAYER ESP")
Visual:CreateToggle({Name = "ESP Box Player Enemy", CurrentValue = true, Flag = "EPE", Callback = function(v) S.ESPPlayerEnemy = v end})
Visual:CreateColorPicker({Name = "Color Player Enemy", Color = Color3.fromRGB(255, 50, 50), Flag = "EPEC", Callback = function(c) S.ColorPlayerEnemy = c end})
Visual:CreateToggle({Name = "ESP Box Player Team", CurrentValue = false, Flag = "EPT", Callback = function(v) S.ESPPlayerTeam = v end})
Visual:CreateColorPicker({Name = "Color Player Team", Color = Color3.fromRGB(50, 255, 50), Flag = "EPTC", Callback = function(c) S.ColorPlayerTeam = c end})

Visual:CreateSection("BOT ESP")
Visual:CreateToggle({Name = "ESP Box Bot Enemy", CurrentValue = true, Flag = "EBE", Callback = function(v) S.ESPBotEnemy = v end})
Visual:CreateColorPicker({Name = "Color Bot Enemy", Color = Color3.fromRGB(255, 165, 0), Flag = "EBEC", Callback = function(c) S.ColorBotEnemy = c end})
Visual:CreateToggle({Name = "ESP Box Bot Team", CurrentValue = false, Flag = "EBT", Callback = function(v) S.ESPBotTeam = v end})
Visual:CreateColorPicker({Name = "Color Bot Team", Color = Color3.fromRGB(0, 255, 255), Flag = "EBTC", Callback = function(c) S.ColorBotTeam = c end})

Visual:CreateSection("GLOBAL ESP")
Visual:CreateToggle({Name = "ESP Name", CurrentValue = true, Flag = "EN", Callback = function(v) S.ESPName = v end})
Visual:CreateColorPicker({Name = "ESP Name Color", Color = Color3.fromRGB(255, 255, 255), Flag = "ENC", Callback = function(c) S.ColorName = c end})
Visual:CreateToggle({Name = "ESP Health Bar", CurrentValue = true, Flag = "EH", Callback = function(v) S.ESPHealth = v end})
Visual:CreateColorPicker({Name = "ESP Health Bar Color", Color = Color3.fromRGB(0, 255, 0), Flag = "EHC", Callback = function(c) S.ColorHealth = c end})

local Combat = Window:CreateTab("Combat", 4483345998)
Combat:CreateSection("AIMBOT")
Combat:CreateToggle({Name = "Aimbot (Camera Lock)", CurrentValue = false, Flag = "AB", Callback = function(v) S.Aimbot = v end})
Combat:CreateSlider({Name = "Aim Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = 3, Flag = "ABS", Callback = function(v) S.AimSmooth = v end})
Combat:CreateDropdown({Name = "Aim Target", Options = {"All", "PlayerOnly", "BotOnly"}, CurrentOption = "All", Flag = "ABT", Callback = function(v) S.AimTarget = v end})
Combat:CreateDropdown({Name = "Aim Part", Options = {"Head", "Body", "Foot"}, CurrentOption = "Head", Flag = "ABP", Callback = function(v) S.AimPart = v end})

Combat:CreateSection("POV & SNAPLINE")
Combat:CreateToggle({Name = "Show POV Circle", CurrentValue = true, Flag = "SPOV", Callback = function(v) S.ShowPOV = v end})
Combat:CreateSlider({Name = "POV Radius", Range = {10, 400}, Increment = 1, CurrentValue = 150, Flag = "POVR", Callback = function(v) S.POVRadius = v end})
Combat:CreateColorPicker({Name = "POV Color", Color = Color3.fromRGB(255, 0, 0), Flag = "POVC", Callback = function(c) S.POVColor = c end})
Combat:CreateToggle({Name = "SnapLine", CurrentValue = true, Flag = "SL", Callback = function(v) S.SnapLine = v end})
Combat:CreateColorPicker({Name = "SnapLine Color", Color = Color3.fromRGB(255, 50, 50), Flag = "SLC", Callback = function(c) S.SnapLineColor = c end})

Combat:CreateSection("SETTINGS")
Combat:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "TC", Callback = function(v) S.TeamCheck = v end})
Combat:CreateToggle({Name = "Wall Check", CurrentValue = true, Flag = "WC", Callback = function(v) S.WallCheck = v end})
Combat:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Flag = "HB", Callback = function(v) S.Hitbox = v end})
Combat:CreateSlider({Name = "Hitbox Size", Range = {2, 20}, Increment = 1, CurrentValue = 5, Flag = "HBS", Callback = function(v) S.HitboxSize = v end})

local PlayerTab = Window:CreateTab("Player", 4483345998)
PlayerTab:CreateSection("MOVEMENT")
PlayerTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Flag = "SH", Callback = function(v) S.SpeedHack = v end})
PlayerTab:CreateSlider({Name = "Speed Value", Range = {16, 100}, Increment = 1, CurrentValue = 32, Flag = "SV", Callback = function(v) S.SpeedValue = v end})
PlayerTab:CreateToggle({Name = "Jump Hack", CurrentValue = false, Flag = "JH", Callback = function(v) S.JumpHack = v end})
PlayerTab:CreateSlider({Name = "Jump Value", Range = {50, 150}, Increment = 1, CurrentValue = 50, Flag = "JV", Callback = function(v) S.JumpValue = v end})
PlayerTab:CreateToggle({Name = "Infinity Jump", CurrentValue = false, Flag = "IJ", Callback = function(v) S.InfJump = v end})
PlayerTab:CreateToggle({Name = "No Clip", CurrentValue = false, Flag = "NC", Callback = function(v) S.NoClip = v end})

local Farm = Window:CreateTab("Farm", 4483345998)
Farm:CreateSection("KILL ALL")
Farm:CreateToggle({Name = "Kill All (Auto Sweep)", CurrentValue = false, Flag = "KA", Callback = function(v) S.KillAllEnabled = v; if v then DebugWarn("KILL ALL ON!") end end})
Farm:CreateSlider({Name = "Fire Rate Delay", Range = {0.01, 0.5}, Increment = 0.01, Suffix = "s", CurrentValue = 0.04, Flag = "KAD", Callback = function(v) _G.KillAllSettings.FireRateDelay = v end})
Farm:CreateDropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart", "UpperTorso"}, CurrentOption = "Head", Flag = "KAT", Callback = function(v) _G.KillAllSettings.TargetPart = v end})

Farm:CreateSection("BRING ENEMY")
Farm:CreateToggle({Name = "Bring Enemy (Tarik Musuh)", CurrentValue = false, Flag = "BE", Callback = function(v) S.BringEnemy = v; if v then DebugWarn("Bring Enemy ON!") end end})
Farm:CreateDropdown({Name = "Bring Type", Options = {"SingleEnemy", "AllEnemy"}, CurrentOption = "SingleEnemy", Flag = "BT", Callback = function(v) S.BringType = v end})
Farm:CreateDropdown({Name = "Bring Target", Options = {"All", "PlayerEnemy", "BotEnemy"}, CurrentOption = "All", Flag = "BTG", Callback = function(v) S.BringTarget = v end})
Farm:CreateSlider({Name = "Bring Studs (Jarak)", Range = {1, 50}, Increment = 1, CurrentValue = 5, Flag = "BS", Callback = function(v) S.BringStuds = v end})

Rayfield:Notify({Title = "RENXX Hub v10.3", Content = "Bug Fixed! ESP & Aimbot presisi.", Duration = 8, Image = 4483362458})
DebugOK("RENXX HUB v10.3 | SIAP!")
