-- ModEntry.lua
-- PUBG Mobile .pak mod — STEALTH EDITION
-- Polymorphic hooks, humanized aim, obfuscated strings, adaptive bypass

local M = {}

-- ============================================================
-- UTILS: String obfuscation & Random
-- ============================================================
local _rxor = function(s, k)
    local r = ""
    for i = 1, #s do
        r = r .. string.char(bit.bxor(string.byte(s, i), k))
    end
    return r
end

local _rdump = function(t, k)
    local r = {}
    for i, v in ipairs(t) do
        r[i] = _rxor(v, k)
    end
    return r
end

local _rnd = function(min, max)
    if not min then return math.random() end
    if not max then min, max = 1, min end
    return math.random(min, max)
end

local _jitter = function(base, variance)
    return base + (math.random() - 0.5) * variance
end

-- Obfuscated class names
local _OBF = {
    k1 = 0x55,
    k2 = 0xAA,
    k3 = 0x37,
    k4 = 0x91
}

local _C = _rdump({
    "\x47\x61\x6d\x65\x4c\x75\x61",                                       -- GameLua
    "\x43\x72\x65\x61\x74\x69\x76\x65\x42\x61\x73\x65",                   -- CreativeBase
    "\x47\x61\x6d\x65\x70\x6c\x61\x79",                                    -- Gameplay
    "\x43\x6f\x6d\x70\x6f\x6e\x65\x6e\x74",                               -- Component
    "\x4f\x62\x6a\x65\x63\x74\x46\x75\x6e\x63\x73",                       -- ObjectFuncs
    "\x43\x72\x65\x61\x74\x69\x76\x65\x47\x61\x6d\x65\x54\x61\x73\x6b",   -- CreativeGameTask
    "\x48\x69\x67\x67\x73\x42\x6f\x73\x6f\x6e",                           -- HiggsBoson
    "\x53\x65\x63\x75\x72\x69\x74\x79",                                   -- Security
    "\x42\x61\x73\x65\x4d\x6f\x64",                                       -- BaseMod
    "\x43\x6f\x6d\x6d\x6f\x6e",                                           -- Common
    "\x46\x69\x6c\x65\x53\x79\x73\x74\x65\x6d",                           -- FileSystem
    "\x44\x69\x72\x53\x63\x61\x6e\x6e\x65\x72",                           -- DirScanner
    "\x46\x69\x6c\x65\x4d\x61\x6e\x61\x67\x65\x72",                       -- FileManager
    "\x4e\x65\x74\x77\x6f\x72\x6b\x4d\x61\x6e\x61\x67\x65\x72",           -- NetworkManager
    "\x53\x65\x63\x75\x72\x69\x74\x79\x55\x74\x69\x6c\x73",               -- SecurityUtils
    "\x50\x72\x6f\x63\x65\x73\x73\x4d\x61\x6e\x61\x67\x65\x72",           -- ProcessManager
    "\x53\x74\x72\x69\x6e\x67\x53\x63\x61\x6e\x6e\x65\x72",               -- StringScanner
    "\x53\x63\x72\x65\x65\x6e\x73\x68\x6f\x74\x4d\x61\x6e\x61\x67\x65\x72", -- ScreenshotManager
    "\x4c\x6f\x67\x4d\x61\x6e\x61\x67\x65\x72",                           -- LogManager
    "\x4c\x75\x61\x45\x6e\x76\x69\x72\x6f\x6e\x6d\x65\x6e\x74",           -- LuaEnvironment
    "\x43\x45\x44\x65\x74\x65\x63\x74\x6f\x72",                           -- CEDetector
    "\x4e\x65\x74\x49\x6e\x74\x65\x72\x63\x65\x70\x74\x6f\x72"            -- NetInterceptor
}, _OBF.k1)

local function _cls(name)
    return name
end

-- ============================================================
-- POLYMORPHIC HOOK ENGINE
-- ============================================================
local _hookCache = {}
local _hookId = 0

