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
      s..=select(i,"",...)..p
  end
  return s
 end


-- radix sort
function rsort(data)  
  local len,buffer1,buffer2,idx=#data, data, {}, {}

  -- radix shift (multiplied by 128 to get more precision)
  for shift=-7,-2,5 do
  	-- faster than for each/zeroing count array
    memset(0xd51c,0,32)
	  for i,b in pairs(buffer1) do
		  local c=0xd51c+((b.key>>shift)&31)
		  poke(c,@c+1)
		  idx[i]=c
	  end
				
    -- shifting array
    local c0=@0xd51c
    for mem=0xd51d,0xd61b do
      local c1=@mem+c0
      poke(mem,c1)
      c0=c1
    end

    for i=len,1,-1 do
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
  -- to allow call from exec
  fn=_ENV[fn] or fn
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

local function inherit(t,env)
  return setmetatable(t,{__index=env or _ENV})
end
function nop() end
_ENV["//"]=nop
function set(k,v,env)
  (_ENV[env] or _ENV)[k]=v
end

-- helper to execute a call (usually from a split string)
function exec(code)
  split2d(code,function(fn,...)
    _ENV[fn](...)
  end)
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


