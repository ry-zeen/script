-- =====================================================
--  RENXX HUB v8.1 | DEAGLE ARENA CUSTOM
--  Fitur: Visual ESP, Combat, Player, Farm (Kill All + Bring)
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
local function DebugErr(msg) DebugMsg(msg, Color3.fromRGB(255, 100, 100)) end

DebugOK("Loading RENXX Hub v8.1...")

local successRay, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not successRay or not Rayfield then DebugErr("Gagal load Rayfield!") return end
DebugOK("Rayfield berhasil di-load.")

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
    -- Visual ESP
    ESPPlayerEnemy = true, ColorPlayerEnemy = Color3.fromRGB(255, 50, 50),
    ESPPlayerTeam = false, ColorPlayerTeam = Color3.fromRGB(50, 255, 50),
    ESPBotEnemy = true, ColorBotEnemy = Color3.fromRGB(255, 165, 0),
    ESPBotTeam = false, ColorBotTeam = Color3.fromRGB(0, 255, 255),
    ESPName = true, ColorESPName = Color3.fromRGB(255, 255, 255),
    ESPHealth = true, ColorESPHealth = Color3.fromRGB(0, 255, 0),
    
    -- Combat (Aimbot & POV)
    Aimbot = false, AimSmooth = 3, AimTarget = "All", AimPart = "Head",
    ShowPOV = true, POVColor = Color3.fromRGB(255, 0, 0), POVRadius = 150,
    SnapLine = true, SnapLineColor = Color3.fromRGB(255, 50, 50),
    TeamCheck = true, WallCheck = true,
    Hitbox = false, HitboxSize = 5,
    
    -- Player
    SpeedHack = false, SpeedValue = 32,
    JumpHack = false, JumpValue = 50,
    InfJump = false, NoClip = false,
    
    -- Farm
    KillAll = false, KillAllDelay = 0.04,
    BringEnemy = false, BringType = "All Enemy", BringTarget = "All", BringStuds = 5, BringDelay = 0.5
}
local S = getgenv().RENXX.S

