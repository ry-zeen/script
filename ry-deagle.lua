-- =====================================================
--  RENXX HUB v6.0 | DEAGLE ARENA ULTIMATE
--  UI: Rayfield | Made by: Ren & Deep
--  Fitur: KillAll, AutoShoot, Wallbang, GunMods, ESP, Fly, TP, AutoCollect
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

DebugOK("Loading RENXX Hub v6.0...")

local successRay, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not successRay or not Rayfield then DebugErr("Gagal load Rayfield!") return end
DebugOK("Rayfield UI berhasil di-load.")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =====================================================
-- SETTINGS
-- =====================================================
getgenv().RENXX = getgenv().RENXX or {}
getgenv().RENXX.S = {
    -- Kill All
    KillAll = false, KillAllFireRateDelay = 0.04, PanicHealthThreshold = 40, KillAllTargetPart = "Head",
    -- Auto Shoot
    AutoShoot = false, Hitbox = "Head", FOV = 25, MaxDistance = 500,
    VisibleCheck = true, Wallbang = false, ShowFOV = true, ShowTarget = true,
    MinDelay = 0.02,
    -- Gun Mods
    AutoReload = true, AutoEquip = true, InstantReload = false, AutomaticGun = false,
    InfiniteAmmo = false, FireRateChanger = false, FireRate = 600,
    -- Team Check
    TeamCheck = true,
    -- ESP
    HighlightESP = false, ESPTeam = true, ESPThroughWalls = true, ESPMaxDistance = 1000,
    EnemyFill = Color3.fromRGB(255, 60, 60), EnemyOutline = Color3.fromRGB(255, 0, 0),
    DrawingESP = false, DrawingESPBox = false, DrawingESPName = false, DrawingESPTracers = false,
    -- Player
    GodMode = false, AntiKick = true, AntiAFK = false,
    SpeedEnabled = false, SpeedValue = 32,
    JumpEnabled = false, JumpValue = 50, InfJump = false,
    NoClip = false,
    FlyEnabled = false, FlySpeed = 50,
    -- Farm
    TPEnemy = false, TPTarget = "All Enemy", TPPosition = "Depan", TPDistance = 5, TPDelay = 0.5,
    AutoCollect = false, CollectRadius = 20,
}
local S = getgenv().RENXX.S

-- =====================================================
-- CORE REFERENCES
-- =====================================================
local DeagleController, DeagleShared = nil, nil
pcall(function()
    local PS = LocalPlayer:WaitForChild("PlayerScripts", 10)
    if PS then
        local ML = PS:WaitForChild("ModuleLoader", 10)
        if ML then
            DeagleController = require(ML:WaitForChild("DeagleController", 10))
            DebugOK("DeagleController: BERHASIL di-require!")
        end
    end
end)
if not DeagleController then DebugWarn("DeagleController: GAGAL di-require!") end

pcall(function()
    local Mods = ReplicatedStorage:WaitForChild("Modules", 10)
    if Mods then
        local Shared = Mods:WaitForChild("Shared", 10)
        if Shared then
            DeagleShared = require(Shared:WaitForChild("DeagleShared", 10))
            DebugOK("DeagleShared: BERHASIL di-require!")
        end
    end
end)
if not DeagleShared then DebugWarn("DeagleShared: GAGAL di-require!") end

-- =====================================================
-- ANTI-KICK
-- =====================================================
pcall(function()
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if m == "Kick" and S.AntiKick then return nil end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
    DebugOK("Anti-Kick aktif.")
end)

-- =====================================================
-- HELPERS
-- =====================================================
local function IsAlive(char)
    if not char or not char.Parent then return false end
    if char:GetAttribute("Alive") == false then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    return true
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

local function GetTargets()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
            if IsEnemy(p) then table.insert(list, p) end
        end
    end
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("IsBot") == true and IsAlive(m) then
            table.insert(list, {Name=m.Name, Character=m})
        end
    end
    return list
end

local function GetTargetPart(char, name)
    local p = char:FindFirstChild(name)
    if p and p:IsA("BasePart") then return p end
    if name == "UpperTorso" or name == "Torso" or name == "LowerTorso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function GetPredictedPosition(part)
    local char = part.Parent
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if root and root:IsA("BasePart") then
        return part.Position + (root.AssemblyLinearVelocity * ((LocalPlayer:GetNetworkPing() or 0.03) * 1.85))
    end
    return part.Position
