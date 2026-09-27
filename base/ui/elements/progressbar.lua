local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local width = tonumber(setting.width) or defaults.standard_width
    local height = tonumber(setting.height) or defaults.standard_height
    local base_x = tonumber(setting.x) or 100
    local base_y = tonumber(setting.y) or 160
    local progress = tonumber(setting.val) or 0
    local fill_texture = setting.fill_image or defaults.fill_texture
    local bg_texture = setting.bg_image or defaults.bg_texture

    local bg = images_prim.new()
    bg:set_size(width, height)
    if bg_texture ~= '' then
        bg:set_path(bg_texture)
    end
    bg:set_fit(false)
    if bg_texture == '' then
        bg.always_hidden = true
    end
    -- bg:show()

    local fill = images_prim.new()
    fill:set_size(math.floor(width * progress), height)
    if fill_texture ~= '' then
         fill:set_path(fill_texture)
    end
    fill:set_fit(false)
    if fill_texture == '' then
        fill.always_hidden = true
    end
    -- fill:show()

    local bar,id = ui_base:new({
        type = 'progressbar',
        base_x = base_x,
        base_y = base_y,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = width,
        height = height,
        visible = true,
        children = {bg, fill},
        val = progress,
        margin = {left = 0, right = 0, top = 0, bottom = 0},
        name = setting.name or nil,

        on_refresh = function(self)
            local val = math.min(math.max(self.val, 0), 1)
            local w = self.width - (self.margin.left + self.margin.right)
            local h = self.height - (self.margin.top + self.margin.bottom)
            local new_width = math.floor(w * val)
            local new_x = self.margin.left
            local new_y = self.margin.top
            fill:set_pos(new_x, new_y)
            fill:set_size(new_width, h)
        end,

        set_value = function(self, new_val)
            if type(new_val) ~= 'number' or self.val == new_val then return end
            self.val = new_val
            self:on_refresh()
        end,

        set_fill_image = function(self, path)
            fill:set_path(path)
            fill:set_fit(false)
        end,

        set_bg_image = function(self, path)
            bg:set_path(path)
            bg:set_fit(false)
        end,

        set_fill_margin = function(self, left, right, top, bottom)
            self.margin.left = left or 0
            self.margin.right = right or 0
            self.margin.top = top or 0
            self.margin.bottom = bottom or 0
            self:on_refresh()
        end
    })

    bar:add(bg)
    bar:add(fill)

    bar:update_absolute_position()
    return bar,id
end