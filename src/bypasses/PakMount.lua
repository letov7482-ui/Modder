local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local PakFile = GameLua.Mod.BaseMod.Common.PakFile
    if not PakFile then return end

    _hook.hook(PakFile, "Unmount", function(self, pakPath)
        if pakPath and (string.find(pakPath, "puffer_temp") or string.find(pakPath, "game_patch")) then
            return false -- Блокируем отмонтирование
        end
        local orig = _getOrig("Unmount")
        if orig then return orig(self, pakPath) end
        return false
    end)

    _hook.hook(PakFile, "UnregisterPak", function(self, pakPath)
        if pakPath and (string.find(pakPath, "puffer_temp") or string.find(pakPath, "game_patch")) then
            return false
        end
        local orig = _getOrig("UnregisterPak")
        if orig then return orig(self, pakPath) end
        return false
    end)
end

return M
