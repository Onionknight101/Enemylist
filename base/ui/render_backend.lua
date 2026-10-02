-- Backend-neutral retained renderer for Enemylist image and text primitives.
-- Windower remains fully supported; DirectX uses direct_ffxi's final-frame pass.
local renderer = {}

local records = {}
local order = {}
local serial = 0
local dirty = true
local requested_mode = 'windower'
local active_mode = 'windower'
local fallback_reason = nil
local mode_listeners = {}

local function notify_mode_changed()
    for _, listener in ipairs(mode_listeners) do
        pcall(listener, active_mode, requested_mode, fallback_reason)
    end
end

-- Windower font sizes are point-like while the bitmap renderer consumes pixel
-- heights. 1.5 matches Actor's Arial presentation more closely than a strict
-- 96-DPI conversion, and remains independently adjustable by the user.
local saved_text_scale = type(get_save_setting) == 'function'
    and tonumber(get_save_setting('ui_directx_text_scale')) or nil
local direct_text_scale = saved_text_scale or 1.5

local direct_draw = nil
local direct_menu = nil
local direct_init_error = DIRECT_FFXI_ERROR
local direct_generation = 1
local dynamic_texture_changes = 0
local dynamic_texture_limit = 48
if DIRECT_FFXI then
    local ok, message = pcall(function()
        direct_draw = DIRECT_FFXI.new('enemylist-ui')
        direct_menu = DIRECT_FFXI.menu.new(direct_draw)
    end)
    if not ok then
        direct_draw = nil
        direct_menu = nil
        direct_init_error = tostring(message)
    end
end

local function dynamic_texture_path(path)
    if type(path) ~= 'string' then return false end
    local normalized = path:lower():gsub('\\', '/')
    return normalized:find('/media/maps/crop_cache/', 1, true) ~= nil
end

local function recycle_direct_context()
    if not DIRECT_FFXI or not direct_draw or not direct_menu then return false end
    direct_generation = direct_generation + 1
    local ok, new_draw, new_menu = pcall(function()
        local draw = DIRECT_FFXI.new('enemylist-ui-' .. tostring(direct_generation))
        return draw, DIRECT_FFXI.menu.new(draw)
    end)
    if not ok or not new_draw or not new_menu then
        direct_init_error = tostring(new_draw or 'failed to recycle DirectX UI')
        return false
    end
    pcall(function() direct_menu:clear() end)
    pcall(function() direct_draw:close() end)
    direct_draw, direct_menu = new_draw, new_menu
    dynamic_texture_changes = 0
    return true
end

local function normalize_mode(value)
    value = tostring(value or ''):lower()
    if value == 'dx' or value == 'd3d' then value = 'directx' end
    if value ~= 'windower' and value ~= 'directx' and value ~= 'auto' then
        return nil
    end
    return value
end

local function mark_dirty()
    dirty = true
end