local function _hook(obj, name, fn)
    if not obj or not obj[name] then return false end
    _hookId = _hookId + 1
    
    -- Сохраняем оригинал с уникальным ключём
    local key = "_orig_" .. name .. "_" .. _hookId .. "_" .. _rnd(1000, 9999)
    _hookCache[key] = obj[name]
    
    -- Создаём wrapper с разным поведением каждый запуск
    local wrapper
    if _hookId % 3 == 0 then
        wrapper = function(self, ...)
            if _rnd() > 0.001 then  -- 0.1% chance пропустить хук
                return fn(self, ...)
            end
            return _hookCache[key](self, ...)
        end
    elseif _hookId % 3 == 1 then
        wrapper = function(self, ...)
            return fn(self, ...)
        end
    else
        local offset = _rnd(1, 100)
        wrapper = function(self, ...)
            -- Меняем стек вызова для анти-паттерна
            local r = { fn(self, ...) }
            return unpack(r)
        end
    end
    
    obj[name] = wrapper
    return true
end

-- ============================================================
-- BYPASS: File Deletion Protection (исправлено)
-- ============================================================
local function InitFileProtection()
    local FileSystem = GameLua.Mod.BaseMod.Common.FileSystem
    if not FileSystem then return end

    _hook(FileSystem, "DeleteFile", function(self, path)
        if path and (string.find(path, "puffer_temp") or string.find(path, "game_patch")) then
            return true
        end
        return _hookCache["_orig_DeleteFile_" .. _hookId .. "_" .. 0](self, path)
    end)

    _hook(FileSystem, "RemoveDirectory", function(self, path)
        if path and string.find(path, "puffer_temp") then return true end
        return _hookCache["_orig_RemoveDirectory_" .. _hookId .. "_" .. 0](self, path)
    end)

    _hook(FileSystem, "RenameFile", function(self, oldPath, newPath)
        if oldPath and (string.find(oldPath, "puffer_temp") or string.find(oldPath, "game_patch")) then
            return true
        end
        return _hookCache["_orig_RenameFile_" .. _hookId .. "_" .. 0](self, oldPath, newPath)
    end)
end

-- ============================================================
-- BYPASS: Directory Listing Hide
-- ============================================================
local function InitDirHide()
    local DirScanner = GameLua.Mod.BaseMod.Common.DirScanner
    if not DirScanner then return end

    _hook(DirScanner, "ScanDirectory", function(self, path)
        local orig = _hookCache["_orig_ScanDirectory_" .. _hookId .. "_" .. 0]
        if not orig then return {} end
        local results = orig(self, path)
        if path and (string.find(path, "Paks") or string.find(path, "puffer_temp")) then
            local filtered = {}
            for _, file in ipairs(results) do
                if not (file and string.find(file, "game_patch")) then
                    table.insert(filtered, file)
                end
            end
            return filtered
        end
        return results
    end)
end

-- ============================================================
-- BYPASS: Anti-Report (CreativeGameTaskComponent)
-- ============================================================
local function InitAntiReport()
    local comp = GameLua.Mod.CreativeBase.Gameplay.Component.ObjectFuncs.CreativeGameTaskComponent
    if not comp then return end

    _hook(comp, "ReportPlayer", function(self, reportType, targetPlayerId, reason)
        return true
    end)

    _hook(comp, "SubmitReport", function(self, reportData)
        return true
    end)

    _hook(comp, "CheckAbnormalBehavior", function(self, playerId)
        return false
    end)

    _hook(comp, "OnReportSubmitted", function(self, reportId, status)
        return true
    end)

    _hook(comp, "GetReportCooldown", function(self)
        return 0
    end)
end

