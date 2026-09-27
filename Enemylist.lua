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
function get_save_setting(key) return settings.values[tostring(key):lower()] end
function set_character_save_setting(_, _, key, value)
    key = tostring(key):lower()
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

local failed_debuff_messages = {
    [75] = true,  -- no effect
    [85] = true,  -- resisted
    [284] = true, -- resisted (additional target)
    [653] = true, -- immunobreak
    [654] = true, -- immunobreak (additional target)
    [655] = true, -- completely resisted
    [656] = true, -- completely resisted (additional target)
}

-- Absorb stat spells do not expose a status in Windower's spell resources.
-- Their success message identifies the matching Down effect on the target.
local absorb_effects = {
    [242] = {debuff_id = 146, buff_id = 90, message = 533},  -- Absorb-ACC
    [266] = {debuff_id = 136, buff_id = 119, message = 329}, -- Absorb-STR
    [267] = {debuff_id = 137, buff_id = 120, message = 330}, -- Absorb-DEX
    [268] = {debuff_id = 138, buff_id = 121, message = 331}, -- Absorb-VIT
    [269] = {debuff_id = 139, buff_id = 122, message = 332}, -- Absorb-AGI
    [270] = {debuff_id = 140, buff_id = 123, message = 333}, -- Absorb-INT
    [271] = {debuff_id = 141, buff_id = 124, message = 334}, -- Absorb-MND
    [272] = {debuff_id = 142, buff_id = 125, message = 335}, -- Absorb-CHR
}

-- Windower's spell resources omit status metadata for the Poisonga line.
local spell_debuff_overrides = {
    [112] = {id = 156, duration = 12}, -- Flash
    [225] = {id = 3, duration = 90},  -- Poisonga
    [226] = {id = 3, duration = 120}, -- Poisonga II
    [227] = {id = 3, duration = 60},  -- Poisonga III
    [228] = {id = 3, duration = 60},  -- Poisonga IV
    [229] = {id = 3, duration = 60},  -- Poisonga V
}

local function applied_debuff(spell_id, result)
    spell_id = tonumber(spell_id)
    if not spell_id then return nil end
    local message = tonumber(result.message)
    if failed_debuff_messages[message] then return nil end
    if tonumber(result.param) == 1 and tonumber(result.reaction) == 1 then return nil end -- blink/shadow

    local absorb = absorb_effects[spell_id]
    if absorb then
        if message == absorb.message then return absorb.debuff_id, 60 end
        return nil
    end

    local override = spell_debuff_overrides[spell_id]
    if override then return override.id, override.duration end

    local spell = resources.spells[spell_id]
    local effect = spell and tonumber(spell.status)
    local targets = spell and spell.targets
    local targets_enemy = type(targets) == 'table' and targets.contains and targets:contains('Enemy')
        or bit.band(tonumber(targets) or 0, 32) ~= 0
    if effect and effect > 0 and targets_enemy then
        return effect, tonumber(spell.duration) or 60
    end
end

local function applied_absorb_buff(spell_id, result)
    local absorb = absorb_effects[tonumber(spell_id)]
    local message = tonumber(result.message)
    if not absorb or message ~= absorb.message or failed_debuff_messages[message] then return nil end
    if tonumber(result.param) == 1 and tonumber(result.reaction) == 1 then return nil end
    return absorb.buff_id, 60
end

local function applied_spell_buff(spell_id, result)
    spell_id = tonumber(spell_id)
    if not spell_id or absorb_effects[spell_id] then return nil end
    local message = tonumber(result.message)
    if failed_debuff_messages[message] then return nil end
    if tonumber(result.param) == 1 and tonumber(result.reaction) == 1 then return nil end

    local spell = resources.spells[spell_id]
    local effect = spell and tonumber(spell.status)
    local effect_type = effect and RESOURCES:E('buff_types', effect)
    if effect_type and effect_type.type == 'Buff' then
        return effect, tonumber(spell.duration) or 60
    end
end

windower.register_event('action', function(action)
    if not update_player() then return end
    local source = mob_by_id(action.actor_id)
    local source_is_party = party_ids[action.actor_id]
    local source_entry
    for _, target in ipairs(action.targets or {}) do
        if party_ids[target.id] then source_entry = track(source) or source_entry end
        local entry = ACTOR_LIB.enemy[target.id]
        if source_is_party then entry = track(mob_by_id(target.id)) or entry end
        for _, result in ipairs(target.actions or {}) do
            if action.category == 4 then
                if entry then
                    local effect, duration = applied_debuff(action.param, result)
                    if effect then
                        entry.debuffs[effect] = {id = effect, end_time = os.time() + duration}
                    end
                    local buff, buff_duration = applied_spell_buff(action.param, result)
                    if buff then
                        entry.buffs[buff] = {id = buff, end_time = os.time() + buff_duration}
                    end
                end
                if source_entry then
                    local effect, duration = applied_absorb_buff(action.param, result)
                    if effect then
                        source_entry.buffs[effect] = {id = effect, end_time = os.time() + duration}
                    end
                end
            end
            if entry then
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
    if entry and (message == 204 or message == 206) then
        entry.debuffs[effect] = nil
        entry.buffs[effect] = nil
        refresh_view()
    end
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
