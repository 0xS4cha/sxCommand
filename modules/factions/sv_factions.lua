SX.Factions = {}
SX.Modules:Register('Factions', 5)

local membership = {}

local function rgbToInt(rgb)
    if type(rgb) ~= 'table' then return 0xFFFFFF end
    return ((rgb.r or 255) << 16) | ((rgb.g or 255) << 8) | (rgb.b or 255)
end

local function same(a, b)
    if a == nil or b == nil then return a == b end
    return a.id == b.id and a.commander == b.commander and a.color == b.color and a.label == b.label
end

function SX.Factions:Resolve(source)
    local job, grade = Bridge.GetJob(source)
    local settings = job and Config.Factions.jobs[job]
    if settings then
        return { id = 'job:' .. job, label = settings.label, color = settings.color, commander = grade >= settings.commandGrade }
    end

    local ace = Config.Factions.ace
    if ace and ace.member and IsPlayerAceAllowed(source, ace.member) then
        local base = Config.Factions.jobs[ace.job] or { label = ace.job, color = 0x3EE6FF }
        return { id = 'job:' .. ace.job, label = base.label, color = base.color, commander = IsPlayerAceAllowed(source, ace.commander) }
    end

    if Config.Factions.sxIllegalsGroups then
        local group = Bridge.GetIllegalsGroup(source)
        if group and group.id then
            return { id = 'group:' .. group.id, label = group.name, color = rgbToInt(group.rgb), commander = Bridge.IsIllegalsCommander(source) }
        end
    end

    return nil
end

function SX.Factions:Get(source)
    return membership[source]
end

function SX.Factions:Members(factionId)
    local list = {}
    for source, faction in pairs(membership) do
        if faction.id == factionId then list[#list + 1] = source end
    end
    return list
end

function SX.Factions:All()
    local factions = {}
    for source, faction in pairs(membership) do
        factions[faction.id] = factions[faction.id] or {}
        table.insert(factions[faction.id], source)
    end
    return factions
end

function SX.Factions:Refresh(source)
    if not GetPlayerName(source) then
        membership[source] = nil
        return
    end
    local faction = self:Resolve(source)
    if faction then SX.Squads:Load(source) end
    if same(faction, membership[source]) then return end
    local previous = membership[source]
    membership[source] = faction
    if previous and (not faction or faction.id ~= previous.id or not faction.commander) then
        SX.Plans:Stop(source)
    end
    TriggerClientEvent('sxCommand:faction', source, faction)
    if faction then SX.Orders:SendTo(source) end
end

function SX.Factions:RefreshAll()
    for _, playerId in ipairs(GetPlayers()) do
        self:Refresh(tonumber(playerId))
    end
end

local function registerPermission()
    if not Bridge.HasIllegals() then return end
    pcall(function() exports.sxIllegals:RegisterGroupPermission('canCommand', 'Tactical command') end)
end

function SX.Factions:Initialize()
    Bridge.OnJobChange(function(source)
        SX.Factions:Refresh(source)
    end)

    RegisterNetEvent('sxCommand:ready', function()
        local src = source
        membership[src] = nil
        SX.Factions:Refresh(src)
    end)

    AddEventHandler('playerDropped', function()
        membership[source] = nil
    end)

    AddEventHandler('onResourceStart', function(resource)
        if resource == 'sxIllegals' then registerPermission() end
    end)
    registerPermission()
end

function SX.Factions:InitializeAsync()
    while true do
        self:RefreshAll()
        Wait(Config.Factions.refresh * 1000)
    end
end
