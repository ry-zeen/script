-- =======================================
-- RENXX HYPERSHOT - SAFE MODE v1.2
-- By: DEEP & RENXX
-- Library: Rayfield
-- =======================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== EXECUTOR CHECK ====================
local hasDrawing = pcall(function()
    local d = Drawing.new("Text")
    d:Remove()
end)

local hasHook = pcall(function()
    return hookmetamethod and getrawmetatable and setreadonly and newcclosure and getnamecallmethod
end)

-- ==================== HYPERSHOT REMOTE ====================
local Shoot = nil
pcall(function()
    local blaster = ReplicatedStorage:WaitForChild("Blaster", 10)
    if blaster then
        local remotes = blaster:WaitForChild("Remotes", 5)
        if remotes then
            Shoot = remotes:WaitForChild("Shoot", 5)
        end
    end
end)

if Shoot then
    print("[RENXX] Remote Shoot loaded.")
else
    warn("[RENXX] Remote Shoot NOT FOUND.")
end

-- ==================== STATS ====================
local Stats = {
    BlockedKick = 0,
    BlockedBan = 0,
    BlockedDetect = 0,
    BlockedVoid = 0,
    RateLimited = 0,
}

-- ==================== CONFIG ====================
local Config = {
    -- PROTECTION
    Bypass = true,
    AntiBan = true,
    AntiDetect = true,
    AntiKick = true,
    AntiAFK = true,
    RateLimiter = false,
    -- VISUAL
    ESPLine = false,
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPBox = false,
    ESPLineTeamColor = Color3.fromRGB(0, 255, 0),
    ESPLineEnemyColor = Color3.fromRGB(255, 0, 0),
    ESPLineBOTColor = Color3.fromRGB(255, 255, 0),
    ESPTextColor = Color3.fromRGB(255, 255, 255),
    ESPBoxColor = Color3.fromRGB(255, 0, 0),
    -- COMBAT
    Aimbot = false,
    AimSmooth = 5,
    POV = 90,
    ShowPOV = false,
    POVColor = Color3.fromRGB(255, 0, 100),
    AimPart = "Head",
    TeamCheck = true,
    WallCheck = false,
}

-- ==================== STATE ====================
local aimTarget = nil
local aimTargetPart = nil
local playerESP = {}
local botESP = {}
local originalNamecall = nil
local fireCount = 0
local lastFireReset = tick()

-- ==================== HELPER ====================
local function fovToRadius(fovDeg)
    return math.tan(math.rad(fovDeg / 2)) * (Camera.ViewportSize.Y / 2)
end

local function isSameTeam(player)
    local ok, result = pcall(function()
        if not LocalPlayer.Team or not player.Team then return false end
        return player.Team == LocalPlayer.Team
    end)
    return ok and result or false
end

local function hasLineOfSight(part)
    if not Config.WallCheck then return true end
    local ok, result = pcall(function()
        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin)
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
        return hit == nil or hit:IsDescendantOf(part.Parent)
    end)
    return ok and result or true
end

local function canFire()
    if not Config.Bypass then return true end
    if not Config.RateLimiter then return true end
    local now = tick()
    if now - lastFireReset >= 1 then
        fireCount = 0
        lastFireReset = now
    end
    if fireCount >= 8 then
        Stats.RateLimited = Stats.RateLimited + 1
        return false
    end
    fireCount = fireCount + 1
    return true
end

local function getBotFolder()
    local gameFolder = workspace:FindFirstChild("Game")
    if gameFolder then
        return gameFolder:FindFirstChild("__ServerBotCharacters")
    end
    return nil
end

