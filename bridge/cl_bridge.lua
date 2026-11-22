Bridge = {}

local function started(resource)
    return GetResourceState(resource) == 'started'
end

local function framework()
    local wanted = Config.Framework
    if wanted == 'standalone' then return 'standalone' end
    if (wanted == 'auto' or wanted == 'qbx') and started('qbx_core') then return 'qbx' end
    if (wanted == 'auto' or wanted == 'qb') and started('qb-core') then return 'qb' end
    if (wanted == 'auto' or wanted == 'esx') and started('es_extended') then return 'esx' end
    return 'standalone'
end

local function plain(message)
    return (message:gsub('~%a~', ''))
end

local QB_TYPES = { info = 'primary', success = 'success', error = 'error', warning = 'error' }
local QBX_TYPES = { info = 'inform', success = 'success', error = 'error', warning = 'warning' }

function Bridge.Notify(message, kind)
    local name = framework()
    if name == 'esx' then
        TriggerEvent('esx:showNotification', message, kind)
        return
    end
    if name == 'qbx' then
        local ok = pcall(function() exports.qbx_core:Notify(plain(message), QBX_TYPES[kind] or 'inform') end)
        if ok then return end
    end
    if name == 'qb' or name == 'qbx' then
        TriggerEvent('QBCore:Notify', plain(message), QB_TYPES[kind] or 'primary')
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('sxCommand:notify', function(message, kind)
    Bridge.Notify(message, kind)
end)
