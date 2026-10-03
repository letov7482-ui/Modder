-- ModEntry.lua
-- PUBG Mobile .pak mod — Anti-report bypass + ESP + Aimbot + NoRecoil

local M = {}

-- ============================================================
-- HOOK: CreativeGameTaskComponent (новая система репортов)
-- ============================================================
local CreativeGameTaskComponent = GameLua.Mod.CreativeBase.Gameplay.Component.ObjectFuncs.CreativeGameTaskComponent

if CreativeGameTaskComponent then
    local orig_ReportPlayer = CreativeGameTaskComponent.ReportPlayer
    CreativeGameTaskComponent.ReportPlayer = function(self, reportType, targetPlayerId, reason)
        return true
    end

    local orig_SubmitReport = CreativeGameTaskComponent.SubmitReport
    CreativeGameTaskComponent.SubmitReport = function(self, reportData)
        reportData = {}
        return true
    end

    local orig_CheckAbnormalBehavior = CreativeGameTaskComponent.CheckAbnormalBehavior
    CreativeGameTaskComponent.CheckAbnormalBehavior = function(self, playerId)
        return false
    end
end

-- ============================================================
-- HOOK: HiggsBosonComponent (телеметрия/безопасность)
-- ============================================================
local HiggsBosonComponent = GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent

if HiggsBosonComponent then
    local orig_OnReportEvent = HiggsBosonComponent.OnReportEvent
    HiggsBosonComponent.OnReportEvent = function(self, eventType, eventData)
        return
    end

    local orig_SecurityCheck = HiggsBosonComponent.SecurityCheck
    HiggsBosonComponent.SecurityCheck = function(self)
        return true
    end

    local orig_UploadReportData = HiggsBosonComponent.UploadReportData
    HiggsBosonComponent.UploadReportData = function(self, data)
        data = { reportId = "0", payload = "", timestamp = 0 }
        return orig_UploadReportData(self, data)
    end

    local orig_GetReportFlags = HiggsBosonComponent.GetReportFlags
    HiggsBosonComponent.GetReportFlags = function(self)
        return 0
    end
end

-- ============================================================
-- ESP — отрисовка через Canvas
-- ============================================================
local ESP = {
    enabled = true,
    maxDistance = 300,
    color = { r = 255, g = 0, b = 0, a = 255 }
}

local function WorldToScreen(worldPos, cameraCtx)
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
                    canvas.K2_DrawLine({X = screenPos.X - 25, Y = screenPos.Y - 50}, {X = screenPos.X + 25, Y = screenPos.Y - 50}, 2.0, ESP.color)
                    canvas.K2_DrawLine({X = screenPos.X - 25, Y = screenPos.Y - 50}, {X = screenPos.X - 25, Y = screenPos.Y + 5}, 2.0, ESP.color)
                    canvas.K2_DrawLine({X = screenPos.X + 25, Y = screenPos.Y - 50}, {X = screenPos.X + 25, Y = screenPos.Y + 5}, 2.0, ESP.color)
                    canvas.K2_DrawLine({X = screenPos.X - 25, Y = screenPos.Y + 5}, {X = screenPos.X + 25, Y = screenPos.Y + 5}, 2.0, ESP.color)
                    
                    canvas.K2_DrawLine({X = canvas.SizeX / 2, Y = canvas.SizeY}, {X = screenPos.X, Y = screenPos.Y + 5}, 1.0, {r = 255, g = 255, b = 0, a = 120})
                    canvas.K2_DrawText(string.format("%.0fm", dist), {X = screenPos.X - 20, Y = screenPos.Y - 65}, {r = 255, g = 255, b = 255, a = 255})
                    
                    local health = player.Health / 100.0
                    local barH = 55 * health
                    canvas.K2_DrawLine({X = screenPos.X - 32, Y = screenPos.Y - 50}, {X = screenPos.X - 32, Y = screenPos.Y - 50 + (55 - barH)}, 2.0, {r = 0, g = 0, b = 0, a = 200})
                    canvas.K2_DrawLine({X = screenPos.X - 32, Y = screenPos.Y - 50 + (55 - barH)}, {X = screenPos.X - 32, Y = screenPos.Y + 5}, 2.0, {r = 0, g = 255, b = 0, a = 255})
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
    fov = 150,
    smooth = 8,
    bone = "head_01",
    key = "RightMouse"
}

local function GetClosestPlayerToCrosshair()
    local canvas = UE4.Canvas
    if not canvas then return nil end
    local centerX = canvas.SizeX / 2
    local centerY = canvas.SizeY / 2

    local players = UE4.GameplayStatics.GetAllActorsOfClass(UE4.WorldContextObject, UE4.Class.APlayerCharacter)
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return nil end
    local localLoc = localPlayer.K2_GetActorLocation()

    local closest = nil
    local minDist = Aimbot.fov

    for _, player in ipairs(players) do
        if player ~= localPlayer and player:IsAlive() then
            local mesh = player.Mesh
            if mesh then
                local boneLoc = mesh:GetSocketLocation(Aimbot.bone)
                local dist = UE4.Vector.Dist(boneLoc, localLoc) / 100.0
                if dist <= 300 then
                    local screenPos = WorldToScreen(boneLoc, canvas)
                    if screenPos then
                        local dx = screenPos.X - centerX
                        local dy = screenPos.Y - centerY
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
    if not UE4.Input.IsPressed(Aimbot.key) then return end

    local target = GetClosestPlayerToCrosshair()
    if not target then return end

    local canvas = UE4.Canvas
    if not canvas then return end
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return end
    local controller = UE4.GameplayStatics.GetPlayerController(0)
    if not controller then return end

    local mesh = target.Mesh
    if not mesh then return end

    local boneLoc = mesh:GetSocketLocation(Aimbot.bone)
    local screenPos = WorldToScreen(boneLoc, canvas)

    if screenPos then
        local centerX = canvas.SizeX / 2
        local centerY = canvas.SizeY / 2
        local dx = (screenPos.X - centerX) / Aimbot.smooth
        local dy = (screenPos.Y - centerY) / Aimbot.smooth
        controller:AddYawInput(dx * 0.1)
        controller:AddPitchInput(dy * 0.1)
    end
end

-- ============================================================
-- NO RECOIL
-- ============================================================
local NoRecoil = { enabled = true }

local function ApplyNoRecoil()
    if not NoRecoil.enabled then return end
    local localPlayer = UE4.GameplayStatics.GetPlayerCharacter(0)
    if not localPlayer then return end
    local weapon = localPlayer:GetCurrentWeapon()
    if not weapon then return end

    if weapon.SetRecoilVertical then weapon:SetRecoilVertical(0.0) end
    if weapon.SetRecoilHorizontal then weapon:SetRecoilHorizontal(0.0) end
    if weapon.SetRecoilRecovery then weapon:SetRecoilRecovery(0.0) end
    if weapon.SetSwayScale then weapon:SetSwayScale(0.0) end
    if weapon.SetBulletSpread then weapon:SetBulletSpread(0.0) end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function Tick()
    DrawESP()
    AimbotTick()
    ApplyNoRecoil()
end

function M.Init()
    UE4.GameplayEvent.Tick:Add(Tick)
    print("[Mod] Loaded — ESP/Aimbot/NoRecoil/AntiReport active")
end

function M.Shutdown()
    UE4.GameplayEvent.Tick:Remove(Tick)
end

M.Init()
return M
