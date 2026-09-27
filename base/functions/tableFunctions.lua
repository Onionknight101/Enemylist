tableFunctions = {}

function tableFunctions.dots_to_string(...)
	local l = {...}
	local retS = ''
	for i=1,#l do
		retS = retS..l[i]
		if(i<#l) then retS = retS..' ' end
	end
	return retS
end

function tableFunctions.contains(t,val)
	for i=1,#t do
		if(t[i] == val) then
			return true
		end
	end
	return false
end

function tableFunctions.contains_keyed(t,val)
	for k,v in pairs(t) do
		if(v == val) then
			return true
		end
	end
	return false
end

function tableFunctions.count(t)
	local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
	return count
end

function tableFunctions.is_empty(t)
	return tableFunctions.count(t)==0
end

function tableFunctions.count_with_numeric(t)
	local count = 0
    for k, v in pairs(t) do
		if(tonumber(k)) then
			count = count + 1
		end
    end
	return count
end

function tableFunctions.index_of(t,o)
	for i=1, #t do
      if(t[i]==o) then return i end
	end 
	return -1
end

function tableFunctions.add(t1,t2)
	for k, v in  ipairs (t2) do
      table.insert (t1, v)
	end 
 
   return t1
end

function tableFunctions.remove(t,o)
	for k, v in  ipairs (t) do
      if(v==o) then t[k]=nil return end
	end 
	
	for i=1, #t do
      if(t[i]==o) then table.remove(t,i) return end
	end 
end

function tableFunctions.add_to_top(t,entry,max_length)
	if(#t>=max_length) then table.remove(t,1) end
	t[#t+1] = entry
end

function tableFunctions.get_entry_by_field(t,field_name_,field_val_)
	for k,v in pairs(t) do
		if(v[field_name_] and v[field_name_] == field_val_) then return v end
	end
	return nil
end

function tableFunctions.merge(target, source)
	for k, v in pairs(source) do
		if not v then 
			return
		elseif type(v) == "table" then
			if(k~='base') then
				target[k] = {}
				tableFunctions.merge(target[k],v)
			end
		elseif type(v) == "function" then
			--skip functions
		elseif type(v) == "userdata" then
			--skip userdata
		else
			target[k] = v
		end
	end
end


function tableFunctions.data_merge_copy(target, source)
	local retTable = {}

	if type(target) == "table" and type(source) == "table" then
		-- add all values.
		tableFunctions.merge(retTable, target)
		tableFunctions.merge(retTable, source)
	end
	return retTable
end

function tableFunctions.get_indent(level)
	return stringFunctions.repeat_string('    ',level)
end

local function table_add_table(table_,name_)
	if(tonumber(name_)) then name_=tonumber(name_) end
	if(table_==nil) then
		return {[name_]={base = {parent = {}}}}
	else
		table_[name_] = {base = {parent = table_}}
		return table_[name_]
	end
end

function tableFunctions.get_entry_where_field_is(t,field_name,field_entry)
	for k, v in  pairs (t) do
		for k2, v2 in  pairs (v) do
			if(k2==field_name and v2 == field_entry) then return v end
		end
	end 
end

function tableFunctions.table_from_saved_list(list_)
	local category = {}
	local table_name = ''
	--split by \n
	local s = stringFunctions.split(list_,'\n')

	for i=1,#s do
		if(string.match(s[i], "<table")) then
			--remove <table
			s[i] = string.gsub(s[i], "<table", "")
			--remove >
			s[i] = string.gsub(s[i], ">", "")
			--add new table
			local table_name = 'unknown_'..stringFunctions.randomString(5)
			local sP = stringFunctions.split(s[i],' ')
			

			for j=1,#sP do
				if(string.match(sP[j], "=")) then
					local sPC = stringFunctions.split(sP[j],'=')
					local findCat=true
					local cat = ''
					for k=1,#sPC do
						--trim start and end ' '
						sPC[k] = stringFunctions.trim_end(stringFunctions.trim_start(sPC[k],' '),' ')
						if(findCat) then
							cat = sPC[k]
							findCat = false
						else
							if(cat=='id') then
								table_name=sPC[k]
							else
								print('<tableFunctions> unknown category '..cat)
							end
							
							findCat = true
						end
					end
				end
			end
			-- print('<tableFunctions> loading category '..table_name..' '..tostring(category==nil) )
			local cat = category
			category = table_add_table(category,table_name)
		elseif(string.match(s[i], "</table")) then
			category = category.base.parent
		else
			if(s[i]~=nil) then
				if(not string.match(s[i], ":")) then
					print('<tableFunctions> skipping '..s[i]..' for table '..table_name)
				else
					--trim start and end ' '
					s[i] = stringFunctions.trim_spaces_and_newlines(s[i])
					local sP = stringFunctions.split(s[i],'\:')
					if(#sP~=2 and #sP~=1) then
						print('<tableFunctions> incorrect value format in '..s[i]..' for table '..table_name)
					else
						sP[1] = stringFunctions.trim_spaces_and_newlines(sP[1])
						if(#sP==1) then
							sP[2] = ''
						else
							sP[2] = stringFunctions.trim_spaces_and_newlines(sP[2])
							if(tonumber(sP[2])) then sP[2] = tonumber(sP[2]) end
						end
						
						--add field with name and value
						category[sP[1]] = sP[2]
					end
				end
			end
		end
	end
	return category
end

function tableFunctions.to_list(tObject,indent,value_only)
	local res = ''

	if not indent then
		indent = 0
	end
	if(indent>10) then 
	return '' end

	local format_value = function(k, v, indent,value_only)
		if(k=='parent' or k=='base') then return '' end
		formatting = ''

		-- if k then
			-- if type(k) == "table" then
				-- k = '[table]'
			-- end
			-- formatting = formatting .. k .. ": "
		-- end

		if not v then
			return formatting..tableFunctions.get_indent(indent)..k.. ': (nil)\n'
		elseif type(v) == "table" then
			return formatting..tableFunctions.get_indent(indent)..'<table id='..k..'>\n'..tableFunctions.to_list(v,indent+1)..tableFunctions.get_indent(indent)..'</table>\n'
		elseif type(v) == "function" then
			if(not value_only) then
				return formatting..tableFunctions.get_indent(indent)..tostring(v)..'\n'
			end
		elseif type(v) == "userdata" then
			if(not value_only) then
				return formatting..tableFunctions.get_indent(indent)..'<userdata>\n'
			end
		elseif type(v) == "boolean" then
			if v then
				return formatting ..tableFunctions.get_indent(indent).. k .. ': true\n'
			else
				return formatting ..tableFunctions.get_indent(indent).. k .. ': false\n'
			end
		else
			return formatting ..tableFunctions.get_indent(indent).. k .. ': '..v..'\n'
		end
	end

	if type(tObject) == "table" then
		local first = true

		-- add the meta table.
		-- local mt = getmetatable(tObject)
		-- if mt then
			-- res = res .. format_value('__mt', mt, indent)
			-- first = false
		-- end

		-- add all values.
		for k, v in pairs(tObject) do
			res = res .. format_value(k, v, indent)
			first = false
		end
	else
		res = res .. format_value(nil, tObject, indent)
	end

	return res
end

function tableFunctions.unpack_duo(arr,i,m)
	if(i<m) then
		return arr[i],tableFunctions.unpack_duo(arr,i+1,m)
	else
		return arr[m]
	end
end

function tableFunctions.scuffedunpack(a)
	return tableFunctions.unpack_duo(a,1,table.maxn(a))
end

function tableFunctions.has_changed(t1,t2)
	for k,v in pairs(t1) do
		if(t2[k]==nil) then 
			-- print('DIDNT FIND '..k)
			return true 
		end
		
		local t = type(v)
		if(t=='table') then
			-- print('IN '..k)
			if(tableFunctions.has_changed(v,t2[k])==true) then return true end
		else
			if(v~=t2[k]) then 
				-- print('for '..k..' '..v..'~='..t2[k])
				return true 
			end
		end
	end
			
	-- print('COUNT '..tableFunctions.count(t1)..' '..tableFunctions.count(t2))
	return tableFunctions.count(t1)~=tableFunctions.count(t2)
end

function tableFunctions.has_changed_indexed(t1,t2)
	for i=1,#t1 do
		if(t2[k]==nil) then 
			return true 
		end
		
		local t = type(v)
		if(t=='table') then
			if(tableFunctions.has_changed(v,t2[k])==true) then return true end
		else
			if(v~=t2[k]) then return true end
		end
	end
	return tableFunctions.count(t1)~=tableFunctions.count(t2)
end

function tableFunctions.describe(tbl, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)

    for key, value in pairs(tbl) do
        local keyStr = tostring(key)
        if type(value) == "table" then
            print(indentStr .. keyStr .. " = {")
            tableFunctions.describe(value, indent + 1)
            print(indentStr .. "}")
        else
            print(indentStr .. keyStr .. " = " .. tostring(value))
        end
    end
end
