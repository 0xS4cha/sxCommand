Bridge = {}
Bridge.Name = 'standalone'

local ESX = nil
local QBCore = nil

local function started(resource)
    return GetResourceState(resource) == 'started'
end

local function detectFramework()
    local wanted = Config.Framework
    if wanted == 'standalone' then return 'standalone' end

    if (wanted == 'auto' or wanted == 'qbx') and started('qbx_core') then
        return 'qbx'
    end

    if (wanted == 'auto' or wanted == 'qb') and started('qb-core') then
        local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and obj then
            QBCore = obj
            return 'qb'
        end
        Logger:error('BRIDGE', 'qb-core could not be loaded')
    end

    if (wanted == 'auto' or wanted == 'esx') and GetResourceState('es_extended') ~= 'missing' then
        local ok, obj = pcall(function() return exports.es_extended:getSharedObject() end)
        if ok and obj then
            ESX = obj
            return 'esx'
        end
        Logger:error('BRIDGE', 'es_extended could not be loaded')
    end

    if wanted ~= 'auto' then
        Logger:error('BRIDGE', ('Framework "%s" was not found, running standalone'):format(tostring(wanted)))
    end
    return 'standalone'
end

Bridge.Name = detectFramework()
Logger:info('BRIDGE', 'Framework:', Bridge.Name)

local function esxPlayer(source)
    return ESX and ESX.GetPlayerFromId(source) or nil
end

-- PlayerData of a QBCore or Qbox player
local function qbData(source)
    if Bridge.Name == 'qbx' then
        local ok, player = pcall(function() return exports.qbx_core:GetPlayer(source) end)
        return ok and player and player.PlayerData or nil
    end
    if QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        return player and player.PlayerData or nil
    end
    return nil
end

local function license(source)
    return GetPlayerIdentifierByType(source, 'license2') or GetPlayerIdentifierByType(source, 'license')
end

-- Stable identifier of the character, used to keep callsigns between sessions
function Bridge.GetIdentifier(source)
    local xPlayer = esxPlayer(source)
    if xPlayer and xPlayer.identifier then return xPlayer.identifier end
    local data = qbData(source)
    if data and data.citizenid then return data.citizenid end
    return license(source)
end

function Bridge.GetName(source)
    local xPlayer = esxPlayer(source)
    if xPlayer and xPlayer.getName then
        local ok, name = pcall(xPlayer.getName)
        if ok and name then return name end
    end
    local data = qbData(source)
    local info = data and data.charinfo
    if info and info.firstname then
        return ('%s %s'):format(info.firstname, info.lastname or '')
    end
    return GetPlayerName(source) or ('#' .. tostring(source))
end

-- Returns the job name and grade, or nil when the player has no job or is off duty
function Bridge.GetJob(source)
    local xPlayer = esxPlayer(source)
    if xPlayer then
        local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
        if not job then return nil, 0 end
        return job.name, tonumber(job.grade) or 0
    end

    local data = qbData(source)
    local job = data and data.job
    if job then
        if Config.Factions.requireDuty and job.onduty == false then return nil, 0 end
        local grade = type(job.grade) == 'table' and job.grade.level or job.grade
        return job.name, tonumber(grade) or 0
    end

    return nil, 0
end

-- Calls refresh(source) whenever the framework reports a job or duty change
function Bridge.OnJobChange(refresh)
    AddEventHandler('esx:setJob', function(source) refresh(source) end)
    AddEventHandler('QBCore:Server:OnJobUpdate', function(source) refresh(source) end)
    AddEventHandler('QBCore:Server:SetDuty', function(source) refresh(source) end)
    AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
        local source = type(player) == 'table' and player.PlayerData and player.PlayerData.source or player
        if tonumber(source) then refresh(tonumber(source)) end
    end)
end

function Bridge.HasIllegals()
    return started('sxIllegals')
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
