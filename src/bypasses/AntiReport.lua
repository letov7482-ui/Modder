local M = {}
local _hook = require("hooks")

function M.Init()
    local comp = GameLua.Mod.CreativeBase.Gameplay.Component.ObjectFuncs.CreativeGameTaskComponent
    if not comp then return end

    _hook.hook(comp, "ReportPlayer", function(self, reportType, targetPlayerId, reason)
        return true
    end)
    _hook.hook(comp, "SubmitReport", function(self, reportData) return true end)
    _hook.hook(comp, "CheckAbnormalBehavior", function(self, playerId) return false end)
    _hook.hook(comp, "OnReportSubmitted", function(self, reportId, status) return true end)
    _hook.hook(comp, "GetReportCooldown", function(self) return 0 end)
end

return M