end

local function IsVisible(origin, part, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    local res = workspace:Raycast(origin, part.Position - origin, params)
    return res == nil or res.Instance:IsDescendantOf(char)
end

-- =====================================================
-- FIRE FUNCTION
-- =====================================================
local function FireAt(target)
    if not target then return false end
    local part = target.part or GetTargetPart(target.Character or target, S.Hitbox)
    if not part then return false end
    local aimPos = GetPredictedPosition(part)
    
    if DeagleController then
        if typeof(DeagleController) == "table" then
            DeagleController.ShootCooldownUntil = 0
            DeagleController.CanShoot = true
            DeagleController.CurrentSpread = 0
            if DeagleController.WeaponStats then DeagleController.WeaponStats.Spread = 0 end
        end
        local ok = pcall(function()
            if typeof(DeagleController.Shoot) == "function" then DeagleController.Shoot(aimPos)
            elseif typeof(DeagleController.Fire) == "function" then DeagleController.Fire(aimPos) end
        end)
        if ok then return true end
    end
    return false
end

-- =====================================================
-- KILL ALL
-- =====================================================
local CurrentShotTargets = {}
local killCount = 0
local lastKillLog = 0

local function ExecuteKillAll()
    if not S.KillAll then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    local myHum = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
    if not myChar or not myRoot or not myHum or not DeagleController then return end
    
    local isVuln = (myHum.Health / myHum.MaxHealth * 100) <= S.PanicHealthThreshold
    table.clear(CurrentShotTargets)
    
    local targets = GetTargets()
    table.sort(targets, function(a,b)
        local ra = (a.Character or a):FindFirstChild("HumanoidRootPart") or (a.Character or a):FindFirstChild("Torso")
        local rb = (b.Character or b):FindFirstChild("HumanoidRootPart") or (b.Character or b):FindFirstChild("Torso")
        if ra and rb then return (myRoot.Position - ra.Position).Magnitude < (myRoot.Position - rb.Position).Magnitude end
        return false
    end)
    
    if isVuln then
        for _, t in ipairs(targets) do
            local char = t.Character or t
            local part = GetTargetPart(char, S.KillAllTargetPart)
            if part and IsVisible(myRoot.Position, part, char) then
                CurrentShotTargets[part] = true
                if FireAt({part=part, Character=char}) then killCount = killCount + 1 end
                break
            end
        end
    else
        for _, t in ipairs(targets) do
            local char = t.Character or t
            local part = GetTargetPart(char, S.KillAllTargetPart)
            if part then
                CurrentShotTargets[part] = true
                if FireAt({part=part, Character=char}) then killCount = killCount + 1 end
            end
        end
    end
    
    if os.clock() - lastKillLog > 5 then
        lastKillLog = os.clock()
        if killCount > 0 then DebugOK("Kill All: " .. killCount .. " tembakan | Target: " .. #targets) end
    end
end

-- =====================================================
-- AUTO SHOOT
-- =====================================================
local function FindBestTarget()
    local origin = Camera.CFrame.Position
    local look = Camera.CFrame.LookVector
    local maxAngle = S.FOV / 2
    local best, bestAng = nil, maxAngle
    for _, t in ipairs(GetTargets()) do
        local char = t.Character or t
        local part = GetTargetPart(char, S.Hitbox)
        if part then
            local pos = part.Position
            local dist = (pos - origin).Magnitude
            if dist <= S.MaxDistance then
                local dir = (pos - origin).Unit
                local ang = math.deg(math.acos(math.clamp(look:Dot(dir), -1, 1)))
                if ang <= maxAngle then
                    if (not S.VisibleCheck) or IsVisible(origin, part, char) or S.Wallbang then
                        if ang < bestAng then best, bestAng = {part=part, Character=char}, ang end
                    end
                end
            end
        end
    end
    return best
end

local lastShot = 0
local function ExecuteAutoShoot()
    if not S.AutoShoot or S.KillAll then return end
    local now = os.clock()
    if now - lastShot < S.MinDelay then return end
    local target = FindBestTarget()
    if target then
        if FireAt(target) then lastShot = now end
    end
end

-- =====================================================
-- GUN MODS
-- =====================================================
local origRate, origFM = {}, {}
local function ApplyGunMods()
    local char = LocalPlayer.Character
    if not char then return end
    local blaster = char:FindFirstChildWhichIsA("Tool")
    if not blaster and S.AutoEquip then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") then char:FindFirstChildOfClass("Humanoid"):EquipTool(item) blaster = item break end
            end
        end
    end
    if blaster then
        if S.InfiniteAmmo then blaster:SetAttribute("_ammo", blaster:GetAttribute("magazineSize") or 999) end
        if S.InstantReload then blaster:SetAttribute("reloadTime", 0) end
        if S.FireRateChanger then
            if not origRate[blaster] then origRate[blaster] = blaster:GetAttribute("rateOfFire") end
            blaster:SetAttribute("rateOfFire", S.FireRate)
        elseif origRate[blaster] then
            blaster:SetAttribute("rateOfFire", origRate[blaster]) origRate[blaster] = nil
        end
        if S.AutomaticGun then
            if not origFM[blaster] then origFM[blaster] = blaster:GetAttribute("fireMode") end
            blaster:SetAttribute("fireMode", "Auto")
        elseif origFM[blaster] then
            blaster:SetAttribute("fireMode", origFM[blaster]) origFM[blaster] = nil
        end
    end
end

-- =====================================================
-- ESP (Highlight)
-- =====================================================
local espObjects = {}
local function UpdateESP()
    if not S.HighlightESP then
        for p, h in pairs(espObjects) do pcall(function() h:Destroy() end) espObjects[p] = nil end
        return
    end
    local origin = Camera.CFrame.Position
    local depth = S.ESPThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local valid = char and hum and hum.Health > 0
            if valid and S.ESPTeam and not IsEnemy(p) then valid = false end
            if valid then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - origin).Magnitude > S.ESPMaxDistance then valid = false end
            end
            local h = espObjects[p]
            if valid then
                if not h or h.Parent ~= char then
                    if h then pcall(function() h:Destroy() end) end
                    h = Instance.new("Highlight")
                    h.Name = "RENXX_ESP" h.Adornee = char h.Parent = char
                    espObjects[p] = h
                end
                h.FillColor = S.EnemyFill h.FillTransparency = 0.5
                h.OutlineColor = S.EnemyOutline h.OutlineTransparency = 0
                h.DepthMode = depth
            elseif h then
                pcall(function() h:Destroy() end) espObjects[p] = nil
            end
        end
    end
end

-- =====================================================
-- DRAWING ESP
-- =====================================================
local Drawing = Drawing
local drawCache = {}
local function UpdateDrawingESP()
    if not Drawing then return end
    if not S.DrawingESP then
        for _, o in pairs(drawCache) do for _, d in pairs(o) do pcall(function() d:Remove() end) end end
        drawCache = {}
        return
    end
    local active = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
            if not (S.ESPTeam and not IsEnemy(p)) then
                local char = p.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    active[char] = true
                    if not drawCache[char] then
                        drawCache[char] = {
                            box = Drawing.new("Square"), box.T = 1 box.Filled = false box.Visible = false,
                            name = Drawing.new("Text"), 
                            tracer = Drawing.new("Line")
                        }
                        local o = drawCache[char]
                        o.box.Thickness = 1 o.box.Filled = false o.box.Visible = false
                        o.name.Size = 14 o.name.Center = true o.name.Outline = true o.name.OutlineColor = Color3.new(0,0,0) o.name.Visible = false
                        o.tracer.Thickness = 1 o.tracer.Visible = false
                    end
                    local o = drawCache[char]
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen and pos.Z > 0 then
                        local topS = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,3,0))
                        local botS = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
                        local h = math.abs(topS.Y - botS.Y)
                        local w = h * 0.5
                        local x = pos.X - w / 2
                        local y = topS.Y
                        if S.DrawingESPBox then
                            o.box.Visible = true o.box.Size = Vector2.new(w,h) o.box.Position = Vector2.new(x,y)
                            o.box.Color = S.EnemyOutline
                        else o.box.Visible = false end
                        if S.DrawingESPName then
                            o.name.Visible = true o.name.Text = p.DisplayName o.name.Position = Vector2.new(pos.X, y-18)
                            o.name.Color = S.EnemyOutline
                        else o.name.Visible = false end
                        if S.DrawingESPTracers then
                            o.tracer.Visible = true
                            o.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            o.tracer.To = Vector2.new(pos.X, y+h)
                            o.tracer.Color = S.EnemyOutline
                        else o.tracer.Visible = false end
                    else
                        o.box.Visible = false o.name.Visible = false o.tracer.Visible = false
                    end
                end
            end
        end
    end
    for char, o in pairs(drawCache) do
        if not active[char] then
            for _, d in pairs(o) do pcall(function() d:Remove() end) end
            drawCache[char] = nil
        end
    end
