-- ═══════════════════════════════════════════════════════════════
--   RY ANTI-CHEAT SCANNER v1
--   By: ry-zeen
--   Fungsi: Scan SEMUA anti-cheat, rate limit, UI detect, dll
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local OUTPUT = {}
local function add(t) table.insert(OUTPUT, t) end
local function line() add("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━") end
local function section(t) add(""); line(); add("▬▬▬ " .. t .. " ▬▬▬"); line() end

print("━━━ ANTI-CHEAT SCAN START ━━━")
local startTime = tick()

-- ═══════════════════════════════════════════════════════════════
--   1. ANTI-CHEAT REMOTES
-- ═══════════════════════════════════════════════════════════════
local function ScanACRemotes()
    section("1. ANTI-CHEAT REMOTES")
    
    local Network = RS:FindFirstChild("Network")
    if not Network then add("❌ Network gak ada"); return end
    
    local AC_KEYS = {
        "ban","kick","report","detect","cheat","hack","exploit","anticheat",
        "ac_","_ac","watch","flag","suspect","violation","admin","mod",
        "punish","warn","strike","log","blacklist","whitelist","verify",
        "validate","check","auth","secure","guard","sentry","watchdog"
    }
    
    for _, containerName in ipairs({"Remotes","ClientRemotes"}) do
        local container = Network:FindFirstChild(containerName)
        if container then
            add("")
            add("▸ Network." .. containerName .. ":")
            local found = 0
            for _, r in ipairs(container:GetChildren()) do
                local nl = r.Name:lower()
                for _, kw in ipairs(AC_KEYS) do
                    if nl:find(kw) then
                        add("  [!] [" .. r.ClassName .. "] " .. r.Name)
                        found = found + 1
                        break
                    end
                end
            end
            if found == 0 then add("  ✅ Gak ada remote anti-cheat") end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   2. ANTI-CHEAT SCRIPTS
-- ═══════════════════════════════════════════════════════════════
local function ScanACScripts()
    section("2. ANTI-CHEAT SCRIPTS")
    
    local AC_KEYS = {
        "anticheat","anti_cheat","anti-cheat","detect","monitor",
        "ac_","_ac","protection","guard","watchdog","sentry",
        "security","secure","verify","validate","check","ban",
        "kick","report","flag","suspect","exploit","hack"
    }
    
    local found = 0
    
    local function scan(container, path)
        local ok, children = pcall(function() return container:GetChildren() end)
        if not ok then return end
        
        for _, obj in ipairs(children) do
            if obj:IsA("Script") or obj:IsA("ModuleScript") or obj:IsA("LocalScript") then
                local nl = obj.Name:lower()
                for _, kw in ipairs(AC_KEYS) do
                    if nl:find(kw) then
                        add("  [!] " .. path .. "." .. obj.Name .. " (" .. obj.ClassName .. ")")
                        found = found + 1
                        break
                    end
                end
            elseif obj:IsA("Folder") and obj.Name ~= "Modules" then
                scan(obj, path .. "." .. obj.Name)
            end
        end
    end
    
    scan(RS, "RS")
    scan(WS, "WS")
    
    if found == 0 then add("  ✅ Gak ada script anti-cheat yang ketara") end
end

-- ═══════════════════════════════════════════════════════════════
--   3. DETECT PATTERNS (getgc)
-- ═══════════════════════════════════════════════════════════════
local function ScanPatterns()
    section("3. DETECT PATTERNS (via getgc)")
    
    if typeof(getgc) ~= "function" then
        add("❌ getgc gak support")
        return
    end
    
    local PATTERNS = {
        "getgenv", "_G", "hookmetamethod", "hookfunction", "getrawmetatable",
        "setreadonly", "getnamecallmethod", "Drawing", "Rayfield", "scriptware",
        "synapse", "krnl", "fluxus", "delta", "arceus", "hydrogen",
    }
    
    local stats = {}
    for _, p in ipairs(PATTERNS) do stats[p] = 0 end
    
    -- Scan global vars
    local _G_count = 0
    for k, v in pairs(_G) do
        _G_count = _G_count + 1
    end
    add("Global (_G) count: " .. _G_count)
    
    -- Scan getgenv
    if getgenv then
        local genv_count = 0
        for k, v in pairs(getgenv()) do
            genv_count = genv_count + 1
        end
        add("getgenv() count: " .. genv_count)
    end
    
    add("")
    add("Pattern yang di-scan:")
    for _, p in ipairs(PATTERNS) do
        add("  🔍 " .. p)
    end
