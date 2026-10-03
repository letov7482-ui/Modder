local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local fm = GameLua.Mod.BaseMod.Common.FileManager
    if not fm then return end

    _hook.hook(fm, "GetFileHash", function(self, path)
        if path and (string.find(path, "game_patch") or string.find(path, "puffer_temp")) then
            return "ORIGINAL_HASH_PLACEHOLDER"
        end
        local orig = _getOrig("GetFileHash")
        if orig then return orig(self, path) end
        return ""
    end)

    _hook.hook(fm, "VerifyFile", function(self, path, expectedHash)
        if path and (string.find(path, "game_patch") or string.find(path, "puffer_temp")) then
            return true
        end
        local orig = _getOrig("VerifyFile")
        if orig then return orig(self, path, expectedHash) end
        return true
    end)
end

return M
