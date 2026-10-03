-- ModEntry.lua
-- PUBG Mobile .pak mod — MODULAR STEALTH EDITION

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
    require("bypasses.CEDetector")
}

local function InitBypasses()
    for _, mod in ipairs(bypassModules) do
        pcall(mod.Init)
    end
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

local function WorldToScreen(worldPos)
    if not UE4.Canvas then return nil end
    return UE4.Canvas.ProjectWorldToScreen(worldPos, nil)
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
-- AIMBOT
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
    end
    return closest
end

local function AimbotTick()
    if not Aimbot.enabled then return end
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
-- NO RECOIL
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
    if math.random() > NoRecoil.applyChance then return end

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

    HeartbeatTick()
    DrawESP()
    AimbotTick()
    ApplyNoRecoil()
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
