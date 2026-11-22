SX.Intel = {}
SX.Modules:Register('Intel', 15)

local function aimedPoint()
    local origin = GetGameplayCamCoord()
    local rotation = GetGameplayCamRot(2)
    local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
    local direction = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local target = origin + direction * Config.Pings.distance
    local handle = StartExpensiveSynchronousShapeTestLosProbe(origin.x, origin.y, origin.z, target.x, target.y, target.z, -1, PlayerPedId(), 7)
    local _, hit, coords = GetShapeTestResult(handle)
    return hit == 1 and coords or target
end

function SX.Intel:SendPing(coords)
    if not SX.Faction:Get() or not coords then return end
    TriggerServerEvent('sxCommand:sendPing', coords.x, coords.y, coords.z or 0.0)
end

function SX.Intel:Initialize()
    RegisterNetEvent('sxCommand:ping', function(ping)
        if not SX.Faction:Get() then return end
        Atlas.Ping('p' .. ping.id, ping.x, ping.y, COLORS.ping, Config.Pings.life)
        if ping.authorId ~= GetPlayerServerId(PlayerId()) then
            PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        end
    end)

    RegisterNetEvent('sxCommand:heat', function(cells)
        if not SX.Faction:Get() then return end
        Atlas.Heat(Config.Heat.cell, cells, COLORS.heat)
    end)

    Keys.Register({
        name = 'sxcommand_ping',
        description = 'keymap_ping',
        defaultKey = Config.Pings.key or '',
        onPressed = function()
            SX.Intel:SendPing(aimedPoint())
        end,
    })
end
