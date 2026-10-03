local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local FileSystem = GameLua.Mod.BaseMod.Common.FileSystem
    if not FileSystem then return end

    _hook.hook(FileSystem, "DeleteFile", function(self, path)
        if path and (string.find(path, "puffer_temp") or string.find(path, "game_patch")) then
            return true
        end
        local orig = _getOrig("DeleteFile")
        if orig then return orig(self, path) end
        return true
    end)

    _hook.hook(FileSystem, "RemoveDirectory", function(self, path)
        if path and string.find(path, "puffer_temp") then return true end
        local orig = _getOrig("RemoveDirectory")
        if orig then return orig(self, path) end
        return true
    end)

    _hook.hook(FileSystem, "RenameFile", function(self, oldPath, newPath)
        if oldPath and (string.find(oldPath, "puffer_temp") or string.find(oldPath, "game_patch")) then
            return true
        end
        local orig = _getOrig("RenameFile")
        if orig then return orig(self, oldPath, newPath) end
        return true
    end)

    _hook.hook(FileSystem, "GetFileAttributes", function(self, path)
        if path and string.find(path, "game_patch") then
            return { readOnly = true, hidden = false, system = true }
        end
        local orig = _getOrig("GetFileAttributes")
        if orig then return orig(self, path) end
        return { readOnly = false, hidden = false, system = false }
    end)
end

return M
