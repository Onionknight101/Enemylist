local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local label_text = setting.text or ''
    local fnc = setting.fnc_change
    local arg1 = setting.fnc_arg1
    local arg2 = setting.fnc_arg2
    local font_size = setting.size or defaults.font_size
    local auto_width = setting.auto_width or false
    local auto_height = setting.auto_height or false




    local txt_prim = texts_prim.new('',{
        x = 0,
        y = 0,
        text = {
            font = setting.font or 'Consolas',
            size = font_size,
            red = setting.color and setting.color[1] or 255, green = setting.color and setting.color[2] or 255, blue = setting.color and setting.color[3] or 255, alpha = setting.color and setting.color[4] or 255,
            -- stroke = {width = 1, alpha = 255, red = 0, green = 0, blue = 0}
        },
        -- flags = {draggable = setting.draggable ~= false},
        -- bg = {red = 0, green = 0, blue = 0, alpha = 0, visible = false},
        padding = 0
    })

    local dyn_label,id = ui_base:new({
        type = 'dynamic_label',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = setting.width or defaults.standard_width,
        height = setting.height or defaults.standard_height,
        txt_obj = txt_prim,
        visible = true,
        auto_width = auto_width,
        auto_height = auto_height,
        font_size = font_size,
        children = {},
        name = setting.name or nil,
    })
    dyn_label:add(txt_prim)

    function dyn_label:get_line_count()
        local txt_val = self.txt_obj:get_text() or ''
        local count = 1
        for _ in txt_val:gmatch('\n') do count = count + 1 end
        return count
    end

    function dyn_label:on_refresh()
        local value = ''
        if fnc then value = tostring(fnc(arg1, arg2)) end
        local full_text = (label_text ~= '') and (label_text .. ': ' .. value) or value
    
        self.txt_obj:set_text(full_text)
    -- print('Dynamic label set text:', self.txt_obj.width)
        -- if self.auto_width then
        --     local width = ui.get_text_width(full_text, setting.font or 'Consolas', font_size)
        --     self.width = math.floor(width)
        -- end
        -- if self.auto_height then
        --     self.height = self:get_line_count() * self.font_size
        -- end
    end

    function dyn_label:get_text()
        return self.txt_obj:get_text()
    end

    function dyn_label:get_line_spacing()
        return txt_prim:get_line_spacing()
    end

    dyn_label:add(txt_prim)
    dyn_label:on_refresh()
    return dyn_label
end