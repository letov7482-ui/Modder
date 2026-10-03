local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

local blockTags = {
    "cheat", "anticheat", "security", "detection", "violation",
    "ace", "report", "abnormal", "inject", "hook", "bypass",
    "modified", "unauthorized", "screenshot", "forensic",
    "integrity", "tamper", "unverified"
}

function M.Init()
    local lm = GameLua.Mod.BaseMod.Common.LogManager
    if not lm then return end

    _hook.hook(lm, "WriteLog", function(self, level, tag, message)
        local check = string.lower(tostring(tag) .. " " .. tostring(message))
        for _, blocked in ipairs(blockTags) do
            if string.find(check, blocked) then return end
        end
        local orig = _getOrig("WriteLog")
        if orig then return orig(self, level, tag, message) end
    end)

    _hook.hook(lm, "SendLog", function(self, logData)
        local check = string.lower(tostring(logData))
        for _, pattern in ipairs(blockTags) do
            if string.find(check, pattern) then return end
        end
        local orig = _getOrig("SendLog")
        if orig then return orig(self, logData) end
    end)

    _hook.hook(lm, "FlushLogs", function(self)
        local orig = _getOrig("FlushLogs")
        if orig then return orig(self) end
    end)
end

return M
