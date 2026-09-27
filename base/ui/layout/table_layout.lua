local defaults = require('base/ui/ui_defaults')

Table_Layout = {}
Table_Layout.__index = Table_Layout

function Table_Layout:new(opts)
    if opts==nil then opts= {} end
    local o = {
        type = 'Table_Layout',
        size = opts.size, --describing sizes. Has size.row as {} and size.column as {}. size.row[1] = height of row 1, size.column[1] = width of column 1
        base_width = opts.base_width or defaults.standard_width,
        base_height = opts.base_height or defaults.standard_height,
        align = opts.align or 'top', -- future-proofing
        spacing = opts.spacing or defaults.standard_spacing,
        auto_size = opts.auto_size or false
    }

    if opts.padding then
        if opts.padding.top then
            o.padding_top = opts.padding.top
        end

        if opts.padding.left then
            o.padding_left = opts.padding.left
        end
    end

    return setmetatable(o, self)
end

local function get_position_in_table(obj,child)
    local cur_base_x = obj.padding_left or 0
    local cur_base_y = obj.padding_top or 0
    
    if child.extra_info then
        if child.extra_info[1]>1 then
            for x=1,child.extra_info[1]-1 do
                local s = obj.base_width or defaults.standard_width
                if obj.size.column and obj.size.column[x]~=nil then s = obj.size.column[x] end
                cur_base_x = cur_base_x + s + obj.spacing
            end
        end
        if child.extra_info[2]>1 then
            for y=1,child.extra_info[2]-1 do
                local s = obj.base_height or defaults.standard_height
                if obj.size.row and obj.size.row[y]~=nil then s = obj.size.row[y] end
                cur_base_y = cur_base_y + s + obj.spacing
            end
        end
    end
    return cur_base_x,cur_base_y
end

function Table_Layout:get_child(parent,x,y)
    local cur_base_x = 0
    local cur_base_y = 0

    for _, child in ipairs(parent.children) do
        if child.extra_info then
            if child.extra_info[1]==x and child.extra_info[2]==y then
                return child
            end
        end
    end
end

function Table_Layout:apply(parent, force_update)
    if parent._applying_layout then return end
    parent._applying_layout = true

    local child_updated_absolute_position = false

    self._last_parent_x = self._last_parent_x or parent.x
    self._last_parent_y = self._last_parent_y or parent.y
    self._last_parent_width = self._last_parent_width or parent.width
    self._last_parent_height = self._last_parent_height or parent.height

    for _, child in ipairs(parent.children) do
        --extra_info will have the position in the table as {x,y}. self.size will have the sizes
        local c_x,c_y=get_position_in_table(self, child)
        --add layout_div from parent object to c_x and c_y


        c_x = c_x + (child.layout_div_x or 0)
        c_y = c_y + (child.layout_div_y or 0)
        -- if auto_size then all children height are set to the height of the layout
        if self.auto_size then
            local changed = child:set_height(parent.height)
            if changed then
                child_updated_absolute_position = true
            end
        end

        -- Alleen set_position als de x-positie wijzigt
        if child.base_x ~= c_x or child.base_y ~= c_y then
            child:set_position(c_x, c_y)
            child_updated_absolute_position = true
        elseif child.update_absolute_position then
            child:update_absolute_position(force_update)
            child_updated_absolute_position = true
        end
    end

    self._last_parent_x = parent.base_x
    self._last_parent_y = parent.base_y
    self._last_parent_width = parent.width
    self._last_parent_height = parent.height

    parent._applying_layout = false
    return child_updated_absolute_position
end