-- ============================================================
-- BYPASS: HiggsBosonComponent (ACE/Security)
-- ============================================================
local function InitHiggsBosonBypass()
    local hb = GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent
    if not hb then return end

    _hook(hb, "OnReportEvent", function(self, eventType, eventData)
        return
    end)

    _hook(hb, "SecurityCheck", function(self)
        return true
    end)

    _hook(hb, "GetReportFlags", function(self)
        return 0
    end)

    _hook(hb, "UploadReportData", function(self, data)
        return true
    end)

    _hook(hb, "MemoryScan", function(self)
        return { detected = false, flags = 0, regions = {} }
    end)

    _hook(hb, "FileScan", function(self, path)
        if path and (string.find(path, "puffer_temp") or string.find(path, "game_patch")) then
            return { isValid = true, isModified = false, hash = "original" }
        end
        return { isValid = true, isModified = false }
    end)

    _hook(hb, "VerifyScriptIntegrity", function(self, scriptPath, hash)
        return true
    end)

    _hook(hb, "CaptureScreen", function(self)
        return { width = 1, height = 1, data = "", format = "rgba" }
    end)

    _hook(hb, "VerifyMemoryIntegrity", function(self, addr, size)
        return { isValid = true, hash = "original" }
    end)

    _hook(hb, "CheckModuleIntegrity", function(self, moduleName)
        return { isValid = true, isModified = false }
    end)

    _hook(hb, "OnDetectionEvent", function(self, detectionType, data)
        return
    end)

    _hook(hb, "SendDetectionReport", function(self, reportData)
        return true
    end)

    _hook(hb, "AnalyzeBehavior", function(self, playerId, data)
        return { isAbnormal = false, score = 0, flags = 0 }
    end)

    _hook(hb, "CheckInjection", function(self)
        return { detected = false, modules = {} }
    end)
end

-- ============================================================
-- BYPASS: File Hash (исправлена рекурсия)
-- ============================================================
local function InitFileHashBypass()
    local fm = GameLua.Mod.BaseMod.Common.FileManager
    if not fm then return end

    local orig_GetFileHash = fm.GetFileHash
    _hook(fm, "GetFileHash", function(self, path)
        if path and (string.find(path, "game_patch") or string.find(path, "puffer_temp")) then
            return "ORIGINAL_HASH_PLACEHOLDER"
        end
        if orig_GetFileHash then
            return orig_GetFileHash(self, path)
        end
        return ""
    end)

    local orig_VerifyFile = fm.VerifyFile
    _hook(fm, "VerifyFile", function(self, path, expectedHash)
        if path and (string.find(path, "game_patch") or string.find(path, "puffer_temp")) then
            return true
        end
        if orig_VerifyFile then
            return orig_VerifyFile(self, path, expectedHash)
        end
        return true
    end)
end

-- ============================================================
-- BYPASS: Network — глубокий перехват пакетов
-- ============================================================
local function InitNetworkBypass()
    local nm = GameLua.Mod.BaseMod.Common.NetworkManager
    if not nm then return end

    local blockPatterns = {
        "report", "anticheat", "security", "cheat", "detection",
        "abnormal", "tpsdk", "ace_", "violation", "modified",
        "unauthorized", "inject", "hook", "bypass", "antiche",
        "safe", "verify", "integrity", "screenshot", "forensic"
    }

    _hook(nm, "SendPacket", function(self, packet)
        if not packet then return true end
        local ptype = packet.type or ""
        local pdata = tostring(packet.data or "")
        local check = string.lower(ptype .. " " .. pdata)
        for _, pattern in ipairs(blockPatterns) do
            if string.find(check, pattern) then
                return true
            end
        end
        local orig = _hookCache["_orig_SendPacket_" .. _hookId .. "_" .. 0]
        if orig then return orig(self, packet) end
        return true
    end)

    _hook(nm, "SendHTTPRequest", function(self, url, data)
        if not url then return { statusCode = 200, body = '{"code":0}' } end
        local lower = string.lower(url)
        for _, pattern in ipairs(blockPatterns) do
            if string.find(lower, pattern) then
                return {
                    statusCode = 200,
                    body = '{"code":0,"msg":"ok","data":null}',
                    headers = {}
                }
            end
        end
        local orig = _hookCache["_orig_SendHTTPRequest_" .. _hookId .. "_" .. 0]
        if orig then return orig(self, url, data) end
        return { statusCode = 200, body = '{"code":0}' }
    end)

    _hook(nm, "SendRawData", function(self, data, size)
        local orig = _hookCache["_orig_SendRawData_" .. _hookId .. "_" .. 0]
        if orig then return orig(self, data, size) end
        return true
    end)
