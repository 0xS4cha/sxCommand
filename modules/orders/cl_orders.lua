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

function SX.Orders:Draw(layer, id, kind, points)
    local p = points[1]
    if kind == 'rally' then
        Atlas.Circle(layer, id, p.x, p.y, Config.Orders.radius.rally, COLORS.rally, 55, 1, 3, 1)
    elseif kind == 'danger' then
        Atlas.Circle(layer, id, p.x, p.y, Config.Orders.radius.danger, COLORS.danger, 75, 2, 3, 3)
    elseif kind == 'objective' then
        Atlas.Circle(layer, id, p.x, p.y, Config.Orders.radius.objective, COLORS.objective, 65, 0, 3, 1)
    elseif kind == 'axis' and points[2] then
        Atlas.Arrow(layer, id, p, points[2], COLORS.axis, 7, 4)
    elseif kind == 'perimeter' and #points >= 3 then
        Atlas.Polygon(layer, id, points, COLORS.perimeter, 18, 0, 3, 2)
    end
end

function SX.Orders:Render(list)
    Atlas.ClearLayer('orders')
    for _, order in ipairs(list or {}) do
        self:Draw('orders', 'o' .. order.id, order.kind, order.points)
    end
end

function SX.Orders:Initialize()
    RegisterNetEvent('sxCommand:orders', function(list)
        if not SX.Faction:Get() then return end
        SX.Orders:Render(list)
    end)

    RegisterNetEvent('sxCommand:newOrder', function(kind, author)
        local shown = HelpUI.Show('order', 'order', {
            header = { subtitle = GetPhrase('order_from', author), title = GetPhrase('order_' .. kind), watermark = GetPhrase('order_watermark') },
            rows = { { type = 'text', label = GetPhrase('order_hint'), value = GetPhrase('order_hint_value'), icon = 'map', tone = 'accent' } },
            duration = 6000,
            position = 'top-right',
        })
        PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
        if not shown then
            Bridge.Notify(GetPhrase('notify_order', author, GetPhrase('order_' .. kind)), 'info')
        end
    end)
end
