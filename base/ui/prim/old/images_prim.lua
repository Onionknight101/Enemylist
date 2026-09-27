local defaults = require('base/ui/ui_defaults')

images_prim = {}

local images_methods = {}

function images_methods:set_pos(x, y)
    if not x or not y then return end

    self.settings.x = x
    self.settings.y = y
    
    self:update_pos()
end

function images_methods:update_pos()
    windower.prim.set_position(self.active_id, self:get_pos_raw())
end

function images_methods:get_pos()
    return self.settings.x, self.settings.y
end

function images_methods:get_pos_raw()
    if(self.parent_id) then
        local parent = ui.elements.reference[self.parent_id]
        local parent_x, parent_y = parent:get_absolute_position()
        return self.settings.x + parent_x - parent.scroll_x, self.settings.y + parent_y - parent.scroll_y
    else
        -- Als er geen parent is, gebruik de eigen positie
        return self.settings.x, self.settings.y
    end
end

function images_methods:set_size(w, h)
    if self.settings.width == w and self.settings.height == h then return end

    self.settings.width = w
    self.settings.height = h
    windower.prim.set_size(self.active_id, w, h)
end

function images_methods:get_size()
    return self.settings.width, self.settings.height
end

function images_methods:set_color(r, g, b, a)
    -- if self.settings==nil then return end
    -- if self.settings.color
    --    and self.settings.color[1] == r
    --    and self.settings.color[2] == g
    --    and self.settings.color[3] == b
    --    and self.settings.color[4] == (a or 255) then
    --     return
    -- end

    self.settings.color = {r, g, b, a or 255}
    windower.prim.set_color(self.active_id, a or 255, r, g, b)
end

function images_methods:set_path(path)
    if self.settings.path == path then return end
    self.settings.path = path

    --get a free id from the buffer and check the queue for the time it was set. 
    local found_id = nil
    if self.buffer_amount > 1 then
        for i=1, self.buffer_amount do
            local buffer_id = self.multi_buffer[i]
            if buffer_id~=self.active_id then
                local is_used=false
                for q=1, #self.queue do
                    local item = self.queue[q]
                    if item.id == buffer_id  then
                        is_used = true
                        break
                    end
                end
                if is_used == false then
                    found_id = buffer_id
                    break
                end
            end
        end
    end
    if found_id == nil then
        --no free id. overwrite current
        windower.prim.set_texture(self.active_id, path)
    else
        table.insert(self.queue, {time = os.clock(), id = found_id})
        windower.prim.set_texture(self.found_id, path)
    end

end

function images_methods:set_fit(fit)
    if self.settings.fit == fit then return end

    self.settings.fit = fit
    windower.prim.set_fit_to_texture(self.active_id, fit)
end

function images_methods:show()
    if self.visible==true then return end

    self.visible = true
    windower.prim.set_visibility(self.active_id, true)
end

function images_methods:hide()
    if  self.visible==false then return end

    self.visible = false
    windower.prim.set_visibility(self.active_id, false)
end

function images_methods:set_parent(parent)
    if not parent or not parent.id then return end
    if self.parent_id == parent.id then return end
    
    self.parent_id = parent.id
    self:update_pos()
end

function images_methods:destroy()
    for i=1, obj.buffer_amount do
        windower.prim.delete(self.multi_buffer[i].id)
    end
    -- primDelete(self.active_id)
end

local function generate_id()
    return 'img_' .. tostring(os.clock()):gsub('%.', '') .. '_' .. tostring(math.random(10000, 99999))
end

local buffer_wait_time = 0.5

function images_prim.new(settings)
    local id = generate_id()
    local obj = {
        id = id,
        active_id = id .. '_1',
        settings = settings or {},
        visible = true,
        buffer_amount = settings and settings.buffer_amount or 1,
        multi_buffer = {},
        queue = {}
    }

    obj.settings.x = obj.settings.x or 0
    obj.settings.y = obj.settings.y or 0
    obj.settings.width = obj.settings.width or defaults.standard_width
    obj.settings.height = obj.settings.height or defaults.standard_height

    for i=1, obj.buffer_amount do
        windower.prim.create(id .. '_' .. i)
        windower.prim.set_visibility(id .. '_' .. i, i==1)
        windower.prim.set_size(id .. '_' .. i, obj.settings.width, obj.settings.height)
        table.insert(obj.multi_buffer, id .. '_' .. i)
    end

    setmetatable(obj, {__index = images_methods})
    ui.elements:add_ref(id, obj)

    if obj.buffer_amount > 1 then
        obj.timer = Timers.add('img_' .. id, 0.1, 0.1, true, function()
            for i=1, #obj.queue do
                local item = obj.queue[i]
                if os.clock() - item.time >= buffer_wait_time then
                    --hide current active and show new
                    windower.prim.set_visibility(obj.active_id, false)
                    obj.active_id = item.id
                    windower.prim.set_visibility(item.id, true)
                    table.remove(obj.queue, i)
                end
            end
        end)
    end

    return obj,id
end

--create timer to handle buffer swapping if buffer_amount > 1
