SX.Command = {}
SX.Modules:Register('Command', 40)

local COMMANDER_TOOLS = { 'rally', 'perimeter', 'axis', 'danger', 'objective', 'ping' }
local MEMBER_TOOLS = { 'ping' }

local active = false
local toolIndex = 1
local targetIndex = 1
local draft = {}
local lastPreview = nil

local function tools()
    return SX.Faction:IsCommander() and COMMANDER_TOOLS or MEMBER_TOOLS
end

local function currentTool()
    local list = tools()
    if toolIndex > #list then toolIndex = 1 end
    return list[toolIndex]
end

-- Squad that receives the next order, nil for the whole faction
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

local function key(control, fallback)
    return HelpUI.KeyLabel(control, fallback)
end

local function showCard()
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
        { key = key(Config.Command.place, 'ENTER'), label = GetPhrase('command_place') },
        { key = key(Config.Command.undo, 'DEL'), label = GetPhrase('command_undo') },
        { key = key(Config.Command.toggle, 'SPACE'), label = GetPhrase('command_exit') },
    }
    if canTarget() then
        table.insert(keys, 1, { key = key(Config.Command.target, 'TAB'), label = GetPhrase('command_target') })
    end
    if #tools() > 1 then
        table.insert(keys, 1, { key = key(Config.Command.previous, 'Q') .. '/' .. key(Config.Command.next, 'E'), label = GetPhrase('command_switch') })
    end
    rows[#rows + 1] = { type = 'keys', keys = keys }

    HelpUI.ShowThisFrame('command', 'command', {
        header = { subtitle = SX.Faction:Get().label, title = GetPhrase('command_title'), watermark = GetPhrase('command_watermark') },
        rows = rows,
        position = 'top-left',
        offset = { x = 2.5, y = 16.0 },
        pauseMenu = true,
        hide = { pauseMenu = false },
    }, ('%s:%d:%s:%s:%s'):format(tool, #draft, tostring(target), tostring(plan), tostring(canTarget())))
end

local function showHint()
    HelpUI.ShowThisFrame('command_hint', 'command_hint', {
        header = { subtitle = SX.Faction:Get().label, title = GetPhrase('command_hint_title') },
        rows = { { type = 'keys', keys = { { key = key(Config.Command.toggle, 'SPACE'), label = GetPhrase('command_open') } } } },
        position = 'top-left',
        offset = { x = 2.5, y = 16.0 },
        pauseMenu = true,
        hide = { pauseMenu = false },
    }, 'hint')
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

local function pressed(control)
    DisableControlAction(2, control, true)
    return IsDisabledControlJustPressed(2, control)
end

function SX.Command:Initialize()
    CreateThread(function()
        while true do
            local wait = 500
            local faction = SX.Faction:Get()

            if faction and IsPauseMenuActive() then
                local cursor = GetPauseMapPointerWorldPosition()
                if cursor then
                    wait = 0
                    if pressed(Config.Command.toggle) then
                        active = not active
                        reset()
                    end

                    if active then
                        if pressed(Config.Command.previous) then
                            toolIndex = toolIndex - 1
                            if toolIndex < 1 then toolIndex = #tools() end
                            reset()
                        elseif pressed(Config.Command.next) then
                            toolIndex = toolIndex % #tools() + 1
                            reset()
                        end

                        if pressed(Config.Command.target) and canTarget() then
                            targetIndex = targetIndex % #targets() + 1
                        end

                        if pressed(Config.Command.place) then place(cursor) end
                        if pressed(Config.Command.undo) then undo() end

                        drawPreview(cursor)
                        showCard()
                    else
                        showHint()
                    end
                end
            elseif active then
                active = false
                reset()
            end

            Wait(wait)
        end
    end)
end
