local _plyr,_cam,_things,_grid

function make_fps_cam()
    local up={0,1,0}
    
    return {
        origin={0,0,0},    
        track=function(self,origin,m,angles)
            --origin=v_add(v_add(origin,m_fwd(m),-24),m_up(m),24)	      
            local m={unpack(m)}		
            self.fwd=m_fwd(m)

            -- inverse view matrix
            m[2],m[5]=m[5],m[2]
            m[3],m[9]=m[9],m[3]
            m[7],m[10]=m[10],m[7]
            --
            self.m=m_x_m(m,{
                1,0,0,0,
                0,1,0,0,
                0,0,1,0,
                -origin[1],-origin[2],-origin[3],1
            })
            self.origin=origin
        end
    }
end

function make_player(origin,a)
    local angle,dangle,velocity,dead,deadangle={0,a,0},{0,0,0},{0,0,0,}
  
    return {
      -- start above floor
      origin=v_add(origin,{0,1,0}),    
      m=make_m_from_euler(unpack(angle)),
      control=function(self)
        -- move
        local dx,dz,a,jmp=0,0,angle[2],0
        if(btn(0,1)) dx=3
        if(btn(1,1)) dx=-3
        if(btn(2,1)) dz=3
        if(btn(3,1)) dz=-3
        if(btnp(4)) jmp=12
  
        dangle=v_add(dangle,{stat(39),stat(38),0})
        local c,s=cos(a),-sin(a)
        velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx})         
      end,
      update=function(self)
        -- damping      
        angle[3]*=0.8
        dangle=v_scale(dangle,0.6)
        velocity[1]*=0.7
        --velocity[2]*=0.9
        velocity[3]*=0.7
        -- gravity
        velocity[2]-=1
  
        if dead then
          angle=v_lerp(angle,deadangle,0.6)
        else
          angle=v_add(angle,dangle,1/1024)
        end
  
        -- check next position
        local vn,vl=v_normz(velocity)      
        local new_pos,new_vel,new_ground=v_add(self.origin,velocity),velocity,self.ground
        if vl>0.1 then
            if new_pos[2]<0 then
              new_pos[2]=0
              new_vel[2]=0
            end
            -- stays on floor
            new_pos[1]=mid(new_pos[1],0,1024)
            new_pos[3]=mid(new_pos[3],0,1024)
            -- use corrected velocity
            self.origin=new_pos
            velocity=new_vel
        end

        if dead then
          self.eye_pos=v_add(self.origin,{0,8,0})
        else
          self.eye_pos=v_add(self.origin,{0,24,0})

          -- check collisions
          --[[
          local things=_grid[world_to_grid(self.eye_pos)]
          for thing in pairs(things) do
            local dist=v_len(make_v(self.eye_pos,thing.origin))
            if dist<16 then
              dead=true
              deadangle=v_clone(angle)
              deadangle[1]-=rnd()/32
            end
          end
          ]]
        end
        self.m=make_m_from_euler(unpack(angle))   
        self.angle=angle         
      end
    } 
end

local ground={
    {0,0,0},
    {0,0,1024},
    {1024,0,1024},
    {1024,0,0}
}

