local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local width = setting.width or defaults.standard_width
    local height = setting.height or defaults.standard_height
    local image_path = setting.path or ''
    local fit = setting.fit or false
    local draggable = setting.draggable == true

    -- 📷 Maak windower image object
    local img = images_prim.new()
    img:set_pos(0, 0) -- wordt gepositioneerd via ui_base
    img:set_size(width , height)
    img:set_path(image_path)
    img:set_fit(fit)

    if setting.color then
        if type(setting.color) == "table" then
            img:set_color(setting.color[1], setting.color[2], setting.color[3], setting.color[4])
        else
            -- -- als bg_color een hex is, converteer naar rgba
            local c = setting.color
            local a = bit.rshift(bit.band(c, 0xFF000000), 24)
            local r = bit.rshift(bit.band(c, 0x00FF0000), 16)
            local g = bit.rshift(bit.band(c, 0x0000FF00), 8)
            local b = bit.band(c, 0x000000FF)
            img:set_color(r, g, b, a)
        end
    end

    -- 🧱 Maak base UI object

    local image_obj,id = ui_base:new({
        type = 'image',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = width,
        height = height,
        visible = true,
        children = {},
        on_click = setting.on_click,
        name = setting.name or nil,

        set_image = function(self, new_path)
            img:set_path(new_path)
        end,

        set_color = function(self, new_color)
            local r = new_color.r or 255
            local g = new_color.g or 255
            local b = new_color.b or 255
            local a = new_color.a or 255
            img:set_color(r, g, b, a)
        end,

        -- set_size = function(self, w, h)
        --     self.width = w
        --     self.height = h
        --     img:set_size(w, h)
        -- end,

        set_visibility = function(self, visible)
            img:visible(visible)
        end,

        on_size_change = function(self)
            img:set_size(self.width, self.height)
        end,

        mouse_event = function(self, type, mx, my, delta)
            local inside = self:contains_point(mx, my)

            if inside == true then
                if type == 1 then
                    ui.elements:press(self.id)
                    return true,self.id

                elseif type == 2 then
                    if ui.elements:is_pressed(self.id) then
                        ui.elements:unpress()

                        if inside and self.on_click then
                            self.on_click()
                        end
                        return true,self.id
                    end

                elseif type == 0 and ui.elements:is_pressed(self.id) then
                    is_pressed = false
                end
            end
            return ui.elements:is_pressed(self.id),self.id
        end,

        destroy = function(self)
            img:destroy()
            ui.elements:remove_ref(id)
        end,
    })
    
    image_obj:add(img)
    return image_obj
end