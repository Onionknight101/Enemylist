-- ui_root.lua

local ui_root = {
    reference = {}, --reference only. dont modify directly
    focused = nil,
    pressed = nil,
    root = {}
}

function ui_root:add_to_root(element)
    table.insert(self.root, element)
    element:update_draw()
end

function ui_root:is_in_root(element)
    for _, e in ipairs(self.root) do
        if e == element then
            return true
        end
    end
    return false
end

function ui_root:print_all_in_root()
    local ret = 'Elements in root: '
    for _, e in ipairs(self.root) do
        ret = ret .. tostring(e.id) .. ' '
    end
    return ret
end

function ui_root:remove_from_root(id)
    for i, element in ipairs(self.root) do
        if element.id == id then
            table.remove(self.root, i)
            element:update_draw()
            break
        end
    end
end

function ui_root:pass_mouse_event(type, mx, my, delta)
    local function test_element(element)
        if not element then return false end
        if element.visible == false then return false end
        
        -- print('Testing element id '..tostring(element.id)..' for mouse event at ('..mx..','..my..') with type '..type)
        -- Als het element zelf een mouse_event handler heeft, probeer die eerst
        if element.mouse_event then
            local ret, ret_id = element:mouse_event(type, mx, my, delta)
            -- print('Element id '..tostring(element.id)..' mouse_event returned: '..tostring(ret))
            if ret == true then
                -- print('Element handled mouse event, id: '..tostring(ret_id))
                if type ~= 0 and self.focused and self.focused ~= ret_id then
                    -- If focused but not pressed, unpress the focused element
                    ui_root:unfocus(ret_id)
                end
                return true, ret_id
            end
        end

        -- Controleer children (recursief) als het element geen mouse_event of het niet afhandelde
        if element.children then
            --reverse check children, so the topmost element gets priority
            for i = #element.children, 1, -1 do
                local child = element.children[i]
                if child then
                    local handled, cid = test_element(child)
                    if handled then
                        return true, cid
                    end
                end
            end
        end

        return false
    end

    --check root elements. topmost element gets priority, so reverse order
    for i = #self.root, 1, -1 do
        local element = self.root[i]
        if element.type and element.type == 'composed' then
            element = element.main_ui
        end

        if(element~=nil) then
            local handled, ret_id = test_element(element)
            if handled then
                --check if button was released
                if type ==2 and self.focused and self.focused ~= ret_id then
                    -- If handled element not the focussed element, unfocus the old element
                    ui_root:unfocus(ret_id)
                end
                return true
            end
        end
    end

    if type ==2 and self.focused then
        -- If no element responded with true, unfocus the old element
        ui_root:unfocus(nil)
    end

    --unpress if pressed
    if self.pressed and type ~= 0 then
        local pressed_element = self.reference[self.pressed]
        if pressed_element and pressed_element.unpress then
            print('Unpressing element id '..tostring(self.pressed))
            pressed_element:unpress()
        elseif self.focused then
            -- If focused but not pressed, unpress the focused element
            ui_root:unfocus(nil)
        end
        self.pressed = nil
        self.focused = nil
        return true
    end
    
    return false
end

function ui_root:add_ref(id, element)
    if id==nil then return end
    self.reference[id] = element
end

function ui_root:remove_ref(id)
    if id==nil then return end
    self.reference[id] = nil
end

function ui_root:get(id)
    return self.reference[id]
end

function ui_root:clear()
    for id in pairs(self.reference) do
        self:remove(id)
    end
end

function ui_root:set_focus(id)
    self.focused = id
end

function ui_root:get_focus()
    return self.focused and self.reference[self.focused] or nil
end

function ui_root:press(id)
    if(self.focused and id~=self.focused) then
        -- If focused but not pressed, unpress the focused element
        ui_root:unfocus(id)
    end
    self.pressed = id
    self.focused = id
end

function ui_root:unfocus(new_focused)
    local focused_element = self.reference[self.focused]
    self.focused = new_focused
    if focused_element and focused_element.unpress then
        focused_element:unpress()
    end
end

function ui_root:unpress()
    local pressed_element = self.reference[self.pressed]
    if pressed_element and pressed_element.unpress then
        pressed_element:unpress()
    end
    self.pressed = nil
end

function ui_root:is_pressed(id)
    return self.pressed == id
end

function ui_root:child_count()
    local count = 0
    for _, _ in pairs(self.reference) do
        count = count + 1
    end
    return count
end

function ui_root:print_all_child_ids()
    for id, _ in pairs(self.reference) do
        ui.print_success('Child ID: ' .. tostring(id))
    end
end

function ui_root:refresh()
    for _, element in pairs(self.reference) do
        if type(element.on_refresh) == "function" then
            element:on_refresh()
        end
    end
end

return ui_root