end

-- ═══════════════════════════════════════════════════════════════
--   4. GLOBAL VARS
-- ═══════════════════════════════════════════════════════════════
local function ScanGlobalVars()
    section("4. GLOBAL VARS (_G & getgenv)")
    
    add("▸ _G:")
    local count = 0
    for k, v in pairs(_G) do
        count = count + 1
        if count <= 50 then
            local typeStr = typeof(v)
            local valStr = tostring(v)
            if #valStr > 50 then valStr = valStr:sub(1,50) .. "..." end
            add("  " .. tostring(k) .. " = " .. valStr .. " (" .. typeStr .. ")")
        end
    end
    if count > 50 then add("  ... (+" .. (count-50) .. " lagi)") end
    
    add("")
    if getgenv then
        add("▸ getgenv():")
        local gc = 0
        for k, v in pairs(getgenv()) do
            gc = gc + 1
            if gc <= 50 then
                local typeStr = typeof(v)
                local valStr = tostring(v)
                if #valStr > 50 then valStr = valStr:sub(1,50) .. "..." end
                add("  " .. tostring(k) .. " = " .. valStr .. " (" .. typeStr .. ")")
            end
        end
        if gc > 50 then add("  ... (+" .. (gc-50) .. " lagi)") end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   5. UI DETECT
-- ═══════════════════════════════════════════════════════════════
local function ScanUIDetect()
    section("5. UI DETECT")
    
    add("▸ CoreGui children:")
    local cgCount = 0
    pcall(function()
        for _, v in ipairs(CoreGui:GetChildren()) do
            cgCount = cgCount + 1
            add("  [" .. v.ClassName .. "] " .. v.Name)
        end
    end)
    if cgCount == 0 then add("  (kosong / gak bisa akses)") end
    
    add("")
    add("▸ PlayerGui children:")
    local pgCount = 0
    for _, v in ipairs(PGui:GetChildren()) do
        pgCount = pgCount + 1
        if pgCount <= 30 then
            add("  [" .. v.ClassName .. "] " .. v.Name)
        end
    end
    if pgCount > 30 then add("  ... (+" .. (pgCount-30) .. " lagi)") end
    
    add("")
    add("▸ Suspicious names:")
    local SUS = {"script","executor","cheat","hack","inject","synapse","krnl","fluxus","delta","rayfield","ry","renxx"}
    local susFound = 0
    pcall(function()
        for _, v in ipairs(CoreGui:GetChildren()) do
            local nl = v.Name:lower()
            for _, s in ipairs(SUS) do
                if nl:find(s) then
                    add("  ⚠️ CoreGui: " .. v.Name)
                    susFound = susFound + 1
                    break
                end
            end
        end
    end)
    for _, v in ipairs(PGui:GetChildren()) do
        local nl = v.Name:lower()
        for _, s in ipairs(SUS) do
            if nl:find(s) then
                add("  ⚠️ PlayerGui: " .. v.Name)
                susFound = susFound + 1
                break
            end
        end
    end
    if susFound == 0 then add("  ✅ Gak ada UI suspicious") end
end

