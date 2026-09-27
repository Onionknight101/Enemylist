mathFunctions = {}

function mathFunctions.mod(a_,b_)
	return a_ - math.floor(a_/b_)*b_
end

function mathFunctions.pow(a_, b_)
    return a_ ^ b_
end

function mathFunctions.equals_one_of(object_,compareArray_)
	for i=1,#compareArray_ do
		if(object_ == compareArray_[i]) then return true end
	end
	return false
end

function mathFunctions.is_between(num,min_,max_)
	return num>=min_ and num<=max_
end

function mathFunctions.shift_x_by_angle(start_x,height,degree)
	degree=degree%360
	if(degree<0) then degree=degree*-1 end

	return start_x+math.cos(math.rad(degree-90))*height
end

function mathFunctions.shift_y_by_angle(start_y,height,degree)
	degree=degree%360
	if(degree<0) then degree=degree*-1 end

	return start_y+math.sin(math.rad(degree-90))*height
end

function mathFunctions.distance ( x1, y1, x2, y2 )
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt ( (dx * dx) + (dy * dy) )
end

function mathFunctions.distance_3d ( x1, y1, z1, x2, y2, z2 )
if not x1 or not y1 or not z1 or not x2 or not y2 or not z2 then return 0 end
  local dx = x1 - x2
  local dy = y1 - y2
  local dz = z1 - z2
  return math.sqrt(( dx * dx) + (dy * dy) + (dz * dz))
end

function mathFunctions.round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

function mathFunctions.toHex(dec_)
    
    local B,K,_hex,I,D=16,"0123456789ABCDEF","",0
    while dec_>0 do
        I=I+1
        dec_,D=math.floor(dec_/B),math.mod(dec_,B)+1
        _hex=string.sub(K,D,D).._hex
    end
    return _hex
end

function mathFunctions.reverse_bits(arr)
	local i, j = 1, #arr

	while i < j do
		arr[i], arr[j] = arr[j], arr[i]

		i = i + 1
		j = j - 1
	end
	
	return arr
end

function mathFunctions.toBits(num,bits)
    -- returns a table of bits, most significant first.
    bits = bits or math.max(1, select(2, math.frexp(num)))
    local t = {} -- will contain the bits        
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[b]) / 2)
    end
    return mathFunctions.reverse_bits(t)
end

function mathFunctions.toBitArray(n,s)
	local r = {}
	for i=s-1,0,-1 do
		if((n/2^i)>=1) then
			table.insert(r,1,1)
			n=n-2^i
		else
			table.insert(r,1,0)
		end
	end
	return r
 end

function mathFunctions.construct_value(a,f,s)
	--account for first spot f so subract 1 from the size
	local e = s-1
	--check out of bounds requests
	if(s<=0 or f<1 or f>#a or f+e<1 or f+e>#a) then return nil end	
	--size of 1 means return current entry
	if(e==0) then return a[f] end
	--start at 0
	local r = 0
	--for i=f till s-1 add values by power of 2 starting at 0 multiplied by the entry at a[i]
	for i=f,f+e do
		r = r+((2^(i-f))*a[i])
	end
	return r
 end

function mathFunctions.get_index(id_)
	return CLIENT_INFO.get_index_from_id(id_)
	-- return tonumber(string.sub(stringFunctions.keep_length(mathFunctions.toHex(id_),8,'0'),6,8), 16)
end

function mathFunctions.get_direction_tag(angle)
  local directions = {
    "E", "NE", "N", "NW", 
    "W", "SW", "S", "SE"
  }
  local index = math.floor(((angle + math.pi / 8) % (2 * math.pi)) / (math.pi / 4)) + 1
  return directions[index]
end

function mathFunctions.formatTime(time)
  local seconds = time % 60
  local minutes = math.floor((time / 60) % 60)
  local hours = math.floor(time / 3600)

  local formattedTime = ""
  if hours > 0 then
    formattedTime = hours .. "h"
  elseif minutes > 0 then
    formattedTime = minutes .. "m"
  else
    formattedTime = seconds .. "s"
  end

  return formattedTime
end

local bool_map ={ [true]=true, [false]=false,["true"]=true, ["false"]=false,["TRUE"]=true, ["FALSE"]=false }

function mathFunctions.bool_check(val_,default_)
  val_=bool_map[val_]
  if(val_==nil) then return default_ end
  return val_
end

function mathFunctions.bool_to_on_off(val_)
  if(val_==nil) then return 'off' end
  if(val_==true) then return 'on' end
  return 'off'
end

function mathFunctions.get_bits(byte)
    local bits = {}
    for i = 0, 7 do
        bits[i+1] = bit.band(bit.rshift(byte, i), 1) == 1
    end
    return bits
end

function mathFunctions.band(a, b)
    local res = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if (a % 2 == 1) and (b % 2 == 1) then
            res = res + bitval
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bitval = bitval * 2
    end
    return res
end

local function pow10(d) return 10^(d or 0) end

local function round_down(x, decimals)
    local f = pow10(decimals)
    return math.floor(x * f + 1e-12) / f
end

local function round_up(x, decimals)
    local f = pow10(decimals)
    return math.ceil(x * f - 1e-12) / f
end

function mathFunctions.round_nearest(x, decimals)
    decimals = decimals or 0
    local f = pow10(decimals)
    if x >= 0 then
        return math.floor(x * f + 0.5) / f
    else
        return math.ceil(x * f - 0.5) / f
    end
end

function mathFunctions.get_color_set_alpha(c, a)
    a = a or 255
    return { c.r or c[1] or 255, c.g or c[2] or 255, c.b or c[3] or 255, a }
end

function mathFunctions.local_time()
    local sec, ms
    local ok, socket = pcall(require, "socket")
    if ok and socket and socket.gettime then
        local t = socket.gettime()            -- float seconds
        sec = math.floor(t)
        ms  = math.floor((t - sec) * 1000 + 0.5)
    else
        sec = os.time()
        -- os.clock is CPU-time, dus minder precies maar beter dan niets
        ms = math.floor((os.clock() - math.floor(os.clock())) * 1000 + 0.5)
    end

    local dt = os.date("*t", sec)
    return string.format("%02d:%02d:%02d.%03d", dt.hour, dt.min, dt.sec, ms)
end

function mathFunctions.now_ms()
    local ok, socket = pcall(require, "socket")
    if ok and socket and socket.gettime then
        return socket.gettime() * 1000
    end
    -- fallback: combine os.time (seconds) with fractional part from os.clock (approx)
    local sec = os.time()
    local frac = os.clock() - math.floor(os.clock())
    return sec * 1000 + math.floor(frac * 1000 + 0.5)
end

-- returns difference in milliseconds (t2 - t1). if t2 omitted uses current time.
function mathFunctions.diff_ms(t1, t2)
    if not t1 then return nil end
    local end_ms = t2 or mathFunctions.now_ms()
    return math.floor((end_ms - t1) + 0.5)
end