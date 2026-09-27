local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local label = setting.label or " "

    local on_click = setting.on_click
    local width = setting.width or 100
    local height = setting.height or 26
    local font_size = setting.size or defaults.font_size

    local is_pressed = false


    local bg = images_prim.new()
    bg:set_size(width - 2, height - 2)
    bg:set_pos(1, 1)
    bg:set_fit(false)
    if setting.image then
        bg:set_path(setting.image)
    else
        bg:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
    end

    local imagebutton,id = ui_base:new({
        type = "button",
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = width,
        height = height,
        visible = true,
        bg_object = bg,
        last_text_width = 0,
        on_click = on_click,
        name = setting.name or nil,
    })
    
    imagebutton:add(bg)

    function imagebutton:update_absolute_position()
        ui_base.update_absolute_position(self)
    end

    function imagebutton:mouse_event(type, mx, my, delta)
        local inside = imagebutton:contains_point(mx, my)

        if inside == true then
            if type == 1 then
                ui.elements:press(self.id)
                imagebutton.bg_object:set_color(128, 128, 128, 255)
                imagebutton:update_absolute_position()
                return true,self.id

            elseif type == 2 then
                if ui.elements:is_pressed(self.id) then
                    ui.elements:unpress()
                    imagebutton.bg_object:set_color(255, 255, 255, 255)
                    imagebutton:update_absolute_position()

                    if inside and imagebutton.on_click then
                        imagebutton:on_click()
                    end
                    return true,self.id
                end

            elseif type == 0 and ui.elements:is_pressed(self.id) then
                is_pressed = false
                imagebutton.bg_object:set_color(255, 255, 255, 255)
                imagebutton:update_absolute_position()
            end
        end
        return ui.elements:is_pressed(self.id),self.id
    end

    function imagebutton:unpress()
        imagebutton.bg_object:set_color(255, 255, 255, 255)
        imagebutton:update_absolute_position()
    end

    function imagebutton:set_image(image_path)
        if not self.bg_object then return end
        self.bg_object:set_path(image_path)
    end

    imagebutton:update_absolute_position()
    return imagebutton
end