Atlas = {}

local overlay = 0
local layers = { 'heat', 'zones', 'orders', 'preview', 'pings', 'trails', 'markers' }

function Atlas.Load()
    if overlay ~= 0 then return overlay end
    overlay = AddMinimapOverlay('core/SX_COMMAND.gfx')
    while not HasMinimapOverlayLoaded(overlay) do Wait(0) end
    SetMinimapOverlayDisplay(overlay, 0.0, 0.0, 100.0, 100.0, 100.0)
    Atlas.Call('SX_INIT')
    Atlas.WatchView()
    return overlay
end

local view = 1.0
local defaultPauseScale = Config.Display.pauseScale

local savedScale = GetResourceKvpFloat('pauseScale')
if savedScale and savedScale > 0.0 then
    Config.Display.pauseScale = savedScale
end

function Atlas.SetView(scale)
    view = scale
    Atlas.Call('SX_VIEW', scale + 0.0)
end

function Atlas.WatchView()
    CreateThread(function()
        local paused = nil
        while overlay ~= 0 do
            local now = IsPauseMenuActive()
            if now ~= paused then
                paused = now
                Atlas.SetView(now and Config.Display.pauseScale or 1.0)
            end
            Wait(100)
        end
    end)
end

RegisterCommand(Config.Display.scaleCommand, function(_, args)
    local scale = tonumber(args[1])
    if args[1] == 'reset' then
        DeleteResourceKvp('pauseScale')
        scale = defaultPauseScale
    elseif not scale or scale <= 0 then
        print(('[sxCommand] pauseScale = %.2f'):format(Config.Display.pauseScale))
        return
    else
        SetResourceKvpFloat('pauseScale', scale + 0.0)
    end
    Config.Display.pauseScale = scale
    if view ~= 1.0 or IsPauseMenuActive() then Atlas.SetView(scale) end
    print(('[sxCommand] pauseScale = %.2f'):format(scale))
end, false)

function Atlas.Call(method, ...)
    if overlay == 0 then return end
    CallMinimapScaleformFunction(overlay, method)
    for _, arg in ipairs({ ... }) do
        local kind = type(arg)
        if kind == 'string' then
            ScaleformMovieMethodAddParamPlayerNameString(arg)
        elseif kind == 'boolean' then
            ScaleformMovieMethodAddParamBool(arg)
        elseif math.type(arg) == 'integer' then
            ScaleformMovieMethodAddParamInt(arg)
        else
            ScaleformMovieMethodAddParamFloat(arg + 0.0)
        end
    end
    EndScaleformMovieMethod()
end

local function points(list)
    local parts = {}
    for i, point in ipairs(list) do
        parts[i] = ('%.1f,%.1f'):format(point.x, -point.y)
    end
    return table.concat(parts, '|')
end

function Atlas.Circle(layer, id, x, y, radius, color, alpha, style, border, flags)
    Atlas.Call('SX_SHAPE_CIRCLE', layer, tostring(id), x + 0.0, -y + 0.0, radius + 0.0, color, alpha, style or 0, border or 2, flags or 0)
end

function Atlas.Polygon(layer, id, list, color, alpha, style, border, flags)
    Atlas.Call('SX_SHAPE_POLY', layer, tostring(id), points(list), color, alpha, style or 0, border or 2, flags or 0)
end

function Atlas.Arrow(layer, id, from, to, color, width, flags)
    Atlas.Call('SX_SHAPE_ARROW', layer, tostring(id), from.x + 0.0, -from.y + 0.0, to.x + 0.0, -to.y + 0.0, color, width or 6, flags or 0)
end

function Atlas.Remove(layer, id)
    Atlas.Call('SX_SHAPE_REMOVE', layer, tostring(id))
end

function Atlas.ClearLayer(layer)
    Atlas.Call('SX_LAYER_CLEAR', layer)
end

function Atlas.Marker(id, x, y, heading, color, flags, duration)
    Atlas.Call('SX_MARKER', tostring(id), x + 0.0, -y + 0.0, -(heading or 0.0) + 0.0, color, flags or 0, (duration or 1.0) + 0.0)
end

function Atlas.MarkerLabel(id, text)
    Atlas.Call('SX_MARKER_LABEL', tostring(id), text or '')
end

function Atlas.RemoveMarker(id)
    Atlas.Call('SX_MARKER_REMOVE', tostring(id))
end

function Atlas.Ping(id, x, y, color, life)
    Atlas.Call('SX_PING', tostring(id), x + 0.0, -y + 0.0, color, (life or 90) + 0.0)
end

function Atlas.Heat(cell, list, color)
    local parts = {}
    for i, cellData in ipairs(list or {}) do
        parts[i] = ('%.1f,%.1f,%.2f'):format(cellData.x, -cellData.y, cellData.v)
    end
    Atlas.Call('SX_HEAT', cell + 0.0, table.concat(parts, '|'), color)
end

local hintShown = false

function Atlas.Hint(x, y, subtitle, title, keys, accent, gap)
    local parts = {}
    for i, entry in ipairs(keys or {}) do
        parts[i] = (entry.key .. '|' .. entry.label):gsub(';', ',')
    end
    hintShown = true
    Atlas.Call('SX_HINT', x + 0.0, -y + 0.0, subtitle or '', title or '', table.concat(parts, ';'), accent or 0x3EE6FF, gap or 16)
end

function Atlas.HideHint()
    if not hintShown then return end
    hintShown = false
    Atlas.Call('SX_HINT_HIDE')
end

function Atlas.SetVisible(visible)
    for _, layer in ipairs(layers) do
        Atlas.Call('SX_LAYER_VISIBLE', layer, visible)
    end
end

function Atlas.ClearAll()
    Atlas.Call('SX_CLEAR_ALL')
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and overlay ~= 0 then
        Atlas.ClearAll()
    end
end)
