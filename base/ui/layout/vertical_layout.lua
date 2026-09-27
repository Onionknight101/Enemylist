local defaults = require('base/ui/ui_defaults')

 Vertical_Layout = {}
Vertical_Layout.__index = Vertical_Layout

function Vertical_Layout:new(opts)
	if opts==nil then opts= {} end
    local o = {
        type = 'Vertical_Layout',
        spacing = opts.spacing or defaults.standard_spacing,
        padding = opts.padding or defaults.padding.top,
        top_padding = opts.top_padding or opts.padding or defaults.padding.top,
        padding_left = opts.padding_left,
        align = opts.align or 'left', -- future-proofing
        auto_size = opts.auto_size or false,
        first_run = true,
    }
    return setmetatable(o, self)
end

function Vertical_Layout:apply(parent, force_update)
    if parent._applying_layout then return end
    parent._applying_layout = true

    -- Voeg deze boolean toe
    local child_updated_absolute_position = false

    -- Sla parent positie en size op op layout-niveau
    self._last_parent_x = self._last_parent_x or parent.x
    self._last_parent_y = self._last_parent_y or parent.y
    self._last_parent_width = self._last_parent_width or parent.width
    self._last_parent_height = self._last_parent_height or parent.height

    local cursor_y = self.top_padding or 0
    local count = 0
    local oldX = 0
    for _, child in ipairs(parent.children) do
        if self.first_run and stringFunctions.starts_with(child.id,'region') then
            --  print(count,"AA child x:", child.base_x, " id:", child.id)
             oldX = child.base_x
        end
        if child.visible ~= false then
            -- if auto_size then all children width are set to the width of the layout
            if self.auto_size then
                local changed = child:set_width(parent.width)
                if changed then
                    child_updated_absolute_position = true
                end
            end

            -- Alleen set_position als de positie wijzigt
            local parent_div_x = parent.layout_div_x or 0
            local parent_div_y = parent.layout_div_y or 0
            if child.base_y ~= cursor_y then
                child:set_position((self.padding_left or child.base_x) + parent_div_x,cursor_y + parent_div_y)
                child_updated_absolute_position = true
            elseif child.update_absolute_position then
                child:update_absolute_position(force_update)
                child_updated_absolute_position = true 
            end   

            count = count + 1
            -- if(count==1) then print('Positioned child '..count..' at '..tostring(child_x)..','..tostring(cursor_y)..' width '..tostring(child.width)..' height '..tostring(child.height)) end
            cursor_y = cursor_y + (child.height or defaults.standard_height) + self.spacing
        end
    end

    -- Update opgeslagen parent positie en size voor volgende layout-run
    self._last_parent_x = parent.base_x
    self._last_parent_y = parent.base_y
    self._last_parent_width = parent.width
    self._last_parent_height = parent.height

    parent._applying_layout = false
    return child_updated_absolute_position
end

