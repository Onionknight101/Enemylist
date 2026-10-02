--[[
    direct_ffxi runtime - Direct3D drawing inside FFXI.

        local direct = require('direct_ffxi')
        local draw = direct.new('myaddon')

    Ship direct_ffxi_runtime.lua, direct_ffxi_native_v19.dll and the private
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
    local dll = directory .. 'direct_ffxi_native_v19.dll'

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

function direct_ffxi.crop_image(source, output, left, top, size, rotation_degrees,
        mirror_x)
    if rotation_degrees == nil and not mirror_x then
        return native.crop_image(source, output, left, top, size)
    end
    return native.crop_image(source, output, left, top, size,
        rotation_degrees or 0, mirror_x == true)
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
    for i = 1, #handles do
        local handle = handles[i].handle
        pcall(handle.close, handle)
    end
end)

return direct_ffxi