end

-- =====================================================
-- MOVEMENT & FLY
-- =====================================================
local flyBV, flyConn
local function ToggleFly(state)
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    ContextActionService:UnbindAction("RENXX_Up")
    ContextActionService:UnbindAction("RENXX_Down")
    if state then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.new(0,0,0)
        flyBV.Parent = hrp
        local function handleFly(action, state)
            if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then return end
            if not flyBV or not flyBV.Parent then return end
            local spd = S.FlySpeed
            if action == "RENXX_Up" then flyBV.Velocity = Vector3.new(flyBV.Velocity.X, spd, flyBV.Velocity.Z)
            elseif action == "RENXX_Down" then flyBV.Velocity = Vector3.new(flyBV.Velocity.X, -spd, flyBV.Velocity.Z) end
        end
        ContextActionService:BindAction("RENXX_Up", handleFly, true, Enum.KeyCode.Space)
        ContextActionService:SetTitle("RENXX_Up", "⬆ FLY")
        ContextActionService:SetPosition("RENXX_Up", UDim2.new(0.75, 0, 0.4, 0))
        ContextActionService:BindAction("RENXX_Down", handleFly, true, Enum.KeyCode.LeftControl)
        ContextActionService:SetTitle("RENXX_Down", "⬇ FLY")
        ContextActionService:SetPosition("RENXX_Down", UDim2.new(0.75, 0, 0.55, 0))
        flyConn = RunService.RenderStepped:Connect(function()
            if not flyBV or not flyBV.Parent then return end
            local c = LocalPlayer.Character
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            flyBV.Velocity = Vector3.new(hum.MoveDirection.X * S.FlySpeed, flyBV.Velocity.Y, hum.MoveDirection.Z * S.FlySpeed)
        end)
        DebugOK("Fly ON!")
    end
