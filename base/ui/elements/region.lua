local ui_base = require('base/ui/ui_base')
local defaults = require('base/ui/ui_defaults')

return function(setting)
    local x = setting.x or 0
    local y = setting.y or 0
    local w = setting.width or 0
    local h = setting.height or 0

    local outline_size = 0
    if setting.outline_size then
        outline_size = setting.outline_size
    else
        outline_size = 2 -- standaard outline-dikte
    end

    -- Outline
    local outline_color = setting.outline_color or defaults.outline_color
    if setting.outline_alpha then outline_color = mathFunctions.get_color_set_alpha(outline_color, setting.outline_alpha) end
    local outline = ui.create_line{
        thickness = 3,
        closed = true,
        color = outline_color,
        lines = {
            { x = 0,  y = 0 },   -- P0 (start)
            { x = 0, y = h },  -- P1 (control)
            { x = w, y = h },   -- P2 (end)
            { x = w, y = 0 },   -- P2 (end)
        },	
    }
    outline:set_visibility(setting.outline_color ~= nil)
    -- BG (boven de outline, iets kleiner zodat de outline zichtbaar blijft)
    local bg = images_prim.new()
    local bg_x = outline_size
    local bg_y = outline_size
    local bg_w = (setting.width or 0) - 2 * outline_size
    local bg_h = (setting.height or 0) - 2 * outline_size
    if bg_w < 0 then bg_w = 0 end
    if bg_h < 0 then bg_h = 0 end
    bg:set_size(bg_w, bg_h)
    bg:set_pos(bg_x, bg_y)
    -- Gebruik kleur uit setting of standaardkleur
    if setting.bg_color then
        if type(setting.bg_color) == "table" then
            bg:set_color(setting.bg_color[1], setting.bg_color[2], setting.bg_color[3], setting.bg_color[4])
        else
            -- -- als bg_color een hex is, converteer naar rgba
            local c = setting.bg_color
            local a = bit.rshift(bit.band(c, 0xFF000000), 24)
            local r = bit.rshift(bit.band(c, 0x00FF0000), 16)
            local g = bit.rshift(bit.band(c, 0x0000FF00), 8)
            local b = bit.band(c, 0x000000FF)
            bg:set_color(r, g, b, a)
        end
    else
        bg:set_color(30, 30, 30, 180)
    end
    bg:set_fit(false)

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
        outline = outline,
        bg_prim = bg,
        ignore_child_mouse = setting.ignore_child_mouse or false,
        name = setting.name or nil,

        draw_outline = function(self)
            outline:show()
        end,

        hide_outline = function(self)
            if self.outline then
                self.outline:hide()
                self.outline:destroy()
                self.outline = nil
            end
        end,

        set_draggable = function(self, state)
            self.draggable = state and true or false
        end,


        on_position_change = function(self)
            if self.outline then
                -- self.outline:set_start(self.base_x, self.base_y)
            end
            if self.bg_prim then
                local bg_x = outline_size
                local bg_y = outline_size
                self.bg_prim:set_pos(bg_x, bg_y)
            end

            if self.on_region_position_change then
                self.on_region_position_change(self)
            end
        end,

        on_size_change = function(self)
            if self.outline then
                self.outline:set_lines({
                    { x = 0,  y = 0 },   -- P0 (start)
                    { x = 0, y = self.height },  -- P1 (control)
                    { x = self.width, y = self.height },   -- P2 (end)
                    { x = self.width, y = 0 },   -- P2 (end)
                })
            end
            if self.bg_prim then
                local bg_w = self.width - 2 * outline_size
                local bg_h = self.height - 2 * outline_size
                if bg_w < 0 then bg_w = 0 end
                if bg_h < 0 then bg_h = 0 end
                self.bg_prim:set_size(bg_w, bg_h)
            end
        end,
    })

    -- Voeg eerst outline toe, dan bg (bg boven outline)
    region:add_internal(outline)
    region:add_internal(bg)

    function region:mouse_event(type, mx, my, delta)
        -- print('Region mouse_event', region.id, mx, my, delta, region.draggable)
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
                    if is_pressed and self.on_region_drag_end then
                        self.on_region_drag_end(self)
                    end
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
