-- =======================================
-- RENXX LOADER v1.4
-- By: DEEP & RENXX
-- Library: Qanuir Orion UI
-- =======================================

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

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
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/fixx-fps-one-tap.lua",  -- ✅ FIX #2
    },
    {
        name = "SAFE MODE HYPERSHOT",
        desc = "Protection + Weapon Mod",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-hypershot-safemode.lua",  -- ✅ FIX #3
    },
    {
        name = "ULTIMATE HYPERSHOT",
        desc = "Hypershot Full Features v3.8",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-ultimate-hypershot.lua",
    },
    {
        name = "KING HYPERSHOT",
        desc = "King Hypershot Script",
        url = "https://raw.githubusercontent.com/ry-zeen/script/main/ry-king-hypershot.lua",  -- ✅ Bonus
    },
}

-- ==================== STATE ====================
local Loading = false

-- ==================== FUNGSI LOAD ====================
local function loadScript(script)
    if Loading then
        OrionLib:MakeNotification({
            Name = "RENXX Loader",
            Content = "Tunggu, masih loading script lain...",
            Time = 3,
        })
        return
    end
    
    Loading = true
    
    OrionLib:MakeNotification({
        Name = "RENXX Loader",
        Content = "Loading: " .. script.name .. "...",
        Time = 3,
    })
    
    -- Download
    local ok, body = pcall(function()
        return game:HttpGet(script.url)
    end)
    
    if not ok or type(body) ~= "string" or #body < 50 then
        OrionLib:MakeNotification({
            Name = "RENXX Loader",
            Content = "Gagal download: " .. script.name,
            Time = 4,
        })
        Loading = false
        return
    end
    
    -- Compile
    local fn, err = loadstring(body)
    if not fn then
        OrionLib:MakeNotification({
            Name = "RENXX Loader",
            Content = "Error compile: " .. script.name,
            Time = 4,
        })
        Loading = false
        return
    end
    
    -- Execute
    local success, execErr = pcall(fn)
    if not success then
        OrionLib:MakeNotification({
            Name = "RENXX Loader",
            Content = "Error execute: " .. script.name,
            Time = 4,
        })
        Loading = false
        return
    end
    
    OrionLib:MakeNotification({
        Name = "RENXX Loader",
        Content = "Berhasil: " .. script.name,
        Time = 3,
    })
    
    Loading = false
end

-- ==================== WINDOW ====================
local Window = OrionLib:MakeWindow({
    Name = "RENXX LOADER | Hub",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "RENXXLoader",
    IntroEnabled = true,
    IntroText = "RENXX LOADER",
})  -- ✅ FIX #4 & #5: Hapus IntroIcon & Icon

-- ==================== TAB: SEMUA SCRIPT ====================
local MainTab = Window:MakeTab({
    Name = "SEMUA SCRIPT",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

MainTab:AddSection({
    Name = "Total: " .. #Scripts .. " Script",
})

for i, script in ipairs(Scripts) do
    MainTab:AddButton({
        Name = i .. ". " .. script.name,
        Callback = function()
            loadScript(script)
        end,
    })
end

-- ==================== TAB: INFO ====================
local InfoTab = Window:MakeTab({
    Name = "INFO",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

InfoTab:AddSection({
    Name = "Tentang",
})

InfoTab:AddParagraph({
    Title = "RENXX LOADER",
    Content = "Loader buat semua script RENXX.\nTinggal klik tombol, script otomatis ke-load.",
})

InfoTab:AddSection({
    Name = "Credits",
})

InfoTab:AddParagraph({
    Title = "Developer",
    Content = "DEEP & RENXX\nGitHub: ry-zeen\nBy: RENXX XITERZ",
})

-- ==================== INTRO ====================
OrionLib:Init()  -- ✅ FIX #1: Bukan Window:Init()

-- ==================== NOTIFIKASI ====================
OrionLib:MakeNotification({
    Name = "RENXX LOADER",
    Content = "Loaded! " .. #Scripts .. " script siap dipilih.",
    Time = 5,
})

print("═══════════════════════════════")
print("RENXX LOADER v1.4 | Qanuir Orion UI")
print("Total Scripts: " .. #Scripts)
print("By DEEP & RENXX")
print("═══════════════════════════════")
