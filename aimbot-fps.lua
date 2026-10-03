--[[
    ═══════════════════════════════════════════════
    AIMBOT FPS  FINAL | By RENXX
    DEPY IS GOOD
    ═══════════════════════════════════════════════
    Library : Orion UI
    Hook    : Unified __namecall (Raycast + Kick + Shop
    ═══════════════════════════════════════════════
]]

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════ CLEANUP _G ═══════════════
if getgenv then
    getgenv()._renxxShopPrinted = {}
end

-- ═══════════════ GUARDS ═══════════════
local hasHook = pcall(function()
    return hookmetamethod and getrawmetatable and setreadonly
end)
local newcclosure = newcclosure or function(f) return f end
local getnamecallmethod = getnamecallmethod or function() return "" end
local hasDrawing = pcall(function()
    local d = Drawing.new("Text")
    d:Remove()
end)

if not hasDrawing then
    warn("[RENXX v4.7] Executor nggak support Drawing API!")
end

-- ═══════════════ SHOOT REMOTE ═══════════════
local Shoot
pcall(function()
    Shoot = ReplicatedStorage:WaitForChild("Blaster", 10):WaitForChild("Remotes", 10):WaitForChild("Shoot", 10)
end)

-- ═══════════════ CONFIG ═══════════════
local C = {
    AutoKill = false, FireDelay = 100,
    SilentAim = false, POV = 100, ShowPOV = false,
    POVColor = Color3.fromRGB(255, 255, 255),
    SnapLine = true, SnapLineColor = Color3.fromRGB(0, 255, 0),
    TeamCheck = true, WallCheck = true,

    ESP_LinePlayer = false, ESP_LineBOT = false,
    ESP_Name = false, ESP_Health = false,
    ESP_Distance = false, ESP_Box = false,
    LinePlayerColor = Color3.fromRGB(0, 255, 0),
    LineBOTColor = Color3.fromRGB(255, 255, 0),
    TextColor = Color3.fromRGB(255, 255, 255),
    BoxColor = Color3.fromRGB(255, 0, 0),

    AutoFarm = false, AutoCollect = false,

    WalkSpeed = 16, JumpPower = 50,
    Noclip = false, Fly = false, FlySpeed = 50,

    TPBehind = false, TPDistance = 4,
    TPAutoShoot = true, TPCooldown = 1,

    InfinityMoney = false, InfinityRuby = false,
    MoneyMultiplier = 1000,

    AntiKick = true,
}

-- ═══════════════ STATE ═══════════════
local lastShot = 0
local lastTP = 0
local targetIndex = 1
local flyBV, flyBG
local aimTarget = nil
local espData = {}
local botEspData = {}
local uiRefs = {}  -- FIX: simpan referensi toggle buat sinkron keybind

-- ═══════════════ HELPERS ═══════════════
local function getBlaster()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("Blaster") or char:FindFirstChildOfClass("Tool")
end

local function isSameTeam(player)
    if not C.TeamCheck then return false end
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function isVisible(part)
    if not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ig = {}
    if LocalPlayer.Character then table.insert(ig, LocalPlayer.Character) end
    table.insert(ig, Camera)
    params.FilterDescendantsInstances = ig
    local r = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    if not r then return true end
    return r.Instance == part or r.Instance:IsDescendantOf(part.Parent)
end

local function fovToRadius(fov)
    return math.tan(math.rad(fov / 2)) * (Camera.ViewportSize.Y / 2)
end

local function getBotFolder()
    local gameFolder = Workspace:FindFirstChild("Game")
    if gameFolder then
        return gameFolder:FindFirstChild("__ServerBotCharacters")
    end
    return nil
end

local function getAimPart(model)
    if not model then return nil end
    return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

-- FIX #1: Auto-update Camera reference
task.spawn(function()
    while task.wait(1) do
        if Camera ~= Workspace.CurrentCamera then
            Camera = Workspace.CurrentCamera
        end
    end
end)

-- ═══════════════ TARGETS ═══════════════
local function getAllTargets()
    local targets, seen = {}, {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not isSameTeam(player) then
                local h = player.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 and not seen[h] then
                    seen[h] = true
                    table.insert(targets, h)
                end
            end
        end
    end
    local botFolder = getBotFolder()
    if botFolder then
        for _, botChar in ipairs(botFolder:GetChildren()) do
            local h = botChar:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not seen[h] then
                seen[h] = true
                table.insert(targets, h)
            end
        end
    end
    return targets
end

-- ═══════════════ AUTO KILL ═══════════════
local function tagEveryone()
    if not Shoot then return end
    local blaster = getBlaster()
    if not blaster then return end
    local targets = getAllTargets()
    if #targets == 0 then return end
    if targetIndex > #targets then targetIndex = 1 end
    local currentTarget = targets[targetIndex]
    targetIndex += 1
    pcall(function()
        Shoot:FireServer(
            Workspace:GetServerTimeNow(),
            blaster,
            Camera.CFrame,
            { ["1"] = currentTarget },
            { ["1"] = true },
            { isQuickscope = false, isNoscope = true }
        )
    end)
end

local function killAll()
    if not Shoot then return end
    local blaster = getBlaster()
    if not blaster then return end
    local targets = getAllTargets()
    local count = 0
    for _, target in ipairs(targets) do
        if count >= 30 then break end
        if target and target.Parent and target.Health > 0 then
            pcall(function()
                Shoot:FireServer(
                    Workspace:GetServerTimeNow(),
                    blaster,
                    Camera.CFrame,
                    { ["1"] = target },
                    { ["1"] = true },
                    { isQuickscope = false, isNoscope = true }
                )
            end)
            count = count + 1
        end
        task.wait(0.05)
    end
end

-- ═══════════════ SILENT AIM ═══════════════
local function getClosestTarget()
    if not C.SilentAim then return nil end
    local bestPos, bestDist = nil, C.POV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not isSameTeam(player) then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local part = getAimPart(player.Character)
                if hum and hum.Health > 0 and part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestDist then
                            if not C.WallCheck or isVisible(part) then
                                bestDist = d
                                bestPos = part.Position
                            end
                        end
                    end
                end
            end
        end
    end

    local botFolder = getBotFolder()
    if botFolder then
        for _, botChar in ipairs(botFolder:GetChildren()) do
            local hum = botChar:FindFirstChildOfClass("Humanoid")
            local part = getAimPart(botChar)
            if hum and hum.Health > 0 and part then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then
                        if not C.WallCheck or isVisible(part) then
                            bestDist = d
                            bestPos = part.Position
                        end
                    end
                end
            end
        end
    end
    return bestPos
end

-- ═══════════════ UNIFIED HOOK ═══════════════
local shopKeywords = {"money", "cash", "ruby", "gem", "diamond", "coin", "reward", "credit"}

if hasHook then
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall

        if not oldNamecall._renxxUnified then
            local nf = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method then method = method:lower() end
                local args = {...}

                -- 1. SILENT AIM (raycast)
                if C.SilentAim and aimTarget and method == "raycast" and typeof(self) == "Instance" and self.Name == "Workspace" then
                    local originalDir = args[2]
                    local originalLength = 200
                    if typeof(originalDir) == "Vector3" then
                        originalLength = originalDir.Magnitude
                        if originalLength < 1 then originalLength = 200 end
                    end
                    args[2] = (aimTarget - Camera.CFrame.Position).Unit * originalLength
                    return oldNamecall(self, table.unpack(args))
                end

                -- 2. ANTI KICK
                if method == "kick" and self == LocalPlayer then
                    if C.AntiKick then return nil end
                end

                -- 3. SHOP MULTIPLIER (FIX #2: range 10-999999)
                if (C.InfinityMoney or C.InfinityRuby) then
                    if method == "fireserver" or method == "invokeserver" then
                        if typeof(self) == "Instance" then
                            local rn = self.Name:lower()
                            local isShopRemote = false
                            for _, kw in ipairs(shopKeywords) do
                                if rn:find(kw) then
                                    isShopRemote = true
                                    break
                                end
                            end
                            if isShopRemote then
                                -- Cari angka di range 10-999999 (skip ID kecil & timestamp)
                                local targetIdx = nil
                                for i, v in ipairs(args) do
                                    if type(v) == "number" and v >= 10 and v < 999999 then
                                        targetIdx = i
                                        break
                                    end
                                end
                                if targetIdx then
                                    local newVal = math.floor(args[targetIdx] * C.MoneyMultiplier)
                                    if newVal > 999999999 then newVal = 999999999 end
                                    args[targetIdx] = newVal
                                end

                                local key = self.Name
                                local tbl = (getgenv and getgenv()._renxxShopPrinted) or {}
                                if not tbl[key] or os.clock() - tbl[key] > 3 then
                                    tbl[key] = os.clock()
                                    if getgenv then getgenv()._renxxShopPrinted = tbl end
                                    print("[SHOP] Multiplied: " .. self.Name .. " (x" .. C.MoneyMultiplier .. ")")
                                end
                            end
                        end
                    end
                end

                return oldNamecall(self, table.unpack(args))
            end)
            nf._renxxUnified = true
            mt.__namecall = nf
        end
        setreadonly(mt, true)
        print("[RENXX v4.7] Unified hook: AKTIF")
    end)
end

-- ═══════════════ INFINITY MONEY/RUBY ═══════════════
local moneyValues = {}
local rubyValues = {}

local function scanMoneyRuby()
    moneyValues, rubyValues = {}, {}

    local function checkObj(obj)
        pcall(function()
            local n = obj.Name:lower()
            if obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("StringValue") then
                if n:find("money") or n:find("cash") or n:find("coin") then
                    table.insert(moneyValues, obj)
                end
                if n:find("ruby") or n:find("gem") or n:find("diamond") then
                    table.insert(rubyValues, obj)
                end
            end
        end)
    end

    for _, obj in ipairs(LocalPlayer:GetDescendants()) do checkObj(obj) end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, obj in ipairs(leaderstats:GetChildren()) do checkObj(obj) end
    end

    local count = 0
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if count > 500 then break end
        checkObj(obj)
        count = count + 1
    end

    return #moneyValues, #rubyValues
end

local function setInfinityMoney()
    for _, v in ipairs(moneyValues) do
        pcall(function()
            if v:IsA("StringValue") then
                local num = tonumber(v.Value)
                if num then v.Value = "999999999" end
            else
                v.Value = 999999999
            end
        end)
    end
end

local function setInfinityRuby()
    for _, v in ipairs(rubyValues) do
        pcall(function()
            if v:IsA("StringValue") then
                local num = tonumber(v.Value)
                if num then v.Value = "999999999" end
            else
                v.Value = 999999999
            end
        end)
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if C.InfinityMoney then setInfinityMoney() end
        if C.InfinityRuby then setInfinityRuby() end
    end
end)

