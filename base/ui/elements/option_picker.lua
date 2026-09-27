local defaults = require('base/ui/ui_defaults')

-- A paged option list that is meant to replace a settings page temporarily.
-- It never opens on top of sibling controls, which avoids Windower's global
-- image-before-text draw order problem.
return function(setting)
    setting = setting or {}

    local width = tonumber(setting.width) or 240
    local height = tonumber(setting.height) or 160
    local row_height = math.max(16, tonumber(setting.row_height) or 20)
    local row_gap = math.max(0, tonumber(setting.row_gap) or 3)
    local header_height = math.max(20, tonumber(setting.header_height) or 22)
    local footer_height = math.max(20, tonumber(setting.footer_height) or 22)
    local options = setting.options or {}
    local selected_value = setting.value
    local current_page = 1

    local available_height = math.max(row_height, height - header_height - footer_height - 6)
    local calculated_rows = math.max(1, math.floor((available_height + row_gap) / (row_height + row_gap)))
    local rows_per_page = math.max(1, math.floor(tonumber(setting.rows_per_page) or calculated_rows))

    local picker = ui.create_imageless_region({
        x = setting.x or 0,
        y = setting.y or 0,
        width = width,
        height = height,
        draggable = false,
        name = setting.name or 'option_picker',
    })

    local back_button = ui.create_button({
        x = 0, y = 0,
        width = 56, height = 20,
        label = '< Back',
        size = tonumber(setting.button_size) or 8,
        on_click = function()
            if setting.on_back then setting.on_back() end
        end,
    })
    picker:add(back_button)

    local title = ui.create_label({
        x = 64, y = 0,
        width = width - 64,
        height = 20,
        text = setting.title or 'Select option',
        size = tonumber(setting.title_size) or 9,
        color = setting.title_color or {225, 235, 245, 255},
    })
    title.txt_obj:set_bold(true)
    picker:add(title)

    local row_buttons = {}
    local page_label
    local previous_button
    local next_button

    local function total_pages()
        return math.max(1, math.ceil(#options / rows_per_page))
    end

    local function refresh()
        local pages = total_pages()
        current_page = math.max(1, math.min(current_page, pages))

        for slot, button in ipairs(row_buttons) do
            local index = (current_page - 1) * rows_per_page + slot
            local option = options[index]
            button.option_index = index
            if option ~= nil then
                local prefix = option == selected_value and '> ' or '  '
                button:set_text(prefix .. tostring(option))
                button:show()
            else
                button:hide()
            end
        end

        page_label:set_text(tostring(current_page) .. ' / ' .. tostring(pages))
        previous_button:set_visibility(pages > 1)
        next_button:set_visibility(pages > 1)
        page_label:set_visibility(pages > 1)
    end

    for slot = 1, rows_per_page do
        local row_slot = slot
        local button = ui.create_button({
            x = 0,
            y = header_height + (slot - 1) * (row_height + row_gap),
            width = width,
            height = row_height,
            label = '',
            size = tonumber(setting.option_size) or 9,
            on_click = function()
                local index = (current_page - 1) * rows_per_page + row_slot
                local option = options[index]
                if option == nil then return end
                selected_value = option
                refresh()
                if setting.on_select then setting.on_select(index, option) end
            end,
        })
        row_buttons[slot] = button
        picker:add(button)
    end

    local footer_y = height - footer_height
    previous_button = ui.create_button({
        x = 0, y = footer_y,
        width = 28, height = 20,
        label = '<', size = 9,
        on_click = function()
            if current_page <= 1 then return end
            current_page = current_page - 1
            refresh()
        end,
    })
    picker:add(previous_button)

    next_button = ui.create_button({
        x = width - 28, y = footer_y,
        width = 28, height = 20,
        label = '>', size = 9,
        on_click = function()
            if current_page >= total_pages() then return end
            current_page = current_page + 1
            refresh()
        end,
    })
    picker:add(next_button)

    page_label = ui.create_label({
        x = 34, y = footer_y,
        width = width - 68,
        height = 20,
        text = '1 / 1',
        size = 8,
        horizontal_align = 'center',
        color = {190, 200, 220, 255},
    })
    picker:add(page_label)

    function picker:set_options(new_options)
        options = new_options or {}
        current_page = 1
        refresh()
    end

    function picker:set_selected_value(value)
        selected_value = value
        for index, option in ipairs(options) do
            if option == value then
                current_page = math.ceil(index / rows_per_page)
                break
            end
        end
        refresh()
    end

    function picker:get_selected_value()
        return selected_value
    end

    function picker:get_page()
        return current_page
    end

    function picker:get_total_pages()
        return total_pages()
    end

    refresh()
    return picker
end
