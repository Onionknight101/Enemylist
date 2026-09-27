local defaults = require('base/ui/ui_defaults')

texts_prim = texts_prim or {}
local texts_meta = {}
local texts_store = {} --object ref storage

local function generate_id()
    return 'text_' .. tostring(os.clock()):gsub('%.', '') .. '_' .. tostring(math.random(10000, 99999))
end

local default_settings = {
    x = 0, y = 0,
    text = {
        value = '',
        font = 'Arial',
        size = 12,
        color = {255,255,255,255},
    },
    visible = true,
}

math.randomseed(os.clock())

local function deepcopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local t = {}
    for k,v in pairs(tbl) do
        if type(v) == 'table' then
            t[k] = deepcopy(v)
        else
            t[k] = v
        end
    end
    return t
end

local function load_font_metrics(font)
    local ok, metrics = pcall(require, 'base/ui/font_metrics/fonts/' .. tostring(font or 'Arial'))
    if ok and metrics then return metrics end

    ok, metrics = pcall(require, 'base/ui/font_metrics/fonts/Arial')
    return ok and metrics or nil
end

local function apply_settings(obj)
    if not obj or not obj.id or not obj.settings then return end
    local s = obj.settings
    local id = obj.id

    if not windower.text then return end

    windower.text.set_location(id, s.x or 0, s.y or 0)
    if s.bg then
        windower.text.set_bg_color(id, s.bg.alpha or 0, s.bg.red or 0, s.bg.green or 0, s.bg.blue or 0)
        windower.text.set_bg_visibility(id, s.bg.visible ~= false)
    end
    if s.text then
        windower.text.set_color(id, s.text.alpha or 255, s.text.red or 255, s.text.green or 255, s.text.blue or 255)
        windower.text.set_font(id, s.text.font or 'Arial', unpack(s.text.fonts or {}))
        windower.text.set_font_size(id, s.text.size or 12)
        windower.text.set_stroke_width(id, s.text.stroke and s.text.stroke.width or 0)
        if s.text.stroke then
            windower.text.set_stroke_color(id,
                s.text.stroke.alpha or 255,
                s.text.stroke.red or 0,
                s.text.stroke.green or 0,
                s.text.stroke.blue or 0)
        end
    end
    windower.text.set_bg_border_size(id, s.padding or 0)
    if s.flags then
        windower.text.set_italic(id, s.flags.italic or false)
        windower.text.set_bold(id, s.flags.bold or false)
        windower.text.set_right_justified(id, s.flags.right or false)
        -- windower.text.set_bottom_justified(id, s.flags.bottom or false)
    end
    windower.text.set_visibility(id, obj.visible ~= false)
end

local get_line_count = function(txt)
    txt = txt or ''
    local count = 1
    for _ in txt:gmatch('\n') do
        count = count + 1
    end
    return count
end

local function get_line_count(txt)
    txt = txt or ''
    local count = 1
    for _ in txt:gmatch('\n') do
        count = count + 1
    end
    return count
end

-- Cache text width op basis van text/font/size
local function update_text_extents(self)
    local old_width = self.width
    local old_height = self.height

    local font = self.settings.text.font or 'Arial'
    local size = self.settings.text.size or 12
    local value = self.settings.text.value or ''

    local max_width = 0
    local found = false
    for line in tostring(value):gmatch("([^\n]*)\n?") do
        -- Stop als het de allerlaatste lege regel is na een trailing \n
        if not (line == "" and found and value:sub(-1) == "\n") then
            local w
            if self.font_metrics then
                w = FONT_METRICS.text_width(self.font_metrics,line, size)
            else
                w = #line * size -- fallback
            end
            if w > max_width then
                max_width = w
            end
        end


        found = true
    end
    self.text_width = max_width
    self.width = max_width
    local line_count = get_line_count(value)
    if self.font_metrics then
        self.text_height = (self.font_metrics.top_offset or 0)
            + line_count * size
            + (line_count - 1) * FONT_METRICS.get_line_spacing(self.font_metrics, size)
    else
        self.text_height = line_count * size
    end
    self.height = self.text_height
    
    return old_width ~= self.width or old_height ~= self.height
end