-- ═══════════════ AUTO COLLECT ═══════════════
task.spawn(function()
    while task.wait(0.3) do
        if C.AutoCollect and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    pcall(function()
                        local n = obj.Name:lower()
                        if obj:IsA("BasePart") and (n:find("coin") or n:find("money") or n:find("cash") or n:find("pickup") or n:find("drop")) then
                            local dist = (obj.Position - hrp.Position).Magnitude
                            if dist < 20 then
                                hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                            end
                        end
                    end)
                end
            end
        end
    end
end)

-- ═══════════════ ESP ═══════════════
local function createESP(container, key)
    if not hasDrawing then return end
    if container[key] then return end
    container[key] = {
        Line = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Box = Drawing.new("Square"),
    }
    local d = container[key]
    d.Line.Thickness = 1
    d.Line.Visible = false
    d.Name.Size = 14
    d.Name.Center = true
    d.Name.Outline = true
    d.Name.Font = 2
    d.Name.Visible = false
    d.Distance.Size = 12
    d.Distance.Center = true
    d.Distance.Outline = true
    d.Distance.Font = 2
    d.Distance.Visible = false
    d.HealthBG.Filled = true
    d.HealthBG.Color = Color3.fromRGB(0, 0, 0)
    d.HealthBG.Visible = false
    d.HealthBar.Filled = true
    d.HealthBar.Visible = false
    d.Box.Thickness = 1
    d.Box.Filled = false
    d.Box.Visible = false
