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

exports('Atlas', function()
    return {
        circle = Atlas.Circle,
        polygon = Atlas.Polygon,
        arrow = Atlas.Arrow,
        remove = Atlas.Remove,
        clearLayer = Atlas.ClearLayer,
    }
end)