end

-- =====================================================
-- MAIN LOOP
-- =====================================================
task.spawn(function()
    while task.wait(0.02) do
        pcall(UpdateESP)
        pcall(UpdateDrawingESP)
        pcall(ApplyGunMods)
        pcall(ExecuteKillAll)
        pcall(ExecuteAutoShoot)
    end
end)

-- Speed/Jump/NoClip
task.spawn(function()
    while task.wait(0.2) do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = S.SpeedEnabled and S.SpeedValue or 16
                hum.UseJumpPower = true
                hum.JumpPower = S.JumpEnabled and S.JumpValue or 50
            end
            if S.NoClip then
                for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            end
            if S.GodMode then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then h.MaxHealth = math.huge h.Health = math.huge end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if S.InfJump and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.Idled:Connect(function()
    if S.AntiAFK then VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end
end)

-- =====================================================
-- TP & AUTO COLLECT
-- =====================================================
task.spawn(function()
    while true do
        task.wait(S.TPDelay)
        if S.TPEnemy then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local enemies = {}
                if S.TPTarget == "All Enemy" or S.TPTarget == "Player Enemy" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) and IsEnemy(p) then
                            local r = p.Character:FindFirstChild("HumanoidRootPart")
                            if r then table.insert(enemies, r) end
                        end
                    end
                end
                local closest, cd = nil, math.huge
                for _, e in ipairs(enemies) do
                    local d = (e.Position - hrp.Position).Magnitude
                    if d < cd then cd = d closest = e end
                end
                if closest then
                    local off = Vector3.new(0,0,0)
                    local pt = S.TPPosition
                    if pt == "Atas" then off = Vector3.new(0, S.TPDistance, 0)
                    elseif pt == "Bawah" then off = Vector3.new(0, -S.TPDistance, 0)
                    elseif pt == "Depan" then off = closest.CFrame.LookVector * S.TPDistance
                    elseif pt == "Belakang" then off = -closest.CFrame.LookVector * S.TPDistance end
                    hrp.CFrame = CFrame.new(closest.Position + off)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if S.AutoCollect then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local myPos = hrp.Position
                local r = S.CollectRadius
                local names = {"coin","cash","money","item","drop","pickup","collect","crate","gem","reward"}
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local tp = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                        if tp then
                            local match = false
                            local low = string.lower(obj.Name)
                            for _, n in ipairs(names) do if string.find(low, n) then match = true break end end
                            if match and (tp.Position - myPos).Magnitude <= r then
                                pcall(function()
                                    firetouchinterest(hrp, tp, 0)
                                    task.wait()
                                    firetouchinterest(hrp, tp, 1)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =====================================================
-- UI (RAYFIELD)
-- =====================================================
local Window = Rayfield:CreateWindow({
    Name = "RENXX Hub v6.0 | Deagle Arena",
    LoadingTitle = "RENXX Hub",
    LoadingSubtitle = "by Ren & Deep",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
})

-- COMBAT
local Combat = Window:CreateTab("Combat", 4483345998)
Combat:CreateSection("KILL ALL")
Combat:CreateToggle({Name = "Kill All (Auto Sweep)", CurrentValue = false, Flag = "KA", Callback = function(v) S.KillAll = v; if v then DebugWarn("KILL ALL ON!") else DebugOK("Kill All OFF") end end})
Combat:CreateSlider({Name = "Kill All Delay", Range = {0.01, 0.5}, Increment = 0.01, Suffix = "s", CurrentValue = 0.04, Flag = "KADelay", Callback = function(v) S.KillAllFireRateDelay = v end})
Combat:CreateSlider({Name = "Panic Health", Range = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = 40, Flag = "KAPanic", Callback = function(v) S.PanicHealthThreshold = v end})
Combat:CreateDropdown({Name = "Kill All Target", Options = {"Head","HumanoidRootPart","UpperTorso","Torso"}, CurrentOption = "Head", Flag = "KATarget", Callback = function(v) S.KillAllTargetPart = v end})

Combat:CreateSection("AUTO SHOOT")
Combat:CreateToggle({Name = "Auto Shoot", CurrentValue = false, Flag = "AS", Callback = function(v) S.AutoShoot = v; if v then DebugOK("Auto Shoot ON") end end})
Combat:CreateToggle({Name = "Wallbang", CurrentValue = false, Flag = "WB", Callback = function(v) S.Wallbang = v; if v then DebugWarn("Wallbang ON!") end end})
Combat:CreateToggle({Name = "Visible Check", CurrentValue = true, Flag = "VC", Callback = function(v) S.VisibleCheck = v end})
Combat:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "TC", Callback = function(v) S.TeamCheck = v end})
Combat:CreateDropdown({Name = "Hitbox", Options = {"Head","HumanoidRootPart","UpperTorso","Torso"}, CurrentOption = "Head", Flag = "HB", Callback = function(v) S.Hitbox = v end})
Combat:CreateSlider({Name = "FOV", Range = {1, 360}, Increment = 1, Suffix = "°", CurrentValue = 25, Flag = "FOV", Callback = function(v) S.FOV = v end})
Combat:CreateSlider({Name = "Max Distance", Range = {10, 2000}, Increment = 10, Suffix = " studs", CurrentValue = 500, Flag = "MD", Callback = function(v) S.MaxDistance = v end})
Combat:CreateSlider({Name = "Min Delay", Range = {0, 0.5}, Increment = 0.01, Suffix = "s", CurrentValue = 0.02, Flag = "MinD", Callback = function(v) S.MinDelay = v end})
Combat:CreateToggle({Name = "Show FOV Circle", CurrentValue = true, Flag = "SF", Callback = function(v) S.ShowFOV = v end})

