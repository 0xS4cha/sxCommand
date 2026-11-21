exports('GetFaction', function(source)
    return SX.Factions:Get(source)
end)

exports('GetOrders', function(factionId)
    return SX.Orders:List(factionId)
end)

exports('CreateOrder', function(source, kind, points)
    return SX.Orders:Create(source, kind, points)
end)

exports('Ping', function(source, coords)
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' then return end
    SX.Intel:Ping(source, coords.x, coords.y, coords.z)
end)

exports('AddShot', function(coords)
    SX.Intel:AddShot(coords)
end)
