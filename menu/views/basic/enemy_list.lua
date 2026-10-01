local defaults = require('base/ui/ui_defaults')
local bit = require('bit')
local shared = require('menu/views/shared_style')
local shared_style = shared.values

local view_key = ACTOR_LIB.player.name .. '_view_basic_enemy_list'
local clean_mode_key = view_key .. '_clean'
local rows_per_page_key = view_key .. '_rows_per_page'
local width = 330
local inset = 6
local column_height = 15
local row_height = 28
local footer_height = 20
local min_rows_per_page = 3
local max_rows_per_page = 10
local rows_per_page = math.max(min_rows_per_page, math.min(max_rows_per_page,
    math.floor(tonumber(get_save_setting(rows_per_page_key)) or max_rows_per_page)))
local effect_icon_size = 12
local compact_effect_icon_size = 10
local effects_per_row = 10
local max_effect_icons = effects_per_row * 2
local claim_icon_size = 9
local skillchain_icon_size = 10
local skillchain_step_width = 7
local skillchain_step_gap = 1
local max_skillchain_icons = 3
local height = column_height + row_height * max_rows_per_page + footer_height

local region = ui.create_region({
    x = get_save_setting(view_key .. '_x') or 20,
    y = get_save_setting(view_key .. '_y') or 160,
    width = width,
    height = height,
    auto_height = true,
    bg_color = shared_style.background,
    outline_color = shared_style.outline,
    draggable = true,
    name = 'enemy_list',
})

region.on_region_drag_end = function(self)
    set_character_save_setting('view_basic_enemy_list_x', ACTOR_LIB.player.name, view_key .. '_x', self.x)
    set_character_save_setting('view_basic_enemy_list_y', ACTOR_LIB.player.name, view_key .. '_y', self.y)
end

-- Text primitives do not clip, so shorten text to the assigned column width.
local function bounded_label(settings)
    settings.font = shared_style.font
    local initial_text = settings.text or ''
    settings.text = ''
    local result = ui.create_label(settings)
    shared.bind_label(result, settings.color)
    local set_text = result.set_text

    function result:set_text(text)
        text = tostring(text or '')
        if self.full_text == text then return end
        self.full_text = text
        set_text(self, text)
        if self.txt_obj:get_text_width() <= self.width then return end

        local shortened = text
        repeat
            shortened = shortened:sub(1, -2)
            set_text(self, shortened .. '...')
        until #shortened == 0 or self.txt_obj:get_text_width() <= self.width
    end

    result:set_text(initial_text)
    return result
end

local claim_icon_x = inset
local name_x = claim_icon_x + claim_icon_size + 3
local name_width = 100
local bar_x = name_x + name_width + 2
local bar_width = 76
local skillchain_x = bar_x
local effects_x = bar_x + bar_width + 4

local function add_column(text, x, column_width, align)
    local column = bounded_label({
        x = x,
        y = 0,
        width = column_width,
        height = column_height,
        text = text,
        size = 8,
        color = shared_style.muted,
        horizontal_align = align or 'left',
    })
    region:add(column)
end

add_column('Enemy / ID', name_x, name_width)
add_column('HP', bar_x, bar_width)
add_column('Effects', effects_x, width - effects_x - inset)

