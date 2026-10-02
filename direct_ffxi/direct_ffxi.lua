-- Reusable entry point for Direct3D-backed FFXI world drawing.
--
-- Add this directory to package.path and require('direct_ffxi'), or load this
-- file directly with dofile. The native engine and hook daemon live beside it.

local cache_key = 'direct_ffxi.runtime'
if package.loaded[cache_key] then
    return package.loaded[cache_key]
end

local source = debug.getinfo(1, 'S').source
local path = source:sub(1, 1) == '@' and source:sub(2) or source
local directory = path:match('^(.*[\\/])') or ''
local loader, message = loadfile(directory .. 'direct_ffxi_runtime.lua')

if not loader then
    error('direct_ffxi: could not load direct_ffxi_runtime.lua: ' .. tostring(message), 2)
end

local direct_ffxi = loader()
local menu_loader, menu_message = loadfile(directory .. 'menu.lua')
if not menu_loader then
    error('direct_ffxi: could not load menu.lua: ' .. tostring(menu_message), 2)
end
direct_ffxi.menu = menu_loader()
package.loaded[cache_key] = direct_ffxi
return direct_ffxi
