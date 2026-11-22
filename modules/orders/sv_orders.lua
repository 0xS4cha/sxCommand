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

-- Checks an order and returns { kind, points, squad } or nil
function SX.Orders:Build(kind, points, squad)
    local shape = TYPES[kind]
    if not shape then return nil end
    local min = shape == 'point' and 1 or shape == 'line' and 2 or 3
    local max = shape == 'point' and 1 or shape == 'line' and 2 or Config.Orders.maxPoints
    points = sanitizePoints(points, min, max)
    if not points then return nil end
    return { kind = kind, points = points, squad = squad and SX.Squads:NormalizeSquad(squad) or nil }
end

function SX.Orders:List(factionId)
    local list = {}
    local now = os.time()
    for _, order in ipairs(orders[factionId] or {}) do
        if order.expiresAt > now then list[#list + 1] = order end
    end
    return list
end

-- A commander editing a plan sees the plan instead of the live orders
function SX.Orders:SendTo(source)
    if SX.Plans:IsEditing(source) then
        SX.Plans:SendDraft(source)
        return
    end
    local faction = SX.Factions:Get(source)
    TriggerClientEvent('sxCommand:orders', source, faction and self:List(faction.id) or {})
end

function SX.Orders:Sync(factionId)
    local list = self:List(factionId)
    for _, source in ipairs(SX.Factions:Members(factionId)) do
        if SX.Plans:IsEditing(source) then
            SX.Plans:SendDraft(source)
        else
            TriggerClientEvent('sxCommand:orders', source, list)
        end
    end
end

local function newOrder(entry, author, authorId)
    nextId = nextId + 1
    return {
        id = nextId,
        kind = entry.kind,
        points = entry.points,
        squad = entry.squad,
        author = author,
        authorId = authorId,
        expiresAt = os.time() + Config.Orders.duration * 60,
    }
end

-- Members who receive the card of an order: its squad, or everyone when it has none
local function concerned(member, squad)
    if not squad then return true end
    return SX.Squads:GetSquad(member) == squad or (SX.Factions:Get(member) or {}).commander == true
end

function SX.Orders:Create(source, kind, points, squad)
    local faction = SX.Factions:Get(source)
    if not faction or not faction.commander then return false end

    local entry = self:Build(kind, points, squad)
    if not entry then return false end

    if SX.Plans:IsEditing(source) then
        return SX.Plans:AddDraft(source, entry)
    end

    orders[faction.id] = self:List(faction.id)
    local list = orders[faction.id]
    if #list >= Config.Orders.maxPerFaction then table.remove(list, 1) end

    local author = Bridge.GetName(source)
    list[#list + 1] = newOrder(entry, author, source)

    self:Sync(faction.id)
    for _, member in ipairs(SX.Factions:Members(faction.id)) do
        if member ~= source and not SX.Plans:IsEditing(member) and concerned(member, entry.squad) then
            TriggerClientEvent('sxCommand:newOrder', member, entry.kind, author, entry.squad)
        end
    end
    TriggerEvent('sxCommand:orderCreated', faction.id, entry.kind, entry.points, source, entry.squad)
    return true
end

-- Replaces the orders of a faction, used to deploy a saved plan
function SX.Orders:Replace(factionId, entries, author, authorId)
    local list = {}
    for _, entry in ipairs(entries) do
        if #list >= Config.Orders.maxPerFaction then break end
        local order = self:Build(entry.kind, entry.points, entry.squad)
        if order then list[#list + 1] = newOrder(order, author, authorId) end
    end
    orders[factionId] = list
    self:Sync(factionId)
    return #list
end

function SX.Orders:Undo(source)
    local faction = SX.Factions:Get(source)
    if not faction or not faction.commander then return end
    if SX.Plans:IsEditing(source) then
        SX.Plans:UndoDraft(source)
        return
    end
    local list = self:List(faction.id)
    if #list == 0 then return end
    table.remove(list, #list)
    orders[faction.id] = list
    self:Sync(faction.id)
end

function SX.Orders:Clear(source)
    local faction = SX.Factions:Get(source)
    if not faction or not faction.commander then return end
    if SX.Plans:IsEditing(source) then
        SX.Plans:ClearDraft(source)
        return
    end
    orders[faction.id] = {}
    self:Sync(faction.id)
end

function SX.Orders:Initialize()
    RegisterNetEvent('sxCommand:createOrder', function(kind, points, squad)
        SX.Orders:Create(source, kind, points, squad)
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
        for factionId, list in pairs(orders) do
            local before = #list
            orders[factionId] = self:List(factionId)
            if #orders[factionId] ~= before then self:Sync(factionId) end
            if #orders[factionId] == 0 then orders[factionId] = nil end
        end
    end
end