local rows = {}
for index = 1, max_rows_per_page do
    local y = column_height + (index - 1) * row_height
    local row = ui.create_imageless_region({
        x = 0,
        y = y,
        width = width,
        height = row_height,
        draggable = false,
    })

    row.claim_icon = ui.create_image({
        x = claim_icon_x,
        y = 3,
        width = claim_icon_size,
        height = claim_icon_size,
        path = windower.addon_path .. 'media/ui/dot_white.png',
    })
    row.name_label = bounded_label({
        x = name_x,
        y = 0,
        width = name_width,
        height = 15,
        text = '',
        size = 9,
        color = shared_style.text,
    })
    row.id_label = bounded_label({
        x = name_x + 2,
        y = 13,
        width = name_width - 2,
        height = 12,
        text = '',
        size = 7,
        color = shared_style.muted,
    })
    row.hp_bar = ui.create_progressbar({
        x = bar_x,
        y = 5,
        width = bar_width,
        height = 8,
        bg_image = windower.addon_path .. 'media/ui/bar.png',
        fill_image = windower.addon_path .. 'media/ui/bar_fill_hp.png',
    })
    row.hp_bar:set_fill_margin(4, 5, 0, 0)
    row.hp_label = bounded_label({
        x = bar_x,
        y = 13,
        width = bar_width,
        height = 12,
        text = '',
        size = 7,
        horizontal_align = 'right',
        color = shared_style.text,
    })
    row.skillchain_step_label = bounded_label({
        x = skillchain_x,
        y = 15,
        width = skillchain_step_width,
        height = skillchain_icon_size,
        text = '',
        size = 7,
        horizontal_align = 'right',
        color = shared_style.text,
    })
    row.skillchain_step_label:hide()
    row.skillchain_icons = {}
    for icon_index = 1, max_skillchain_icons do
        local icon = ui.create_image({
            x = skillchain_x + skillchain_step_width + skillchain_step_gap
                + (icon_index - 1) * (skillchain_icon_size + 1),
            y = 15,
            width = skillchain_icon_size,
            height = skillchain_icon_size,
            path = '',
        })
        icon:hide()
        row.skillchain_icons[icon_index] = icon
    end
    row.effect_icons = {}
    for icon_index = 1, max_effect_icons do
        local icon = ui.create_image({
            x = effects_x + (icon_index - 1) * effect_icon_size,
            y = 7,
            width = effect_icon_size,
            height = effect_icon_size,
            path = '',
        })
        icon:hide()
        row.effect_icons[icon_index] = icon
    end

    row:add(row.claim_icon)
    row:add(row.name_label)
    row:add(row.id_label)
    row:add(row.hp_bar)
    row:add(row.hp_label)
    row:add(row.skillchain_step_label)
    for _, icon in ipairs(row.skillchain_icons) do row:add(icon) end
    for _, icon in ipairs(row.effect_icons) do row:add(icon) end
    region:add(row)
    rows[index] = row
end

local current_page = 1
local total_pages = 1
local refresh
local footer_y = height - footer_height

local previous_button = ui.create_button({
    x = inset,
    y = footer_y,
    width = 20,
    height = 16,
    label = '<',
    on_click = function()
        current_page = math.max(1, current_page - 1)
        if refresh then refresh() end
    end,
})
region:add(previous_button)

local next_button = ui.create_button({
    x = previous_button:get_relative_right() + 3,
    y = footer_y,
    width = 20,
    height = 16,
    label = '>',
    on_click = function()
        current_page = math.min(total_pages, current_page + 1)
        if refresh then refresh() end
    end,
})
region:add(next_button)

local page_label = bounded_label({
    x = next_button:get_relative_right() + 5,
    y = footer_y,
    width = 80,
    height = 16,
    text = '1 / 1',
    size = 8,
    color = shared_style.muted,
})
region:add(page_label)

local clean_mode = get_save_setting(clean_mode_key)
clean_mode = clean_mode == true or clean_mode == 'true'

local function apply_clean_mode(enabled)
    region.bg_prim.always_hidden = enabled
    region.bg_prim:update_draw_visibility(region:is_drawn())
    region.outline:set_visibility(not enabled)
end

local function set_clean_mode(enabled)
    clean_mode = enabled == true
    set_save_setting('view_basic_enemy_list_clean', ACTOR_LIB.player.name, clean_mode_key, clean_mode)
    apply_clean_mode(clean_mode)
end

apply_clean_mode(clean_mode)

