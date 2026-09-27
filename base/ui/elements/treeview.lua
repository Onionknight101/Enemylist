--treeview showing elements and their children in a tree structure
local defaults = require('base/ui/ui_defaults')

--a branch is a table with the following structure:
-- {
--     text = 'Branch Name', -- text to display for this branch
--     children =  -- list of child branches
--     parent = -- reference to parent branch, nil for root
--     expanded = false, -- whether the branch is expanded or not
--     label = nil, -- reference to the OnionLabel for this branch, set when drawn
--     expand_image = nil, -- reference to the expand/collapse image for this branch, set when drawn
-- }

local branch = {}

function branch:new(text, parent, width, height)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.text = text or ''
    o.parent = parent or nil
    o.children = {}
    o.expanded = false

    o.region = ui.create_imageless_region({
        x=0, y=0,
        width = width or 100, height = height or 20,
    })
    o.region:hide() -- hide by default, will be shown when drawn

    --create label and expand image when branch is created
    o.label = ui.create_onion_label({
        text = o.text,
        color = defaults.text_color,
        font = defaults.font,
        size = defaults.font_size,
    })
    o.label:hide() -- hide by default, will be shown when drawn
    o.region:add(o.label)

    --expand image is a simple triangle pointing right when collapsed and down when expanded. we can use the same image and rotate it based on the state
    o.expand_image = ui.create_image({
        path = windower.addon_path .. 'media/ui/triangle_right.png',
        width = 8, height = 8,
    })
    o.expand_image:hide() -- hide by default, will be shown when drawn
    o.region:add(o.expand_image)

    function o:toggle()
        self.expanded = not self.expanded
        if self.expanded then
            self.expand_image:set_path(windower.addon_path .. 'media/ui/triangle_down.png')
        else
            self.expand_image:set_path(windower.addon_path .. 'media/ui/triangle_right.png')
        end
    end

    function o:add_child(text)
        local child = branch:new(text, self)
        table.insert(self.children, child)
        return child
    end

    function o:remove_child(child)
        for i, c in ipairs(self.children) do
            if c == child then
                table.remove(self.children, i)
                return true
            end
        end
        return false
    end

    --hide
    function o:hide()
        self.region:hide()
        self.label:hide()
        self.expand_image:hide()
        for _, child in ipairs(self.children) do
            child:hide()
        end
    end

    --show
    function o:show()
        self.region:show()
        self.label:show()
        if #self.children > 0 then
            self.expand_image:show()
        end
        if self.expanded then
            for _, child in ipairs(self.children) do
                child:show()
            end
        end
    end

    function o:is_leaf()
        return #self.children == 0
    end

    function o:get_level()
        local level = 0
        local current = self
        while current.parent do
            level = level + 1
            current = current.parent
        end
        return level
    end

    function o:get_path()
        local path = {}
        local current = self
        while current do
            table.insert(path, 1, current.text)
            current = current.parent
        end
        return path
    end

    function o:find_child(text)
        for _, child in ipairs(self.children) do
            if child.text == text then
                return child
            end
        end
        return nil
    end

    function o:find_descendant(text)
        if self.text == text then
            return self
        end
        for _, child in ipairs(self.children) do
            local found = child:find_descendant(text)
            if found then
                return found
            end
        end
        return nil
    end

    function o:expand_all()
        self.expanded = true
        self.expand_image:set_path(windower.addon_path .. 'media/ui/triangle_down.png')
        for _, child in ipairs(self.children) do
            child:expand_all()
        end
    end

    function o:collapse_all()
        self.expanded = false
        self.expand_image:set_path(windower.addon_path .. 'media/ui/triangle_right.png')
        for _, child in ipairs(self.children) do
            child:collapse_all()
        end
    end

    --destroy the branch and all its children
    function o:destroy()
        for _, child in ipairs(self.children) do
            child:destroy()
        end
        self.region:destroy()
        self.label:destroy()
        self.expand_image:destroy()
    end

    return o
end

return function(setting)
    setting = setting or {}

    local width = setting.width or defaults.standard_width
    local height = setting.height or defaults.standard_height * 8
    local row_height = setting.row_height or defaults.standard_height
    local indent = setting.indent or 12
    local padding = setting.padding or 4

    local parent_region_ = ui.create_imageless_region({
        x=setting.x or 0, y=setting.y or 0,
        width = width,
        height = height,
        layout = Vertical_Layout:new({ spacing = 0, padding = padding }),
    })

    --there is no scroll so add a page_change
end