-- ============================================================
--  Snapshot.lua
--  Auto-screenshot addon for memorable moments
--  WotLK 3.3.5 / Ascension compatible
-- ============================================================

local ADDON_NAME = "Snapshot"
local DELAY      = 0.3   -- seconds to wait before firing Screenshot()
                          -- (gives the UI time to render the event overlay)

-- ----------------------------------------------------------------
-- Default settings
-- ----------------------------------------------------------------
local DEFAULTS = {
    levelUp        = true,
    achievement    = true,
    death          = true,
    bossKill       = true,
    pvpKill        = true,
    zoneChange     = false,  -- off by default; can be noisy
    duelWin        = true,
    arenaEnd       = true,
    lootLegendary  = true,
    delay          = DELAY,
}

-- ----------------------------------------------------------------
-- Saved variable init
-- ----------------------------------------------------------------
local function InitDB()
    if not SnapshotDB then
        SnapshotDB = {}
    end
    for k, v in pairs(DEFAULTS) do
        if SnapshotDB[k] == nil then
            SnapshotDB[k] = v
        end
    end
end

-- ----------------------------------------------------------------
-- Delayed screenshot helper
-- ----------------------------------------------------------------
local screenshotTimer = 0
local screenshotPending = false

local ticker = CreateFrame("Frame")
ticker:Hide()
ticker:SetScript("OnUpdate", function(self, elapsed)
    screenshotTimer = screenshotTimer - elapsed
    if screenshotTimer <= 0 then
        Screenshot()
        screenshotPending = false
        self:Hide()
    end
end)

local function TakeScreenshot(reason)
    if screenshotPending then return end  -- don't double-fire
    screenshotPending = true
    screenshotTimer = SnapshotDB and SnapshotDB.delay or DELAY
    ticker:Show()
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snapshot]|r Screenshot captured: " .. (reason or "unknown moment"))
    end
end

-- ----------------------------------------------------------------
-- Legendary loot detection helper
-- ----------------------------------------------------------------
local LEGENDARY_QUALITY = 5  -- LE_ITEM_QUALITY_LEGENDARY

local function CheckLootForLegendary()
    if not SnapshotDB.lootLegendary then return end
    for i = 1, GetNumLootItems() do
        local _, _, _, _, rarity = GetLootSlotInfo(i)
        if rarity and rarity >= LEGENDARY_QUALITY then
            TakeScreenshot("legendary loot")
            return  -- one screenshot per loot window is enough
        end
    end
end

-- ----------------------------------------------------------------
-- Main event frame
-- ----------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("ACHIEVEMENT_EARNED")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("BOSS_KILL")
f:RegisterEvent("PLAYER_PVP_KILL")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("DUEL_FINISHED")
f:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
f:RegisterEvent("LOOT_OPENED")

f:SetScript("OnEvent", function(self, event, ...)
    -- ---- addon loaded: init DB and print welcome ----
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            InitDB()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snapshot]|r Loaded. Type |cffffff00/snapshot|r to configure.")
        end
        return
    end

    -- ---- level up ----
    if event == "PLAYER_LEVEL_UP" and SnapshotDB.levelUp then
        local newLevel = ...
        TakeScreenshot("level up to " .. (newLevel or "?"))
        return
    end

    -- ---- achievement earned ----
    if event == "ACHIEVEMENT_EARNED" and SnapshotDB.achievement then
        local _, name = ...
        TakeScreenshot("achievement: " .. (name or "unknown"))
        return
    end

    -- ---- player death ----
    if event == "PLAYER_DEAD" and SnapshotDB.death then
        TakeScreenshot("death")
        return
    end

    -- ---- boss kill ----
    if event == "BOSS_KILL" and SnapshotDB.bossKill then
        local _, name = ...
        TakeScreenshot("boss kill: " .. (name or "unknown boss"))
        return
    end

    -- ---- pvp kill ----
    if event == "PLAYER_PVP_KILL" and SnapshotDB.pvpKill then
        TakeScreenshot("PvP kill")
        return
    end

    -- ---- zone change (optional, off by default) ----
    if event == "ZONE_CHANGED_NEW_AREA" and SnapshotDB.zoneChange then
        local zone = GetZoneText() or "unknown zone"
        TakeScreenshot("entered " .. zone)
        return
    end

    -- ---- duel finished: only screenshot if we won ----
    if event == "DUEL_FINISHED" and SnapshotDB.duelWin then
        -- DUEL_FINISHED fires for both win and loss; check if opponent fled/died
        -- arg1 = opponent name, arg2 = "won" / "lost" / "fled"
        local opponent, result = ...
        if result == "won" then
            TakeScreenshot("duel win vs " .. (opponent or "opponent"))
        end
        return
    end

    -- ---- arena match end ----
    if event == "UPDATE_BATTLEFIELD_STATUS" and SnapshotDB.arenaEnd then
        -- Check all arena slots for a finished match
        for i = 1, MAX_BATTLEFIELD_QUEUES or 2 do
            local status = GetBattlefieldStatus(i)
            if status == "active" then
                -- We'll rely on PLAYER_PVP_KILL for kills;
                -- capture the end of the arena via score popup (see note below)
            end
        end
        return
    end

    -- ---- legendary loot ----
    if event == "LOOT_OPENED" then
        CheckLootForLegendary()
        return
    end