-- =====================================================
-- CORE REFERENCES
-- =====================================================
local DeagleController = nil
pcall(function()
    local PS = LocalPlayer:WaitForChild("PlayerScripts", 10)
    if PS then
        local ML = PS:WaitForChild("ModuleLoader", 10)
        if ML then
            DeagleController = require(ML:WaitForChild("DeagleController", 10))
            DebugOK("DeagleController: BERHASIL!")
        end
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

local function IsEnemy(plr)
    if not S.TeamCheck then return true end
    local myChar = LocalPlayer.Character
    local mt = myChar and myChar:GetAttribute("GamemodeTeam")
    local tt = plr.Character and plr.Character:GetAttribute("GamemodeTeam")
    if mt and tt then return mt ~= tt end
    if LocalPlayer.Team and plr.Team then return LocalPlayer.Team ~= plr.Team end
    return true
end

local function IsVisible(origin, part, char)
    if not S.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    local res = workspace:Raycast(origin, part.Position - origin, params)
    return res == nil or res.Instance:IsDescendantOf(char)
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

-- =====================================================
-- GET TARGETS (Untuk Semua Fitur)
-- =====================================================
local function GetTargets()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
            if S.BringTarget == "All" or S.BringTarget == "PlayerEnemy" or S.BringTarget == "All Enemy" then
                if IsEnemy(p) then table.insert(list, p.Character) end
            end
        end
    end
    -- Bot Logic (Kalo ada)
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("IsBot") == true and IsAlive(m) then
            if S.BringTarget == "All" or S.BringTarget == "BotEnemy" or S.BringTarget == "All Enemy" then
                table.insert(list, m)
            end
        end
    end
    return list
end

-- =====================================================
-- KILL ALL LOGIC (Dipindah ke Farm)
-- =====================================================
task.spawn(function()
    while task.wait(S.KillAllDelay) do
        if S.KillAll and DeagleController then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if myRoot then
                for _, char in ipairs(GetTargets()) do
                    local part = GetTargetPart(char, "Head")
                    if part then
                        if typeof(DeagleController) == "table" then
                            DeagleController.CanShoot = true
                            DeagleController.ShootCooldownUntil = 0
                            pcall(function()
                                DeagleController.Shoot(GetPredictedPosition(part))
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- =====================================================
-- AIMBOT & POV & SNAPLINE LOOP
-- =====================================================
local currentTarget = nil
task.spawn(function()
    while task.wait() do
        if S.Aimbot then
            local best, bestDist = nil, S.POVRadius
            local center = Camera.ViewportSize / 2
            
            for _, char in ipairs(GetTargets()) do
                local part = GetTargetPart(char, S.AimPart)
                if part and IsVisible(Camera.CFrame.Position, part, char) then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            best = part
                        end
                    end
                end
            end
            
            currentTarget = best
            if currentTarget then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, currentTarget.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / S.AimSmooth)
            end
        else
            currentTarget = nil
        end
    end
end)

-- =====================================================
-- DRAWING ESP (VISUAL)
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

local function CreateESP()
    local o = {}
    o.Box = Drawing.new("Square") o.Box.Thickness = 1 o.Box.Filled = false o.Box.Visible = false
    o.Name = Drawing.new("Text") o.Name.Size = 14 o.Name.Center = true o.Name.Outline = true o.Name.OutlineColor = Color3.new(0,0,0) o.Name.Visible = false
    o.HealthBg = Drawing.new("Square") o.HealthBg.Filled = true o.HealthBg.Color = Color3.new(0,0,0) o.HealthBg.Transparency = 0.5 o.HealthBg.Visible = false
    o.HealthBar = Drawing.new("Square") o.HealthBar.Filled = true o.HealthBar.Transparency = 0.2 o.HealthBar.Visible = false
    return o
end

task.spawn(function()
    while task.wait() do
        -- Update POV & Snapline
        if fovCircle then
            fovCircle.Position = Camera.ViewportSize / 2
            fovCircle.Radius = S.POVRadius
            fovCircle.Color = S.POVColor
            fovCircle.Visible = S.ShowPOV
        end
        if snapLine then
            if S.SnapLine and currentTarget then
                local pos, onScreen = Camera:WorldToViewportPoint(currentTarget.Position)
                if onScreen then
                    snapLine.From = Camera.ViewportSize / 2
                    snapLine.To = Vector2.new(pos.X, pos.Y)
                    snapLine.Color = S.SnapLineColor
                    snapLine.Visible = true
                else snapLine.Visible = false end
            else snapLine.Visible = false end
        end

        -- Update ESP
        local active = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
                local char = p.Character
                local isEnemy = IsEnemy(p)
                local showBox = (isEnemy and S.ESPPlayerEnemy) or (not isEnemy and S.ESPPlayerTeam)
                local boxColor = (isEnemy and S.ColorPlayerEnemy) or (not isEnemy and S.ColorPlayerTeam)
                
                if showBox or S.ESPName or S.ESPHealth then
                    active[char] = true
                    if not espCache[char] then espCache[char] = CreateESP() end
                    local o = espCache[char]
                    
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local head = char:FindFirstChild("Head")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    
                    if hrp and head and hum then
                        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                        
                        if onScreen and headOnScreen and pos.Z > 0 then
                            local h = math.abs(headPos.Y - pos.Y)
                            local w = h * 0.5
                            local x = pos.X - w / 2
                            local y = headPos.Y
                            
                            -- Box
                            if showBox then
                                o.Box.Visible = true o.Box.Size = Vector2.new(w, h) o.Box.Position = Vector2.new(x, y) o.Box.Color = boxColor
                            else o.Box.Visible = false end
                            
                            -- Name
                            if S.ESPName then
                                o.Name.Visible = true o.Name.Text = p.Name o.Name.Position = Vector2.new(pos.X, y - 18) o.Name.Color = S.ColorESPName
                            else o.Name.Visible = false end
                            
                            -- Health
                            if S.ESPHealth then
                                local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                local bw = 3
                                local bh = h * pct
                                local bx = x - bw - 4
                                o.HealthBg.Visible = true o.HealthBg.Size = Vector2.new(bw, h) o.HealthBg.Position = Vector2.new(bx, y)
                                o.HealthBar.Visible = true o.HealthBar.Size = Vector2.new(bw, bh) o.HealthBar.Position = Vector2.new(bx, y + (h - bh)) o.HealthBar.Color = S.ColorESPHealth
                            else o.HealthBg.Visible = false o.HealthBar.Visible = false end
                        else
                            o.Box.Visible = false o.Name.Visible = false o.HealthBg.Visible = false o.HealthBar.Visible = false
                        end
                    end
                end
            end
        end
        
        -- Cleanup
        for char, o in pairs(espCache) do
            if not active[char] then
                pcall(function() o.Box:Remove() end)
                pcall(function() o.Name:Remove() end)
                pcall(function() o.HealthBg:Remove() end)
                pcall(function() o.HealthBar:Remove() end)
                espCache[char] = nil
            end
        end
    end
end)

-- =====================================================
-- HITBOX & MOVEMENT & BRING ENEMY
-- =====================================================
task.spawn(function()
    while task.wait(0.2) do
        -- Hitbox
        if S.Hitbox then
            for _, char in ipairs(GetTargets()) do
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
                    hrp.Transparency = 0.5 hrp.CanCollide = false
                end
            end
        end
        
        -- Movement
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
    while task.wait(S.BringDelay) do
        if S.BringEnemy then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                for _, char in ipairs(GetTargets()) do
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
end)

-- =====================================================
-- UI SETUP (RAYFIELD)
-- =====================================================
local Window = Rayfield:CreateWindow({
    Name = "RENXX Hub v8.1 | Deagle Arena",
    LoadingTitle = "RENXX Hub",
    LoadingSubtitle = "by Ren & Deep",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

-- ============ TAB 1: VISUAL ============
local Visual = Window:CreateTab("Visual", 4483345998)
Visual:CreateSection("PLAYER ENEMY")
Visual:CreateToggle({Name = "ESP Box Player Enemy", CurrentValue = true, Flag = "EPE", Callback = function(v) S.ESPPlayerEnemy = v end})
Visual:CreateColorPicker({Name = "Box Player Enemy Color", Color = Color3.fromRGB(255, 50, 50), Flag = "EPEC", Callback = function(c) S.ColorPlayerEnemy = c end})

Visual:CreateSection("PLAYER TEAM")
Visual:CreateToggle({Name = "ESP Box Player Team", CurrentValue = false, Flag = "EPT", Callback = function(v) S.ESPPlayerTeam = v end})
Visual:CreateColorPicker({Name = "Box Player Team Color", Color = Color3.fromRGB(50, 255, 50), Flag = "EPTC", Callback = function(c) S.ColorPlayerTeam = c end})

Visual:CreateSection("BOT ENEMY")
Visual:CreateToggle({Name = "ESP Box Bot Enemy", CurrentValue = true, Flag = "EBE", Callback = function(v) S.ESPBotEnemy = v end})
Visual:CreateColorPicker({Name = "Box Bot Enemy Color", Color = Color3.fromRGB(255, 165, 0), Flag = "EBEC", Callback = function(c) S.ColorBotEnemy = c end})

Visual:CreateSection("BOT TEAM")
Visual:CreateToggle({Name = "ESP Box Bot Team", CurrentValue = false, Flag = "EBT", Callback = function(v) S.ESPBotTeam = v end})
Visual:CreateColorPicker({Name = "Box Bot Team Color", Color = Color3.fromRGB(0, 255, 255), Flag = "EBTC", Callback = function(c) S.ColorBotTeam = c end})

Visual:CreateSection("GLOBAL ESP")
Visual:CreateToggle({Name = "ESP Name", CurrentValue = true, Flag = "EN", Callback = function(v) S.ESPName = v end})
Visual:CreateColorPicker({Name = "ESP Name Color", Color = Color3.fromRGB(255, 255, 255), Flag = "ENC", Callback = function(c) S.ColorESPName = c end})
Visual:CreateToggle({Name = "ESP Health Bar", CurrentValue = true, Flag = "EH", Callback = function(v) S.ESPHealth = v end})
Visual:CreateColorPicker({Name = "ESP Health Bar Color", Color = Color3.fromRGB(0, 255, 0), Flag = "EHC", Callback = function(c) S.ColorESPHealth = c end})

-- ============ TAB 2: COMBAT ============
local Combat = Window:CreateTab("Combat", 4483345998)
Combat:CreateSection("AIMBOT")
Combat:CreateToggle({Name = "Aimbot (Camera Lock)", CurrentValue = false, Flag = "AB", Callback = function(v) S.Aimbot = v end})
Combat:CreateSlider({Name = "Aim Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = 3, Flag = "ABS", Callback = function(v) S.AimSmooth = v end})
Combat:CreateDropdown({Name = "Aim Target", Options = {"All", "PlayerOnly", "BotOnly"}, CurrentOption = "All", Flag = "ABT", Callback = function(v) S.BringTarget = v end})
Combat:CreateDropdown({Name = "Aim Part", Options = {"Head", "Body", "Foot"}, CurrentOption = "Head", Flag = "ABP", Callback = function(v) S.AimPart = v end})

Combat:CreateSection("POV VISUALS")
Combat:CreateToggle({Name = "Show POV Circle", CurrentValue = true, Flag = "SPOV", Callback = function(v) S.ShowPOV = v end})
Combat:CreateSlider({Name = "POV Radius", Range = {10, 400}, Increment = 1, CurrentValue = 150, Flag = "POVR", Callback = function(v) S.POVRadius = v end})
Combat:CreateColorPicker({Name = "POV Color", Color = Color3.fromRGB(255, 0, 0), Flag = "POVC", Callback = function(c) S.POVColor = c end})
Combat:CreateToggle({Name = "SnapLine (Crosshair to Enemy)", CurrentValue = true, Flag = "SL", Callback = function(v) S.SnapLine = v end})
Combat:CreateColorPicker({Name = "SnapLine Color", Color = Color3.fromRGB(255, 50, 50), Flag = "SLC", Callback = function(c) S.SnapLineColor = c end})

Combat:CreateSection("SETTINGS")
Combat:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "TC", Callback = function(v) S.TeamCheck = v end})
Combat:CreateToggle({Name = "Wall Check", CurrentValue = true, Flag = "WC", Callback = function(v) S.WallCheck = v end})
Combat:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Flag = "HB", Callback = function(v) S.Hitbox = v end})
Combat:CreateSlider({Name = "Hitbox Size", Range = {2, 20}, Increment = 1, CurrentValue = 5, Flag = "HBS", Callback = function(v) S.HitboxSize = v end})

-- ============ TAB 3: PLAYER ============
local PlayerTab = Window:CreateTab("Player", 4483345998)
PlayerTab:CreateSection("MOVEMENT")
PlayerTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Flag = "SH", Callback = function(v) S.SpeedHack = v end})
PlayerTab:CreateSlider({Name = "Speed Value", Range = {16, 100}, Increment = 1, CurrentValue = 32, Flag = "SV", Callback = function(v) S.SpeedValue = v end})
PlayerTab:CreateToggle({Name = "Jump Hack", CurrentValue = false, Flag = "JH", Callback = function(v) S.JumpHack = v end})
PlayerTab:CreateSlider({Name = "Jump Value", Range = {50, 150}, Increment = 1, CurrentValue = 50, Flag = "JV", Callback = function(v) S.JumpValue = v end})
PlayerTab:CreateToggle({Name = "Infinity Jump", CurrentValue = false, Flag = "IJ", Callback = function(v) S.InfJump = v end})
PlayerTab:CreateToggle({Name = "No Clip", CurrentValue = false, Flag = "NC", Callback = function(v) S.NoClip = v end})