local middle_pressed = false
local region_mouse_event = region.mouse_event
function region:mouse_event(type, mx, my, delta)
    local inside = mx >= self.x and mx <= self.x + self.width
        and my >= self.y and my <= self.y + self.height

    if type == 7 then -- middle button down
        middle_pressed = inside
        if inside then return true, self.id end
    elseif type == 8 and middle_pressed then -- middle button up
        middle_pressed = false
        if inside then set_clean_mode(not clean_mode) end
        return true, self.id
    end

    return region_mouse_event(self, type, mx, my, delta)
end

local function enemy_name(entry)
    local npc = RESOURCES:NPC_FROM_ID(entry.id)
    local resource_name = type(npc) == 'table' and (npc.name or npc.en) or npc
    if resource_name and resource_name ~= '' then return resource_name end
    local info = windower.ffxi.get_info()
    local zone_id = tonumber(entry.zone) or tonumber(ACTOR_LIB.player.zone)
        or (info and tonumber(info.zone)) or 'unknown'
    local npc_index = tonumber(entry.index)
        or (tonumber(entry.id) and bit.band(tonumber(entry.id), 0x0FFF))
        or 'unknown'
    return 'unknown_' .. tostring(zone_id) .. '_' .. tostring(npc_index)
end

local function enemy_hp(entry)
    local hp = tonumber(entry.hp)
    local max_hp = tonumber(entry.max_hp)
    if hp and max_hp and max_hp > 0 then
        return math.max(0, math.min(1, hp / max_hp)),
            tostring(hp) .. '/' .. tostring(max_hp)
    end

    local hpp = tonumber(entry.hpp)
    if hpp then
        hpp = math.max(0, math.min(100, hpp))
        return hpp / 100, tostring(math.floor(hpp + 0.5)) .. '%'
    end
    return 0, '--'
end

local function active_effect_ids(entry)
    local result = {}
    local seen = {}

    local function add(id, effect, priority)
        id = tonumber(id)
        if not id or id < 0 or id == 255 or seen[id] then return end
        seen[id] = true
        table.insert(result, {id = id, priority = priority})
    end

    local function effect_priority(id, effect, fallback)
        if type(effect) == 'table' and effect.is_buff ~= nil then
            return effect.is_buff == false and 1 or 2
        end
        local info = RESOURCES:E('buff_types', tonumber(id))
        if info and info.type then return info.type == 'Debuff' and 1 or 2 end
        return fallback
    end

    local function add_array(collection, fallback)
        for _, effect in pairs(collection or {}) do
            local id = type(effect) == 'table' and effect.id or effect
            if tonumber(id) then
                add(id, effect, effect_priority(id, effect, fallback))
            end
        end
    end

    local function add_keyed(collection, fallback)
        for key, effect in pairs(collection or {}) do
            if effect then
                local id = type(effect) == 'table' and effect.id or nil
                id = id or key
                if tonumber(id) then
                    add(id, effect, effect_priority(id, effect, fallback))
                end
            end
        end
    end

    add_array(entry.buffs, 2)
    add_array(entry.aura_buffs, 2)
    add_keyed(entry.debuffs, 1)
    add_keyed(entry.event_debuffs, 1)
    add_keyed(entry.event_buffs, 2)
    if buff and buff.enemy_aura_list then
        local ok, positional = pcall(function()
            return select(1, buff.enemy_aura_list(entry))
        end)
        if ok and type(positional) == 'table' then
            for _, id in ipairs(positional) do add(id, id, 1) end
        end
    end

    table.sort(result, function(left, right)
        if left.priority == right.priority then return left.id < right.id end
        return left.priority < right.priority
    end)
    return result
end

local function active_skillchain_icons(entry)
    local current = entry.skillchain
    local started = current and tonumber(current.time)
    if not started then return {} end
    local duration = tonumber(current.skillchain_duration) or 9
    if os.clock() - started >= duration then return {} end

    local types = type(current.type) == 'table' and current.type or {current.type}
    local result = {}
    local seen = {}
    for _, value in ipairs(types) do
        value = tonumber(value)
        if value and value ~= -99 then
            local skillchain_type = math.abs(value)
            if skillchain_type == 101 then skillchain_type = 1 end
            if skillchain_type == 102 then skillchain_type = 2 end
            if skillchain_type >= 1 and skillchain_type <= 14 and not seen[skillchain_type] then
                seen[skillchain_type] = true
                table.insert(result, skillchain_type)
                if #result >= max_skillchain_icons then break end
            end
        end
    end
    return result
