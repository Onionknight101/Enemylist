local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

return function(setting)
    local width = setting.width or 120
    local height = defaults.standard_height
    local options = setting.options or {}
    local selected_index = setting.default_index or -1
    local value = setting.value
    local check_func = setting.check_func
    local on_change = setting.on_change

    if check_func and type(check_func) == 'function' then
        value = check_func()
    end

    local dropdown_open = false
    local dropdown_items = {}
    local dropdown_right = (setting.anchor and setting.anchor.x) or 0
    local dropdown_region = nil
    local dropdown_bg = nil
    local dropdown_label = {}

    local scroll_index = 0
    local max_size = setting.max_size or 10

    if selected_index == -1 and value ~=nil then
        local c_value = value
        if type(value) == 'function' then
            c_value = value()
        end
        --get index from options
        for i, option in ipairs(options) do
            if option == c_value then
                selected_index = i
                break
            end
        end
    end

    local bg = images_prim.new()
    bg:set_pos(0, 2)
    bg:set_size(width, height)
    bg:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
    bg:set_fit(false)

    local txt_prim = texts_prim.new(options[selected_index] or '', {
        x = 6,
        y = 1,
        text = {
            font = 'Arial',
            size = 10,
            red = 255, green = 255, blue = 255,
        },
        flags = {draggable = false},
        bg = {visible = false},
    })

    local arrow = images_prim.new()
    arrow:set_pos(width - (defaults.standard_width-1), 2)
    arrow:set_size(defaults.standard_width-1, height - 1)
    arrow:set_path(windower.addon_path .. 'media/ui/arrow_down.png')
    arrow:set_fit(false)


    local combo = ui_base:new({
        id = id,
        type = 'combobox',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        width = width,
        height = height,
        txt_obj = txt_prim,
        visible = true,
        children = {},
        options = options,
        value = value,
        check_func = check_func,
        selected_index = selected_index,
        press_index = -1,
        extra = setting.extra,
        dropdown_width = setting.dropdown_width or width,
        using_base_dropdownwidth = setting.dropdown_width == nil,
        name = setting.name or nil,
    })

    combo:add(bg)
    combo:add(txt_prim)
    combo:add(arrow)

    combo.bg = bg


    --create a label that will be to the right side of the bg
    local label = ui.create_label({
        x = (setting.x or 0) + width + 4,
        y = setting.y or 0,
        text = setting.label,
        width = width,
        height = defaults.standard_height,
        align = 'center',
    })
    combo.label = label
    combo:add(label)

    if setting.label == '' or setting.label == nil then
        label:hide()
    end

    local function create_dropdown()
        if dropdown_region then
            dropdown_region:destroy()
        end
        local item_right = dropdown_right
        if item_right == 0 then
            item_right = combo.x 
        end
        dropdown_region = ui.create_imageless_region({
            x = item_right-combo.dropdown_width,
            y = combo.y,
            width = combo.dropdown_width,
            height = combo.height * #combo.options,
            bg_color = mathFunctions.get_color_set_alpha(defaults.border_color,0),
            draggable = false,
        })
        ui.elements:add_to_root(dropdown_region)

        -- print('created dropdown',#options, dropdown_region.x, dropdown_region.y, dropdown_region.width, dropdown_region.height)
        for i = 1, #combo.options do
            local item_y =  (i -1) * height

            dropdown_label[i] = texts_prim.new(combo.options[i], {
                x =  6, 
                y = item_y - 1,
                text = {font = 'Arial', size = 10, red = 0, green = 0, blue = 0},
                bg = {visible = false},
            })

            dropdown_region:add(dropdown_label[i])
        end

        dropdown_bg = images_prim.new()
        -- dropdown_bg:set_pos(combo.x, item_y)
        -- dropdown_bg:set_size(combo.width, combo.height)
        dropdown_bg:set_pos(0, 0)
        dropdown_bg:set_size(combo.dropdown_width, combo.height*#combo.options)
        dropdown_bg:set_color(220, 220, 220, 255)
        dropdown_bg:set_fit(false)
        dropdown_region:add(dropdown_bg)

        dropdown_region:hide()
    end
    
    local function refreshscroll_dropdown()
        local dropdown_size = math.min(max_size, #combo.options)
        for i = 1, dropdown_size do
            if not combo.options[i+scroll_index] then
                break
            end
            dropdown_label[i]:set_text(combo.options[i+scroll_index])
        end

        dropdown_region:set_size(combo.dropdown_width, combo.height * dropdown_size)
        dropdown_bg:set_size(combo.dropdown_width, combo.height*dropdown_size)
    end

    local function create_scrollable_dropdown()
        if dropdown_region then
            dropdown_region:destroy()
        end
        local item_right = dropdown_right
        if item_right == 0 then
            item_right = combo.x 
        end

        local dropdown_size = math.min(max_size, #combo.options)
        dropdown_region = ui.create_imageless_region({
            x = item_right-combo.dropdown_width,
            y = combo.y,
            width = combo.dropdown_width,
            height = combo.height * dropdown_size,
            bg_color = mathFunctions.get_color_set_alpha(defaults.border_color,0),
            draggable = false,
        })
        ui.elements:add_to_root(dropdown_region)

        -- print('created dropdown',#options, dropdown_region.x, dropdown_region.y, dropdown_region.width, dropdown_region.height)
        for i = 1, dropdown_size do
            local entry = combo.options[i+scroll_index]

            if not entry then
                break
            end
            local item_y =  (i -1) * height

            dropdown_label[i] = texts_prim.new(entry, {
                x =  6, 
                y = item_y - 1,
                text = {font = 'Arial', size = 10, red = 0, green = 0, blue = 0},
                bg = {visible = false},
            })

            dropdown_region:add(dropdown_label[i])
        end

        dropdown_bg = images_prim.new()
        -- dropdown_bg:set_pos(combo.x, item_y)
        -- dropdown_bg:set_size(combo.width, combo.height)
        dropdown_bg:set_pos(0, 0)
        dropdown_bg:set_size(combo.dropdown_width, combo.height*dropdown_size)
        dropdown_bg:set_color(220, 220, 220, 255)
        dropdown_bg:set_fit(false)
        dropdown_region:add(dropdown_bg)

        dropdown_region:hide()
    end


    create_scrollable_dropdown()


    local function show_dropdown()
        dropdown_open = true

        local item_right = (setting.anchor and setting.anchor:get_x()) or 0
        if item_right == 0 then
            item_right = combo:get_absolute_x() 
        end
        
        dropdown_region:set_position(item_right-combo.width, combo:get_absolute_y())
        dropdown_region:show()
    end

    local function hide_dropdown()
        dropdown_open = false
        dropdown_region:hide()
    end

    local function toggle_dropdown()
        if dropdown_open then
            hide_dropdown()
        else
            show_dropdown()
        end
    end

    local function set_label(text_)
        if setting.label == '' or setting.label == nil then
            setting.label = ''
            label:hide()
        else
            label:show()
        end
        combo.label:set_text(text_)
    end

    local function select(index)
        if index ~= combo.selected_index then
            combo.selected_index = index
            combo.txt_obj:set_text(combo.options[index] or '')
            if on_change then
                on_change(index, combo.options[index],combo.extra)
            end
        end
    end

    function combo:mouse_event(type, mx, my, delta)
        --type 10 is scroll, delta is direction
        --is this inside the combo box?
        if mx >= combo.x and mx <= combo.x + combo.width and my >= combo.y and my <= combo.y + combo.height then
            if(type == 1) then
                bg:set_color(defaults.pressed_color[1], defaults.pressed_color[2], defaults.pressed_color[3], defaults.pressed_color[4])
                ui.elements:press(self.id)
                return true,self.id
            elseif(ui.elements:is_pressed(self.id) and type == 2) then
                ui.elements:unpress()
                combo.press_index = -1
                return true,self.id
            end
        elseif dropdown_open then
            local ix, iy = dropdown_region:get_relative_position()
            local iw = dropdown_region.width
            local ih = dropdown_region.height
            for i = 1, #combo.options do
                local o_i = iy+ (i -1) * height
                if mx >= ix and mx <= ix + iw and my >= o_i and my <= o_i + height then
                    if(type==1) then 
                        ui.elements:press(self.id)
                        combo.press_index = i
                    elseif(type==2 and combo.press_index == i) then
                        ui.elements:unpress()
                        combo.press_index = -1
                        select(i+scroll_index)
                    elseif(type == 10) then
                        if delta > 0 then
                            scroll_index = math.max(0, scroll_index - 1)
                        else
                            scroll_index = math.min(#combo.options - max_size, scroll_index + 1)
                        end
                        refreshscroll_dropdown()
                        return true,self.id
                    end
                    return true,self.id
                end
            end

            return ui.elements:is_pressed(self.id),self.id
        end
        return false
    end

    function combo:unpress()
        if(ui.elements.focused == self.id) then
            toggle_dropdown()
        else
            hide_dropdown()
        end
        if dropdown_open ==true then
            bg:set_color(defaults.selected_color[1], defaults.selected_color[2], defaults.selected_color[3], defaults.selected_color[4])
        else
            bg:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
        end
    end

    function combo:set_options(new_options)
        if new_options == nil then new_options = {} end
        
        self.options = new_options
        self.selected_index = -1
        for i, option in ipairs(new_options) do
            if option == self.value then
                self.selected_index = i
                break
            end
        end
        create_dropdown()
        combo.txt_obj:set_text(new_options[self.selected_index] or '')
    end

    function combo:set_selected_index(index)
        if self.options[index] then
            self.selected_index = index
            combo.txt_obj:set_text(self.options[index])
        end
    end

    function combo:set_selected_value(value)
        self.value = value
        local index = tableFunctions.index_of(self.options, self.value)
        
        if index then
            self.selected_index = index
            combo.txt_obj:set_text(self.options[index])
        else
            self.selected_index = -1
            combo.txt_obj:set_text('')
        end
    end

    function combo:refresh(new_options)
        if new_options~=nil then 
            self.options = new_options 
            create_dropdown()
        end
        
        if self.check_func and type(self.check_func) == 'function' then
            self.value = self.check_func()
        end
        self:set_selected_value(self.value)
    end

    function combo:get_selected()
        return self.selected_index, self.options[self.selected_index]
    end

    function combo:get_selected_index()
        return self.selected_index
    end

    function combo:get_selected_value()
        return self.options[self.selected_index]
    end

    function combo:set_size(w, h)
        self.width = w
        self.height = h
        bg:set_size(w, h)
        arrow:set_pos(w - (defaults.standard_width - 1), 2)
        arrow:set_size(defaults.standard_width - 1, h - 1)
        if dropdown_region and self.using_base_dropdownwidth==true then
            self.dropdown_width = w
            dropdown_region:set_size(self.dropdown_width, h * #combo.options)
        end
    end

    function combo:clear()
        self.options = {}
        self.selected_index = -1
        combo.txt_obj:set_text('')
        hide_dropdown()
    end

    function combo:disable()
        self.disabled = true
        bg:alpha(100)
        arrow:alpha(100)
        combo.txt_obj:set_alpha(150)
    end

    function combo:enable()
        self.disabled = false
        bg:alpha(255)
        arrow:alpha(255)
        combo.txt_obj:set_alpha(255)
    end

    function combo:on_size_change()
        bg:set_size(self.width, self.height)
        arrow:set_pos(self.width - (defaults.standard_width-1), 2)
        if dropdown_region and self.using_base_dropdownwidth==true  then
            self.dropdown_width = self.width 
            dropdown_region:set_size(self.dropdown_width, self.height * #combo.options)
        end
    end

    function combo:on_position_change()
        dropdown_region:set_y(self.y)
    end

    function combo:on_destroy()
        dropdown_region:destroy()
    end

    combo:update_absolute_position()
    return combo
end