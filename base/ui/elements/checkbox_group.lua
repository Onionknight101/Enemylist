local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local spacing = setting.spacing or 0
    local option_width = setting.option_width or defaults.standard_width*6
    local single_select = setting.single_select or false
    local options = setting.options or {}
    local on_select = setting.on_select
    local selected_option = setting.selected_option or nil

    local layout_mode = setting.layout_mode or 'vertical'

    local group,id = ui_base:new({
        type = 'checkbox_group',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = 0,
        height = 0,
        visible = true,
        options = {},
        single_select = single_select,
        layout_mode = layout_mode,
        spacing = spacing,
        on_select = on_select,
        pressed_item = nil,
        name = setting.name or nil,
    })

    local function get_checkbox_icon(checked)
        return single_select
            and (checked and defaults.radio_on_texture or defaults.radio_off_texture)
            or (checked and defaults.checkbox_on_texture or defaults.checkbox_off_texture)
    end

    function group:add_option(label)
        local index = #self.options + 1

        local x = 0
        local y = 0
        if self.layout_mode == 'vertical' then
            y = (index - 1) * (defaults.standard_height+self.spacing)
        elseif self.layout_mode == 'horizontal' then
            x = (index - 1) * (option_width + self.spacing)
        end

        local option_region = ui.create_imageless_region({
            x = x, y = y,
            width = defaults.standard_width , -- arbitrary width for the text
            height = defaults.standard_height,
            draggable = false,
        })

        local box = images_prim.new()
        box:set_pos(0, 0)
        box:set_size(defaults.standard_width, defaults.standard_height)
        box:set_path(get_checkbox_icon(false))
        box:set_fit(false)

        local font_size = 12
        local baseline_offset = 10

        local txt_x = 0
        local txt_y = 0

        if self.layout_mode == 'vertical' then
            txt_x = defaults.standard_width + defaults.standard_spacing
            txt_y = math.floor((defaults.standard_height / 2) - baseline_offset)
        elseif self.layout_mode == 'horizontal' then
            txt_x = defaults.standard_width + defaults.standard_spacing
            txt_y = math.floor((defaults.standard_height / 2) - baseline_offset)
        end

        local txt_prim = texts_prim.new(label, {
            x = txt_x,
            y = txt_y,
            text = {
                font = 'Arial',
                size = font_size,
                red = 255,
                green = 255,
                blue = 255,
                alpha = 255,
            },
            flags = {draggable = false},
            bg = {alpha = 0, visible = false},
        })

        local item = {
            region = option_region,
            label = label,
            checked = false,
            box = box,
            text = txt_prim,
            base_y = y
        }

        table.insert(self.options, item)
        option_region:add(box)
        option_region:add(txt_prim)
        group:add_internal(option_region)

        if self.layout_mode == 'vertical' then
            group.width = defaults.standard_width + option_width + defaults.standard_spacing
            group.height = index * (defaults.standard_height + self.spacing) - self.spacing
        elseif self.layout_mode == 'horizontal' then
            group.width = index * (option_width + self.spacing) - self.spacing
            group.height = defaults.standard_height
        end
        self:update_width() 
        self:update_absolute_position()
    end

    function group:remove(label)
        for i, item in ipairs(self.options) do
            if item.label == label then
                table.remove(self.options, i)
                group:remove_internal(item.region)
                break
            end
        end
        self:update_width() 
        self:update_absolute_position()
    end
    
    function group:update_width()
        local max_right = 0
        for _, item in ipairs(self.options) do
            local box_w = defaults.standard_width
            local text_w = item.text.get_text_width and item.text:get_text_width() or 0
            max_right = math.max(max_right, box_w + text_w)
        end
        self.width = max_right
    end

    function group:toggle(label,skip_event)
        for _, item in ipairs(self.options) do
            if item.label == label then
                if self.single_select then
                    for _, other in ipairs(self.options) do
                        other.checked = false
                        other.box:set_path(get_checkbox_icon(false))
                    end
                    item.checked = true
                    self.selected_option = label
                else
                    item.checked = not item.checked
                end
                item.box:set_path(get_checkbox_icon(item.checked))
                if self.on_select and skip_event~=true then
                    self.on_select(label)
                end
            end
        end
    end

    function group:get_selected()
        local selected = {}
        for _, item in ipairs(self.options) do
            if item.checked then
                table.insert(selected, item.label)
            end
        end
        return selected
    end

    function group:uncheck_all()
        for _, item in ipairs(self.options) do
            item.checked = false
            item.box:set_path(get_checkbox_icon(false))
        end
    end

    function group:mouse_event(type, mx, my, delta)
        for _, item in ipairs(group.options) do
            local bx, by = item.box:get_pos_raw()
            local bw, bh = defaults.standard_width, defaults.standard_height
            if mx >= bx and mx <= bx + bw and my >= by and my <= by + bh then
                if type == 1 then -- left click
                    ui.elements:press(self.id)
                    group.pressed_item = item
                    return true, self.id
                elseif type == 2 and ui.elements:is_pressed(self.id) then -- left release
                    ui.elements:unpress()
                    if group.pressed_item == item then
                        group:toggle(item.label)
                    end
                    group.pressed_item = nil
                    return true, self.id
                end
                return ui.elements:is_pressed(self.id),self.id
            end
        end
        return ui.elements:is_pressed(self.id),self.id
    end

    function group:unpress()
        --nothing for now
    end

    for _, lbl in ipairs(options) do
        group:add_option(lbl)
    end

    if selected_option then
        if type(selected_option) == 'table' then
            for _, opt in ipairs(selected_option) do
                group:toggle(opt, true)
            end
        else
            group:toggle(selected_option, true)
        end
    end

    return group
end