_addon.name = 'Enemylist'
_addon.author = 'Onionlord'
_addon.version = '0.1.0'
_addon.commands = {'enemylist', 'elist'}

require('tables')
require('strings')
local config = require('config')
local resources = require('resources')
local bit = require('bit')
local settings = config.load({enabled = true, values = {}})
require('base/functions/mathFunctions')
require('base/functions/stringFunctions')
require('base/functions/tableFunctions')
require('base/ui/font_metrics/font_metrics')

-- Compatibility surface for the copied renderer, not a dependency on Actor.
ACTOR_LIB = {player = {}, enemy = {}}
LIBRARY_STRUCTURE = {}
RESOURCES = {}
EVENT_TRIGGER = {}
MENU_UI = {}
local buff_types = require('base/res/buff_types')
local refresh_view = function() end
local party_ids = {}
function EVENT_TRIGGER.set(_, _, _, callback) refresh_view = callback end
function LIBRARY_STRUCTURE.is_claimed_by_party(id) return party_ids[id] == true end
function RESOURCES:E(category, id) return category == 'buff_types' and buff_types[id] or nil end
function RESOURCES:NPC_FROM_ID(id)
    local entry = ACTOR_LIB.enemy[id]
    return entry and {id = id, name = entry.name, index = entry.index} or nil
end
function get_save_setting(key) return settings.values[key] end
function set_character_save_setting(_, _, key, value)
    settings.values[key] = value
    config.save(settings)
end
set_save_setting = set_character_save_setting

ui = require('base/ui/ui')
MENU_UI.view_region = ui.create_imageless_region({x = 0, y = 0,
    width = windower.get_windower_settings().ui_x_res,
    height = windower.get_windower_settings().ui_y_res, draggable = false})
ui.elements:add_to_root(MENU_UI.view_region)
local view
local function update_player()
    local player = windower.ffxi.get_player()
    local info = windower.ffxi.get_info()
    if not player or not info or not info.logged_in then return false end
    ACTOR_LIB.player = {id = player.id, name = player.name, zone = info.zone}
    party_ids = {[player.id] = true}
    for key, member in pairs(windower.ffxi.get_party() or {}) do
        if type(member) == 'table' and member.mob then party_ids[member.mob.id] = true end
    end
    return true
end
local function init()
    if not update_player() then return end
    if not view then
        view = require('menu/views/basic/enemy_list')
        MENU_UI.view_region:add(view)
    end
    MENU_UI.view_region:set_visibility(settings.enabled)
end

local function track(mob)
    if not mob or not mob.id or bit.band(tonumber(mob.spawn_type) or 0, 16) == 0 then return nil end
    if mob.valid_target == false or (mob.distance or 0) > 2500 then return nil end
    if mob.hpp == 0 and not ACTOR_LIB.enemy[mob.id] then return nil end
    local entry = ACTOR_LIB.enemy[mob.id] or {id = mob.id, buffs = {}, debuffs = {}}
    entry.name, entry.index, entry.hpp = mob.name, mob.index, mob.hpp
    entry.claim, entry.status, entry.zone = mob.claim_id, mob.status, ACTOR_LIB.player.zone
    ACTOR_LIB.enemy[mob.id] = entry
    return entry
end
local function mob_by_id(id) return windower.ffxi.get_mob_by_id(id) end

windower.register_event('action', function(action)
    if not update_player() then return end
    local source = mob_by_id(action.actor_id)
    local source_is_party = party_ids[action.actor_id]
    for _, target in ipairs(action.targets or {}) do
        if party_ids[target.id] then track(source) end
        local entry = ACTOR_LIB.enemy[target.id]
        if source_is_party then entry = track(mob_by_id(target.id)) or entry end
        if entry then
            for _, result in ipairs(target.actions or {}) do
                -- Only explicit successful status messages; never infer effects from a cast alone.
                if result.message == 236 or result.message == 237 or result.message == 267 or result.message == 268 then
                    local spell = action.category == 4 and resources.spells[action.param]
                    local effect = spell and spell.status
                    if effect and effect > 0 then entry.debuffs[effect] = {id = effect} end
                end
                local message = tonumber(result.add_effect_message)
                if message and message >= 288 and message <= 301 then
                    local prior = entry.skillchain
                    entry.skillchain = {type = message - 287, time = os.clock(), skillchain_duration = 9,
                        step = prior and os.clock() - prior.time < 9 and prior.step + 1 or 2}
                end
            end
        end
    end
    refresh_view()
end)
windower.register_event('action message', function(_, target, _, _, message, effect)
    local entry = ACTOR_LIB.enemy[target]
    if entry and (message == 204 or message == 206) then entry.debuffs[effect] = nil; refresh_view() end
end)
local function clear()
    ACTOR_LIB.enemy = {}
    refresh_view()
end
windower.register_event('zone change', clear)
windower.register_event('logout', function() clear(); MENU_UI.view_region:hide() end)
windower.register_event('login', init)
windower.register_event('mouse', function(...) return ui.elements:pass_mouse_event(...) end)
local next_scan = 0
windower.register_event('prerender', function()
    if os.clock() >= next_scan then
        next_scan = os.clock() + 0.25
        if update_player() then
            init()
            track(windower.ffxi.get_mob_by_target('t'))
            for _, mob in pairs(windower.ffxi.get_mob_array() or {}) do
                track(mob)
            end
            for id, entry in pairs(ACTOR_LIB.enemy) do
                local mob = mob_by_id(id)
                if not mob or mob.valid_target == false or (mob.distance or 0) > 2500 then
                    ACTOR_LIB.enemy[id] = nil
                else
                    track(mob)
                    if entry.hpp == 0 then
                        entry.dead_since = entry.dead_since or os.clock()
                        if os.clock() - entry.dead_since > 5 then ACTOR_LIB.enemy[id] = nil end
                    else entry.dead_since = nil end
                end
            end
            refresh_view()
        else MENU_UI.view_region:hide() end
    end
    ui.refresh_all()
end)
windower.register_event('addon command', function(command)
    command = (command or 'help'):lower()
    if command == 'show' or command == 'hide' or command == 'toggle' then
        settings.enabled = command == 'show' or (command == 'toggle' and not settings.enabled)
        config.save(settings); MENU_UI.view_region:set_visibility(settings.enabled)
    elseif command == 'clear' then clear()
    elseif command == 'style' and view then require('menu/views/shared_style').open(view)
    else windower.add_to_chat(207, '[Enemylist] //enemylist show | hide | toggle | clear | style') end
end)
init()