end

local function destroyESP(container, key)
    if container[key] then
        for _, obj in pairs(container[key]) do
            pcall(function() obj:Remove() end)
        end
        container[key] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(espData, player) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createESP(espData, p) end end)
Players.PlayerRemoving:Connect(function(p) destroyESP(espData, p) end)

-- ═══════════════ BOT ESP ═══════════════
local botBound = false
local botConns = {}
local botHealthConns = {}

local function bindBotESP(botChar)
    createESP(botEspData, botChar)
    local hum = botChar:FindFirstChildOfClass("Humanoid")
    if hum then
        local conn
        conn = hum.HealthChanged:Connect(function(hp)
            if hp <= 0 then
                task.wait(0.5)
                destroyESP(botEspData, botChar)
                if conn then conn:Disconnect() end
                botHealthConns[botChar] = nil
            end
        end)
        botHealthConns[botChar] = conn
    end
end

local function unbindBotESP(botChar)
    destroyESP(botEspData, botChar)
    if botHealthConns[botChar] then
        pcall(function() botHealthConns[botChar]:Disconnect() end)
        botHealthConns[botChar] = nil
    end
end

task.spawn(function()
    while task.wait(2) do
        local botFolder = getBotFolder()
        if botFolder and not botBound then
            botBound = true
            for _, botChar in ipairs(botFolder:GetChildren()) do
                bindBotESP(botChar)
            end
            table.insert(botConns, botFolder.ChildAdded:Connect(function(botChar)
                task.wait(0.2)
                bindBotESP(botChar)
            end))
            table.insert(botConns, botFolder.ChildRemoved:Connect(function(botChar)
                unbindBotESP(botChar)
            end))
            print("[RENXX v4.7] BOT ESP bound")
        elseif not botFolder and botBound then
            botBound = false
            for _, c in ipairs(botConns) do
                pcall(function() c:Disconnect() end)
            end
            botConns = {}
            for botChar, _ in pairs(botEspData) do
                destroyESP(botEspData, botChar)
            end
            for botChar, c in pairs(botHealthConns) do
                pcall(function() c:Disconnect() end)
            end
            botHealthConns = {}
        end
    end
end)

