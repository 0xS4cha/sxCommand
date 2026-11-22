SX.Plans = {}
SX.Modules:Register('Plans', 12)

local editing = nil

-- Name of the plan the local commander is editing, or nil
function SX.Plans:Editing()
    return editing
end

function SX.Plans:Initialize()
    if not Config.Plans.enabled then return end

    RegisterNetEvent('sxCommand:planEditing', function(name)
        editing = name
    end)

    RegisterNetEvent('sxCommand:faction', function(faction)
        if not faction or not faction.commander then editing = nil end
    end)

    RegisterNetEvent('sxCommand:planDeployed', function(name, author, total)
        local shown = HelpUI.Show('order', 'plan', {
            header = { subtitle = GetPhrase('order_from', author), title = name, watermark = GetPhrase('plan_watermark') },
            rows = {
                { type = 'text', label = GetPhrase('plan_orders'), value = tostring(total), icon = 'map', tone = 'accent', scramble = false },
                { type = 'text', label = GetPhrase('order_hint'), value = GetPhrase('order_hint_value') },
            },
            duration = 7000,
            position = 'top-right',
        })
        PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
        if not shown then
            Bridge.Notify(GetPhrase('notify_plan', author, name), 'info')
        end
    end)

    TriggerEvent('chat:addSuggestion', '/' .. Config.Plans.command, GetPhrase('suggest_plan'), {
        { name = 'action', help = 'list | edit | save | cancel | load | delete' },
        { name = 'name', help = GetPhrase('suggest_plan_name') },
    })
end
