local ui_base = require('base/ui/ui_base')
local fonts = require('base/ui/prim/bitmap_font')

local function round_pixel(value)
    value = tonumber(value) or 0
    if value < 0 then return math.ceil(value - 0.5) end
    return math.floor(value + 0.5)
end

-- ImageLabel renders text with image primitives so it shares the same draw layer
-- as icons and bars. A primitive is permanently bound to one glyph texture. It
-- is pooled and reused, but its texture path is never changed.
return function(setting)
    setting = setting or {}

    local font_name = fonts[setting.font] and setting.font or 'base'
    local font = fonts[font_name]
    local font_size = math.max(1, round_pixel(setting.size or font.basePixelSize or 16))
    local fixed_width = tonumber(setting.width)
    local fixed_height = tonumber(setting.height)
    local align = setting.horizontal_align or setting.align or 'left'
    local wrap = setting.wrap == true
    local load_delay = math.max(0, tonumber(setting.load_delay) or 0.05)
    local color = setting.color or {255, 255, 255, 255}

    local pools = {}
    local active = {}
    local layout_running = false

    local label = ui_base:new({
        type = 'imagelabel',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = fixed_width or 1,
        height = fixed_height or font_size,
        visible = true,
        name = setting.name,
    })

    label._text = tostring(setting.text or '')
    label._font_name = font_name
    label._font = font
    label._font_size = font_size
    label._color = color
    label._align = align
    label._wrap = wrap
    label._fixed_width = fixed_width
    label._fixed_height = fixed_height

    local function set_primitive_visible(primitive, visible)
        primitive.always_hidden = not visible
        primitive:update_draw_visibility(visible)
    end

    local function glyph_metrics(current_font, byte)
        return current_font.letter[byte]
            or current_font.letter[63]
            or {size = current_font.basePixelSize or 16, left = 0, kerning = {}}
    end

    local function glyph_path(current_font, byte)
        if current_font.texture_map and current_font.texture_map[byte] then
            return current_font.texture_map[byte]
        end
        return current_font.folder .. '/' .. tostring(byte) .. '.png'
    end

    local function update_slot_visibility(slot)
        local visible = slot.in_use and slot.ready and label:is_drawn()
        set_primitive_visible(slot.primitive, visible)
    end

    local function create_slot(byte)
        local primitive = images_prim.new({x = 0, y = 0, width = 1, height = 1})
        set_primitive_visible(primitive, false)
        primitive:set_fit(false)
        primitive:set_path(glyph_path(label._font, byte))
        label:add_internal(primitive)

        local slot = {
            primitive = primitive,
            byte = byte,
            font_name = label._font_name,
            in_use = false,
            ready = false,
            generation = 0,
            color = nil,
        }

        local function mark_ready()
            if label._destroyed then return end
            slot.ready = true
            update_slot_visibility(slot)
        end
        if coroutine and coroutine.schedule and load_delay > 0 then
            coroutine.schedule(mark_ready, load_delay)
        else
            mark_ready()
        end
        return slot
    end

    local function acquire_slot(byte)
        pools[label._font_name] = pools[label._font_name] or {}
        local font_pool = pools[label._font_name]
        font_pool[byte] = font_pool[byte] or {}
        local glyph_pool = font_pool[byte]

        for _, slot in ipairs(glyph_pool) do
            if not slot.in_use then
                slot.in_use = true
                slot.generation = slot.generation + 1
                return slot
            end
        end

        local slot = create_slot(byte)
        slot.in_use = true
        slot.generation = slot.generation + 1
        table.insert(glyph_pool, slot)
        return slot
    end

    local function release_slot(slot)
        if not slot or not slot.in_use then return end
        slot.in_use = false
        slot.generation = slot.generation + 1
        set_primitive_visible(slot.primitive, false)
    end

    local function scale()
        return label._font_size / (label._font.basePixelSize or label._font_size)
    end

    local function advance_for(text, index, current_scale)
        local byte = text:byte(index)
        local metrics = glyph_metrics(label._font, byte)
        local advance = tonumber(metrics.size) or label._font.basePixelSize or label._font_size
        advance = advance - (tonumber(metrics.left) or 0)
        local next_byte = text:byte(index + 1)
        if next_byte and metrics.kerning then
            advance = advance - (tonumber(metrics.kerning[next_byte]) or 0)
        end
        return advance * current_scale + (tonumber(label._font.between) or 0)
    end

    local function measure_line(text)
        local current_scale = scale()
        local width = 0
        for index = 1, #text do
            width = width + advance_for(text, index, current_scale)
        end
        return math.max(0, width)
    end

    local function split_lines(text)
        local physical = {}
        local start = 1
        while true do
            local position = text:find('\n', start, true)
            if not position then
                table.insert(physical, text:sub(start))
                break
            end
            table.insert(physical, text:sub(start, position - 1))
            start = position + 1
        end

        if not label._wrap or not label._fixed_width then return physical end

        local result = {}
        for _, line in ipairs(physical) do
            if line == '' then
                table.insert(result, '')
            else
                local current = ''
                for index = 1, #line do
                    local candidate = current .. line:sub(index, index)
                    if current ~= '' and measure_line(candidate) > label._fixed_width then
                        table.insert(result, current)
                        current = line:sub(index, index)
                    else
                        current = candidate
                    end
                end
                table.insert(result, current)
            end
        end
        return result
    end

    local function apply_slot_color(slot)
        local previous = slot.color
        if previous and previous[1] == label._color[1] and previous[2] == label._color[2]
            and previous[3] == label._color[3] and previous[4] == label._color[4] then
            return
        end
        slot.primitive:set_color(
            label._color[1], label._color[2], label._color[3], label._color[4]
        )
        slot.color = {label._color[1], label._color[2], label._color[3], label._color[4]}
    end

    function label:layout_text()
        if layout_running then return end
        layout_running = true
        local previous_active = active
        local next_active = {}
        local glyph_index = 0

        local lines = split_lines(self._text)
        local current_scale = scale()
        local line_height = self._font_size
            + round_pixel((tonumber(self._font.verticalSpacing) or 0) * current_scale)
        local widest = 0

        for line_index, line in ipairs(lines) do
            local line_width = measure_line(line)
            widest = math.max(widest, line_width)
            local available_width = self._fixed_width or line_width
            local cursor_x = 0
            if self._align == 'center' then
                cursor_x = math.max(0, (available_width - line_width) / 2)
            elseif self._align == 'right' then
                cursor_x = math.max(0, available_width - line_width)
            end

            for index = 1, #line do
                local byte = line:byte(index)
                local metrics = glyph_metrics(self._font, byte)
                if byte ~= 32 and byte ~= 9 then
                    if not self._font.letter[byte] then byte = 63 end
                    glyph_index = glyph_index + 1
                    local slot = previous_active[glyph_index]
                    if not slot or slot.font_name ~= self._font_name or slot.byte ~= byte then
                        release_slot(slot)
                        slot = acquire_slot(byte)
                    end
                    -- Always snap from the unrounded layout position. Flooring every
                    -- glyph independently makes narrow letters lose up to a full pixel,
                    -- which visibly distorts bitmap fonts at smaller sizes.
                    local glyph_width = math.max(1, round_pixel((metrics.size or self._font_size) * current_scale))
                    local glyph_x = round_pixel(cursor_x)
                    local glyph_y = round_pixel((line_index - 1) * line_height)

                    slot.primitive:set_pos(glyph_x, glyph_y)
                    slot.primitive:set_size(glyph_width, self._font_size)
                    apply_slot_color(slot)
                    next_active[glyph_index] = slot
                    update_slot_visibility(slot)
                end
                cursor_x = cursor_x + advance_for(line, index, current_scale)
            end
        end

        for index = glyph_index + 1, #previous_active do
            release_slot(previous_active[index])
        end
        active = next_active

        local new_width = self._fixed_width or math.max(1, math.ceil(widest))
        local new_height = self._fixed_height or math.max(1, #lines * line_height)
        local changed = self.width ~= new_width or self.height ~= new_height
        self.width = new_width
        self.height = new_height
        layout_running = false

        if changed and self.parent_id then
            local parent = ui.elements.reference[self.parent_id]
            if parent and (parent.auto_width or parent.auto_height) and not parent.locked then
                parent:update_absolute_position(true)
            end
        end
    end

    function label:set_text(value)
        value = tostring(value or '')
        if self._text == value then return false end
        self._text = value
        self:layout_text()
        return true
    end

    function label:get_text()
        return self._text
    end

    function label:set_font(value)
        if not fonts[value] or value == self._font_name then return false end
        self._font_name = value
        self._font = fonts[value]
        self:layout_text()
        return true
    end

    function label:set_font_size(value)
        value = tonumber(value)
        if not value or value <= 0 then return false end
        value = math.max(1, round_pixel(value))
        if value == self._font_size then return false end
        self._font_size = value
        self:layout_text()
        return true
    end

    function label:set_color(r, g, b, a)
        self._color = type(r) == 'table' and r or {r or 255, g or 255, b or 255, a or 255}
        for _, slot in ipairs(active) do apply_slot_color(slot) end
    end

    function label:set_alignment(value)
        if value ~= 'left' and value ~= 'center' and value ~= 'right' then return false end
        if self._align == value then return false end
        self._align = value
        self:layout_text()
        return true
    end

    function label:set_wrap(value)
        value = value == true
        if self._wrap == value then return false end
        self._wrap = value
        self:layout_text()
        return true
    end

    function label:measure_text(value)
        return measure_line(tostring(value or self._text or ''))
    end

    function label:on_size_change()
        if not layout_running then
            self._fixed_width = self.width
            self._fixed_height = self.height
            self:layout_text()
        end
    end

    function label:on_update_draw_visibility()
        for _, slot in ipairs(active) do update_slot_visibility(slot) end
    end

    function label:on_destroy()
        self._destroyed = true
        active = {}
        pools = {}
    end

    label:update_absolute_position()
    label:layout_text()
    return label
end