-- WEAPON
local Weapon = Window:CreateTab("Weapon", 4483345998)
Weapon:CreateSection("GUN MODS")
Weapon:CreateToggle({Name = "Auto Reload", CurrentValue = true, Flag = "AR", Callback = function(v) S.AutoReload = v end})
Weapon:CreateToggle({Name = "Auto Equip", CurrentValue = true, Flag = "AE", Callback = function(v) S.AutoEquip = v end})
Weapon:CreateToggle({Name = "Instant Reload", CurrentValue = false, Flag = "IR", Callback = function(v) S.InstantReload = v end})
Weapon:CreateToggle({Name = "Automatic Gun", CurrentValue = false, Flag = "AG", Callback = function(v) S.AutomaticGun = v end})
Weapon:CreateToggle({Name = "Infinite Ammo", CurrentValue = false, Flag = "IA", Callback = function(v) S.InfiniteAmmo = v end})
Weapon:CreateToggle({Name = "Fire Rate Changer", CurrentValue = false, Flag = "FRC", Callback = function(v) S.FireRateChanger = v end})
Weapon:CreateSlider({Name = "Fire Rate", Range = {30, 3000}, Increment = 10, Suffix = " RPM", CurrentValue = 600, Flag = "FR", Callback = function(v) S.FireRate = v end})

