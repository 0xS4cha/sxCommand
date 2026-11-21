SX.Units = {}
SX.Modules:Register('Units', 20)

local shown = {}

function SX.Units:Render(units)
    local faction = SX.Faction:Get()
    if not faction then return end
    local me = GetPlayerServerId(PlayerId())
    local seen = {}
    local duration = Config.Units.interval / 1000

    for _, unit in ipairs(units or {}) do
        if unit.id ~= me then
            local id = 'u' .. unit.id
            seen[id] = true
            shown[id] = true
            Atlas.Marker(id, unit.x, unit.y, unit.h, faction.color, unit.f, duration)
        end
    end

    for id in pairs(shown) do
        if not seen[id] then
            Atlas.RemoveMarker(id)
            shown[id] = nil
        end
    end
end

function SX.Units:Initialize()
    RegisterNetEvent('sxCommand:units', function(units)
        SX.Units:Render(units)
    end)

    RegisterNetEvent('sxCommand:faction', function(faction)
        if faction then return end
        for id in pairs(shown) do Atlas.RemoveMarker(id) end
        shown = {}
    end)

    CreateThread(function()
        local last = 0
        while true do
            local wait = 250
            local ped = PlayerPedId()
            if IsPedArmed(ped, 4) then
                wait = 0
                if IsPedShooting(ped) and GetGameTimer() - last > 1000 then
                    last = GetGameTimer()
                    TriggerServerEvent('sxCommand:shot')
                end
            end
            Wait(wait)
        end
    end)
end