end

-- ============================================================
-- BYPASS: Memory & Process
-- ============================================================
local function InitMemoryBypass()
    local su = GameLua.Mod.BaseMod.Common.Security.SecurityUtils
    if su then
        _hook(su, "ScanLuaEnvironment", function(self)
            return { isClean = true, modifiedEntries = {}, globalsChecked = 0 }
        end)
        _hook(su, "CheckFunctionIntegrity", function(self, funcRef)
            return true
        end)
        _hook(su, "VerifyCallStack", function(self)
            return { isClean = true, depth = 0 }
        end)
    end

    local pm = GameLua.Mod.BaseMod.Common.ProcessManager
    if pm then
        _hook(pm, "OpenProcess", function(self, pid, access)
            if access and bit.band(access, 0x10) ~= 0 then
                return nil
            end
            local orig = _hookCache["_orig_OpenProcess_" .. _hookId .. "_" .. 0]
            if orig then return orig(self, pid, access) end
            return nil
        end)

        _hook(pm, "ReadMemory", function(self, addr, size)
            local fake = {}
            for i = 1, size do fake[i] = 0 end
            return fake
        end)

        _hook(pm, "EnumProcessModules", function(self)
            local orig = _hookCache["_orig_EnumProcessModules_" .. _hookId .. "_" .. 0]
            if not orig then return {} end
            local results = orig(self)
            if type(results) ~= "table" then return {} end
            local filtered = {}
            for _, mod in ipairs(results) do
                local name = string.lower(mod.name or "")
                if not string.find(name, "mod") and
                   not string.find(name, "patch") and
                   not string.find(name, "lua") and
                   not string.find(name, "puffer") then
                    table.insert(filtered, mod)
                end
            end
            return filtered
        end)

        _hook(pm, "GetModuleInfo", function(self, moduleName)
            local orig = _hookCache["_orig_GetModuleInfo_" .. _hookId .. "_" .. 0]
            if not orig then return nil end
            if moduleName and (string.find(string.lower(moduleName), "mod") or
               string.find(string.lower(moduleName), "patch")) then
                return nil
            end
            return orig(self, moduleName)
        end)
    end
end

-- ============================================================
-- BYPASS: String Scanner
-- ============================================================
local function InitStringScannerBypass()
    local ss = GameLua.Mod.BaseMod.Common.Security.StringScanner
    if not ss then return end

    _hook(ss, "ScanStrings", function(self, region, patterns)
        return {}
    end)
    _hook(ss, "ScanForPattern", function(self, pattern)
        return false
    end)
    _hook(ss, "ScanMemoryRegion", function(self, start, size)
        return { detected = false, matches = {} }
    end)
    _hook(ss, "CheckForKnownSignatures", function(self)
        return { detected = false, signatures = {} }
    end)
end

-- ============================================================
-- BYPASS: Screenshot (расширенный)
-- ============================================================
local function InitScreenshotBypass()
    local sm = GameLua.Mod.BaseMod.Common.ScreenshotManager
    if not sm then return end

    _hook(sm, "Capture", function(self, width, height)
        local w, h = width or 1, height or 1
        local fakeData = {}
        for i = 1, (w * h * 4) do fakeData[i] = 0 end
        return { width = w, height = h, data = fakeData, format = "rgba" }
    end)

    _hook(sm, "CaptureRegion", function(self, x, y, w, h)
        local fakeData = {}
        for i = 1, ((w or 1) * (h or 1) * 4) do fakeData[i] = 0 end
        return { width = w or 1, height = h or 1, data = fakeData, format = "rgba" }
    end)

    _hook(sm, "GLReadPixels", function(self, x, y, w, h)
        local fakeData = {}
        for i = 1, ((w or 1) * (h or 1) * 4) do fakeData[i] = 0 end
        return fakeData
    end)
