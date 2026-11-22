exports('GetFaction', function(source)
    return SX.Factions:Get(source)
end)

exports('GetOrders', function(factionId)
    return SX.Orders:List(factionId)
end)

exports('CreateOrder', function(source, kind, points, squad)
    return SX.Orders:Create(source, kind, points, squad)
end)

exports('GetCallsign', function(source)
    return SX.Squads:Get(source)
end)

exports('SetCallsign', function(source, callsign)
    return SX.Squads:Set(source, callsign)
end)

exports('GetPlans', function(factionId)
    return SX.Plans:List(factionId)
end)

exports('DeployPlan', function(factionId, name, source)
    return SX.Plans:Deploy(factionId, name, source)
end)

exports('Ping', function(source, coords)
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' then return end
    SX.Intel:Ping(source, coords.x, coords.y, coords.z)
end)

exports('AddShot', function(coords)
    SX.Intel:AddShot(coords)
end)