-- ==================== GET TARGET (PLAYER + BOT) ====================
local function getClosestTarget()
    if not Config.Aimbot then return nil, nil end
    
    local closest, closestPart = nil, nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovRadius = fovToRadius(Config.POV)
    
    -- Loop PLAYER
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not (Config.TeamCheck and isSameTeam(player)) then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local part = player.Character:FindFirstChild(Config.AimPart)
                    or player.Character:FindFirstChild("Head")
                if hum and hum.Health > 0 and part then
                    if hasLineOfSight(part) then
                        local sp, on = Camera:WorldToViewportPoint(part.Position)
                        if on then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d <= fovRadius and d < shortest then
                                shortest = d
                                closest = hum
                                closestPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Loop BOT
    local botFolder = getBotFolder()
    if botFolder then
        for _, botChar in ipairs(botFolder:GetChildren()) do
            local hum = botChar:FindFirstChildOfClass("Humanoid")
            local part = botChar:FindFirstChild(Config.AimPart)
                or botChar:FindFirstChild("Head")
            if hum and hum.Health > 0 and part then
                if hasLineOfSight(part) then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d <= fovRadius and d < shortest then
                            shortest = d
                            closest = hum
                            closestPart = part
                        end
                    end
                end
            end
        end
    end
    
    return closest, closestPart
end