function texts_prim.new(str, settings)
    local obj = {}
    local id = generate_id()
    obj.id = id
    obj.settings = deepcopy(default_settings)
    obj.x = 0
    obj.y = 0
    obj.width = defaults.standard_width
    obj.height = defaults.standard_height
    if settings then
        for k,v in pairs(settings) do
            if type(v) == 'table' and type(obj.settings[k]) == 'table' then
                for sk,sv in pairs(v) do
                    obj.settings[k][sk] = sv
                end
            else
                obj.settings[k] = v
            end
        end
    end
    obj.visible = obj.settings.visible
    texts_store[id] = obj

    obj = setmetatable(obj, texts_meta)


    obj.font_metrics = load_font_metrics(obj.settings.text.font)

    windower.text.create(obj.id)
    apply_settings(obj)

    obj:set_text(str or '')

    ui.elements:add_ref(id, obj)
    return obj,id
end

function texts_prim.get(id)
    return texts_store[id]
end

function texts_prim.destroy(obj)
    if not obj or not obj.id then return end
    -- Als je een echte Windower text primitive hebt:
    windower.text.delete(obj.id)
    -- Verwijder de objecten uit de UI
    texts_store[obj.id] = nil
    -- settings en metatable opruimen
    if obj.settings then
        for k in pairs(obj.settings) do obj.settings[k] = nil end
    end
    obj.visible = false
    -- setmetatable(obj, nil)
    obj.id = nil
end

