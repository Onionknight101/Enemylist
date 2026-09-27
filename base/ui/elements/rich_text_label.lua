local defaults = require('base/ui/ui_defaults')
local ui = require('base/ui/ui_base') -- verwacht ui.create_label beschikbaar
local texts_prim = require('base/ui/prim/texts_prim')

return function(setting)
    local font_default = setting.font or defaults.font
    local base_font_size = setting.size or defaults.font_size
    local max_width = setting.width or defaults.standard_width
    local max_height = setting.height or defaults.standard_height
    local auto_height = setting.auto_height or false

    local label_group = {
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        width = max_width,
        height = max_height,
        _labels = {},
        name = setting.name or nil,
    }

    local function measure_text(text, size)
        local tmp = texts_prim.new(text or '', {
            x = 0, y = 0 ,
            text = { font = font_default, size = size or base_font_size, red = 255, green = 255, blue = 255, alpha = 255 },
            bg = { alpha = 0, visible = false },
        })
        if tmp and tmp.show then tmp:show() end
        local w, h = tmp:extents()
        if tmp and tmp.hide then tmp:hide() end
        if tmp and tmp.destroy then tmp:destroy() end
        return (w or 0), (h or size or base_font_size)
    end

    local function make_label(text, color, size)
        local lbl = ui.create_label({
            x = 0, y = 0 ,
            text = text or '',
            font = font_default,
            size = size or base_font_size,
            color = color or { r = 255, g = 255, b = 255, a = 255 },
        })
        if lbl and lbl.show then lbl:show() end
        return lbl
    end

    local function clear_labels(self)
        for _, l in ipairs(self._labels) do
            if l.hide then l:hide() end
            if l.destroy then l:destroy() end
        end
        self._labels = {}
    end

    -- accepts: string or table of segments; each segment = { text=..., color={r,g,b}, size=... }
    function label_group:set_value(val)
        clear_labels(self)
        if not val then return end

        local segments = {}
        if type(val) == 'string' then
            table.insert(segments, { text = val })
        elseif type(val) == 'table' then
            if #val > 0 then
                for _, s in ipairs(val) do table.insert(segments, s) end
            else
                table.insert(segments, val)
            end
        else
            table.insert(segments, { text = tostring(val) })
        end

        local cursor_x, cursor_y = 0, 0
        local current_line_h = 0

        for _, seg in ipairs(segments) do
            local txt = tostring(seg.text or '')
            local col = seg.color or seg.col or { r = 255, g = 255, b = 255, a = 255 }
            local sz = seg.size or base_font_size

            -- split on newlines
            for line in (txt .. '\n'):gmatch("(.-)\n") do
                if line == '' then
                    -- explicit empty line -> advance by current line height or measured default
                    local lh = current_line_h
                    if lh == 0 then _, lh = measure_text('M', sz) end
                    cursor_x = 0
                    cursor_y = cursor_y + lh
                    current_line_h = 0
                else
                    local w, h = measure_text(line, sz)
                    -- wrap if would overflow
                    if cursor_x > 0 and (cursor_x + w) > self.width then
                        cursor_x = 0
                        cursor_y = cursor_y + current_line_h
                        current_line_h = 0
                    end

                    local lbl = make_label(line, col, sz)
                    -- set position; ui labels expect pos table on creation - try update if available
                    lbl:set_position({ x = self.base_x + cursor_x, y = self.base_y + cursor_y })
                    
                    table.insert(self._labels, lbl)

                    cursor_x = cursor_x + w
                    if h > current_line_h then current_line_h = h end
                end
            end
        end

        local total_h = cursor_y + (current_line_h > 0 and current_line_h or base_font_size)
        if auto_height then
            self.height = math.ceil(total_h)
        end
    end

    function label_group:on_refresh()
        local v = setting.text
        if type(v) == 'function' then v = v() end
        self:set_value(v)
    end

    -- initial render
    label_group:on_refresh()

    return label_group
end