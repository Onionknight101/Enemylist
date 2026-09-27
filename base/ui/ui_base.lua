local defaults = require('base/ui/ui_defaults')

local BaseUIObject = {}
BaseUIObject.__index = BaseUIObject

function BaseUIObject:new(s)
    local object =  s or {}
    setmetatable(object, self)
	
    object.base_x = s.base_x or 0
    object.base_y = s.base_y or 0
    object.x = 0
    object.y = 0
    object.layout_div_x = s.layout_div_x or 0
    object.layout_div_y = s.layout_div_y or 0
    object.width = s.width or 0
    object.height = s.height or 0
    object.visible = true
    object.is_currently_drawn = true
	object.layout = s.layout

    object.dragging = false

    -- Scroll waarden voor x en y
    object.scroll_x = 0
    object.scroll_y = 0
	
    -- Nieuwe toevoeging: lijst met child-objecten
    object.children = {}
    object.internal_children = {}

    object.auto_width = s.auto_width or false
    object.auto_height = s.auto_height or false
    --TODO: autowidth,autoheight
    --TODO: 
    --  type_left: 0 :: relative. x = base_x + parent.x - parent.scroll_x
    --          1 :: offset. x = offset.left + parent.x - parent.scroll_x
    --          2 :: scaled. x = parent.x + scale_x * (parent.width - offset.left - offset.right)

    --  type_right: 0 :: relative. width = width
    --          1 :: offset. width = parent.width - x -offset.right
    --          2 :: scaled. width = parent.width - (parent.width - offset.left - offset.right) * scale_w
    
    object.locked = false
    
    object.id = ui.generate_id(s.type)
    ui.elements:add_ref(object.id, object)
    if s.parent_id then
        object:set_parent(s.parent_id)
    end

    return object, object.id
end

function BaseUIObject:set_layout(layout)
    self.layout = layout
    self:update_absolute_position(true)
end

function BaseUIObject:set_scroll_offset(x, y)
    if (self.scroll_x == x and self.scroll_y == y) or (not x or not y) then return end

    self.scroll_x = x or 0
    self.scroll_y = y or 0
    return self:update_absolute_position(true) 
end

function BaseUIObject:set_position(x, y)
    if not self.base_x or not self.base_y or not x or not y then return end
    -- Alleen updaten als er echt iets verandert
    if self.base_x == x and self.base_y == y then
        return false
    end
    self.base_x = x
    self.base_y = y
    -- Controleer of parent een layout aan het toepassen is
    local change = self:update_absolute_position()
    -- if(change==false and self.on_position_change) then
    --     self:on_position_change()
    -- end
    return change
end

function BaseUIObject:resize(width, height)
    -- Alleen updaten als er echt iets verandert
    if self.width == width and self.height == height then
        return false
    end
    self.width = width
    self.height = height
    -- Controleer of parent een layout aan het toepassen is
    local change = self:update_absolute_position()
    -- if(change==false and self.on_size_change) then
    --     self:on_size_change()
    -- end
    return change
end

function BaseUIObject:set_size(width, height)
    return self:resize(width, height)
end

function BaseUIObject:set_width(width)
    return self:resize(width, self.height)
end

function BaseUIObject:set_height(height)
    return self:resize(self.width, height)
end

function BaseUIObject:set_x(x)
    return self:set_position(x, self.base_y)
end

function BaseUIObject:set_y(y)
    return self:set_position(self.base_x, y)
end

function BaseUIObject:add(element_id,extra)
    self:_add(element_id,extra)
    return element_id
end

function BaseUIObject:_add(element_id,extra)
    if type(element_id) ~= "string" then
        if element_id and element_id.id then
            element_id = element_id.id
        else
            -- Foutafhandeling: element_id is geen string en heeft geen id
            error("Invalid element_id: must be a string or an object with an id property. found: " .. tostring(element_id))
            return
        end
    end

    local el = ui.elements:get(element_id)
    if not el then return end

    el.extra_info = extra

    table.insert(self.children, el)
    el:set_parent(self)

    if el.update_absolute_position then el:update_absolute_position(true) end
    self:update_absolute_position(true)
end

