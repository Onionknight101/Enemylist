primList = {}
--primMemList = {}

local prim_buffer = {}

function prim_buffer.new(id)
    local obj = {
        active_id = id .. '_1',
        buffer_amount = 10,
        multi_buffer = {},
        queue = {}
    }

end


buffer_list = {}

function primGenerateName(name)
	while(primList[name]) do
		name=name..stringFunctions.randomString(5)
	end
	primList[name] = true
	return name
end

function primRemoveNameFromList(name)
	if(primList[name]) then
		primList[name] = nil
	end
end

function primCreate(name)
	windower.prim.create(name)
	set_registry_value('prim_image_count', get_registry_value('prim_image_count')+1)
	--primMemList[name] = true
		--windower.console.write('prim c '..name..' '..tableFunctions.count(primMemList))
end

function primDelete(name)
	windower.prim.delete(name)
	set_registry_value('prim_image_count', get_registry_value('prim_image_count')-1)
	--primMemList[name] = nil
		--windower.console.write('prim d '..name..' '..tableFunctions.count(primMemList))
end

function primSetColor(name,a,r,g,b)
    windower.prim.set_color(name,a,r,g,b)
end

function primSetTexture(name,path)
	windower.prim.set_texture(name,path)
end 

function primVisibility(name,isVisible)
	windower.prim.set_visibility(name,isVisible)
end
	
function primSetPosition(name,x,y)
	windower.prim.set_position(name,x,y)
end

function primSetSize(name,width,height)
	windower.prim.set_size(name,width,height)
end	

function primSetFitToTexture(name,setFit)
	windower.prim.set_fit_to_texture(name,setFit)
end

