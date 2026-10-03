local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

local rpcBlockList = {
    "ServerCheck", "SecurityRPC", "AntiCheatRPC", 
    "VerifyClient", "RequestClientInfo", "CheckIntegrity",
    "SendClientHash", "PingAntiCheat"
}

function M.Init()
    local NetDriver = GameLua.Mod.BaseMod.Common.NetDriver
    if NetDriver then
        _hook.hook(NetDriver, "ProcessRPC", function(self, rpcName, params)
            local lowerName = string.lower(tostring(rpcName))
            for _, pattern in ipairs(rpcBlockList) do
                if string.find(lowerName, string.lower(pattern)) then
                    return -- Глушим RPC
                end
            end
            local orig = _getOrig("ProcessRPC")
            if orig then return orig(self, rpcName, params) end
        end)
    end
end

return M