--add at index
function BaseUIObject:add_at(element_id, index, extra)
    if type(element_id) ~= "string" then
        if element_id and element_id.id then
            element_id = element_id.id
        else
            -- Foutafhandeling: element_id is geen string en heeft geen id
            error("Invalid element_id: must be a string or an object with an id property. found: " .. tostring(element_id))
            return
        end
    end

    local el = ui.elements:get(element_id)
    if not el then return end

    el.extra_info = extra

    table.insert(self.children, index, el)
    el:set_parent(self)

    if el.update_absolute_position then el:update_absolute_position(true) end
    self:update_absolute_position(true)
end

function BaseUIObject:add_internal(element_id)
    if type(element_id) ~= "string" then
        if element_id and element_id.id then
            element_id = element_id.id
        else
            -- Foutafhandeling: element_id is geen string en heeft geen id
            error("Invalid internal element_id: must be a string or an object with an id property. found: " .. tostring(element_id))
            return
        end
    end
    local el = ui.elements:get(element_id)
    if not el then return end

    table.insert(self.internal_children, el)
    el:set_parent(self)

    self:update_absolute_position(true)
end

--add internal at index
function BaseUIObject:add_internal_at(element_id, index)
    if type(element_id) ~= "string" then
        if element_id and element_id.id then
            element_id = element_id.id
        else
            -- Foutafhandeling: element_id is geen string en heeft geen id
            error("Invalid internal element_id: must be a string or an object with an id property. found: " .. tostring(element_id))
            return
        end
    end
    local el = ui.elements:get(element_id)
    if not el then return end

    table.insert(self.internal_children, index, el)
    el:set_parent(self)
    self:update_absolute_position(true)
end

function BaseUIObject:set_parent(parent)
    if not parent or not parent.id then return end
    if self.parent_id == parent.id then return end

    self.parent_id = parent.id

    if self.visible == false then
         self:update_draw(false)
    else
        self:update_draw()
    end

    if parent and (parent.layout and parent.layout.apply) or (parent.auto_height or parent.auto_width) then
        parent:update_absolute_position(true)
    else
        self:update_absolute_position(true)
    end
end

function BaseUIObject:remove(element_id)
    if type(element_id) ~= "string" then
        if element_id and element_id.id then
            element_id = element_id.id
        else
            -- Foutafhandeling: element_id is geen string en heeft geen id
            print("Invalid internal element_id: must be a string or an object with an id property. found: " .. tostring(element_id),element_id.id)
            return
        end
    end

    for i, child in ipairs(self.children) do
        if child.id == element_id then
            --set invisible for hidden removal
            if child.set_visible then child:set_visible(false) end
            table.remove(self.children, i)
            break
        end
    end
    
    self:update_absolute_position(true)
end

function BaseUIObject:remove_internal(element_id)
    if type(element_id) ~= "string" then
        if element_id and element_id.id then
            element_id = element_id.id
        else
            -- Foutafhandeling: element_id is geen string en heeft geen id
            error("Invalid internal element_id: must be a string or an object with an id property. found: " .. tostring(element_id))
            return
        end
    end
    for i, child in ipairs(self.internal_children) do
        if child.id == element_id then
            --set invisible for hidden removal
            if child.set_visible then child:set_visible(false) end
            table.remove(self.internal_children, i)
            break
        end
    end
end

function BaseUIObject:set_auto_width(auto_width_)
    self.auto_width = auto_width_
    if self.parent and (self.parent.layout and self.parent.layout.apply) or (self.parent.auto_height or self.parent.auto_width) then
        self.parent:update_absolute_position(true)
    else
        self:update_absolute_position(true)
    end
end

function BaseUIObject:set_auto_height(auto_height_)
    self.auto_height = auto_height_
    if self.parent and (self.parent.layout and self.parent.layout.apply) or (self.parent.auto_height or self.parent.auto_width) then
        self.parent:update_absolute_position(true)
    else
        self:update_absolute_position(true)
    end
end

function BaseUIObject:refresh_autosize(self)
    local updated_size = false

    if(self.auto_width) then 
        updated_size = self:refresh_width() or updated_size
    end
    if(self.auto_height) then
        updated_size = self:refresh_height() or updated_size
    end
    if updated_size==true and self.update_internal then
        self:update_internal()
    end
end