end

-- ============================================================
-- BYPASS: Log Scrubber
-- ============================================================
local function InitLogScrubber()
    local lm = GameLua.Mod.BaseMod.Common.LogManager
    if not lm then return end

    local blockTags = {
        "cheat", "anticheat", "security", "detection", "violation",
        "ace", "report", "abnormal", "inject", "hook", "bypass",
        "modified", "unauthorized", "screenshot", "forensic",
        "integrity", "tamper", "unverified"
    }

    _hook(lm, "WriteLog", function(self, level, tag, message)
        local check = string.lower(tostring(tag) .. " " .. tostring(message))
        for _, blocked in ipairs(blockTags) do
            if string.find(check, blocked) then return end
        end
        local orig = _hookCache["_orig_WriteLog_" .. _hookId .. "_" .. 0]
        if orig then return orig(self, level, tag, message) end
    end)

    _hook(lm, "SendLog", function(self, logData)
        local check = string.lower(tostring(logData))
        for _, pattern in ipairs(blockTags) do
            if string.find(check, pattern) then return end
        end
        local orig = _hookCache["_orig_SendLog_" .. _hookId .. "_" .. 0]
        if orig then return orig(self, logData) end
    end)

    _hook(lm, "FlushLogs", function(self)
        local orig = _hookCache["_orig_FlushLogs_" .. _hookId .. "_" .. 0]
        if orig then return orig(self) end
    end)
end

-- ============================================================
-- BYPASS: Lua Environment Hider
-- ============================================================
local function InitLuaEnvHide()
    local le = GameLua.Mod.BaseMod.Common.LuaEnvironment
    if not le then return end

    _hook(le, "GetGlobalTable", function(self)
        local fake = {}
        for k, v in pairs(_G) do
            if type(k) == "string" then
                local lk = string.lower(k)
                if not string.find(lk, "esp") and
                   not string.find(lk, "aimbot") and
                   not string.find(lk, "norecoil") and
                   not string.find(lk, "bypass") and
                   not string.find(lk, "hook") and
                   not string.find(lk, "mod") and
                   not string.find(lk, "cheat") and
                   not string.find(lk, "hack") then
                    fake[k] = v
                end
            end
        end
        return fake
    end)

    _hook(le, "ScanGlobals", function(self)
        return { isClean = true, modified = {}, count = 0 }
    end)

    _hook(le, "GetLoadedFiles", function(self)
        local orig = _hookCache["_orig_GetLoadedFiles_" .. _hookId .. "_" .. 0]
        if not orig then return {} end
        local results = orig(self)
        local filtered = {}
        for _, file in ipairs(results) do
            if not (file and (string.find(file, "ModEntry") or string.find(file, "game_patch"))) then
                table.insert(filtered, file)
            end
        end
        return filtered
    end)
end

-- ============================================================
-- BYPASS: CE Detection & Debugger
-- ============================================================
local function InitCEDetectionBypass()
    local ce = GameLua.Mod.BaseMod.Common.Security.CEDetector
    if ce then
        _hook(ce, "Detect", function(self)
            return { detected = false, processes = {}, modules = {} }
        end)
        _hook(ce, "ScanForDebugger", function(self)
            return false
        end)
        _hook(ce, "ScanForBreakpoints", function(self)
            return { detected = false, addresses = {} }
        end)
        _hook(ce, "CheckProcessList", function(self)
  end)
    end
end

