local _plyr,_cam,_things,_grid
local _entities,_particles,_bullets={}

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
    local fire_ttl,fire=0
    return {
      -- start above floor
      origin=v_add(origin,{0,1,0}), 
      tilt=0,   
      m=make_m_from_euler(unpack(angle)),
      control=function(self)
        -- move
        local dx,dz,a,jmp=0,0,angle[2],0
        if(btn(0,1)) dx=3
        if(btn(1,1)) dx=-3
        if(btn(2,1)) dz=3
        if(btn(3,1)) dz=-3
        if(btnp(4)) jmp=12

        if not dead and btn(5) and fire_ttl<=0 then
          fire_ttl,fire=3,true
        end

        dangle=v_add(dangle,{stat(39),stat(38),0})
        self.tilt+=dx/40
        local c,s=cos(a),-sin(a)
        velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx})                 
      end,
      update=function(self)
        -- damping      
        angle[3]*=0.8
        dangle=v_scale(dangle,0.6)
        self.tilt*=0.6
        if(abs(self.tilt)<0.0001) self.tilt=0
        velocity[1]*=0.7
        --velocity[2]*=0.9
        velocity[3]*=0.7
        -- gravity
        velocity[2]-=1
        
        -- avoid overflow!
        fire_ttl=max(fire_ttl-1)

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
            -- temporary: stays on floor
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

        if fire then
          fire=nil
          make_bullet(v_add(self.origin,{0,18,0}),self.m)
        end
      end
    } 
end

function make_bullet(origin,m)
  local o=v_add(origin,v_add(v_scale(m_up(m),1-rnd(2)),m_right(m),1-rnd(2)))
  _bullets[#_bullets+1]={
    origin=o,
    velocity=m_fwd(m),
    ttl=time()+3+rnd(2),
    c=rnd()
  }
end