-- ═══════════════ ESP RENDER ═══════════════
local function renderPlayerESP()
    for player, d in pairs(espData) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hum and hrp and hum.Health > 0) then
            for _, obj in pairs(d) do obj.Visible = false end
        else
            local sp, on = Camera:WorldToViewportPoint(hrp.Position)
            if on then
                if C.ESP_LinePlayer then
                    d.Line.Visible = true
                    d.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    d.Line.To = Vector2.new(sp.X, sp.Y)
                    d.Line.Color = C.LinePlayerColor
                else d.Line.Visible = false end

                if C.ESP_Name then
                    d.Name.Visible = true
                    d.Name.Text = player.Name
                    d.Name.Position = Vector2.new(sp.X, sp.Y - 50)
                    d.Name.Color = C.TextColor
                else d.Name.Visible = false end

                if C.ESP_Health then
                    local hp = hum.Health / hum.MaxHealth
                    d.HealthBG.Visible = true
                    d.HealthBG.Size = Vector2.new(4, 40)
                    d.HealthBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
                    d.HealthBar.Visible = true
                    d.HealthBar.Size = Vector2.new(4, 40 * hp)
                    d.HealthBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hp)))
                    d.HealthBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hp)
                else
                    d.HealthBG.Visible = false
                    d.HealthBar.Visible = false
                end

                if C.ESP_Distance then
                    local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                    d.Distance.Visible = true
                    d.Distance.Text = math.floor(dist) .. "m"
                    d.Distance.Position = Vector2.new(sp.X, sp.Y + 30)
                    d.Distance.Color = C.TextColor
                else d.Distance.Visible = false end

                if C.ESP_Box then
                    d.Box.Visible = true
                    d.Box.Size = Vector2.new(50, 80)
                    d.Box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                    d.Box.Color = C.BoxColor
                else d.Box.Visible = false end
            else
                for _, obj in pairs(d) do obj.Visible = false end
            end
        end
    end
