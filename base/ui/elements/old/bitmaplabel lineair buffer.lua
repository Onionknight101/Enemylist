local ui_base = require('base/ui/ui_base')
local fonts = require('base/ui/prim/bitmap_font')

-- gedeelde in-memory texture cache
local texture_cache = ui_base.bitmap_cache or rawget(_G, 'bitmap_texture_cache')
if not texture_cache then
    texture_cache = {}
    rawset(_G, 'bitmap_texture_cache', texture_cache)
    if ui_base then ui_base.bitmap_cache = texture_cache end
end

return function(setting)
    setting = setting or {}
    local font_name = setting.font or 'base'
    local font = fonts[font_name] or fonts['base']
    local size = setting.size or (font and font.basePixelSize) or 16
    local color = setting.color or {255,255,255,255}
    local x = setting.x or 0
    local y = setting.y or 0
    local wrap = setting.wrap or false
    local max_width = setting.width or nil
    local align = setting.align or 'left'

    local segs = {}

    -- images_prim wordt extern geleverd; haal via ui_base of globale scope
    local images_prim = ui_base.images_prim or rawget(_G, 'images_prim')

    local function create_prim(params)
        params = params or { x = 0, y = 0, width = 1, height = 1 }
        if images_prim and images_prim.new then
            local ok, prim = pcall(images_prim.new, params)
            if ok and prim then
                pcall(function()
                    if params.width and params.height and prim.set_size then prim:set_size(params.width, params.height) end
                    if params.x and params.y and prim.set_pos then prim:set_pos(params.x, params.y) end
                    if prim.set_origin then pcall(prim.set_origin, prim, 0, 0) end
                    if prim.set_anchor then pcall(prim.set_anchor, prim, 0, 0) end
                    if prim.set_pivot then pcall(prim.set_pivot, prim, 0, 0) end
                end)
                return prim
            end
        end
        -- fallback stub
        return {
            set_pos = function() end,
            set_size = function() end,
            set_color = function() end,
            set_path = function() end,
            set_texture = function() end,
            set_bitmap = function() end,
            show = function() end,
            hide = function() end,
            destroy = function() end,
            set_parent = function() end,
            set_origin = function() end,
            set_anchor = function() end,
            set_pivot = function() end,
        }
    end

    local function ensure_seg(i)
        if segs[i] then return segs[i] end
        local p = create_prim({ x = 0, y = 0, width = 1, height = 1 })
        -- bookkeeping and pending-op fields
        if type(p) == 'table' then
            p._last_path = nil
            p._last_x = nil
            p._last_y = nil
            p._last_w = nil
            p._last_h = nil
            p._last_color = nil
            p._pending_path = nil
            p._pending_show = nil
            p._pending_clear = nil
        end
        pcall(function()
            if p and p.set_parent and label_obj then
                if label_obj.id then
                    local ok = pcall(p.set_parent, p, label_obj.id)
                    if not ok then pcall(p.set_parent, p, { id = label_obj.id }) end
                else
                    local lid = (label_obj.get_id and label_obj:get_id()) or nil
                    if lid then
                        local ok = pcall(p.set_parent, p, lid)
                        if not ok then pcall(p.set_parent, p, { id = lid }) end
                    end
                end
            end
        end)
        segs[i] = p
        return p
    end

    local function clear_extra_segs(n)
        for i = n + 1, #segs do
            local s = segs[i]
            if s then
                if s.destroy then pcall(s.destroy, s) end
                if s.hide then pcall(s.hide, s) end
            end
            segs[i] = nil
        end
    end

    local label_obj, id = ui_base:new({
        type = 'bitmaplabel',
        base_x = x,
        base_y = y,
        width = max_width or 0,
        height = size,
        visible = true,
        _segs = segs,
    })

    label_obj._text = tostring(setting.text or '')
    label_obj._font_name = font_name
    label_obj._font = font
    label_obj._size = size
    label_obj._color = color
    label_obj._x = x
    label_obj._y = y
    label_obj._wrap = wrap
    label_obj._max_width = max_width
    label_obj._align = align

    local function glyph_scale(self)
        local base = (self._font and self._font.basePixelSize) or size
        return (self._size / base)
    end

    function label_obj:set_text(t)
        self._text = tostring(t or '')
        self:update_prim()
    end

    function label_obj:set_font(name)
        if fonts[name] then
            self._font_name = name
            self._font = fonts[name]
            self:update_prim()
            return true
        end
        return false
    end

    function label_obj:set_size(w, h)
        if w ~= nil and h ~= nil then
            self.width = tonumber(w) or self.width or 0
            self.height = tonumber(h) or self.height or 0
            if self.update_absolute_position then pcall(self.update_absolute_position, self) end
            pcall(self.update_prim, self)
            return true
        end
        -- single arg = font size (backcompat)
        if w ~= nil and h == nil then
            local newsz = tonumber(w)
            if newsz and newsz > 0 then
                self._size = newsz
                pcall(self.update_prim, self)
                return true
            end
            return nil, "invalid size"
        end
        return nil, "set_size requires width and height or single font-size"
    end

    function label_obj:set_font_size(sz)
        local newsz = tonumber(sz)
        if newsz and newsz > 0 then
            self._size = newsz
            pcall(self.update_prim, self)
            return true
        end
        return nil, "invalid font size"
    end

    function label_obj:set_element_size(w,h)
        return label_obj:set_size(w,h)
    end

    function label_obj:set_color(r,g,b,a)
        if type(r) == 'table' then
            self._color = r
        else
            self._color = { r or 255, g or 255, b or 255, a or 255 }
        end
        for i = 1, #segs do
            local s = segs[i]
            if s and s.set_color then
                local newcol = self._color
                if not s._last_color or s._last_color[1] ~= newcol[1] or s._last_color[2] ~= newcol[2] or s._last_color[3] ~= newcol[3] or s._last_color[4] ~= newcol[4] then
                    pcall(function() s:set_color(newcol[1], newcol[2], newcol[3], newcol[4]) end)
                    s._last_color = { newcol[1], newcol[2], newcol[3], newcol[4] }
                end
            end
        end
    end

    function label_obj:set_pos(nx, ny)
        self._x = nx or self._x
        self._y = ny or self._y
        if self.base_x ~= nil then self.base_x = self._x end
        if self.base_y ~= nil then self.base_y = self._y end
        if self.update_absolute_position then pcall(self.update_absolute_position, self) end
        self:update_prim()
    end

    function label_obj:set_wrap(w, maxw)
        self._wrap = w
        self._max_width = maxw or self._max_width
        self:update_prim()
    end

    function label_obj:measure_text(txt)
        txt = txt or self._text
        local scale = glyph_scale(self)
        local w = 0
        for i = 1, #txt do
            local ch = string.sub(txt, i, i)
            if ch == '\n' then
                -- newline shouldn't contribute to width
            else
                local c = string.byte(ch)
                local m = (self._font and self._font.letter and self._font.letter[c]) or { size = (self._font and self._font.basePixelSize) or size, left = 0 }
                w = w + ((m.size or size) * scale) + (self._font and self._font.between or 0)
            end
        end
        return w
    end

    local function split_lines_by_newline(txt)
        local out = {}
        if not txt or txt == '' then return {''} end
        local pos = 1
        while true do
            local s, e = txt:find('\n', pos, true)
            if not s then
                out[#out+1] = txt:sub(pos)
                break
            else
                out[#out+1] = txt:sub(pos, s-1)
                pos = e + 1
            end
        end
        return out
    end

    -- apply pending texture operations (does the actual set_path/show/hide calls)
    function label_obj:apply_pending_textures()
        for i = 1, #segs do
            local seg = segs[i]
            if seg then
                -- clear request: hide and clear last_path
                if seg._pending_clear then
                    if seg.hide then pcall(function() seg:hide() end) end
                    seg._last_path = nil
                    seg._pending_clear = nil
                end

                -- assign pending texture if different
                if seg._pending_path then
                    if seg._last_path ~= seg._pending_path then
                        pcall(function()
                            if seg.set_path then seg:set_path(seg._pending_path)
                            elseif seg.set_texture then seg:set_texture(seg._pending_path)
                            elseif seg.set_bitmap then seg:set_bitmap(seg._pending_path)
                            end
                        end)
                        seg._last_path = seg._pending_path
                        texture_cache[seg._pending_path] = true
                    end
                end

                -- show/hide according to pending flag (if nil, leave current state)
                if seg._pending_show ~= nil then
                    if seg._pending_show then
                        if seg.show then pcall(function() seg:show() end) end
                    else
                        if seg.hide then pcall(function() seg:hide() end) end
                    end
                    seg._pending_show = nil
                end

                -- clear pending_path after applied (keeps pending semantics)
                seg._pending_path = nil
            end
        end
    end

    function label_obj:update_prim()
        local txt = tostring(self._text or '')
        local scale = glyph_scale(self)

        -- Determine element absolute position (prefer layout-provided x/y if available)
        local px = (self.x or self.absolute_x or self.base_x or self._x or 0)
        local py = (self.y or self.absolute_y or self.base_y or self._y or 0)

        -- first split on explicit newlines
        local physical_lines = split_lines_by_newline(txt)

        -- then apply wrapping per physical line if requested
        local lines = {}
        if not self._wrap or not self._max_width then
            for _, l in ipairs(physical_lines) do lines[#lines+1] = l end
        else
            for _, l in ipairs(physical_lines) do
                if l == '' then
                    lines[#lines+1] = ''
                else
                    local cur = ''
                    for i = 1, #l do
                        cur = cur .. string.sub(l, i, i)
                        if self:measure_text(cur) > self._max_width then
                            local line_to_add = cur:sub(1, -2)
                            if line_to_add == '' then
                                lines[#lines+1] = cur
                                cur = ''
                            else
                                lines[#lines+1] = line_to_add
                                cur = cur:sub(-1)
                            end
                        end
                    end
                    if cur ~= '' then lines[#lines+1] = cur end
                end
            end
        end

        local total_height = 0
        local idx = 1
        local between = (self._font and self._font.between) or 0

        for li = 1, #lines do
            local line = lines[li] or ''
            local line_width = self:measure_text(line)
            local start_x = px
            if self._max_width and self._align == 'center' then
                start_x = start_x + math.floor((self._max_width - line_width) / 2)
            elseif self._max_width and self._align == 'right' then
                start_x = start_x + math.floor(self._max_width - line_width)
            end

            local xcursor = start_x
            for i = 1, #line do
                local ch = string.sub(line, i, i)

                -- whitespace: advance cursor, mark seg slot to be cleared if previously used
                if ch == ' ' or ch == '\t' then
                    local c = string.byte(ch)
                    local m = (self._font and self._font.letter and self._font.letter[c]) or { size = (self._font and self._font.basePixelSize) or size }
                    -- if there is a seg allocated at this index, mark it to be cleared (hide)
                    local seg = segs[idx]
                    if seg then
                        seg._pending_path = nil
                        seg._pending_show = false
                        seg._pending_clear = true
                    end
                    xcursor = xcursor + ((m.size or size) * scale) + between
                    -- do not increment idx (no prim used)
                else
                    local c = string.byte(ch)
                    local m = (self._font and self._font.letter and self._font.letter[c]) or { size = (self._font and self._font.basePixelSize) or size, left = 0 }

                    local glyph_w = math.max(1, math.floor((m.size or size) * scale))
                    local glyph_h = math.max(1, math.floor(self._size))

                    local seg = ensure_seg(idx)

                    -- size/pos/color still updated in update_prim (cheap)
                    if seg.set_size then
                        if seg._last_w ~= glyph_w or seg._last_h ~= glyph_h then
                            pcall(function() seg:set_size(glyph_w, glyph_h) end)
                            seg._last_w = glyph_w
                            seg._last_h = glyph_h
                        end
                    end

                    pcall(function()
                        if seg.set_origin then seg:set_origin(0,0) end
                        if seg.set_anchor then seg:set_anchor(0,0) end
                        if seg.set_pivot then seg:set_pivot(0,0) end
                    end)

                    local y_offset = 0
                    if m.yoffset then
                        y_offset = math.floor((m.yoffset or 0) * scale)
                    elseif m.top then
                        y_offset = math.floor((m.top or 0) * scale)
                    else
                        y_offset = math.floor((self._size - glyph_h) / 2)
                    end

                    local gx = math.floor(xcursor + ((m.left or 0) * scale))
                    local gy = math.floor(py + total_height + y_offset)

                    if seg.set_pos then
                        if seg._last_x ~= gx or seg._last_y ~= gy then
                            pcall(function() seg:set_pos(gx, gy) end)
                            seg._last_x = gx
                            seg._last_y = gy
                        end
                    end

                    if seg.set_color then
                        local col = self._color
                        if not seg._last_color or seg._last_color[1] ~= col[1] or seg._last_color[2] ~= col[2] or seg._last_color[3] ~= col[3] or seg._last_color[4] ~= col[4] then
                            pcall(function() seg:set_color(col[1], col[2], col[3], col[4]) end)
                            seg._last_color = { col[1], col[2], col[3], col[4] }
                        end
                    end

                    -- determine texture path but DO NOT assign it here
                    local tex_found = false
                    local tex = nil
                    if self._font and self._font.texture_map and self._font.texture_map[c] then
                        tex = self._font.texture_map[c]
                        tex_found = true
                    else
                        local folder = (self._font and self._font.folder) or (windower and windower.addon_path and (windower.addon_path .. 'base/ui/font_metrics/base'))
                        if folder then
                            tex = folder .. '/' .. tostring(c) .. '.png'
                            tex_found = true
                        end
                    end

                    if tex_found and tex then
                        seg._pending_path = tex
                        seg._pending_show = true
                        seg._pending_clear = nil
                    else
                        -- mark to hide/clear later
                        seg._pending_path = nil
                        seg._pending_show = false
                        seg._pending_clear = true
                    end

                    xcursor = xcursor + ((m.size or size) * scale) + between
                    idx = idx + 1
                end
            end

            total_height = total_height + math.floor(self._size + (self._font and self._font.verticalSpacing or 0))
        end

        clear_extra_segs(idx - 1)

        label_obj.width = math.max(1, self._max_width or self:measure_text(txt))
        label_obj.height = math.max(1, total_height)
        if label_obj.update_absolute_position then label_obj:update_absolute_position() end
    end

    if label_obj.visible ~= false then label_obj:update_prim() end

    return label_obj, #segs
end