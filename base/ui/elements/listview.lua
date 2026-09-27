--listview of labels. uses page_change to show more items than the height allows
local defaults = require('base/ui/ui_defaults')

return function(setting)
    setting = setting or {}

    local width = setting.width or defaults.standard_width
    local height = setting.height or defaults.standard_height * 8
    local row_height = setting.row_height or defaults.standard_height
    local padding = setting.padding or 4

    local parent_region_ = ui.create_imageless_region({
        x=setting.x or 0, y=setting.y or 0,
        width = width,
        height = height,
        layout = Vertical_Layout:new({ spacing = 0, padding = padding }),
        name = setting.name or nil,
    })

    --there is no scroll so add a page_change at the bottom of the region
    local page_change = ui.create_page_change({
        x = 0, y = height - row_height,
        width = width, height = row_height,
        page_size = math.floor(height / row_height),
    })
    parent_region_:add(page_change)

    --the listview needs functions to add and remove labels  from the list
    parent_region_.add_item = function(self, text)
        --use onionlabels
        local label = ui.create_onion_label({
            text = text,
            width = width - indent,
            height = row_height,
            x = 0, y = 0,
        })
        parent_region_:add(label)
    end

    parent_region_.clear_items = function(self)
        for _, child in pairs(self.children) do
            if child ~= page_change then
                child:destroy()
            end
        end

    end

    --remove
    parent_region_.remove_item = function(self, text)
        for _, child in pairs(self.children) do
            if child.text == text then
                child:destroy()
            end
        end
    end

    --change index of an item
    parent_region_.change_item_index = function(self, text, new_index)
        local item_to_move
        for _, child in pairs(self.children) do
            if child.text == text then
                item_to_move = child
                break
            end
        end
        --remove
        
    end

    --move item down 
    parent_region_.move_item_down = function(self, text)
        local item_to_move
        for _, child in pairs(self.children) do
            if child.text == text then
                item_to_move = child
                break
            end
        end
        if item_to_move then
            local current_index = math.floor(item_to_move.y / row_height) + 1
            local new_index = current_index + 1
            item_to_move:move(0, (new_index - 1) * row_height)
        end
    end
    return parent_region_
end