end

local claim_colors = {
    party = {r = 255, g = 55, b = 55, a = 255},
    other = {r = 255, g = 105, b = 180, a = 255},
    help = {r = 255, g = 220, b = 45, a = 255},
    unclaimed = {r = 255, g = 255, b = 255, a = 255},
}
local active_name_color = shared_style.text
local defeated_name_color = shared_style.muted

local function set_enemy_name_color(row, entry)
    local hp = tonumber(entry.hp)
    local max_hp = tonumber(entry.max_hp)
    local hpp = tonumber(entry.hpp)
    local is_defeated
    if hp ~= nil and max_hp ~= nil and max_hp > 0 then
        is_defeated = hp <= 0
    elseif hpp ~= nil then
        is_defeated = hpp <= 0
    else
        is_defeated = hp ~= nil and hp <= 0
    end
    local color = is_defeated and defeated_name_color or active_name_color
    row.name_label.txt_obj:set_color(color[1], color[2], color[3], color[4])
end

local function claim_color(entry)
    local status = tonumber(entry.status) or 0
    if bit.band(status, 0x20) ~= 0 then return claim_colors.help end

    local claim = tonumber(entry.claim) or 0
    if claim == 0 then return claim_colors.unclaimed end
    if claim == tonumber(ACTOR_LIB.player.id) or LIBRARY_STRUCTURE.is_claimed_by_party(claim) then
        return claim_colors.party
    end
    return claim_colors.other
end

local function refresh_icons(row, entry)
    row.claim_icon:set_color(claim_color(entry))
    row.claim_icon:show()

    local skillchain_icons = active_skillchain_icons(entry)
    if #skillchain_icons > 0 then
        local step = math.max(1, math.floor(tonumber(entry.skillchain.step) or 1))
        row.skillchain_step_label:set_text(tostring(step))
        row.skillchain_step_label:show()
    else
        row.skillchain_step_label:hide()
    end
    for index, icon in ipairs(row.skillchain_icons) do
        local skillchain_id = skillchain_icons[index]
        if skillchain_id then
            if icon.skillchain_id ~= skillchain_id then
                icon:set_image(windower.addon_path .. 'media/elements/' .. skillchain_id .. '.png')
                icon.skillchain_id = skillchain_id
            end
            icon:show()
        else
            icon:hide()
            icon.skillchain_id = nil
        end
    end

    local effects = active_effect_ids(entry)
    local compact = #effects > effects_per_row
    local icon_size = compact and compact_effect_icon_size or effect_icon_size
    local icon_gap = compact and 1 or 0
    for index, icon in ipairs(row.effect_icons) do
        local effect = effects[index]
        if effect then
            local column = (index - 1) % effects_per_row
            local effect_row = compact and math.floor((index - 1) / effects_per_row) or 0
            icon:set_position(
                effects_x + column * (icon_size + icon_gap),
                compact and (2 + effect_row * (icon_size + 2)) or 7
            )
            if icon.width ~= icon_size or icon.height ~= icon_size then
                icon:set_size(icon_size, icon_size)
                icon:on_size_change()
            end
            if icon.effect_id ~= effect.id then
                icon:set_image(windower.addon_path .. 'media/icons/' .. effect.id .. '.png')
                icon.effect_id = effect.id
            end
            icon:show()
        else
            icon:hide()
            icon.effect_id = nil
        end
    end
end

local function hide_icons(row)
    row.claim_icon:hide()
    row.skillchain_step_label:hide()
    for _, icon in ipairs(row.skillchain_icons) do
        icon:hide()
        icon.skillchain_id = nil
    end
    for _, icon in ipairs(row.effect_icons) do
        icon:hide()
        icon.effect_id = nil
    end
