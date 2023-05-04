function lerp(a,b,t)
  return a+(b-a)*t
end

-- collision map benchmark
function make_collmap(max_depth)
  -- create an array of nested planes
  local function make_plane(mins,maxs,dir,depth)
    if(depth>max_depth) return
    local node,cp={things={},leaf=depth==max_depth},(mins[dir]+maxs[dir])/2
    -- debug
    node.mins=mins
    node.maxs=maxs
    -- note: always returns a positive distance
    node.classify=function(p,r)
      local d=p[dir]-cp
      if d>r then return 2,d
      elseif d<-r then return 1,-d end
      -- stradling
      return 3,0
    end
    local other_dir=({2,1})[dir]
    local right_mins={unpack(mins)}
    right_mins[dir]=cp
    local left_maxs={unpack(maxs)}
    left_maxs[dir]=cp
    -- left
    node[1]=make_plane(mins,left_maxs,other_dir,depth+1)
    -- right
    node[2]=make_plane(right_mins,maxs,other_dir,depth+1)

    return node
  end
  return make_plane({0,0},{128,128},1,0)
end

local _things={}
function _init()
  -- mouse
  poke(0x5f2d,0x7)

  _nodes=make_collmap(4)

  srand(42)
  for i=1,100 do
    local thing=add(_things,{
      p={rnd(128),rnd(128)},
      r=4+rnd(8)
    })
    local node=classify_point(_nodes,thing.p,thing.r)
    node.things[thing]=true
    thing.node=node
  end

end

function draw_collmap(root,side)
  if(not root) return
  local x0,y0=unpack(root.mins)
  local x1,y1=unpack(root.maxs)
  rect(x0,y0,x1,y1,side)
  print(side,(x0+x1)/2-2,(y0+y1)/2-2,7)

  draw_collmap(root[1],1)
  draw_collmap(root[2],2)
end

-- return first node that contains given point at radius r
function classify_point(root,p,r)
  local side,dist=root.classify(p,r)
  -- either straddling or no childs
  if not root[side] then
    return root
  end

  return classify_point(root[side],p,r)
end

function intersect(root,p0,p1,cb)
  local side,dist=root.classify(p0,0)
  local other_side,other_dist=root.classify(p1,0)
  -- use current node
  cb(root,p0,p1)
  if(root.leaf) return

  if side==other_side then
    -- stradling?
    if side!=3 then
      -- go left or right
      intersect(root[side],p0,p1,cb)
    end
    return
  end
  -- anything to cross to? 
  local leaf,other_leaf=root[side],root[other_side]
  if leaf or other_leaf then
    local tmid=dist/(dist+other_dist)
    local pmid={
      lerp(p0[1],p1[1],tmid),
      lerp(p0[2],p1[2],tmid)
    }
    if(leaf) intersect(leaf,p0,pmid,cb)
    if(other_leaf) intersect(other_leaf,pmid,p1,cb)
    pset(pmid[1],pmid[2],11)
  end
end

local _swap=false
local _p0,_p1={24,24},{96,96}
function _update()
  local dx,dy=stat(38),stat(39)
  if btnp(4) then
    _swap=not _swap
  end
  if _swap then
    _p0[1]+=dx
    _p0[2]+=dy
  else
    _p1[1]+=dx
    _p1[2]+=dy
  end
end

function _draw()
  cls()

  for _,thing in pairs(_things) do
    circ(thing.p[1],thing.p[2],thing.r,1)
  end

  local r=9
  -- (_nodes,{_mx,_my},r)
  --draw_collmap(_nodes,1)
    
  line(_p0[1],_p0[2],_p1[1],_p1[2],7)
  local count=0
  intersect(_nodes,_p0,_p1,function(node)
    local x0,y0=unpack(node.mins)
    local x1,y1=unpack(node.maxs)
    rect(x0,y0,x1,y1,1)
    for thing in pairs(node.things) do
      local x,y=thing.p[1],thing.p[2]
      circ(x,y,thing.r,5)
      count+=1
    end
  end)
  print(flr(100*(count/#_things)).."%",2,2,7)
end