local function add_record(id, kind)
    serial = serial + 1
    local item = {id = id, kind = kind, serial = serial, visible = true}
    records[id] = item
    order[#order + 1] = item
    mark_dirty()
    return item
end

local function record(id, kind)
    return records[id] or add_record(id, kind)
end

local function remove_record(id)
    local item = records[id]
    if not item then return end
    records[id] = nil
    for index = #order, 1, -1 do
        if order[index] == item then
            table.remove(order, index)
            break
        end
    end
    mark_dirty()
end

-- Reorder one retained item relative to another without promoting it above
-- unrelated windows that were created later.
function renderer.place_after(id, reference_id)
    local item, reference = records[id], records[reference_id]
    if not item or not reference or item == reference then return false end
    for index = #order, 1, -1 do
        if order[index] == item then
            table.remove(order, index)
            break
        end
    end
    local reference_index
    for index, candidate in ipairs(order) do
        if candidate == reference then reference_index = index break end
    end
    if not reference_index then return false end
    table.insert(order, reference_index + 1, item)
    mark_dirty()
    return true
end

local function absolute_path(path)
    if type(path) ~= 'string' or path == '' then return nil end
    if path:match('^%a:[/\\]') or path:match('^[/\\][/\\]') then return path end
    return windower.addon_path .. path:gsub('^[/\\]+', '')
end

local function color(r, g, b, a)
    return {tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255,
        tonumber(a) or 255}
end

local function direct_available()
    if not direct_draw or not direct_menu then
        return false, direct_init_error or 'direct_ffxi is unavailable'
    end
    local ok, width, height = pcall(function()
        return direct_draw:screen_size()
    end)
    if not ok then return false, tostring(width) end
    return true, width and height and nil or 'waiting for the Direct3D viewport'
end

local function hide_windower()
    for _, item in ipairs(order) do
        if item.kind == 'image' then
            windower.prim.set_visibility(item.id, false)
        else
            windower.text.set_visibility(item.id, false)
        end
    end
end

local function apply_image(item)
    windower.prim.set_position(item.id, item.x or 0, item.y or 0)
    windower.prim.set_size(item.id, item.width or 1, item.height or 1)
    local c = item.color or color(255, 255, 255, 255)
    windower.prim.set_color(item.id, c[4], c[1], c[2], c[3])
    if item.path then windower.prim.set_texture(item.id, item.path) end
    if item.fit ~= nil then windower.prim.set_fit_to_texture(item.id, item.fit) end
    windower.prim.set_visibility(item.id, item.visible ~= false)
end

local function apply_text(item)
    windower.text.set_location(item.id, item.x or 0, item.y or 0)
    local c = item.color or color(255, 255, 255, 255)
    windower.text.set_color(item.id, c[4], c[1], c[2], c[3])
    windower.text.set_font(item.id, item.font or 'Arial', unpack(item.fonts or {}))
    windower.text.set_font_size(item.id, item.size or 12)
    windower.text.set_text(item.id, item.value or '')
    windower.text.set_bg_border_size(item.id, item.padding or 0)
    local bg = item.bg or color(0, 0, 0, 0)
    windower.text.set_bg_color(item.id, bg[4], bg[1], bg[2], bg[3])
    windower.text.set_bg_visibility(item.id, item.bg_visible == true)
    windower.text.set_bold(item.id, item.bold == true)
    windower.text.set_italic(item.id, item.italic == true)
    windower.text.set_right_justified(item.id, item.right == true)
    local stroke = item.stroke or {width = 0, color = color(0, 0, 0, 255)}
    windower.text.set_stroke_width(item.id, stroke.width or 0)
    windower.text.set_stroke_color(item.id, stroke.color[4], stroke.color[1],
        stroke.color[2], stroke.color[3])
    windower.text.set_visibility(item.id, item.visible ~= false)
end

local function show_windower()
    for _, item in ipairs(order) do
        if item.kind == 'image' then apply_image(item) else apply_text(item) end
    end
end

local function bitmap_font(name)
    if not BITMAPFONT then return nil end
    name = tostring(name or 'Arial')
    if BITMAPFONT[name] then return BITMAPFONT[name] end
    local wanted = name:lower()
    for key, font in pairs(BITMAPFONT) do
        if tostring(key):lower() == wanted then return font end
    end
    return BITMAPFONT.Arial or BITMAPFONT.base
end

local function draw_direct_text(item)
    local font = bitmap_font(item.font)
    if not font then return end
    local real_bold = item.bold and font.bold_font
    if real_bold then font = real_bold end
    local value = item.value or ''
    local size = (item.size or 12) * direct_text_scale
    local width, height = direct_menu:measure_text(font, value, size)
    local x, y = item.x or 0, item.y or 0
    if item.right then x = x - width end

    local padding = item.padding or 0
    if item.bg_visible and item.bg and item.bg[4] > 0 then
        direct_menu:rect(x - padding, y - padding,
            width + padding * 2, height + padding * 2, item.bg)
    end

    local stroke = item.stroke
    if stroke and (stroke.width or 0) > 0 then
        local amount = math.max(1, math.floor(stroke.width))
        local offsets = {{-amount, 0}, {amount, 0}, {0, -amount}, {0, amount}}
        for _, offset in ipairs(offsets) do
            direct_menu:text(font, x + offset[1], y + offset[2], value, size,
                stroke.color)
        end
    end
    if item.bold and not real_bold then
        direct_menu:text(font, x + 1, y, value, size, item.color)
    end
    direct_menu:text(font, x, y, value, size, item.color)
end

local function render_direct()
    local ok, message = pcall(function()
        direct_menu:begin()
        for _, item in ipairs(order) do
            if records[item.id] == item and item.visible ~= false then
                if item.kind == 'image' then
                    local c = item.color or color(255, 255, 255, 255)
                    if item.path then
                        direct_menu:image(item.x or 0, item.y or 0,
                            item.width or 1, item.height or 1,
                            absolute_path(item.path), c, item.effect, item.viewport)
                    else
                        direct_menu:rect(item.x or 0, item.y or 0,
                            item.width or 1, item.height or 1, c)
                    end
                else
                    draw_direct_text(item)
                end
            end
        end
        direct_menu:commit()
    end)
    if not ok then return false, tostring(message) end
    dirty = false
    return true
end

function renderer.set_mode(mode)
    mode = normalize_mode(mode)
    if not mode then return false, 'mode must be windower, directx, or auto' end
    local previous_mode = active_mode
    requested_mode = mode
    fallback_reason = nil

    local target = mode
    if mode == 'auto' then target = 'directx' end
    if target == 'directx' then
        local available, reason = direct_available()
        if not available then
            target = 'windower'
            fallback_reason = reason
        end
    end

    if active_mode == 'directx' and target ~= 'directx' and direct_menu then
        direct_menu:clear()
    end
    active_mode = target
    if active_mode == 'directx' then
        hide_windower()
        mark_dirty()
    else
        show_windower()
    end
    if active_mode ~= previous_mode then notify_mode_changed() end
    return true, renderer.status()
end

function renderer.flush()
    if active_mode ~= 'directx' or not dirty then return true end
    local ok, reason = render_direct()
    if ok then return true end
    fallback_reason = reason
    local previous_mode = active_mode
    active_mode = 'windower'
    if direct_menu then pcall(function() direct_menu:clear() end) end
    show_windower()
    if active_mode ~= previous_mode then notify_mode_changed() end
    return false, reason
end

function renderer.status()
    local status = ('requested=%s active=%s objects=%d text_scale=%.2f')
        :format(requested_mode, active_mode, #order, direct_text_scale)
    if fallback_reason then status = status .. ' fallback=' .. fallback_reason end
    return status
end

function renderer.get_mode() return active_mode, requested_mode end
function renderer.is_directx() return active_mode == 'directx' end
function renderer.add_mode_listener(listener)
    if type(listener) ~= 'function' then return false end
    mode_listeners[#mode_listeners + 1] = listener
    return true
end
function renderer.invalidate() mark_dirty() end
function renderer.set_text_scale(value)
    value = tonumber(value)
    if not value or value < 0.75 or value > 3 then
        return false, 'DirectX text scale must be between 0.75 and 3.00'
    end
    direct_text_scale = value
    mark_dirty()
    return true, direct_text_scale
end
function renderer.get_text_scale() return direct_text_scale end
function renderer.shutdown()
    if direct_menu then pcall(function() direct_menu:clear() end) end
    for index = #order, 1, -1 do
        local item = order[index]
        if item.kind == 'image' then
            pcall(windower.prim.delete, item.id)
        else
            pcall(windower.text.delete, item.id)
        end
    end
    records = {}
    order = {}
    serial = 0
    mode_listeners = {}
    dirty = true
end

renderer.image = {}
function renderer.image.create(id)
    windower.prim.create(id)
    local item = record(id, 'image')
    -- A UI image is not ready to draw until its owner has assigned its
    -- hierarchy, texture and final visibility. Starting native primitives
    -- visible lets unused image slots flash for one Windower frame.
    item.visible = false
    windower.prim.set_visibility(id, false)
    return item
end
function renderer.image.delete(id)
    windower.prim.delete(id)
    remove_record(id)
end
function renderer.image.set_position(id, x, y)
    local item = record(id, 'image'); item.x, item.y = x, y; mark_dirty()
    if active_mode == 'windower' then windower.prim.set_position(id, x, y) end
end
function renderer.image.set_size(id, width, height)
    local item = record(id, 'image'); item.width, item.height = width, height; mark_dirty()
    if active_mode == 'windower' then windower.prim.set_size(id, width, height) end
end
function renderer.image.set_color(id, alpha, red, green, blue)
    local item = record(id, 'image'); item.color = color(red, green, blue, alpha); mark_dirty()
    if active_mode == 'windower' then windower.prim.set_color(id, alpha, red, green, blue) end
end
function renderer.image.set_texture(id, path)
    local item = record(id, 'image')
    local changed = item.path ~= path
    item.path = path
    if changed and active_mode == 'directx' and dynamic_texture_path(path) then
        dynamic_texture_changes = dynamic_texture_changes + 1
        if dynamic_texture_changes >= dynamic_texture_limit then
            recycle_direct_context()
        end
    end
    mark_dirty()
    if active_mode == 'windower' then windower.prim.set_texture(id, path) end
end
function renderer.image.is_ready(id)
    local item = records[id]
    if not item or item.kind ~= 'image' or not item.path then return false end
    if active_mode ~= 'directx' or not direct_menu
            or type(direct_menu.texture_ready) ~= 'function' then
        return nil
    end
    local ok, ready, failed = pcall(function()
        return direct_menu:texture_ready(absolute_path(item.path))
    end)
    if not ok then return nil end
    return ready == true, failed == true
end
function renderer.image.set_viewport(id, viewport)
    local item = record(id, 'image')
    item.viewport = viewport
    mark_dirty()
end
function renderer.image.set_fit_to_texture(id, fit)
    local item = record(id, 'image'); item.fit = fit; mark_dirty()
    if active_mode == 'windower' then windower.prim.set_fit_to_texture(id, fit) end
end
function renderer.image.set_effect(id, effect)
    local item = record(id, 'image'); item.effect = effect; mark_dirty()
end
function renderer.image.set_visibility(id, visible)
    local item = record(id, 'image'); item.visible = visible == true; mark_dirty()
    windower.prim.set_visibility(id, active_mode == 'windower' and item.visible)
end

renderer.text = {}
function renderer.text.create(id)
    windower.text.create(id)
    local item = record(id, 'text')
    windower.text.set_visibility(id, active_mode == 'windower')
    return item
end
function renderer.text.delete(id)
    windower.text.delete(id)
    remove_record(id)
end
local function text_item(id) return record(id, 'text') end
function renderer.text.set_location(id, x, y)
    local item = text_item(id); item.x, item.y = x, y; mark_dirty()
    if active_mode == 'windower' then windower.text.set_location(id, x, y) end
end
function renderer.text.set_text(id, value)
    local item = text_item(id); item.value = tostring(value or ''); mark_dirty()
    if active_mode == 'windower' then windower.text.set_text(id, item.value) end
end
function renderer.text.set_color(id, alpha, red, green, blue)
    local item = text_item(id); item.color = color(red, green, blue, alpha); mark_dirty()
    if active_mode == 'windower' then windower.text.set_color(id, alpha, red, green, blue) end
end
function renderer.text.set_font(id, font, ...)
    local item = text_item(id); item.font, item.fonts = font, {...}; mark_dirty()
    if active_mode == 'windower' then windower.text.set_font(id, font, ...) end
end
function renderer.text.set_font_size(id, size)
    local item = text_item(id); item.size = size; mark_dirty()
    if active_mode == 'windower' then windower.text.set_font_size(id, size) end
end
function renderer.text.set_visibility(id, visible)
    local item = text_item(id); item.visible = visible == true; mark_dirty()
    windower.text.set_visibility(id, active_mode == 'windower' and item.visible)
end
function renderer.text.set_bg_border_size(id, padding)
    local item = text_item(id); item.padding = padding; mark_dirty()
    if active_mode == 'windower' then windower.text.set_bg_border_size(id, padding) end
end
function renderer.text.set_bg_color(id, alpha, red, green, blue)
    local item = text_item(id); item.bg = color(red, green, blue, alpha); mark_dirty()
    if active_mode == 'windower' then windower.text.set_bg_color(id, alpha, red, green, blue) end
end
function renderer.text.set_bg_visibility(id, visible)
    local item = text_item(id); item.bg_visible = visible == true; mark_dirty()
    if active_mode == 'windower' then windower.text.set_bg_visibility(id, visible) end
end
function renderer.text.set_bold(id, value)
    local item = text_item(id); item.bold = value == true; mark_dirty()
    if active_mode == 'windower' then windower.text.set_bold(id, value) end
end
function renderer.text.set_italic(id, value)
    local item = text_item(id); item.italic = value == true; mark_dirty()
    if active_mode == 'windower' then windower.text.set_italic(id, value) end
end
function renderer.text.set_right_justified(id, value)
    local item = text_item(id); item.right = value == true; mark_dirty()
    if active_mode == 'windower' then windower.text.set_right_justified(id, value) end
end
function renderer.text.set_stroke_width(id, width)
    local item = text_item(id); item.stroke = item.stroke or {color = color(0, 0, 0, 255)}
    item.stroke.width = width; mark_dirty()
    if active_mode == 'windower' then windower.text.set_stroke_width(id, width) end
end
function renderer.text.set_stroke_color(id, alpha, red, green, blue)
    local item = text_item(id); item.stroke = item.stroke or {width = 0}
    item.stroke.color = color(red, green, blue, alpha); mark_dirty()
    if active_mode == 'windower' then
        windower.text.set_stroke_color(id, alpha, red, green, blue)
    end
end
function renderer.text.get_extents(id)
    local item = records[id]
    local font = item and bitmap_font(item.font) or nil
    if active_mode == 'directx' and item and direct_menu and font then
        return direct_menu:measure_text(font, item.value or '',
            (item.size or 12) * direct_text_scale)
    end
    return windower.text.get_extents(id)
end

local initial = type(get_save_setting) == 'function' and get_save_setting('ui_renderer')
renderer.set_mode(normalize_mode(initial) or 'windower')

return renderer
