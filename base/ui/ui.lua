 require('base/ui/prim/texts_prim')
require('base/ui/prim/images_prim')
local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')
local ui = {}

-- Container voor actieve elementen
ui.elements = require('base/ui/ui_root')

-- Genereer unieke ID
function ui.generate_id(pre_fix)
    pre_fix = pre_fix or 'ui_'
    return pre_fix .. tostring(os.clock()):gsub('%.', '') .. '_' .. tostring(math.random(10000, 99999))
end

-----------------------------------------------------
-- 🏷️ Elements
-----------------------------------------------------
ui.create_line = require('base/ui/elements/line')
ui.create_label = require('base/ui/elements/label')
ui.create_onion_label = require('base/ui/elements/onionlabel')
ui.create_bitmap_label = require('base/ui/elements/bitmaplabel')
ui.create_image_label = require('base/ui/elements/imagelabel')
ui.create_imagelabel = ui.create_image_label

ui.create_progressbar = require('base/ui/elements/progressbar')
ui.create_dynamic_label = require('base/ui/elements/dynamic_label')
ui.create_image = require('base/ui/elements/image')
ui.create_checkbox = require('base/ui/elements/checkbox')
ui.create_checkbox_group = require('base/ui/elements/checkbox_group')
ui.create_combobox = require('base/ui/elements/combobox')
ui.create_option_picker = require('base/ui/elements/option_picker')
ui.create_region = require('base/ui/elements/region')
ui.create_imageless_region = require('base/ui/elements/imageless_region')
ui.create_slider = require('base/ui/elements/slider')
ui.create_button = require('base/ui/elements/button')
ui.create_imagebutton = require('base/ui/elements/imagebutton')
ui.create_selector = require('base/ui/elements/selector')
ui.create_treeview = require('base/ui/elements/treeview')
ui.create_page_change = require('base/ui/elements/page_change')
ui.set_composed = require('base/ui/ui_composed')

-----------------------------------------------------
-- 🔁 Refresh dynamische elementen
-----------------------------------------------------
function ui.refresh_all()
    ui.elements:refresh()

end

-- Bereken de breedte van een tekst op basis van font metrics
function ui.get_text_width(text, font_name, font_size)
    font_name = font_name or defaults.font
    font_size = font_size or defaults.font_size
    local ok, metrics = pcall(require, 'base/ui/font_metrics/' .. font_name)
    if ok and metrics and type(metrics.text_width) == "function" then
        return metrics.text_width(text or "", font_size)
    end
    -- fallback: schatting
    local avg_char_width = font_size * 0.6
    return math.floor((text and #tostring(text) or 0) * avg_char_width)
end

-----------------------------------------------------
-- ❌ Clear alle UI-elementen
-----------------------------------------------------
function ui.clear()
    for _, element in pairs(ui.elements) do
        if type(element) == 'table' then
            if element.object then element.object:hide() end
            if element.bg then element.bg:hide() end
            if element.fill then element.fill:hide() end
        elseif type(element) == 'userdata' then
            element:hide()
        end
    end
    ui.elements = {}
end

-----------------------------------------------------
-- 🧾 Chat helpers
-----------------------------------------------------
function ui.print_info(msg)
    windower.add_to_chat(207, '[Actor UI] ' .. msg)
end

function ui.print_success(msg)
    windower.add_to_chat(200, '[Actor UI] ' .. msg)
end

function ui.print_error(msg)
    windower.add_to_chat(123, '[Actor UI] ' .. msg)
end

return ui
