--[[
    direct_ffxi runtime - Direct3D drawing inside FFXI.

        local direct = require('direct_ffxi')
        local draw = direct.new('myaddon')

    Ship direct_ffxi_runtime.lua, direct_ffxi_native_v59.dll and the private
    native hook daemon together. Everything else is reached through the handle.

    This file already closes the handle on unload, ticks the library every
    frame, and tells the player when the library cannot draw. Your addon does
    not need to do any of the three. Nothing is printed while things work.

    If you do want to look at what went wrong:

        d:last_error()          the most recent message of either kind
        d:engineering_error()   the most recent internal detail, prefixed
                                'texture: ', 'gpu: ', 'hook: ', 'draw: ' or
                                'scan: '. Never shown to a player -- this is
                                what belongs in a bug report.
]]

local native
do
    local source = debug.getinfo(1, 'S').source
    local path = source:sub(1, 1) == '@' and source:sub(2) or source
    local directory = path:match('^(.*[\\/])') or ''
    local dll = directory .. 'direct_ffxi_native_v59.dll'

    local loader, message = package.loadlib(dll, 'luaopen_worlddraw')
    if not loader then
        error('direct_ffxi: could not load ' .. dll .. ': ' .. tostring(message), 2)
    end

    native = loader()
end

local handles = {}

local direct_ffxi = {}

-- A chat line per line of the message, each carrying the name the addon gave
-- itself, so a player running several can tell which one is speaking. 123 is
-- Windower's error colour.
local function announce(entry, message)
    for line in message:gmatch('[^\n]+') do
        line = line:gsub('^worlddraw', 'direct_ffxi')
        windower.add_to_chat(123, '[' .. entry.name .. '] ' .. line)
    end
end

-- The engine records why it cannot draw and says nothing itself, so this is
-- what puts the reason in front of the player. Reading the message takes it,
-- so there is nothing to remember here: what comes back has not been shown,
-- and the read after it comes back empty.
local function check(entry)
    local message = entry.handle:player_error()
    if message then
        announce(entry, message)
    end
end

-- direct_ffxi.new(name [, options]). options.reset_on_zone = true has the handle
-- reset itself on every zone change, as if the addon had called d:reset()
-- there.
function direct_ffxi.new(name, options)
    if type(name) ~= 'string' then
        error('direct_ffxi.new: name must be a string', 2)
    end

    local handle = native.new(name)

    local entry = {handle = handle, name = name,
        reset_on_zone = type(options) == 'table' and options.reset_on_zone == true}
    handles[#handles + 1] = entry

    -- Whatever went wrong at setup has gone wrong by now. The handle is
    -- returned either way: an addon whose library cannot draw still runs, and
    -- every call on the handle stays safe to make.
    check(entry)
    return handle
end

function direct_ffxi.version()
    return native.version()
end

-- The selected D3D8.1 pixel-shader profile for textured UI batches. It is
-- `pending` until the first textured draw, then ps.1.4 .. ps.1.1 or the
-- fixed-function compatibility fallback.
function direct_ffxi.ui_shader_profile()
    return native.ui_shader_profile()
end

-- DirectX framebuffer transport used by Actor's local camera wall. Pixel data
-- stays in named shared memory and is composed by this same native renderer.
function direct_ffxi.camera_start(character_name)
    return native.camera_start(character_name)
end

function direct_ffxi.camera_view(enabled, x, y, width, height, count, names,
        cover_x, cover_y, cover_width, cover_height, drag_slot, spread)
    return native.camera_view(enabled == true, x or 0, y or 0, width or 0,
        height or 0, count or 1, names or '', cover_x or 0, cover_y or 0,
        cover_width or 0, cover_height or 0, drag_slot or 0, spread or 3)
end

function direct_ffxi.camera_stop()
    return native.camera_stop()
end

function direct_ffxi.controller_state(index)
    return native.controller_state(index or 0)
end

function direct_ffxi.controller_capture(enabled)
    return native.controller_capture(enabled == true)
end

function direct_ffxi.controller_mapping()
    return native.controller_mapping()
end

function direct_ffxi.draw_parts_start(pass)
    return native.draw_parts_start(pass or 'world')
end

function direct_ffxi.draw_parts_stop()
    return native.draw_parts_stop()
end

function direct_ffxi.draw_parts_state()
    return native.draw_parts_state()
end

function direct_ffxi.draw_menus_visible(visible)
    if visible == nil then return native.draw_menus_visible() end
    return native.draw_menus_visible(visible == true)
end

function direct_ffxi.draw_parts_list()
    return native.draw_parts_list()
end

-- Pass a stable 16-digit hexadecimal fingerprint to show matching game draws
-- without their texture. Pass nil to clear the selection.
function direct_ffxi.draw_parts_select(fingerprint)
    return native.draw_parts_select(fingerprint)
end

function direct_ffxi.draw_parts_preview(visible, x, y, size)
    return native.draw_parts_preview(visible == true, x or 0, y or 0, size or 96)
end

function direct_ffxi.draw_parts_save_texture(path)
    return native.draw_parts_save_texture(path)
end

function direct_ffxi.draw_parts_save_status()
    return native.draw_parts_save_status()
end

function direct_ffxi.draw_parts_replacement(enabled, path)
    return native.draw_parts_replacement(enabled == true, path)
end

function direct_ffxi.draw_parts_replacement_status()
    return native.draw_parts_replacement_status()
end

function direct_ffxi.crop_image(source, output, left, top, size, rotation_degrees,
        mirror_x)
    local crop = native.crop_image
    if type(crop) ~= 'function' then
        return false, 'unavailable'
    end
    local ok, result, reason
    if rotation_degrees == nil and not mirror_x then
        ok, result, reason = pcall(crop, source, output, left, top, size)
    else
        ok, result, reason = pcall(crop, source, output, left, top, size,
            rotation_degrees or 0, mirror_x == true)
    end
    if not ok then return false, tostring(result) end
    return result, reason
end

-- Some failures arrive long after load -- another program taking the graphics
-- hooks, a device the game replaced -- so the tick looks for them every two
-- seconds. No string crosses out of C on the frames in between.
local poll_interval = 2.0
local last_poll = 0

windower.register_event('prerender', function()
    native.tick()

    local now = os.clock()
    if now - last_poll < poll_interval then
        return
    end
    last_poll = now

    for i = 1, #handles do
        check(handles[i])
    end
end)

windower.register_event('zone change', function()
    for i = 1, #handles do
        if handles[i].reset_on_zone then
            local handle = handles[i].handle
            pcall(handle.reset, handle)
        end
    end
end)

windower.register_event('unload', function()
    pcall(native.camera_stop)
    pcall(native.controller_capture, false)
    pcall(native.draw_menus_visible, true)
    pcall(native.draw_parts_select, nil)
    pcall(native.draw_parts_preview, false, 0, 0, 0)
    pcall(native.draw_parts_replacement, false)
    for i = 1, #handles do
        local handle = handles[i].handle
        pcall(handle.close, handle)
    end
end)

return direct_ffxi
