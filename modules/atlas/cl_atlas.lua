Atlas = {}

local overlay = 0
local layers = { 'heat', 'zones', 'orders', 'preview', 'pings', 'trails', 'markers' }

function Atlas.Load()
    if overlay ~= 0 then return overlay end
    overlay = AddMinimapOverlay('core/SX_COMMAND.gfx')
    while not HasMinimapOverlayLoaded(overlay) do Wait(0) end
    SetMinimapOverlayDisplay(overlay, 0.0, 0.0, 100.0, 100.0, 100.0)
    Atlas.Call('SX_INIT')
    return overlay
end

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

-- style: 0 solid, 1 soft gradient, 2 hatched. flags: 1 pulse, 2 dashed border, 4 flowing (arrows)
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

-- flags: 1 injured, 2 firing, 4 commander. heading in GTA degrees.
function Atlas.Marker(id, x, y, heading, color, flags, duration)
    Atlas.Call('SX_MARKER', tostring(id), x + 0.0, -y + 0.0, -(heading or 0.0) + 0.0, color, flags or 0, (duration or 1.0) + 0.0)
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
