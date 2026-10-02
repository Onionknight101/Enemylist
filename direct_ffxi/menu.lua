local menu = {}
local painter = {}
painter.__index = painter

local function clamp_byte(value)
    value = math.floor(tonumber(value) or 0)
    if value < 0 then return 0 end
    if value > 255 then return 255 end
    return value
end

function menu.argb(red, green, blue, alpha)
    return clamp_byte(alpha == nil and 255 or alpha) * 0x1000000
        + clamp_byte(red) * 0x10000
        + clamp_byte(green) * 0x100
        + clamp_byte(blue)
end

local function color_value(value, fallback)
    if type(value) == 'number' then return value end
    if type(value) == 'table' then
        return menu.argb(value[1], value[2], value[3], value[4])
    end
    return fallback or 0xFFFFFFFF
end

local function effect_value(value)
    if value == 1 or value == 'gray' or value == 'grayscale' then return 1 end
    if value == 2 or value == 'shimmer' or value == 'sweep' then return 2 end
    if value == 3 or value == 'combined' or value == 'vertex_pixel' then return 3 end
    if value == 4 or value == 'pulse' or value == 'breathe' then return 4 end
    return 0
end

function menu.new(handle)
    if not handle then error('direct_ffxi.menu.new needs a draw handle', 2) end
    return setmetatable({handle = handle, textures = {}}, painter)
end

function painter:begin()
    return self.handle:begin()
end

function painter:commit()
    return self.handle:commit()
end

function painter:clear()
    return self.handle:clear()
end

function painter:size()
    return self.handle:screen_size()
end

function painter:rect(x, y, width, height, color)
    return self.handle:screen_rect(x, y, width, height,
        color_value(color, 0xFFFFFFFF))
end

function painter:border(x, y, width, height, thickness, color)
    return self.handle:screen_border(x, y, width, height, thickness,
        color_value(color, 0xFFFFFFFF))
end

function painter:texture(path)
    local id = self.textures[path]
    if id then return id end
    id = self.handle:load_texture(path)
    if id then self.textures[path] = id end
    return id
end

function painter:texture_ready(path)
    local id = self.textures[path]
    if not id then return false, false end
    return self.handle:texture_ready(id)
end

local function viewport_uv(viewport)
    if type(viewport) ~= 'table' then return nil end
    local texture_width = tonumber(viewport.texture_width) or 512
    local texture_height = tonumber(viewport.texture_height) or 512
    local size = tonumber(viewport.size) or texture_width
    local center_x = (tonumber(viewport.left) or 0) + size / 2
    local center_y = (tonumber(viewport.top) or 0) + size / 2
    local radians = math.rad(tonumber(viewport.rotation) or 0)
    local cosine, sine = math.cos(radians), math.sin(radians)
    local mirror_x = viewport.mirror_x == true

    local function sample(dx, dy)
        local source_x = dx * cosine + dy * sine
        local source_y = -dx * sine + dy * cosine
        if mirror_x then source_x = -source_x end
        return (center_x + source_x) / texture_width,
            (center_y + source_y) / texture_height
    end

    local half = size / 2
    local au, av = sample(-half, -half)
    local bu, bv = sample(half, -half)
    local cu, cv = sample(-half, half)
    local du, dv = sample(half, half)
    return {au, av, bu, bv, cu, cv, du, dv}
end

function painter:image(x, y, width, height, texture, color, effect, viewport)
    local id = texture
    if type(texture) == 'string' then id = self:texture(texture) end
    if not id then return false end
    local uv = viewport_uv(viewport)
    self.handle:screen_image(x, y, width, height, id,
        color_value(color, 0xFFFFFFFF), effect_value(effect),
        uv and uv[1], uv and uv[2], uv and uv[3], uv and uv[4],
        uv and uv[5], uv and uv[6], uv and uv[7], uv and uv[8])
    return true
end

local function glyph_metrics(font, byte)
    return font.letter[byte] or font.letter[63]
        or {size = font.basePixelSize or 16, left = 0, kerning = {}}
end

local function glyph_path(font, byte)
    if font.texture_map and font.texture_map[byte] then
        return font.texture_map[byte]
    end
    return font.folder .. '/' .. tostring(byte) .. '.png'
end

function painter:measure_text(font, text, size)
    if type(font) ~= 'table' or type(font.letter) ~= 'table' then
        return 0, 0
    end
    text = tostring(text or '')
    size = math.max(1, tonumber(size) or font.basePixelSize or 16)
    local scale = size / (font.basePixelSize or size)
    local cursor = 0
    local widest = 0
    local lines = 1
    for index = 1, #text do
        local byte = text:byte(index)
        if byte == 10 then
            widest = math.max(widest, cursor)
            cursor = 0
            lines = lines + 1
        else
            local metrics = glyph_metrics(font, byte)
            local advance = tonumber(metrics.size) or font.basePixelSize or size
            advance = advance - (tonumber(metrics.left) or 0)
            local next_byte = text:byte(index + 1)
            if next_byte and metrics.kerning then
                advance = advance - (tonumber(metrics.kerning[next_byte]) or 0)
            end
            if byte == 9 then advance = advance * 4 end
            cursor = cursor + advance * scale + (tonumber(font.between) or 0)
        end
    end
    return math.max(widest, cursor), lines * size
end

-- Stages bitmap text using Actor's bitmap_font shape (folder, basePixelSize,
-- letter metrics). Glyph textures are loaded once per painter and then reused.
function painter:text(font, x, y, text, size, color, effect)
    if type(font) ~= 'table' or type(font.letter) ~= 'table' then
        error('menu:text needs a bitmap font table', 2)
    end
    text = tostring(text or '')
    size = math.max(1, tonumber(size) or font.basePixelSize or 16)
    local scale = size / (font.basePixelSize or size)
    local start_x = x
    local cursor_x = x
    local cursor_y = y
    local widest = 0
    local lines = 1
    local tint = color_value(color, 0xFFFFFFFF)

    for index = 1, #text do
        local byte = text:byte(index)
        if byte == 10 then
            widest = math.max(widest, cursor_x - start_x)
            cursor_x = start_x
            cursor_y = cursor_y + size
            lines = lines + 1
        else
            local metrics = glyph_metrics(font, byte)
            if byte ~= 32 and byte ~= 9 then
                if not font.letter[byte] then byte = 63 end
                local width = math.max(1, (tonumber(metrics.size) or size) * scale)
                local texture = self:texture(glyph_path(font, byte))
                if texture then
                    self.handle:screen_image(cursor_x, cursor_y, width, size, texture, tint,
                        effect_value(effect))
                end
            end

            local advance = tonumber(metrics.size) or font.basePixelSize or size
            advance = advance - (tonumber(metrics.left) or 0)
            local next_byte = text:byte(index + 1)
            if next_byte and metrics.kerning then
                advance = advance - (tonumber(metrics.kerning[next_byte]) or 0)
            end
            if byte == 9 then advance = advance * 4 end
            cursor_x = cursor_x + advance * scale + (tonumber(font.between) or 0)
        end
    end
    widest = math.max(widest, cursor_x - start_x)
    return widest, lines * size
end

return menu
