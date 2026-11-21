SX.Intel = {}
SX.Modules:Register('Intel', 15)

local heat = {}
local lastPing = {}
local nextPing = 0

function SX.Intel:AddShot(coords)
    if not Config.Heat.enabled or not coords then return end
    local cell = Config.Heat.cell
    local key = math.floor(coords.x / cell) .. ':' .. math.floor(coords.y / cell)
    heat[key] = math.min(1.0, (heat[key] or 0.0) + Config.Heat.shot)
end

function SX.Intel:HeatPayload()
    local cell = Config.Heat.cell
    local parts = {}
    for key, value in pairs(heat) do
        local gx, gy = key:match('^(%-?%d+):(%-?%d+)$')
        parts[#parts + 1] = { x = (tonumber(gx) + 0.5) * cell, y = (tonumber(gy) + 0.5) * cell, v = value }
    end
    return parts
end

function SX.Intel:Ping(source, x, y, z)
    local faction = SX.Factions:Get(source)
    if not faction then return end
    local now = GetGameTimer()
    if lastPing[source] and now - lastPing[source] < Config.Pings.cooldown * 1000 then return end
    lastPing[source] = now

    x, y = tonumber(x), tonumber(y)
    if not x or not y then return end
    nextPing = nextPing + 1
    local ping = { id = nextPing, x = x + 0.0, y = y + 0.0, z = (tonumber(z) or 0.0) + 0.0, author = Bridge.GetName(source), authorId = source }
    for _, member in ipairs(SX.Factions:Members(faction.id)) do
        TriggerClientEvent('sxCommand:ping', member, ping)
    end
    TriggerEvent('sxCommand:pinged', faction.id, ping, source)
end

function SX.Intel:Initialize()
    RegisterNetEvent('sxCommand:sendPing', function(x, y, z)
        SX.Intel:Ping(source, x, y, z)
    end)
    AddEventHandler('playerDropped', function()
        lastPing[source] = nil
    end)
end

function SX.Intel:InitializeAsync()
    if not Config.Heat.enabled then return end
    while true do
        Wait(Config.Heat.interval * 1000)
        for key, value in pairs(heat) do
            value = value * Config.Heat.decay
            heat[key] = value > 0.03 and value or nil
        end
        local payload = self:HeatPayload()
        for _, members in pairs(SX.Factions:All()) do
            for _, source in ipairs(members) do
                TriggerClientEvent('sxCommand:heat', source, payload)
            end
        end
    end
end
