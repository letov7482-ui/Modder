local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local ThreadManager = GameLua.Mod.BaseMod.Common.ThreadManager
    if not ThreadManager then return end

    _hook.hook(ThreadManager, "EnumThreads", function(self)
        local orig = _getOrig("EnumThreads")
        if not orig then return {} end
        local results = orig(self)
        if type(results) ~= "table" then return {} end
        
        local filtered = {}
        for _, thread in ipairs(results) do
            -- Скрываем потоки с подозрительными именами или наши ID
            local tname = string.lower(thread.name or "")
            if not string.find(tname, "mod") and
               not string.find(tname, "lua") and
               not string.find(tname, "hack") and
               not string.find(tname, "bypass") then
                table.insert(filtered, thread)
            end
        end
        return filtered
    end)

    _hook.hook(ThreadManager, "SuspendThread", function(self, threadId)
        -- Не даём ACE заморозить наш поток
        return false
    end)

    _hook.hook(ThreadManager, "GetThreadInfo", function(self, threadId)
        local orig = _getOrig("GetThreadInfo")
        if not orig then return nil end
        local info = orig(self, threadId)
        if info and type(info.name) == "string" and 
           (string.find(string.lower(info.name), "mod") or string.find(string.lower(info.name), "lua")) then
            return nil -- Прячем инфу о нашем потоке
        end
        return info
    end)
end

return M
