Config = {}

Config.Framework = 'auto'

Config.Factions = {
    jobs = {
        police = { label = 'LSPD', color = 0x3EE6FF, commandGrade = 3 },
        sheriff = { label = 'BCSO', color = 0xFFC94D, commandGrade = 3 },
        ambulance = { label = 'EMS', color = 0xFF5A4F, commandGrade = 3 },
    },
    ace = { member = 'sxcommand.police', commander = 'sxcommand.commander', job = 'police' },
    sxIllegalsGroups = true,
    requireDuty = true,
    refresh = 15,
}

Config.Units = {
    interval = 1000,
    injuredHealth = 150,
    firingSeconds = 1.5,
}

Config.Squads = {
    enabled = true,
    command = 'callsign',
    maxLength = 10,
    labels = true,
}

Config.Orders = {
    duration = 20,
    maxPerFaction = 12,
    maxPoints = 12,
    radius = { rally = 40.0, danger = 90.0, objective = 25.0 },
}

Config.Pings = {
    life = 90,
    cooldown = 3,
    distance = 400.0,
    key = 'G',
}

Config.Heat = {
    enabled = true,
    cell = 80.0,
    shot = 0.25,
    decay = 0.9,
    interval = 5,
}

Config.Command = {
    keys = {
        toggle = 'SPACE',
        previous = 'Q',
        next = 'E',
        place = 'RETURN',
        undo = 'DELETE',
        target = 'TAB',
    },
    blockedControls = {
        idle = { 203 },
        active = { 201, 203, 204, 205, 206, 214 },
    },
    closeDistance = 30.0,
}

Config.Plans = {
    enabled = true,
    command = 'tacticalplan',
    maxPerFaction = 20,
    maxNameLength = 24,
}

Config.RateLimit = {
    enabled = true,
    actions = {
        createOrder = { limit = 8, window = 10 },
        undoOrder = { limit = 12, window = 10 },
        clearOrders = { limit = 3, window = 10 },
        ping = { limit = 5, window = 10 },
        shot = { limit = 15, window = 10 },
        ready = { limit = 3, window = 60 },
        callsign = { limit = 6, window = 60 },
        plan = { limit = 12, window = 60 },
    },
    strikes = 30,
    strikeReset = 60,
    punishment = 'log',
}

Config.Display = {
    command = 'tactical',
    pauseScale = 8.0,
    scaleCommand = 'tacticalscale',
    mapHint = true,
    hintAnchor = { x = 0.03, y = 0.2 },
}