function draw_ground(light)
    local m=_cam.m
    local m1,m5,m9,m13,m2,m6,m10,m14,m3,m7,m11,m15=m[1],m[5],m[9],m[13],m[2],m[6],m[10],m[14],m[3],m[7],m[11],m[15]
    local verts,outcode,nearclip={},0xffff,0  
    -- to cam space + clipping flags
    for i,v0 in pairs(ground) do
        local code,x,y,z=2,v0[1],v0[2],v0[3]
        local ax,ay,az=m1*x+m5*y+m9*z+m13,m2*x+m6*y+m10*z+m14,m3*x+m7*y+m11*z+m15
        if(az>8) code=0
        if(az>854) code|=1
        -- fov adjustment
        if(-ax<<1>az) code|=4
        if(ax<<1>az) code|=8
        
        local w=128/az 
        verts[i]={ax,ay,az,u=x>>4,v=z>>4,x=63.5+ax*w,y=63.5-ay*w,w=w}

        outcode&=code
        nearclip+=code&2
    end
    -- out of screen?
    if outcode==0 then
      if nearclip!=0 then
        -- near clipping required?
        local res,v0={},verts[#verts]
        local d0=v0[3]-8
        for i,v1 in inext,verts do
          local side=d0>0
          if(side) res[#res+1]=v0
          local d1=v1[3]-8
          if (d1>0)!=side then
            -- clip!
            local t=d0/(d0-d1)
            local v=v_lerp(v0,v1,t)
            -- project
            -- z is clipped to near plane
            v.x=63.5+(v[1]<<4)
            v.y=63.5-(v[2]<<4)
            v.w=16
            v.u=lerp(v0.u,v1.u,t)
            v.v=lerp(v0.v,v1.v,t)
            res[#res+1]=v
          end
          v0,d0=v1,d1
        end
        verts=res
      end
      mode7(verts,#verts,light)
    end    
end

function mode7(p,np,light)
  poke4(0x5f38,0x0000.0404)
  local miny,maxy,mini=32000,-32000
  -- find extent
  for i=1,np do
    local y=p[i].y
    if (y<miny) mini,miny=i,y
    if (y>maxy) maxy=y
  end

  --data for left & right edges:
  local lj,rj,ly,ry,lx,ldx,rx,rdx,lu,ldu,lv,ldv,ru,rdu,rv,rdv,lw,ldw,rw,rdw=mini,mini,miny-1,miny-1
  local maxlight,pal0=light\0.066666
  --step through scanlines.
  if(maxy>127) maxy=127
  if(miny<0) miny=-1
  for y=1+miny&-1,maxy do
    --maybe update to next vert
    while ly<y do
      local v0=p[lj]
      lj+=1
      if (lj>np) lj=1
      local v1=p[lj]
      -- make sure w gets enough precision
      local y0,y1,w1=v0.y,v1.y,v1.w
      local dy=y1-y0
      ly=y1&-1
      lx=v0.x
      lw=v0.w
      lu=v0.u*lw
      lv=v0.v*lw
      ldx=(v1.x-lx)/dy
      ldu=(v1.u*w1-lu)/dy
      ldv=(v1.v*w1-lv)/dy
      ldw=(w1-lw)/dy
      --sub-pixel correction
      local dy=y-y0
      lx+=dy*ldx
      lu+=dy*ldu
      lv+=dy*ldv
      lw+=dy*ldw
    end   
    while ry<y do
      local v0=p[rj]
      rj-=1
      if (rj<1) rj=np
      local v1=p[rj]
      local y0,y1,w1=v0.y,v1.y,v1.w
      local dy=y1-y0
      ry=y1&-1
      rx=v0.x
      rw=v0.w
      ru=v0.u*rw
      rv=v0.v*rw
      rdx=(v1.x-rx)/dy
      rdu=(v1.u*w1-ru)/dy
      rdv=(v1.v*w1-rv)/dy
      rdw=(w1-rw)/dy
      --sub-pixel correction
      local dy=y-y0
      rx+=dy*rdx
      ru+=dy*rdu
      rv+=dy*rdv
      rw+=dy*rdw
    end
    
    -- rectfill(rx,y,lx,y,8/rw)
    if rw>0.15 then
      local rx,lx,ru,rv,lu,lv=rx,lx,ru,rv,lu,lv
      local ddx=lx-rx--((lx+0x1.ffff)&-1)-(rx&-1)
      local ddu,ddv=(lu-ru)/ddx,(lv-rv)/ddx
      if(rx<0) ru-=rx*ddu rv-=rx*ddv rx=0
      if(lx>127) lu+=(128-lx)*ddu lv+=(128-lx)*ddv lx=128
      if rx<lx then
        local r0=rw>0.46875 and maxlight or (light*rw)\0.03125
        if(pal0!=r0) memcpy(0x5f00,0x4300|r0<<4,16) pal0=r0	-- color shift now to free up a variable
        -- refresh actual extent
        ddx=lx-rx--((lx+0x1.ffff)&-1)-(rx&-1)
        ddu,ddv=(lu-ru)/ddx,(lv-rv)/ddx
        local pix=1-rx&0x0.ffff
        tline(rx,y,lx\1-1,y,(ru+pix*ddu)/rw,(rv+pix*ddv)/rw,ddu/rw,ddv/rw)
      end
    end

    lx+=ldx
    lu+=ldu
    lv+=ldv
    lw+=ldw
    rx+=rdx
    ru+=rdu
    rv+=rdv
    rw+=rdw
  end      
end

-- grid helpers
function world_to_grid(p)
  return (p[1]\128)>>16|(p[2]\128)>>8|(p[3]\128)
end

function grid_register(thing)
  local id=world_to_grid(thing.origin)
  local things=_grid[id] or {}
  things[thing]=true
  _grid[id]=things
end

function grid_unregister(thing)
  local id=world_to_grid(thing.origin)
  local things=_grid[id] or {}
  things[thing]=nil
  _grid[id]=things
end

function collect_blocks(cam,visible_blocks) 
  -- note: fwd is in world space   
  local fwd=cam.fwd
  local majord,majori=-32000,1
  for i=1,3 do
      local d=abs(fwd[i])
      if d>majord then
          majori,majord=i,d
      end
  end

  local minord,minori=-32000,1
  for i=1,3 do
      if i!=majori then
          local d=abs(fwd[i])
          if d>minord then
              minori,minord=i,d
          end
      end
  end
  local last={
      {-1,3,2},
      {3,-1,1},
      {2,1,-1}
  }
  local extents={7,7,2}

  local lasti=last[majori][minori]

  local cam_last=cam.origin[lasti]\128

  local last0,last1=0,7
  local last_fix=cam_last
  local lastc=last_fix
  if lastc<last0 then
      lastc,last_fix=last0-1
  elseif lastc>last1 then
      lastc,last_fix=last1+1
  end   
  local last_shift=(3-lasti)<<3
  local collect_last=function(idx)
      for last=last0,lastc-1 do        
          local idx=idx|last>>>last_shift
          local things=_grid[idx]
          if things then
              add(visible_blocks,things)
              add(visible_blocks,idx)
          end
      end
      -- flip side
      for last=last1,lastc+1,-1 do        
          local idx=idx|last>>>last_shift
          local things=_grid[idx]
          if things then
            add(visible_blocks,things)
            add(visible_blocks,idx)
        end
      end
      if last_fix then
          local idx=idx|lastc>>>last_shift
          local things=_grid[idx]
          if things then
            add(visible_blocks,things)
            add(visible_blocks,idx)
        end
      end
  end     

  local minor0,minor1=0,7
  local minor_fix=cam.origin[minori]\128
  local minorc=minor_fix
  if minorc<minor0 then
      minorc,minor_fix=minor0-1
  elseif minorc>minor1 then
      minorc,minor_fix=minor1+1
  end   
  local minor_shift=(3-minori)<<3
  local collect_minor=function(idx)
      for minor=minor0,minorc-1 do        
        collect_last(idx|minor>>>minor_shift)
      end
      -- flip side
      for minor=minor1,minorc+1,-1 do        
        collect_last(idx|minor>>>minor_shift)
      end
      -- camera fix?
      if minor_fix then
        collect_last(idx|minorc>>>minor_shift)
      end
  end    

  -- main render loop
  local major0,major1=0,7
  local major_fix=cam.origin[majori]\128
  local majorc=major_fix
  if majorc<major0 then
      majorc,major_fix=major0-1
  elseif majorc>major1 then
    majorc,major_fix=major1+1
  end    
  local major_shift=(3-majori)<<3
  for major=major0,majorc-1 do        
    collect_minor(major>>>major_shift)
  end
  -- flip side
  for major=major1,majorc+1,-1 do        
    collect_minor(major>>>major_shift)
  end
  if major_fix then
    collect_minor(majorc>>>major_shift)
  end
end

function draw_grid(cam,light)
  local m,fov=cam.m,cam.fov
  local cx,cy,cz=unpack(cam.origin)
  local visible_blocks,grid={},_grid
  local m1,m5,m9,m13,m2,m6,m10,m14,m3,m7,m11,m15=m[1],m[5],m[9],m[13],m[2],m[6],m[10],m[14],m[3],m[7],m[11],m[15]

  -- viz blocks
  collect_blocks(cam,visible_blocks)

  -- render shadows
  poke(0x5f5e, 0b11111110)
  for i=1,#visible_blocks,2 do
    for thing in pairs(visible_blocks[i]) do
      local origin=thing.origin
      local x,z=origin[1],origin[3]
      -- draw shadows (y=0)
      local ax,az=m1*x+m9*z+m13,m3*x+m11*z+m15
      if az>8 and az<854 and ax<az and -ax<az then
        local ay=m2*x+m10*z+m14
        -- 
        local w=128/az
        -- thing offset+cam offset              
        local dx,dz=cx-x,cz-z
        local a=atan2(dx,dz)        
        local d=dx*cos(a)+dz*sin(a)
        local a=atan2(d,cy)
        local r=4*w
        local ry=-r*sin(a)
        local x0,y0=63.5+ax*w,63.5-ay*w
        ovalfill(x0-r,y0-ry,x0+r,y0+ry,1)
      end
    end
  end
  poke(0x5f5e, 0xff)

  -- render in order
  for i=1,#visible_blocks,2 do
    -- sorted array
    local things={}      
    for thing in pairs(visible_blocks[i]) do
      local origin=thing.origin
      local x,y,z=origin[1],origin[2],origin[3]
      -- draw shadows
      local ax,az=m1*x+m5*y+m9*z+m13,m3*x+m7*y+m11*z+m15
      if az>8 and az<854 and ax<az and -ax<az then
        local ay=m2*x+m6*y+m10*z+m14
      
        -- default: insert at end of sorted array
        local w,thingi=128/az,#things+1
        -- basic insertion sort
        for i,otherthing in inext,things do          
          if(otherthing[1]>w) thingi=i break
        end
        -- thing offset+cam offset
        add(things,{w,thing,63.5+ax*w,63.5-ay*w},thingi)
      end
    end
    
    -- draw things
    local prev_base,pal0
    for _,head in inext,things do
      local w0,thing=head[1],head[2]
      -- zangle
      local lookat=make_v(thing.origin,cam.origin)
      local side,flip=8*((atan2(lookat[1],-lookat[3])-thing.zangle+0.0625)&0x0.ffff)\1
      if(side>4) side=4-(side%5) flip=true
      
      local dx,dz=lookat[1],lookat[3]
      local a=atan2(dx,dz)        
      local dist=dx*cos(a)+dz*sin(a)
      local yside,yflip=8*((atan2(dist,lookat[2])-0.25+0.0625)&0x0.ffff)\1
      if(yside>4) yside=4-(yside%5) yflip=true
      -- copy to spr
      -- skip top+top rotation
      local mem,base=0x0,128*(8*(5-yside)+side)+1
      if not prev_base!=base then
        for i=0,31 do
          poke4(mem,_sprites[base],_sprites[base+1],_sprites[base+2],_sprites[base+3])
          mem+=64
          base+=4
        end
        prev_base=base
      end
      local sw=16*w0
      local sx,sy,pal1=head[3]-sw/2,head[4]-sw/2,(light*min(15,w0<<5))\1
      if(pal0!=pal1) memcpy(0x5f00,0x4300|pal1<<4,16) palt(0,true) pal0=pal1   
      sspr(0,0,32,32,sx,sy,sw+sx%1,sw+sy%1,flip)
      --print(thing.zangle,sx+sw/2,sy-8,9)      
    end
  end    
end

-- things
function make_skull(_origin)
  local forces,vel={0,0,0},{0,0,0}
  local seed,wobling=rnd(3),3+rnd(2)
  local thing=add(_things,setmetatable({
    -- sprite id
    id=0,
    origin=_origin,
    zangle=rnd(),
    yangle=0,
    update=function(_ENV)
      grid_unregister(_ENV)

      -- some gravity
      if origin[2]<12 then 
        forces={0,wobling,0}
      elseif origin[2]>80 then
        forces={0,-wobling*2,0}
      end
      -- some friction
      vel=v_scale(vel,0.9)
      -- converge toward player
      local dir=v_dir(origin,_plyr.eye_pos)
      forces=v_add(forces,dir,5+seed*cos(time()/5))
      -- avoid others
      local idx=world_to_grid(origin)
      
      local fx,fy,fz=unpack(forces)
      for other in pairs(_grid[idx]) do
        local avoid,avoid_dist=v_dir(origin,other.origin)
        if(avoid_dist<1) avoid_dist=1
        local t=-4/avoid_dist
        fx+=t*avoid[1]
        fy+=t*avoid[2]
        fz+=t*avoid[3]
      end
      forces={fx,fy,fz}

      local old_vel=vel
      vel=v_add(vel,forces,1/30)
      
      -- align direction and sprite direction
      local target_angle=atan2(old_vel[1]-vel[1],vel[3]-old_vel[3])
      zangle=lerp(shortest_angle(target_angle,zangle),target_angle,0.2)
      
      -- move & clamp
      origin[1]=mid(origin[1]+vel[1],0,1024)
      origin[2]=max(4,origin[2]+vel[2])
      origin[3]=mid(origin[3]+vel[3],0,1024)

      forces={0,0,0}
      grid_register(_ENV)
    end
  },{__index=_ENV}))
  grid_register(thing)
  return thing
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

-- gameplay state
function play_state()
  local start_time

  -- load images
  _sprites=decompress("pic",0,0,unpack_images)
  reload()

  -- camera & player
  _plyr=make_player({512,24,512},0)
  _things={}
  -- spatial partitioning grid
  _grid={}

  add(_things,_plyr)
  -- test object
  for i=0,50 do
    make_skull({32+rnd(768),18+rnd(48),32+rnd(768)})
  end

  _cam=make_fps_cam()

  return
    -- update
    function()
      _plyr:control()
      
      _cam:track(_plyr.eye_pos,_plyr.m,_plyr.angle)
    end,
    -- draw
    function()
      cls(0)
            
      draw_ground(1)

      -- draw things
      draw_grid(_cam,1)      
                            
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 12,0},1)

      print(stat(0).."kb",2,2,3)
    end,
    -- init
    function()
      start_time=time()
    end
end

-- pico8 entry points
function _init()
  -- enable tile 0 + extended memory
  poke(0x5f36, 0x18)
  -- capture mouse
  -- enable lock
  poke(0x5f2d,0x7)

  -- exit menu entry
  menuitem(1,"main menu",function()
    -- local version
    load("freds72_daggers_title.p8")
    -- bbs version
    load("#freds72_daggers_title")
  end)

  -- capture gradient
  local mem=0x4300
  for i=15,0,-1 do
    for j=0,15 do
      poke(mem,sget(i+32,j+16))
      mem+=1
    end
  end

  -- run game
  next_state(play_state)
end

function _update()
  -- keep world running
  count=0
  for thing in all(_things) do
    if(thing.update) thing:update()
  end
  _update_state()
end

-- data unpacking functions
-- unpack 1 or 2 bytes
function unpack_variant()
	return mpeek()|mpeek()<<8
end
-- unpack a fixed 16:16 value or 4 bytes
function unpack_dword()
	return mpeek()>>16|mpeek()>>8|mpeek()|mpeek()<<8
end

-- unpack an array of bytes
function unpack_array(fn)
	for i=1,unpack_variant() do
		fn(i)
	end
end

function unpack_images()
  local sprites={}
  unpack_array(function()
    for i=1,128 do
      add(sprites,unpack_dword())
    end
  end)

  return sprites
end