end)

-- ----------------------------------------------------------------
-- Slash command  /snapshot  or  /ss
-- ----------------------------------------------------------------
local function PrintStatus()
    local db = SnapshotDB
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snapshot] Current settings:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  levelUp       = " .. tostring(db.levelUp))
    DEFAULT_CHAT_FRAME:AddMessage("  achievement   = " .. tostring(db.achievement))
    DEFAULT_CHAT_FRAME:AddMessage("  death         = " .. tostring(db.death))
    DEFAULT_CHAT_FRAME:AddMessage("  bossKill      = " .. tostring(db.bossKill))
    DEFAULT_CHAT_FRAME:AddMessage("  pvpKill       = " .. tostring(db.pvpKill))
    DEFAULT_CHAT_FRAME:AddMessage("  duelWin       = " .. tostring(db.duelWin))
    DEFAULT_CHAT_FRAME:AddMessage("  arenaEnd      = " .. tostring(db.arenaEnd))
    DEFAULT_CHAT_FRAME:AddMessage("  lootLegendary = " .. tostring(db.lootLegendary))
    DEFAULT_CHAT_FRAME:AddMessage("  zoneChange    = " .. tostring(db.zoneChange))
    DEFAULT_CHAT_FRAME:AddMessage("  delay         = " .. tostring(db.delay) .. "s")
end

local VALID_KEYS = {
    levelUp=true, achievement=true, death=true, bossKill=true,
    pvpKill=true, duelWin=true, arenaEnd=true, lootLegendary=true,
    zoneChange=true,
}

local function HandleSlash(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "" or msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snapshot] Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /snapshot status              — show all settings")
        DEFAULT_CHAT_FRAME:AddMessage("  /snapshot <key> on|off        — toggle a trigger")
        DEFAULT_CHAT_FRAME:AddMessage("  /snapshot delay <seconds>     — set screenshot delay")
        DEFAULT_CHAT_FRAME:AddMessage("  /snapshot test                — fire a test screenshot")
        DEFAULT_CHAT_FRAME:AddMessage("  /snapshot reset               — restore defaults")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Keys:|r levelUp, achievement, death, bossKill,")
        DEFAULT_CHAT_FRAME:AddMessage("       pvpKill, duelWin, arenaEnd, lootLegendary, zoneChange")
        return
    end

    if msg == "status" then
        PrintStatus()
        return
    end

    if msg == "test" then
        TakeScreenshot("test")
        return
    end

    if msg == "reset" then
        for k, v in pairs(DEFAULTS) do
            SnapshotDB[k] = v
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snapshot]|r Settings reset to defaults.")
        return
    end

    -- /snapshot delay <n>
    local delayVal = msg:match("^delay%s+([%d%.]+)$")
    if delayVal then
        local n = tonumber(delayVal)
        if n and n >= 0 and n <= 5 then
            SnapshotDB.delay = n
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snapshot]|r Delay set to " .. n .. "s.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[Snapshot]|r Delay must be between 0 and 5 seconds.")
        end
        return
    end

    -- /snapshot <key> on|off
    local key, val = msg:match("^(%a+)%s+(on|off)$")
    if key and val then
        if VALID_KEYS[key] then
            SnapshotDB[key] = (val == "on")
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snapshot]|r " .. key .. " set to " .. val .. ".")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[Snapshot]|r Unknown key: " .. key)
        end
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[Snapshot]|r Unknown command. Type /snapshot help.")
end

SLASH_SNAPSHOT1 = "/snapshot"
SLASH_SNAPSHOT2 = "/ss"
SlashCmdList["SNAPSHOT"] = HandleSlash