-- ═══════════════════════════════════════════════════════════════
--   6. HOOK DETECTION CHECK
-- ═══════════════════════════════════════════════════════════════
local function ScanHookDetect()
    section("6. HOOK DETECTION CHECK")
    
    add("▸ Executor Support:")
    local functions = {
        "hookmetamethod","hookfunction","getrawmetatable","setreadonly",
        "getgc","getgenv","getreg","getrenv","getnamecallmethod",
        "setclipboard","writefile","readfile","isfile","listfiles",
        "Drawing","gethui","identifyexecutor","getexecutorname"
    }
    
    for _, fn in ipairs(functions) do
        local ok = typeof(_G[fn] or (getgenv and getgenv()[fn])) or "nil"
        if ok == "nil" then ok = "function" else ok = "function" end
        local exists = false
        if _G[fn] then exists = true
        elseif getgenv and getgenv()[fn] then exists = true
        elseif rawget(_G, fn) then exists = true end
        if fn == "Drawing" then exists = Drawing ~= nil
        elseif fn == "getgc" then exists = typeof(getgc) == "function"
        elseif fn == "gethui" then exists = typeof(gethui) == "function"
        elseif fn == "setclipboard" then exists = typeof(setclipboard) == "function"
        elseif fn == "writefile" then exists = typeof(writefile) == "function"
        elseif fn == "readfile" then exists = typeof(readfile) == "function"
        elseif fn == "isfile" then exists = typeof(isfile) == "function"
        elseif fn == "listfiles" then exists = typeof(listfiles) == "function"
        elseif fn == "hookmetamethod" then exists = typeof(hookmetamethod) == "function"
        elseif fn == "hookfunction" then exists = typeof(hookfunction) == "function"
        elseif fn == "getrawmetatable" then exists = typeof(getrawmetatable) == "function"
        elseif fn == "setreadonly" then exists = typeof(setreadonly) == "function"
        elseif fn == "getgenv" then exists = typeof(getgenv) == "function"
        elseif fn == "getreg" then exists = typeof(getreg) == "function"
        elseif fn == "getrenv" then exists = typeof(getrenv) == "function"
        elseif fn == "getnamecallmethod" then exists = typeof(getnamecallmethod) == "function"
        elseif fn == "identifyexecutor" then exists = typeof(identifyexecutor) == "function"
        elseif fn == "getexecutorname" then exists = typeof(getexecutorname) == "function"
        end
        
        add("  " .. (exists and "✅" or "❌") .. " " .. fn)
    end
    
    add("")
    add("▸ Executor Info:")
    if identifyexecutor then
        local ok, name, ver = pcall(identifyexecutor)
        if ok then add("  Executor: " .. tostring(name) .. " " .. tostring(ver or "")) end
    else
        add("  Executor: (gak bisa detect)")
    end
end