-- VISUAL
local Visual = Window:CreateTab("Visual", 4483345998)
Visual:CreateSection("HIGHLIGHT ESP")
Visual:CreateToggle({Name = "Highlight ESP", CurrentValue = false, Flag = "HE", Callback = function(v) S.HighlightESP = v end})
Visual:CreateToggle({Name = "Hide Teammates", CurrentValue = true, Flag = "HT", Callback = function(v) S.ESPTeam = v end})
Visual:CreateToggle({Name = "Through Walls", CurrentValue = true, Flag = "TW", Callback = function(v) S.ESPThroughWalls = v end})
Visual:CreateSlider({Name = "ESP Max Distance", Range = {50, 5000}, Increment = 50, Suffix = " studs", CurrentValue = 1000, Flag = "EMD", Callback = function(v) S.ESPMaxDistance = v end})
Visual:CreateColorPicker({Name = "Enemy Fill", Color = Color3.fromRGB(255, 60, 60), Flag = "EF", Callback = function(c) S.EnemyFill = c end})
Visual:CreateColorPicker({Name = "Enemy Outline", Color = Color3.fromRGB(255, 0, 0), Flag = "EO", Callback = function(c) S.EnemyOutline = c end})

Visual:CreateSection("DRAWING ESP")
Visual:CreateToggle({Name = "Drawing ESP (Master)", CurrentValue = false, Flag = "DESP", Callback = function(v) S.DrawingESP = v; if v then DebugOK("Drawing ESP ON") end end})
Visual:CreateToggle({Name = "ESP Box", CurrentValue = false, Flag = "DEB", Callback = function(v) S.DrawingESPBox = v end})
Visual:CreateToggle({Name = "ESP Name", CurrentValue = false, Flag = "DEN", Callback = function(v) S.DrawingESPName = v end})
Visual:CreateToggle({Name = "ESP Tracers", CurrentValue = false, Flag = "DET", Callback = function(v) S.DrawingESPTracers = v end})

-- PLAYER
local PlayerTab = Window:CreateTab("Player", 4483345998)
PlayerTab:CreateSection("PROTECTION")
PlayerTab:CreateToggle({Name = "God Mode", CurrentValue = false, Flag = "GM", Callback = function(v) S.GodMode = v end})
PlayerTab:CreateToggle({Name = "Anti-Kick", CurrentValue = true, Flag = "AK", Callback = function(v) S.AntiKick = v end})
PlayerTab:CreateToggle({Name = "Anti-AFK", CurrentValue = false, Flag = "AA", Callback = function(v) S.AntiAFK = v end})

