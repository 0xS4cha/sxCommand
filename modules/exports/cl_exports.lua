exports('GetFaction', function()
    return SX.Faction:Get()
end)

exports('IsCommander', function()
    return SX.Faction:IsCommander()
end)

exports('GetCallsign', function()
    return SX.Squads:Mine()
end)

exports('Ping', function(coords)
    SX.Intel:SendPing(coords)
end)

-- Draw on the tactical overlay from another resource, layers: heat, zones, orders, preview, pings, trails, markers
exports('Atlas', function()
    return {
        circle = Atlas.Circle,
        polygon = Atlas.Polygon,
        arrow = Atlas.Arrow,
        remove = Atlas.Remove,
        clearLayer = Atlas.ClearLayer,
    }
end)