function BaseUIObject:update_absolute_position(force_update)
    if self.locked==true then return end
    self.locked = true

    local old_x, old_y = self.x, self.y
    local old_w, old_h = self.width, self.height
    local parent_x, parent_y = 0, 0
    local parent_scroll_x, parent_scroll_y = 0, 0

    if self.parent_id and ui.elements and ui.elements.reference and ui.elements.reference[self.parent_id] then
        local parent = ui.elements.reference[self.parent_id]
        parent_x = parent.x or 0
        parent_y = parent.y or 0
        parent_scroll_x = parent.scroll_x or 0
        parent_scroll_y = parent.scroll_y or 0
    end

    -- Gebruik eigen scroll_x en scroll_y voor deze container, en die van de parent voor de offset
    self.x = parent_x + self.base_x - parent_scroll_x
    self.y = parent_y + self.base_y - parent_scroll_y

    --no update if position and size are unchanged
    if(old_x==self.x and old_y==self.y and old_w==self.width and old_h==self.height and force_update~=true ) then
        self.locked = false
        return false
    end
    
    --set internal settings based on self position
    if(self.update_internal) then
        self:update_internal()
    end

    --repos internal objects
    if(self.internal_children) then
        for _, child in ipairs(self.internal_children) do
            if type(child.update_absolute_position) == "function" then
                child:update_absolute_position(force_update)
            elseif child.update_pos and type(child.update_pos) == "function" then
                -- prim objects
                child:update_pos()
            end
        end
    end
    
    if self.layout and type(self.layout.apply) == "function" then
        local r = self.layout:apply(self, force_update)
        -- Layout bepaalt alles voor de children, dus geen losse update_absolute_position aanroepen
    else
        -- Geen layout: children zelf updaten
        for _, child in ipairs(self.children) do
            if type(child.update_absolute_position) == "function" then
                child:update_absolute_position(force_update)
            elseif child.update_pos and type(child.update_pos) == "function" then
                -- prim objects
                child:update_pos()
            end
           
        end
    end

    self:refresh_autosize(self)

    if((old_x ~= self.x or old_y ~= self.y or force_update) and self.on_position_change) then
        self:on_position_change()
    end

    if((old_w ~= self.width or old_h ~= self.height or force_update) and self.on_size_change) then
        self:on_size_change()
    end

    if(old_x ~= self.x or old_y ~= self.y or old_w ~= self.width or old_h ~= self.height and self.parent_id) then
        local parent = ui.elements.reference[self.parent_id]
        if parent and parent.locked~=true and (parent.auto_width==true or parent.auto_height==true) then
            parent:update_absolute_position(true)
        end
    end
    self.locked = false
    return true
end

function BaseUIObject:expected_change_in_position()
    local parent_x, parent_y = 0, 0
    local parent_scroll_x, parent_scroll_y = 0, 0

    if self.parent_id and ui.elements and ui.elements.reference and ui.elements.reference[self.parent_id] then
        local parent = ui.elements.reference[self.parent_id]
        parent_x = parent.x or 0
        parent_y = parent.y or 0
        parent_scroll_x = parent.scroll_x or 0
        parent_scroll_y = parent.scroll_y or 0
    end
    return self.x ~= (parent_x + self.base_x - parent_scroll_x) or self.y ~= (parent_y + self.base_y - parent_scroll_y)
end

function BaseUIObject:get_absolute_position()
    return self.x, self.y
end

function BaseUIObject:get_absolute_x()
    return self.x
end

function BaseUIObject:get_absolute_y()
    return self.y
end

function BaseUIObject:get_absolute_right()
    return self.x + self.width
end

function BaseUIObject:get_absolute_bottom()
    return self.y + self.height
end

function BaseUIObject:get_relative_position()
    return self.base_x, self.base_y
end

function BaseUIObject:get_x()
    return self.base_x
end

function BaseUIObject:get_y()
    return self.base_y
end

function BaseUIObject:get_relative_right()
    return self.base_x+self.width
end

function BaseUIObject:get_relative_bottom()
    return self.base_y+self.height
end

function BaseUIObject:refresh_width()
    local max_right = 0
    local count = 0
--     for _, child in ipairs(self.internal_children) do
--         if child.visible ~= false then
--             local cx = child.base_x or 0
--             local cw = child.width or 0
--             local right = cx + cw
--             if right > max_right then max_right = right end
--             count=count+1
--         end
-- end

    for _, child in ipairs(self.children or {}) do
        if child.visible ~= false then
            local cx = child.base_x or 0
            local cw = child.width or 0
            local right = cx + cw
            if right > max_right then max_right = right end
            count=count+1
        end
    end
    local new_width = max_right+(defaults.padding and defaults.padding.right or 0)
    if self.width ~= new_width then
        self.width = new_width
        return true, new_width
    end
    return false, self.width
