SX.Squads = {}
SX.Modules:Register('Squads', 6)

local callsigns = {}
local loadedFor = {}

local function storeKey(identifier)
    return 'callsign:' .. identifier
end

local function notify(source, phrase, ...)
    Bridge.Notify(source, GetPhrase(phrase, ...), 'info')
end

function SX.Squads:Normalize(value)
    if type(value) ~= 'string' then return nil end
    value = Utils.Trim(value):upper()
    if value == '' or #value > Config.Squads.maxLength or not value:match('^[%w%-]+$') then return nil end
    return value
end

-- ADAM-12 and ADAM12 are in the ADAM squad, a callsign without letters has no squad
function SX.Squads:SquadOf(callsign)
    if type(callsign) ~= 'string' then return nil end
    return callsign:match('^(%a+)')
end

function SX.Squads:NormalizeSquad(value)
    if type(value) ~= 'string' then return nil end
    value = value:upper()
    if #value > Config.Squads.maxLength or not value:match('^%a+$') then return nil end
    return value
end

function SX.Squads:Get(source)
    return callsigns[source]
end

function SX.Squads:GetSquad(source)
    return self:SquadOf(callsigns[source])
end

-- Loads the saved callsign, again when the player switches to another character
function SX.Squads:Load(source)
    if not Config.Squads.enabled then return end
    local identifier = Bridge.GetIdentifier(source)
    if not identifier or loadedFor[source] == identifier then return end
    loadedFor[source] = identifier
    callsigns[source] = GetResourceKvpString(storeKey(identifier))
    TriggerClientEvent('sxCommand:callsign', source, callsigns[source])
end

function SX.Squads:Set(source, callsign)
    callsign = callsign and self:Normalize(callsign) or nil
    callsigns[source] = callsign
    local identifier = Bridge.GetIdentifier(source)
    if identifier then
        loadedFor[source] = identifier
        if callsign then
            SetResourceKvp(storeKey(identifier), callsign)
        else
            DeleteResourceKvp(storeKey(identifier))
        end
    end
    TriggerClientEvent('sxCommand:callsign', source, callsign)
    TriggerEvent('sxCommand:callsignChanged', source, callsign)
    return callsign
end

local function command(source, args)
    if source == 0 then return end
    local faction = SX.Factions:Get(source)
    if not faction then
        notify(source, 'notify_no_faction')
        return
    end

    local target, value = source, args[1]
    if args[3] or (args[2] and not tonumber(args[1])) then
        notify(source, 'callsign_invalid', Config.Squads.maxLength)
        return
    end
    if args[2] then
        target, value = tonumber(args[1]), args[2]
        if not faction.commander then
            notify(source, 'notify_not_commander')
            return
        end
        local other = SX.Factions:Get(target)
        if target ~= source and (not other or other.id ~= faction.id) then
            notify(source, 'callsign_not_member')
            return
        end
    end

    if not value then
        local current = SX.Squads:Get(target)
        notify(source, current and 'callsign_current' or 'callsign_none', current)
        return
    end

    if value:lower() == 'clear' then
        SX.Squads:Set(target, nil)
        notify(source, 'callsign_cleared')
        return
    end

    local callsign = SX.Squads:Normalize(value)
    if not callsign then
        notify(source, 'callsign_invalid', Config.Squads.maxLength)
        return
    end

    SX.Squads:Set(target, callsign)
    notify(source, 'callsign_set', callsign)
    if target ~= source then
        notify(target, 'callsign_set_by', callsign, Bridge.GetName(source))
    end
end

function SX.Squads:Initialize()
    if not Config.Squads.enabled then return end

    RegisterCommand(Config.Squads.command, command, false)

    AddEventHandler('playerDropped', function()
        callsigns[source] = nil
        loadedFor[source] = nil
    end)
end