end

local function enemies()
    local result = {}
    for id, entry in pairs(ACTOR_LIB.enemy or {}) do
        local enemy_id = type(entry) == 'table' and tonumber(entry.id or id) or nil
        if enemy_id and enemy_id ~= -1 then
            table.insert(result, {
                entry = entry,
                id = enemy_id,
                name = enemy_name(entry),
            })
        end
    end
    table.sort(result, function(left, right)
        local left_name = left.name:lower()
        local right_name = right.name:lower()
        if left_name == right_name then return tonumber(left.id) < tonumber(right.id) end
        return left_name < right_name
    end)
    return result
end

refresh = function()
    local list = enemies()
    total_pages = math.max(1, math.ceil(#list / rows_per_page))
    current_page = math.max(1, math.min(current_page, total_pages))
    page_label:set_text(tostring(current_page) .. ' / ' .. tostring(total_pages))

    local show_page_controls = total_pages > 1
    previous_button:set_visibility(show_page_controls)
    next_button:set_visibility(show_page_controls)
    page_label:set_visibility(show_page_controls)

    local first = (current_page - 1) * rows_per_page + 1
    local visible_rows = math.min(rows_per_page, math.max(0, #list - first + 1))
    if #list == 0 then visible_rows = 1 end
    local current_footer_y = column_height + visible_rows * row_height
    previous_button:set_y(current_footer_y)
    next_button:set_y(current_footer_y)
    page_label:set_y(current_footer_y)

    for row_index, row in ipairs(rows) do
        local entry = row_index <= rows_per_page and list[first + row_index - 1] or nil
        if entry then
            local ratio, hp_text = enemy_hp(entry.entry)
            row.name_label:set_text(entry.name)
            set_enemy_name_color(row, entry.entry)
            row.id_label:set_text('ID ' .. tostring(entry.id))
            row.hp_bar:set_value(ratio)
            row.hp_label:set_text(hp_text)
            row.enemy_entry = entry.entry
            refresh_icons(row, entry.entry)
            row:show()
        elseif #list == 0 and row_index == 1 then
            row.name_label:set_text('No enemies tracked')
            row.name_label.txt_obj:set_color(
                active_name_color[1], active_name_color[2], active_name_color[3], active_name_color[4]
            )
            row.id_label:set_text('')
            row.hp_label:set_text('')
            row.hp_bar:hide()
            row.enemy_entry = nil
            hide_icons(row)
            row:show()
        else
            row.enemy_entry = nil
            hide_icons(row)
            row:hide()
        end
        if entry then row.hp_bar:show() end
    end
    region:update_absolute_position(true)
end

function region:get_enemylist_settings()
    return {
        rows_per_page = rows_per_page,
    }
end

function region:set_enemylist_rows_per_page(value)
    value = math.max(min_rows_per_page, math.min(max_rows_per_page, math.floor(tonumber(value) or rows_per_page)))
    if rows_per_page == value then return end
    rows_per_page = value
    current_page = 1
    set_character_save_setting('view_basic_enemy_list_rows_per_page', ACTOR_LIB.player.name, rows_per_page_key, value)
    refresh()
end

EVENT_TRIGGER.set('enemy_update',
    {'spawn', 'pop', 'despawn', 'removed', 'reset', 'name', 'hpp', 'status', 'claim', 'buff', 'debuff', 'action_taken_sc'},
    'view_basic_enemy_list',
    function()
        refresh()
    end)

local next_icon_refresh = 0
windower.register_event('prerender', function()
    if not region:is_drawn() then return end
    local now = os.clock()
    if now < next_icon_refresh then return end
    next_icon_refresh = now + 0.5
    refresh()
end)

refresh()
shared.bind_frame(region)
shared.subscribe(function()
    for _, row in ipairs(rows) do row.name_label.full_text = nil end
    refresh()
end)
shared.attach_double_click(region)
return region