function make_particle(origin,fwd)
  _particles[#_particles+1]={
    origin=origin,
    velocity=fwd,
    ttl=time()+0.25+rnd()/5,
    c=rnd(2)+10
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
  return (p[1]\32)>>16|(p[2]\32)>>8|(p[3]\32)
end

function grid_register(thing)
  local id=world_to_grid(thing.origin)
  local things=_grid[id] or {}
  things[thing]=true
  _grid[id]=things
end

-- note: assumes a call to register was done before
function grid_unregister(thing)
  local id=world_to_grid(thing.origin)
  local things=_grid[id]
  if things then
    things[thing]=nil
    -- kill bucket
    if(not next(things)) _grid[id]=nil
  end
end

-- radix sort
function rsort(_data)  
  local _len,buffer1,buffer2,idx=#_data, _data, {}, {}

  -- radix shift
  for shift=0,5,5 do
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

function draw_grid(cam,light)
  local m,fov=cam.m,cam.fov
  local cx,cy,cz=unpack(cam.origin)
  local m1,m5,m9,m13,m2,m6,m10,m14,m3,m7,m11,m15=m[1],m[5],m[9],m[13],m[2],m[6],m[10],m[14],m[3],m[7],m[11],m[15]

  local things={}
  -- bullets
  poke4(0x5f38,0x0004.0101)

  -- render shadows (& collect)
  poke(0x5f5e, 0b11111110)
  for _,thing in pairs(_things) do
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

    local x,y,z=origin[1],origin[2],origin[3]
    if thing!=_plyr then
      -- collect monsters
      local ax,az=m1*x+m5*y+m9*z+m13,m3*x+m7*y+m11*z+m15
      if az>8 and az<854 and ax<az and -ax<az then
        local ay=m2*x+m6*y+m10*z+m14
      
        local w=128/az
        things[#things+1]={key=w,type=1,thing=thing,x=63.5+ax*w,y=63.5-ay*w}      
      end
    end
  end
  poke(0x5f5e, 0xff)

  -- collect bullets
  for i,bullet in pairs(_bullets) do
    local prev,origin=bullet.prev,bullet.origin
    local x0,y0,z0=prev[1],prev[2],prev[3]
    local x1,y1,z1=origin[1],origin[2],origin[3]
    -- 
    local ax0,az0=m1*x0+m5*y0+m9*z0+m13,m3*x0+m7*y0+m11*z0+m15
    local ax1,az1=m1*x1+m5*y1+m9*z1+m13,m3*x1+m7*y1+m11*z1+m15
    if az0>8 and az1>8 and az0<854 and az1<854 and ax0<az0 and -ax0<az0 and ax1<az1 and -ax1<az1 then
      local ay0=m2*x0+m6*y0+m10*z0+m14
      local ay1=m2*x1+m6*y1+m10*z1+m14
    
      local w0,w1=128/az0,128/az1
      things[#things+1]={key=max(w0,w1),type=2,thing=bullet,x0=63.5+ax0*w0,y0=63.5-ay0*w0,x1=63.5+ax1*w1,y1=63.5-ay1*w1}
    end
  end

  -- collect particles
  for i,bullet in pairs(_particles) do
    local origin=bullet.origin
    local x0,y0,z0=origin[1],origin[2],origin[3]
    -- 
    local ax0,az0=m1*x0+m5*y0+m9*z0+m13,m3*x0+m7*y0+m11*z0+m15
    if az0>8 and az0<854 and ax0<az0 and -ax0<az0 then
      local ay0=m2*x0+m6*y0+m10*z0+m14
      local w0=128/az0
      things[#things+1]={key=w0,type=3,thing=bullet,x=63.5+ax0*w0,y=63.5-ay0*w0}
    end
  end

  -- radix sort
  bench_start("rsort")
  rsort(things)
  bench_end()

  -- render in order
  local prev_base,pal0
  for _,item in ipairs(things) do
    local pal1=(light*min(15,item.key<<5))\1
    if(pal0!=pal1) memcpy(0x5f00,0x4300|pal1<<4,16) palt(0,true) pal0=pal1   
    if item.type==1 then
      -- draw things
      local w0,thing=item.key,item.thing
      -- todo: change to use thing type
      local sprites=_entities.skull
      local origin=thing.origin
      -- zangle
      local dx,dz=cx-origin[1],cz-origin[3]
      local zangle=atan2(dx,-dz)
      local side,flip=8*((zangle-thing.zangle+0.5+0.0625)&0x0.ffff)\1
      if(side>4) side=4-(side%5) flip=true
      
      local yside=8*((atan2(dx*cos(-zangle)+dz*sin(-zangle),cy-origin[2])-0.25+0.0625)&0x0.ffff)\1
      if(yside>4) yside=4-(yside%5)
      -- copy to spr
      -- skip top+top rotation
      local mem,base=0x0,128*(8*(5-yside)+side)+1
      if prev_base!=base then
        for i=0,31 do
          poke4(mem,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
          mem+=64
          base+=4
        end
        prev_base=base
      end
      local sw=16*w0
      local sx,sy=item.x-sw/2,item.y-sw/2
      --
      sspr(0,0,32,32,sx,sy,sw+(sx&0x0.ffff),sw+(sy&0x0.ffff),flip)
      --sspr(0,0,32,32,sx,sy,32,32,flip)
      --print(thing.zangle,sx+sw/2,sy-8,9)      
    elseif item.type==2 then
      tline(item.x0,item.y0,item.x1,item.y1,item.thing.c,0,0,1/8)
    elseif item.type==3 then
      pset(item.x,item.y,item.thing.c)
    end
  end 
  
  -- tilt!
  -- screen = gfx
  local yshift=8*sin(_plyr.tilt)/128
  poke(0x5f54,0x60)
  for i=0,127 do
    sspr(i,0,1,128,i,(i-64)*yshift)
  end
  -- reset
  poke(0x5f54,0x00)
  -- hide trick top/bottom 8 pixel rows :)
  memset(0x6000,0,512)
  memset(0x7e00,0,512)
end

-- things
function make_skull(_origin)
  local forces,vel={0,0,0},{0,0,0}
  local seed,wobling=rnd(3),3+rnd(2)
  local resolved={}
  local thing=add(_things,setmetatable({
    -- sprite id
    id=0,
    origin=_origin,
    zangle=rnd(),
    yangle=0,
    apply=function(_ENV,other,force,t)
      forces[1]+=t*force[1]
      forces[2]+=t*force[2]
      forces[3]+=t*force[3]
      resolved[other]=true
    end,
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
      
      local fx,fy,fz=forces[1],forces[2],forces[3]
      for other in pairs(_grid[idx]) do
        -- todo: apply inverse force to other (and keep track)
        if not resolved[other] then
          local avoid,avoid_dist=v_dir(origin,other.origin)
          if(avoid_dist<1) avoid_dist=1
          local t=-4/avoid_dist
          fx+=t*avoid[1]
          fy+=t*avoid[2]
          fz+=t*avoid[3]

          other:apply(_ENV,avoid,-t)
          resolved[other]=true
        end
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
      resolved={}
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

  -- camera & player
  _plyr=make_player({512,24,512},0)
  _things,_particles,_bullets={},{},{}
  -- spatial partitioning grid
  _grid={}

  add(_things,_plyr)
  -- test objects
  for i=0,50 do
    make_skull({32+rnd(768),18+rnd(48),32+rnd(768)})
  end
  --make_skull({512,24,512})

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
      bench_start("draw_grid")
      draw_grid(_cam,1)      
      bench_end()
            
      -- player "hud"
      -- spr(64,48,96,4,4)
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 12,0},1)
      
      print(stat(0).."kb",2,2,3)

      bench_print(2,8,7)
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

  -- load images
  _entities=decompress("pic",0,0,unpack_entities)
  reload()
  
  -- run game
  next_state(play_state)
end

function _update()
  -- keep world running
  bench_start("things")
  for thing in all(_things) do
    if(thing.update) thing:update()
  end
  bench_end()
  
  local t=time()
  for i=#_bullets,1,-1 do
    local b=_bullets[i]
    if b.ttl<t then
      deli(_bullets,i)
    else
      b.prev,b.origin=b.origin,v_add(b.origin,b.velocity,5)      
      -- hit ground?
      if b.origin[2]<0 then
        -- intersection
        local dy=(b.prev[2])/(b.origin[2]-b.prev[2])
        for i=0,rnd(4) do
          make_particle({
            lerp(b.prev[1],b.origin[1],dy),
            0,
            lerp(b.prev[3],b.origin[3],dy)
          },{1-rnd(2),2+rnd(),1-rnd(2)})
        end
        deli(_bullets,i)
      end
    end
  end
  for i=#_particles,1,-1 do
    local p=_particles[i]
    if p.ttl<t then
      deli(_particles,i)
    else
      p.origin=v_add(p.origin,p.velocity,0.2)
      -- bit of gravity
      p.velocity[2]-=2      
      if p.origin[2]<0 then
        -- fake bounce
        p.velocity[1]*=0.8      
        p.velocity[2]*=-0.8      
        p.velocity[3]*=0.8      
        --deli(_particles,i)
      end
    end
  end

  _update_state()
end

-- data unpacking functions
function mpeek2()
	return mpeek()|mpeek()<<8
end
-- unpack a fixed 16:16 value or 4 bytes
function mpeek4()
	return mpeek2()|mpeek()>>>16|mpeek()>>8
end

-- unpack an array of bytes
function unpack_array(fn)
	for i=1,mpeek2() do
		fn(i)
	end
end

function unpack_entities()  
  local entities,names={},split"skull,reaper,blood0,blood1,blood2"
  unpack_array(function()
    local id=mpeek()
    if id!=0 then
      entities[names[id]]=unpack_images()
    end
  end)
  return entities
end

function unpack_images()
  local sprites={}
  unpack_array(function(k)
    for i=1,128 do
      add(sprites,mpeek4())
    end
  end)

  return sprites
end