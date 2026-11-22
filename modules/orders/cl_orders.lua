SX.Orders = {}
SX.Modules:Register('Orders', 10)

COLORS = {
    rally = 0x5EF0A4,
    axis = 0x5EF0A4,
    danger = 0xFF5A4F,
    objective = 0x3EE6FF,
    perimeter = 0xFFC94D,
    ping = 0xFF5A4F,
    heat = 0xFF5A4F,
}

function SX.Orders:Draw(layer, id, kind, points, dim)
    local p = points[1]
    local fade = dim and 0.35 or 1.0
    local border = dim and 1 or 3
    local function alpha(value) return math.floor(value * fade) end
    local function flags(value) return dim and 0 or value end
    if kind == 'rally' then
        Atlas.Circle(layer, id, p.x, p.y, Config.Orders.radius.rally, COLORS.rally, alpha(55), 1, border, flags(1))
    elseif kind == 'danger' then
        Atlas.Circle(layer, id, p.x, p.y, Config.Orders.radius.danger, COLORS.danger, alpha(75), 2, border, flags(3))
    elseif kind == 'objective' then
        Atlas.Circle(layer, id, p.x, p.y, Config.Orders.radius.objective, COLORS.objective, alpha(65), 0, border, flags(1))
    elseif kind == 'axis' and points[2] then
        Atlas.Arrow(layer, id, p, points[2], COLORS.axis, dim and 3 or 7, flags(4))
    elseif kind == 'perimeter' and #points >= 3 then
        Atlas.Polygon(layer, id, points, COLORS.perimeter, alpha(18), 0, border, flags(2))
    end
end

local function forOthers(order)
    if not order.squad or SX.Faction:IsCommander() then return false end
    return SX.Squads:MySquad() ~= order.squad
end

local last = {}

function SX.Orders:Render(list)
    last = list or {}
    Atlas.ClearLayer('orders')
    for _, order in ipairs(list or {}) do
        self:Draw('orders', 'o' .. order.id, order.kind, order.points, forOthers(order))
    end
end

function SX.Orders:Initialize()
    RegisterNetEvent('sxCommand:orders', function(list)
        if not SX.Faction:Get() then return end
        SX.Orders:Render(list)
    end)

    RegisterNetEvent('sxCommand:callsign', function()
        if SX.Faction:Get() then SX.Orders:Render(last) end
    end)

    RegisterNetEvent('sxCommand:newOrder', function(kind, author, squad)
        local rows = { { type = 'text', label = GetPhrase('order_hint'), value = GetPhrase('order_hint_value'), icon = 'map', tone = 'accent' } }
        if squad then
            table.insert(rows, 1, { type = 'text', label = GetPhrase('command_target'), value = squad, icon = 'users', tone = 'warning', scramble = false })
        end
        local shown = HelpUI.Show('order', 'order', {
            header = { subtitle = GetPhrase('order_from', author), title = GetPhrase('order_' .. kind), watermark = GetPhrase('order_watermark') },
            rows = rows,
            duration = 6000,
            position = 'top-right',
        })
        PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
        if not shown then
            Bridge.Notify(GetPhrase('notify_order', author, GetPhrase('order_' .. kind)), 'info')
        end
    end)
end
