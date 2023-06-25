-- print helper
function arizona_print(s,x,y,sel)
  sel=sel or 0
  -- shadow
  local pos=?s,x,y+1,1
  for j=0,6 do
    clip(0,y+j,127,1)
    ?s,x,y,sget(32+sel,j)
  end
  clip()
  return pos
end

-- string/value replacement function
-- credits: @heraclum
function scanf(st,...)
  local s=""
  for i,p in inext,split(st,"$") do
      s..=({"",...})[i]..p
  end
  return s
 end


-- radix sort
function rsort(_data)  
  local _len,buffer1,buffer2,idx=#_data, _data, {}, {}

  -- radix shift (multiplied by 64 to get more precision)
  for shift=-8,-3,5 do
  	-- faster than for each/zeroing count array
    memset(0x4300,0,32)
	  for i,b in pairs(buffer1) do
		  local c=0x4300+((b.key>>shift)&31)
		  poke(c,@c+1)
		  idx[i]=c
	  end
				
    -- shifting array
    local c0=@0x4300
    for mem=0x4301,0x431f do
      local c1=@mem+c0
      poke(mem,c1)
      c0=c1
    end

    for i=_len,1,-1 do
		local k=idx[i]
      local c=@k
      buffer2[c] = buffer1[i]
      poke(k,c-1)
    end

    buffer1, buffer2 = buffer2, buffer1
  end
  return buffer2
end

-- game states
function next_state(fn,...)
  local u,d,i=fn(...)
  -- ensure update/draw pair is consistent
  _update_state=function()
    -- init function (if any)
    if(i) i()
    -- 
    _update_state,_draw=u,d
    -- actually run the update
    u()
  end
end

-- registers a new coroutine
local _futures={}
-- returns a handle to the coroutine
-- used to cancel a coroutine
function do_async(fn)
  return add(_futures,{co=cocreate(fn)})
end
-- wait until timer
function wait_async(t)
	for i=1,t do
		yield()
	end
end

function update_asyncs()
  for i=#_futures,1,-1 do
    -- get actual coroutine
    local f=_futures[i].co
    -- still active?
    if f and costatus(f)=="suspended" then
      assert(coresume(f))
    else
      deli(_futures,i)
    end
  end
end

-- helper to execute a call (usually from a split string)
function exec(fn,...)
  -- skip comments :)
  if(fn=="--") return
  _ENV[fn](...) 
end

-- split a 2d table:
-- each line is \n separated
-- section in ; separated
-- name credits: @krystman
function split2d(config,cb)
  for line in all(split(config,"\n")) do
    cb(unpack(split(line,";")))
  end
end


