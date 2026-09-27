local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local width = setting.width or defaults.standard_width
    local height = setting.height or defaults.standard_height
    local label = setting.label or ''
    local is_checked = setting.checked == true
    local check_func = setting.check_func
    local checked_icon = nil
    local unchecked_icon = nil
    local custom_checked_icon = setting.checked_icon
    local custom_unchecked_icon = setting.unchecked_icon

    if check_func and type(check_func) == 'function' then
        is_checked = check_func()
    end
    is_checked = mathFunctions.bool_check(is_checked,false)

    local box = images_prim.new()
    box:set_pos(0, 0)
    box:set_size(defaults.big_width, defaults.big_height)
    box:set_path(is_checked and checked_icon or unchecked_icon)
    box:set_fit(false)

    txt_prim = texts_prim.new(label, {
        x = defaults.standard_width + 4,
        y = 0,
        text = {
            font = 'Arial',
            size = 11,
            red = 255,
            green = 255,
            blue = 255,
            alpha = 255
        },
        flags = {draggable = false},
        bg = {alpha = 0, visible = false},
    })

    local checkbox_obj = ui_base:new({
        id = id,
        type = 'checkbox',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = width,
        height = height,
        visible = true,
        children = {},
        checked = is_checked,
        check_func = check_func,
        extra = setting.extra,
        name = setting.name or nil,
        set = function(self, state)
            self.checked = state
            local icon = state and checked_icon or unchecked_icon
            box:set_path(icon)
        end,

        toggle = function(self)
            self:set(not self.checked)
            if setting.on_change then
                setting.on_change(self.checked,self.extra)
            end
        end
    })

    function checkbox_obj:mouse_event(type, mx, my, delta)
        local x, y = checkbox_obj.x, checkbox_obj.y
        local w, h = checkbox_obj.width, checkbox_obj.height
        local is_in_area = mx >= x and mx <= x + w and my >= y and my <= y + h

        if is_in_area then
            if type == 1 then -- left click
                ui.elements:press(self.id)
            elseif type == 2 and ui.elements:is_pressed(self.id) then -- left release
               
                ui.elements:unpress()
                checkbox_obj:toggle()
            end
            return true,self.id
        end
        return ui.elements:is_pressed(self.id),self.id
    end

    function checkbox_obj:update_width()
        local box_w = defaults.standard_width
        local spacing = 4
        local text_w = txt_prim.get_text_width and txt_prim:get_text_width() or 0
        local width = box_w + spacing + text_w
        self.width = width
        return width
    end

    function checkbox_obj:unpress()
        --nothing for now
    end

    function checkbox_obj:is_checked()
        return self.checked
    end

    function checkbox_obj:set_check(pressed_)
        --if this checkbox is set by a function ignore the given value and get the value from the function
        if self.check_func and type(self.check_func) == 'function' then
            self.checked = mathFunctions.bool_check(self.check_func(),false)
        else
            self.checked = pressed_ == true or pressed_ == 1 or pressed_ == 'true' or pressed_ == '1' or pressed_ == 'TRUE'
        end
        box:set_path(self.checked and checked_icon or unchecked_icon)
    end

    function checkbox_obj:refresh()
        --set the checkbox state based on the value function if it exists, otherwise keep the current state
        if self.check_func and type(self.check_func) == 'function' then
            self.checked = mathFunctions.bool_check(self.check_func(),false)
            box:set_path(self.checked and checked_icon or unchecked_icon)
        end
    end

    function checkbox_obj:set_mode(mode)
        if mode == 'playpauze' then
            checked_icon = defaults.checkbox_play
            unchecked_icon = defaults.checkbox_pauze
        elseif mode == 'custom' then
            checked_icon = custom_checked_icon or defaults.checkbox_on_texture
            unchecked_icon = custom_unchecked_icon or defaults.checkbox_off_texture
        else
            checked_icon = defaults.checkbox_on_texture
            unchecked_icon = defaults.checkbox_off_texture
        end
        box:set_path(self.checked and checked_icon or unchecked_icon)
    end

    checkbox_obj:add(box)
    checkbox_obj:add(txt_prim)
    checkbox_obj.width = width or checkbox_obj:update_width()

    checkbox_obj:set_mode(setting.mode)
    return checkbox_obj
end