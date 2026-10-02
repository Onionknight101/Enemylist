local defaults = require('base/ui/ui_defaults')
local renderer = require('base/ui/render_backend')

images_prim = {}
local images_store = {}

local images_methods = {}

function images_methods:set_pos(x, y)
    if not x or not y then return end

    self.settings.x = x
    self.settings.y = y
    
    self:update_pos()
end

function images_methods:update_pos()
    renderer.image.set_position(self.id, self:get_pos_raw())
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
    renderer.image.set_size(self.id, w, h)
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
    renderer.image.set_color(self.id, a or 255, r, g, b)
end

function images_methods:set_path(path)
    if self.settings.path == path then return end

    self.settings.path = path
    renderer.image.set_texture(self.id, path)
end

function images_methods:has_a_path()
    return self.settings.path ~= nil and self.settings.path ~= ''
end

function images_methods:is_ready()
    return renderer.image.is_ready(self.id)
end

function images_methods:set_viewport(viewport)
    renderer.image.set_viewport(self.id, viewport)
end

function images_methods:set_fit(fit)
    if self.settings.fit == fit then return end

    self.settings.fit = fit
    renderer.image.set_fit_to_texture(self.id, fit)
end

function images_methods:set_effect(effect)
    if self.settings.effect == effect then return end
    self.settings.effect = effect
    renderer.image.set_effect(self.id, effect)
end

-- function images_methods:show()
--     if self.visible==true or self.always_hidden==true then return end

--     self.visible = true
--     windower.prim.set_visibility(self.id, true)
-- end

-- function images_methods:hide()
--     if  self.visible==false then return end

--     self.visible = false
--     windower.prim.set_visibility(self.id, false)
-- end

function images_methods:update_draw_visibility(state)
    if self.always_hidden then state = false end
    if state == self.last_draw_visibility then return end

    self.last_draw_visibility = state
    if state == true then
        renderer.image.set_visibility(self.id, true)
    else
        renderer.image.set_visibility(self.id, false)
    end

    -- print('Updated draw visibility for image ', self.id, state)
end

function images_methods:set_parent(parent)
    if not parent or not parent.id then return end
    if self.parent_id == parent.id then return end
    
    self.parent_id = parent.id
    self:update_pos()
end

function images_methods:destroy()
    renderer.image.delete(self.id)
    images_store[self.id] = nil
end

local function generate_id()
    return 'img_' .. tostring(os.clock()):gsub('%.', '') .. '_' .. tostring(math.random(10000, 99999))
end

function images_prim.new(settings)
    local id = generate_id()
    renderer.image.create(id)
    local obj = {
        id = id,
        settings = settings or {},
        always_hidden = false,
        last_draw_visibility = nil,
    }

    obj.settings.x = obj.settings.x or 0
    obj.settings.y = obj.settings.y or 0
    obj.settings.width = obj.settings.width or defaults.standard_width
    obj.settings.height = obj.settings.height or defaults.standard_height
    renderer.image.set_size(id, obj.settings.width, obj.settings.height)

    setmetatable(obj, {__index = images_methods})
    images_store[id] = obj
    ui.elements:add_ref(id, obj)
    return obj,id
end
