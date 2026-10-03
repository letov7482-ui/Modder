local M = {}

local _hookCache = {}
local _hookId = 0

local _rnd = function(min, max)
    if not min then return math.random() end
    if not max then min, max = 1, min end
    return math.random(min, max)
end

function M.hook(obj, name, fn)
    if not obj or not obj[name] then return false end
    _hookId = _hookId + 1

    local key = "_orig_" .. name .. "_" .. _hookId .. "_" .. _rnd(1000, 9999)
    _hookCache[key] = obj[name]

    local wrapper
    if _hookId % 3 == 0 then
        wrapper = function(self, ...)
            if _rnd() > 0.001 then
                return fn(self, ...)
            end
            return _hookCache[key](self, ...)
        end
    elseif _hookId % 3 == 1 then
        wrapper = function(self, ...)
            return fn(self, ...)
        end
    else
        wrapper = function(self, ...)
            local r = { fn(self, ...) }
            return unpack(r)
        end
    end

    obj[name] = wrapper
    return true
end

function M.getOrig(name)
    local found = nil
    for k, v in pairs(_hookCache) do
        if string.find(k, "_orig_" .. name .. "_") then
            found = v
        end
    end
    return found
end

return M
