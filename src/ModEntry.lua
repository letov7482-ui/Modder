-- ModEntry.lua
-- PUBG Mobile .pak mod — MODULAR STEALTH EDITION v4 (GUI + Anti-Ban)

local M = {}

math.randomseed(os.time() + os.clock() * 1000)

-- ============================================================
-- HOOK ENGINE
-- ============================================================
local _hook = require("hooks")

-- ============================================================
-- BYPASS MODULES
-- ============================================================
local bypassModules = {
    require("bypasses.FileSystem"),
    require("bypasses.DirHide"),
    require("bypasses.AntiReport"),
    require("bypasses.HiggsBoson"),
    require("bypasses.FileHash"),
    require("bypasses.Network"),
    require("bypasses.Memory"),
    require("bypasses.StringScanner"),
    require("bypasses.Screenshot"),
    require("bypasses.LogScrubber"),
    require("bypasses.LuaEnv"),
    require("bypasses.CEDetector"),
    require("bypasses.PakMount"),
    require("bypasses.RPCHook"),
    require("bypasses.InputSpoof"),
    require("bypasses.ThreadProtect"),
    require("bypasses.NativeFile")
}

local function InitBypasses()
    for _, mod in ipairs(bypassModules) do
        pcall(mod.Init)
    end
end

-- ============================================================
-- MODULE STATES
-- ============================================================
local ESP = {
    enabled = true,
    maxDistance = 300,
    color = { r = 255, g = 0, b = 0, a = 255 },
    boxJitter = 2,
    showHealth = true,
    showDistance = true,
    showName = false,
    fadeStart = 200,
    fadeEnd = 300
}

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

local NoRecoil = { enabled = true }
local SafeMode = { enabled = false }
local MenuState = { 
    visible = false, 
    minimized = false,
    toggleKey = "Insert",
    x = 0, y = 50,
    w = 200, h = 280,
    dragging = false,
    dragX = 0, dragY = 0,
    itemHeight = 22,
    tab = 1
}

-- ============================================================
-- SESSION LIMITER
-- ============================================================
local Session = {
    maxPlayTime = 45 * 60,
    cooldownTime = 15 * 60,
    startTime = os.time(),
    cooldownEnd = 0,
    isCoolingDown = false
}

local function CheckSession()
    if SafeMode.enabled then return false end
    if Session.isCoolingDown then
        if os.time() >= Session.cooldownEnd then
            Session.isCoolingDown = false
            Session.startTime = os.time()
            return true
        end
        return false
    end
    if (os.time() - Session.startTime) >= Session.maxPlayTime then
        Session.isCoolingDown = true
        Session.cooldownEnd = os.time() + Session.cooldownTime
        return false
    end
    return true
end

-- ============================================================
-- ANTI-SPECTATOR
-- ============================================================
local AntiSpec = {
    isSpectated = false,
    checkInterval = 30,
    tickCount = 0
}

local function CheckSpectators()
    AntiSpec.tickCount = AntiSpec.tickCount + 1
    if AntiSpec.tickCount < AntiSpec.checkInterval then return end
    AntiSpec.tickCount = 0
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return end
    local spectators = {}
    if localPlayer.GetSpectators then
        local ok, ret = pcall(localPlayer.GetSpectators, localPlayer)
        if ok and type(ret) == "table" then spectators = ret end
    end
    AntiSpec.isSpectated = #spectators > 0
end

-- ============================================================
-- HEARTBEAT SPOOF
-- ============================================================
local hbState = { lastBeat = 0, interval = math.random(25, 45) }

local function HeartbeatTick()
    hbState.lastBeat = hbState.lastBeat + 1
    if hbState.lastBeat < hbState.interval then return end
    hbState.lastBeat = 0
    hbState.interval = math.random(25, 45)
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
            sessionId = tostring(math.random(100000, 999999))
        })
    end
end

-- ============================================================
-- ESP
-- ============================================================
local function WorldToScreen(worldPos)
    if not UE4.Canvas then return nil end
    return UE4.Canvas.ProjectWorldToScreen(worldPos, nil)
end

