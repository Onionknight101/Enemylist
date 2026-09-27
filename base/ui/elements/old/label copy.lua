
-- require('onion/system/font');
-- require('onion/functions/stringFunctions');
-- require('onion/handling/onionViewHandling');
-- require('onion/handling/onionMouseHandling')
-- require('onion/handling/onionTextHandling')
-- require('onion/handling/onionColorHandling')
-- require('onion/handling/onionValueHandling')
-- require('onion/handling/onionNumberHandling')
-- require('test/testTable');

onionLabel = {
}

function onionLabel:getXDif(entry)
	if(self.horizontal_mode:get()==1) then
		return self.line[self.letterInfo[entry].line].max_x_shift/2.0
	elseif(self.horizontal_mode:get()==2) then
		return self.line[self.letterInfo[entry].line].max_x_shift
	else 
		return 0
	end
end

function onionLabel:getYDif(entry)
	if(self.vertical_mode:get()==1) then
		return self.max_y_shift/2.0
	elseif(self.vertical_mode:get()==2) then
		return self.max_y_shift
	else 
		return 0
	end
end

function onionLabel:clearGraphics()
	--clear graphics
	for entry=1,#self.graphics.letter do
		--remove letter graphics
		primDelete(self.graphics.letter[entry])
		primRemoveNameFromList(self.graphics.letter[entry])
		--remove edge graphics
		if(#self.graphics.edge>0) then
			for i=1,4 do
				primDelete(self.graphics.edge[((entry-1)*4)+i])
				primRemoveNameFromList(self.graphics.edge[((entry-1)*4)+i])
			end
		end
		--remove shadow graphics
		if(#self.graphics.shadow>0) then
			primDelete(self.graphics.shadow[entry])
			primRemoveNameFromList(self.graphics.shadow[entry])
		end
		table.remove(self.letterInfo,1)
	end
end

function onionLabel:clearEdgeGraphics()
	for entry=1,#self.graphics.letter do
		--remove edge graphics
		if(#self.graphics.edge>0) then
			for i=1,4 do
				primDelete(self.graphics.edge[((entry-1)*4)+i])
			end
		end
	end
end

function onionLabel:addEdgeGraphicsEntry(entry)
	for i=1,4 do
		primCreate(self.graphics.edge[((entry-1)*4)+i])
		primVisibility(self.graphics.edge[((entry-1)*4)+i],self.letterInfo[entry].visibility)
		primSetColor(self.graphics.edge[((entry-1)*4)+i],self.edge.color.a,self.edge.color.r,self.edge.color.g,self.edge.color.b)
	end
	--left
	primSetSize(self.graphics.edge[((entry-1)*4)+1],self.letterInfo[entry].width,self.letterInfo[entry].height)
	primSetTexture(self.graphics.edge[((entry-1)*4)+1],self.text.font:get().folder..'/'..self.letterInfo[entry].code..'.png')
	primSetFitToTexture(self.graphics.edge[((entry-1)*4)+1],false)
	--top
	primSetSize(self.graphics.edge[((entry-1)*4)+2],self.letterInfo[entry].width,self.letterInfo[entry].height)
	primSetTexture(self.graphics.edge[((entry-1)*4)+2],self.text.font:get().folder..'/'..self.letterInfo[entry].code..'.png')
	primSetFitToTexture(self.graphics.edge[((entry-1)*4)+2],false)
	--right
	primSetSize(self.graphics.edge[((entry-1)*4)+3],self.letterInfo[entry].width,self.letterInfo[entry].height)
	primSetTexture(self.graphics.edge[((entry-1)*4)+3],self.text.font:get().folder..'/'..self.letterInfo[entry].code..'.png')
	primSetFitToTexture(self.graphics.edge[((entry-1)*4)+3],false)
	--bottom
	primSetSize(self.graphics.edge[((entry-1)*4)+4],self.letterInfo[entry].width,self.letterInfo[entry].height)
	primSetTexture(self.graphics.edge[((entry-1)*4)+4],self.text.font:get().folder..'/'..self.letterInfo[entry].code..'.png')
	primSetFitToTexture(self.graphics.edge[((entry-1)*4)+4],false)
end

function onionLabel:addEdgeGraphics()
	--add edge graphics
	if(#self.graphics.edge>0) then
		for entry=1,#self.graphics.letter do
			if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
				self:addEdgeGraphicsEntry(entry)
				self:setEdgeGraphicsEntryPosition(entry,self:getXDif(entry),self:getYDif(entry))
			end
		end
	end
end

function onionLabel:setEdgeGraphicsEntryPosition(entry,x_dif,y_dif)
	--left
		primSetPosition(self.graphics.edge[((entry-1)*4)+1],self.view.rawX+self.letterInfo[entry].edge.left.left+x_dif,self.view.rawY+self.letterInfo[entry].edge.left.top+y_dif)
	--top
		primSetPosition(self.graphics.edge[((entry-1)*4)+2],self.view.rawX+self.letterInfo[entry].edge.top.left+x_dif,self.view.rawY+self.letterInfo[entry].edge.top.top+y_dif)
	--right
		primSetPosition(self.graphics.edge[((entry-1)*4)+3],self.view.rawX+self.letterInfo[entry].edge.right.left+x_dif,self.view.rawY+self.letterInfo[entry].edge.right.top+y_dif)
	--bottom
		primSetPosition(self.graphics.edge[((entry-1)*4)+4],self.view.rawX+self.letterInfo[entry].edge.bottom.left+x_dif,self.view.rawY+self.letterInfo[entry].edge.bottom.top+y_dif)
end

function onionLabel:syncEdgeOffset()
	for entry=1,#self.graphics.letter do
		if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
			self.letterInfo[entry].edge.left.left = self.letterInfo[entry].left-self.edge.offset:get()
			self.letterInfo[entry].edge.left.top = self.letterInfo[entry].top
			self.letterInfo[entry].edge.top.left = self.letterInfo[entry].left
			self.letterInfo[entry].edge.top.top = self.letterInfo[entry].top-self.edge.offset:get()
			self.letterInfo[entry].edge.right.left = self.letterInfo[entry].left+self.edge.offset:get()
			self.letterInfo[entry].edge.right.top = self.letterInfo[entry].top
			self.letterInfo[entry].edge.bottom.left = self.letterInfo[entry].left
			self.letterInfo[entry].edge.bottom.top = self.letterInfo[entry].top+self.edge.offset:get()
			self:setEdgeGraphicsEntryPosition(entry,self:getXDif(entry),self:getYDif(entry))
		end
	end
end

function onionLabel:clearShadowGraphics()
	for entry=1,#self.graphics.letter do
		--remove shadow graphics
		if(#self.graphics.shadow>0) then
			primDelete(self.graphics.shadow[entry])
		end
	end
end

function onionLabel:addShadowGraphicsEntry(entry)
	primCreate(self.graphics.shadow[entry])
	primVisibility(self.graphics.shadow[entry],self.letterInfo[entry].visibility)
	primSetColor(self.graphics.shadow[entry],self.shadow.color.a,self.shadow.color.r,self.shadow.color.g,self.shadow.color.b)
	primSetSize(self.graphics.shadow[entry],self.letterInfo[entry].width,self.letterInfo[entry].height)
	primSetTexture(self.graphics.shadow[entry],self.text.font:get().folder..'/'..self.letterInfo[entry].code..'.png')
	primSetFitToTexture(self.graphics.shadow[entry],false)
end

function onionLabel:addShadowGraphics()
	--add shadow graphics
	if(#self.graphics.shadow>0) then
		for entry=1,#self.graphics.letter do
			if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
				self:addShadowGraphicsEntry(entry)
				self:setShadowGraphicsEntryPosition(entry,self:getXDif(entry),self:getYDif(entry))
			end
		end
	end
end

function onionLabel:setShadowGraphicsEntryPosition(entry,x_dif,y_dif)
	primSetPosition(self.graphics.shadow[entry],self.view.rawX+self.letterInfo[entry].shadow.left+x_dif,self.view.rawY+self.letterInfo[entry].shadow.top+y_dif)
end

function onionLabel:syncShadow()
	shadowRad = math.rad(self.shadow.angle:get()-90)
	for entry=1,#self.graphics.letter do
		if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
			self.letterInfo[entry].shadow.left =self.letterInfo[entry].left+(math.cos(shadowRad)*self.shadow.offset:get())
			self.letterInfo[entry].shadow.top=self.letterInfo[entry].top+(math.sin(shadowRad)*self.shadow.offset:get())
			self:setShadowGraphicsEntryPosition(entry,self:getXDif(entry),self:getYDif(entry))
		end
	end
end

function onionLabel:setPositions()
	for entry=1,#self.letterInfo do
		if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
		x_dif =self:getXDif(entry)
		y_dif =self:getYDif(entry)
			if(self.shadow.use:get()) then
				self:setShadowGraphicsEntryPosition(entry,x_dif,y_dif)
			end
			--edges
			if(self.edge.use:get()) then
				self:setEdgeGraphicsEntryPosition(entry,x_dif,y_dif)
			end
			--letter
			--set position
			primSetPosition(self.graphics.letter[entry],self.view.rawX+self.letterInfo[entry].left+x_dif,self.view.rawY+self.letterInfo[entry].top+y_dif)
		end
	end
end


function onionLabel:createTextFromList()
	for entry=1,#self.letterInfo do
		--create shadows
		if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
			if(self.shadow.use:get()) then
				self:addShadowGraphicsEntry(entry)
			end
			--edges
			if(self.edge.use:get()) then
				self:addEdgeGraphicsEntry(entry)
			end
			--letter
			primCreate(self.graphics.letter[entry])
			primVisibility(self.graphics.letter[entry],self.letterInfo[entry].visibility)
			primSetColor(self.graphics.letter[entry],self.text.color.a,self.text.color.r,self.text.color.g,self.text.color.b)
			-- set texture
			primSetTexture(self.graphics.letter[entry],self.text.font:get().folder..'/'..self.letterInfo[entry].code..'.png')
			primSetFitToTexture(self.graphics.letter[entry],false)
			--set size
			primSetSize(self.graphics.letter[entry],self.letterInfo[entry].width,self.letterInfo[entry].height)
		end
	end
	self:setPositions()
end

-- function onionLabel:setVisibility()
	-- for entry=1,#self.letterInfo do
		-- primVisibility(self.graphics.shadow[entry],self.letterInfo[entry].visibility)
		-- for i=1,4 do
			-- primVisibility(self.graphics.edge[((entry-1)*4)+i],self.letterInfo[entry].visibility)
		-- end
		-- primVisibility(self.graphics.letter[entry],self.letterInfo[entry].visibility)
	-- end
-- end

function onionLabel:setVisibility(entry)
	primVisibility(self.graphics.shadow[entry],self.letterInfo[entry].visibility)
	for i=1,4 do
		primVisibility(self.graphics.edge[((entry-1)*4)+i],self.letterInfo[entry].visibility)
	end
	primVisibility(self.graphics.letter[entry],self.letterInfo[entry].visibility)
end

function onionLabel:updateVisibility()
	for entry=1,#self.letterInfo do	
		if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
			if(self.clip:get()) then
				
				if(self.letterInfo[entry].left<self.view.width :get()
				and self.letterInfo[entry].left+self.letterInfo[entry].width<self.view.width:get()
				and self.letterInfo[entry].top<self.view.height:get()
				and self.letterInfo[entry].top+self.letterInfo[entry].height<self.view.height:get()) then
					if(self.letterInfo[entry].visibility~=self.view.visibility) then
						self.letterInfo[entry].visibility=self.view.visibility
						self:setVisibility(entry)
					end
				else
					if(self.letterInfo[entry].visibility~=false) then
						self.letterInfo[entry].visibility=false
						self:setVisibility(entry)
					end
				end
			else
				if(self.letterInfo[entry].visibility~=self.view.visibility) then
					self.letterInfo[entry].visibility=self.view.visibility
					self:setVisibility(entry)
				end
			end
		else
			if(self.letterInfo[entry].visibility~=false) then
				self.letterInfo[entry].visibility=false
				self:setVisibility(entry)
			end
		end
	end
end

function onionLabel:redoShiftInfo()
	--calculate mode max shift values
	if(self.longestHeight<self.view.height:get()) then
		self.max_y_shift = self.view.height:get()-self.longestHeight
	else
		self.max_y_shift = 0
	end
	for entry=1,string.len(self.text:get()) do
		if(self.longestWidth<self.view.width:get()) then 
			self.line[self.letterInfo[entry].line].max_x_shift = self.view.width:get()-self.line[self.letterInfo[entry].line].width
		else
			self.line[self.letterInfo[entry].line].max_x_shift = 0
		end
	end
end

function onionLabel:redoLetterPrimNames()
	--clear old tables
	for entry=1,#self.graphics.letter do
		--remove letter graphics
		primRemoveNameFromList(self.graphics.letter)
		table.remove(self.graphics.letter,1)
		--remove edge graphics
		if(#self.graphics.edge>0) then
			for i=1,4 do
				primRemoveNameFromList(self.graphics.edge[1])
				table.remove(self.graphics.edge,1)
			end
		end
		--remove shadow graphics
		if(#self.graphics.shadow>0) then
			primRemoveNameFromList(self.graphics.shadow[1])
			table.remove(self.graphics.shadow,1)
		end
		table.remove(self.letterInfo,1)
	end

	txtLen = string.len(self.text:get())
	if(txtLen==0) then return end
	--create shadows
	for entry=1,txtLen do
		table.insert(self.graphics.shadow,primGenerateName(self.name..'shadow'..entry..''..stringFunctions.randomString(5)))
	end
	--create edges and letters
	for entry=1,txtLen do
		--edges
		for i=1,4 do
			table.insert(self.graphics.edge,primGenerateName(self.name..'edge'..((entry-1)*4)+i..''..stringFunctions.randomString(5)))
		end
		--letter
		table.insert(self.graphics.letter,primGenerateName(self.name..entry..'letter'..stringFunctions.randomString(5)))
	end
end

function onionLabel:redoLetterPositionInfo()
	--clear
	--clear info objects
	self.letterInfo = {}
	self.line = {}
	
	--check textLength
	txtLen = string.len(self.text:get())
	--exit if text length is 0
	if(txtLen==0) then return end
		curX=0
		curY=0
		
		oldLen = #self.graphics.letter
		lineSpacing = self.text.font:get()['verticalSpacing']*self.text.size:get()
	if(lineSpacing < self.text.font:get()['minimumLineSpacing']) then
		lineSpacing = self.text.font:get()['minimumLineSpacing']
	end
	
	if(self.multiline:get()) then
		if(self.autosize:get()) then
			_BreakWidth = false
		else
			_BreakWidth = self.breakwidth:get()
		end
	else
		_BreakWidth = false
	end
	
	self.longestWidth = 1
	--create from start
	
	--shadow radians. angle -90 cause angles are east directed at 0 stanndard
	shadowRad = math.rad(self.shadow.angle:get()-90)
	
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
			curChar = string.sub(self.text:get(),entry,entry)
			curCode = string.byte(curChar)
			if(curCode==10 or curCode == 32) then --newline or space
				--next word starts at the next entry
				wordStartEntry = entry+1
				--newline check
				if(curCode==10) then
					--log position
					self.letterInfo[entry] = {
						['left']=curX,
						['top']=curY,
						['width']=1,
						['height']=self.text.size:get(),
						['line']=currentLine,
						['code']=curCode,
					}
					
					if(self.multiline:get()) then
						
						if(curX>self.longestWidth) then
							self.longestWidth = curX
						end
						self.line[currentLine] ={['width']=self.letterInfo[entry].left}
						currentLine = currentLine+1
						curX=0
						curY=curY+self.text.size:get()-lineSpacing 
						lineStartEntry = entry+1
					else
						curX = curX+1
					end
				elseif(curCode==32) then
					--log position
					self.letterInfo[entry] = {
						['left']=curX,
						['top']=curY,
						['width']=math.floor((self.text.font:get()['letter'][curCode]['size']/self.text.font:get()['basePixelSize'])*self.text.size:get()),
						['height']=self.text.size:get(),
						['line']=currentLine,
						['code']=curCode,
						
					}
					
					curX = curX+self.letterInfo[entry]['width']
				end
			else
				--get letter width
				shiftPercent= self.text.font:get()['letter'][curCode]['size']/self.text.font:get()['basePixelSize']
				--log info
				self.letterInfo[entry] = {
					['left']=curX,
					['top']=curY,
					['width']=self.text.size:get()*shiftPercent,
					['height']=self.text.size:get(),
					['line']=currentLine,
					['code']=curCode,
					['edge']={
						['offset'] = self.edge.offset:get(),
						['left']={
								['left']=curX-self.edge.offset:get(),
								['top']=curY,
								},
						['top']={
								['left']=curX,
								['top']=curY-self.edge.offset:get(),
								},
						['right']={
								['left']=curX+self.edge.offset:get(),
								['top']=curY,
								},
						['bottom']={
								['left']=curX,
								['top']=curY+self.edge.offset:get(),
								},
					},
					['shadow']={
								['left']=curX+(math.cos(shadowRad)*self.shadow.offset:get()),
								['top']=curY+(math.sin(shadowRad)*self.shadow.offset:get()),
					},
				}
				
				--set left shift if available
				if(self.text.font:get()['letter'][curCode]['left']) then
					shiftPercent=shiftPercent-self.text.font:get()['letter'][curCode]['left']/self.text.font:get()['basePixelSize']
				end
				--get next char code
				nextCode =string.byte( string.sub(self.text:get(),entry+1,entry+1))
				if(entry<txtLen and nextCode~=10) then
					if(self.kerning_use and self.text.font:get()['letter'][curCode]['kerning'][nextCode]) then
						shiftPercent = shiftPercent-(self.text.font:get()['letter'][curCode]['kerning'][nextCode]/self.text.font:get()['basePixelSize'])
					end
				end
				--if we cant get over the width and this isnt a space then newline the graphics starting at the wordStartEntry
				if(self.multiline:get()) then
					if(_BreakWidth and curX+math.floor(shiftPercent*self.text.size:get())>=self.view:getRight() and lineStartEntry ~= wordStartEntry) then
						self.line[currentLine] ={['width']=self.letterInfo[wordStartEntry-1].left+self.letterInfo[wordStartEntry-1].width}
						currentLine = currentLine+1
						
						curX=0
						curY=curY+self.text.size:get()-lineSpacing
						--set current entry at 1 entry befor wordStartEntry. avoid this when this is the first letter in a word
						exitAt = wordStartEntry
						lineStartEntry = wordStartEntry
						break
					else
						curX = curX+math.floor(shiftPercent*self.text.size:get())
					end
				else
					curX = curX+math.floor(shiftPercent*self.text.size:get())
				end
			end
			exitAt = entry
		end
	end
	
	--autosize if required
	--if(self.block_redo==false) then
	--		self.block_redo = true
		--add last linewidth
		self.line[currentLine] ={['width']= self.letterInfo[txtLen].left+self.letterInfo[txtLen].width}
		--last longestWidth check
		if(curX>self.longestWidth) then
			self.longestWidth = curX
		end
		--longestHeight check
		self.longestHeight = self.letterInfo[txtLen].top+self.letterInfo[txtLen].height
		
		if(self.autosize:get()) then
			addition = 0
			if(self.edge.use:get()) then
				addition = self.edge.offset:get()
			end
			if(self.shadow.use:get() and math.cos(shadowRad)*self.shadow.offset:get()>addition) then
				addition = math.cos(shadowRad)*self.shadow.offset:get()
			end
			
			self.view:setSize(self.longestWidth+addition,curY+self.text.size:get()-lineSpacing)
			
			self.max_y_shift = 0
			self.line[self.letterInfo[entry].line].max_x_shift = 0
		else
			--calculate mode max shift values
			self:redoShiftInfo()
		end
		--visibility
		self:updateVisibility()
		--keep drawOrder
		--if(not self.view:isTopView()) then
		--end
--		self.block_redo = false
	--end

end

function onionLabel:refreshFullSize()
	--breakwidth
	--autosize
	--clip
	--horizontal_mode
	--vertical_mode
	if(self.breakwidth:get() or self.autosize:get() or self.horizontal_mode:get()~=0 or self.vertical_mode:get()~=0) then
		self:redoLetterPositionInfo()
		--self:createTextFromList()
		self:refreshPositionOnly()
		self:updateVisibility()
	else
		--self:redoShiftInfo()
		--self:refreshPositionOnly()
		self:updateVisibility()
	end
end

function onionLabel:refreshPositionOnly()
	--self:redoLetterPositionInfo()
	--self:createTextFromList()
	
	for entry=1,#self.letterInfo do
		if(self.letterInfo[entry].code ~= 10 and self.letterInfo[entry].code ~= 32) then
		x_dif =self:getXDif(entry)
		y_dif =self:getYDif(entry)
			if(self.shadow.use:get()) then
				self:setShadowGraphicsEntryPosition(entry,x_dif,y_dif)
			end
			--edges
			if(self.edge.use:get()) then
				self:setEdgeGraphicsEntryPosition(entry,x_dif,y_dif)
			end
			--letter
			--set position
			primSetPosition(self.graphics.letter[entry],self.view.rawX+self.letterInfo[entry].left+x_dif,self.view.rawY+self.letterInfo[entry].top+y_dif)
		end
	end
	
end

function onionLabel:setColor(a,r,g,b)
	if(self.text.color.a ~= a or self.text.color.r ~= r or self.text.color.g ~= g or self.text.color.b ~= b) then
		for entry=1,#self.graphics.letter do
			primSetColor(self.graphics.letter[entry],self.text.color.a,self.text.color.r,self.text.color.g,self.text.color.b)
		end
	end
end

function onionLabel:setStrokeColor(a,r,g,b)
    --TODO
end

function onionLabel:setStrokeWidth(width_)
    --TODO
end

function onionLabel:pointIsInObject(x,y)
	--is it in current objects area?

	if(self.view:pointIsInPosition(x,y)) then
		return self;
	end
	return nil;
end

function onionLabel:checkMouseEvent(event)
	lEvent = self.mouseEvent.last 
	self.mouseEvent.last = event
	
	--check if the event happend in this objects area
	if(self.view:pointIsInPosition(event.x,event.y)) then
		return self
	end
	return nil
end

function onionLabel:_RebuildOutsidePrim()
	self:createTextFromList()
end

function onionLabel:_RemoveOutsidePrim()
	for entry=1,#self.graphics.letter do
		--remove letter graphics
		primDelete(self.graphics.letter[entry])
		--remove edge graphics
		if(#self.graphics.edge>0) then
			for i=1,4 do
				primDelete(self.graphics.edge[((entry-1)*4)+i])
			end
		end
		--remove shadow graphics
		if(#self.graphics.shadow>0) then
			primDelete(self.graphics.shadow[entry])
		end
	end
end

function onionLabel:new (parent_,name_,font_,size_)
	local o = {
		name = name_,
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
	}
    self.__index = self
	local combined = setmetatable(o, self) 
	
	combined.view = onionViewHandling:new(combined)
	
	combined.mouse = onionMouseHandling:new(combined)
	
	combined.text = onionTextHandling:new(combined,'',font_,size_,255,255,255,255,
			function(value)
				combined:clearGraphics()
				combined:redoLetterPrimNames()
				combined:redoLetterPositionInfo()
				combined:createTextFromList()
				--combined.view:redrawFromView()
			end,
			function(a_,r_,g_,b_)
				for entry=1,#combined.graphics.letter do
					primSetColor(combined.graphics.letter[1],a_,r_,g_,b_)
				end
			end)
			
	combined.line = {}		
			
	--horizontal_mode 
	--0 = left
	--1 = middle
	--2 = right
	combined.horizontal_mode = onionValueHandling:new(0,
				function(value)
					if(value==0 or value==1 or value==2) then
						--reset positions
						combined:setPositions()
					else
						return false
					end
				end)
	--vertical_mode 
	--0 = top
	--1 = middle
	--2 = bottom
	combined.vertical_mode = onionValueHandling:new(0,
				function(value)
					if(value==0 or value==1 or value==2) then
						--reset positions
						combined:setPositions()
					else
						return false
					end
				end)
	
	combined.autosize = onionValueHandling:new(false,
				function(value)
					combined:redoLetterPositionInfo()
					--combined:createTextFromList()
					combined:refreshPositionOnly()
					combined:updateVisibility()
					combined.view:redrawFromView()
				end)
	
	combined.breakwidth = onionValueHandling:new(false,
				function(value)
					combined:redoLetterPositionInfo()
					--combined:createTextFromList()
					combined:refreshPositionOnly()
					combined:updateVisibility()
					combined.view:redrawFromView()
				end)
	
	combined.multiline = onionValueHandling:new(true,
				function(value)
					combined:redoLetterPositionInfo()
					--combined:createTextFromList()
					combined:refreshPositionOnly()
					combined:updateVisibility()
					combined.view:redrawFromView()
				end)
				
	combined.edge = {
			use = onionValueHandling:new(false,
				function(value)
					if(value==false) then
						--just remove edge graphics
						combined:clearEdgeGraphics()
					else
						--full remake
						combined:_RemoveOutsidePrim()
						combined:_RebuildOutsidePrim()
					end
				end),
			color = onionColorHandling:new(combined.edge,255,0,0,0,
				function(a_,r_,g_,b_)
					if(#combined.graphics.edge>0) then
						for entry=1,#combined.graphics.letter do
							for i=1,4 do
								primSetColor(combined.graphics.edge[((entry-1)*4)+i],a_,r_,g_,b_)
							end
						end
					end
				end),
			offset = onionValueHandling:new(1,
				function(value)
					combined:syncEdgeOffset()
				end),
		}
	combined.shadow = {
			use = onionValueHandling:new(false,
				function(value)
					if(value==false)then
						--just remove shadow graphics
						combined:clearShadowGraphics()
					else
						--full remake
						combined:_RemoveOutsidePrim()
						combined:_RebuildOutsidePrim()
					end
				end),
			color = onionColorHandling:new(combined.shadow,255,128,128,128,
				function(a_,r_,g_,b_)
					if(#combined.graphics.shadow>0) then
						for entry=1,#combined.graphics.letter do
							primSetColor(combined.graphics.shadow[entry],a_,r_,g_,b_)
						end
					end
				end),
			offset = onionValueHandling:new(10,
				function(value)
					if(#combined.graphics.shadow>0) then
						combined:syncShadow()
					end
				end),
			angle = onionValueHandling:new(135,
				function(value)
					if(#combined.graphics.shadow>0) then
						combined:syncShadow()
					end
				end),
		}
			
	combined.clip = onionValueHandling:new(true,
				function(value)
					--update visibility
					combined:updateVisibility()
				end)
		
	combined.view.events.visibilityChange = function(newVis)	
		combined:updateVisibility()
	end			
				
	combined.view:refresh(true,true,true)
	
	return combined
end

function onionLabel:destroy()
	if(self.view==nil) then return end
	if(self.parent ~= nil and self.parent.child~=nil) then
		self.parent.child:remove(self.name)
	end
	self:clearGraphics()
	self.view:destroy()
	self.name = nil
	self.view = nil
	self.graphics = nil
	self.letterInfo=nil
	self.parent = nil
	self.text:destroy()
	self.text=nil
	self.mouse:destroy()
	self.mouse=nil
	self.line = nil
	self.kerning_use = nil
	self.longestWidth = nil
	self.longestHeight = nil
	self.max_y_shift = nil
	self.block_redo = nil
	self.horizontal_mode:destroy()
	self.horizontal_mode=nil
	self.vertical_mode:destroy()
	self.vertical_mode=nil
	self.autosize:destroy()
	self.autosize=nil
	self.breakwidth:destroy()
	self.breakwidth=nil
	self.multiline:destroy()
	self.multiline=nil
	self.clip:destroy()
	self.clip=nil
	self.edge.use:destroy()
	self.edge.use=nil
	self.edge.color:destroy()
	self.edge.color=nil
	self.edge.offset:destroy()
	self.edge.offset=nil
	self.shadow.use:destroy()
	self.shadow.use=nil
	self.shadow.color:destroy()
	self.shadow.color=nil
	self.shadow.offset:destroy()
	self.shadow.offset=nil
	self.angle=nil
end