-- ============================================================
-- BYPASS: Heartbeat Spoof (рандомизированный)
-- ============================================================
local hbState = {
    lastBeat = 0,
    interval = _rnd(25, 45),  -- рандомный интервал
    jitter = _rnd(1, 10)
}

local function HeartbeatTick()
    hbState.lastBeat = hbState.lastBeat + 1
    if hbState.lastBeat < hbState.interval then return end
    hbState.lastBeat = 0
    hbState.interval = _rnd(25, 45)  -- меняем интервал каждый раз

    local hb = GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent
    if hb and hb.SendHeartbeat then
        hb:SendHeartbeat({
            status = "ok",
            detectionFlags = 0,
            memoryIntact = true,
            filesIntact = true,
            luaIntact = true,
            modulesIntact = true,
            networkIntact = true,
            timestamp = os.time(),
            uptime = os.clock(),
            sessionId = tostring(_rnd(100000, 999999))
        })
    end
end

-- ============================================================
-- ESP — STEALTH MODE
-- ============================================================
local ESP = {
    enabled = true,
    maxDistance = 300,
    color = { r = 255, g = 0, b = 0, a = 255 },
    -- Stealth features
    boxJitter = 2,       -- случайное смещение рамки
    snaplineAlpha 120,
    showHealth = true,
    showDistance = true,
    showName = false,    -- имена оставляем выключенными — палевно
    fadeStart = 200,     -- начинаем затухание
    fadeEnd = 300        -- полностью прозрачный
}

local function WorldToScreen(worldPos, cameraCtx)
    if not UE4.Canvas then return nil end
    return UE4.Canvas.ProjectWorldToScreen(worldPos, cameraCtx)
end

local function DrawESP()
    if not ESP.enabled then return end
    local canvas = UE4.Canvas
    if not canvas then return end
    local players = UE4.GameplayStatics.GetAllActorsOfClass(UE4.WorldContextObject, UE4.Class.APlayerCharacter)
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return end
    local localLoc = localPlayer.K2_GetActorLocation()

    for _, player in ipairs(players) do
        if player ~= localPlayer and player:IsAlive() then
            local loc = player.K2_GetActorLocation()
            local dist = UE4.Vector.Dist(loc, localLoc) / 100.0
            if dist <= ESP.maxDistance then
                local screenPos = WorldToScreen(loc, canvas)
                if screenPos then
                    -- Вычисляем прозрачность по дистанции
                    local alpha = ESP.color.a
                    if dist > ESP.fadeStart then
                        local fadeRatio = 1.0 - ((dist - ESP.fadeStart) / (ESP.fadeEnd - ESP.fadeStart))
                        fadeRatio = math.max(0, math.min(1, fadeRatio))
                        alpha = math.floor(alpha * fadeRatio)
                    end

                    -- Добавляем джиттер — рамка не стоит идеально ровно
                    local jx = _rnd(-ESP.boxJitter, ESP.boxJitter)
                    local jy = _rnd(-ESP.boxJitter, ESP.boxJitter)
                    
                    local bx, by = screenPos.X + jx, screenPos.Y + jy
                    local bw, bh = 25, 55

                    local col = { r = ESP.color.r, g = ESP.color.g, b = ESP.color.b, a = alpha }
                    canvas.K2_DrawLine({X = bx - bw, Y = by - bh}, {X = bx + bw, Y = by - bh}, 1.5, col)
                    canvas.K2_DrawLine({X = bx - bw, Y = by - bh}, {X = bx - bw, Y = by + 5}, 1.5, col)
                    canvas.K2_DrawLine({X = bx + bw, Y = by - bh}, {X = bx + bw, Y = by + 5}, 1.5, col)
                    canvas.K2_DrawLine({X = bx - bw, Y = by + 5}, {X = bx + bw, Y = by + 5}, 1.5, col)

                    canvas.K2_DrawLine(
                        {X = canvas.SizeX / 2, Y = canvas.SizeY},
                        {X = bx, Y = by + 5},
                        1.0,
                        { r = 255, g = 255, b = 0, a = math.floor(alpha * 0.5) }
                    )

                    if ESP.showDistance then
                        canvas.K2_DrawText(
                            string.format("%.0fm", dist),
                            {X = bx - 20, Y = by - 70},
                            { r = 255, g = 255, b = 255, a = alpha }
                        )
                    end

                    if ESP.showHealth then
                        local health = (player.Health or 100) / 100.0
                        health = math.max(0, math.min(1, health))
                        local barH = bh * health
                        local hcol = { r = 0, g = 255, b = 0, a = alpha }
                        if health < 0.3 then hcol = { r = 255, g = 0, b = 0, a = alpha } end
                        if health < 0.6 then hcol = { r = 255, g = 165, b = 0, a = alpha } end

                        canvas.K2_DrawLine(
                            {X = bx - bw - 7, Y = by - bh},
                            {X = bx - bw - 7, Y = by - bh + (bh - barH)},
                            2.0,
                            { r = 0, g = 0, b = 0, a = math.floor(alpha * 0.7) }
                        )
                        canvas.K2_DrawLine(
                            {X = bx - bw - 7, Y = by - bh + (bh - barH)},
                            {X = bx - bw - 7, Y = by + 5},
                            2.0,
                            hcol
                        )
                    end
                end
            end
        end
    end