-- ═══════════════════════════════════════════════════════════════
--   7. RATE LIMIT TEST
-- ═══════════════════════════════════════════════════════════════
local function ScanRateLimit()
    section("7. RATE LIMIT TEST")
    
    add("▸ Analisa rate limit server:")
    add("")
    add("  Catatan:")
    add("  - Server-side rate limit (267ms?) → cek per-remote")
    add("  - Client-side rate limit → gak ke-detect")
    add("")
    
    -- Cek remote yang kita sering spam
    local Network = RS:FindFirstChild("Network")
    if Network then
        local Remotes = Network:FindFirstChild("Remotes")
        if Remotes then
            add("  ▸ Remote yang berisiko rate limit:")
            local KEY = {"Shoot","Fire","Attack","Ability","Use","Damage","Hit","Kill","Movement"}
            for _, r in ipairs(Remotes:GetChildren()) do
                for _, kw in ipairs(KEY) do
                    if r.Name:find(kw) then
                        add("    ⚠️ " .. r.Name)
                        break
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   8. TELEPORT / SPEED DETECT
-- ═══════════════════════════════════════════════════════════════
local function ScanTPSpeedDetect()
    section("8. TELEPORT / SPEED DETECT")
    
    add("▸ Cek server-side validation:")
    add("  (Server-side tidak bisa di-scan dari client)")
    add("")
    add("▸ Cek client-side validation:")
    
    -- Cek LocalScript yang handle movement
    local MOBILE_KEYS = {"movement","speed","tpspeed","antiteleport","anticheat"}
    local found = 0
    pcall(function()
        for _, obj in ipairs(LP:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("Script") then
                local nl = obj.Name:lower()
                for _, k in ipairs(MOBILE_KEYS) do
                    if nl:find(k) then
                        add("  ⚠️ " .. obj:GetFullName())
                        found = found + 1
                        break
                    end
                end
            end
        end
    end)
    if found == 0 then add("  ✅ Gak ada client-side movement check") end
end

-- ═══════════════════════════════════════════════════════════════
--   9. PLAYER DATA
-- ═══════════════════════════════════════════════════════════════
local function ScanPlayerData()
    section("9. PLAYER DATA")
    
    add("Player: " .. LP.Name)
    add("UserId: " .. LP.UserId)
    add("AccountAge: " .. LP.AccountAge .. " hari")
    add("Team: " .. tostring(LP:GetAttribute("Team")))
    add("Rank: " .. tostring(LP:GetAttribute("Rank") or "?"))
    add("Level: " .. tostring(LP:GetAttribute("Level") or "?"))
    add("")
    
    add("▸ Attributes:")
    for k, v in pairs(LP:GetAttributes()) do
        local valStr = tostring(v)
        if #valStr > 40 then valStr = valStr:sub(1,40) .. "..." end
        add("  " .. k .. " = " .. valStr)
    end
end

-- ═══════════════════════════════════════════════════════════════
--   10. EXECUTOR INFO
-- ═══════════════════════════════════════════════════════════════
local function ScanExecutor()
    section("10. EXECUTOR INFO")
    
    if identifyexecutor then
        local ok, name, ver = pcall(identifyexecutor)
        if ok then
            add("  Name: " .. tostring(name))
            add("  Version: " .. tostring(ver or "?"))
        end
    end
    
    add("  getgc: " .. (typeof(getgc) == "function" and "✅" or "❌"))
    add("  Drawing: " .. (Drawing and "✅" or "❌"))
    add("  gethui: " .. (typeof(gethui) == "function" and "✅" or "❌"))
    add("  hookmetamethod: " .. (typeof(hookmetamethod) == "function" and "✅" or "❌"))
    add("  writefile: " .. (typeof(writefile) == "function" and "✅" or "❌"))
    add("  setclipboard: " .. (typeof(setclipboard) == "function" and "✅" or "❌"))
end

-- ═══════════════════════════════════════════════════════════════
--   RUN ALL
-- ═══════════════════════════════════════════════════════════════
local function RunScan()
    OUTPUT = {}
    line()
    add("RY ANTI-CHEAT SCANNER — FULL RESULT")
    add("Date: " .. os.date("%Y-%m-%d %H:%M:%S"))
    add("Player: " .. LP.Name)
    add("PlaceId: " .. game.PlaceId)
    line()
    
    ScanACRemotes()
    ScanACScripts()
    ScanPatterns()
    ScanGlobalVars()
    ScanUIDetect()
    ScanHookDetect()
    ScanRateLimit()
    ScanTPSpeedDetect()
    ScanPlayerData()
    ScanExecutor()
    
    line()
    local scanTime = tick() - startTime
    add("END OF SCAN — " .. string.format("%.2f", scanTime) .. "s")
    line()
end

-- ═══════════════════════════════════════════════════════════════
--   BUILD UI
-- ═══════════════════════════════════════════════════════════════
local function BuildUI()
    local parent
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then parent = hui end
    end
    if not parent then parent = CoreGui end
    
    local old = parent:FindFirstChild("RY_AC_Scanner")
    if old then old:Destroy() end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "RY_AC_Scanner"
    gui.ResetOnSpawn = false
    gui.Parent = parent
    
    local W = IsMobile and 340 or 420
    local H = IsMobile and 460 or 500
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, W, 0, H)
    main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 60, 60)
    stroke.Thickness = 2
    stroke.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    title.BorderSizePixel = 0
    title.Text = "🛡️ ANTI-CHEAT SCANNER"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.Parent = main
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)
    
    -- Tombol row
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -20, 0, 40)
    btnRow.Position = UDim2.new(0, 10, 0, 42)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = main
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 5)
    layout.Parent = btnRow
    
    local function makeBtn(text, color, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.33, -4, 1, 0)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.LayoutOrder = order
        b.Parent = btnRow
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        return b
    end
    
    local btnCopy = makeBtn("📋 COPY", Color3.fromRGB(40, 120, 200), 1)
    local btnSave = makeBtn("💾 SAVE", Color3.fromRGB(40, 180, 80), 2)
    local btnClose = makeBtn("❌ CLOSE", Color3.fromRGB(180, 40, 40), 3)
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 22)
    status.Position = UDim2.new(0, 10, 0, 88)
    status.BackgroundTransparency = 1
    status.Text = "Status: Scanning..."
    status.TextColor3 = Color3.fromRGB(255, 200, 0)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = main
    
    local preview = Instance.new("ScrollingFrame")
    preview.Size = UDim2.new(1, -20, 1, -160)
    preview.Position = UDim2.new(0, 10, 0, 115)
    preview.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    preview.BorderSizePixel = 0
    preview.ScrollBarThickness = 6
    preview.CanvasSize = UDim2.new(0, 0, 0, 0)
    preview.AutomaticCanvasSize = Enum.AutomaticSize.Y
    preview.Parent = main
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)
    
    local previewText = Instance.new("TextLabel")
    previewText.Size = UDim2.new(1, -10, 0, 0)
    previewText.Position = UDim2.new(0, 5, 0, 5)
    previewText.BackgroundTransparency = 1
    previewText.Text = "(scanning...)"
    previewText.TextColor3 = Color3.fromRGB(220, 220, 220)
    previewText.TextSize = 10
    previewText.Font = Enum.Font.Code
    previewText.TextXAlignment = Enum.TextXAlignment.Left
    previewText.TextYAlignment = Enum.TextYAlignment.Top
    previewText.TextWrapped = true
    previewText.AutomaticSize = Enum.AutomaticSize.Y
    previewText.Parent = preview
    
    local function setStatus(text, color)
        status.Text = "Status: " .. text
        status.TextColor3 = color or Color3.fromRGB(255, 200, 0)
    end
    
    btnCopy.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(table.concat(OUTPUT, "\n"))
            setStatus("✅ Copied!", Color3.fromRGB(0, 255, 100))
        else
            setStatus("❌ No clipboard", Color3.fromRGB(255, 80, 80))
        end
    end)
    
    btnSave.MouseButton1Click:Connect(function()
        if writefile then
            local fname = "RY_AC_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
            local ok = pcall(function() writefile(fname, table.concat(OUTPUT, "\n")) end)
            if ok then
                setStatus("✅ Saved: " .. fname, Color3.fromRGB(0, 255, 100))
            else
                setStatus("❌ Save gagal", Color3.fromRGB(255, 80, 80))
            end
        else
            setStatus("❌ writefile gak support", Color3.fromRGB(255, 80, 80))
        end
    end)
    
    btnClose.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    return gui, setStatus, previewText
end

-- ═══════════════════════════════════════════════════════════════
--   EXECUTE
-- ═══════════════════════════════════════════════════════════════
local gui, setStatus, previewText = BuildUI()

task.spawn(function()
    RunScan()
    previewText.Text = table.concat(OUTPUT, "\n")
    if setStatus then setStatus("✅ Done! COPY atau SAVE.", Color3.fromRGB(0, 255, 100)) end
    print(table.concat(OUTPUT, "\n"))
end)