local function DrawESP()
    if not ESP.enabled or SafeMode.enabled then return end
    if AntiSpec.isSpectated then return end
    local canvas = UE4.Canvas
    if not canvas then return end
    local players = UE4.GameplayStatics.GetAllActorsOfClass(UE4.WorldContextObject, UE4.Class.APlayerCharacter)
    if not players then return end
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return end
    local localLoc = localPlayer.K2_GetActorLocation()

    for _, player in ipairs(players) do
        pcall(function()
            if player ~= localPlayer and player:IsAlive() then
                local loc = player.K2_GetActorLocation()
                local dist = UE4.Vector.Dist(loc, localLoc) / 100.0
                if dist <= ESP.maxDistance then
                    local screenPos = WorldToScreen(loc)
                    if screenPos then
                        local alpha = ESP.color.a
                        if dist > ESP.fadeStart then
                            local fadeRatio = 1.0 - ((dist - ESP.fadeStart) / (ESP.fadeEnd - ESP.fadeStart))
                            fadeRatio = math.max(0, math.min(1, fadeRatio))
                            alpha = math.floor(alpha * fadeRatio)
                        end
                        local jx = math.random(-ESP.boxJitter, ESP.boxJitter)
                        local jy = math.random(-ESP.boxJitter, ESP.boxJitter)
                        local bx, by = screenPos.X + jx, screenPos.Y + jy
                        local bw, bh = 25, 55
                        local col = { r = ESP.color.r, g = ESP.color.g, b = ESP.color.b, a = alpha }

                        canvas.K2_DrawLine({X = bx - bw, Y = by - bh}, {X = bx + bw, Y = by - bh}, 1.5, col)
                        canvas.K2_DrawLine({X = bx - bw, Y = by - bh}, {X = bx - bw, Y = by + 5}, 1.5, col)
                        canvas.K2_DrawLine({X = bx + bw, Y = by - bh}, {X = bx + bw, Y = by + 5}, 1.5, col)
                        canvas.K2_DrawLine({X = bx - bw, Y = by + 5}, {X = bx + bw, Y = by + 5}, 1.5, col)
                        canvas.K2_DrawLine({X = canvas.SizeX / 2, Y = canvas.SizeY}, {X = bx, Y = by + 5}, 1.0, { r = 255, g = 255, b = 0, a = math.floor(alpha * 0.5) })
                        
                        if ESP.showDistance then
                            canvas.K2_DrawText(string.format("%.0fm", dist), {X = bx - 20, Y = by - 70}, { r = 255, g = 255, b = 255, a = alpha })
                        end
                        if ESP.showHealth then
                            local health = (player.Health or 100) / 100.0
                            health = math.max(0, math.min(1, health))
                            local barH = bh * health
                            local hcol = { r = 0, g = 255, b = 0, a = alpha }
                            if health < 0.3 then hcol = { r = 255, g = 0, b = 0, a = alpha } end
                            if health < 0.6 then hcol = { r = 255, g = 165, b = 0, a = alpha } end
                            canvas.K2_DrawLine({X = bx - bw - 7, Y = by - bh}, {X = bx - bw - 7, Y = by - bh + (bh - barH)}, 2.0, { r = 0, g = 0, b = 0, a = math.floor(alpha * 0.7) })
                            canvas.K2_DrawLine({X = bx - bw - 7, Y = by - bh + (bh - barH)}, {X = bx - bw - 7, Y = by + 5}, 2.0, hcol)
                        end
                    end
                end
            end
        end)
    end
end

-- ============================================================
-- SMART AIMBOT
-- ============================================================
local function GetClosestPlayerToCrosshair()
    local canvas = UE4.Canvas
    if not canvas then return nil end
    local centerX, centerY = canvas.SizeX / 2, canvas.SizeY / 2
    local players = UE4.GameplayStatics.GetAllActorsOfClass(UE4.WorldContextObject, UE4.Class.APlayerCharacter)
    if not players then return nil end
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return nil end
    local localLoc = localPlayer.K2_GetActorLocation()
    local closest, minDist = nil, Aimbot.fov

    for _, player in ipairs(players) do
        pcall(function()
            if player ~= localPlayer and player:IsAlive() then
                local mesh = player.Mesh
                if mesh then
                    if player.IsParachuting and player:IsParachuting() then return end
                    local boneLoc = mesh:GetSocketLocation(Aimbot.bone)
                    local dist = UE4.Vector.Dist(boneLoc, localLoc) / 100.0
                    if dist <= 300 then
                        local hit = UE4.GameplayStatics.LineTraceSingle(UE4.WorldContextObject, localLoc, boneLoc, UE4.ETraceTypeQuery.TraceTypeQuery_Visibility, false, {}, UE4.EDrawDebugTrace.None)
                        if hit and hit.HitActor ~= player then return end
                        local screenPos = WorldToScreen(boneLoc)
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
        end)
    end
    return closest
