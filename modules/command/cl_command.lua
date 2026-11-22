SX.Command = {}
SX.Modules:Register('Command', 40)

local COMMANDER_TOOLS = { 'rally', 'perimeter', 'axis', 'danger', 'objective', 'ping' }
local MEMBER_TOOLS = { 'ping' }

local active = false
local toolIndex = 1
local targetIndex = 1
local draft = {}
local lastPreview = nil
local cursorNow = nil
local binds = {}

local KEY_NAMES = { RETURN = 'ENTER', DELETE = 'DEL', SPACE = 'SPACE', TAB = 'TAB' }

local function tools()
    return SX.Faction:IsCommander() and COMMANDER_TOOLS or MEMBER_TOOLS
end

local function currentTool()
    local list = tools()
    if toolIndex > #list then toolIndex = 1 end
    return list[toolIndex]
end

local function targets()
    local list = { false }
    if Config.Squads.enabled then
        for _, squad in ipairs(SX.Squads:List()) do list[#list + 1] = squad end
    end
    return list
end

local function currentTarget()
    local list = targets()
    if targetIndex > #list then targetIndex = 1 end
    return list[targetIndex] or nil
end

local function canTarget()
    return SX.Faction:IsCommander() and currentTool() ~= 'ping' and #targets() > 1
end

local function clearPreview()
    Atlas.ClearLayer('preview')
    lastPreview = nil
end

local function reset()
    draft = {}
    clearPreview()
end

local function key(name)
    local bind = binds[name]
    if not bind then return '?' end
    local button = GetControlInstructionalButton(0, bind.hash, true)
    if type(button) == 'string' and button:sub(1, 2) == 't_' then
        return button:sub(3)
    end
    return KEY_NAMES[bind.defaultKey] or bind.defaultKey
end

local scale = { samples = {}, last = nil, value = nil }

local function resetScale()
    scale.samples = {}
    scale.last = nil
    scale.value = nil
end

local function median(list)
    local sorted = {}
    for i, v in ipairs(list) do sorted[i] = v end
    table.sort(sorted)
    return sorted[math.ceil(#sorted / 2)]
end

local function measureScale(cursor, sx, sy, width, height)
    local last = scale.last
    scale.last = { sx = sx, sy = sy, x = cursor.x, y = cursor.y }
    if not last then return end

    local dx, dy = (sx - last.sx) * width, (sy - last.sy) * height
    local pixels = math.sqrt(dx * dx + dy * dy)
    if pixels < 3 then return end

    local wx, wy = cursor.x - last.x, cursor.y - last.y
    local meters = math.sqrt(wx * wx + wy * wy)
    if meters < 0.05 or wx * dx < 0 or wy * dy > 0 then return end

    table.insert(scale.samples, meters / pixels)
    if #scale.samples > 9 then table.remove(scale.samples, 1) end
    if #scale.samples >= 3 then scale.value = median(scale.samples) end
end

local function hintPoint(cursor)
    local anchor = Config.Display.hintAnchor
    if not anchor then return cursor.x, cursor.y, 16 end

    local sx, sy = GetControlNormal(2, 239), GetControlNormal(2, 240)
    local width, height = GetActiveScreenResolution()
    measureScale(cursor, sx, sy, width, height)
    if not scale.value then return cursor.x, cursor.y, 16 end

    local x = cursor.x + (anchor.x - sx) * width * scale.value
    local y = cursor.y - (anchor.y - sy) * height * scale.value
    return x, y, 0
end

local function showCard(cursor)
    local tool = currentTool()
    local target = currentTarget()
    local plan = SX.Plans:Editing()
    local rows = {}
    if plan then
        rows[#rows + 1] = { type = 'text', label = GetPhrase('plan_label'), value = plan, icon = 'clipboard-list', tone = 'warning', scramble = false }
    end
    rows[#rows + 1] = { type = 'text', label = GetPhrase('command_tool'), value = GetPhrase('order_' .. tool), icon = 'pencil-ruler', tone = 'accent', scramble = false }
    if SX.Faction:IsCommander() and tool ~= 'ping' then
        rows[#rows + 1] = { type = 'text', label = GetPhrase('command_target'), value = target or GetPhrase('command_target_all'), icon = 'users', scramble = false }
    end
    if tool == 'perimeter' then
        rows[#rows + 1] = { type = 'text', label = GetPhrase('command_points'), value = tostring(#draft), scramble = false }
    elseif tool == 'axis' then
        rows[#rows + 1] = { type = 'text', label = GetPhrase('command_step'), value = GetPhrase(#draft == 0 and 'command_axis_start' or 'command_axis_end'), scramble = false }
    end

    local keys = {
        { key = key('place'), label = GetPhrase('command_place') },
        { key = key('undo'), label = GetPhrase('command_undo') },
        { key = key('toggle'), label = GetPhrase('command_exit') },
    }
    if canTarget() then
        table.insert(keys, 1, { key = key('target'), label = GetPhrase('command_target') })
    end
    if #tools() > 1 then
        table.insert(keys, 1, { key = key('previous') .. '/' .. key('next'), label = GetPhrase('command_switch') })
    end
    rows[#rows + 1] = { type = 'keys', keys = keys }

    local shown = HelpUI.ShowThisFrame('command', 'command', {
        header = { subtitle = SX.Faction:Get().label, title = GetPhrase('command_title'), watermark = GetPhrase('command_watermark') },
        rows = rows,
        position = 'top-left',
        offset = { x = 2.5, y = 16.0 },
        pauseMenu = true,
        hide = { pauseMenu = false },
    }, ('%s:%d:%s:%s:%s'):format(tool, #draft, tostring(target), tostring(plan), tostring(canTarget())))
    if shown or not Config.Display.mapHint then
        Atlas.HideHint()
        return
    end

    local subtitle = SX.Faction:Get().label
    if plan then subtitle = subtitle .. ' · ' .. GetPhrase('plan_label') .. ' : ' .. plan end
    local title = GetPhrase('order_' .. tool)
    if tool == 'perimeter' and #draft > 0 then
        title = ('%s · %d'):format(title, #draft)
    elseif tool == 'axis' then
        title = title .. ' · ' .. GetPhrase(#draft == 0 and 'command_axis_start' or 'command_axis_end')
    end
    local mapKeys = {}
    for i, entry in ipairs(keys) do
        mapKeys[i] = { key = entry.key, label = entry.label }
        if entry.label == GetPhrase('command_target') then
            mapKeys[i].label = ('%s : %s'):format(entry.label, target or GetPhrase('command_target_all'))
        end
    end
    local x, y, gap = hintPoint(cursor)
    Atlas.Hint(x, y, subtitle, title, mapKeys, plan and COLORS.perimeter or SX.Faction:Get().color, gap)
end

local function showHint(cursor)
    local subtitle, title = SX.Faction:Get().label, GetPhrase('command_hint_title')
    local keys = { { key = key('toggle'), label = GetPhrase('command_open') } }
    local shown = HelpUI.ShowThisFrame('command_hint', 'command_hint', {
        header = { subtitle = subtitle, title = title },
        rows = { { type = 'keys', keys = keys } },
        position = 'top-left',
        offset = { x = 2.5, y = 16.0 },
        pauseMenu = true,
        hide = { pauseMenu = false },
    }, 'hint')
    if shown or not Config.Display.mapHint then
        Atlas.HideHint()
        return
    end
    local x, y, gap = hintPoint(cursor)
    Atlas.Hint(x, y, subtitle, title, keys, SX.Faction:Get().color, gap)
end

local function drawPreview(cursor)
    local tool = currentTool()
    local signature = ('%s:%d:%.0f:%.0f'):format(tool, #draft, cursor.x, cursor.y)
    if signature == lastPreview then return end
    lastPreview = signature

    Atlas.ClearLayer('preview')
    local point = { x = cursor.x, y = cursor.y }
    if tool == 'perimeter' then
        local points = {}
        for i, p in ipairs(draft) do points[i] = p end
        points[#points + 1] = point
        if #points >= 3 then
            Atlas.Polygon('preview', 'draft', points, COLORS.perimeter, 12, 0, 2, 2)
        elseif #points == 2 then
            Atlas.Arrow('preview', 'draft', points[1], points[2], COLORS.perimeter, 3, 0)
        end
        for i, p in ipairs(draft) do
            Atlas.Circle('preview', 'pt' .. i, p.x, p.y, 6.0, COLORS.perimeter, 100, 0, 0, 0)
        end
    elseif tool == 'axis' then
        if draft[1] then
            Atlas.Arrow('preview', 'draft', draft[1], point, COLORS.axis, 5, 0)
        else
            Atlas.Circle('preview', 'draft', point.x, point.y, 8.0, COLORS.axis, 90, 0, 0, 0)
        end
    elseif tool == 'ping' then
        Atlas.Circle('preview', 'draft', point.x, point.y, 12.0, COLORS.ping, 60, 0, 2, 2)
    else
        SX.Orders:Draw('preview', 'draft', tool, { point })
    end
end

local function place(cursor)
    local tool = currentTool()
    local point = { x = cursor.x, y = cursor.y }

    if tool == 'ping' then
        SX.Intel:SendPing(vector3(cursor.x, cursor.y, cursor.z or 0.0))
        return
    end

    if tool == 'perimeter' then
        local first = draft[1]
        if first and #draft >= 3 and #(vector2(first.x, first.y) - vector2(point.x, point.y)) <= Config.Command.closeDistance then
            TriggerServerEvent('sxCommand:createOrder', 'perimeter', draft, currentTarget())
            reset()
            return
        end
        draft[#draft + 1] = point
        if #draft >= Config.Orders.maxPoints then
            TriggerServerEvent('sxCommand:createOrder', 'perimeter', draft, currentTarget())
            reset()
        end
        lastPreview = nil
        return
    end

    if tool == 'axis' then
        if not draft[1] then
            draft[1] = point
            lastPreview = nil
            return
        end
        TriggerServerEvent('sxCommand:createOrder', 'axis', { draft[1], point }, currentTarget())
        reset()
        return
    end

    TriggerServerEvent('sxCommand:createOrder', tool, { point }, currentTarget())
end

local function undo()
    if #draft > 0 then
        table.remove(draft, #draft)
        lastPreview = nil
        if #draft == 0 then clearPreview() end
        return
    end
    if SX.Faction:IsCommander() then
        TriggerServerEvent('sxCommand:undoOrder')
    end
end

local actions = {
    toggle = function()
        active = not active
        reset()
    end,
    previous = function()
        if not active then return end
        toolIndex = toolIndex - 1
        if toolIndex < 1 then toolIndex = #tools() end
        reset()
    end,
    next = function()
        if not active then return end
        toolIndex = toolIndex % #tools() + 1
        reset()
    end,
    target = function()
        if active and canTarget() then
            targetIndex = targetIndex % #targets() + 1
        end
    end,
    place = function()
        if active then place(cursorNow) end
    end,
    undo = function()
        if active then undo() end
    end,
}

local function registerKeys()
    for _, name in ipairs({ 'toggle', 'previous', 'next', 'target', 'place', 'undo' }) do
        binds[name] = Keys.Register({
            name = 'sxcommand_' .. name,
            description = 'keymap_' .. name,
            defaultKey = Config.Command.keys[name],
            pauseMenu = true,
            onPressed = function()
                if cursorNow and SX.Faction:Get() and IsPauseMenuActive() then
                    actions[name]()
                end
            end,
        })
    end
end

local function blockControls()
    for _, control in ipairs(Config.Command.blockedControls[active and 'active' or 'idle']) do
        DisableControlAction(2, control, true)
    end
end

function SX.Command:Initialize()
    registerKeys()

    CreateThread(function()
        while true do
            local wait = 500
            local faction = SX.Faction:Get()
            cursorNow = nil

            if faction and IsPauseMenuActive() then
                local cursor = GetPauseMapPointerWorldPosition()
                if cursor then
                    wait = 0
                    cursorNow = cursor
                    blockControls()

                    if active then
                        drawPreview(cursor)
                        showCard(cursor)
                    else
                        showHint(cursor)
                    end
                else
                    Atlas.HideHint()
                end
            else
                Atlas.HideHint()
                if scale.last then resetScale() end
                if active then
                    active = false
                    reset()
                end
            end

            Wait(wait)
        end
    end)
end
