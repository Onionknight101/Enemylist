local defaults = require('base/ui/ui_defaults')

Row_Layout = {}
Row_Layout.__index = Row_Layout

function Row_Layout:new(opts)
    opts = opts or {}
    local o = {
        spacing = opts.spacing or defaults.standard_spacing,
        padding = opts.padding or defaults.padding.top,
        row_spacing = opts.row_spacing or defaults.standard_spacing,
        align = opts.align or 'left',
        offset_x = opts.offset_x or 0,
        offset_y = opts.offset_y or 0,
    }
    return setmetatable(o, self)
end

function Row_Layout:apply(parent, force_update)
    if parent._applying_layout then return end
    parent._applying_layout = true

    local cursor_y = self.padding + (self.offset_y or 0)
    for _, row in ipairs(parent.children) do
        if row.visible ~= false then
            local cursor_x = self.padding + (self.offset_x or 0)
            -- Horizontale layout voor deze row
            for _, cell in ipairs(row.children or {}) do
                if cell.visible ~= false then
                    cell:set_position(cursor_x, 0)
                    cursor_x = cursor_x + (cell.width or defaults.standard_width) + self.spacing
                end
            end
            -- Zet de row zelf op de juiste verticale positie
            row:set_position(0, cursor_y)
            cursor_y = cursor_y + (row.height or defaults.standard_height) + self.row_spacing
        end
    end

    parent._applying_layout = false
end

return Row_Layout