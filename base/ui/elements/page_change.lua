local defaults = require('base/ui/ui_defaults')

return function(setting)

    --region
    local back_region = ui.create_imageless_region({
        x=setting.x or 0, y=setting.y or 0,
        width = setting.width or 200,
        height = setting.height or defaults.standard_height,
        name = setting.name or nil,
    })
    back_region.current_page = 1
    back_region.total_pages = 1

    local page_label = nil

    function back_region:set_page(page)
        if page == self.current_page then return end
        if page < 1 then page = 1 end
        if page > self.total_pages then page = self.total_pages end

        local old_page = self.current_page
        self.current_page = page

        --update the page label
        page_label:set_text((setting.pre_text or '')..self.current_page.." / "..self.total_pages)
        if setting.fnc_update then
            setting.fnc_update(self.current_page, old_page)
        end
    end

    function back_region:set_total_pages(pages)
        self.total_pages = pages
        --update the page label
        if self.current_page > self.total_pages then
            back_region:set_page(self.total_pages)
        end
        page_label:set_text((setting.pre_text or '')..self.current_page.." / "..self.total_pages)
    end

    function back_region:get_page()
        return self.current_page
    end

    function back_region:get_total_pages()
        return self.total_pages
    end

    function back_region:next_page()
        if self.current_page < self.total_pages then
            self:set_page(self.current_page + 1)
        end
    end

    function back_region:previous_page()
        if self.current_page > 1 then
            self:set_page(self.current_page - 1)
        end
    end

    function back_region:refresh()
        if setting.fnc_update then
            setting.fnc_update(self.current_page, self.current_page)
        end
    end
    

    --button to go up a page. it will be at the bottom left of the region with some padding
    local btn_left = ui.create_button({
        x = defaults.padding.left*2, y = back_region.height - defaults.standard_height- (defaults.padding.bottom*4),
        width = 20,
        height = 20,
        label = "<",
        on_click = function()
            back_region:previous_page()
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
            back_region:next_page()
        end
    })
    back_region:add(btn_right)

    --label next to the btnright showing which page we are on / max page
    page_label = ui.create_label({
        x = btn_right:get_relative_right() + defaults.padding.left, y = back_region.height - defaults.standard_height- (defaults.padding.bottom*4),
        text = (setting.pre_text or '').."1 / 1",
    })
    back_region:add(page_label)

    return back_region
end