Window = {}
Window.__index = Window

local defaults = require('base/ui/ui_defaults')

function Window.new(opts)
    local self = setmetatable({}, Window)
    self.title = opts.title or "Window"
    local x = opts.x or 100
    local y = opts.y or 100
    local w = opts.w or 300
    local h = opts.h or 200
    local dyna_title = opts.dyna_title
    self.state = "normal"
    self.visible = true

    local titlebar_height = defaults.standard_height
    local content_height = h - titlebar_height

    local bg_color = defaults.bg_color
    bg_color[4] = 0
    -- Main region
    self.region = ui.create_region({
        x = x, y = y,
        width = w,
        height = h,
        draggable = opts.draggable,
        bg_color = bg_color,
        layout = nil,
        auto_height = opts.auto_height or false,
    })
    ui.elements:add_to_root(self.region)
    

    -- Titlebar region
    self.titlebar = ui.create_region({
        x = 0, y = 0,
        width = w,
        height = titlebar_height+((defaults.padding.top+defaults.padding.bottom)*2),
        draggable = opts.draggable,
        bg_color = defaults.pressed_color,
        layout = nil,
    })

    -- Title label (links)
    self.title_label = ui.create_dynamic_label{
        text = self.title,
        x = 8, y = 0,
        fnc_change = function(new_text) 
            if dyna_title and type(dyna_title) == 'function' then
                new_text = dyna_title()
            else
                new_text = self.title
            end
            return new_text
        end,
    }
    self.titlebar:add(self.title_label)

    -- Knoppen (rechts, handmatig gepositioneerd)
    local btn_y = 4
    local btn_w = 20
    local btn_h = 16
    self.btn_min = ui.create_button{
        label = "--",
        x = w - 48, y = btn_y,
        width = btn_w,
        height = btn_h,
        on_click = function() self:minimize() end,
    }
    self.btn_close = ui.create_button{
        label = "X",
        x = w - 24, y = btn_y,
        width = btn_w,
        height = btn_h,
        on_click = function() self:close() end,
    }
    self.titlebar:add(self.btn_min)
    self.titlebar:add(self.btn_close)

    self.region:add(self.titlebar)

    -- Content region (onder de titlebar), met standaard padding
    self.content = ui.create_region({
        title = "content",
        x = 0, y = self.titlebar:get_relative_bottom()-((defaults.padding.top+defaults.padding.bottom)),
        width = w ,
        height = content_height - self.titlebar:get_relative_bottom(),
        layout = nil,
        bg_color = {0, 0, 0, 64},
        draggable = opts.draggable,
        auto_height = opts.auto_height or false,
    })
    self.region:add(self.content)

    -- Zorg dat knoppen en regio's goed blijven staan bij resize
    function self:update_layout()
        self.region:set_width(self.region.width)
        self.titlebar:set_width(self.region.width)
        self.btn_min:set_position(self.region.width - 48, btn_y)
        self.btn_close:set_position(self.region.width - 24, btn_y)
        local content_h = self.region.height - titlebar_height
        self.content:set_width(self.region.width)
        self.content:set_height(content_h)
        -- self.content:set_position(defaults.padding.left, titlebar_height)
    end

    -- Call bij init
    self:update_layout()

    
    ui.set_composed(self, self.region)
    return self
end

function Window:minimize()
    if self.state == "minimized" then
        self.state = "normal"
        self.btn_min:set_text("-")
        self.content:show()
        self.region:set_height(defaults.standard_height)
    else
        self.state = "minimized"
        self.btn_min:set_text("^")
        self.content:hide()
        self.region:set_height(24)
    end
    self:update_layout()
end

function Window:clear()
    self.content:clear()
end

function Window:get_x()
    return self.region.x
end

function Window:get_y()
    return self.region.y
end

function Window:get_width()
    return self.region.width
end

function Window:get_height()
    return self.region.height
end

function Window:get_position()
    return self.region.x, self.region.y
end

function Window:set_title(title)
    self.title = title
    self.title_label:set_text(title)
end

function Window:close()
    self.region:hide()
end

function Window:add(element)
    self.content:add(element)
end

function Window:update_absolute_position(force_update)
    self.region:update_absolute_position(force_update)
end

function Window:update_draw()
    self.region:update_draw()
end

function Window:show()
    self.region:show()
end

function Window:hide()
    self.region:hide()
end