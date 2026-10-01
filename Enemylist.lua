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
ACTOR_LIB = {player = {}, party = {}, pet = {}, enemy = {}}
LIBRARY_STRUCTURE = {}
RESOURCES = {}
EVENT_TRIGGER = {}
MENU_UI = {}
buff = {}
local buff_types = require('base/res/buff_types')
local refresh_view = function() end
local party_ids = {}
local geomancy_by_id = {}
local function geomancy_state(id)
    id = tonumber(id)
    if not id then return {} end
    geomancy_by_id[id] = geomancy_by_id[id] or {}
    return geomancy_by_id[id]
end
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
local function has_status(statuses, wanted)
    for _, status in pairs(statuses or {}) do
        local id = type(status) == 'table' and status.id or status
        if tonumber(id) == wanted then return true end
    end
    return false
end

local function position_distance(left, right)
    if not left or not right then return nil end
    local lx, ly, lz = tonumber(left.x), tonumber(left.y), tonumber(left.z)
    local rx, ry, rz = tonumber(right.x), tonumber(right.y), tonumber(right.z)
    if not lx or not ly or not lz or not rx or not ry or not rz then return nil end
    local dx, dy, dz = lx - rx, ly - ry, lz - rz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function update_player()
    local player = windower.ffxi.get_player()
    local info = windower.ffxi.get_info()
    if not player or not info or not info.logged_in then return false end
    local player_mob = windower.ffxi.get_mob_by_id(player.id)
    ACTOR_LIB.player = {
        id = player.id, name = player.name, zone = info.zone,
        x = player_mob and player_mob.x, y = player_mob and player_mob.y,
        z = player_mob and player_mob.z, buffs = player.buffs or {},
        geomancy = geomancy_state(player.id),
    }
    ACTOR_LIB.party = {}
    ACTOR_LIB.pet = {}
    party_ids = {[player.id] = true}
    for key, member in pairs(windower.ffxi.get_party() or {}) do
        if type(member) == 'table' and member.mob then
            local mob = member.mob
            party_ids[mob.id] = true
            if tostring(key):match('^p[0-5]$') then
                local entry = {
                    id = mob.id, name = mob.name, index = mob.index,
                    x = mob.x, y = mob.y, z = mob.z, hpp = mob.hpp,
                    buffs = mob.id == player.id and (player.buffs or {}) or {},
                    geomancy = geomancy_state(mob.id),
                    has_pet = false, pet_id = -1,
                }
                local pet_index = tonumber(mob.pet_index)
                local pet = pet_index and pet_index > 0
                    and windower.ffxi.get_mob_by_index(pet_index) or nil
                if pet and pet.id then
                    entry.has_pet = true
                    entry.pet_id = pet.id
                    ACTOR_LIB.pet[pet.id] = {
                        id = pet.id, index = pet.index, name = pet.name,
                        x = pet.x, y = pet.y, z = pet.z, hpp = pet.hpp,
                        model = pet.model_id,
                    }
                end
                ACTOR_LIB.party[#ACTOR_LIB.party + 1] = entry
                if mob.id == player.id then
                    ACTOR_LIB.player.has_pet = entry.has_pet
                    ACTOR_LIB.player.pet_id = entry.pet_id
                end
            end
        end
    end

    -- Some clients do not expose another party member's pet_index reliably.
    -- A Luopan has a dedicated model range, so associate an unlinked live one
    -- with the nearest party member whose last successful spell was Geo-*.
    local claimed = {}
    for _, source in ipairs(ACTOR_LIB.party) do
        if source.has_pet then claimed[source.pet_id] = true end
    end
    for _, source in ipairs(ACTOR_LIB.party) do
        if not source.has_pet and source.geomancy and source.geomancy.luopan then
            local nearest, nearest_distance
            for _, candidate in pairs(windower.ffxi.get_mob_array() or {}) do
                local model = tonumber(candidate.model_id)
                local hpp = tonumber(candidate.hpp)
                if candidate.id and not claimed[candidate.id]
                    and model and model >= 2850 and model <= 2865
                    and (hpp == nil or hpp > 0) then
                    local candidate_distance = position_distance(source, candidate)
                    if candidate_distance and (not nearest_distance
                        or candidate_distance < nearest_distance) then
                        nearest, nearest_distance = candidate, candidate_distance
                    end
                end
            end
            if nearest then
                source.has_pet, source.pet_id = true, nearest.id
                claimed[nearest.id] = true
                ACTOR_LIB.pet[nearest.id] = {
                    id = nearest.id, index = nearest.index, name = nearest.name,
                    x = nearest.x, y = nearest.y, z = nearest.z,
                    hpp = nearest.hpp, model = nearest.model_id,
                }
                if source.id == player.id then
                    ACTOR_LIB.player.has_pet = true
                    ACTOR_LIB.player.pet_id = nearest.id
                end
            end
        end
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
    local entry = ACTOR_LIB.enemy[mob.id] or {
        id = mob.id, buffs = {}, aura_buffs = {}, debuffs = {},
        event_buffs = {}, event_debuffs = {},
    }
    entry.name, entry.index, entry.hpp = mob.name, mob.index, mob.hpp
    entry.claim, entry.status, entry.zone = mob.claim_id, mob.status, ACTOR_LIB.player.zone
    entry.x, entry.y, entry.z = mob.x, mob.y, mob.z
    ACTOR_LIB.enemy[mob.id] = entry
    return entry
end
local function mob_by_id(id) return windower.ffxi.get_mob_by_id(id) end

local function distance(left, right)
    return position_distance(left, right)
end

-- Positional geomancy effects are absent from an enemy's normal status list.
-- Derive them from the live Indi caster or Luopan position instead.
function buff.enemy_aura_list(entry)
    local result, timers, seen = {}, {}, {}
    local now = os.time()
    local function add(id, end_time)
        id = tonumber(id)
        if not id or id <= 0 or id == 255 or seen[id] then return end
        seen[id] = true
        result[#result + 1] = id
        timers[#timers + 1] = end_time or (now + 5)
    end
    for _, source in ipairs(ACTOR_LIB.party or {}) do
        local geo = source.geomancy or {}
        local indi = geo.indi
        local indi_info = indi and RESOURCES:E('buff_types', indi.status)
        local indi_distance = indi and distance(entry, source)
        local indi_range = indi and indi.is_boosted and 12.8 or 6.4
        if indi and tonumber(indi.end_time) and indi.end_time > now
            and indi_info and indi_info.type == 'Debuff'
            and indi_distance and indi_distance <= indi_range then
            add(indi.status, indi.end_time)
        end

        local luopan = geo.luopan
        local luopan_info = luopan and RESOURCES:E('buff_types', luopan.status)
        local pet = source.has_pet and ACTOR_LIB.pet[source.pet_id] or nil
        local pet_hpp = pet and tonumber(pet.hpp)
        local pet_alive = pet and (pet_hpp == nil or pet_hpp > 0)
        local luopan_distance = pet and distance(entry, pet)
        local luopan_range = luopan and luopan.is_boosted and 12.8 or 6.4
        if luopan and luopan_info and luopan_info.type == 'Debuff'
            and pet_alive
            and luopan_distance and luopan_distance <= luopan_range then
            local end_time = tonumber(luopan.end_time)
            add(luopan.status, end_time and end_time > now and end_time or now + 5)
        end
    end
    return result, timers
end

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

local function is_geomancy_spell(spell_id, spell)
    spell_id = tonumber(spell_id)
    if spell_id and spell_id >= 768 and spell_id <= 827 then return true end
    local type_name = spell and tostring(spell.type):lower() or ''
    local skill_name = spell and tostring(spell.skill):lower() or ''
    return type_name == 'geomancy' or skill_name == 'geomancy'
        or tonumber(spell and spell.skill) == 44
end

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
    if is_geomancy_spell(spell_id, spell) then return nil end
    local effect = spell and tonumber(spell.status)
    local targets = spell and spell.targets
    local targets_enemy = type(targets) == 'table' and targets.contains and targets:contains('Enemy')
        or bit.band(tonumber(targets) or 0, 32) ~= 0
    if effect and effect > 0 and targets_enemy then
        return effect, tonumber(spell.duration) or 60
    end
end

local function result_succeeded(result)
    local message = tonumber(result and result.message)
    if not result or failed_debuff_messages[message] then return false end
    return not (tonumber(result.param) == 1 and tonumber(result.reaction) == 1)
end

local function record_geomancy(action)
    if tonumber(action.category) ~= 4 or not party_ids[action.actor_id] then return end
    local spell_id = tonumber(action.param)
    local spell = resources.spells[spell_id]
    if not spell or not is_geomancy_spell(spell_id, spell) then return end
    local status = tonumber(spell.status)
    -- Windower omits status on several Geo-* records. The matching Indi-*
    -- spell is exactly 30 IDs earlier and carries the same aura status.
    if not status and spell_id and spell_id >= 798 and spell_id <= 827 then
        local indi_spell = resources.spells[spell_id - 30]
        status = indi_spell and tonumber(indi_spell.status) or nil
    end
    if not status or status <= 0 then return end

    local name = tostring(spell.en or spell.name or ''):lower()
    local is_indi = spell_id >= 768 and spell_id <= 797
        or name:find('indi-', 1, true) == 1
    local source_state = geomancy_state(action.actor_id)
    local source_is_player = tonumber(action.actor_id) == tonumber(ACTOR_LIB.player.id)
    local boosted = source_is_player and has_status(ACTOR_LIB.player.buffs, 508) or false
    local duration = tonumber(spell.duration) or 180
    for _, target in ipairs(action.targets or {}) do
        for _, result in ipairs(target.actions or {}) do
            if result_succeeded(result) then
                if is_indi then
                    local origin_id = party_ids[target.id] and target.id or action.actor_id
                    geomancy_state(origin_id).indi = {
                        id = tonumber(spell.id) or tonumber(action.param),
                        status = status, end_time = os.time() + duration,
                        is_boosted = boosted,
                    }
                else
                    local info = RESOURCES:E('buff_types', status)
                    source_state.luopan = {
                        id = tonumber(spell.id) or tonumber(action.param),
                        status = status, end_time = os.time() + duration,
                        is_buff = info and info.type == 'Buff' or false,
                        is_boosted = boosted,
                    }
                end
                return
            end
        end
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
    record_geomancy(action)
    local source_entry
    for _, target in ipairs(action.targets or {}) do
        if party_ids[target.id] then
            source_entry = track(source) or source_entry
        end
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
    ACTOR_LIB.party = {}
    ACTOR_LIB.pet = {}
    geomancy_by_id = {}
    refresh_view()
end
local function print_aura_state()
    update_player()
    windower.add_to_chat(207, '[Enemylist] aura sources: '
        .. tostring(#(ACTOR_LIB.party or {})))
    for _, source in ipairs(ACTOR_LIB.party or {}) do
        local geo = source.geomancy or {}
        local indi, luopan = geo.indi, geo.luopan
        local pet = source.has_pet and ACTOR_LIB.pet[source.pet_id] or nil
        windower.add_to_chat(207, string.format(
            '[Enemylist] %s indi=%s geo=%s pet=%s hpp=%s model=%s',
            tostring(source.name or source.id),
            tostring(indi and indi.status or '-'),
            tostring(luopan and luopan.status or '-'),
            tostring(source.pet_id or '-'),
            tostring(pet and pet.hpp or '-'),
            tostring(pet and pet.model or '-')))
    end
    local shown = 0
    for _, enemy in pairs(ACTOR_LIB.enemy or {}) do
        local ids = buff.enemy_aura_list(enemy)
        windower.add_to_chat(207, '[Enemylist] '
            .. tostring(enemy.name or enemy.id) .. ' aura='
            .. table.concat(ids, ','))
        shown = shown + 1
        if shown >= 5 then break end
    end
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
    elseif command == 'aura' then print_aura_state()
    elseif (command == 'style' or command == 'settings') and view then require('menu/views/shared_style').open(view)
    else windower.add_to_chat(207, '[Enemylist] //enemylist show | hide | toggle | clear | aura | style | settings') end
end)
init()
