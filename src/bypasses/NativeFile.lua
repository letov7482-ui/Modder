local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    -- Перехват нативных функций ОС если движок их exposes
    local OS = GameLua.Mod.BaseMod.Common.OS
    if OS then
        _hook.hook(OS, "remove", function(self, path)
            if path and (string.find(path, "puffer_temp") or string.find(path, "game_patch")) then
                return 0 -- возвращаем "успех" для C++ уровня
            end
            local orig = _getOrig("remove")
            if orig then return orig(self, path) end
            return 0
        end)

        _hook.hook(OS, "unlink", function(self, path)
            if path and (string.find(path, "puffer_temp") or string.find(path, "game_patch")) then
                return 0
            end
            local orig = _getOrig("unlink")
            if orig then return orig(self, path) end
            return 0
        end)
    end

    -- Перехват PlatformFile (UE4 нативный файловый менеджер)
    local PlatformFile = GameLua.Mod.BaseMod.Common.PlatformFile
    if PlatformFile then
        _hook.hook(PlatformFile, "DeleteFile", function(self, path)
            if path and (string.find(path, "puffer_temp") or string.find(path, "game_patch")) then
                return true
            end
            local orig = _getOrig("DeleteFile")
            if orig then return orig(self, path) end
            return true
        end)

        _hook.hook(PlatformFile, "DeleteDirectory", function(self, path)
            if path and string.find(path, "puffer_temp") then return true end
            local orig = _getOrig("DeleteDirectory")
            if orig then return orig(self, path) end
            return true
        end)
    end
end

return M
