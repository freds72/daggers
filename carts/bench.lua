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
  printh("*****************")
  -- mouse
  poke(0x5f2d,0x7)

  _nodes=make_collmap(4)

  srand(42)
  for i=1,100 do
    local thing=add(_things,{
      grid={},
      p={12+rnd(128),12+rnd(128)},
      r=16 -- max: 12
    })
    thing.hr=thing.r/2
  end

  local t0=stat(1)
  for i=1,#_things do
    local thing=_things[i]
    collmap_register(_nodes,thing)
  end
  printh("+collmap:"..stat(1)-t0.." cycles")

  local t0=stat(1)
  for i=1,#_things do
    local thing=_things[i]
    collmap_unregister(_nodes,thing)
  end
  printh("-collmap:"..stat(1)-t0.." cycles")

  local grid={}
  for i=0,4 do
    for j=0,4 do
      grid[i>>16|j]={things={}}
    end
  end

  local t0=stat(1)
  for i=1,#_things do
    local thing=_things[i]
    gridmap_register(grid,thing)
  end
  printh("+gridmap:"..stat(1)-t0.." cycles")

  local t0=stat(1)
  for i=1,#_things do
    local thing=_things[i]
    gridmap_unregister(grid,thing)
  end
  printh("-gridmap:"..stat(1)-t0.." cycles")

  srand(34)
  local t0=stat(1)
  for i=1,100 do
    local x0,y0=rnd(128),rnd(128)
    local x1,y1=rnd(128),rnd(128)
    local dx,dy=x1-x0,y1-y0
    local a=atan2(dx,dy)
    local u,v=cos(a),sin(v)
    grid_collect(grid,{x0,y0},{x1,y1},u,v,function() end)
  end

  printh("hit gridmap:"..stat(1)-t0.." cycles")

  srand(34)
  local t0=stat(1)
  for i=1,100 do
    local x0,y0=rnd(128),rnd(128)
    local x1,y1=rnd(128),rnd(128)
    local dx,dy=x1-x0,y1-y0
    local a=atan2(dx,dy)
    local u,v=cos(a),sin(v)
    intersect(_nodes,{x0,y0},{x1,y1},function() end)
  end

  printh("hit collmap:"..stat(1)-t0.." cycles")

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
  local side=root.classify(p,r)
  -- either straddling or no childs
  if not root[side] then
    return root
  end

  return classify_point(root[side],p,r)
end

function gridmap_unregister(_,thing)
  for idx,grid in inext,thing.grid do
    grid.things[thing]=nil
    thing.grid[idx]=nil
  end
end 

function gridmap_register(grid,thing)
  local r,p=thing.hr,thing.p
  local x,y=p[1],p[2]
  local y0,y1=(y-r)\32,(y+r)\32
  -- \32 + >>16
  for idx=(x-r)>>21,(x+r)>>21,0x0.0001 do
    for y=y0,y1 do
      local grid=grid[idx|y]
      grid.things[thing]=true
      -- for fast unregister
      thing.grid[idx|y]=grid
    end
  end
end

function collmap_unregister(root,thing)
  thing.node.things[thing]=nil
  thing.node=nil
end

function collmap_register(root,thing)
  local node=classify_point(root,thing.p,thing.r)
  node.things[thing]=true
  thing.node=node
end

-- collect all grids touched by (a,b) vector
function grid_collect(grid,a,b,u,v,cb)
  local mapx,mapy,dest_mapx,dest_mapy,mapdx,mapdy=a[1]\32,a[2]\32,b[1]\32,b[2]\32
  -- check first cell
  cb(grid[mapx>>16|mapy])
  -- early exit
  if dest_mapx==mapx and dest_mapy==mapy then    
    return
  end
  local ddx,ddy,distx,disty=abs(1/u),abs(1/v)
  if u<0 then
    mapdx=-1
    distx=(a[1]/32-mapx)*ddx
  else
    mapdx=1
    distx=(mapx+1-a[1]/32)*ddx
  end
  
  if v<0 then
    mapdy=-1
    disty=(a[2]/32-mapy)*ddy
  else
    mapdy=1
    disty=(mapy+1-a[2]/32)*ddy
  end
  while dest_mapx!=mapx and dest_mapy!=mapy do
    if distx<disty then
      distx+=ddx
      mapx+=mapdx
    else
      disty+=ddy
      mapy+=mapdy
    end
    cb(grid[mapx>>16|mapy])
  end  
end

function intersect(root,p0,p1,cb)
  local side,dist=root.classify(p0,0)
  local other_side,other_dist=root.classify(p1,0)
  -- use current node
  if root.leaf or side!=other_side or dist<32 or other_dist<32 then
    cb(root,p0,p1)
  end
  if(root.leaf) return

  if side==other_side then
    if side!=3 then
      -- go left or right
      intersect(root[side],p0,p1,cb)
    end
    return
  end
  -- anything to cross to? 
  local tmid=dist/(dist+other_dist)
  local pmid={
    lerp(p0[1],p1[1],tmid),
    lerp(p0[2],p1[2],tmid)
  }
  local leaf,other_leaf=root[side],root[other_side]
  if(leaf) intersect(leaf,p0,pmid,cb)
  if(other_leaf) intersect(other_leaf,pmid,p1,cb)
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
  intersect(_nodes,_p0,_p1,function(node,p0,p1)
    local c=5
    local x0,y0=unpack(node.mins)
    local x1,y1=unpack(node.maxs)
    rect(x0,y0,x1,y1,1)
    for thing in pairs(node.things) do
      local x,y=thing.p[1],thing.p[2]
      circ(x,y,thing.r,c)
      count+=1
    end
  end)
  print(flr(100*(count/#_things)).."%",2,2,7)
end

