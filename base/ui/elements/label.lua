local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local text_value = setting.text or ''
    local auto_width = setting.auto_width or false
    local auto_height = setting.auto_height or false
    local font_size = setting.size or defaults.font_size

    local txt_prim = texts_prim.new(text_value, {
        x = 0, y = -1,
        text = {
            font = setting.font or defaults.font,
            size = font_size,
             red = setting.color and setting.color[1] or 255, green = setting.color and setting.color[2] or 255, blue = setting.color and setting.color[3] or 255, alpha = setting.color and setting.color[4] or 255,
        },
        bg = {
            alpha = 0,
            visible = false,
        },
        flags = {
            draggable = setting.draggable == true,
        },
        padding = 0,
    })

    local label = ui_base:new({
        type = 'label',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = setting.width or defaults.standard_width,
        height = setting.height or defaults.standard_height,
        visible = true,
        auto_width = auto_width,
        auto_height = auto_height,
        font_size = font_size,
        font = setting.font or defaults.font,
        txt_obj = txt_prim,
        children = {},
        horizontal_align = setting.horizontal_align or 'left',
        vertical_align = setting.vertical_align or 'middle',
        name = setting.name or nil,
    })

    label:add(txt_prim)

    function label:get_line_count()
        local txt = self.txt_obj:get_text() or ''
        local count = 1
        for _ in txt:gmatch('\n') do
            count = count + 1
        end
        return count
    end

    function label:set_text(value)
        if value == self.txt_obj:get_text() then return end
        self.txt_obj:set_text(value)

        if self.auto_width or self.auto_height then
            self:refresh_autosize(self)
            self:update_absolute_position(true)
        elseif self.parent and ((self.parent.layout and self.parent.layout.apply) or (self.parent.auto_height or self.parent.auto_width)) then
            self.parent:update_absolute_position(true)
        end

        -- if self.auto_width then
            -- local width = ui.get_text_width(value, self.font, self.font_size)
            -- self.width = math.floor(width)
        -- end
        -- if self.auto_height then
            -- self.height = self:get_line_count() * self.font_size
        -- end
        -- print('Set label text to '..tostring(value)..' width '..tostring(width)..' height '..tostring(self:get_line_count() * self.font_size))
        -- label.txt_obj:resize(math.floor(width), self:get_line_count() * self.font_size)
        -- label:update_absolute_position()
        -- print('Updated label text to '..tostring(value)..' width '..tostring(label.width)..' height '..tostring(label.height))
    end

    function label:get_text()
        return self.txt_obj:get_text()
    end

    function label:get_line_spacing()
        return txt_prim:get_line_spacing()
    end

    function label:on_size_change()
        --set txt_prim relative position based on alignments
        local x_offset = 0
        local y_offset = 0
        local old_y_offset = self.txt_obj.settings.y
        if self.horizontal_align == 'center' then
            x_offset = (self.width - self.txt_obj:get_text_width()) / 2
        elseif self.horizontal_align == 'right' then
            x_offset = self.width - self.txt_obj:get_text_width()
        end
        
        if self.vertical_align == 'middle' then
            y_offset = (self.height - self.txt_obj.height) / 2
        elseif self.vertical_align == 'bottom' then
            y_offset = self.height - self.txt_obj.height
        end 
        self.txt_obj:set_pos(x_offset, y_offset)
    end

    label:update_absolute_position()
    return label
end