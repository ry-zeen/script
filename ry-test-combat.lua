-- ═══════════════════════════════════════════════════════
-- RENXX v6.1 | COMBAT ARENA EDITION
-- By: Ren & Deep | Powered by Orion UI (Qanuir)
-- ═══════════════════════════════════════════════════════

-- ═══ LOAD ORION ═══
local success, Orion = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()
end)

if not success or not Orion then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "RENXX v6.1",
        Text = "Gagal load Orion UI. Cek koneksi atau ganti executor!",
        Duration = 5
    })
    return
end

local Library = Orion
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ═══ CLEANUP OLD ═══
pcall(function()
    if Library and Library.Unload then Library:Unload() end
end)

-- ═══ CONFIG ═══
local Config = {
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(255, 50, 50),
    ESPTeamCheck = true,
    ESPName = true,
    Fullbright = false,
    AimbotEnabled = false,
    AimPart = "Head",
    AimSmooth = 0.3,
    AimFOV = 500,
    AimTeamCheck = true,
    SpeedEnabled = false,
    SpeedValue = 60,
    JumpEnabled = false,
    JumpValue = 100,
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    DamageBoost = false,
    DamageMultiplier = 5,
    FreezeNPC = false,
}

-- ═══ HELPER: GET NPC FOLDERS ═══
local function getNPCFolders()
    local folders = {}
    for _, name in ipairs({"CombatantNPCs", "NPCS", "NPCs", "Bots", "Enemies"}) do
        local f = Workspace:FindFirstChild(name)
        if f then table.insert(folders, f) end
    end
    return folders
end

-- ═══ WINDOW ═══
local Window = Library:MakeWindow({
    Name = "RENXX v6.1 | Combat Arena",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "RENXX"
})

