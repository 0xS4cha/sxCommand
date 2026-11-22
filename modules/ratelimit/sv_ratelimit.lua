SX.RateLimit = {}
SX.Modules:Register('RateLimit', 1)

local calls = {}
local strikes = {}
local warned = {}

local SILENT = { shot = true, ready = true }

local function bucket(map, source)
    map[source] = map[source] or {}
    return map[source]
end

local function flag(source, action, count)
    Logger:warn('RATELIMIT', ('%s [%s] blocked on %s (%d blocked calls)'):format(GetPlayerName(source) or '?', source, action, count))
    TriggerEvent('sxCommand:rateLimited', source, action, count)
    if Config.RateLimit.punishment == 'kick' then
        DropPlayer(source, GetPhrase('kick_rate_limited'))
    end
end

function SX.RateLimit:Allow(source, action)
    local settings = Config.RateLimit
    if not settings.enabled or not source or source == 0 then return true end
    local rule = settings.actions[action]
    if not rule then return true end

    local now = GetGameTimer()
    local window = rule.window * 1000
    local list = bucket(calls, source)[action] or {}
    calls[source][action] = list

    local kept = {}
    for _, at in ipairs(list) do
        if now - at < window then kept[#kept + 1] = at end
    end
    calls[source][action] = kept

    if #kept < rule.limit then
        kept[#kept + 1] = now
        return true
    end

    local strike = bucket(strikes, source)
    if strike.at and now - strike.at > settings.strikeReset * 1000 then strike.count = 0 end
    strike.count = (strike.count or 0) + 1
    strike.at = now
    if strike.count == settings.strikes then flag(source, action, strike.count) end

    local seen = bucket(warned, source)
    if not SILENT[action] and (not seen[action] or now - seen[action] > window) then
        seen[action] = now
        Bridge.Notify(source, GetPhrase('notify_rate_limited'), 'error')
    end
    return false
end

function SX.RateLimit:Initialize()
    AddEventHandler('playerDropped', function()
        calls[source] = nil
        strikes[source] = nil
        warned[source] = nil
    end)
end
