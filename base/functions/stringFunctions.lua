local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

local booleanstring = { ["true"]=true, ["false"]=false,["TRUE"]=true, ["FALSE"]=false }

stringFunctions = {}

stringfunctionsrandomised = false

function stringFunctions.randomString(length)
    if not length or length <= 0 then return '' end
	if not stringfunctionsrandomised then
		math.randomseed(os.time())
		stringfunctionsrandomised = true
	end
	math.random();math.random(); math.random();
    return stringFunctions.randomString(length - 1) .. charset[math.random(1, #charset)]
end

function stringFunctions.starts_with(str, start)
	if(type(str)~='string') then return false end
   return str:sub(1, #start) == start
end

function stringFunctions.ends_with(str, ending)
	if(type(str)~='string') then return false end
   return ending == "" or str:sub(-#ending) == ending
end

function stringFunctions.split(inputstr, sep)
	if sep == nil then
	   sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function stringFunctions.split_keepstrings(inputstr, sep, keep_quotes)
    -- Laat tekst tussen " en ' intact, optioneel inclusief de quotes zelf
    local result = {}
    local i = 1
    local len = #inputstr
    while i <= len do
        local c = inputstr:sub(i, i)
        if c == '"' or c == "'" then
            -- Vind het einde van de quote
            local close = inputstr:find(c, i + 1)
            if close then
                if keep_quotes and keep_quotes==true then
                    table.insert(result, inputstr:sub(i, close)) -- inclusief quotes
                else
                    table.insert(result, inputstr:sub(i + 1, close - 1)) -- zonder quotes
                end
                i = close + 1
            else
                -- Geen sluitende quote, neem de rest
                if keep_quotes and keep_quotes==true then
                    table.insert(result, inputstr:sub(i))
                else
                    table.insert(result, inputstr:sub(i + 1))
                end
                break
            end
        elseif not c:match("%s") then
            -- Normaal woord buiten quotes
            local next_space = inputstr:find("%s", i)
            if next_space then
                table.insert(result, inputstr:sub(i, next_space - 1))
                i = next_space + 1
            else
                table.insert(result, inputstr:sub(i))
                break
            end
        else
            i = i + 1
        end
    end
    return result
end

function stringFunctions.separateStringAndSpaces(inputstr)
	local sArr = {}
	local sIndex = {}
	local openState=false
	local cStart = 1
	for n=1,string.len(inputstr) do
		local c = string.sub(inputstr,n,n)
		if(c=='\'') then
			if(openState==true) then
		-- print('insert: '..string.sub(inputstr,cStart,n))
				table.insert(sArr,string.sub(inputstr,cStart,n))
				sIndex[#sArr]=true
				cStart=n+1
				openState=false
			else
				if(n~=cStart) then
		-- print('insert: '..string.sub(inputstr,cStart,n-1))
					table.insert(sArr,string.sub(inputstr,cStart,n-1))
				end
				cStart = n
				openState=true
			end
		end
	end
	if(openState) then error('<stringFunctions.separateStringAndSpaces> open ended string') end
	if(cStart<=string.len(inputstr)) then
		-- print('insert: '..string.sub(inputstr,cStart,n))
		table.insert(sArr,string.sub(inputstr,cStart,string.len(inputstr)))
	end
	--split by spaces if not string
	local retArr = {}
	for n=1,#sArr do
		if(sIndex[n]==nil) then
			local s = stringFunctions.split(sArr[n], ' ')
			-- print('for '..n..' '..#s..' in::'..sArr[n])
		if(#s==0) then table.insert(s, inputstr) end
			
			if(n>1 and sIndex[n-1]==true and stringFunctions.starts_with(sArr[n],' ')==false) then
				retArr[#retArr]=retArr[#retArr]..s[1]
			else
					table.insert(retArr,s[1])
			end
				for sI=2,#s do
					table.insert(retArr,s[sI])
				end
		else
			if(n>1 and (stringFunctions.ends_with(sArr[n-1],' ') or sIndex[n-1]==true)) then
				table.insert(retArr,sArr[n])
			elseif(#retArr>0) then
				retArr[#retArr]=retArr[#retArr]..sArr[n]
			else
				
				retArr[1]=sArr[n]
			end
		end
	end
	
	-- for n=1,#retArr do
		-- print(n..' '..retArr[n])
	-- end
	-- error('<stringFunctions.separateStringAndSpaces> end test')
	return retArr
end

function stringFunctions.combine(stringArray,combineString)
	if(#stringArray==0) then return '' end
	local ret = stringArray[1]
	for i=2,#stringArray do
		ret = ret..combineString..stringArray[i]
	end
	return ret
end

--equals functions can also be used for any type of object

function stringFunctions.equals_one_of(string_,compareStringArray_)
	if(type(compareStringArray_)~='table') then 
		if(string_ == compareStringArray_) then return true,compareStringArray_ end
	else
		for i=1,#compareStringArray_ do
			if(string_ == compareStringArray_[i]) then return true,compareStringArray_[i] end
		end
	end
	return false
end


function stringFunctions.removeNonChar(input_)
	local retString = ''
	for i=1,string.len(input_) do
		local c = string.sub(input_,i,i)
		
		if(string.len(string.byte(c))>1) then
			retString = retString..c 
		end
	end
	return retString
end

function stringFunctions.sub_withoutNonChar(input_,start_)
	local retString = ''
	for i=start_,string.len(input_) do
		local c = string.sub(input_,i,i)
		
		if(string.len(string.byte(c))>1) then
			retString = retString..c 
		end
	end
	return retString
end

function stringFunctions.trim(input_,start_,end_)
	if(start_==nil) then return input_:match "^%s*(.-)%s*$" end
	
	if(stringFunctions.starts_with(input_,start_) and stringFunctions.ends_with(input_,end_)) then
		return string.sub(input_,1+string.len(start_),-string.len(end_)-1)
	end
	return input_
end

function stringFunctions.trim_start(input_,start_)
	if(stringFunctions.starts_with(input_,start_)) then
		if(string.len(start_)==string.len(input_)) then return '' end
		return string.sub(input_,string.len(start_)+1,-1)
	end
	return input_
end

function stringFunctions.trim_end(input_,end_)
	if(stringFunctions.ends_with(input_,end_)) then
		return string.sub(input_,1,-string.len(end_)-1)
	end
	return input_
end

function stringFunctions.replace(input_,to_be_replaced_,with_)
	return string.gsub(input_, to_be_replaced_, with_)
end

function stringFunctions.last_part(input_,after_)
	local res = string.match(input_, after_.."(.*)")
	if(res==nil) then return input_ end
	return res
end

function stringFunctions.trim_spaces_and_newlines(input_)
	return string.gsub(input_, '^%s*(.-)%s*$', '%1')
end

function stringFunctions.befor(input_,check_,startIndex_)
	if(check_==nil or check_=='') then return input_ end
	
	local check_length = string.len(check_)
	local st = 1
	if(startIndex_ and tonumber(startIndex_)~=nil) then st = tonumber(startIndex_) end
	for i=st,string.len(input_) do
		if(string.sub(input_,i,i+check_length-1)==check_) then
			return string.sub(input_,st,i-1)
		end
	end
	return nil
end

function stringFunctions.beforA(input_,check_,startIndex_)
	if(type(check_)~='table') then return stringFunctions.befor(input_,check_,startIndex_) end
	
	local lowestResult = string.len(input_)
	local lastBefor = nil
	local cType = nil
	local check_length = nil
	for c =1,#check_ do
		check_length = string.len(check_[c])
		local st = 1
		if(startIndex_ and tonumber(startIndex_)~=nil) then st = tonumber(startIndex_) end
		for i=st,lowestResult do
			if(string.sub(input_,i,i+check_length-1)==check_[c]) then
				lowestResult = i-1
				lastBefor = string.sub(input_,st,i-1)
				cType = check_[c]
				break
			end
		end
	end
	return lastBefor,lowestResult+1+check_length,cType
end

function stringFunctions.contains(str, pattern)
  local found = string.find(str, pattern, 1, true)
  return found ~= nil
end

function stringFunctions.containsOnlyTypes( text_, checkString_)
        if(text_ == nil or text_ == '') then
            return false;
        end

        for i = 1, string.len(text_) do
            if(checkString_ ~= string.sub(text_,i,i+1)) then
                return false;
            end
        end

        return true;
end
	
function stringFunctions.count( text_, occ_)
	return select(2, string.gsub(text_, occ_, ""))
end
	
function stringFunctions.repeat_string(string_,amount)
	local retString = ''
	for i=1,amount do
		retString=retString..string_
	end
	return retString
end

function stringFunctions.mergeArgs(tArgs)
	local curOpen=false
	local tempHold=''
	local args = {}
	
	 for i=1,#tArgs do
		if(curOpen) then
			tempHold=tempHold..' '..tArgs[i]
			if(stringFunctions.ends_with(tArgs[i],'\'')) then
				table.insert(args,tempHold)
				tempHold=''
				curOpen = false
			end
		else
			if(stringFunctions.starts_with(tArgs[i],'\'')) then
				if(not stringFunctions.ends_with(tArgs[i],'\'')) then
					tempHold = tArgs[i]
					curOpen=true
				else
					table.insert(args,tArgs[i])
				end
			else
				table.insert(args,tArgs[i])
			end
		end
	 end
	 return args
end

function stringFunctions.stringAddIfNotEmpty(string_,pref_,add_)
	if(string_==nil or string_=='') then return add_ end
	return string_..pref_..add_
end

function stringFunctions.stringUpArgs(tArgs,from_)
	local curOpen=false
	local tempHold=''
	local stringedUp = ''
	
	local from = 1
	if(from_) then from = from_ end
	 for i=from,#tArgs do
		if(curOpen) then
			tempHold=tempHold..' '..tArgs[i]
			if(stringFunctions.ends_with(tArgs[i],'\'')) then
				stringedUp = stringFunctions.stringAddIfNotEmpty(stringedUp,' ',tempHold)
				tempHold=''
				curOpen = false
			end
		else
			if(stringFunctions.starts_with(tArgs[i],'\'')) then
				if(not stringFunctions.ends_with(tArgs[i],'\'')) then
					tempHold = tArgs[i]
					curOpen=true
				else
					stringedUp = stringFunctions.stringAddIfNotEmpty(stringedUp,' ',tArgs[i])
				end
			else
				stringedUp = stringFunctions.stringAddIfNotEmpty(stringedUp,' ',tArgs[i])
			end
		end
	 end
	 return stringedUp
end

function stringFunctions.toShallowJSON(tObject,indent)
	local res = ''

	if not indent then
		indent = 0
	end

	local format_value = function(k, v, indent)
		if(k=='parent') then return '' end
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
			formatting =  formatting..tableFunctions.get_indent(indent)..'<table id='..k..'>\n'
			if(v.base) then
				formatting =formatting..v:toShallowJSON(indent+1)
			else
				formatting =formatting..stringFunctions.toShallowJSON(v,indent+1)
			end
			return formatting..tableFunctions.get_indent(indent)..'</table>\n'
		elseif type(v) == "function" then
			return formatting..tableFunctions.get_indent(indent)..tostring(v)..'\n'
		elseif type(v) == "userdata" then
			return formatting..tableFunctions.get_indent(indent)..'<userdata>\n'
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

--to saveable string
function stringFunctions.toSendableString(tObject)
	local format_value = function(k, v)
	
		if not v then
			return ':v|'..k..'|(nil)'
		elseif type(v) == "number" then
			return ':n|'..k..'|'..v
		elseif type(v) == "table" then
				return ':t|'..k
		elseif type(v) == "function" then --skip
			return ''
		elseif type(v) == "userdata" then --skip
			return ''
		elseif type(v) == "boolean" then
			if v then
				return ':b|'..k..'|true'
			else
				return ':b|'..k..'|false'
			end
		else
			return ':v|'..k..'|'..v
		end
	end
	
	local res = ''
	-- add all values.
	for k, v in pairs(tObject) do
		res = res .. format_value(k, v)
	end
	return res
end

--only supporting arrays,numbers,booleans and strings
function stringFunctions.toTableBaseString(arr_)
	local retS = '{'
	local first = true
	for k,v in pairs(arr_) do
		-- print('a')
		if(first==false) then
			retS = retS..','
		else
			first=false
		end
		retS = retS..'['..k..']='
		if(type(v) == 'table') then
			retS = retS..stringFunctions.toTableBaseString(v)
		elseif(type(v) == 'string') then
			retS = retS..'\''..tostring(v)..'\''
		else
			retS = retS..tostring(v)
		end
	end
	return retS..'}'
end

function stringFunctions.between(startI,startString,endString,checkString)
	local sI = -1
	for i=startI,string.len(checkString)-string.len(startString)+1 do
		if(checkString:sub(i, i+string.len(startString)-1)==startString) then 
			sI = i+1 
			break
		end
	end
	if(sI==-1) then return nil end
	
	for i=sI,string.len(checkString)-string.len(endString) do
		if(checkString:sub(i, i+string.len(endString)-1)==endString) then 
			return checkString:sub(sI, i-1),i+#endString
		end
	end
	return nil 
end

function stringFunctions.find(startI,findString,checkString,acceptOthers)
	local foundOthers = false
	for i=startI,string.len(checkString)-string.len(findString)+1 do
		if(checkString:sub(i, i+string.len(findString)-1)==findString) then 
			if(acceptOthers==false and foundOthers) then return nil end
			return i+1 
		end
		if(checkString:sub(i, i)~=' ') then foundOthers=true end
	end
	return nil
end

function stringFunctions.findA(startI,findArr,checkString,acceptOthers)
	if(type(findArr)=='string') then return stringFunctions.find(startI,findArr,checkString,acceptOthers) end
	local rFoundOthers = false
	local rI = -1
	local cType = nil
	local lowestEndI = string.len(checkString)
	for c =1,#findArr do
		local foundOthers = false
		for i=startI,lowestEndI-string.len(findArr[c])+1 do
			if(checkString:sub(i, i)~=' ') then foundOthers=true end
			if(checkString:sub(i, i+string.len(findArr[c])-1)==findArr[c]) then 
				lowestEndI = i-1
				if(foundOthers) then rFoundOthers=nil  end
				rI=i+1
				cType = findArr[c]
				break
			end
		end
	end
	if(rI~=-1) then
		if(acceptOthers==false and rFoundOthers) then return nil  end
		return rI,cType
	end
	
	return nil
end

function stringFunctions.first(startI,checkString,ignoreSpace)
	local sI = -1
	local foundOthers = false
	for i=startI,string.len(checkString) do
		local c = checkString:sub(i, i)
		if(c==' ') then 
			if(ignoreSpace~= true) then return ' ',i+1 end
		else
			return c,i+1
		end
	end
	return nil
end

function stringFunctions.isSpaces(startI,checkString)
	for i=startI,string.len(checkString) do
		if(checkString:sub(i, i)~=' ') then return false end
	end
	return true
end

local function processTableBaseString(index,baseString)
	local retEntry = nil
	-- find []
	local k = nil
	local val = nil
	k,index = stringFunctions.between(index,'[',']',baseString)
	if(k==nil) then print('<stringFunctions.fromTableBaseString> Key not found in '..baseString) return nil end
	--find =, but dont accept only spaces inbetween
	index = stringFunctions.find(index,'=',baseString,false)
	if(index==nil) then print('<stringFunctions.fromTableBaseString> unknown after key in '..baseString) return nil end
	--check possible value type
	local vType =nil
	vType,index = stringFunctions.first(index,baseString,true)
	if(vType==nil) then print('<stringFunctions.fromTableBaseString> unknown value type in '..baseString) return nil end
	if(vType=='{') then
		--start new table. add to current table
		local fTable = nil
		val,index = stringFunctions.fromTableBaseString(index,baseString)
		if(val == nil) then return nil end
	elseif(vType=='\'') then
		--find closing '
		local endindex = stringFunctions.find(index,'\'',baseString,true)
		if(endindex==nil) then print('<stringFunctions.fromTableBaseString> open string in '..baseString) return nil end
		--add string to current table
		val = baseString:sub(index, endindex-2)
		index=endindex
	else
		--shift back 1 index since we start at the value
		index=index-1
		--get all till , or }
		local cType = nil
		val,index,cType = stringFunctions.beforA(baseString,{'\,','}'},index)
		if(index==nil) then print('<stringFunctions.fromTableBaseString> missing value in '..baseString) return nil end
		--check if its a boolean
		if(booleanstring[val]) then
			--add boolean to current table
			val = booleanstring[val]
		elseif(tonumber(val)~=nil) then
			--add boolean to current table
			val = tonumber(val)
		else
			print('<stringFunctions.fromTableBaseString> unknown value in '..baseString..' at '..index..'/'..string.len(baseString)) 
			return nil 
		end
		
		--shift back 1 index since an end was caught
		index=index-1
	end
	return k,val,index
end

function stringFunctions.fromTableBaseString(index,baseString)
	local retA = {}
	while(index<string.len(baseString)) do
		--find entry
		local k = nil
		local v = nil
		k,v,index = processTableBaseString(index,baseString)
		--if entry is nil then expect error was caught
		if(k==nil) then return nil end
		retA[k] = v
		--find either , to check next or a } to end this array	
		local cType = nil
		index,cType = stringFunctions.findA(index,{'\,','}'},baseString,false)
		if(index==nil) then print('<stringFunctions.fromTableBaseString> open array in '..baseString) return nil end
		--if we ended on a } then return the array
		if(cType=='}') then return retA,index end
		--presuming we are currently on a ,
		--check if last characters are spaces
		if(stringFunctions.isSpaces(index,baseString)) then return retA,string.len(baseString) end
	end
end

function stringFunctions.mergeArrayArgs(args)
	local curOpen = false
	local openCount = 0
	local openArgIndex = -1
	for i=1,#args do
		if(curOpen) then
			for s=1,string.len(args[i]) do
				if(args[i]:sub(s,s)=='{') then
					openCount = openCount+1
				elseif(args[i]:sub(s,s)=='}') then	
					openCount = openCount-1
					if(openCount==0) then
						curOpen=false
						--last close needs to be last letter in the args
						if(s~=string.len(args[i])) then return args,false,1 end
						if(openArgIndex~=i) then
							--merge relevant args
							for m=openArgIndex+1,i do
								args[openArgIndex] = args[openArgIndex]..args[m]
							end
							for m=i,openArgIndex+1,-1 do
								table.remove(args,m)
							end
						end
						return args,true
					end
				end
			end
		else
			if(args[i]:sub(1,1)=='\'') then
				--ignore this one
			elseif(args[i]:sub(1,1)=='{') then
				curOpen=true
				openCount = 1				
			end
		end
	end
	--open end error
	if(curOpen) then return args,false,2 end
	--unknown error
	return args,false,3
end

function stringFunctions.get_array_info(string_)
	local type, count_str = string_:match('(.+)%[(.+)%]')
    type = stringFunctions.trim(type or string_)
	if(count_str==nil) then
		count_str = 1
	else
		count_str = tonumber(count_str)
	end
	return type,count_str
end

function stringFunctions.keep_length(string_,length_,front_padding_)
	if(string.len(string_)>length_) then
		string_ = string.sub(string_,1,length_)
	elseif(string.len(string_)<length_) then
		for i=string.len(string_)+1,length_ do
			string_= front_padding_..string_
		end
	end
	return string_
end

--convert strings in an array to numbers or boolean if applicable
function stringFunctions.convertArrayTypes( arr_)
	for i=1,#arr_ do
		--array table
		if(arr_[i]:sub(1,1)=='{') then
			arr_[i]=stringFunctions.fromTableBaseString(1,arr_[i])
		--number
		elseif(tonumber(arr_[i])~=nil) then
			arr_[i]=tonumber(arr_[i])
		--boolean
		elseif(booleanstring[arr_[i]]~=nil) then
			arr_[i]=booleanstring[arr_[i]]
		end
	end
	return arr_
end

function stringFunctions.convert( s)
	if(booleanstring[s]~=nil) then
		return booleanstring[s]
	elseif(tonumber(s)~=nil) then
		return tonumber(s)
	else
		return s
	end	
end

function stringFunctions.convertToFunction(strCommand)
	-- if(strCommand:sub(string.len(strCommand),string.len(strCommand))~=')') then return nil end
	--get function name
	-- local funcName = stringFunctions.befor(strCommand,'(')
	-- local argString = strCommand:sub(string.len(funcName)+2,string.len(strCommand)-1)
	 -- print('arg '..strCommand)
	local p =parser:new() 
	p:parse({strCommand},'')
	return p:toOneLineCommand()
	
end

function stringFunctions.toboolean( str_)
	return booleanstring[str_]
end

function stringFunctions.to_binary(number,position)
    if type(number) ~= "number"  then
		number = tonumber(number)
		if(number==nil) then
			error("<stringFunctions.to_binary> Input must be a number "..tostring(number))
		end
    end
    
    if number == 0 then
        return 0
    end

    local binaryString = ""
    while number > 0 do
        local remainder = number % 2
        binaryString = tostring(remainder) .. binaryString
        number = math.floor(number / 2)
    end

	-- print('stringFunctions.to_binary '..tostring(number)..' '..tostring(binaryString)..' '..string.len(binaryString)..' '..position..' '..tostring(tonumber(binaryString:sub(string.len(binaryString)-position+1, string.len(binaryString)-position+1))))
	if(position) then
		local l = string.len(binaryString)
		if(position<= l) then
			return tonumber(binaryString:sub(l-position+1, l-position+1))
		else
			return 0
		end
	end
	return binaryString
end

function stringFunctions.tab()
	return '   '
end