Library:MakeNotification({
    Name = "RENXX v6.1",
    Content = "Script loaded! Selamat main bang!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- ═══ ESP SYSTEM (OPTIMIZED) ═══
local espHighlights = {}
local espNames = {}
local lastESPUpdate = 0

local function clearESP()
    for _, h in pairs(espHighlights) do
        pcall(function() h:Destroy() end)
    end
    for _, n in pairs(espNames) do
        pcall(function() n:Destroy() end)
    end
    espHighlights = {}
    espNames = {}
end

local function updateESP()
    if not Config.ESPEnabled then
        if next(espHighlights) then clearESP() end
        return
    end

    local function addHighlight(model, isPlayer)
        if not model or not model.Parent then return end
        if not model:FindFirstChildOfClass("Humanoid") then return end
        if espHighlights[model] then return end

        pcall(function()
            local highlight = Instance.new("Highlight")
            highlight.Adornee = model
            highlight.FillColor = Config.ESPColor
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = isPlayer and 0.5 or 0.3
            highlight.OutlineTransparency = 0
            highlight.Parent = game:GetService("CoreGui")
            espHighlights[model] = highlight

            if Config.ESPName then
                local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
                if head then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Adornee = head
                    billboard.Size = UDim2.new(0, 150, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = game:GetService("CoreGui")

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = model.Name
                    label.TextColor3 = Config.ESPColor
                    label.TextStrokeTransparency = 0
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 13
                    label.Parent = billboard
                    espNames[model] = billboard
                end
            end
        end)
    end

    -- Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local skip = false
            if Config.ESPTeamCheck and p.Team and LP.Team and p.Team == LP.Team then
                skip = true
            end
            if not skip then addHighlight(p.Character, true) end
        end
    end

    -- NPCs
    for _, folder in ipairs(getNPCFolders()) do
        for _, npc in ipairs(folder:GetChildren()) do
            addHighlight(npc, false)
        end
    end
end

-- ═══ AIMBOT ═══
local function getClosestTarget()
    local closest = nil
    local shortestDist = Config.AimFOV

    local function checkTarget(model)
        if not model or not model.Parent then return end
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local part = model:FindFirstChild(Config.AimPart) or model:FindFirstChild("HumanoidRootPart")
        if not part then return end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closest = part
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local skip = false
            if Config.AimTeamCheck and p.Team and LP.Team and p.Team == LP.Team then
                skip = true
            end
            if not skip then checkTarget(p.Character) end
        end
    end

    for _, folder in ipairs(getNPCFolders()) do
        for _, npc in ipairs(folder:GetChildren()) do
            checkTarget(npc)
        end
    end

    return closest
end

-- ═══ WEAPON PATCHER (AMAN) ═══
local function patchWeapons()
    if not getgc then return end
    if not (Config.NoRecoil or Config.NoSpread or Config.RapidFire or Config.DamageBoost) then return end

    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                local hasFireRate = rawget(obj, "FireRate")
                local hasSpread = rawget(obj, "Spread")
                if hasFireRate and hasSpread then
                    if Config.NoRecoil then
                        pcall(function()
                            rawset(obj, "VerticalRecoil", 0)
                            rawset(obj, "HorizontalRecoil", 0)
                            rawset(obj, "KickUpForce", 0)
                            rawset(obj, "PushbackForce", 0)
                        end)
                    end
                    if Config.NoSpread then
                        pcall(function()
                            rawset(obj, "Spread", Vector2.new(0, 0))
                            rawset(obj, "AimSpread", Vector2.new(0, 0))
                        end)
                    end
                    if Config.RapidFire then
                        pcall(function() rawset(obj, "FireRate", 99999) end)
                    end
                    if Config.DamageBoost then
                        pcall(function()
                            local baseDmg = rawget(obj, "BaseDamage")
                            if typeof(baseDmg) == "Vector2" then
                                rawset(obj, "BaseDamage", Vector2.new(
                                    baseDmg.X * Config.DamageMultiplier,
                                    baseDmg.Y * Config.DamageMultiplier
                                ))
                            end
                            local headDmg = rawget(obj, "HeadshotDamage")
                            if typeof(headDmg) == "Vector2" then
                                rawset(obj, "HeadshotDamage", Vector2.new(
                                    headDmg.X * Config.DamageMultiplier,
                                    headDmg.Y * Config.DamageMultiplier
                                ))
                            end
                        end)
                    end
                end
            end
        end
    end)
end

-- ═══ FLY VARIABLE ═══
local flyVelocity = nil

-- ═══ MAIN LOOP ═══
RunService.RenderStepped:Connect(function(dt)
    -- Aimbot
    if Config.AimbotEnabled then
        local target = getClosestTarget()
        if target then
            local targetCF = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, Config.AimSmooth)
        end
    end

    -- ESP (update tiap 0.5 detik biar ringan)
    local now = tick()
    if now - lastESPUpdate > 0.5 then
        lastESPUpdate = now
        updateESP()
    end

    -- Player Movement
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Config.SpeedEnabled and Config.SpeedValue or 16
            hum.JumpPower = Config.JumpEnabled and Config.JumpValue or 50
            hum.UseJumpPower = true
        end

        -- Noclip
        if Config.NoclipEnabled then
            for _, v in ipairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end

        -- Fly
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if Config.FlyEnabled and hrp then
            if not flyVelocity or not flyVelocity.Parent then
                if flyVelocity then pcall(function() flyVelocity:Destroy() end) end
                flyVelocity = Instance.new("BodyVelocity")
                flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                flyVelocity.Velocity = Vector3.new(0, 0, 0)
                flyVelocity.Parent = hrp
            end

            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            flyVelocity.Velocity = moveDir * Config.FlySpeed
        else
            if flyVelocity then
                pcall(function() flyVelocity:Destroy() end)
                flyVelocity = nil
            end
        end
    end
end)

-- ═══ PATCH LOOP ═══
task.spawn(function()
    while task.wait(1) do
        pcall(patchWeapons)
    end
end)

-- ═══ NPC FREEZE LOOP ═══
task.spawn(function()
    while task.wait(1) do
        if Config.FreezeNPC then
            pcall(function()
                for _, folder in ipairs(getNPCFolders()) do
                    for _, npc in ipairs(folder:GetChildren()) do
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.WalkSpeed = 0
                            hum.JumpPower = 0
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══ TAB: VISUAL ═══
local VisualTab = Window:MakeTab({
    Name = "VISUAL",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

VisualTab:AddSection({Name = "ESP Settings"})

VisualTab:AddToggle({
    Name = "ESP Player & NPC",
    Default = false,
    Save = true,
    Flag = "ESPEnabled",
    Callback = function(state) Config.ESPEnabled = state end
})

VisualTab:AddColorpicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 50, 50),
    Save = true,
    Flag = "ESPColor",
    Callback = function(color)
        Config.ESPColor = color
        for _, h in pairs(espHighlights) do
            pcall(function() h.FillColor = color end)
        end
        for _, n in pairs(espNames) do
            pcall(function()
                local label = n:FindFirstChildOfClass("TextLabel")
                if label then label.TextColor3 = color end
            end)
        end
    end
})

VisualTab:AddToggle({
    Name = "ESP Team Check",
    Default = true,
    Save = true,
    Flag = "ESPTeamCheck",
    Callback = function(state) Config.ESPTeamCheck = state end
})

VisualTab:AddToggle({
    Name = "ESP Name Tag",
    Default = true,
    Save = true,
    Flag = "ESPName",
    Callback = function(state) Config.ESPName = state end
})

VisualTab:AddSection({Name = "Lighting"})

VisualTab:AddToggle({
    Name = "Fullbright",
    Default = false,
    Save = true,
    Flag = "Fullbright",
    Callback = function(state)
        Config.Fullbright = state
        pcall(function()
            if state then
                Lighting.Brightness = 3
                Lighting.ClockTime = 12
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            else
                Lighting.Brightness = 2
                Lighting.FogEnd = 100000
            end
        end)
    end
})

-- ═══ TAB: COMBAT ═══
local CombatTab = Window:MakeTab({
    Name = "COMBAT",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

CombatTab:AddSection({Name = "Aimbot"})

CombatTab:AddToggle({
    Name = "Aimbot Enabled",
    Default = false,
    Save = true,
    Flag = "AimbotEnabled",
    Callback = function(state) Config.AimbotEnabled = state end
})

CombatTab:AddDropdown({
    Name = "Aim Part",
    Default = "Head",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"},
    Save = true,
    Flag = "AimPart",
    Callback = function(option) Config.AimPart = option end
})

CombatTab:AddSlider({
    Name = "Aim Smoothness",
    Min = 1, Max = 10, Default = 3,
    Color = Color3.fromRGB(255, 50, 150),
    Increment = 1,
    ValueName = "x",
    Save = true,
    Flag = "AimSmooth",
    Callback = function(value) Config.AimSmooth = value / 10 end
})

CombatTab:AddSlider({
    Name = "Aim FOV",
    Min = 50, Max = 800, Default = 500,
    Color = Color3.fromRGB(255, 50, 150),
    Increment = 10,
    ValueName = "px",
    Save = true,
    Flag = "AimFOV",
    Callback = function(value) Config.AimFOV = value end
})

CombatTab:AddToggle({
    Name = "Aim Team Check",
    Default = true,
    Save = true,
    Flag = "AimTeamCheck",
    Callback = function(state) Config.AimTeamCheck = state end
})

-- ═══ TAB: PLAYER ═══
local PlayerTab = Window:MakeTab({
    Name = "PLAYER",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

PlayerTab:AddSection({Name = "Movement"})

PlayerTab:AddToggle({
    Name = "Speed Hack",
    Default = false,
    Save = true,
    Flag = "SpeedEnabled",
    Callback = function(state) Config.SpeedEnabled = state end
})

PlayerTab:AddSlider({
    Name = "Speed Value",
    Min = 16, Max = 200, Default = 60,
    Color = Color3.fromRGB(0, 200, 255),
    Increment = 1,
    ValueName = "studs",
    Save = true,
    Flag = "SpeedValue",
    Callback = function(value) Config.SpeedValue = value end
})

PlayerTab:AddToggle({
    Name = "Jump Hack",
    Default = false,
    Save = true,
    Flag = "JumpEnabled",
    Callback = function(state) Config.JumpEnabled = state end
})

PlayerTab:AddSlider({
    Name = "Jump Value",
    Min = 50, Max = 500, Default = 100,
    Color = Color3.fromRGB(0, 200, 255),
    Increment = 10,
    ValueName = "power",
    Save = true,
    Flag = "JumpValue",
    Callback = function(value) Config.JumpValue = value end
})

PlayerTab:AddSection({Name = "Utility"})

PlayerTab:AddToggle({
    Name = "Noclip",
    Default = false,
    Save = true,
    Flag = "NoclipEnabled",
    Callback = function(state) Config.NoclipEnabled = state end
})

PlayerTab:AddToggle({
    Name = "Fly (W/A/S/D + Space/LCtrl)",
    Default = false,
    Save = true,
    Flag = "FlyEnabled",
    Callback = function(state) Config.FlyEnabled = state end
})

PlayerTab:AddSlider({
    Name = "Fly Speed",
    Min = 10, Max = 200, Default = 50,
    Color = Color3.fromRGB(0, 200, 255),
    Increment = 5,
    ValueName = "studs",
    Save = true,
    Flag = "FlySpeed",
    Callback = function(value) Config.FlySpeed = value end
})

-- ═══ TAB: WEAPON ═══
local WeaponTab = Window:MakeTab({
    Name = "WEAPON",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

WeaponTab:AddSection({Name = "Weapon Mods (Experimental)"})

WeaponTab:AddToggle({
    Name = "No Recoil",
    Default = false,
    Save = true,
    Flag = "NoRecoil",
    Callback = function(state) Config.NoRecoil = state end
})

WeaponTab:AddToggle({
    Name = "No Spread",
    Default = false,
    Save = true,
    Flag = "NoSpread",
    Callback = function(state) Config.NoSpread = state end
})

WeaponTab:AddToggle({
    Name = "Rapid Fire",
    Default = false,
    Save = true,
    Flag = "RapidFire",
    Callback = function(state) Config.RapidFire = state end
})

WeaponTab:AddToggle({
    Name = "Damage Boost",
    Default = false,
    Save = true,
    Flag = "DamageBoost",
    Callback = function(state) Config.DamageBoost = state end
})

WeaponTab:AddSlider({
    Name = "Damage Multiplier",
    Min = 1, Max = 20, Default = 5,
    Color = Color3.fromRGB(255, 100, 0),
    Increment = 1,
    ValueName = "x",
    Save = true,
    Flag = "DamageMultiplier",
    Callback = function(value) Config.DamageMultiplier = value end
})

-- ═══ TAB: FARM ═══
local FarmTab = Window:MakeTab({
    Name = "FARM",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

FarmTab:AddSection({Name = "NPC Control"})

FarmTab:AddToggle({
    Name = "Freeze NPC (Walk Speed = 0)",
    Default = false,
    Save = true,
    Flag = "FreezeNPC",
    Callback = function(state) Config.FreezeNPC = state end
})

FarmTab:AddSection({Name = "Info"})

FarmTab:AddParagraph({
    Title = "ℹ️ Catatan",
    Content = "Freeze NPC cuma ngefek kalau NPC-nya client-side. Kalau server-side, cuma keliatan diam di layar lu doang. Damage Boost & weapon mods butuh scan lebih lanjut buat 100% jalan."
})

-- ═══ INIT ═══
Library:Init()
