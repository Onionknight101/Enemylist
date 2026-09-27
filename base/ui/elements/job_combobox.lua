local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

local job_list = RESOURCES:ENL('jobs')
--remove 'Monipulator' from job list
for i=#job_list,1,-1 do
    if job_list[i]=='Monipulator' then
        table.remove(job_list,i)
    end
end

return function(setting)
    local width = setting.width or 120
    local height = defaults.standard_height*2
    local dropdrown_height = defaults.standard_height

    local selected_index = setting.default_index or -1
    local value = setting.value
    local on_change = setting.on_change

    local dropdown_open = false
    local dropdown_items = {}
    local dropdown_right = (setting.anchor and setting.anchor.x) or 0
    local dropdown_region = nil

    local pre_job_text = setting.job_type and setting.job_type~='' and setting.job_type..': ' or ''

    if selected_index == -1 and value ~=nil then
        local c_value = value
        if type(value) == 'function' then
            c_value = value()
        end
        --get index from options
        for i, option in ipairs(job_list) do
            if option == c_value then
                selected_index = i
                break
            end
        end
    end

    local bg = images_prim.new()
    bg:set_pos(0, 0)
    bg:set_size(width, height)
    bg:set_color(defaults.element_color[1], defaults.element_color[2], defaults.element_color[3], defaults.element_color[4])
    bg:set_fit(false)
    -- bg:show()

    local image_region = ui.create_imageless_region({
        width = defaults.standard_width*2,
        height = defaults.standard_height*2,
        bg_color = mathFunctions.get_color_set_alpha(defaults.border_color,0),
        draggable = false,
    })
    image_region:add(ui.create_image({
        width = defaults.standard_width*2, height = height,
        path = windower.addon_path .. 'media/ui/checkbox_unchecked.png'
    }))
    
    image_region:add(ui.create_image({
        width = defaults.standard_width*2, height = height,
        path = windower.addon_path .. 'media/jobs/'..setting.job..'.png'
    }))

    local txt_prim = texts_prim.new(job_list[selected_index] or '', {
        x = image_region.width, y = 0,
        text = {
            font = 'Arial',
            size = defaults.font_size*1.5,
            red = 255, green = 255, blue = 255,
        },
        flags = {draggable = false},
        bg = {visible = false},
    })
    txt_prim:set_text(pre_job_text .. job.get_long_name[setting.job])

    local arrow = images_prim.new()
    arrow:set_pos(width - (defaults.standard_width*2), 0)
    arrow:set_size(defaults.standard_width*2, height - 1)
    arrow:set_path(windower.addon_path .. 'media/ui/arrow_down.png')
    arrow:set_fit(false)
    -- arrow:show()

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
        value = value,
        selected_index = selected_index,
        press_index = -1,
        extra = setting.extra,
        dropdown_width = 150,
        name = setting.name or nil,
    })

    combo:add(bg)
    combo:add(image_region)
    combo:add(txt_prim)
    combo:add(arrow)

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
        local item_right = dropdown_right
        if item_right == 0 then
            item_right = combo.x 
        end
        dropdown_region = ui.create_imageless_region({
            x = item_right-combo.dropdown_width,
            y = combo.y,
            width = combo.dropdown_width,
            height = dropdrown_height* #job_list,
            bg_color = mathFunctions.get_color_set_alpha(defaults.border_color,0),
            draggable = false,
        })
        ui.elements:add_to_root(dropdown_region)

        -- print('created dropdown',#job_list, dropdown_region.x, dropdown_region.y, dropdown_region.width, dropdown_region.height)
        for i = 1, #job_list do
            local item_y =  (i -1) * dropdrown_height

            local item_text = texts_prim.new(job_list[i], {
                x =  6,
                y = item_y - 1,
                text = {font = 'Arial', size = 10, red = 0, green = 0, blue = 0},
                bg = {visible = false},
            })

            dropdown_region:add(item_text)
        end

        local item_bg = images_prim.new()
        -- item_bg:set_pos(combo.x, item_y)
        -- item_bg:set_size(combo.width, combo.height)
        item_bg:set_pos(0, 0)
        item_bg:set_size(combo.dropdown_width, dropdrown_height*#job_list)
        item_bg:set_color(220, 220, 220, 255)
        item_bg:set_fit(false)
        -- item_bg:show()
        dropdown_region:add(item_bg)

        dropdown_region:hide()
    end
    create_dropdown()


    local function show_dropdown()
        dropdown_open = true

        local item_right = (setting.anchor and setting.anchor:get_x()) or 0
        if item_right == 0 then
            item_right = combo:get_absolute_x() 
        end
        
        dropdown_region:set_position(item_right-combo.dropdown_width, combo:get_absolute_y())
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

    local function select(index)
        if index ~= combo.selected_index then
            combo.selected_index = index
            combo.txt_obj:set_text(pre_job_text .. job_list[index] or '')

            image_region:get_last_child():set_image(windower.addon_path .. 'media/jobs/'..job.get_short_name[job_list[index]]..'.png')

            if on_change then
                on_change(index, job.get_short_name[job_list[index]],job_list[index],combo.extra)
            end
        end
    end

    function combo:mouse_event(type, mx, my, delta)
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
            for i = 1, #job_list do
                local o_i = iy+ (i -1) * dropdrown_height
                if mx >= ix and mx <= ix + iw and my >= o_i and my <= o_i + dropdrown_height then
                    if(type==1) then 
                        ui.elements:press(self.id)
                        combo.press_index = i
                    elseif(type==2 and combo.press_index == i) then
                        ui.elements:unpress()
                        combo.press_index = -1
                        select(i)
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

    function combo:set_selected_index(index)
        if job_list[index] then
            self.selected_index = index
            combo.txt_obj:set_text(pre_job_text .. job_list[index])
            image_region:get_last_child():set_image(windower.addon_path .. 'media/jobs/'..job.get_short_name[job_list[index]]..'.png')
        end
    end

    function combo:set_selected_value(value)
        local index = tableFunctions.index_of(job_list, value)
        self.selected_index = index
        
        if index then
            self.selected_index = index
            combo.txt_obj:set_text(pre_job_text .. job_list[index])
            image_region:get_last_child():set_image(windower.addon_path .. 'media/jobs/'..job.get_short_name[job_list[index]]..'.png')
        else
            self.selected_index = 0
            combo.txt_obj:set_text(pre_job_text .. job_list[1])
            image_region:get_last_child():set_image(windower.addon_path .. 'media/jobs/'..job.get_short_name[job_list[1]]..'.png')
        end
    end

    function combo:set_short_value(value)
        local long_val = job.get_long_name[value]
        local index = tableFunctions.index_of(job_list, long_val)
        self.selected_index = index
        
        if index then
            self.selected_index = index
            combo.txt_obj:set_text(pre_job_text .. job_list[index])
            image_region:get_last_child():set_image(windower.addon_path .. 'media/jobs/'..job.get_short_name[job_list[index]]..'.png')
        else
            self.selected_index = 0
            combo.txt_obj:set_text(pre_job_text .. job_list[1])
            image_region:get_last_child():set_image(windower.addon_path .. 'media/jobs/'..job.get_short_name[job_list[1]]..'.png')
        end
    end

    function combo:get_selected()
        return self.selected_index, job_list[self.selected_index]
    end

    function combo:get_selected_index()
        return self.selected_index
    end

    function combo:get_selected_long_value()
        return job_list[self.selected_index]
    end

    function combo:get_selected_short_value()
        return job.get_short_name[job_list[self.selected_index]]
    end

    function combo:set_size(w, h)
        self.width = w
        self.height = h
        bg:set_size(w, h)
        arrow:set_pos(w - (defaults.standard_width*2), 0)
        arrow:set_size(defaults.standard_width*2 , h - 1)
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
        arrow:set_pos(self.width - (defaults.standard_width*2), 0)
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