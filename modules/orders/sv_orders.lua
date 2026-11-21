SX.Orders = {}
SX.Modules:Register('Orders', 10)

local TYPES = { rally = 'point', danger = 'point', objective = 'point', axis = 'line', perimeter = 'polygon' }
local orders = {}
local nextId = 0

local function clean(value)
    value = tonumber(value)
    if not value or value ~= value or math.abs(value) > 20000 then return nil end
    return value + 0.0
end

local function sanitizePoints(points, min, max)
    if type(points) ~= 'table' or #points < min or #points > max then return nil end
    local out = {}
    for i, point in ipairs(points) do
        local x, y = clean(point.x), clean(point.y)
        if not x or not y then return nil end
        out[i] = { x = x, y = y }
    end
    return out
end

function SX.Orders:List(factionId)
    local list = {}
    local now = os.time()
    for _, order in ipairs(orders[factionId] or {}) do
        if order.expiresAt > now then list[#list + 1] = order end
    end
    return list
end

function SX.Orders:Sync(factionId)
    local list = self:List(factionId)
    for _, source in ipairs(SX.Factions:Members(factionId)) do
        TriggerClientEvent('sxCommand:orders', source, list)
    end
end

function SX.Orders:SendTo(source)
    local faction = SX.Factions:Get(source)
    TriggerClientEvent('sxCommand:orders', source, faction and self:List(faction.id) or {})
end

function SX.Orders:Create(source, kind, points)
    local faction = SX.Factions:Get(source)
    if not faction or not faction.commander then return false end

    local shape = TYPES[kind]
    if not shape then return false end
    local min = shape == 'point' and 1 or shape == 'line' and 2 or 3
    local max = shape == 'point' and 1 or shape == 'line' and 2 or Config.Orders.maxPoints
    points = sanitizePoints(points, min, max)
    if not points then return false end

    orders[faction.id] = self:List(faction.id)
    local list = orders[faction.id]
    if #list >= Config.Orders.maxPerFaction then table.remove(list, 1) end

    nextId = nextId + 1
    list[#list + 1] = {
        id = nextId,
        kind = kind,
        points = points,
        author = Bridge.GetName(source),
        authorId = source,
        expiresAt = os.time() + Config.Orders.duration * 60,
    }

    self:Sync(faction.id)
    for _, member in ipairs(SX.Factions:Members(faction.id)) do
        if member ~= source then
            TriggerClientEvent('sxCommand:newOrder', member, kind, Bridge.GetName(source))
        end
    end
    TriggerEvent('sxCommand:orderCreated', faction.id, kind, points, source)
    return true
end

function SX.Orders:Undo(source)
    local faction = SX.Factions:Get(source)
    if not faction or not faction.commander then return end
    local list = self:List(faction.id)
    if #list == 0 then return end
    table.remove(list, #list)
    orders[faction.id] = list
    self:Sync(faction.id)
end

function SX.Orders:Clear(source)
    local faction = SX.Factions:Get(source)
    if not faction or not faction.commander then return end
    orders[faction.id] = {}
    self:Sync(faction.id)
end

function SX.Orders:Initialize()
    RegisterNetEvent('sxCommand:createOrder', function(kind, points)
        SX.Orders:Create(source, kind, points)
    end)
    RegisterNetEvent('sxCommand:undoOrder', function()
        SX.Orders:Undo(source)
    end)
    RegisterNetEvent('sxCommand:clearOrders', function()
        SX.Orders:Clear(source)
    end)
end

function SX.Orders:InitializeAsync()
    while true do
        Wait(30000)
        local now = os.time()
        for factionId, list in pairs(orders) do
            local before = #list
            orders[factionId] = self:List(factionId)
            if #orders[factionId] ~= before then self:Sync(factionId) end
            if #orders[factionId] == 0 then orders[factionId] = nil end
        end
    end
end
