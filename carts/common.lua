-- print helper
function arizona_print(s,x,y,sel)
  sel=sel or 0
  -- shadow
  ?s,x,y+1,1
  for j=0,6 do
    clip(0,y+j,127,1)
    ?s,x,y,sget(32+sel,j)
  end
  clip()
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

