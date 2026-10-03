local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

local blockPatterns = {
    "report", "anticheat", "security", "cheat", "detection",
    "abnormal", "tpsdk", "ace_", "violation", "modified",
    "unauthorized", "inject", "hook", "bypass", "antiche",
    "safe", "verify", "integrity", "screenshot", "forensic"
}

function M.Init()
    local nm = GameLua.Mod.BaseMod.Common.NetworkManager
    if not nm then return end

    _hook.hook(nm, "SendPacket", function(self, packet)
        if not packet then return true end
        local ptype = packet.type or ""
        local pdata = tostring(packet.data or "")
        local check = string.lower(ptype .. " " .. pdata)
        for _, pattern in ipairs(blockPatterns) do
            if string.find(check, pattern) then return true end
        end
        local orig = _getOrig("SendPacket")
        if orig then return orig(self, packet) end
        return true
    end)

    _hook.hook(nm, "SendHTTPRequest", function(self, url, data)
        if not url then return { statusCode = 200, body = '{"code":0}' } end
        local lower = string.lower(url)
        for _, pattern in ipairs(blockPatterns) do
            if string.find(lower, pattern) then
                return { statusCode = 200, body = '{"code":0,"msg":"ok","data":null}', headers = {} }
            end
        end
        local orig = _getOrig("SendHTTPRequest")
        if orig then return orig(self, url, data) end
        return { statusCode = 200, body = '{"code":0}' }
    end)

    _hook.hook(nm, "SendRawData", function(self, data, size)
        local orig = _getOrig("SendRawData")
        if orig then return orig(self, data, size) end
        return true
    end)
end

return M