end

local function AimbotTick()
    if not Aimbot.enabled or SafeMode.enabled then return end
    if AntiSpec.isSpectated then return end
    if not UE4.Input.IsPressed(Aimbot.key) then
        Aimbot.currentSpeed = 0
        return
    end
    if math.random() < Aimbot.missChance then
        local controller = UE4.GameplayStatics.GetPlayerController(0)
        if controller then
            controller:AddYawInput(math.random(-2, 2) * Aimbot.microAdjust)
            controller:AddPitchInput(math.random(-2, 2) * Aimbot.microAdjust)
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
    local screenPos = WorldToScreen(boneLoc)
    if not screenPos then return end
    local centerX, centerY = canvas.SizeX / 2, canvas.SizeY / 2
    local dx = screenPos.X - centerX
    local dy = screenPos.Y - centerY
    Aimbot.currentSpeed = math.min(Aimbot.currentSpeed + Aimbot.accelRate, Aimbot.maxSpeed)
    local jx = (math.random() - 0.5) * Aimbot.microAdjust
    local jy = (math.random() - 0.5) * Aimbot.microAdjust
    local smoothX = math.max(4, Aimbot.smooth + math.random(-2, 2))
    local smoothY = math.max(4, Aimbot.smooth + math.random(-2, 2))
    local moveX = (dx / smoothX + jx) * Aimbot.currentSpeed
    local moveY = (dy / smoothY + jy) * Aimbot.currentSpeed
    controller:AddYawInput(moveX * 0.1)
    controller:AddPitchInput(moveY * 0.1)
end

-- ============================================================
-- HUMAN RECOIL
-- ============================================================
local function ApplyHumanRecoil()
    if not NoRecoil.enabled or SafeMode.enabled then return end
    if AntiSpec.isSpectated then return end
    if not UE4.Input.IsPressed("LeftMouse") then return end
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return end
    local weapon = localPlayer:GetCurrentWeapon()
    if not weapon then return end
    local recoil = 0
    if weapon.GetRecoilVertical then recoil = weapon:GetRecoilVertical()
    elseif weapon.RecoilVertical then recoil = weapon.RecoilVertical end
    if recoil > 0 then
        local compensation = recoil * (0.85 + math.random() * 0.15) * 0.1
        local jitter = (math.random() - 0.5) * 0.05
        local controller = UE4.GameplayStatics.GetPlayerController(0)
        if controller then controller:AddPitchInput(-(compensation + jitter)) end
    end
end

-- ============================================================
-- GUI MENU
-- ============================================================
local menuItems = {
    { name = "ESP", key = "enabled", target = ESP },
    { name = "Aimbot", key = "enabled", target = Aimbot },
    { name = "No Recoil", key = "enabled", target = NoRecoil },
    { name = "Safe Mode", key = "enabled", target = SafeMode }
}

