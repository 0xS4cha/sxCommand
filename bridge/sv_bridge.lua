Bridge = {}
Bridge.Name = 'standalone'

local ESX = nil

local function detectFramework()
    if Config.Framework == 'standalone' then return 'standalone' end

    if Config.Framework == 'esx' or GetResourceState('es_extended') ~= 'missing' then
        local ok, obj = pcall(function()
            return exports.es_extended:getSharedObject()
        end)
        if ok and obj then
            ESX = obj
            return 'esx'
        end
        Logger:error('BRIDGE', 'es_extended could not be loaded, running standalone')
    end

    return 'standalone'
end

Bridge.Name = detectFramework()
Logger:info('BRIDGE', 'Framework:', Bridge.Name)

local function esxPlayer(source)
    return ESX and ESX.GetPlayerFromId(source) or nil
end

function Bridge.GetName(source)
    local xPlayer = esxPlayer(source)
    if xPlayer and xPlayer.getName then
        local ok, name = pcall(xPlayer.getName)
        if ok and name then return name end
    end
    return GetPlayerName(source) or ('#' .. tostring(source))
end

function Bridge.GetJob(source)
    local xPlayer = esxPlayer(source)
    if not xPlayer then return nil, 0 end
    local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
    if not job then return nil, 0 end
    return job.name, tonumber(job.grade) or 0
end

function Bridge.HasIllegals()
    return GetResourceState('sxIllegals') == 'started'
end

function Bridge.GetIllegalsGroup(source)
    if not Bridge.HasIllegals() then return nil end
    local ok, group = pcall(function() return exports.sxIllegals:GetPlayerGroup(source) end)
    return ok and group or nil
end

function Bridge.IsIllegalsCommander(source)
    local ok, leader = pcall(function() return exports.sxIllegals:IsPlayerGroupLeader(source) end)
    if ok and leader then return true end
    local ok2, allowed = pcall(function() return exports.sxIllegals:HasGroupPermission(source, 'canCommand') end)
    return ok2 and allowed == true
end

function Bridge.Notify(source, message, kind)
    TriggerClientEvent('sxCommand:notify', source, message, kind or 'info')
end
