local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local label = setting.label or " "

    local on_click = setting.on_click
    local width = setting.width or 100
    local height = setting.height or 26
    local font_size = setting.size or defaults.font_size

    local is_pressed = false

    local border_thickness = 1

    local border = images_prim.new()
    border:set_size(width, height)
    border:set_pos(0, 0)
    border:set_color(defaults.border_color[1], defaults.border_color[2], defaults.border_color[3], defaults.border_color[4])
    border:set_fit(false)

    local bg = images_prim.new()
    bg:set_size(width - border_thickness * 2, height - border_thickness * 2)
    bg:set_pos(border_thickness, border_thickness)
    bg:set_fit(false)
    bg:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
    

    local txt_prim = texts_prim.new(label, {
        x = 0,
        y = 0,
        text = {
            font = setting.font or defaults.font,
            size = font_size,
            red = 255,
            green = 255,
            blue = 255,
            alpha = 255,
        },
        bg = {alpha = 0, visible = false},
        flags = {draggable = false},
        padding = 0
    })

    local button,id = ui_base:new({
        type = "button",
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = width,
        height = height,
        visible = true,
        text_object = txt_prim,
        bg_object = bg,
        border = border,
        last_text_width = 0,
        on_click = on_click,
        name = setting.name or nil,
    })
    
    button:add(border)
    button:add(bg)
    button:add(txt_prim)

    function button:set_text(new_text)
        if not self.text_object then return end

        self.text_object:set_text(new_text)

        coroutine.schedule(function()
            local width = ui.get_text_width(new_text, self.text_object:get_font() or 'Arial', font_size)
            if self.auto_width then
                self.width = math.floor(width + 10)
            end

            if self.auto_height and self.font_size then
                local lines = 1
                for _ in (new_text or ''):gmatch('\n') do lines = lines + 1 end
                self.height = lines * self.font_size
            end

            self:update_absolute_position()
        end, 0.05)
    end

    function button:update_absolute_position()
        ui_base.update_absolute_position(self)

        border:set_size(self.width, self.height)
        bg:set_size(
            math.max(0, self.width - border_thickness * 2),
            math.max(0, self.height - border_thickness * 2)
        )

        local offset = ui.elements:is_pressed(self.id) and 1 or 0

        local inner_width = self.width - border_thickness * 2
        local text = self.text_object:get_text() or ""
        local text_width = self.text_object.text_width
        if text_width == nil and self.text_object.get_text_width then
            text_width = self.text_object:get_text_width()
        end
        text_width = tonumber(text_width) or 0
        
        local cx = border_thickness + math.floor((inner_width - text_width) / 2) + offset

        local lines = 1
        for _ in text:gmatch('\n') do lines = lines + 1 end
        local total_text_height = lines * font_size

        local cy = math.floor((self.height - total_text_height) / 2) + offset
        local baseline = self.text_object:get_baseline() or 0
        cy = cy - math.floor(baseline / 2)

        -- print("Button text position: ", cx, "Text width: ", text_width,self.width)

        self.text_object:set_pos(cx, cy)
    end

    function button:mouse_event(type, mx, my, delta)
        if not button:is_drawn() then return false, self.id end
        local inside = button:contains_point(mx, my)

        if inside == true then
            if type == 1 then
                ui.elements:press(self.id)
                button.bg_object:set_color(defaults.pressed_color[1], defaults.pressed_color[2], defaults.pressed_color[3], defaults.pressed_color[4])
                button:update_absolute_position()
                return true,self.id

            elseif type == 2 then
                if ui.elements:is_pressed(self.id) then
                    ui.elements:unpress()
                    button.bg_object:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
                    button:update_absolute_position()

                    if inside and button.on_click then
                        button:on_click()
                    end
                    return true,self.id
                end

            elseif type == 0 and ui.elements:is_pressed(self.id) then
                is_pressed = false
                button.bg_object:set_color(defaults.pressed_color[1], defaults.pressed_color[2], defaults.pressed_color[3], defaults.pressed_color[4])
                button:update_absolute_position()
            end
        end
        return ui.elements:is_pressed(self.id),self.id
    end

    function button:unpress()
        button.bg_object:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
        button:update_absolute_position()
    end

    button:update_absolute_position()
    return button
end