-- ==================== WINDOW ====================
local Window = Rayfield:CreateWindow({
    Name = "RENXX SAFE MODE | Hypershot",
    LoadingTitle = "Loading RENXX...",
    LoadingSubtitle = "Safe Mode - By DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================== TAB 1: PROTECTION ====================
local ProtTab = Window:CreateTab("PROTECTION", 4483362458)

ProtTab:CreateSection("Anti Features")

ProtTab:CreateToggle({
    Name = "Bypass",
    CurrentValue = true,
    Callback = function(v)
        Config.Bypass = v
        Rayfield:Notify({Title="RENXX", Content="Bypass: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

ProtTab:CreateToggle({
    Name = "Anti Ban",
    CurrentValue = true,
    Callback = function(v)
        Config.AntiBan = v
        Rayfield:Notify({Title="RENXX", Content="Anti Ban: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

ProtTab:CreateToggle({
    Name = "Anti Detect",
    CurrentValue = true,
    Callback = function(v) Config.AntiDetect = v end,
})

ProtTab:CreateToggle({
    Name = "Anti Kick",
    CurrentValue = true,
    Callback = function(v) Config.AntiKick = v end,
})

ProtTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Callback = function(v) Config.AntiAFK = v end,
})

ProtTab:CreateSection("Rate Limiter")

ProtTab:CreateToggle({
    Name = "Enable Rate Limiter (Auto-Fire Only)",
    CurrentValue = false,
    Callback = function(v)
        Config.RateLimiter = v
        Rayfield:Notify({Title="RENXX", Content="Rate Limiter: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

ProtTab:CreateSection("Stats")

ProtTab:CreateButton({
    Name = "Show Stats",
    Callback = function()
        Rayfield:Notify({
            Title = "Protection Stats",
            Content = string.format("Kick: %d | Ban: %d | Detect: %d | Void: %d | Rate: %d",
                Stats.BlockedKick, Stats.BlockedBan, Stats.BlockedDetect, 
                Stats.BlockedVoid, Stats.RateLimited),
            Duration = 5,
        })
    end,
})

-- ==================== TAB 2: VISUAL ====================
local VisualTab = Window:CreateTab("VISUAL", 4483362458)

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "ESP Line",
    CurrentValue = false,
    Callback = function(v) Config.ESPLine = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Name",
    CurrentValue = false,
    Callback = function(v) Config.ESPName = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Health",
    CurrentValue = false,
    Callback = function(v) Config.ESPHealth = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = false,
    Callback = function(v) Config.ESPDistance = v end,
})

VisualTab:CreateToggle({
    Name = "ESP Box",
    CurrentValue = false,
    Callback = function(v) Config.ESPBox = v end,
})

VisualTab:CreateSection("Colors")

VisualTab:CreateColorPicker({
    Name = "Line Team Color",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(c) Config.ESPLineTeamColor = c end,
})

VisualTab:CreateColorPicker({
    Name = "Line Enemy Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(c) Config.ESPLineEnemyColor = c end,
})

VisualTab:CreateColorPicker({
    Name = "Line BOT Color",
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(c) Config.ESPLineBOTColor = c end,
})

VisualTab:CreateColorPicker({
    Name = "Text Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(c) Config.ESPTextColor = c end,
})

VisualTab:CreateColorPicker({
    Name = "BOX Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(c) Config.ESPBoxColor = c end,
})

-- ==================== TAB 3: COMBAT ====================
local CombatTab = Window:CreateTab("COMBAT", 4483362458)

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v)
        Config.Aimbot = v
        Rayfield:Notify({Title="RENXX", Content="Aimbot: " .. (v and "ON" or "OFF"), Duration=2})
    end,
})

CombatTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {0, 15}, Increment = 1, Suffix = "x", CurrentValue = 5,
    Callback = function(v) Config.AimSmooth = v end,
})

CombatTab:CreateSlider({
    Name = "POV",
    Range = {0, 360}, Increment = 1, Suffix = "deg", CurrentValue = 90,
    Callback = function(v) Config.POV = v end,
})

CombatTab:CreateToggle({
    Name = "Show POV",
    CurrentValue = false,
    Callback = function(v) Config.ShowPOV = v end,
})

CombatTab:CreateColorPicker({
    Name = "POV Color",
    Color = Color3.fromRGB(255, 0, 100),
    Callback = function(c) Config.POVColor = c end,
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftFoot", "RightFoot"},
    CurrentOption = "Head",
    Callback = function(o)
        if type(o) == "table" then Config.AimPart = o[1] else Config.AimPart = o end
    end,
})

CombatTab:CreateSection("Filter")

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.TeamCheck = v end,
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Callback = function(v) Config.WallCheck = v end,
})

-- ==================== DRAWINGS ====================
local povCircle
if hasDrawing then
    pcall(function()
        povCircle = Drawing.new("Circle")
        povCircle.Visible = false
        povCircle.Thickness = 2
        povCircle.NumSides = 64
        povCircle.Filled = false
        povCircle.Transparency = 1
    end)
end

-- ==================== ESP DRAWINGS ====================
local function createESP()
    if not hasDrawing then return nil end
    local ok, d = pcall(function()
        return {
            line = Drawing.new("Line"),
            name = Drawing.new("Text"),
            hpBG = Drawing.new("Square"),
            hpBar = Drawing.new("Square"),
            dist = Drawing.new("Text"),
            box = Drawing.new("Square"),
        }
    end)
    if not ok then return nil end
    return d
end

local function destroyESP(d)
    if not d then return end
    for k, v in pairs(d) do
        pcall(function() v:Remove() end)
    end
end

local function hideESP(d)
    if not d then return end
    for k, v in pairs(d) do
        pcall(function() v.Visible = false end)
    end
end

-- Player ESP init
if hasDrawing then
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then playerESP[p] = createESP() end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then playerESP[p] = createESP() end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if playerESP[p] then destroyESP(playerESP[p]) playerESP[p] = nil end
    end)
end

-- ==================== BOT ESP CLEANUP LOOP (1.5s) ====================
task.spawn(function()
    while task.wait(1.5) do
        for char, d in pairs(botESP) do
            if not char.Parent then
                destroyESP(d)
                botESP[char] = nil
            else
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then
                    destroyESP(d)
                    botESP[char] = nil
                end
            end
        end
    end
end)

-- ==================== TARGET UPDATE ====================
task.spawn(function()
    while task.wait(0.1) do
        aimTarget, aimTargetPart = getClosestTarget()
    end
end)

-- ==================== RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    -- POV Circle
    if povCircle then
        pcall(function()
            if Config.ShowPOV and Config.Aimbot then
                povCircle.Visible = true
                povCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                povCircle.Radius = fovToRadius(Config.POV)
                povCircle.Color = Config.POVColor
            else
                povCircle.Visible = false
            end
        end)
    end
    
    -- Aimbot Camera
    if Config.Aimbot and aimTargetPart and aimTargetPart.Parent and Config.AimSmooth > 0 then
        local targetCF = CFrame.new(Camera.CFrame.Position, aimTargetPart.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(1, Config.AimSmooth))
    end
    
    -- ESP Render
    if hasDrawing then
        local espActive = Config.ESPLine or Config.ESPName or Config.ESPHealth 
            or Config.ESPDistance or Config.ESPBox
        
        if not espActive then
            for _, d in pairs(playerESP) do hideESP(d) end
            for _, d in pairs(botESP) do hideESP(d) end
        else
            -- PLAYER ESP
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and playerESP[p] then
                    local d = playerESP[p]
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local sp, on = Camera:WorldToViewportPoint(hrp.Position)
                        if on then
                            local isTeam = isSameTeam(p)
                            local lineColor = isTeam and Config.ESPLineTeamColor or Config.ESPLineEnemyColor
                            
                            if Config.ESPLine then
                                d.line.Visible = true
                                d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                d.line.To = Vector2.new(sp.X, sp.Y)
                                d.line.Color = lineColor
                                d.line.Thickness = 1
                            else d.line.Visible = false end
                            
                            if Config.ESPName then
                                d.name.Visible = true
                                d.name.Text = p.Name
                                d.name.Position = Vector2.new(sp.X, sp.Y - 50)
                                d.name.Color = Config.ESPTextColor
                                d.name.Size = 14
                                d.name.Center = true
                                d.name.Outline = true
                            else d.name.Visible = false end
                            
                            if Config.ESPHealth then
                                local hpP = hum.Health / hum.MaxHealth
                                d.hpBG.Visible = true
                                d.hpBG.Size = Vector2.new(4, 40)
                                d.hpBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
                                d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                d.hpBG.Filled = true
                                d.hpBar.Visible = true
                                d.hpBar.Size = Vector2.new(4, 40 * hpP)
                                d.hpBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hpP)))
                                d.hpBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hpP)
                                d.hpBar.Filled = true
                            else
                                d.hpBG.Visible = false
                                d.hpBar.Visible = false
                            end
                            
                            if Config.ESPDistance then
                                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                d.dist.Visible = true
                                d.dist.Text = math.floor(dist) .. "m"
                                d.dist.Position = Vector2.new(sp.X, sp.Y + 25)
                                d.dist.Color = Config.ESPTextColor
                                d.dist.Size = 12
                                d.dist.Center = true
                                d.dist.Outline = true
                            else d.dist.Visible = false end
                            
                            if Config.ESPBox then
                                d.box.Visible = true
                                d.box.Size = Vector2.new(50, 80)
                                d.box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                                d.box.Color = Config.ESPBoxColor
                                d.box.Thickness = 1
                                d.box.Filled = false
                            else d.box.Visible = false end
                        else
                            hideESP(d)
                        end
                    else
                        hideESP(d)
                    end
                end
            end
            
            -- BOT ESP
            local botFolder = getBotFolder()
            if botFolder then
                for _, botChar in ipairs(botFolder:GetChildren()) do
                    local hum = botChar:FindFirstChildOfClass("Humanoid")
                    local hrp = botChar:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        if not botESP[botChar] then
                            botESP[botChar] = createESP()
                        end
                        local d = botESP[botChar]
                        if d then
                            local sp, on = Camera:WorldToViewportPoint(hrp.Position)
                            if on then
                                if Config.ESPLine then
                                    d.line.Visible = true
                                    d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    d.line.To = Vector2.new(sp.X, sp.Y)
                                    d.line.Color = Config.ESPLineBOTColor
                                    d.line.Thickness = 1
                                else d.line.Visible = false end
                                
                                if Config.ESPName then
                                    d.name.Visible = true
                                    d.name.Text = "[BOT] " .. botChar.Name
                                    d.name.Position = Vector2.new(sp.X, sp.Y - 50)
                                    d.name.Color = Config.ESPTextColor
                                    d.name.Size = 14
                                    d.name.Center = true
                                    d.name.Outline = true
                                else d.name.Visible = false end
                                
                                if Config.ESPHealth then
                                    local hpP = hum.Health / hum.MaxHealth
                                    d.hpBG.Visible = true
                                    d.hpBG.Size = Vector2.new(4, 40)
                                    d.hpBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
                                    d.hpBG.Color = Color3.fromRGB(0, 0, 0)
                                    d.hpBG.Filled = true
                                    d.hpBar.Visible = true
                                    d.hpBar.Size = Vector2.new(4, 40 * hpP)
                                    d.hpBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hpP)))
                                    d.hpBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hpP)
                                    d.hpBar.Filled = true
                                else
                                    d.hpBG.Visible = false
                                    d.hpBar.Visible = false
                                end
                                
                                if Config.ESPDistance then
                                    local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                    d.dist.Visible = true
                                    d.dist.Text = math.floor(dist) .. "m"
                                    d.dist.Position = Vector2.new(sp.X, sp.Y + 25)
                                    d.dist.Color = Config.ESPTextColor
                                    d.dist.Size = 12
                                    d.dist.Center = true
                                    d.dist.Outline = true
                                else d.dist.Visible = false end
                                
                                if Config.ESPBox then
                                    d.box.Visible = true
                                    d.box.Size = Vector2.new(50, 80)
                                    d.box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                                    d.box.Color = Config.ESPLineBOTColor
                                    d.box.Thickness = 1
                                    d.box.Filled = false
                                else d.box.Visible = false end
                            else
                                hideESP(d)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ==================== ANTI AFK ====================
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ==================== PROTECTION HOOK ====================
if hasHook then
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        originalNamecall = mt.__namecall
        local newc = newcclosure or function(f) return f end
        
        mt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod()
            if not method then return originalNamecall(self, ...) end
            
            local methodLower = method:lower()
            
            -- ANTI KICK (case-insensitive)
            if Config.AntiKick and methodLower == "kick" and self == LocalPlayer then
                Stats.BlockedKick = Stats.BlockedKick + 1
                return nil
            end
            
            -- Filter cuma FireServer & InvokeServer
            if methodLower == "fireserver" or methodLower == "invokeserver" then
                local args = {...}
                
                if typeof(self) == "Instance" then
                    local n = self.Name:lower()
                    
                    -- ANTI DETECT
                    if Config.AntiDetect then
                        if n:find("detect") or n:find("anticheat") or n:find("flag") 
                           or n:find("report") or n:find("log") or n:find("watch") then
                            Stats.BlockedDetect = Stats.BlockedDetect + 1
                            return nil
                        end
                    end
                    
                    -- ANTI BAN (counter terpisah)
                    if Config.AntiBan then
                        if n:find("ban") or n:find("punish") or n:find("terminate") then
                            Stats.BlockedBan = Stats.BlockedBan + 1
                            return nil
                        end
                    end
                    
                    -- ANTI VOID (keyword spesifik)
                    if n:find("sendtovoid") or n:find("teleportvoid") or n:find("kicktovoid") 
                       or n:find("voidteleport") or n:find("sendback") or n:find("voidkick") then
                        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local myPos = myHRP and myHRP.Position
                        
                        for i = 1, #args do
                            local pos = nil
                            if typeof(args[i]) == "CFrame" then
                                pos = args[i].Position
                            elseif typeof(args[i]) == "Vector3" then
                                pos = args[i]
                            end
                            
                            if pos then
                                local isVoidY = pos.Y < -100 or pos.Y > 50000
                                local isFarFromPlayer = myPos and (pos - myPos).Magnitude > 5000
                                if isVoidY or isFarFromPlayer then
                                    Stats.BlockedVoid = Stats.BlockedVoid + 1
                                    return nil
                                end
                            end
                        end
                    end
                    
                    -- RATE LIMITER (cuma kalau toggle ON)
                    if Config.Bypass and Config.RateLimiter and self == Shoot then
                        if not canFire() then
                            return nil
                        end
                    end
                end
                
                return originalNamecall(self, table.unpack(args))
            end
            
            return originalNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
    print("[RENXX] Protection hook AKTIF.")
end

-- ==================== CHARACTER ADDED ====================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
end)

-- ==================== NOTIFIKASI ====================
Rayfield:Notify({
    Title = "RENXX SAFE MODE v1.2",
    Content = "Loaded! All bugs fixed.",
    Duration = 5,
})

print("RENXX SAFE MODE v1.2")
print("Protection: " .. (hasHook and "ACTIVE" or "DISABLED"))
print("By DEEP & RENXX")
