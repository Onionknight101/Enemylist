primList = {}
--primMemList = {}

local prim_buffer = {}


buffer_list = {}

function primGenerateName(name)
	while(primList[name]) do
		name=name..stringFunctions.randomString(5)
	end
	primList[name] = prim_buffer.new(name)
	return name
end

function primRemoveNameFromList(name)
	if(primList[name]) then
		primList[name]:clear()
		primList[name] = nil
	end
end

function primCreate(name)
	if(primList[name]) then
		primList[name]:primCreate()
	end
end

function primDelete(name)
	if(primList[name]) then
		primList[name]:primDelete()
	end
end

function primSetColor(name,a,r,g,b)
    -- windower.prim.set_color(name,a,r,g,b)

	if(primList[name]) then
		primList[name]:primSetColor(a,r,g,b)
	end
end

function primSetTexture(name,path)
	-- windower.prim.set_texture(name,path)
	if(primList[name]) then
		primList[name]:primSetTexture(path)
	end
end 

function primVisibility(name,isVisible)
	-- windower.prim.set_visibility(name,isVisible)
	
	if(primList[name]) then
		primList[name]:primVisibility(isVisible)
	end
end
	
function primSetPosition(name,x,y)
	-- windower.prim.set_position(name,x,y)

	if(primList[name]) then
		primList[name]:primSetPosition(x, y)
	end
end

function primSetSize(name,width,height)
	-- windower.prim.set_size(name,width,height)
	if(primList[name]) then
		primList[name]:primSetSize(width, height)
	end
end	

function primSetFitToTexture(name,setFit)
	-- windower.prim.set_fit_to_texture(name,setFit)
	if(primList[name]) then
		primList[name]:primSetFitToTexture(setFit)
	end
end

function primGetCount(name)
	if(primList[name]) then
		return primList[name].prim_count
	end
	return 0
end

local buffer_wait_time = 0.5

function prim_buffer.new(id)
    local obj = {
        active_id = id .. '_1',
		prim_count = 0,
        buffer_amount = 1,
		current_slot=1,
		in_use = {},
        multi_buffer = {},
		is_visible = true,
        queue = {},
        hightest_queue_slot = 1,
		path = nil,
    }

    for i=1, obj.buffer_amount do
        table.insert(obj.multi_buffer, id .. '_' .. i)
    end

	function obj:clear()
		for i=1,self.buffer_amount do
			-- print('clearing prim '..self.multi_buffer[i])
			windower.prim.delete(self.multi_buffer[i])
		end
	end

	function obj:primCreate()
		for i=1,self.buffer_amount do
			-- print('creating prim '..self.multi_buffer[i])
			windower.prim.create(self.multi_buffer[i])
			obj.prim_count = obj.prim_count + 1
			set_registry_value('prim_image_count', get_registry_value('prim_image_count')+1)
			if self.active_id == self.multi_buffer[i] then
				windower.prim.set_visibility(self.multi_buffer[i],isVisible)
			else
				windower.prim.set_visibility(self.multi_buffer[i],false)
			end
			--  print('created prim '..self.multi_buffer[i],obj.prim_count)
		end
	end

	function obj:primDelete()
		for i=1,self.buffer_amount do
			-- print('deleting prim '..self.multi_buffer[i])
			windower.prim.delete(self.multi_buffer[i])
			obj.prim_count = obj.prim_count - 1
			set_registry_value('prim_image_count', get_registry_value('prim_image_count')-1)
		end
	end

	function obj:primSetColor(a,r,g,b)
		for i=1,self.buffer_amount do
			-- print('setting color of '..self.multi_buffer[i]..' to '..tostring(a)..','..tostring(r)..','..tostring(g)..','..tostring(b))
			windower.prim.set_color(self.multi_buffer[i],a,r,g,b)
		end
	end

	function obj:primVisibility(isVisible)
		-- print('setting visibility of '..self.active_id..' to '..tostring(isVisible))
		windower.prim.set_visibility(self.active_id,isVisible)
		self.is_visible = isVisible
	end

	function obj:primSetPosition(x, y)
		for i=1,self.buffer_amount do
			-- print('setting position of '..self.multi_buffer[i]..' to '..x..','..y)
			windower.prim.set_position(self.multi_buffer[i],x,y)
		end
	end

	function obj:primSetSize(width, height)
		for i=1,self.buffer_amount do
			-- print('setting size of '..self.multi_buffer[i]..' to '..width..','..height)
			windower.prim.set_size(self.multi_buffer[i],width,height)
		end
	end

	function obj:primSetFitToTexture(setFit)
		for i=1,self.buffer_amount do
			windower.prim.set_fit_to_texture(self.multi_buffer[i],setFit)
		end
	end

	function obj:primSetTexture(path)
		-- print('setting texture of '..self.active_id..' to '..path)
		if self.path == path then return end
		self.path = path

		--get a free id from the buffer and check the queue for the time it was set. 

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
			if self.buffer_amount > 1 then
				--use slot 2
				self.queue[#self.queue].time = os.clock()
				self.hightest_queue_slot = #self.queue
				windower.prim.set_texture(self.queue[#self.queue].id, path)
				-- print('B queued texture '..path..' to show after '..buffer_wait_time..' seconds on '..self.queue[#self.queue].id)
			else
				--no free id. single buffer
				windower.prim.set_texture(self.active_id, path)
			end
		else
			table.insert(self.queue, {time = os.clock(), id = found_id})
			self.hightest_queue_slot = #self.queue
			windower.prim.set_texture(found_id, path)
			-- print('queued texture '..path..' to show after '..buffer_wait_time..' seconds on '..found_id)
		end
	end


    if obj.buffer_amount > 1 then
        obj.timer = Timers.add('img_' .. id, 0.1, 0.1, true, function()
			-- local item = obj.queue[obj.hightest_queue_slot]
			-- if item and os.clock() - item.time >= buffer_wait_time then
			-- 	obj.queue = {}
        	-- 	windower.prim.set_visibility(obj.active_id, false)
			-- 	obj.active_id = item.id
			-- 	windower.prim.set_visibility(obj.active_id, obj.is_visible)
			-- end	
			 for i=1, #obj.queue do
        --    print('checking buffer queue for '..id..' with '..i..'/'..tostring(#obj.queue)..' items')
                local item = obj.queue[i]
                if os.clock() - item.time >= buffer_wait_time then
                    --hide current active and show new
                    windower.prim.set_visibility(obj.active_id, false)
                    obj.active_id = item.id
					print('switching to '..obj.active_id,' after '..tostring(os.clock() - item.time)..' seconds',obj.is_visible)
                    windower.prim.set_visibility(obj.active_id, obj.is_visible)
                    table.remove(obj.queue, i)
					break
                end
            end
        end)
    end
	
	return obj
end