end

-- FIX #3: Collect first, delete after
local function renderBotESP()
    local toRemove = {}
    for botChar, d in pairs(botEspData) do
        if not botChar.Parent then
            for _, obj in pairs(d) do obj.Visible = false end
            table.insert(toRemove, botChar)
        else
            local hrp = botChar:FindFirstChild("HumanoidRootPart")
            local hum = botChar:FindFirstChildOfClass("Humanoid")
            if not hrp then
                for _, obj in pairs(d) do obj.Visible = false end
            else
                local sp, on = Camera:WorldToViewportPoint(hrp.Position)
                if on then
                    if C.ESP_LineBOT then
                        d.Line.Visible = true
                        d.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        d.Line.To = Vector2.new(sp.X, sp.Y)
                        d.Line.Color = C.LineBOTColor
                    else d.Line.Visible = false end

                    if C.ESP_Name then
                        d.Name.Visible = true
                        d.Name.Text = botChar.Name .. " [BOT]"
                        d.Name.Position = Vector2.new(sp.X, sp.Y - 50)
                        d.Name.Color = C.TextColor
                    else d.Name.Visible = false end

                    if C.ESP_Health and hum then
                        local hp = hum.Health / hum.MaxHealth
                        d.HealthBG.Visible = true
                        d.HealthBG.Size = Vector2.new(4, 40)
                        d.HealthBG.Position = Vector2.new(sp.X - 35, sp.Y - 20)
                        d.HealthBar.Visible = true
                        d.HealthBar.Size = Vector2.new(4, 40 * hp)
                        d.HealthBar.Position = Vector2.new(sp.X - 35, sp.Y - 20 + (40 * (1 - hp)))
                        d.HealthBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hp)
                    else
                        d.HealthBG.Visible = false
                        d.HealthBar.Visible = false
                    end

                    if C.ESP_Distance then
                        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                        d.Distance.Visible = true
                        d.Distance.Text = math.floor(dist) .. "m"
                        d.Distance.Position = Vector2.new(sp.X, sp.Y + 30)
                        d.Distance.Color = C.TextColor
                    else d.Distance.Visible = false end

                    if C.ESP_Box then
                        d.Box.Visible = true
                        d.Box.Size = Vector2.new(50, 80)
                        d.Box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
                        d.Box.Color = C.BoxColor
                    else d.Box.Visible = false end
                else
                    for _, obj in pairs(d) do obj.Visible = false end
                end
            end
        end
    end
    -- Hapus setelah iterasi
    for _, botChar in ipairs(toRemove) do
        destroyESP(botEspData, botChar)
        if botHealthConns[botChar] then
            pcall(function() botHealthConns[botChar]:Disconnect() end)
            botHealthConns[botChar] = nil
        end
    end
end

local function updateESP()
    if not hasDrawing then return end
    renderPlayerESP()
    renderBotESP()
end

-- ═══════════════ POV + SNAP ═══════════════
local povCircle, snapLine
if hasDrawing then
    pcall(function()
        povCircle = Drawing.new("Circle")
        povCircle.Thickness = 2
        povCircle.NumSides = 64
        povCircle.Filled = false
        povCircle.Visible = false
        snapLine = Drawing.new("Line")
        snapLine.Thickness = 2
        snapLine.Visible = false
    end)
end

-- ═══════════════ PLAYER FUNCTIONS ═══════════════
local function applyMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = C.WalkSpeed
        if hum.UseJumpPower then
            hum.JumpPower = C.JumpPower
        else
            hum.JumpHeight = C.JumpPower / 7.5
        end
    end
end

local function applyNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local function getMoveDirection()
    local camCF = Camera.CFrame
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
    if move.Magnitude > 0 then move = move.Unit * C.FlySpeed end
    return move
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.P = 1e5
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 1e5
    flyBG.CFrame = Camera.CFrame
    flyBG.Parent = root
end

local function stopFly()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    flyBV, flyBG = nil, nil
end

