--a table of imagebuttons where if you press it does a function based on the image

local defaults = require('base/ui/ui_defaults')

return function(setting)


    --back imageless region. use settings for size and pos
    local back_region = ui.create_imageless_region({
        x = setting.x or 0, y = setting.y or 0,
        width = setting.width,
        height = setting.height,
        draggable = setting.draggable or true,
        name = setting.name or 'selector_back_region',
        name = setting.name or nil,
    })

    local image_size = setting.image_size or 48

    --calculate how many images can fit in the region based on the size of the region and the size of the images. dont forget there is text under the images, so add some padding for that. also add some padding between the images

    local size_between = 5
    local text_height = 15
    local images_per_row = math.floor((back_region.width + size_between) / (image_size + size_between))
    local images_per_column = math.floor((back_region.height + size_between) / (image_size + size_between+text_height))

    local current_page = 1
    local total_pages = math.ceil(#setting.options / (images_per_row * images_per_column))
    local image_per_page = images_per_row * images_per_column


    local images = {}
    if setting.options then
         for i, option in ipairs(setting.options) do
            local image_button = ui.create_image({
                x = ((i-1) % image_per_page) * (image_size + size_between), y = math.floor((i-1) / image_per_page) * (image_size + size_between+text_height),
                width = image_size, height = image_size,
                path = option.image,
                name = option.name or 'selector_image_'..i,
                on_click = function()
                    if setting.on_click then
                        setting.on_click(option.name)
                    end
                end
            })
            back_region:add(image_button)
            --text under the image showing the name of the option. it should be centered under the image
            local label = ui.create_onion_label({
                x = image_button.base_x, y = image_button:get_relative_bottom() + 5,
                text = option.name,
                size = 10,
            })
            back_region:add(label)

            table.insert(images, image_button)
        end
    end

    local function update_images(new_page)
        --hide all images from the current page
        for i = (current_page - 1) * image_per_page + 1, math.min(current_page * image_per_page, #setting.options) do
            if back_region.images and back_region.images[i] then
                back_region.images[i]:hide()
            end
        end
        
        current_page = current_page - 1
        --show all images for the new page
        for i = (current_page - 1) * image_per_page + 1, math.min(current_page * image_per_page, #setting.options) do
            if back_region.images and back_region.images[i] then
                back_region.images[i]:show()
            end
        end
    end


    --button to go up a page. it will be at the bottom left of the region with some padding
    local btn_left = ui.create_button({
        x = defaults.padding.left*2, y = back_region.height - defaults.standard_height- (defaults.padding.bottom*4),
        width = 20,
        height = 20,
        label = "<",
        on_click = function()
            if current_page > 1 then
                update_images(current_page - 1)
            end
        end
    })
    back_region:add(btn_left)

    --button to go down a page. it will be at the bottom right of the region with some padding
    local btn_right = ui.create_button({
        x = defaults.padding.left+btn_left:get_relative_right(), y = back_region.height - defaults.standard_height- (defaults.padding.bottom*4),
        width = 20,
        height = 20,
        label = ">",
        on_click = function()
            if current_page < total_pages then
                update_images(current_page + 1)
            end
        end
    })
    back_region:add(btn_right)
    --label next to the btnright showing which page we are on / max page
    local page_label = ui.create_dynamic_label({
        x = btn_right:get_relative_right() + defaults.padding.left, y = back_region.height - defaults.standard_height- (defaults.padding.bottom*4),
        text = '',
        fnc_change = function()
            return tostring(current_page.." / "..total_pages)
        end,
    })
    back_region:add(page_label)

    return back_region
end