
local defaults = require('base/ui/ui_defaults')
local ui_base = require('base/ui/ui_base')

local function clearGraphics(obj)
	--clear graphics
	for entry=1,#obj.graphics.letter do
		--remove letter graphics
		primDelete(obj.graphics.letter[entry])
		primRemoveNameFromList(obj.graphics.letter[entry])
		--remove edge graphics
		if(#obj.graphics.edge>0) then
			for i=1,4 do
				primDelete(obj.graphics.edge[((entry-1)*4)+i])
				primRemoveNameFromList(obj.graphics.edge[((entry-1)*4)+i])
			end
		end
		--remove shadow graphics
		if(#obj.graphics.shadow>0) then
			primDelete(obj.graphics.shadow[entry])
			primRemoveNameFromList(obj.graphics.shadow[entry])
		end
		table.remove(obj.letterInfo,1)
	end
end

local function redoLetterPrimNames(obj)
	--clear old tables
	for entry=1,#obj.graphics.letter do
		--remove letter graphics
		primRemoveNameFromList(obj.graphics.letter)
		table.remove(obj.graphics.letter,1)
		--remove edge graphics
		if(#obj.graphics.edge>0) then
			for i=1,4 do
				primRemoveNameFromList(obj.graphics.edge[1])
				table.remove(obj.graphics.edge,1)
			end
		end
		--remove shadow graphics
		if(#obj.graphics.shadow>0) then
			primRemoveNameFromList(obj.graphics.shadow[1])
			table.remove(obj.graphics.shadow,1)
		end
		table.remove(obj.letterInfo,1)
	end

	txtLen = string.len(obj.text)
	if(txtLen==0) then return end
	--create shadows
	for entry=1,txtLen do
		table.insert(obj.graphics.shadow,primGenerateName(obj.id..'shadow'..entry..''..stringFunctions.randomString(5)))
	end
	--create edges and letters
	for entry=1,txtLen do
		--edges
		for i=1,4 do
			table.insert(obj.graphics.edge,primGenerateName(obj.id..'edge'..((entry-1)*4)+i..''..stringFunctions.randomString(5)))
		end
		--letter
		table.insert(obj.graphics.letter,primGenerateName(obj.id..entry..'letter'..stringFunctions.randomString(5)))
	end
end

local function redoShiftInfo(obj)
	--calculate mode max shift values
	if(obj.longestHeight<obj.height) then
		obj.max_y_shift = obj.height-obj.longestHeight
	else
		obj.max_y_shift = 0
	end
	for entry=1,string.len(obj.text) do
		if(obj.longestWidth<obj.width) then
			obj.line[obj.letterInfo[entry].line].max_x_shift = obj.width-obj.line[obj.letterInfo[entry].line].width
		else
			obj.line[obj.letterInfo[entry].line].max_x_shift = 0
		end
	end
end

local function updateVisibility(obj)
	for entry=1,#obj.letterInfo do	
		if(obj.letterInfo[entry].code ~= 10 and obj.letterInfo[entry].code ~= 32) then
			if(obj.clip==true) then

				if(obj.letterInfo[entry].left<obj.width
				and obj.letterInfo[entry].left+obj.letterInfo[entry].width<obj.width
				and obj.letterInfo[entry].top<obj.height
				and obj.letterInfo[entry].top+obj.letterInfo[entry].height<obj.height) then
					if(obj.letterInfo[entry].visible~=obj.visible) then
						obj.letterInfo[entry].visible=obj.visible
						-- obj:set_visibility(obj.visible))
					end
				else
					if(obj.letterInfo[entry].visible~=false) then
						obj.letterInfo[entry].visible=false
						-- obj:set_visibility(false)
					end
				end
			else
				if(obj.letterInfo[entry].visible~=obj.visible) then
					obj.letterInfo[entry].visible=obj.visible
					-- obj:set_visibility(obj.visible)
                    primVisibility(obj.graphics.letter[entry],obj.letterInfo[entry].visible)
				end
			end
		else
			if(obj.letterInfo[entry].visible~=false) then
				obj.letterInfo[entry].visible=false
				-- obj:set_visibility(false)
                primVisibility(obj.graphics.letter[entry],obj.letterInfo[entry].visible)
			end
		end
	end
end

local function redoLetterPositionInfo(obj)
	--clear
	--clear info objects
	obj.letterInfo = {}
	obj.line = {}

	--check textLength
	txtLen = string.len(obj.text)
	--exit if text length is 0
	if(txtLen==0) then return end
		curX=0
		curY=0

		oldLen = #obj.graphics.letter
		lineSpacing = obj.font.base['verticalSpacing']*obj.font.size
	if(lineSpacing < obj.font.base['minimumLineSpacing']) then
		lineSpacing = obj.font.base['minimumLineSpacing']
	end

	if(obj.multiline==true) then
		if(obj.auto_width) then
			_BreakWidth = false
		else
			_BreakWidth = obj.breakwidth
		end
	else
		_BreakWidth = false
	end

	obj.longestWidth = 1
	--create from start
	
	--shadow radians. angle -90 cause angles are east directed at 0 stanndard
	shadowRad = math.rad(obj.font.shadow.angle-90)

	--the entry where a graphical word starts
	wordStartEntry = 1
	lineStartEntry = 1
	exitAt = 0
	
	currentLine = 1
	--fill in position,size and textures
	while(exitAt <txtLen) do
		if(exitAt==0) then
			exitAt = 1
		end
		for entry=exitAt,txtLen do
			--get current char and byte code
			curChar = string.sub(obj.text,entry,entry)
			curCode = string.byte(curChar)
			if(curCode==10 or curCode == 32) then --newline or space
				--next word starts at the next entry
				wordStartEntry = entry+1
				--newline check
				if(curCode==10) then
					--log position
					obj.letterInfo[entry] = {
						['left']=curX,
						['top']=curY,
						['width']=1,
						['height']=obj.font.size,
						['line']=currentLine,
						['code']=curCode,
					}

					if(obj.multiline==true) then

						if(curX>obj.longestWidth) then
							obj.longestWidth = curX
						end
						obj.line[currentLine] ={['width']=obj.letterInfo[entry].left, max_x_shift=0}
						currentLine = currentLine+1
						curX=0
						curY=curY+obj.font.size-lineSpacing
						lineStartEntry = entry+1
					else
						curX = curX+1
					end
				elseif(curCode==32) then
					--log position
					obj.letterInfo[entry] = {
						['left']=curX,
						['top']=curY,
						['width']=math.floor((obj.font.base['letter'][curCode]['size']/obj.font.base['basePixelSize'])*obj.font.size),
						['height']=obj.font.size,
						['line']=currentLine,
						['code']=curCode,
						
					}

					curX = curX+obj.letterInfo[entry]['width']
				end
			else
				--get letter width
				shiftPercent= obj.font.base['letter'][curCode]['size']/obj.font.base['basePixelSize']
				--log info
				obj.letterInfo[entry] = {
					['left']=curX,
					['top']=curY,
					['width']=obj.font.size*shiftPercent,
					['height']=obj.font.size,
					['line']=currentLine,
					['code']=curCode,
					['edge']={
						['offset'] = obj.font.edge.offset,
						['left']={
								['left']=curX-obj.font.edge.offset,
								['top']=curY,
								},
						['top']={
								['left']=curX,
								['top']=curY-obj.font.edge.offset,
								},
						['right']={
								['left']=curX+obj.font.edge.offset,
								['top']=curY,
								},
						['bottom']={
								['left']=curX,
								['top']=curY+obj.font.edge.offset,
								},
					},
					['shadow']={
								['left']=curX+(math.cos(shadowRad)*obj.font.shadow.offset),
								['top']=curY+(math.sin(shadowRad)*obj.font.shadow.offset),
					},
				}
				
				--set left shift if available
				if(obj.font.base['letter'][curCode]['left']) then
					shiftPercent=shiftPercent-obj.font.base['letter'][curCode]['left']/obj.font.base['basePixelSize']
				end
				--get next char code
				nextCode =string.byte( string.sub(obj.text,entry+1,entry+1))
				if(entry<txtLen and nextCode~=10) then
					if(obj.kerning_use and obj.font.base['letter'][curCode]['kerning'][nextCode]) then
						shiftPercent = shiftPercent-(obj.font.base['letter'][curCode]['kerning'][nextCode]/obj.font.base['basePixelSize'])
					end
				end
				--if we cant get over the width and this isnt a space then newline the graphics starting at the wordStartEntry
				if(obj.multiline==true) then
					if(_BreakWidth and curX+math.floor(shiftPercent*obj.font.size)>=obj.width and lineStartEntry ~= wordStartEntry) then
						obj.line[currentLine] ={['width']=obj.letterInfo[wordStartEntry-1].left+obj.letterInfo[wordStartEntry-1].width, max_x_shift=0}
						currentLine = currentLine+1
						
						curX=0
						curY=curY+obj.font.size-lineSpacing
						--set current entry at 1 entry befor wordStartEntry. avoid this when this is the first letter in a word
						exitAt = wordStartEntry
						lineStartEntry = wordStartEntry
						break
					else
						curX = curX+math.floor(shiftPercent*obj.font.size)
					end
				else
					curX = curX+math.floor(shiftPercent*obj.font.size)
				end
			end
			exitAt = entry
		end
	end
	
	--autosize if required
	--if(self.block_redo==false) then
	--		self.block_redo = true
		--add last linewidth
		obj.line[currentLine] ={['width']= obj.letterInfo[txtLen].left+obj.letterInfo[txtLen].width, max_x_shift=0}
		--last longestWidth check
		if(curX>obj.longestWidth) then
			obj.longestWidth = curX
		end
		--longestHeight check
		obj.longestHeight = obj.letterInfo[txtLen].top+obj.letterInfo[txtLen].height

        
        if(obj.auto_height == true) then
            obj.height = obj.longestHeight
        end

		if(obj.auto_width == true) then
			addition = 0
			if(obj.font.edge.use) then
				addition = obj.font.edge.offset
			end
			if(obj.font.shadow.use and math.cos(shadowRad)*obj.font.shadow.offset>addition) then
				addition = math.cos(shadowRad)*obj.font.shadow.offset
			end

			-- obj.view:setSize(obj.longestWidth+addition,curY+obj.font.size-lineSpacing)

			obj.max_y_shift = 0
			-- obj.line[obj.letterInfo[entry].line].max_x_shift = 0
            obj.width = obj.longestWidth
		else
			--calculate mode max shift values
			redoShiftInfo(obj)
		end


		--visibility
		updateVisibility(obj)
		--keep drawOrder
		--if(not self.view:isTopView()) then
		--end
--		self.block_redo = false
	--end

end

local function addShadowGraphicsEntry(obj,entry)
	primCreate(obj.graphics.shadow[entry])
	primVisibility(obj.graphics.shadow[entry],obj.letterInfo[entry].visible)
	primSetColor(obj.graphics.shadow[entry],obj.font.shadow.color.a,obj.font.shadow.color.r,obj.font.shadow.color.g,obj.font.shadow.color.b)
	primSetSize(obj.graphics.shadow[entry],obj.letterInfo[entry].width,obj.letterInfo[entry].height)
	primSetTexture(obj.graphics.shadow[entry],obj.font.base.folder..'/'..obj.letterInfo[entry].code..'.png')
	primSetFitToTexture(obj.graphics.shadow[entry],false)
end

local function setShadowGraphicsEntryPosition(obj,entry,x_dif,y_dif)
	primSetPosition(obj.graphics.shadow[entry],obj.x+obj.letterInfo[entry].shadow.left+x_dif,obj.y+obj.letterInfo[entry].shadow.top+y_dif)
end

local function addEdgeGraphicsEntry(obj,entry)
	for i=1,4 do
		primCreate(obj.graphics.edge[((entry-1)*4)+i])
		primVisibility(obj.graphics.edge[((entry-1)*4)+i],obj.letterInfo[entry].visible)
		primSetColor(obj.graphics.edge[((entry-1)*4)+i],obj.font.edge.color.a,obj.font.edge.color.r,obj.font.edge.color.g,obj.font.edge.color.b)
	end
	--left
	primSetSize(obj.graphics.edge[((entry-1)*4)+1],obj.letterInfo[entry].width,obj.letterInfo[entry].height)
	primSetTexture(obj.graphics.edge[((entry-1)*4)+1],obj.font.base.folder..'/'..obj.letterInfo[entry].code..'.png')
	primSetFitToTexture(obj.graphics.edge[((entry-1)*4)+1],false)
	--top
	primSetSize(obj.graphics.edge[((entry-1)*4)+2],obj.letterInfo[entry].width,obj.letterInfo[entry].height)
	primSetTexture(obj.graphics.edge[((entry-1)*4)+2],obj.font.base.folder..'/'..obj.letterInfo[entry].code..'.png')
	primSetFitToTexture(obj.graphics.edge[((entry-1)*4)+2],false)
	--right
	primSetSize(obj.graphics.edge[((entry-1)*4)+3],obj.letterInfo[entry].width,obj.letterInfo[entry].height)
	primSetTexture(obj.graphics.edge[((entry-1)*4)+3],obj.font.base.folder..'/'..obj.letterInfo[entry].code..'.png')
	primSetFitToTexture(obj.graphics.edge[((entry-1)*4)+3],false)
	--bottom
	primSetSize(obj.graphics.edge[((entry-1)*4)+4],obj.letterInfo[entry].width,obj.letterInfo[entry].height)
	primSetTexture(obj.graphics.edge[((entry-1)*4)+4],obj.font.base.folder..'/'..obj.letterInfo[entry].code..'.png')
	primSetFitToTexture(obj.graphics.edge[((entry-1)*4)+4],false)
end

local function setEdgeGraphicsEntryPosition(obj,entry,x_dif,y_dif)
	--left
		primSetPosition(obj.graphics.edge[((entry-1)*4)+1],obj.x+obj.letterInfo[entry].edge.left.left+x_dif,obj.y+obj.letterInfo[entry].edge.left.top+y_dif)
	--top
		primSetPosition(obj.graphics.edge[((entry-1)*4)+2],obj.x+obj.letterInfo[entry].edge.top.left+x_dif,obj.y+obj.letterInfo[entry].edge.top.top+y_dif)
	--right
		primSetPosition(obj.graphics.edge[((entry-1)*4)+3],obj.x+obj.letterInfo[entry].edge.right.left+x_dif,obj.y+obj.letterInfo[entry].edge.right.top+y_dif)
	--bottom
		primSetPosition(obj.graphics.edge[((entry-1)*4)+4],obj.x+obj.letterInfo[entry].edge.bottom.left+x_dif,obj.y+obj.letterInfo[entry].edge.bottom.top+y_dif)
end

local function getXDif(obj,entry)
	if(obj.horizontal_mode==1) then
		return obj.line[obj.letterInfo[entry].line].max_x_shift/2.0
	elseif(obj.horizontal_mode==2) then
		return obj.line[obj.letterInfo[entry].line].max_x_shift
	else 
		return 0
	end
end

local function getYDif(obj,entry)
	if(obj.vertical_mode==1) then
		return obj.max_y_shift/2.0
	elseif(obj.vertical_mode==2) then
		return obj.max_y_shift
	else 
		return 0
	end
end

local function setPositions(obj)
	for entry=1,#obj.letterInfo do
		if(obj.letterInfo[entry].code ~= 10 and obj.letterInfo[entry].code ~= 32) then
		x_dif = getXDif(obj,entry)
		y_dif = getYDif(obj,entry)
			if(obj.font.shadow.use) then
				setShadowGraphicsEntryPosition(obj,entry,x_dif,y_dif)
			end
			--edges
			if(obj.font.edge.use) then
				setEdgeGraphicsEntryPosition(obj,entry,x_dif,y_dif)
			end
			--letter
			--set position
			primSetPosition(obj.graphics.letter[entry],obj.x+obj.letterInfo[entry].left+x_dif,obj.y+obj.letterInfo[entry].top+y_dif)

        end
	end
end

local function createTextFromList(obj)
	for entry=1,#obj.letterInfo do
		--create shadows
		if(obj.letterInfo[entry].code ~= 10 and obj.letterInfo[entry].code ~= 32) then
			if(obj.font.shadow.use) then
				addShadowGraphicsEntry(obj,entry)
			end
			--edges
			if(obj.font.edge.use) then
				addEdgeGraphicsEntry(obj,entry)
			end
			--letter
			primCreate(obj.graphics.letter[entry])
			primVisibility(obj.graphics.letter[entry],obj.letterInfo[entry].visible)
			primSetColor(obj.graphics.letter[entry],obj.font.color.a,obj.font.color.r,obj.font.color.g,obj.font.color.b)
			-- set texture
			primSetTexture(obj.graphics.letter[entry],obj.font.base.folder..'/'..obj.letterInfo[entry].code..'.png')
			primSetFitToTexture(obj.graphics.letter[entry],false)
			--set size
            primSetSize(obj.graphics.letter[entry],obj.letterInfo[entry].width,obj.letterInfo[entry].height)
		end
	end
	setPositions(obj)
end

local function update_extents(self)
    if(self.parent_id) then
        local parent = ui.elements.reference[self.parent_id]
        if parent and parent.locked~=nil and (parent.locked==false) then
            parent:update_absolute_position(true)
        end
    end
end

return function(setting)
    setting = setting or {}

    local label = ui_base:new({
        type = 'label',
        base_x = setting.x or 0,
        base_y = setting.y or 0,
        layout_div_x = setting.layout_div_x or 0,
        layout_div_y = setting.layout_div_y or 0,
        auto_width = setting.auto_width or true,
        auto_height = setting.auto_height or true,
    	pre_text = setting.pre_text,
    	fnc = setting.fnc_change,
        graphics = {
            letter = {},
            edge = {},
            shadow = {},
		},
		letterInfo = {},
		parent = parent_,
		kerning_use = true, --TODO
		longestWidth = 1,
		longestHeight = 1,
		max_y_shift = 0,
		block_redo = false,

        multiline = true,
        breakwidth = false,
        horizontal_mode = setting.horizontal_mode or 1,
        vertical_mode = setting.vertical_mode or 1,
        font = {
            base = setting.font or BITMAPFONT['base'],
            size = setting.size or (defaults.font_size*1.5),
            color = setting.color or {r=255,g=255,b=255,a=255},
            shadow = {
                use = setting.use_shadow or false,
                color = setting.shadow_color or {r=0,g=0,b=0,a=255},
                offset = setting.shadow_offset or 10,
                angle = setting.shadow_angle or 135,
            },
            edge = {
                use = setting.use_edge or false,
                color = setting.edge_color or {r=0,g=0,b=0,a=255},
                offset = setting.edge_offset or 1,
            },
        },
    })

    function label:get_line_count()
        local txt = self.txt_obj:get_text() or ''
        local count = 1
        for _ in txt:gmatch('\n') do
            count = count + 1
        end
        return count
    end

    function label:set_text(value)
        if self.text == value then return end
        label.text = value
        clearGraphics(self)
        redoLetterPrimNames(self)
        redoLetterPositionInfo(self)
        createTextFromList(self)
        update_extents(self)
    end

    function label:set_horizontal_mode(mode)
        if self.horizontal_mode == mode then return end
        self.horizontal_mode = mode
        if mode < 1 or mode > 3 then
            error('Invalid horizontal mode. Please use 1, 2, or 3.')
        end
        setPositions(self)
        update_extents(self)
    end

    function label:set_vertical_mode(mode)
        if self.vertical_mode == mode then return end
        self.vertical_mode = mode
        if mode < 1 or mode > 3 then
            error('Invalid vertical mode. Please use 1, 2, or 3.')
        end
        setPositions(self)
        update_extents(self)
    end

    function label:set_autowidth(toggle)
        if self.auto_width == toggle then return end
        self.auto_width = toggle
        redoLetterPositionInfo(self)
        refreshPositionOnly(self)
        updateVisibility(self)
        update_extents(self)
    end

    function label:set_breakwidth(toggle)
        if self.breakwidth == toggle then return end
        self.breakwidth = toggle
        redoLetterPositionInfo(self)
        refreshPositionOnly(self)
        updateVisibility(self)
        update_extents(self)
    end

    function label:set_multiline(toggle)
        if self.multiline == toggle then return end
        self.multiline = toggle
        redoLetterPositionInfo(self)
        refreshPositionOnly(self)
        updateVisibility(self)
        update_extents(self)
    end

    function label:set_edge_use(toggle)
        if self.font.edge.use == toggle then return end
        self.font.edge.use = toggle
        if(toggle==false) then
            --just remove edge graphics
            clearEdgeGraphics(self)
        else
            --full remake
            _RemoveOutsidePrim(self)
            _RebuildOutsidePrim(self)
        end
        update_extents(self)
    end

    function label:set_edge_color(color)
        --check if color is valid
        if type(color) ~= "table" or not color.r or not color.g or not color.b or not color.a then
            error("Invalid color format. Please use a table with r, g, b, and a values.")
        end

        if self.font.edge.color == color then return end
        self.font.edge.color = color
        if(#self.graphics.shadow>0) then
            for entry=1,#self.graphics.letter do
                primSetColor(self.graphics.shadow[entry],self.font.edge.color.a,self.font.edge.color.r,self.font.edge.color.g,self.font.edge.color.b)
            end
        end
        update_extents(self)
    end

    function label:set_edge_color_argb(a,r,g,b)
        --check if color is valid
        if type(a) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
            error("Invalid color format. Please use numbers for a, r, g, and b values.")
        end

        if self.font.edge.color == {a=a, r=r, g=g, b=b} then return end
        self.font.edge.color = {a=a, r=r, g=g, b=b}
        if(#self.graphics.shadow>0) then
            for entry=1,#self.graphics.letter do
                primSetColor(self.graphics.shadow[entry],self.font.edge.color.a,self.font.edge.color.r,self.font.edge.color.g,self.font.edge.color.b)
            end
        end
        update_extents(self)
    end

    function label:set_edge_offset(offset)
        if self.font.edge.offset == offset then return end
        self.font.edge.offset = offset
		syncEdgeOffset(self)
        update_extents(self)
    end 

    function label:set_shadow_use(toggle)
        if self.font.shadow.use == toggle then return end
        self.font.shadow.use = toggle
        if(toggle==false) then
            --just remove shadow graphics
            clearShadowGraphics(self)
        else
            --full remake
            _RemoveOutsidePrim(self)
            _RebuildOutsidePrim(self)
        end
        update_extents(self)
    end

    function label:set_shadow_color(color)
        --check if color is valid
        if type(color) ~= "table" or not color.r or not color.g or not color.b or not color.a then
            error("Invalid color format. Please use a table with r, g, b, and a values.")
        end

        if self.font.shadow.color == color then return end
        self.font.shadow.color = color
        if(#self.graphics.shadow>0) then
            for entry=1,#self.graphics.letter do
                primSetColor(self.graphics.shadow[entry],self.font.shadow.color.a,self.font.shadow.color.r,self.font.shadow.color.g,self.font.shadow.color.b)
            end
        end
        update_extents(self)
    end

    function label:set_shadow_color_argb(a,r,g,b)
        --check if color is valid
        if type(a) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
            error("Invalid color format. Please use numbers for a, r, g, and b values.")
        end

        if self.font.shadow.color == {a=a, r=r, g=g, b=b} then return end
        self.font.shadow.color = {a=a, r=r, g=g, b=b}
        if(#self.graphics.shadow>0) then
            for entry=1,#self.graphics.letter do
                primSetColor(self.graphics.shadow[entry],self.font.shadow.color.a,self.font.shadow.color.r,self.font.shadow.color.g,self.font.shadow.color.b)
            end
        end
        update_extents(self)
    end

    function label:set_shadow_offset(offset)
        if self.font.shadow.offset == offset then return end
        self.font.shadow.offset = offset
        if(#self.graphics.shadow>0) then
            syncShadow(self)
        end
        update_extents(self)
    end 

    function label:set_shadow_angle(angle)
        if self.font.shadow.angle == angle then return end
        self.font.shadow.angle = angle
        if(#self.graphics.shadow>0) then
            syncShadow(self)
        end
        update_extents(self)
    end 



    function label:on_position_change()
        for entry=1,#self.letterInfo do
            if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
            x_dif =getXDif(self,entry)
            y_dif =getYDif(self,entry)
                if(self.font.shadow.use) then
                    setShadowGraphicsEntryPosition(self,entry,x_dif,y_dif)
                end
                --edges
                if(self.font.edge.use) then
                    setEdgeGraphicsEntryPosition(self,entry,x_dif,y_dif)
                end
                --letter
                --set position
                primSetPosition(self.graphics.letter[entry],self.x+self.letterInfo[entry].left+x_dif,self.y+self.letterInfo[entry].top+y_dif)
            end
        end
    end

    function label:on_size_change()
    end

    function label:on_refresh()
        local value = ''
        if label.fnc then value = tostring(label.fnc(label.arg1, label.arg2)) end
        local full_text = (label.pre_text and(label.pre_text ~= '') and (label.pre_text .. ': ' .. (value or ''))) or value or ''
		
		if self.text ~= full_text then
        	self:set_text(full_text)
		end
    end

    function label:refresh_width()
        return false, self.width
    end

    function label:refresh_height()
        return false, self.height
    end

	label:set_text((label.pre_text and(label.pre_text ~= '') and (label.pre_text .. ': ' .. (setting.text or ''))) or setting.text or '')
    label:update_absolute_position()
    return label
end