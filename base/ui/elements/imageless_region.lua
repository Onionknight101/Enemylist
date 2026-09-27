local ui_base = require('base/ui/ui_base')
local defaults = require('base/ui/ui_defaults')


return function(setting)
    local x = setting.x or 0
    local y = setting.y or 0
    local w = setting.width or 0
    local h = setting.height or 0


    local region,id = ui_base:new({
        title = setting.title or "region",
        type = 'region',
        base_x = x,
        base_y = y,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = setting.width or 0,
        height = setting.height or 0,
        auto_width = setting.auto_width or false,
        auto_height = setting.auto_height or false,
        layout = setting.layout,
        visible = true,
        scrollable = setting.scrollable or false,
        draggable = (setting.draggable == nil) and true or setting.draggable,
        drag_offset_x = defaults.padding.left,
        drag_offset_y = defaults.padding.top,
        offset_x = defaults.padding.left,
        offset_y = defaults.padding.top,
        ignore_child_mouse = setting.ignore_child_mouse or false,
        name = setting.name or nil,

        set_draggable = function(self, state)
            self.draggable = state and true or false
        end,

        on_position_change = function(self)
            if self.on_region_position_change then
                self.on_region_position_change(self)
            end
        end,
    })


    function region:mouse_event(type, mx, my, delta)
        if self.ignore_child_mouse==true then
            -- print('Region mouse_event', region.id,self.x, type, mx, my, delta, self.draggable,self.ignore_child_mouse)
        end
        if not region.visible then return end
        local rx, ry = region.x, region.y
        local rw, rh = region.width, region.height

        local is_pressed = ui.elements:is_pressed(self.id) 
        if is_pressed or (mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh) then

            if is_pressed == false and type < 4 then
                -- Check children eerst
                if self.ignore_child_mouse~=true then
                    for _, child in ipairs(region.children) do
                        if child.mouse_event then
                            local ret,ret_id = child:mouse_event(type, mx, my, delta)
                            if ret == true then return true,ret_id end
                        end
                    end
                end
                -- Geen child handled het, return false
                return false

            elseif region.scrollable == true and type == 10 and delta and delta ~= 0 then
                -- Scroll logica hier (optioneel)
                return true,self.id

            elseif region.draggable == true then
                if type == 4 then -- mouse down
                    ui.elements:press(self.id)
                    region.drag_offset_x = mx - region.base_x
                    region.drag_offset_y = my - region.base_y
                elseif type == 5 then -- mouse up
                    ui.elements:unpress()
                elseif type == 0 and is_pressed then -- mouse move
                    region.base_x = mx - region.drag_offset_x
                    region.base_y = my - region.drag_offset_y
                    region:update_absolute_position()
                end
                return true,self.id
            end
            return false
        end
    end

    function region:unpress()
    end

    region:update_absolute_position()
    
    return region
end