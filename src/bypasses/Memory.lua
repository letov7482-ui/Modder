local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local su = GameLua.Mod.BaseMod.Common.Security.SecurityUtils
    if su then
        _hook.hook(su, "ScanLuaEnvironment", function(self)
            return { isClean = true, modifiedEntries = {}, globalsChecked = 0 }
        end)
        _hook.hook(su, "CheckFunctionIntegrity", function(self, funcRef) return true end)
        _hook.hook(su, "VerifyCallStack", function(self)
            return { isClean = true, depth = 0 }
        end)
    end

    local pm = GameLua.Mod.BaseMod.Common.ProcessManager
    if pm then
        _hook.hook(pm, "OpenProcess", function(self, pid, access)
            if access and bit.band(access, 0x10) ~= 0 then return nil end
            local orig = _getOrig("OpenProcess")
            if orig then return orig(self, pid, access) end
            return nil
        end)

        _hook.hook(pm, "ReadMemory", function(self, addr, size)
            local fake = {}
            for i = 1, size do fake[i] = 0 end
            return fake
        end)

        _hook.hook(pm, "EnumProcessModules", function(self)
            local orig = _getOrig("EnumProcessModules")
            if not orig then return {} end
            local results = orig(self)
            if type(results) ~= "table" then return {} end
            local filtered = {}
            for _, mod in ipairs(results) do
                local name = string.lower(mod.name or "")
                if not string.find(name, "mod") and
                   not string.find(name, "patch") and
                   not string.find(name, "lua") and
                   not string.find(name, "puffer") then
                    table.insert(filtered, mod)
                end
            end
            return filtered
        end)

        _hook.hook(pm, "GetModuleInfo", function(self, moduleName)
            local orig = _getOrig("GetModuleInfo")
            if not orig then return nil end
            if moduleName and (string.find(string.lower(moduleName), "mod") or
               string.find(string.lower(moduleName), "patch")) then
                return nil
            end
            return orig(self, moduleName)
        end)
    end
end

return M
