Config = {}

-- 'auto', 'esx', 'qb' (qb-core), 'qbx' (qbx_core) or 'standalone'
Config.Framework = 'auto'

-- ESX, QBCore or Qbox jobs that form a faction. commandGrade: minimum grade to give orders.
-- Without a framework, the ACE permissions below give the police faction and the commander role.
Config.Factions = {
    jobs = {
        police = { label = 'LSPD', color = 0x3EE6FF, commandGrade = 3 },
        sheriff = { label = 'BCSO', color = 0xFFC94D, commandGrade = 3 },
        ambulance = { label = 'EMS', color = 0xFF5A4F, commandGrade = 3 },
    },
    ace = { member = 'sxcommand.police', commander = 'sxcommand.commander', job = 'police' },
    sxIllegalsGroups = true,
    -- QBCore and Qbox: only players on duty are part of their job faction
    requireDuty = true,
    refresh = 15,
}

Config.Units = {
    interval = 1000,
    injuredHealth = 150,
    firingSeconds = 1.5,
}

-- Callsigns: /callsign ADAM-12 puts the player in the ADAM squad (the letters before the first dash or digit).
-- Commanders can give an order to a single squad, and set the callsign of a member with /callsign <id> <callsign>.
Config.Squads = {
    enabled = true,
    command = 'callsign',
    maxLength = 10,
    labels = true, -- show the callsigns next to the units on the map
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

-- Frontend controls read in the pause map while the command mode is on
Config.Command = {
    toggle = 203,
    previous = 205,
    next = 206,
    place = 201,
    undo = 214,
    target = 204, -- cycles the squad that receives the next order (TAB)
    closeDistance = 30.0,
}

-- Saved operations: commanders prepare orders in private and deploy them later
Config.Plans = {
    enabled = true,
    command = 'tacticalplan',
    maxPerFaction = 20,
    maxNameLength = 24,
}

Config.Display = {
    command = 'tactical',
    pauseScale = 8.0,
    scaleCommand = 'tacticalscale',
}
