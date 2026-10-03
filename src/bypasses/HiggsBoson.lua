local M = {}
local _hook = require("hooks")

function M.Init()
    local hb = GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent
    if not hb then return end

    _hook.hook(hb, "OnReportEvent", function(self, eventType, eventData) return end)
    _hook.hook(hb, "SecurityCheck", function(self) return true end)
    _hook.hook(hb, "GetReportFlags", function(self) return 0 end)
    _hook.hook(hb, "UploadReportData", function(self, data) return true end)

    _hook.hook(hb, "MemoryScan", function(self)
        return { detected = false, flags = 0, regions = {} }
    end)

    _hook.hook(hb, "FileScan", function(self, path)
        if path and (string.find(path, "puffer_temp") or string.find(path, "game_patch")) then
            return { isValid = true, isModified = false, hash = "original" }
        end
        return { isValid = true, isModified = false }
    end)

    _hook.hook(hb, "VerifyScriptIntegrity", function(self, scriptPath, hash) return true end)

    _hook.hook(hb, "CaptureScreen", function(self)
        return { width = 1, height = 1, data = "", format = "rgba" }
    end)

    _hook.hook(hb, "VerifyMemoryIntegrity", function(self, addr, size)
        return { isValid = true, hash = "original" }
    end)

    _hook.hook(hb, "CheckModuleIntegrity", function(self, moduleName)
        return { isValid = true, isModified = false }
    end)

    _hook.hook(hb, "OnDetectionEvent", function(self, detectionType, data) return end)
    _hook.hook(hb, "SendDetectionReport", function(self, reportData) return true end)

    _hook.hook(hb, "AnalyzeBehavior", function(self, playerId, data)
        return { isAbnormal = false, score = 0, flags = 0 }
    end)

    _hook.hook(hb, "CheckInjection", function(self)
        return { detected = false, modules = {} }
    end)
end

return M