end

-- ============================================================
-- AIMBOT — HUMANIZED
-- ============================================================
local Aimbot = {
    enabled = true,
    fov = 120,
    smooth = 12,
    bone = "head_01",
    key = "RightMouse",
    missChance = 0.02,
    microAdjust = 0.3,
    accelRate = 0.15,
    currentSpeed = 0,
    maxSpeed = 1.0
}

local function GetClosestPlayerToCrosshair()
    local canvas = UE4.Canvas
    if not canvas then return nil end
    local centerX, centerY = canvas.SizeX / 2, canvas.SizeY / 2
    local players = UE4.GameplayStatics.GetAllActorsOfClass(UE4.WorldContextObject, UE4.Class.APlayerCharacter)
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return nil end
    local localLoc = localPlayer.K2_GetActorLocation()
    local closest, minDist = nil, Aimbot.fov

    for _, player in ipairs(players) do
        if player ~= localPlayer and player:IsAlive() then
            local mesh = player.Mesh
            if mesh then
                local boneLoc = mesh:GetSocketLocation(Aimbot.bone)
                local dist = UE4.Vector.Dist(boneLoc, localLoc) / 100.0
                if dist <= 300 then
                    local screenPos = WorldToScreen(boneLoc, canvas)
                    if screenPos then
                        local dx, dy = screenPos.X - centerX, screenPos.Y - centerY
                        local screenDist = math.sqrt(dx * dx + dy * dy)
                        if screenDist < minDist then
                            minDist = screenDist
                            closest = player
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function AimbotTick()
    if not Aimbot.enabled then return end
    if not UE4.Input.IsPressed(Aimbot.key) then
        Aimbot.currentSpeed = 0
        return
    end

    if _rnd() < Aimbot.missChance then
        local controller = UE4.GameplayStatics.GetPlayerController(0)
        if controller then
            controller:AddYawInput(_rnd(-2, 2) * Aimbot.microAdjust)
            controller:AddPitchInput(_rnd(-2, 2) * Aimbot.microAdjust)
        end
        return
    end

    local target = GetClosestPlayerToCrosshair()
    if not target then
        Aimbot.currentSpeed = 0
        return
    end

    local canvas = UE4.Canvas
    if not canvas then return end
    local controller = UE4.GameplayStatics.GetPlayerController(0)
    if not controller then return end

    local mesh = target.Mesh
    if not mesh then return end

    local boneLoc = mesh:GetSocketLocation(Aimbot.bone)
    local screenPos = WorldToScreen(boneLoc, canvas)
    if not screenPos then return end

    local centerX, centerY = canvas.SizeX / 2, canvas.SizeY / 2
    local dx = screenPos.X - centerX
    local dy = screenPos.Y - centerY

    Aimbot.currentSpeed = math.min(Aimbot.currentSpeed + Aimbot.accelRate, Aimbot.maxSpeed)

    local jx = (_rnd() - 0.5) * Aimbot.microAdjust
    local jy = (_rnd() - 0.5) * Aimbot.microAdjust

    local smoothX = Aimbot.smooth + _rnd(-2, 2)
    local smoothY = Aimbot.smooth + _rnd(-2, 2)
    smoothX = math.max(4, smoothX)
    smoothY = math.max(4, smoothY)

    local moveX = (dx / smoothX + jx) * Aimbot.currentSpeed
    local moveY = (dy / smoothY + jy) * Aimbot.currentSpeed

    controller:AddYawInput(moveX * 0.1)
    controller:AddPitchInput(moveY * 0.1)
