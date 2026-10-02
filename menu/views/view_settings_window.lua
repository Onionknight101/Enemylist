local defaults = require('base/ui/ui_defaults')

local view_settings_window = {}

function view_settings_window.new(settings)
    settings = settings or {}
    local width = tonumber(settings.width) or 285
    local height = tonumber(settings.height) or 174
    local gap = tonumber(settings.gap) or 8

    local region = ui.create_region({
        x = tonumber(settings.x) or 0,
        y = tonumber(settings.y) or 0,
        width = width,
        height = height,
        bg_color = settings.background_color or mathFunctions.get_color_set_alpha(defaults.bg_color, 235),
        outline_color = settings.outline_color or defaults.outline_color,
        draggable = false,
        name = settings.name or 'view_settings_window',
    })

    local title = ui.create_label({
        x = 8,
        y = 2,
        width = width - 16,
        height = 20,
        text = settings.title or 'View settings',
        size = tonumber(settings.title_size) or 10,
        color = settings.title_color or {230, 235, 245, 255},
    })
    title.txt_obj:set_bold(true)
    region:add(title)

    local result = {
        region = region,
        title = title,
        gap = gap,
        open = false,
        on_hide = settings.on_hide,
    }

    function result:add(element, extra)
        return self.region:add(element, extra)
    end

    function result:is_open()
        return self.open == true
    end

    function result:position_next_to(anchor)
        if not anchor then return end
        local x = anchor.x + anchor.width + self.gap
        local y = anchor.y
        local windower_settings = windower.get_windower_settings()
        local screen_width = tonumber(windower_settings.ui_x_res) or self.region.width
        local screen_height = tonumber(windower_settings.ui_y_res) or self.region.height
        if x + self.region.width > screen_width then
            x = anchor.x - self.region.width - self.gap
        end
        x = math.max(0, math.min(x, math.max(0, screen_width - self.region.width)))
        y = math.max(0, math.min(y, math.max(0, screen_height - self.region.height)))
        self.region:set_position(x, y)
    end

    function result:clamp_to_screen()
        local windower_settings = windower.get_windower_settings()
        local screen_width = tonumber(windower_settings.ui_x_res) or self.region.width
        local screen_height = tonumber(windower_settings.ui_y_res) or self.region.height
        local x = math.max(0, math.min(self.region.base_x or 0, math.max(0, screen_width - self.region.width)))
        local y = math.max(0, math.min(self.region.base_y or 0, math.max(0, screen_height - self.region.height)))
        self.region:set_position(x, y)
    end

    function result:show(anchor)
        if anchor then self:position_next_to(anchor) else self:clamp_to_screen() end
        self.open = true
        self.region:show()
    end

    function result:hide()
        if not self.open and self.region:is_hidden() then return end
        self.open = false
        self.region:hide()
        if self.on_hide then self.on_hide(self) end
    end

    function result:toggle(anchor)
        if self.open then self:hide() else self:show(anchor) end
    end

    local outside_release
    local outside_pass_through = false
    local original_mouse_event = region.mouse_event
    function region:mouse_event(type, mx, my, delta)
        if not self.visible then return false end
        local inside = mx >= self.x and mx <= self.x + self.width
            and my >= self.y and my <= self.y + self.height

        if not inside then
            if type == 1 or type == 4 or type == 7 then
                if type == 1 then outside_release = 2
                elseif type == 4 then outside_release = 5
                else outside_release = 8
                end
                -- Preserve the focus state from mouse-down. The initial click
                -- must reach an inactive game window, and its matching release
                -- must follow the same path after that click gives it focus.
                outside_pass_through = windower.has_focus
                    and not windower.has_focus() or false
            end
            if outside_release then
                if type == outside_release then
                    outside_release = nil
                    result:hide()
                end
                return not outside_pass_through, self.id
            end
        elseif outside_release and type == outside_release then
            outside_release = nil
            result:hide()
            return not outside_pass_through, self.id
        end

        return original_mouse_event(self, type, mx, my, delta)
    end

    region:hide()
    if settings.parent then
        if settings.parent.add_at then
            settings.parent:add_at(region, 1)
        else
            settings.parent:add(region)
        end
    end
    return result
end

return view_settings_window
