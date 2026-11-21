SX.Faction = {}
SX.Modules:Register('Faction', 5)

local current = nil
local visible = true

function SX.Faction:Get()
    return current
end

function SX.Faction:IsCommander()
    return current ~= nil and current.commander == true
end

function SX.Faction:IsVisible()
    return visible
end

function SX.Faction:Initialize()
    RegisterNetEvent('sxCommand:faction', function(faction)
        local previous = current
        current = faction
        if not faction then
            Atlas.ClearAll()
            if previous then Bridge.Notify(GetPhrase('notify_left'), 'info') end
            return
        end
        Atlas.Load()
        Atlas.SetVisible(visible)
        if not previous or previous.id ~= faction.id then
            Atlas.ClearAll()
            Bridge.Notify(GetPhrase(faction.commander and 'notify_joined_commander' or 'notify_joined', faction.label), 'success')
        end
    end)

    RegisterCommand(Config.Display.command, function()
        if not current then return end
        visible = not visible
        Atlas.SetVisible(visible)
        Bridge.Notify(GetPhrase(visible and 'notify_display_on' or 'notify_display_off'), 'info')
    end, false)

    CreateThread(function()
        Wait(1500)
        TriggerServerEvent('sxCommand:ready')
    end)
end
