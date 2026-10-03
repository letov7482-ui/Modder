local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local le = GameLua.Mod.BaseMod.Common.LuaEnvironment
    if not le then return end

    _hook.hook(le, "GetGlobalTable", function(self)
        local fake = {}
        for k, v in pairs(_G) do
            if type(k) == "string" then
                local lk = string.lower(k)
                if not string.find(lk, "esp") and
                   not string.find(lk, "aimbot") and
                   not string.find(lk, "norecoil") and
                   not string.find(lk, "bypass") and
                   not string.find(lk, "hook") and
                   not string.find(lk, "mod") and
                   not string.find(lk, "cheat") and
                   not string.find(lk, "hack") then
                    fake[k] = v
                end
            end
        end
        return fake
    end)

    _hook.hook(le, "ScanGlobals", function(self)
        return { isClean = true, modified = {}, count = 0 }
    end)

    _hook.hook(le, "GetLoadedFiles", function(self)
        local orig = _getOrig("GetLoadedFiles")
        if not orig then return {} end
        local results = orig(self)
        if type(results) ~= "table" then return {} end
        local filtered = {}
        for _, file in ipairs(results) do
            if not (file and type(file) == "string" and (string.find(file, "ModEntry") or string.find(file, "game_patch"))) then
                table.insert(filtered, file)
            end
        end
        return filtered
    end)
end

return M
