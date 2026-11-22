SX.Units = {}
SX.Modules:Register('Units', 20)

local firing = {}
local lastShot = {}

function SX.Units:Tick()
    local now = GetGameTimer()
    for factionId, members in pairs(SX.Factions:All()) do
        local units = {}
        for _, source in ipairs(members) do
            local ped = GetPlayerPed(source)
            if ped and ped ~= 0 then
                local coords = GetEntityCoords(ped)
                local health = GetEntityHealth(ped)
                local faction = SX.Factions:Get(source)
                local flags = 0
                if health < Config.Units.injuredHealth then flags = flags | 1 end
                if firing[source] and firing[source] > now then flags = flags | 2 end
                if faction and faction.commander then flags = flags | 4 end
                units[#units + 1] = { id = source, x = coords.x, y = coords.y, h = GetEntityHeading(ped), f = flags, c = SX.Squads:Get(source) }
            end
        end
        for _, source in ipairs(members) do
            TriggerClientEvent('sxCommand:units', source, units)
        end
    end
end

function SX.Units:Initialize()
    RegisterNetEvent('sxCommand:shot', function()
        local src = source
        local now = GetGameTimer()
        if lastShot[src] and now - lastShot[src] < 900 then return end
        lastShot[src] = now
        firing[src] = now + Config.Units.firingSeconds * 1000
        SX.Intel:AddShot(GetEntityCoords(GetPlayerPed(src)))
    end)

    AddEventHandler('playerDropped', function()
        firing[source] = nil
        lastShot[source] = nil
    end)
end

function SX.Units:InitializeAsync()
    while true do
        Wait(Config.Units.interval)
        local ok, err = pcall(self.Tick, self)
        if not ok then Logger:error('UNITS', 'Tick failed:', err) end
    end
end
