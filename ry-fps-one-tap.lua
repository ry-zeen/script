-- [[ RYZREN HUB v19 - AESTHETIC EDITION ]]
print("[RYZREN] Loading Aesthetic Script...")

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("[RYZREN] Gagal load Rayfield UI.")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== SETTINGS =====
local Settings = {
    -- Visual (Warna Default Dibikin Neon/Cyan biar Cantik)
    EspMaxRadius = 1000, EspTeamCheck = true, EspBotNameTag = true, EspLinePos = "Bottom",
    EspLine = true, EspName = true, EspHealth = true, EspBox = true, EspSkeleton = true, EspDistance = true,
    ColLinePlayer = Color3.fromRGB(0, 255, 255), ColNamePlayer = Color3.fromRGB(255, 255, 255), ColHealthPlayer = Color3.fromRGB(0, 255, 128), ColSkeletonPlayer = Color3.fromRGB(255, 255, 255), ColBoxPlayer = Color3.fromRGB(0, 255, 255),
    ColLineBot = Color3.fromRGB(255, 0, 128), ColNameBot = Color3.fromRGB(255, 255, 255), ColHealthBot = Color3.fromRGB(255, 0, 0), ColSkeletonBot = Color3.fromRGB(255, 255, 255), ColBoxBot = Color3.fromRGB(255, 0, 128),
    -- Combat
    SilentAim = true, SilentFov = 150, SilentShowFov = true, SilentAimPart = "Head", SilentFovColor = Color3.fromRGB(255, 255, 255), SnapLine = true, SnapLineColor = Color3.fromRGB(255, 0, 0),
    WallBang = false,
    Aimbot = false, AimSmooth = 0.2, AimPart = "Head", AimFov = 100, AimShowFov = false, AimFovColor = Color3.fromRGB(0, 255, 255), AimTeamCheck = true, AimWallCheck = true,
    -- Player
    SpeedHack = false, SpeedValue = 16, JumpHack = false, JumpValue = 100, InfJump = false, NoClip = false,
    Fly = false, FlySpeed = 50,
    -- Farm
    Hitbox = false, HitboxSize = 5, HitboxPart = "All", Bring = false, BringType = "All", BringDist = 10
}

local target = { position = nil, character = nil }
local ESP_Cache = {}

