local M = {values = require('settings/view_settings').shared_style, listeners = {}}
M.roles = {'background', 'outline', 'text', 'muted', 'accent', 'warning', 'danger'}
local path = windower.addon_path .. 'settings/view_style.ini'

function M.subscribe(callback) M.listeners[#M.listeners + 1] = callback end
local function notify() for _, callback in ipairs(M.listeners) do callback() end end
local preview_baseline
local function snapshot()
    local result = {font = M.values.font}
    for _, role in ipairs(M.roles) do
        local c = M.values[role]
        result[role] = {c[1], c[2], c[3], c[4]}
    end
    return result
end

local function apply_preview(value)
    M.values.font = value.font
    for _, role in ipairs(M.roles) do
        for channel = 1, 4 do M.values[role][channel] = value[role][channel] end
    end
    notify()
end

local function end_preview()
    if not preview_baseline then return end
    local restore = preview_baseline
    preview_baseline = nil
    apply_preview(restore)
end

function M.reload()
    local file = io.open(path, 'r')
    if not file then return end
    local content = file:read('*a')
    file:close()
    local font = content:match('font=([^\r\n]+)')
    if font and #font <= 80 then M.values.font = font end
    for _, role in ipairs(M.roles) do
        local r, g, b, a = content:match(role .. '=(%d+),(%d+),(%d+),(%d+)')
        if r and tonumber(r) <= 255 and tonumber(g) <= 255 and tonumber(b) <= 255 and tonumber(a) <= 255 then
            local value = M.values[role]
            value[1], value[2], value[3], value[4] = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
        end
    end
    -- An explicit save/reload supersedes the rollback point, including Theatre updates.
    if preview_baseline then preview_baseline = snapshot() end
    notify()
end

function M.save(draft)
    local file, err = io.open(path, 'w')
    if not file then return false, err end
    local lines = {'font=' .. draft.font}
    for _, role in ipairs(M.roles) do lines[#lines + 1] = role .. '=' .. table.concat(draft[role], ',') end
    local ok, write_error = file:write(table.concat(lines, '\n') .. '\n')
    file:close()
    if not ok then return false, write_error end
    M.reload()
    windower.send_ipc_message('enemylist_style_reload')
    return true
end

function M.bind_label(label, color)
    local role
    for _, key in ipairs(M.roles) do if color == M.values[key] then role = key end end
    M.subscribe(function()
        label.txt_obj:set_font(M.values.font)
        label.font = M.values.font
        if role then
            local c = M.values[role]
            label.txt_obj:set_color(c[1], c[2], c[3], c[4])
        end
    end)
end

-- Standard view heading, matching Superwarp. Keep new view titles consistent.
function M.create_title(settings)
    settings.text = tostring(settings.text or ''):upper()
    settings.size = 10
    settings.height = 16
    settings.font = M.values.font
    settings.color = M.values.accent
    local label = ui.create_label(settings)
    label.txt_obj:set_bold(true)
    M.bind_label(label, M.values.accent)
    return label
end

function M.bind_frame(region)
    M.subscribe(function()
        local c = M.values.background
        region.bg_prim:set_color(c[1], c[2], c[3], c[4])
        region.outline:set_color(M.values.outline)
    end)
end

local editor, draft, sliders, font_picker, font_button, status, main_page, style_picker, style_button
local active_view
local rows_slider, rows_label, rows_value
local function show_main_page()
    if font_picker then font_picker:hide() end
    if style_picker then style_picker:hide() end
    if main_page then
        main_page:show()
        if rows_slider then
            local supports_list_settings = active_view and active_view.get_enemylist_settings ~= nil
            rows_slider:set_visibility(supports_list_settings)
            rows_label:set_visibility(supports_list_settings)
            rows_value:set_visibility(supports_list_settings)
        end
    end
end
local function sync_list_settings()
    if not active_view or not active_view.get_enemylist_settings then return end
    local values = active_view:get_enemylist_settings()
    rows_slider.val = values.rows_per_page
    rows_slider:update_slider_position()
    rows_value:set_text(tostring(values.rows_per_page))
end
local function sync_controls()
    for _, role in ipairs(M.roles) do
        for channel = 1, 4 do
            sliders[role][channel].val = draft[role][channel]
            sliders[role][channel]:update_slider_position()
        end
    end
    font_picker:set_selected_value(draft.font)
    font_button:set_text(draft.font)
end

local function preview_preset(name)
    local file = io.open(windower.addon_path .. 'settings/view_styles/' .. name .. '.ini', 'r')
    if not file then status:set_text('Preset unavailable: ' .. name); return end
    local content = file:read('*a'); file:close()
    local next_style = {font = content:match('font=([^\r\n]+)')}
    for _, role in ipairs(M.roles) do
        local r, g, b, a = content:match(role .. '=(%d+),(%d+),(%d+),(%d+)')
        if not r or tonumber(r) > 255 or tonumber(g) > 255 or tonumber(b) > 255 or tonumber(a) > 255 then
            status:set_text('Invalid preset: ' .. name); return
        end
        next_style[role] = {tonumber(r), tonumber(g), tonumber(b), tonumber(a)}
    end
    if not next_style.font then status:set_text('Preset font missing'); return end
    draft = next_style
    sync_controls()
    apply_preview(draft)
    status:set_text(name .. ' preview — Apply and save to keep')
    return true
end
function M.open(anchor)
    active_view = anchor
    if not editor then
        editor = require('menu/views/view_settings_window').new({
            width = 470, height = 400, title = 'View settings',
            name = 'shared_style_editor', parent = MENU_UI.view_region,
            on_hide = function() end_preview(); show_main_page() end,
        })
        main_page = ui.create_imageless_region({x = 0, y = 0, width = 470, height = 400, draggable = false})
        editor:add(main_page)
        local function text(value, x, y, width)
            local label = ui.create_label({text = value, x = x, y = y, width = width, height = 20, size = 9})
            main_page:add(label)
            return label
        end
        text('Font', 10, 29, 80)
        local font_options = {'Arial', 'Verdana', 'Tahoma', 'Consolas', 'Segoe UI', 'Trebuchet MS'}
        font_button = ui.create_button({x = 100, y = 29, width = 220, height = 23,
            label = M.values.font, on_click = function()
                font_picker:set_selected_value(draft.font)
                main_page:hide()
                font_picker:show()
            end})
        main_page:add(font_button)
        font_picker = ui.create_option_picker({x = 10, y = 29, width = 450, height = 320,
            title = 'Select font', options = font_options, rows_per_page = 10,
            name = 'shared_font_picker', value = M.values.font, on_back = show_main_page,
            on_select = function(_, value)
                draft.font = value
                font_button:set_text(value)
                apply_preview(draft)
                status:set_text('Live preview — Apply and save to keep changes')
                show_main_page()
            end})
        editor:add(font_picker)
        font_picker:hide()
        for channel, name in ipairs({'Red', 'Green', 'Blue', 'Alpha'}) do text(name, 100 + (channel - 1) * 91, 57, 84) end
        sliders = {}
        for index, role in ipairs(M.roles) do
            text(role, 10, 82 + (index - 1) * 27, 88)
            sliders[role] = {}
            for channel = 1, 4 do
                local slider = ui.create_slider({x = 100 + (channel - 1) * 91, y = 82 + (index - 1) * 27,
                    length = 80, min = 0, max = 255, step = 1, val = M.values[role][channel],
                    on_change = function(value)
                        if draft then
                            draft[role][channel] = math.floor(value)
                            apply_preview(draft)
                            status:set_text('Live preview — Apply and save to keep changes')
                        end
                    end})
                sliders[role][channel] = slider
                main_page:add(slider)
            end
        end
        local preset_files = {}
        text('Base style', 10, 276, 88)
        style_button = ui.create_button({x = 100, y = 276, width = 220, height = 23,
            label = 'Select style...', on_click = function()
                local options = {}
                preset_files = {}
                local ok, files = pcall(windower.get_dir, windower.addon_path .. 'settings/view_styles/')
                for _, file in ipairs(ok and files or {}) do
                    local name = file:match('^([^/\\]+)%.[iI][nN][iI]$')
                    if name then
                        local label = name:lower() == 'ff7' and 'FF7' or name:gsub('^%l', string.upper)
                        options[#options + 1] = label
                        preset_files[label] = name
                    end
                end
                table.sort(options)
                style_picker:set_options(options)
                main_page:hide()
                style_picker:show()
        end})
        main_page:add(style_button)
        style_picker = ui.create_option_picker({x = 10, y = 29, width = 450, height = 320,
            title = 'Select base style', options = {}, rows_per_page = 10,
            name = 'shared_style_picker', on_back = show_main_page,
            on_select = function(_, label)
                if preset_files[label] and preview_preset(preset_files[label]) then style_button:set_text(label) end
                show_main_page()
            end})
        editor:add(style_picker)
        style_picker:hide()

        rows_label = text('Enemies per page', 10, 310, 125)
        rows_value = text('10', 410, 310, 35)
        rows_slider = ui.create_slider({x = 140, y = 310, length = 260, min = 3, max = 10, step = 1, val = 10,
            on_change = function(value)
                value = math.floor(tonumber(value) or 10)
                rows_value:set_text(tostring(value))
                if active_view and active_view.set_enemylist_rows_per_page then
                    active_view:set_enemylist_rows_per_page(value)
                end
            end})
        main_page:add(rows_slider)

        main_page:add(ui.create_button({x = 10, y = 350, width = 135, height = 23, label = 'Apply and save',
            on_click = function()
                local ok, err = M.save(draft)
                status:set_text(ok and 'Saved for all shared views' or ('Save failed: ' .. tostring(err)))
            end}))
        main_page:add(ui.create_button({x = 158, y = 350, width = 90, height = 23, label = 'Close', on_click = function() editor:hide() end}))
        status = text('', 10, 378, 450)
    end
    end_preview()
    preview_baseline = snapshot()
    draft = {font = M.values.font}
    for _, role in ipairs(M.roles) do
        draft[role] = {}
        for channel = 1, 4 do
            draft[role][channel] = M.values[role][channel]
            sliders[role][channel].val = draft[role][channel]
            sliders[role][channel]:update_slider_position()
        end
    end
    font_picker:set_selected_value(draft.font)
    font_button:set_text(draft.font)
    status:set_text('Live preview — Close discards unapplied changes')
    style_button:set_text('Select style...')
    sync_list_settings()
    show_main_page()
    editor:show(anchor)
end

function M.attach_double_click(region)
    local original = region.mouse_event
    local last_click, down_x, down_y = 0
    function region:mouse_event(kind, x, y, delta)
        if not self:is_drawn() then down_x = nil; last_click = 0; return false end
        local inside = x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
        if kind == 1 and inside then down_x, down_y = x, y end
        if kind == 2 and down_x then
            if inside and math.abs(x - down_x) < 4 and math.abs(y - down_y) < 4 then
                local now = os.clock()
                if last_click > 0 and now - last_click < 0.35 then M.open(self); last_click = 0 else last_click = now end
            end
            down_x = nil
        end
        return original(self, kind, x, y, delta)
    end
end

windower.register_event('ipc message', function(message) if message == 'enemylist_style_reload' then M.reload() end end)
M.reload()
return M