end

-- ============================================================
-- NO RECOIL — STEALTH
-- ============================================================
local NoRecoil = {
    enabled = true,
    verticalResidual = 0.01,
    horizontalResidual = 0.01,
    recoveryResidual = 0.02,
    swayResidual = 0.1,
    spreadResidual = 0.05,
    applyChance = 0.85
}

local function ApplyNoRecoil()
    if not NoRecoil.enabled then return end
    if _rnd() > NoRecoil.applyChance then return end

    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return end
    local weapon = localPlayer:GetCurrentWeapon()
    if not weapon then return end

    if weapon.SetRecoilVertical then weapon:SetRecoilVertical(NoRecoil.verticalResidual) end
    if weapon.SetRecoilHorizontal then weapon:SetRecoilHorizontal(NoRecoil.horizontalResidual) end
    if weapon.SetRecoilRecovery then weapon:SetRecoilRecovery(NoRecoil.recoveryResidual) end
    if weapon.SetSwayScale then weapon:SetSwayScale(NoRecoil.swayResidual) end
    if weapon.SetBulletSpread then weapon:SetBulletSpread(NoRecoil.spreadResidual) end
end

-- ============================================================
-- SELF-CLEANUP
-- ============================================================
local function SelfCleanup()
    if package and package.loaded then
        for k, _ in pairs(package.loaded) do
            if type(k) == "string" and (string.find(k, "ModEntry") or string.find(k, "game_patch")) then
                package.loaded[k] = nil
            end
        end
    end
    if debug and debug.sethook then
        debug.sethook(function() return end, "")
    end
end

-- ============================================================
-- INIT ALL BYPASSES
-- ============================================================
local bypassInits = {
    InitFileProtection,
    InitDirHide,
    InitAntiReport,
    InitHiggsBosonBypass,
    InitFileHashBypass,
    InitNetworkBypass,
    InitMemoryBypass,
    InitStringScannerBypass,
    InitScreenshotBypass,
    InitLogScrubber,
    InitLuaEnvHide,
    InitCEDetectionBypass
}

local function InitBypasses()
    for _, initFn in ipairs(bypassInits) do
        pcall(initFn)
    end
end

-- ============================================================
-- MAIN TICK LOOP
-- ============================================================
local delayTicks = _rnd(200, 400)
local tickCount = 0
local cleaned = false

local function Tick()
    tickCount = tickCount + 1
    if tickCount < delayTicks then return end

    if not cleaned then
        SelfCleanup()
        cleaned = true
    end

    HeartbeatTick()
    DrawESP()
    AimbotTick()
    ApplyNoRecoil()
end

function M.Init()
    math.randomseed(os.time() + os.clock() * 1000)
    InitBypasses()
    UE4.GameplayEvent.Tick:Add(Tick)
end

function M.Shutdown()
    UE4.GameplayEvent.Tick:Remove(Tick)
end

M.Init()
return M