-- ===== RAYFIELD UI =====
local Window = Rayfield:CreateWindow({
   Name = "🌸 Ryzren Hub v19",
   LoadingTitle = "Memuat Aesthetic...",
   LoadingSubtitle = "Neon Edition",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local VisualTab = Window:CreateTab("Visual", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local FarmTab = Window:CreateTab("Farm", 4483362458)

-- ============================================================
-- TAB VISUAL
-- ============================================================
VisualTab:CreateSection("ESP Settings")
VisualTab:CreateSlider({ Name = "ESP Max Radius", Range = {100, 2000}, Increment = 50, Suffix = "m", CurrentValue = 1000, Flag = "EspMaxRadius", Callback = function(v) Settings.EspMaxRadius = v end })
VisualTab:CreateToggle({ Name = "ESP Player Team Check", CurrentValue = true, Flag = "EspTeamCheck", Callback = function(v) Settings.EspTeamCheck = v end })
VisualTab:CreateToggle({ Name = "ESP Bot Name Tag", CurrentValue = true, Flag = "EspBotNameTag", Callback = function(v) Settings.EspBotNameTag = v end })
VisualTab:CreateToggle({ Name = "ESP Distance", CurrentValue = true, Flag = "EspDistance", Callback = function(v) Settings.EspDistance = v end })
VisualTab:CreateDropdown({ Name = "ESP Line Position", Options = {"Bottom", "Center", "Top"}, CurrentOption = {"Bottom"}, Flag = "EspLinePos", Callback = function(o) Settings.EspLinePos = o[1] end })

VisualTab:CreateSection("ESP Elements")
VisualTab:CreateToggle({ Name = "ESP Line", CurrentValue = true, Flag = "EspLine", Callback = function(v) Settings.EspLine = v end })
VisualTab:CreateToggle({ Name = "ESP Name & Info", CurrentValue = true, Flag = "EspName", Callback = function(v) Settings.EspName = v end })
VisualTab:CreateToggle({ Name = "ESP Health (Smooth Bar)", CurrentValue = true, Flag = "EspHealth", Callback = function(v) Settings.EspHealth = v end })
VisualTab:CreateToggle({ Name = "ESP Box (Corner Mode)", CurrentValue = true, Flag = "EspBox", Callback = function(v) Settings.EspBox = v end })
VisualTab:CreateToggle({ Name = "ESP Skeleton", CurrentValue = true, Flag = "EspSkeleton", Callback = function(v) Settings.EspSkeleton = v end })

VisualTab:CreateSection("ESP Colors - Player")
VisualTab:CreateColorPicker({ Name = "Line Color", Color = Settings.ColLinePlayer, Flag = "ColLineP", Callback = function(v) Settings.ColLinePlayer = v end })
VisualTab:CreateColorPicker({ Name = "Box Color", Color = Settings.ColBoxPlayer, Flag = "ColBoxP", Callback = function(v) Settings.ColBoxPlayer = v end })
VisualTab:CreateColorPicker({ Name = "Health Color", Color = Settings.ColHealthPlayer, Flag = "ColHealthP", Callback = function(v) Settings.ColHealthPlayer = v end })

VisualTab:CreateSection("ESP Colors - Bot")
VisualTab:CreateColorPicker({ Name = "Line Color", Color = Settings.ColLineBot, Flag = "ColLineB", Callback = function(v) Settings.ColLineBot = v end })
VisualTab:CreateColorPicker({ Name = "Box Color", Color = Settings.ColBoxBot, Flag = "ColBoxB", Callback = function(v) Settings.ColBoxBot = v end })
VisualTab:CreateColorPicker({ Name = "Health Color", Color = Settings.ColHealthBot, Flag = "ColHealthB", Callback = function(v) Settings.ColHealthBot = v end })

-- ============================================================
-- TAB COMBAT
-- ============================================================
CombatTab:CreateSection("Silent Aim")
CombatTab:CreateToggle({ Name = "Silent Aim", CurrentValue = true, Flag = "SilentAim", Callback = function(v) Settings.SilentAim = v end })
CombatTab:CreateSlider({ Name = "Pov / FOV Circle", Range = {0, 360}, Increment = 5, CurrentValue = 150, Flag = "SilentFov", Callback = function(v) Settings.SilentFov = v end })
CombatTab:CreateToggle({ Name = "Show Pov", CurrentValue = true, Flag = "SilentShowFov", Callback = function(v) Settings.SilentShowFov = v end })
CombatTab:CreateDropdown({ Name = "Aim Part", Options = {"Head", "Body"}, CurrentOption = {"Head"}, Flag = "SilentAimPart", Callback = function(o) Settings.SilentAimPart = o[1] end })
CombatTab:CreateColorPicker({ Name = "Pov Color", Color = Settings.SilentFovColor, Flag = "SilentFovColor", Callback = function(v) Settings.SilentFovColor = v end })
CombatTab:CreateToggle({ Name = "SnapLine", CurrentValue = true, Flag = "SnapLine", Callback = function(v) Settings.SnapLine = v end })
CombatTab:CreateColorPicker({ Name = "SnapLine Color", Color = Settings.SnapLineColor, Flag = "SnapLineColor", Callback = function(v) Settings.SnapLineColor = v end })
CombatTab:CreateToggle({ Name = "Wall Bang (Magic Bullet)", CurrentValue = false, Flag = "WallBang", Callback = function(v) Settings.WallBang = v end })

CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({ Name = "Aimbot", CurrentValue = false, Flag = "Aimbot", Callback = function(v) Settings.Aimbot = v end })
CombatTab:CreateSlider({ Name = "Aim Smoothness", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.2, Flag = "AimSmooth", Callback = function(v) Settings.AimSmooth = v end })
CombatTab:CreateDropdown({ Name = "Aim Part (Aimbot)", Options = {"Head", "Body"}, CurrentOption = {"Head"}, Flag = "AimPart", Callback = function(o) Settings.AimPart = o[1] end })
CombatTab:CreateSlider({ Name = "Pov / FOV Circle (Aimbot)", Range = {0, 360}, Increment = 5, CurrentValue = 100, Flag = "AimFov", Callback = function(v) Settings.AimFov = v end })
CombatTab:CreateToggle({ Name = "Show Pov (Aimbot)", CurrentValue = false, Flag = "AimShowFov", Callback = function(v) Settings.AimShowFov = v end })
CombatTab:CreateColorPicker({ Name = "Pov Color (Aimbot)", Color = Settings.AimFovColor, Flag = "AimFovColor", Callback = function(v) Settings.AimFovColor = v end })
CombatTab:CreateToggle({ Name = "Team Check (Aimbot)", CurrentValue = true, Flag = "AimTeamCheck", Callback = function(v) Settings.AimTeamCheck = v end })
CombatTab:CreateToggle({ Name = "Wall Check (Aimbot)", CurrentValue = true, Flag = "AimWallCheck", Callback = function(v) Settings.AimWallCheck = v end })

-- ============================================================
-- TAB PLAYER
-- ============================================================
PlayerTab:CreateSection("Speed & Jump")
PlayerTab:CreateToggle({ Name = "Speed Hack", CurrentValue = false, Flag = "SpeedHack", Callback = function(v) Settings.SpeedHack = v end })
PlayerTab:CreateSlider({ Name = "Speed Value", Range = {16, 100}, Increment = 1, CurrentValue = 16, Flag = "SpeedValue", Callback = function(v) Settings.SpeedValue = v end })
PlayerTab:CreateToggle({ Name = "Jump Hack", CurrentValue = false, Flag = "JumpHack", Callback = function(v) Settings.JumpHack = v end })
PlayerTab:CreateSlider({ Name = "Jump Value", Range = {50, 500}, Increment = 10, CurrentValue = 100, Flag = "JumpValue", Callback = function(v) Settings.JumpValue = v end })
PlayerTab:CreateToggle({ Name = "Infinity Jump", CurrentValue = false, Flag = "InfJump", Callback = function(v) Settings.InfJump = v end })

PlayerTab:CreateSection("Fly Mods")
PlayerTab:CreateToggle({ Name = "✈️ Fly (Pake Analog)", CurrentValue = false, Flag = "Fly", Callback = function(v) Settings.Fly = v end })
PlayerTab:CreateSlider({ Name = "Fly Speed", Range = {10, 200}, Increment = 5, CurrentValue = 50, Flag = "FlySpeed", Callback = function(v) Settings.FlySpeed = v end })

PlayerTab:CreateSection("Extra")
PlayerTab:CreateToggle({ Name = "No Clip", CurrentValue = false, Flag = "NoClip", Callback = function(v) Settings.NoClip = v end })

-- ============================================================
-- TAB FARM
-- ============================================================
FarmTab:CreateSection("Hitbox Expander")
FarmTab:CreateToggle({ Name = "Hitbox", CurrentValue = false, Flag = "Hitbox", Callback = function(v) Settings.Hitbox = v end })
FarmTab:CreateSlider({ Name = "Hitbox Size", Range = {2, 20}, Increment = 1, CurrentValue = 5, Flag = "HitboxSize", Callback = function(v) Settings.HitboxSize = v end })
FarmTab:CreateDropdown({ Name = "Hit Part", Options = {"All", "Head", "Body"}, CurrentOption = {"All"}, Flag = "HitboxPart", Callback = function(o) Settings.HitboxPart = o[1] end })

FarmTab:CreateSection("Bring")
FarmTab:CreateToggle({ Name = "Bring Player & Bot", CurrentValue = false, Flag = "Bring", Callback = function(v) Settings.Bring = v end })
FarmTab:CreateDropdown({ Name = "Bring Type", Options = {"All", "SingleOnly"}, CurrentOption = {"All"}, Flag = "BringType", Callback = function(o) Settings.BringType = o[1] end })
FarmTab:CreateSlider({ Name = "Bring Dist", Range = {0, 100}, Increment = 1, CurrentValue = 10, Flag = "BringDist", Callback = function(v) Settings.BringDist = v end })

-- ============================================================
-- LOGIKA VISUAL CANTIK (AESTHETIC ESP)
-- ============================================================
pcall(function()
    local silentCircle = Drawing.new("Circle"); silentCircle.Thickness = 1; silentCircle.Transparency = 0.5; silentCircle.NumSides = 60
    local aimCircle = Drawing.new("Circle"); aimCircle.Thickness = 1; aimCircle.Transparency = 0.5; aimCircle.NumSides = 60
    local snapLine = Drawing.new("Line"); snapLine.Thickness = 1; snapLine.Transparency = 0.5

    local function getPart(char, partType)
        if not char then return nil end
        if partType == "Head" then return char:FindFirstChild("Head") end
        if partType == "Body" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
        return char:FindFirstChild("HumanoidRootPart")
    end

    local function getTarget(fovRadius, isAimbot)
        local closest, dist = nil, fovRadius
        local closestChar = nil
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        
        local function checkTarget(entity, isBot)
            if not entity or entity == LocalPlayer.Character then return end
            local hum = entity:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            
            if not isBot and isAimbot and Settings.AimTeamCheck then
                local p = Players:GetPlayerFromCharacter(entity)
                if p and p.Team == LocalPlayer.Team then return end
            end
            
            local part = getPart(entity, isAimbot and Settings.AimPart or Settings.SilentAimPart)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d < dist then
                        if isAimbot and Settings.AimWallCheck and not Settings.WallBang then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
                            if result and not result.Instance:IsDescendantOf(entity) then return end
                        end
                        dist = d
                        closest = part
                        closestChar = entity
                    end
                end
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do checkTarget(p.Character, false) end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then checkTarget(obj, true) end
        end
        return closest, closestChar
    end

    -- Skeleton Bones
    local bonesR15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local bonesR6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

    -- Bikin Objek ESP
    local function createESP()
        -- Corner Box Lines (8 Garis)
        local corners = {}
        for i=1, 8 do
            local l = Drawing.new("Line")
            l.Thickness = 1.5
            l.Visible = false
            table.insert(corners, l)
        end

        local name = Drawing.new("Text"); name.Size = 13; name.Center = true; name.Outline = true; name.Visible = false; name.Font = 2
        local distText = Drawing.new("Text"); distText.Size = 11; distText.Center = true; distText.Outline = true; distText.Visible = false; distText.Font = 2
        
        -- Health Bar (Kotak isi & Background)
        local healthBg = Drawing.new("Square"); healthBg.Thickness = 1; healthBg.Filled = true; healthBg.Color = Color3.fromRGB(20, 20, 20); healthBg.Visible = false
        local healthFill = Drawing.new("Square"); healthFill.Thickness = 1; healthFill.Filled = true; healthFill.Visible = false

        local lineEsp = Drawing.new("Line"); lineEsp.Thickness = 1; lineEsp.Visible = false
        local lines = {}
        for i=1, 14 do local l = Drawing.new("Line"); l.Thickness = 1; l.Visible = false; table.insert(lines, l) end

        return {Corners=corners, Name=name, Dist=distText, HealthBg=healthBg, Health=healthFill, LineEsp=lineEsp, Skeleton=lines}
    end

    local function processESP(entity, isBot)
        if not ESP_Cache[entity] then ESP_Cache[entity] = createESP() end
        local esp = ESP_Cache[entity]
        local hum = entity:FindFirstChildOfClass("Humanoid")
        local hrp = entity:FindFirstChild("HumanoidRootPart")
        local head = entity:FindFirstChild("Head")
        
        if not hum or hum.Health <= 0 or not hrp or not head then
            for _, l in pairs(esp.Corners) do l.Visible = false end
            esp.Name.Visible = false; esp.Dist.Visible = false; esp.Health.Visible = false; esp.HealthBg.Visible = false; esp.LineEsp.Visible = false
            for _, l in pairs(esp.Skeleton) do l.Visible = false end
            return
        end

        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        local rootPos = Camera:WorldToViewportPoint(hrp.Position)
        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        
        if onScreen and dist <= Settings.EspMaxRadius then
            local cLine = isBot and Settings.ColLineBot or Settings.ColLinePlayer
            local cName = isBot and Settings.ColNameBot or Settings.ColNamePlayer
            local cHealth = isBot and Settings.ColHealthBot or Settings.ColHealthPlayer
            local cBox = isBot and Settings.ColBoxBot or Settings.ColBoxPlayer
            local cSkel = isBot and Settings.ColSkeletonBot or Settings.ColSkeletonPlayer

            local show = true
            if not isBot and Settings.EspTeamCheck then
                local p = Players:GetPlayerFromCharacter(entity)
                if p and p.Team == LocalPlayer.Team then show = false end
            end

            if show then
                -- Nama & Jarak
                if Settings.EspName and (not isBot or Settings.EspBotNameTag) then
                    esp.Name.Text = isBot and "BOT" or entity.Name
                    esp.Name.Position = Vector2.new(headPos.X, headPos.Y - 35)
                    esp.Name.Color = cName; esp.Name.Visible = true
                    
                    if Settings.EspDistance then
                        esp.Dist.Text = "[" .. math.floor(dist) .. "m]"
                        esp.Dist.Position = Vector2.new(headPos.X, headPos.Y - 22)
                        esp.Dist.Color = cName; esp.Dist.Visible = true
                    else esp.Dist.Visible = false end
                else esp.Name.Visible = false; esp.Dist.Visible = false end

                -- Hitung Ukuran Box
                local height = math.abs(headPos.Y - rootPos.Y)
                local width = height / 2.5 -- Bikin box agak lebih ramping biar estetik
                local topX, topY = headPos.X - width/2, headPos.Y
                local botX, botY = headPos.X + width/2, headPos.Y + height
                local cornerSize = height / 4 -- Panjang garis sudut

                -- Corner Box Logic
                if Settings.EspBox then
                    -- Kiri Atas
                    esp.Corners[1].From = Vector2.new(topX, topY); esp.Corners[1].To = Vector2.new(topX + cornerSize, topY)
                    esp.Corners[2].From = Vector2.new(topX, topY); esp.Corners[2].To = Vector2.new(topX, topY + cornerSize)
                    -- Kanan Atas
                    esp.Corners[3].From = Vector2.new(botX, topY); esp.Corners[3].To = Vector2.new(botX - cornerSize, topY)
                    esp.Corners[4].From = Vector2.new(botX, topY); esp.Corners[4].To = Vector2.new(botX, topY + cornerSize)
                    -- Kiri Bawah
                    esp.Corners[5].From = Vector2.new(topX, botY); esp.Corners[5].To = Vector2.new(topX + cornerSize, botY)
                    esp.Corners[6].From = Vector2.new(topX, botY); esp.Corners[6].To = Vector2.new(topX, botY - cornerSize)
                    -- Kanan Bawah
                    esp.Corners[7].From = Vector2.new(botX, botY); esp.Corners[7].To = Vector2.new(botX - cornerSize, botY)
                    esp.Corners[8].From = Vector2.new(botX, botY); esp.Corners[8].To = Vector2.new(botX, botY - cornerSize)
                    
                    for _, l in pairs(esp.Corners) do l.Color = cBox; l.Visible = true end
                else
                    for _, l in pairs(esp.Corners) do l.Visible = false end
                end

                -- Health Bar (Smooth)
                if Settings.EspHealth then
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barWidth = 2
                    local barX = topX - 6
                    
                    esp.HealthBg.Size = Vector2.new(barWidth + 1, height)
                    esp.HealthBg.Position = Vector2.new(barX - 0.5, topY)
                    esp.HealthBg.Color = Color3.fromRGB(20, 20, 20)
                    esp.HealthBg.Visible = true

                    esp.Health.Size = Vector2.new(barWidth, height * hp)
                    esp.Health.Position = Vector2.new(barX, botY - (height * hp))
                    esp.Health.Color = cHealth
                    esp.Health.Visible = true
                else
                    esp.Health.Visible = false; esp.HealthBg.Visible = false
                end

                -- Line ESP
                if Settings.EspLine then
                    local startX = Camera.ViewportSize.X / 2
                    local startY = Camera.ViewportSize.Y 
                    if Settings.EspLinePos == "Center" then startY = Camera.ViewportSize.Y / 2
                    elseif Settings.EspLinePos == "Top" then startY = 0 end
                    esp.LineEsp.From = Vector2.new(startX, startY); esp.LineEsp.To = Vector2.new(headPos.X, botY); esp.LineEsp.Color = cLine; esp.LineEsp.Visible = true
                else esp.LineEsp.Visible = false end

                -- Skeleton ESP
                if Settings.EspSkeleton then
                    local useBones = entity:FindFirstChild("UpperTorso") and bonesR15 or bonesR6
                    for i, bone in pairs(useBones) do
                        local p1, p2 = entity:FindFirstChild(bone[1]), entity:FindFirstChild(bone[2])
                        if p1 and p2 and esp.Skeleton[i] then
                            local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                            if on1 and on2 then
                                esp.Skeleton[i].From = Vector2.new(pos1.X, pos1.Y); esp.Skeleton[i].To = Vector2.new(pos2.X, pos2.Y); esp.Skeleton[i].Color = cSkel; esp.Skeleton[i].Visible = true
                            else esp.Skeleton[i].Visible = false end
                        elseif esp.Skeleton[i] then esp.Skeleton[i].Visible = false end
                    end
                else for _, l in pairs(esp.Skeleton) do l.Visible = false end end
            else
                for _, l in pairs(esp.Corners) do l.Visible = false end
                esp.Name.Visible = false; esp.Dist.Visible = false; esp.Health.Visible = false; esp.HealthBg.Visible = false; esp.LineEsp.Visible = false
                for _, l in pairs(esp.Skeleton) do l.Visible = false end
            end
        else
            for _, l in pairs(esp.Corners) do l.Visible = false end
            esp.Name.Visible = false; esp.Dist.Visible = false; esp.Health.Visible = false; esp.HealthBg.Visible = false; esp.LineEsp.Visible = false
            for _, l in pairs(esp.Skeleton) do l.Visible = false end
        end
    end

    -- RENDER LOOP
    RunService.RenderStepped:Connect(function()
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        silentCircle.Position = center; silentCircle.Radius = Settings.SilentFov; silentCircle.Color = Settings.SilentFovColor; silentCircle.Visible = Settings.SilentAim and Settings.SilentShowFov
        aimCircle.Position = center; aimCircle.Radius = Settings.AimFov; aimCircle.Color = Settings.AimFovColor; aimCircle.Visible = Settings.Aimbot and Settings.AimShowFov

        if Settings.SilentAim then
            local targetPart, targetChar = getTarget(Settings.SilentFov, false)
            if targetPart and targetChar then
                target.position = targetPart.Position
                target.character = targetChar
                if Settings.SnapLine then
                    local sp, on = Camera:WorldToViewportPoint(targetPart.Position)
                    if on then snapLine.From = center; snapLine.To = Vector2.new(sp.X, sp.Y); snapLine.Color = Settings.SnapLineColor; snapLine.Visible = true
                    else snapLine.Visible = false end
                else snapLine.Visible = false end
            else target.position = nil; target.character = nil; snapLine.Visible = false end
        else target.position = nil; target.character = nil; snapLine.Visible = false end

        if Settings.Aimbot then
            local targetPart = getTarget(Settings.AimFov, true)
            if targetPart then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.AimSmooth)
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do if p.Character then processESP(p.Character, false) end end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then processESP(obj, true) end
        end
    end)

    -- HEARTBEAT LOOP (PLAYER & FARM)
    RunService.Heartbeat:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local hum = LocalPlayer.Character.Humanoid
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if Settings.SpeedHack then hum.WalkSpeed = Settings.SpeedValue end

            if Settings.Fly and hrp then
                local moveDir = hum.MoveDirection
                local forward = Camera.CFrame.LookVector
                local right = Camera.CFrame.RightVector
                if moveDir.Magnitude > 0 then
                    local flyVector = (forward * -moveDir.Z + right * moveDir.X).Unit
                    hrp.Velocity = flyVector * Settings.FlySpeed
                else
                    hrp.Velocity = Vector3.new(0, 0, 0)
                end
            end
            
            if Settings.NoClip then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            end
        end

        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            local function processFarm(entity, isBot)
                local hum = entity:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return end
                local hrp = entity:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                if Settings.Hitbox then
                    if Settings.HitboxPart == "All" then
                        for _, part in pairs(entity:GetChildren()) do if part:IsA("BasePart") then part.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize) end end
                    elseif Settings.HitboxPart == "Head" then
                        local head = entity:FindFirstChild("Head")
                        if head then head.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize) end
                    elseif Settings.HitboxPart == "Body" then
                        hrp.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    end
                end

                if Settings.Bring then
                    if Settings.BringType == "SingleOnly" and isBot then return end
                    if (hrp.Position - myHrp.Position).Magnitude <= Settings.BringDist then
                        pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
                        hrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -5)
                    end
                end
            end
            for _, p in ipairs(Players:GetPlayers()) do if p.Character then processFarm(p.Character, false) end end
            for _, obj in ipairs(workspace:GetChildren()) do if obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then processFarm(obj, true) end end
        end
    end)

    -- JUMP HACK FIX
    UserInputService.JumpRequest:Connect(function()
        if not LocalPlayer.Character or Settings.Fly then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if Settings.JumpHack then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, Settings.JumpValue, hrp.Velocity.Z)
            elseif Settings.InfJump then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
            end
        end
    end)

    -- SILENT AIM & WALL BANG HOOK
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if Settings.SilentAim and target.position and target.character and (method == "Raycast" or method == "FindPartOnRay") and self == workspace then
            if typeof(args[2]) == "Vector3" then
                local origin = args[1]
                args[2] = (target.position - origin).Unit * args[2].Magnitude
                if Settings.WallBang and method == "Raycast" then
                    local params = args[3]
                    if typeof(params) == "RaycastParams" then
                        params.FilterType = Enum.RaycastFilterType.Include
                        params.FilterDescendantsInstances = {target.character}
                    end
                end
                return oldNamecall(self, table.unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end))
end)

print("[RYZREN] Script v19 (AESTHETIC) Loaded!")