local function DrawMenu()
    if not MenuState.visible then return end
    local canvas = UE4.Canvas
    if not canvas then return end

    if MenuState.x == 0 then
        MenuState.x = canvas.SizeX - MenuState.w - 20
    end

    local mx, my = 0, 0
    local touchActive = false
    if UE4.Input.GetTouchState and UE4.Input:GetTouchState(0) then
        mx, my = UE4.Input:GetTouchLocation(0)
        touchActive = true
    end

    if touchActive then
        if not MenuState.dragging then
            if mx >= MenuState.x and mx <= MenuState.x + MenuState.w and 
               my >= MenuState.y and my <= MenuState.y + 30 then
                MenuState.dragging = true
                MenuState.dragX = mx - MenuState.x
                MenuState.dragY = my - MenuState.y
            end
        else
            MenuState.x = mx - MenuState.dragX
            MenuState.y = my - MenuState.dragY
        end
    else
        MenuState.dragging = false
    end

    local x, y = MenuState.x, MenuState.y
    local w = MenuState.w

    if MenuState.minimized then
        canvas.K2_DrawBox({X = x, Y = y}, w, 30, { r = 20, g = 20, b = 25, a = 240 })
        canvas.K2_DrawText("[+] PLUMA MENU", {X = x + 10, Y = y + 7}, { r = 100, g = 200, b = 255, a = 255 })
        if touchActive and mx >= x and mx <= x + w and my >= y and my <= y + 30 then
            MenuState.minimized = false
        end
        return
    end

    local h = MenuState.h
    canvas.K2_DrawBox({X = x, Y = y}, w, h, { r = 15, g = 15, b = 20, a = 245 })
    canvas.K2_DrawBox({X = x, Y = y}, w, 30, { r = 30, g = 30, b = 40, a = 255 })
    canvas.K2_DrawText("PLUMA MOD v4", {X = x + 8, Y = y + 7}, { r = 100, g = 200, b = 255, a = 255 })
    canvas.K2_DrawText("[-]", {X = x + w - 20, Y = y + 7}, { r = 255, g = 100, b = 100, a = 255 })

    if touchActive and mx >= x + w - 25 and mx <= x + w and my >= y and my <= y + 30 then
        MenuState.minimized = true
        return
    end

    local itemY = y + 40
    for i, item in ipairs(menuItems) do
        local isOn = item.target[item.key]
        local hover = touchActive and mx >= x + 5 and mx <= x + w - 5 and my >= itemY and my <= itemY + MenuState.itemHeight

        if hover then
            canvas.K2_DrawBox({X = x + 5, Y = itemY}, w - 10, MenuState.itemHeight, { r = 40, g = 60, b = 90, a = 200 })
        end

        canvas.K2_DrawText(item.name, {X = x + 12, Y = itemY + 4}, { r = 220, g = 220, b = 220, a = 255 })
        
        local stateText = isOn and "ON" or "OFF"
        local stateCol = isOn and { r = 0, g = 255, b = 100, a = 255 } or { r = 255, g = 80, b = 80, a = 255 }
        canvas.K2_DrawText(stateText, {X = x + w - 35, Y = itemY + 4}, stateCol)

        if hover and not MenuState.dragging then
            item.target[item.key] = not isOn
        end

        itemY = itemY + MenuState.itemHeight + 5
    end

    local statusY = y + h - 20
    local statusText = "Active"
    if SafeMode.enabled then statusText = "SAFE MODE"
    elseif Session.isCoolingDown then statusText = "Cooldown"
    elseif AntiSpec.isSpectated then statusText = "Hidden" end
    
    canvas.K2_DrawText(statusText, {X = x + 8, Y = statusY}, { r = 150, g = 150, b = 150, a = 200 })
end

-- ============================================================
-- INPUT: Toggle Menu
-- ============================================================
local function CheckMenuToggle()
    if UE4.Input.WasKeyJustPressed and UE4.Input:WasKeyJustPressed(MenuState.toggleKey) then
        MenuState.visible = not MenuState.visible
    end
end

-- ============================================================
-- SELF-CLEANUP
-- ============================================================
local function SelfCleanup()
    if package and package.loaded then
        for k, _ in pairs(package.loaded) do
            if type(k) == "string" and (string.find(k, "ModEntry") or string.find(k, "game_patch") or string.find(k, "hooks") or string.find(k, "bypasses")) then
                package.loaded[k] = nil
            end
        end
    end
    if debug and debug.sethook then
        debug.sethook(function() return end, "")
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local delayTicks = math.random(200, 400)
local tickCount = 0
local cleaned = false

local function Tick()
    tickCount = tickCount + 1
    if tickCount < delayTicks then return end

    if not cleaned then
        SelfCleanup()
        cleaned = true
    end

    CheckMenuToggle()
    CheckSpectators()

    if not AntiSpec.isSpectated then
        DrawMenu()
    end

    if not CheckSession() then return end

    HeartbeatTick()

    if not AntiSpec.isSpectated and not SafeMode.enabled then
        DrawESP()
        AimbotTick()
        ApplyHumanRecoil()
    end
end

function M.Init()
    InitBypasses()
    UE4.GameplayEvent.Tick:Add(Tick)
end

function M.Shutdown()
    UE4.GameplayEvent.Tick:Remove(Tick)
end

M.Init()
return M