PlayerTab:CreateSection("MOVEMENT")
PlayerTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Flag = "SH", Callback = function(v) S.SpeedEnabled = v end})
PlayerTab:CreateSlider({Name = "Speed Value", Range = {16, 100}, Increment = 1, Suffix = " studs/s", CurrentValue = 32, Flag = "SV", Callback = function(v) S.SpeedValue = v end})
PlayerTab:CreateToggle({Name = "Jump Hack", CurrentValue = false, Flag = "JH", Callback = function(v) S.JumpEnabled = v end})
PlayerTab:CreateSlider({Name = "Jump Power", Range = {50, 100}, Increment = 1, Suffix = " power", CurrentValue = 50, Flag = "JV", Callback = function(v) S.JumpValue = v end})
PlayerTab:CreateToggle({Name = "Infinity Jump", CurrentValue = false, Flag = "IJ", Callback = function(v) S.InfJump = v end})
PlayerTab:CreateToggle({Name = "No Clip", CurrentValue = false, Flag = "NC", Callback = function(v) S.NoClip = v end})
PlayerTab:CreateToggle({Name = "Fly (Joystick + ⬆⬇)", CurrentValue = false, Flag = "FLY", Callback = function(v) S.FlyEnabled = v ToggleFly(v) end})
PlayerTab:CreateSlider({Name = "Fly Speed", Range = {16, 100}, Increment = 1, Suffix = " studs/s", CurrentValue = 50, Flag = "FS", Callback = function(v) S.FlySpeed = v end})

PlayerTab:CreateSection("FARM")
PlayerTab:CreateToggle({Name = "TP to Enemy", CurrentValue = false, Flag = "TPE", Callback = function(v) S.TPEnemy = v end})
PlayerTab:CreateDropdown({Name = "TP Target", Options = {"All Enemy","Player Enemy"}, CurrentOption = "All Enemy", Flag = "TPT", Callback = function(v) S.TPTarget = v end})
PlayerTab:CreateDropdown({Name = "TP Position", Options = {"Atas","Bawah","Depan","Belakang"}, CurrentOption = "Depan", Flag = "TPP", Callback = function(v) S.TPPosition = v end})
PlayerTab:CreateSlider({Name = "TP Distance", Range = {1, 50}, Increment = 1, Suffix = " studs", CurrentValue = 5, Flag = "TPD", Callback = function(v) S.TPDistance = v end})
PlayerTab:CreateSlider({Name = "TP Delay", Range = {0.1, 5}, Increment = 0.1, Suffix = "s", CurrentValue = 0.5, Flag = "TPDL", Callback = function(v) S.TPDelay = v end})
PlayerTab:CreateToggle({Name = "Auto Collect Coin", CurrentValue = false, Flag = "AC", Callback = function(v) S.AutoCollect = v; if v then DebugOK("Auto Collect ON") end end})
PlayerTab:CreateSlider({Name = "Collect Radius", Range = {5, 100}, Increment = 1, Suffix = " studs", CurrentValue = 20, Flag = "CR", Callback = function(v) S.CollectRadius = v end})

-- INFO
local Info = Window:CreateTab("Info", 4483345998)
Info:CreateSection("STATUS")
Info:CreateParagraph({Title = "DeagleController", Content = DeagleController and "BERHASIL di-require!" or "GAGAL di-require."})
Info:CreateParagraph({Title = "DeagleShared", Content = DeagleShared and "BERHASIL di-require!" or "GAGAL di-require."})
Info:CreateSection("DEBUG")
Info:CreateButton({Name = "Test Debug Chat", Callback = function() DebugOK("Debug jalan!") end})
Info:CreateButton({Name = "Cek Status", Callback = function()
    DebugOK("=== STATUS ===")
    DebugMsg("KillAll: " .. (S.KillAll and "ON" or "OFF"))
    DebugMsg("AutoShoot: " .. (S.AutoShoot and "ON" or "OFF"))
    DebugMsg("Wallbang: " .. (S.Wallbang and "ON" or "OFF"))
    DebugMsg("DrawingESP: " .. (S.DrawingESP and "ON" or "OFF"))
    DebugMsg("Fly: " .. (S.FlyEnabled and "ON" or "OFF"))
    DebugMsg("Total Kill: " .. killCount)
end})

Rayfield:Notify({Title = "RENXX Hub v6.0", Content = "Ultimate Deagle Arena aktif!", Duration = 8, Image = 4483362458})
DebugOK("====================================")
DebugOK("  RENXX HUB v6.0 | DEAGLE ARENA")
DebugOK("  Status: LOADED & READY")
DebugOK("====================================")