end

function BaseUIObject:refresh_height()
    local max_bottom = 0
    local count = 0
    
    for _, child in ipairs(self.children or {}) do
        if child.visible ~= false then
            local cy = child.base_y or 0
            local ch = child.height or 0
            local bottom = cy + ch
            if bottom > max_bottom then max_bottom = bottom end
        end
    end

    local new_height = max_bottom+(defaults.padding and defaults.padding.bottom or 0)

    if self.height ~= new_height then
        self.height = new_height
        return true, new_height
    end
    return false, self.height
end

function BaseUIObject:get_last_autosize_root()
    if self.parent_id and ui.elements and ui.elements.reference and ui.elements.reference[self.parent_id] then
        local parent = ui.elements.reference[self.parent_id]

        if parent.auto_width==true or parent.auto_height==true then
            return parent:get_last_autosize_root()
        else
            return self
        end
    else
        return self
    end
end

function BaseUIObject:show()
    if self.visible == true then return end

    self.visible = true
    self:update_draw()

    if self.on_visibility_change then
        self:on_visibility_change(true)
    end

    if self.parent_id and ui.elements and ui.elements.reference and ui.elements.reference[self.parent_id] then
        local parent = ui.elements.reference[self.parent_id]
        if parent.auto_width==true or parent.auto_height==true then
            parent:update_absolute_position(true)
        else
            self:update_absolute_position(true)
        end
    else
        self:update_absolute_position(true)
    end
    --check parent and their parents if they have auto height or auto width and update if needed
    -- self:get_last_autosize_root():update_absolute_position(true)
end

function BaseUIObject:hide()
    if self.visible == false then return end

    self.visible = false
    self:update_draw()

    if self.on_visibility_change then
        self:on_visibility_change(false)
    end

    if self.parent_id and ui.elements and ui.elements.reference and ui.elements.reference[self.parent_id] then
        local parent = ui.elements.reference[self.parent_id]
        if parent.auto_width==true or parent.auto_height==true then
            parent:update_absolute_position(true)
        else
            self:update_absolute_position(true)
        end
    else
        self:update_absolute_position(true)
    end
    --check parent and their parents if they have auto height or auto width and update if needed
    -- self:get_last_autosize_root():update_absolute_position(true)
end

function BaseUIObject:is_visible()
    return self.visible
end

function BaseUIObject:is_hidden()
    return self.visible == false
end

function BaseUIObject:toggle_visibility()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end


function BaseUIObject:set_visibility(state)
    if state == true then
        self:show()
    else
        self:hide()
    end
end

function BaseUIObject:is_drawn()
    --check parent draw visibility
    if self.visible == false then 
        --always false
        return false
    elseif self.parent_id and ui.elements and ui.elements.reference and ui.elements.reference[self.parent_id] then
        local parent = ui.elements.reference[self.parent_id]
        return parent:is_drawn()
    elseif ui.elements:is_in_root(self) then
        --checked earlier if visible is false so can only return true here, if in root and visible then show
        return true
    else
        --dont show if not in root
        return false
    end
end

function BaseUIObject:is_drawn_test()
    --check parent draw visibility
    if self.visible == false then 
        --check prim children to verify that they are not drawn, if they are drawn then return 'E' for error
        if self.children then
            for _, child in ipairs(self.children) do
                if child.last_draw_visibility and child.last_draw_visibility == true then
                    return 'E'
                end
            end
        end
        --always false
        return 'A'
    elseif self.parent_id and ui.elements and ui.elements.reference and ui.elements.reference[self.parent_id] then
        local parent = ui.elements.reference[self.parent_id]
        local ret = parent:is_drawn_test()
        return 'B ('..parent.id..'/'..ret..') '
    elseif ui.elements:is_in_root(self) then
        --checked earlier if visible is false so can only return true here, if in root and visible then show
        return 'C'
    else
        --dont show if not in root
        -- print(self.id,ui.elements:print_all_in_root(),MENU_UI.view_region.id)
        return 'D'
    end
end