texts_meta.__index = {
    set_text = function(self, str)
        if str==nil then str='' end
        if self.settings.text.value == str then return end
        
        self.settings.text.value = str
        if windower.text and self.id then
            windower.text.set_text(self.id, str)
        end
        self:update_extents()
    end,
    get_text = function(self)
        return self.settings.text.value
    end,
    set_pos = function(self, x, y)
        if self.settings.x == x and self.settings.y == y then return end

        self.settings.x = x
        self.settings.y = y
        self:update_pos()
    end,
    set_position = function(self, x, y)
        if self.settings.x == x and self.settings.y == y then return end

        self.settings.x = x
        self.settings.y = y
        self:update_pos()
    end,
    update_pos = function(self)
        if self.id then
            local x,y = self:get_pos_raw()
            windower.text.set_location(self.id, x, y)
        end
    end,
    get_pos = function(self)
        return self.settings.x, self.settings.y
    end,
    get_pos_raw = function(self)
        if(self.parent_id) then
            local parent = ui.elements.reference[self.parent_id]
            local parent_x, parent_y = parent:get_absolute_position()
            return self.settings.x + parent_x - parent.scroll_x, self.settings.y + parent_y - parent.scroll_y
        else
            -- Als er geen parent is, gebruik de eigen positie
            return self.settings.x, self.settings.y
        end
    end,
    set_font = function(self, font, ...)
        self.settings.text.font = font
        self.settings.text.fonts = {...}
        self.font_metrics = load_font_metrics(font)
        if windower.text and self.id then
            windower.text.set_font(self.id, font, ...)
        end
        self:update_extents()
    end,
    get_font = function(self)
        return self.settings.text.font
    end,
    set_size = function(self, size)
        if self.settings.text.size == size then return end

        self.settings.text.size = size
        if windower.text and self.id then
            windower.text.set_font_size(self.id, size)
        end
        self:update_extents()
    end,
    set_color = function(self, r, g, b, a)
        if self.settings.text.red == r and
           self.settings.text.green == g and
           self.settings.text.blue == b and
           self.settings.text.alpha == a then
            return
        end

        self.settings.text.red = r
        self.settings.text.green = g
        self.settings.text.blue = b
        self.settings.text.alpha = a or 255
        if windower.text and self.id then
            windower.text.set_color(self.id,
                self.settings.text.alpha or 255,
                self.settings.text.red or 255,
                self.settings.text.green or 255,
                self.settings.text.blue or 255)
        end
    end,
    set_alpha = function(self, a)
        if self.settings.text.alpha == a then return end

        self.settings.text.alpha = a
        if windower.text and self.id then
            windower.text.set_color(self.id,
                self.settings.text.alpha or 255,
                self.settings.text.red or 255,
                self.settings.text.green or 255,
                self.settings.text.blue or 255)
        end
    end,
    set_padding = function(self, pad)
        if self.settings.padding == pad then return end

        self.settings.padding = pad
        if windower.text and self.id then
            windower.text.set_bg_border_size(self.id, pad)
        end
    end,
    set_bold = function(self, bold)
        if self.settings.flags and self.settings.flags.bold == bold then return end

        self.settings.flags = self.settings.flags or {}
        self.settings.flags.bold = bold
        if windower.text and self.id then
            windower.text.set_bold(self.id, bold)
        end
    end,
    set_italic = function(self, italic)
        if self.settings.flags and self.settings.flags.italic == italic then return end

        self.settings.flags = self.settings.flags or {}
        self.settings.flags.italic = italic
        if windower.text and self.id then
            windower.text.set_italic(self.id, italic)
        end
    end,
    set_right_justified = function(self, right)
        if self.settings.flags and self.settings.flags.right == right then return end

        self.settings.flags = self.settings.flags or {}
        self.settings.flags.right = right
        if windower.text and self.id then
            windower.text.set_right_justified(self.id, right)
        end
    end,
    extents = function(self)
        return windower.text.get_extents(self.id)
    end,

    -- set_bottom_justified = function(self, bottom)
    --     self.settings.flags = self.settings.flags or {}
    --     self.settings.flags.bottom = bottom
    --     if windower.text and self.id then
    --         windower.text.set_bottom_justified(self.id, bottom)
    --     end
    -- end,
    set_stroke = function(self, width, r, g, b, a)
        if self.settings.text.stroke and
           self.settings.text.stroke.width == width and
           self.settings.text.stroke.red == r and
           self.settings.text.stroke.green == g and
           self.settings.text.stroke.blue == b and
           self.settings.text.stroke.alpha == a then
            return
        end

        self.settings.text.stroke = self.settings.text.stroke or {}
        self.settings.text.stroke.width = width
        self.settings.text.stroke.red = r
        self.settings.text.stroke.green = g
        self.settings.text.stroke.blue = b
        self.settings.text.stroke.alpha = a or 255
        if windower.text and self.id then
            windower.text.set_stroke_width(self.id, width)
            windower.text.set_stroke_color(self.id, a or 255, r, g, b)
        end
    end,
    set_bg = function(self, r, g, b, a, visible)
        if self.settings.bg and
           self.settings.bg.red == r and
           self.settings.bg.green == g and
           self.settings.bg.blue == b and
           self.settings.bg.alpha == a and
           self.settings.bg.visible == visible then
            return
        end

        self.settings.bg = self.settings.bg or {}
        self.settings.bg.red = r
        self.settings.bg.green = g
        self.settings.bg.blue = b
        self.settings.bg.alpha = a or 0
        self.settings.bg.visible = visible
        if windower.text and self.id then
            windower.text.set_bg_color(self.id, a or 0, r, g, b)
            windower.text.set_bg_visibility(self.id, visible)
        end
    end,
    -- show = function(self)
    --     if self.visible == true then return end

    --     self.visible = true
    --     if windower.text and self.id then
    --         windower.text.set_visibility(self.id, true)
    --     end
    -- end,
    -- hide = function(self)
    --     if self.visible == false then return end

    --     self.visible = false
    --     if windower.text and self.id then
    --         windower.text.set_visibility(self.id, false)
    --     end
    -- end,
    

    update_draw_visibility = function(self, state)
        if state == self.last_draw_visibility then return end
        self.last_draw_visibility = state
        if state == true then
            windower.text.set_visibility(self.id, true)
        else
            windower.text.set_visibility(self.id, false)
        end
    end,

    is_visible = function(self)
        return self.visible
    end,
    get_baseline = function(self)
        local baseline = 0
        if not self.font_metrics then
            return baseline
        end
        return FONT_METRICS.get_baseline(self.font_metrics,self.font_size)
    end,
    set_parent = function(self, parent)
        if not parent or not parent.id then return end
        if self.parent_id == parent.id then return end

        self.parent_id = parent.id
        if windower.text and self.id then
            self:update_pos()
        end
    end,
    destroy = function(self)
        texts_prim.destroy(self)
    end,
    update_extents = function(self)
        if(update_text_extents(self)==true and self.parent_id) then
            local parent = ui.elements.reference[self.parent_id]
            if parent and parent.locked~=nil and (parent.locked==false) then
                parent:update_absolute_position(true)
            end
        end
    end,
    get_text_width = function(self)
        if self.text_width == nil then
            self:update_extents()
        end
        return self.text_width
    end,
    get_line_spacing = function(self)
        if not self.font_metrics then
            return 0
        end
        return FONT_METRICS.get_line_spacing(self.font_metrics, self.settings.text.size or 12)
    end,
}
