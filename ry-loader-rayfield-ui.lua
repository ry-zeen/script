-- =======================================
-- RENXX LOADER v2.0 | Rayfield Edition
-- By: DEEP & RENXX
-- Library: Rayfield UI
-- =======================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ==================== LIST SEMUA SCRIPT ====================
local Scripts = {
    {
        name = "AIMBOT FPS",
        desc = "Aimbot FPS Universal",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-aimbot-fps.lua",
    },
    {
        name = "FPS ONE TAP",
        desc = "One Tap FPS",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-fps-one-tap.lua",
    },
    {
        name = "FIX FPS ONE TAP",
        desc = "One Tap FPS (Fix Version)",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/fixx-fps-one-tap.lua",
    },
    {
        name = "SAFE MODE HYPERSHOT",
        desc = "Protection + Weapon Mod",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-hypershot-safemode.lua",
    },
    {
        name = "ULTIMATE HYPERSHOT",
        desc = "Hypershot Full Features v3.8",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-ultimate-hypershot.lua",
    },
    {
        name = "KING HYPERSHOT",
        desc = "King Hypershot Script",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-king-hypershot.lua",
    },
}

-- ==================== STATE ====================
local Loading = false

-- ==================== FUNGSI LOAD ====================
local function loadScript(script)
    if Loading then
        Rayfield:Notify({
            Title = "RENXX Loader",
            Content = "Tunggu, masih loading script lain...",
            Duration = 3,
        })
        return
    end
    
    Loading = true
    
    Rayfield:Notify({
        Title = "RENXX Loader",
        Content = "Loading: " .. script.name .. "...",
        Duration = 3,
    })
    
    -- Download
    local ok, body = pcall(function()
        return game:HttpGet(script.url)
    end)
    
    if not ok or type(body) ~= "string" or #body < 50 then
        Rayfield:Notify({
            Title = "RENXX Loader",
            Content = "Gagal download: " .. script.name,
            Duration = 4,
        })
        Loading = false
        return
    end
    
    -- Compile
    local fn, err = loadstring(body)
    if not fn then
        Rayfield:Notify({
            Title = "RENXX Loader",
            Content = "Error compile: " .. script.name,
            Duration = 4,
        })
        Loading = false
        return
    end
    
    -- Execute
    local success, execErr = pcall(fn)
    if not success then
        Rayfield:Notify({
            Title = "RENXX Loader",
            Content = "Error execute: " .. script.name,
            Duration = 4,
        })
        Loading = false
        return
    end
    
    Rayfield:Notify({
        Title = "RENXX Loader",
        Content = "Berhasil: " .. script.name,
        Duration = 3,
    })
    
    Loading = false
end

-- ==================== WINDOW ====================
local Window = Rayfield:CreateWindow({
    Name = "RENXX LOADER | Hub",
    LoadingTitle = "Loading RENXX LOADER...",
    LoadingSubtitle = "By DEEP & RENXX",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ==================== TAB: SEMUA SCRIPT ====================
local MainTab = Window:CreateTab("SEMUA SCRIPT", 4483362458)

MainTab:CreateSection("Total: " .. #Scripts .. " Script")

for i, script in ipairs(Scripts) do
    MainTab:CreateButton({
        Name = i .. ". " .. script.name,
        Callback = function()
            loadScript(script)
        end,
    })
end

-- ==================== TAB: INFO ====================
local InfoTab = Window:CreateTab("INFO", 4483362458)

InfoTab:CreateSection("Tentang")

InfoTab:CreateParagraph({
    Title = "RENXX LOADER",
    Content = "Loader buat semua script RENXX.\nTinggal klik tombol, script otomatis ke-load.",
})

InfoTab:CreateSection("Credits")

InfoTab:CreateParagraph({
    Title = "Developer",
    Content = "DEEP & RENXX\nGitHub: ry-zeen\nBy: RENXX XITERZ",
})

InfoTab:CreateSection("Links")

InfoTab:CreateButton({
    Name = "Copy GitHub URL",
    Callback = function()
        if setclipboard then
            setclipboard("https://github.com/ry-zeen/script")
            Rayfield:Notify({
                Title = "RENXX Loader",
                Content = "GitHub URL copied!",
                Duration = 3,
            })
        end
    end,
})

-- ==================== NOTIFIKASI ====================
Rayfield:Notify({
    Title = "RENXX LOADER v2.0",
    Content = "Loaded! " .. #Scripts .. " script siap dipilih.",
    Duration = 5,
})

print("═══════════════════════════════")
print("RENXX LOADER v2.0 | Rayfield UI")
print("Total Scripts: " .. #Scripts)
print("By DEEP & RENXX")
print("═══════════════════════════════")