-- ═══════════════ TELEPORT BEHIND ═══════════════
local function teleportBehind(target)
    if not target or not target.Parent then return end
    local char = LocalPlayer.Character
    if not char then return end
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    local enemyHRP = target.Parent:FindFirstChild("HumanoidRootPart")
    if not myHRP or not enemyHRP then return end
    local enemyLook = enemyHRP.CFrame.LookVector
    local behindPos = enemyHRP.Position - (enemyLook * C.TPDistance)
    local behindCF = CFrame.new(behindPos, enemyHRP.Position)
    myHRP.CFrame = behindCF
    Camera.CFrame = behindCF
    if C.TPAutoShoot then
        task.wait(0.05)
        tagEveryone()
    end
end

-- ═══════════════ MAIN LOOP ═══════════════
RunService.Heartbeat:Connect(function()
    if C.AutoKill or C.AutoFarm then
        if os.clock() - lastShot >= (C.FireDelay / 1000) then
            tagEveryone()
            lastShot = os.clock()
        end
    end

    if C.TPBehind then
        if os.clock() - lastTP >= C.TPCooldown then
            local targets = getAllTargets()
            if #targets > 0 then
                teleportBehind(targets[math.random(1, #targets)])
                lastTP = os.clock()
            end
        end
    end

    if C.SilentAim then
        aimTarget = getClosestTarget()
        if aimTarget and C.SnapLine and snapLine then
            local sp, on = Camera:WorldToViewportPoint(aimTarget)
            if on then
                snapLine.Visible = true
                snapLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                snapLine.To = Vector2.new(sp.X, sp.Y)
                snapLine.Color = C.SnapLineColor
            else snapLine.Visible = false end
        elseif snapLine then snapLine.Visible = false end

        if C.ShowPOV and povCircle then
            povCircle.Visible = true
            povCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            povCircle.Radius = fovToRadius(C.POV)
            povCircle.Color = C.POVColor
        elseif povCircle then povCircle.Visible = false end
    else
        aimTarget = nil
        if snapLine then snapLine.Visible = false end
        if povCircle then povCircle.Visible = false end
    end

    applyMovement()
    if C.Noclip then applyNoclip() end

    if C.Fly and flyBV and flyBV.Parent then
        flyBV.Velocity = getMoveDirection()
        if flyBG and flyBG.Parent then flyBG.CFrame = Camera.CFrame end
    end
end)

RunService.RenderStepped:Connect(updateESP)

-- ═══════════════ ORION UI ═══════════════
local Window = OrionLib:MakeWindow({
    Name = "AIMBOT FPS v4.7 | By RENXX",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "RENXX HUB Loading...",
    IntroIcon = "rbxassetid://4483345998",
})

-- COMBAT
local CombatTab = Window:MakeTab({Name = "⚔️ COMBAT", Icon = "rbxassetid://4483345998"})
CombatTab:AddSection({Name = "AUTO KILL"})
CombatTab:AddToggle({Name = "Auto Kill", Default = false, Callback = function(v) C.AutoKill = v end})
CombatTab:AddSlider({Name = "Fire Delay (ms)", Min = 5, Max = 500, Default = 100, Callback = function(v) C.FireDelay = v end})
CombatTab:AddSection({Name = "SILENT AIM"})
CombatTab:AddToggle({Name = "Silent Aim", Default = false, Callback = function(v) C.SilentAim = v end})
CombatTab:AddSlider({Name = "POV (0-360°)", Min = 0, Max = 360, Default = 100, Callback = function(v) C.POV = v end})
CombatTab:AddToggle({Name = "Show POV", Default = false, Callback = function(v) C.ShowPOV = v end})
CombatTab:AddColorpicker({Name = "POV Color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) C.POVColor = c end})
CombatTab:AddToggle({Name = "Snap Line", Default = true, Callback = function(v) C.SnapLine = v end})
CombatTab:AddColorpicker({Name = "Snap Line Color", Default = Color3.fromRGB(0, 255, 0), Callback = function(c) C.SnapLineColor = c end})
CombatTab:AddToggle({Name = "Team Check", Default = true, Callback = function(v) C.TeamCheck = v end})
CombatTab:AddToggle({Name = "Wall Check", Default = true, Callback = function(v) C.WallCheck = v end})
CombatTab:AddSection({Name = "AKSI"})
CombatTab:AddButton({Name = "🔥 Kill All (Cap 30)", Callback = function()
    killAll()
    OrionLib:MakeNotification({Name = "Kill All", Content = "Killing all targets...", Time = 3})
end})

-- VISUAL
local VisualTab = Window:MakeTab({Name = "👁️ VISUAL", Icon = "rbxassetid://4483345998"})
VisualTab:AddSection({Name = "ESP FEATURES"})
VisualTab:AddToggle({Name = "ESP Line Player", Default = false, Callback = function(v) C.ESP_LinePlayer = v end})
VisualTab:AddToggle({Name = "ESP Line BOT", Default = false, Callback = function(v) C.ESP_LineBOT = v end})
VisualTab:AddToggle({Name = "ESP Name", Default = false, Callback = function(v) C.ESP_Name = v end})
VisualTab:AddToggle({Name = "ESP Health", Default = false, Callback = function(v) C.ESP_Health = v end})
VisualTab:AddToggle({Name = "ESP Distance", Default = false, Callback = function(v) C.ESP_Distance = v end})
VisualTab:AddToggle({Name = "ESP Box", Default = false, Callback = function(v) C.ESP_Box = v end})
VisualTab:AddSection({Name = "COLORS"})
VisualTab:AddColorpicker({Name = "Line Player Color", Default = Color3.fromRGB(0, 255, 0), Callback = function(c) C.LinePlayerColor = c end})
VisualTab:AddColorpicker({Name = "Line BOT Color", Default = Color3.fromRGB(255, 255, 0), Callback = function(c) C.LineBOTColor = c end})
VisualTab:AddColorpicker({Name = "Text Color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) C.TextColor = c end})
VisualTab:AddColorpicker({Name = "Box Color", Default = Color3.fromRGB(255, 0, 0), Callback = function(c) C.BoxColor = c end})

-- FARM
local FarmTab = Window:MakeTab({Name = "💰 FARM", Icon = "rbxassetid://4483345998"})
FarmTab:AddSection({Name = "AUTO FARM"})
FarmTab:AddToggle({Name = "Auto Farm (Kill Bot)", Default = false, Callback = function(v) C.AutoFarm = v end})
FarmTab:AddToggle({Name = "Auto Collect Money", Default = false, Callback = function(v) C.AutoCollect = v end})
FarmTab:AddSection({Name = "AKSI"})
FarmTab:AddButton({Name = "💰 Farm 10 Detik", Callback = function()
    C.AutoFarm = true
    task.wait(10)
    C.AutoFarm = false
end})

-- PLAYER
local PlayerTab = Window:MakeTab({Name = "🏃 PLAYER", Icon = "rbxassetid://4483345998"})
PlayerTab:AddSection({Name = "MOVEMENT"})
PlayerTab:AddSlider({Name = "WalkSpeed", Min = 16, Max = 500, Default = 16, Callback = function(v) C.WalkSpeed = v end})
PlayerTab:AddSlider({Name = "Jump Power", Min = 50, Max = 500, Default = 50, Callback = function(v) C.JumpPower = v end})
PlayerTab:AddToggle({Name = "Noclip", Default = false, Callback = function(v) C.Noclip = v end})
PlayerTab:AddSection({Name = "FLY"})
-- FIX #4: Simpan referensi toggle buat sinkron keybind
PlayerTab:AddToggle({Name = "Fly", Default = false, Callback = function(v)
    C.Fly = v
    if v then startFly() else stopFly() end
end})
PlayerTab:AddSlider({Name = "Fly Speed", Min = 10, Max = 500, Default = 50, Callback = function(v) C.FlySpeed = v end})

-- TELEPORT
local TPTab = Window:MakeTab({Name = "🎯 TELEPORT", Icon = "rbxassetid://4483345998"})
TPTab:AddSection({Name = "TELEPORT BEHIND"})
TPTab:AddToggle({Name = "Enable Teleport Behind", Default = false, Callback = function(v) C.TPBehind = v end})
TPTab:AddSlider({Name = "Distance Behind (stud)", Min = 2, Max = 20, Default = 4, Callback = function(v) C.TPDistance = v end})
TPTab:AddToggle({Name = "Auto Shoot After TP", Default = true, Callback = function(v) C.TPAutoShoot = v end})
TPTab:AddSlider({Name = "Cooldown (detik)", Min = 0, Max = 5, Default = 1, Callback = function(v) C.TPCooldown = v end})
TPTab:AddSection({Name = "AKSI"})
TPTab:AddButton({Name = "🎯 Teleport ke Musuh Terdekat", Callback = function()
    local targets = getAllTargets()
    if #targets > 0 then teleportBehind(targets[1]) end
end})

-- SHOP
local ShopTab = Window:MakeTab({Name = "💎 SHOP", Icon = "rbxassetid://4483345998"})
ShopTab:AddSection({Name = "SCAN"})
ShopTab:AddButton({Name = "🔍 Scan Money/Ruby Value", Callback = function()
    local m, r = scanMoneyRuby()
    OrionLib:MakeNotification({
        Name = "SCAN DONE",
        Content = "Money Values: " .. m .. " | Ruby Values: " .. r,
        Time = 6
    })
end})
ShopTab:AddSection({Name = "MONEY"})
ShopTab:AddToggle({Name = "Infinity Money", Default = false, Callback = function(v)
    C.InfinityMoney = v
    if v then
        scanMoneyRuby()
        setInfinityMoney()
    end
end})
ShopTab:AddSlider({Name = "Money Multiplier (x)", Min = 1, Max = 10000, Default = 1000, Callback = function(v) C.MoneyMultiplier = v end})
ShopTab:AddSection({Name = "RUBY"})
ShopTab:AddToggle({Name = "Infinity Ruby", Default = false, Callback = function(v)
    C.InfinityRuby = v
    if v then
        scanMoneyRuby()
        setInfinityRuby()
    end
end})
ShopTab:AddSection({Name = "INFO"})
ShopTab:AddParagraph({Title = "Cara Pakai", Content = "1. Klik Scan dulu\n2. Aktifin Infinity Money/Ruby\n3. Kill bot / buka peti\n4. Money dikali otomatis (x1000)"})

-- SETTING
local SetTab = Window:MakeTab({Name = "⚙️ SETTING", Icon = "rbxassetid://4483345998"})
SetTab:AddSection({Name = "PROTECTION"})
SetTab:AddToggle({Name = "Anti-Kick", Default = true, Callback = function(v) C.AntiKick = v end})
SetTab:AddSection({Name = "KEYBIND"})
SetTab:AddParagraph({Title = "Keybind", Content = "F = Toggle Auto Kill\nG = Toggle Fly\nT = Teleport Behind"})
SetTab:AddSection({Name = "INFO"})
SetTab:AddParagraph({Title = "AIMBOT FPS v4.7", Content = "By: RENXX\nDepy is God\nLibrary: Orion UI\nFINAL - No Bug"})

OrionLib:Init()

-- FIX #4: Keybind G hapus (biar nggak bentrok sama UI)
-- Pake keybind F & T aja
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        C.AutoKill = not C.AutoKill
    elseif input.KeyCode == Enum.KeyCode.T then
        local targets = getAllTargets()
        if #targets > 0 then teleportBehind(targets[1]) end
    end
end)

-- FIX #7: Auto-stop fly pas mati
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    flyBV, flyBG = nil, nil
    if C.Fly then
        startFly()
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    -- Stop fly pas karakter ilang
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    flyBV, flyBG = nil, nil
end)

OrionLib:MakeNotification({
    Name = "AIMBOT FPS v4.7 FINAL",
    Content = "Script loaded! FINAL - No Bug. By RENXX | Depy is God",
    Image = "rbxassetid://4483345998",
    Time = 5,
})

print("═══════════════════════════════════════")
print("[AIMBOT FPS v4.7 FINAL] By RENXX - LOADED!")
print("DEPY IS GOOD")
print("All bugs fixed. Clean & Stable.")
print("═══════════════════════════════════════")