function BaseUIObject:update_draw(pre_calculated_draw)
    --check parent draw visibility
    self.is_currently_drawn = (pre_calculated_draw == false) and false or self:is_drawn()
    -- if self.is_currently_drawn == new_draw then return self.is_currently_drawn end
    
    --update child
    if(self.internal_children) then
        for _, child in ipairs(self.internal_children) do
            if child.update_draw_visibility then
                child:update_draw_visibility(self.is_currently_drawn)
            elseif child.update_draw then
                child:update_draw(self.is_currently_drawn)
            end
        end
    end

    if self.children then
        for _, child in ipairs(self.children) do
            if child.update_draw_visibility then
                child:update_draw_visibility(self.is_currently_drawn)
            elseif child.update_draw then
                child:update_draw(self.is_currently_drawn)
            end
        end
    end
    --update self custom visibility
    if self.on_update_draw_visibility then
        self:on_update_draw_visibility(self.is_currently_drawn)
    end

    return self.is_currently_drawn
end

function BaseUIObject:child_count()
    return #self.children
end

function BaseUIObject:get_child(index_,index_extra)
    if index_extra and self.layout and self.layout.get_child then
        return self.layout:get_child(self,index_,index_extra)
    end
    return self.children[index_]
end

function BaseUIObject:get_child_by_field(field, value)
    for _, child in ipairs(self.children) do
        if child[field] == value then
            return child
        end
    end
    return nil
end

function BaseUIObject:get_last_child()
    if #self.children == 0 then return nil end
    return self.children[#self.children]
end

function BaseUIObject:internalchild_count()
    return #self.internal_children
end

function BaseUIObject:destroy()
    if self.internal_children then
        for _, child in ipairs(self.internal_children) do
            if type(child.destroy) == "function" then
                child:destroy()
            end
            -- Verwijder ook uit ui.elements indien mogelijk
            if child.id and ui and ui.elements and ui.elements.remove then
                ui.elements:remove_ref(child.id)
            end
        end
    end
    if self.children then
        for _, child in ipairs(self.children) do
            if type(child.destroy) == "function" then
                child:destroy()
                if child.id and ui and ui.elements and ui.elements.remove then
                    ui.elements:remove_ref(child.id)
                end
            elseif child.object and type(child.object.destroy) == "function" then
                child.object:hide()
                child.object:destroy()
                if child.object.id and ui and ui.elements and ui.elements.remove then
                    ui.elements:remove_ref(child.object.id)
                end
            end
        end
    end
    if self.on_destroy then
        self:on_destroy()
    end
    -- Verwijder dit object zelf ook uit ui.elements
    if self.id and ui and ui.elements and ui.elements.remove then
        ui.elements:remove_ref(self.id)
    end
    self.internal_children = {}
    self.children = {}
end

function BaseUIObject:render()
    if(self.internal_children) then
        for _, child in ipairs(self.internal_children) do
            if type(child.render) == "function" then
                child:render(self)
            end
        end
    end
    if self.children then
        for _, child in ipairs(self.children) do
            if type(child.render) == "function" then
                child:render(self)
            end
        end
    end
end

function BaseUIObject:contains_point(px, py)
    return px >= self.x and px <= self.x + self.width
       and py >= self.y and py <= self.y + self.height
end

function BaseUIObject:clear()
    if self.children then
        for _, child in ipairs(self.children) do
            -- if type(child.destroy) == "function" then
            --     child:destroy()
            --     if child.id and ui and ui.elements and ui.elements.remove then
            --         ui.elements:remove_ref(child.id)
            --     end
            -- elseif child.object and type(child.object.destroy) == "function" then
            --     child.object:hide()
            --     child.object:destroy()
            --     if child.object.id and ui and ui.elements and ui.elements.remove then
            --         ui.elements:remove_ref(child.object.id)
            --     end
            -- end
            child.set_parent(nil)
        end
    end
    self.children = {}
    self:update_absolute_position(true)
end

function BaseUIObject:destroy_content()
    if self.children then
        for _, child in ipairs(self.children) do
            if type(child.destroy) == "function" then
                child:destroy()
                -- if child.id and ui and ui.elements and ui.elements.remove then
                --     ui.elements:remove_ref(child.id)
                -- end
            elseif child.object and type(child.object.destroy) == "function" then
                child.object:hide()
                child.object:destroy()
                -- if child.object.id and ui and ui.elements and ui.elements.remove then
                --     ui.elements:remove_ref(child.object.id)
                -- end
            end
        end
    end
    self.children = {}
    self:update_absolute_position(true)
end

return BaseUIObject