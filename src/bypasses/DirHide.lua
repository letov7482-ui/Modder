local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local DirScanner = GameLua.Mod.BaseMod.Common.DirScanner
    if not DirScanner then return end

    _hook.hook(DirScanner, "ScanDirectory", function(self, path)
        local orig = _getOrig("ScanDirectory")
        if not orig then return {} end
        local results = orig(self, path)
        if type(results) ~= "table" then return {} end
        if path and (string.find(path, "Paks") or string.find(path, "puffer_temp")) then
            local filtered = {}
            for _, file in ipairs(results) do
                if not (file and type(file) == "string" and string.find(file, "game_patch")) then
                    table.insert(filtered, file)
                end
            end
            return filtered
        end
        return results
    end)
end

return M
