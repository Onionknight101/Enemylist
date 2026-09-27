local defaults = require('base/ui/ui_defaults')

Horizontal_Layout = {}
Horizontal_Layout.__index = Horizontal_Layout

function Horizontal_Layout:new(opts)
    if opts==nil then opts= {} end
    local o = {
        type = 'Horizontal_Layout',
        spacing = opts.spacing or defaults.standard_spacing,
        padding = opts.padding or defaults.padding.left,
        padding_top = opts.padding_top,
        align = opts.align or 'top', -- future-proofing
        auto_size = opts.auto_size or false
    }
    return setmetatable(o, self)
end

function Horizontal_Layout:apply(parent, force_update)
    if parent._applying_layout then return end
    parent._applying_layout = true

    local child_updated_absolute_position = false

    self._last_parent_x = self._last_parent_x or parent.x
    self._last_parent_y = self._last_parent_y or parent.y
    self._last_parent_width = self._last_parent_width or parent.width
    self._last_parent_height = self._last_parent_height or parent.height

    local cursor_x = self.padding + (parent.offset_x or 0) -- offset_x toegevoegd

    local has_offset = false

    for _, child in ipairs(parent.children) do

        -- if auto_size then all children height are set to the height of the layout
        if self.auto_size then
            local changed = child:set_height(parent.height)
            if changed then
                child_updated_absolute_position = true
            end
        end

        
        local child_div_x = cursor_x + (child.layout_div_x or 0)
        local child_div_y =  (child.layout_div_y or 0)

        -- Alleen set_position als de x-positie wijzigt
        if child.base_x ~= child_div_x then
            child:set_position(child_div_x, (self.padding_top or child.base_y) + child_div_y)
            child_updated_absolute_position = true
        elseif child.update_absolute_position then
            child:update_absolute_position(force_update)
            child_updated_absolute_position = true
        end
        
        cursor_x = cursor_x + (child.width or defaults.standard_width) + self.spacing
    end

    self._last_parent_x = parent.base_x
    self._last_parent_y = parent.base_y
    self._last_parent_width = parent.width
    self._last_parent_height = parent.height

    parent._applying_layout = false
    return child_updated_absolute_position
end