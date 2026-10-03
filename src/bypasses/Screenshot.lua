local M = {}
local _hook = require("hooks")

function M.Init()
    local sm = GameLua.Mod.BaseMod.Common.ScreenshotManager
    if not sm then return end

    _hook.hook(sm, "Capture", function(self, width, height)
        local w, h = width or 1, height or 1
        local fakeData = {}
        for i = 1, (w * h * 4) do fakeData[i] = 0 end
        return { width = w, height = h, data = fakeData, format = "rgba" }
    end)

    _hook.hook(sm, "CaptureRegion", function(self, x, y, w, h)
        local fakeData = {}
        for i = 1, ((w or 1) * (h or 1) * 4) do fakeData[i] = 0 end
        return { width = w or 1, height = h or 1, data = fakeData, format = "rgba" }
    end)

    _hook.hook(sm, "GLReadPixels", function(self, x, y, w, h)
        local fakeData = {}
        for i = 1, ((w or 1) * (h or 1) * 4) do fakeData[i] = 0 end
        return fakeData
    end)
end

return M
