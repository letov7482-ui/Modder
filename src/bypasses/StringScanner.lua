local M = {}
local _hook = require("hooks")

function M.Init()
    local ss = GameLua.Mod.BaseMod.Common.Security.StringScanner
    if not ss then return end

    _hook.hook(ss, "ScanStrings", function(self, region, patterns) return {} end)
    _hook.hook(ss, "ScanForPattern", function(self, pattern) return false end)
    _hook.hook(ss, "ScanMemoryRegion", function(self, start, size)
        return { detected = false, matches = {} }
    end)
    _hook.hook(ss, "CheckForKnownSignatures", function(self)
        return { detected = false, signatures = {} }
    end)
end

return M
