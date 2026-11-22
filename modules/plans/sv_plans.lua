SX.Plans = {}
SX.Modules:Register('Plans', 12)

local editing = {}
local nextDraft = 0

local function storeKey(factionId)
    return 'plans:' .. factionId
end

local function readPlans(factionId)
    local raw = GetResourceKvpString(storeKey(factionId))
    local ok, plans = pcall(json.decode, raw or '{}')
    return ok and type(plans) == 'table' and plans or {}
end

local function writePlans(factionId, plans)
    SetResourceKvp(storeKey(factionId), json.encode(plans))
end

local function count(map)
    local total = 0
    for _ in pairs(map) do total = total + 1 end
    return total
end

local function notify(source, phrase, ...)
    Bridge.Notify(source, GetPhrase(phrase, ...), 'info')
end

local function normalizeName(value)
    if type(value) ~= 'string' then return nil end
    value = Utils.Trim(value)
    if value == '' or #value > Config.Plans.maxNameLength or not value:match('^[%w%-_ ]+$') then return nil end
    return value, value:lower()
end

local function entries(list)
    local out = {}
    for _, order in ipairs(list) do
        out[#out + 1] = { kind = order.kind, points = order.points, squad = order.squad }
    end
    return out
end

function SX.Plans:IsEditing(source)
    return editing[source] ~= nil
end

function SX.Plans:SendDraft(source)
    local draft = editing[source]
    if not draft then return end
    TriggerClientEvent('sxCommand:orders', source, draft.orders)
end

function SX.Plans:AddDraft(source, entry)
    local draft = editing[source]
    if not draft then return false end
    if #draft.orders >= Config.Orders.maxPerFaction then
        notify(source, 'plan_full', Config.Orders.maxPerFaction)
        return false
    end
    nextDraft = nextDraft + 1
    entry.id = 'p' .. nextDraft
    draft.orders[#draft.orders + 1] = entry
    self:SendDraft(source)
    return true
end

function SX.Plans:UndoDraft(source)
    local draft = editing[source]
    if not draft or #draft.orders == 0 then return end
    table.remove(draft.orders, #draft.orders)
    self:SendDraft(source)
end

function SX.Plans:ClearDraft(source)
    local draft = editing[source]
    if not draft then return end
    draft.orders = {}
    self:SendDraft(source)
end

function SX.Plans:Stop(source)
    if not editing[source] then return end
    editing[source] = nil
    TriggerClientEvent('sxCommand:planEditing', source, nil)
    if GetPlayerName(source) then SX.Orders:SendTo(source) end
end

function SX.Plans:List(factionId)
    local list = {}
    for _, plan in pairs(readPlans(factionId)) do
        list[#list + 1] = { name = plan.name, orders = #plan.orders, author = plan.author, savedAt = plan.savedAt }
    end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

function SX.Plans:Save(factionId, name, list, author)
    local display, key = normalizeName(name)
    if not display then return false, 'plan_invalid_name' end
    local plans = readPlans(factionId)
    if not plans[key] and count(plans) >= Config.Plans.maxPerFaction then return false, 'plan_limit' end
    plans[key] = { name = display, orders = entries(list), author = author, savedAt = os.time() }
    writePlans(factionId, plans)
    return true
end

function SX.Plans:Delete(factionId, name)
    local _, key = normalizeName(name)
    local plans = readPlans(factionId)
    if not key or not plans[key] then return false end
    plans[key] = nil
    writePlans(factionId, plans)
    return true
end

function SX.Plans:Deploy(factionId, name, source)
    local _, key = normalizeName(name)
    local plan = key and readPlans(factionId)[key]
    if not plan then return nil end
    local author = source and Bridge.GetName(source) or plan.author or 'HQ'
    local total = SX.Orders:Replace(factionId, plan.orders, author, source)
    for _, member in ipairs(SX.Factions:Members(factionId)) do
        if member ~= source and not editing[member] then
            TriggerClientEvent('sxCommand:planDeployed', member, plan.name, author, total)
        end
    end
    TriggerEvent('sxCommand:planDeployed', factionId, plan.name, source)
    return total
end

local actions = {}

function actions.list(source, faction)
    local list = SX.Plans:List(faction.id)
    if #list == 0 then
        notify(source, 'plan_list_empty')
        return
    end
    local names = {}
    for i, plan in ipairs(list) do names[i] = ('%s (%d)'):format(plan.name, plan.orders) end
    notify(source, 'plan_list', table.concat(names, ', '))
end

function actions.edit(source, faction, name)
    local display, key = normalizeName(name)
    if not display then
        notify(source, 'plan_invalid_name')
        return
    end
    local existing = readPlans(faction.id)[key]
    local draft = { factionId = faction.id, name = existing and existing.name or display, orders = {} }
    for _, entry in ipairs(existing and existing.orders or {}) do
        nextDraft = nextDraft + 1
        draft.orders[#draft.orders + 1] = { id = 'p' .. nextDraft, kind = entry.kind, points = entry.points, squad = entry.squad }
    end
    editing[source] = draft
    TriggerClientEvent('sxCommand:planEditing', source, draft.name)
    SX.Plans:SendDraft(source)
    notify(source, 'plan_editing', draft.name, Config.Plans.command)
end

function actions.save(source, faction, name)
    local draft = editing[source]
    local list = draft and draft.orders or SX.Orders:List(faction.id)
    name = name or (draft and draft.name)
    if not name then
        notify(source, 'plan_usage', Config.Plans.command)
        return
    end
    if #list == 0 then
        notify(source, 'plan_nothing')
        return
    end
    local ok, err = SX.Plans:Save(draft and draft.factionId or faction.id, name, list, Bridge.GetName(source))
    if not ok then
        notify(source, err, Config.Plans.maxPerFaction)
        return
    end
    notify(source, 'plan_saved', Utils.Trim(name), #list)
    SX.Plans:Stop(source)
end

function actions.cancel(source)
    if not editing[source] then return end
    SX.Plans:Stop(source)
    notify(source, 'plan_cancelled')
end

function actions.load(source, faction, name)
    if editing[source] then SX.Plans:Stop(source) end
    local total = SX.Plans:Deploy(faction.id, name, source)
    if not total then
        notify(source, 'plan_unknown', tostring(name))
        return
    end
    notify(source, 'plan_deployed_self', Utils.Trim(name), total)
end

function actions.delete(source, faction, name)
    if not SX.Plans:Delete(faction.id, name) then
        notify(source, 'plan_unknown', tostring(name))
        return
    end
    notify(source, 'plan_deleted', Utils.Trim(name))
end

local function command(source, args)
    if source == 0 then return end
    local faction = SX.Factions:Get(source)
    if not faction or not faction.commander then
        notify(source, 'notify_not_commander')
        return
    end

    local action = (args[1] or 'list'):lower()
    local name = #args > 1 and table.concat(args, ' ', 2) or nil
    local handler = actions[action]
    if not handler or ((action == 'edit' or action == 'load' or action == 'delete') and not name) then
        notify(source, 'plan_usage', Config.Plans.command)
        return
    end
    handler(source, faction, name)
end

function SX.Plans:Initialize()
    if not Config.Plans.enabled then return end

    RegisterCommand(Config.Plans.command, command, false)

    AddEventHandler('playerDropped', function()
        editing[source] = nil
    end)
end
