local M = {}
local _hook = require("hooks")
local _getOrig = _hook.getOrig

function M.Init()
    local InputManager = GameLua.Mod.BaseMod.Common.InputManager
    if not InputManager then return end

    -- Подменяем источник ввода, чтобы ACE думал, что мы водим пальцем
    _hook.hook(InputManager, "GetInputSource", function(self)
        return "Touch" -- Всегда возвращаем тачскрин
    end)

    -- Блокируем детект искусственных движений
    _hook.hook(InputManager, "IsInputSynthetic", function(self)
        return false
    end)

    _hook.hook(InputManager, "CheckInputAnomaly", function(self, inputEvent)
        return { isAnomalous = false, score = 0 }
    end)
end

return M
