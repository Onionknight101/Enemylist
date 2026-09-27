-- ui_defaults.lua
-- Centrale plek voor standaardwaarden van UI-elementen

local defaults = {}

-- 📏 Afmetingen
defaults.standard_width = 16
defaults.standard_height = 16
defaults.standard_spacing = 6
defaults.standard_padding = 0
defaults.big_width = 16
defaults.big_height = 16

-- 🎨 Kleuren
defaults.bg_color = {30, 30, 30, 180 }
defaults.outline_color = {60, 60, 60, 255 }
defaults.element_color = { 80, 80, 80, 255 }
defaults.selected_color = { 50, 50, 50, 255 }
defaults.pressed_color = { 40, 40, 40, 255 }
defaults.fill_color = { 200, 60, 60, 255 }
defaults.border_color = { 120, 120, 120, 255 }

-- 🖋️ Tekststijl
defaults.font = 'Arial'
defaults.font_size = 12
defaults.text_color = { red = 255, 255, blue = 255, alpha = 255 }

-- 🖼️ Standaardpaden voor textures (indien gebruikt)
defaults.bg_texture = windower.addon_path .. 'media/ui/bar.png'        -- bijv. windower.addon_path .. 'media/bar_bg.png'
defaults.fill_texture = windower.addon_path .. 'media/ui/bar_fill_hp.png'      -- bijv. windower.addon_path .. 'media/bar_fill.png'
defaults.checkbox_off_texture = windower.addon_path .. 'media/ui/checkbox_unchecked.png'  -- bijv. windower.addon_path .. 'media/checkbox.png'
defaults.checkbox_on_texture = windower.addon_path .. 'media/ui/checkbox_checked.png'  -- bijv. windower.addon_path .. 'media/checkbox.png'
defaults.checkbox_play = windower.addon_path .. 'media/ui/checkbox_play.png'  -- bijv. windower.addon_path .. 'media/checkbox.png'
defaults.checkbox_pauze = windower.addon_path .. 'media/ui/checkbox_pauze.png'  -- bijv. windower.addon_path .. 'media/checkbox.png'
defaults.radio_off_texture = windower.addon_path .. 'media/ui/radio_off.png'  -- bijv. windower.addon_path .. 'media/checkbox.png'
defaults.radio_on_texture = windower.addon_path .. 'media/ui/radio_on.png'  -- bijv. windower.addon_path .. 'media/checkbox.png'

-- 📐 Padding en margins
defaults.padding = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2
}

-- 🔘 Checkbox
defaults.checkbox_size = { width = 12, height = 12 }
defaults.checkbox_spacing = 6  -- ruimte tussen checkbox en label


--editpanel
local ws = windower.get_windower_settings()
defaults.edit_panel = {
    width = 0.85 * ws.ui_x_res,
    height = 0.9 * ws.ui_y_res,
    x = 0,
    y = ws.ui_y_res * 0.05
}
defaults.side_panel = {
    width = 0.20 * ws.ui_x_res,
    height = 0.9 * ws.ui_y_res,
    x = 0.8 * ws.ui_x_res,
    y = ws.ui_y_res * 0.05
}

local min_width = 400
if defaults.side_panel.width< min_width then
    defaults.side_panel.width = min_width
    defaults.side_panel.x = ws.ui_x_res - min_width
end
return defaults
