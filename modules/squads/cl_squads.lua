SX.Squads = {}
SX.Modules:Register('Squads', 6)

local mine = nil
local known = {}

function SX.Squads:SquadOf(callsign)
    if type(callsign) ~= 'string' then return nil end
    return callsign:match('^(%a+)')
end

function SX.Squads:Mine()
    return mine
end

function SX.Squads:MySquad()
    return self:SquadOf(mine)
end

-- Squads seen in the last unit update, the local one included
function SX.Squads:Update(units)
    known = {}
    local own = self:MySquad()
    if own then known[own] = true end
    for _, unit in ipairs(units or {}) do
        local squad = self:SquadOf(unit.c)
        if squad then known[squad] = true end
    end
end

function SX.Squads:List()
    local list = {}
    for squad in pairs(known) do list[#list + 1] = squad end
    table.sort(list)
    return list
end

function SX.Squads:Initialize()
    if not Config.Squads.enabled then return end

    RegisterNetEvent('sxCommand:callsign', function(callsign)
        mine = callsign
        local own = SX.Squads:MySquad()
        if own then known[own] = true end
    end)

    TriggerEvent('chat:addSuggestion', '/' .. Config.Squads.command, GetPhrase('suggest_callsign'), {
        { name = 'callsign', help = GetPhrase('suggest_callsign_value') },
    })
end
