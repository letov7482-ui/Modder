local M = {}
local _hook = require("hooks")

function M.Init()
    local ce = GameLua.Mod.BaseMod.Common.Security.CEDetector
    if not ce then return end

    _hook.hook(ce, "Detect", function(self)
        return { detected = false, processes = {}, modules = {} }
    end)
    _hook.hook(ce, "ScanForDebugger", function(self) return false end)
    _hook.hook(ce, "ScanForBreakpoints", function(self)
        return { detected = false, addresses = {} }
    end)
    _hook.hook(ce, "CheckProcessList", function(self)
        return { suspicious = {}, count = 0 }
    end)
end

return M