-- ============ TAB 4: FARM ============
local Farm = Window:CreateTab("Farm", 4483345998)

Farm:CreateSection("KILL ALL")
Farm:CreateToggle({Name = "Kill All (Auto Sweep)", CurrentValue = false, Flag = "KA", Callback = function(v) S.KillAll = v; if v then DebugWarn("KILL ALL ON!") end end})
Farm:CreateSlider({Name = "Kill All Delay", Range = {0.01, 0.5}, Increment = 0.01, Suffix = "s", CurrentValue = 0.04, Flag = "KAD", Callback = function(v) S.KillAllDelay = v end})

Farm:CreateSection("BRING ENEMY")
Farm:CreateToggle({Name = "Bring Enemy (Tarik Musuh)", CurrentValue = false, Flag = "BE", Callback = function(v) S.BringEnemy = v; if v then DebugWarn("Bring Enemy ON!") end end})
Farm:CreateDropdown({Name = "Bring Type", Options = {"SingleEnemy", "AllEnemy"}, CurrentOption = "SingleEnemy", Flag = "BT", Callback = function(v) S.BringType = v end})
Farm:CreateDropdown({Name = "Bring Target", Options = {"All", "PlayerEnemy", "BotEnemy"}, CurrentOption = "All", Flag = "BTG", Callback = function(v) S.BringTarget = v end})
Farm:CreateSlider({Name = "Bring Studs (Jarak)", Range = {1, 50}, Increment = 1, CurrentValue = 5, Flag = "BS", Callback = function(v) S.BringStuds = v end})
Farm:CreateSlider({Name = "Bring Delay", Range = {0.1, 5}, Increment = 0.1, Suffix = "s", CurrentValue = 0.5, Flag = "BD", Callback = function(v) S.BringDelay = v end})

-- =====================================================
-- NOTIFIKASI
-- =====================================================
Rayfield:Notify({
    Title = "RENXX Hub v8.1",
    Content = "Visual ESP & Farm (Kill All + Bring) siap!",
    Duration = 8,
    Image = 4483362458,
})

DebugOK("====================================")
DebugOK("  RENXX HUB v8.1 | CUSTOM BUILD")
DebugOK("  Status: LOADED & READY")
DebugOK("====================================")
