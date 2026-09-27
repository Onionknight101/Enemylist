local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local orientation = setting.vertical and "vertical" or "horizontal"
    local length = setting.length
    local width, height

    if orientation == "horizontal" then
        width = length or 120
        height = defaults.standard_height
    else
        width =  defaults.standard_width
        height = length or 120
    end

    local min_value = setting.min or 0
    local max_value = setting.max or 1
    local step_value = setting.step or 0.01

    local on_get = setting.on_get
    local initial_val = setting.val or 0
    local on_change = setting.on_change
    local handle_size = orientation == "horizontal" and {w = 10, h = height} or {w = width, h = 10}

    if on_get and type(on_get) == "function" then
        initial_val = on_get()
    end
    if initial_val < min_value then initial_val = min_value end
    if initial_val > max_value then initial_val = max_value end

    local slider,id = ui_base:new({
        type = "slider",
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = width,
        height = height,
        val = initial_val,
        orientation = orientation,
        visible = true,
        object = nil,
        handle = nil,
        on_get = on_get,
        on_change = on_change,
        name = setting.name or nil,

        set_value = function(self, v)
            if type(v) ~= 'number' or self.val == v then return end
            self.val = math.min(math.max(v, 0), 1)
            self:update_absolute_position()
        end,

        get_value = function(self)
            return self.val
        end,

        is_inside = function(self, mx, my)
            local hx, hy = self.x,self.y
            local hw, hh = self.width, self.height
            return mx >= hx and mx <= hx + hw and my >= hy and my <= hy + hh
        end,
    })

    local bg = images_prim.new()
    bg:set_size(width, height)
    bg:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
    bg:set_fit(false)
    -- bg:show()
    
    slider.object = bg

    local handle = images_prim.new()
    handle:set_size(handle_size.w, handle_size.h)
    handle:set_color(200, 200, 200, 255)
    handle:set_fit(false)
    -- handle:show()
    slider.handle = handle

    function slider:update_slider_position()
        -- Alleen de handle verplaatsen, niet de bg of self.x/y!
        --val is between min and max, we need to convert it to a value between 0 and 1 for the position
        local normalized_val = (self.val - min_value) / (max_value - min_value)
        
        if self.orientation == "horizontal" then
            local usable = self.width - handle_size.w
            local hx = math.floor(normalized_val * usable)
            handle:set_pos(hx, 0)
        else
            local usable = self.height - handle_size.h
            local hy = math.floor(normalized_val * usable)
            handle:set_pos(0, hy)
        end
    end

    function slider:mouse_event(type, mx, my, delta)
        local is_inside = slider:is_inside(mx, my)
        local is_pressed = ui.elements:is_pressed(self.id)
        if is_inside or is_pressed==true then
            if type == 1 then
                ui.elements:press(self.id)
                bg:set_color(defaults.pressed_color[1], defaults.pressed_color[2], defaults.pressed_color[3], defaults.pressed_color[4])
            end

            if type <3 and is_pressed==true then
                local old_val = slider.val
                if orientation == "horizontal" then
                    local usable = width - handle_size.w
                    val = (mx - slider.x - handle_size.w / 2) / usable
                else
                    local usable = height - handle_size.h
                    val = (my - slider.y - handle_size.h / 2) / usable
                end

                val = math.min(math.max(val, 0), 1)
                --make sure the value is between min and max
                val = min_value + val * (max_value - min_value)
                --make sure val is a multiple of step_value
                local raw_val = val
                val = math.floor(val / step_value + 0.5) * step_value
                --dont forget rounding the value to the same amount of decimals as step_value
                -- local step_decimals = 0
                -- if step_value % 1 ~= 0 then
                --     step_decimals = #tostring(step_value):match(".*%.(.*)")
                --     print("step_decimals", step_decimals, step_value)
                -- end
                -- val = tonumber(string.format("%." .. step_decimals .. "f", val))
                if old_val ~= val then
                    slider.val = val
                    slider:update_slider_position()
                    if slider.on_change then slider.on_change(val) end
                end
            end

            if type == 2 then
                ui.elements:unpress()
            end

            return true,self.id
        end
        return false
    end

    function slider:unpress()
        bg:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
    end

    function slider:refresh()
        if slider.on_get and type(slider.on_get) == "function" then
            local old_val = slider.val
            slider.val = slider.on_get()
            if old_val ~= slider.val then
                slider:update_slider_position()
                if slider.on_change then slider.on_change(slider.val) end
            end
        end
    end
    
    slider:update_slider_position()
    slider:update_absolute_position()
    slider:add(bg)
    slider:add(handle)
    return slider
end