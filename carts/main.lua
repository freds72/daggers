-- global arrays
local _bsp,_things,_futures,_spiders,_plyr,_cam,_grid,_entities={},{},{},{}
-- stats
local _total_jewels,_total_bullets,_total_hits,_show_timer,_start_time=0,0,0,false
local _slow_mo,_hw_pal,_ramp_pal,_fire_ttl,_shotgun_count,_shotgun_spread=0,0,0x8180,3,10,0.025
-- must be globals
_spawn_angle,_spawn_origin=0,split"512,0,512"

local _vertices,_ground_extents=split[[384.0,0,320.0,
384.0,0,704.0,
640.0,0,704.0,
640.0,0,320.0,
320.0,0,384.0,
320.0,0,640.0,
384.0,0,640.0,
384.0,0,384.0,
640.0,0,384.0,
640.0,0,640.0,
704.0,0,640.0,
704.0,0,384.0,
384.0,-32,320.0,
384.0,-32,704.0,
640.0,-32,704.0,
640.0,-32,320.0,
320.0,-32,384.0,
320.0,-32,640.0,
384.0,-32,640.0,
384.0,-32,384.0,
640.0,-32,384.0,
640.0,-32,640.0,
704.0,-32,640.0,
704.0,-32,384.0]],
{
  -- xmin/max - ymin/max
  -- with 8 unit buffer simulate player "volume"
  split"312.0,392.0,376.0,648.0",
  split"376.0,648.0,312.0,712.0",
  split"632.0,712.0,376.0,648.0"
}

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

-- wait until a certain number of jewels is captured
function wait_jewels(n)
  local prev=_total_jewels
  while _total_jewels<n do
    if _total_jewels!=prev then
      for i in all(split"256,288,320,288,0") do
        _hw_pal=i
        yield()
      end
    end
    -- update with current total (avoids overlapping "flash" effects)
    prev=_total_jewels
    yield()
  end
  _slow_mo=0
end

function levelup_async(t)
  -- 30 frames at 1/8 steps
  for j=0.125,t<<2,0.125 do
    _ramp_pal=0x8280+((j*j)&15)*16
    _slow_mo+=1
    yield()
  end
  -- restore state
  _ramp_pal,_slow_mo=0x8180,0
end

-- record number of "things" on playground and wait until free slots are available
-- note: must be called from a coroutine
local _total_things,_time_penalty,_time_wait=0,0
function reserve_async(n)
  while _total_things>60 do
    if(not _time_wait) _time_wait=time()
    yield()
  end
  _total_things+=n
  if(_time_wait) _time_penalty+=time()-_time_wait _time_wait=nil
end

-- misc helpers
function inherit(t,env)
  return setmetatable(t,{__index=env or _ENV})
end
function nop() end
function with_properties(props,dst)
  local dst,props=dst or {},split(props)
  for i=1,#props,2 do
    local k,v=props[i],props[i+1]
    -- deference
    if k[1]=="@" then
      k,v=sub(k,2,-1),_ENV[v]
    elseif k=="ent" then 
      v=_entities[v] 
    else
      local fn=_ENV[v]
      -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      -- note: assumes that function never returns a falsey value
      v=type(fn)=="function" and fn() or v 
    end
    dst[k]=v
  end
  return dst
end

-- grid helpers
-- adds thing in the collision grid
function grid_register(thing)
  local grid,_ENV=_grid,thing
  
  local x,z=origin[1],origin[3]
  -- \32(=5) + >>16
  local x0,x1,z0,z1=(x-radius)>>21,(x+radius)>>21,(z-radius)\32,(z+radius)\32
  -- different from previous range?
  if grid_x0!=x0 or grid_x1!=x1 or grid_z0!=z0 or grid_z1!=z1 then
    -- remove previous grid cells
    grid_unregister(thing)
    for idx=x0,x1,0x0.0001 do
      for idx=idx|z0,idx|z1 do
        local cell=grid[idx]
        cell.things[thing]=true
        -- for fast unregister
        if(not cells) cells={}
        cells[idx]=cell
      end
    end
    -- cache grid coords (keep inline for speed)
    grid_x0=x0
    grid_x1=x1
    grid_z0=z0
    grid_z1=z1

    -- noise emitter?
    if chatter then
      -- \64(=6) + >>16
      local cell=grid[x>>22|z\64]
      cell.chatter[chatter]+=1
      -- for fast unregister
      chatter_cell=cell
    end
  end
end

-- removes thing from the collision grid
function grid_unregister(_ENV)
  for idx,cell in pairs(cells) do
    cell.things[_ENV],cells[idx]=nil
  end  
  if chatter_cell then
    chatter_cell.chatter[chatter]-=1
    chatter_cell=nil
  end    
end

-- range index generator
--[[
  done={}

function visit(x0,y0,len)
 local s=""
	for x=x0,x0+len-1 do
	 for y=y0,y0+len-1 do
	 	local idx=(x-x0)>>16|(y-y0)
	 	if not done[x|y<<6] then
	 	 done[x|y<<6]=true
	 	 s..=tostr(idx,1)..","
	 	end
	 end
	end
	return s
end

local s="{{"..visit(2,2,2).."},\n"
s..="{"..visit(1,1,4).."},\n"
s..="{"..visit(0,0,6).."}}"
printh(s,"@clip")
]]
-- concentric offset around player in chatter grid
--  2222
-- 211112
-- 210012
-- 210012
-- 211112
--  2222

function make_player(_origin,_a)
  local _chatter_ranges,on_ground,prev_jump={
    split"0x0,0x0001,0x0.0001,0x0001.0001",
    split"0x0,0x0001,0x0002,0x0003,0x0.0001,0x0003.0001,0x0.0002,0x0003.0002,0x0.0003,0x0001.0003,0x0002.0003,0x0003.0003",
    split"0x0001,0x0002,0x0003,0x0004,0x0.0001,0x0005.0001,0x0.0002,0x0005.0002,0x0.0003,0x0005.0003,0x0.0004,0x0005.0004,0x0001.0005,0x0002.0005,0x0003.0005,0x0004.0005"
  }    
  return inherit(with_properties("tilt,0,radius,24,attract_power,0,dangle,v_zero,velocity,v_zero,eye_pos,v_zero,fire_ttl,0,fire_released,1,fire_frames,0,dblclick_ttl,0,fire,0",{
    -- start above floor
    origin=v_add(_origin,split"0,1,0"), 
    angle={0,_a,0},
    m=make_m_from_euler(angle),
    control=function(_ENV)
      if(dead) return
      -- move
      local dx,dz,a,jmp,jump_down=0,0,angle[2],0,stat(28,@0xc404)
      if(stat(28,@0xc402)) dx=3
      if(stat(28,@0xc403)) dx=-3
      if(stat(28,@0xc400)) dz=3
      if(stat(28,@0xc401)) dz=-3
      if(on_ground and prev_jump and not jump_down) jmp=24 on_ground=false sfx"58"
      prev_jump=jump_down

      -- straffing = faster!

      -- restore atract power
      attract_power=min(attract_power+0.2,1)

      -- double-click detector
      dblclick_ttl=max(dblclick_ttl-1)
      if btn(@0xc415) then
        if fire_released then
          fire_released=false
        end
        fire_frames+=1
        -- regular fire      
        if dblclick_ttl==0 and fire_ttl<=0 then
          sfx"48"
          fire_ttl,fire=_fire_ttl,1
        end
        -- 
        attract_power=0
      elseif not fire_released then
        if dblclick_ttl>0  then
          -- double click timer still active?
          -- shotgun (repulsive!)
          fire_ttl,fire,dblclick_ttl,attract_power=0,2,0,-1
          sfx"49"
        elseif fire_frames<4 then
          -- candidate for double click?
          dblclick_ttl=8
        end           
        fire_released,fire_frames=true,0
      end

      dangle=v_add(dangle,{$0xc410*stat(39),stat(38),0})
      tilt+=dx/40
      local c,s=cos(a),-sin(a)
      velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx},0.35)                 
    end,
    update=function(_ENV)
      -- damping      
      dangle=v_scale(dangle,0.6)
      -- very slow damping back to normal
      tilt*=0.82
      if(abs(tilt)<=0.0001) tilt=0
      velocity[1]*=0.7
      --velocity[2]*=0.9
      velocity[3]*=0.7
      -- gravity
      velocity[2]-=0.8
      
      -- avoid overflow!
      fire_ttl=max(fire_ttl-1)

      angle=v_add(angle,dangle,$0xc416/1024)
      -- limit x amplitude
      angle[1]=mid(angle[1],-0.24,0.24)
      -- check next position
      local vn,vl=v_normz(velocity)      
      local prev_pos,new_pos,new_vel=v_clone(origin),v_add(origin,velocity),velocity
      if vl>0.1 then
          local x,y,z=unpack(new_pos)
          if y<-64 then
            y=-64
            new_vel[2]=0
            if not dead then
              dead=true
              next_state(gameover_state,"FLOORED")
            end
          elseif y<0 then
            -- main grid?              
            local out=0
            for _,extent in pairs(_ground_extents) do
              if x<extent[1] or x>extent[2] or z<extent[3] or z>extent[4] then
                out+=1
              end
            end
            -- missed all ground chunks?
            if out!=#_ground_extents then
              -- stop velocity
              y=0
              new_vel[2]=0
              on_ground=true
            end
          end
          -- use corrected velocity
          origin,velocity={x,y,z},new_vel
      end

      eye_pos=v_add(origin,{0,18,0})

      -- check collisions
      local x,z=origin[1],origin[3]
      if not dead then   
        local vn,vl=v_normz{velocity[1],0,velocity[3]}
        -- for hand effect
        xz_vel=vl
        -- 
        collect_grid(prev_pos,origin,vn[1],vn[3],function(grid_cell)
          -- avoid reentrancy
          if(dead) return
          for thing in pairs(grid_cell) do
            if not thing.dead then
              -- special handling for crawling enemies
              local dist=v_len(thing.on_ground and origin or eye_pos,thing.origin)
              if dist<thing.radius then
                if thing.pickup then
                  thing:pickup()
                else
                  -- avoid reentrancy
                  --dead=true
                  --next_state(gameover_state,thing.obituary)
                  return
                end
              end
            end
          end
        end)
      end

      -- collect nearby chatter
      _chatter={}
      local x0,z0=x>>22,z\64
      for dist,offsets in inext,_chatter_ranges do
        local idx=x0|z0
        for _,idx_offset in inext,offsets do
          local cell=_grid[idx+idx_offset]            
          for chatter_id,cnt in pairs(cell.chatter) do
            if(cnt>0) add(_chatter,{chatter_id,dist-1})
            -- enough data?
            if(#_chatter==3) goto end_noise
          end
        end
        -- next range
        x0-=0x0.0001
        z0-=1
      end
::end_noise::

        --playback chatter
        foreach(_chatter, do_chatter)

        --check for chatter/ambient playback
        for i = 0, 2 do
          local cur_sfx = stat(46 + i)

          if mid(8, cur_sfx, 24) == cur_sfx then
            goto end_chatter
          end
        end

        --playback ambient sfx if no chatter
        sfx"24"

::end_chatter::

      -- refresh angles
      m=make_m_from_euler(unpack(angle))    

      -- normal fire
      local o=v_add(origin,{0,8,0})
      if fire==1 then          
        _total_bullets+=0x0.0001
        make_bullet(o,angle[2],angle[1],0.02)
      elseif fire==2 then
        -- shotgun
        _total_bullets+=_shotgun_count>>16
        for i=1,_shotgun_count do
          make_bullet(o,angle[2],angle[1],_shotgun_spread)
        end
      end
      fire=nil          
    end
  }))
end

local _checked=0
function vector_in_cone(zangle,yangle,spread)
  local zangle,yangle=0.25-zangle+(1-rnd"2")*spread,yangle+(1-rnd"2")*spread
  local u,v,s=cos(zangle),-sin(zangle),cos(yangle)
  return {s*u,sin(yangle),s*v},u,v,sgn(s),zangle,yangle
end

function make_bullet(_origin,_zangle,_yangle,_spread)
  -- no bullets while falling
  if(_origin[2]<2) return

  local _velocity,_u,_v,_s,_zangle=vector_in_cone(_zangle,_yangle,_spread)
  -- local o=v_add(origin,v_add(v_scale(m_up(m),1-rnd(2)),m_right(m),1-rnd(2)))
  add(_things,inherit({
    origin=v_clone(_origin),
    -- must be a unit vector  
    velocity=_velocity,
    -- fixed zangle
    zangle=_zangle,
    yangle=rnd(),
    -- 2d unit vector
    -- precomputed for collision detection
    -- make sure to keep the sign of the y component!!
    u=_s*_u,
    v=_s*_v,
    shadeless=true,
    ttl=time()+0.5+rnd"0.1",
    ent=rnd{_entities.dagger0,_entities.dagger1},
    physic=function(_ENV)
      if ttl<time() then
        dead=true
      else
        _checked+=1
        yangle+=0.1
        local cur_origin,new_origin,len,hit_t,hit_thing,hit_pos=origin,v_add(origin,velocity,10),10,32000
        local x,y,z=unpack(new_origin)
        if y<0 then
          -- hit ground?
          -- intersection with ground
          local dy=cur_origin[2]/(cur_origin[2]-y)
          x,y,z=lerp(cur_origin[1],x,dy),0,lerp(cur_origin[3],z,dy)
          new_origin={x,0,z}
          -- adjust length
          len*=dy
          -- no matter what - we hit the ground!
          dead=true
          -- sparkles
          for i=1,rnd"5" do
            local vel,u,v=vector_in_cone(0.25-zangle,yangle,0.03)
            make_particle(_dagger_hit_template,new_origin,v_scale(vel,1+rnd()))
          end
        end
        -- collect touched grid indices
        collect_grid(cur_origin,new_origin,u,v,function(things)
          -- todo: advanced bullets can traverse enemies
          for thing in pairs(things) do
            -- hitable?
            -- avoid checking the same enemy twice
            if not thing.dead and thing.hit and thing.checked!=_checked then
              thing.checked=_checked
              -- segment (a->b)/sphere(origin,r) intersection
              -- o_offset: y offset to origin (useful for squids)
              -- returns distance to target
              -- note: no need to scale down as check is done per 32x32 region
              local o=thing.origin
              local r,dx,dy,dz,ax,ay,az,oy=thing.radius,velocity[1],velocity[2],velocity[3],cur_origin[1],cur_origin[2],cur_origin[3],o[2]+(thing.o_offset or 0)
              -- projection on ray
              local mx,my,mz,ny=ax-o[1],ay-oy,az-o[3],y-oy
              if((my<-r and ny<-r) or (my>r and ny>r)) goto continue
              local b,c=dx*mx+dy*my+dz*mz,mx*mx+my*my+mz*mz-r*r
              if(c>0 and b>0)  goto continue
              local disc=b*b-c
              if(disc<0)  goto continue
              local t=-b-sqrt(disc)
              -- far away?
              if(t>len)  goto continue
              -- inside radius?
              if(t<0) t=rnd(len)
              if t<hit_t then
                hit_thing,hit_t,hit_pos=thing,t,{ax+t*dx,ay+t*dy,az+t*dz}
              end
::continue::
            end            
          end
        end)
        -- apply hit on closest thing
        if hit_thing then
          hit_thing:hit(hit_pos,_ENV)
          dead=true
          _total_hits+=0x0.0001
          -- todo: allow for multiple hits
        end
        origin=new_origin
      end      
    end
  }))
end

function draw_grid(cam)
  local things,m,cx,cy,cz={},cam.m,unpack(cam.origin)
  -- make sure camera matrix is local
  local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]

  -- clear shadows
	-- draw shadows
  split2d([[_map_display;1
poke;0x5f54;0x00;0x60
poke;0x5f5e;0b00001000
rectfill;0;0;127;127;0
poke;0x5f5e;0b10001000]],exec)

  -- project
  for i,obj in inext,_things do
    local origin=obj.origin  
    local oy=origin[2]
    if not obj.shadeless then
      local sx,sy=(origin[1]-320)/3,(origin[3]-320)/3        
      circfill(sx,sy,obj.radius/3,4)
    end
    -- centipede can be below ground...
    if oy>=1 then
      if not obj.no_render then
        local x,y,z=origin[1]-cx,origin[2]-cy,origin[3]-cz
        local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
        local az4=az<<2
        if az>4 and az<192 and ax<az4 and -ax<az4 and ay<az4 and -ay<az4 then
          local w=32/az
          things[#things+1]={key=w,thing=obj,x=63.5+ax*w,y=63.5-ay*w}      
        end
      end
    end
  end
  -- default transparency
  split2d([[poke;0x5f5e;0xff
poke;0x5f54;0x60;0x00
_map_display;0
poke;0x5f0f;0x1f
palt;0;0x00]],exec)

  -- radix sort
  rsort(things)

  -- render in order
  local prev_base,prev_sprites,pal0
  for _,item in inext,things do
    local thing=item.thing
    local hit_ttl,pal1=thing.hit_ttl
    if hit_ttl and hit_ttl>0 then
      pal1=15+hit_ttl
    else
      local light=thing.light_t and min(1,(time()-thing.light_t)/0.15) or 1
      pal1=(light*min(15,item.key<<4))\1
    end    
    if(pal0!=pal1) memcpy(0x5f00,_ramp_pal+(pal1<<4),16) palt(15,true) pal0=pal1   
      -- draw things
      local w0,entity,origin=item.key,thing.ent,thing.origin
      -- zangle (horizontal)
      local dx,dz,yangles,side,flip=cx-origin[1],cz-origin[3],entity.yangles,0
      local zangle=atan2(dx,-dz)
      if yangles!=0 then
        local step=1/(yangles<<1)
        side=((zangle-thing.zangle+0.5+step/2)&0x0.ffff)\step
        if(side>yangles) side=yangles-(side%yangles) flip=true
      end

      -- up/down angle
      local zangles,yside=entity.zangles,0
      if zangles!=0 then
        local yangle,step=thing.yangle or 0,1/(zangles<<1)
        yside=((atan2(dx*cos(-zangle)+dz*sin(-zangle),-cy+origin[2])-0.25+step/2+yangle)&0x0.ffff)\step
      if(yside>zangles) yside=zangles-(yside%zangles)
    end
    -- copy to spr
    -- skip top+top rotation
    local frame,sprites=entity.frames[(yangles+1)*yside+side+1],entity.sprites
    local base,w,h=frame.base,frame.width,frame.height
    -- cache works in 10% of cases :/
    if prev_base!=base or prev_sprites!=sprites then
      prev_base,prev_sprites=base,sprites
      for i=0,(h-1)<<6,64 do
        poke4(i,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
        base+=4
      end
    end
    w0*=(thing.scale or 1)
    local sx,sy=item.x-w*w0/2,item.y-h*w0/2
    local sw,sh=w*w0+(sx&0x0.ffff),h*w0+(sy&0x0.ffff)
    --
    sspr(frame.xmin,0,w,h,sx,sy,sw,sh,flip)

    --[[
    if thing.radius then
      local oy=thing.o_offset
      if oy then
        oy+=thing.origin[2]
        local x,y,z=origin[1]-cx,oy-cy,origin[3]-cz
        local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
        local w=32/az
        circ(63.5+w*ax,63.5-w*ay,w*thing.radius,10)
      else
        circ(item.x,item.y,w0*thing.radius,9)
      end
    end
    ]]
    --[[
    circ(item.x,item.y,(thing.radius or 1)*w0,9)
    if thing.debug_forces then
      -- draw
      local forces=thing.debug_forces
      local x,y,z=origin[1]+forces[1]-cx,origin[2]+forces[2]-cy,origin[3]+forces[3]-cz
      -- 
      local ax,az=m1*x+m5*y+m9*z,m3*x+m7*y+m11*z
      if az>8 then
        local ay,w=m2*x+m6*y+m10*z,64/az
        line(item.x,item.y,63.5+ax*w,63.5-ay*w,7)
      end
    end
    ]]

    --sspr(0,0,32,32,sx,sy,32,32,flip)
    --print(thing.zangle,sx+sw/2,sy-8,9)      
  end
end

-- particle thingy
function make_particle(template,_origin,_velocity)  
  local max_ttl=15+rnd"12"
  return add(_things,inherit({
    origin=_origin,
    update=function(_ENV)
      ttl+=1
      if(ttl>max_ttl) dead=true return
      -- animated?
      if(ents) ent=ents[flr(#ents*ttl/max_ttl)+1]
      -- trail
      if trail and ttl%4==0 then
        -- make sure child don't spawn other entities
        -- no need to clone as origin will be renewed after update
        -- particles are affected by gravity
        make_particle(_ENV[trail],v_clone(origin),{0,0,0})
      end
      if _velocity then
        -- if moving, apply gravity
        _velocity[2]-=0.4
        origin=v_add(origin,_velocity)        
        if origin[2]<1 and _velocity[2]<0 then
          origin[2]=1 _velocity=v_scale(_velocity,0.8) _velocity[2]*=rebound
          -- write on playground
          if stain and rebound==0 then
            -- convert coords into map space
            local sx,sy=(origin[1]-320)/3,(origin[3]-320)/3        
            pset(sx,sy,stain)
            dead=true
          end
        end
      end
    end
  },template))
end

function make_blood(origin,velocity)
  make_particle(_gib_template,origin,velocity)
end

function make_goo(_origin)
  return make_particle(_goo_gib_template,_origin)
end

-- base class for:
-- skull I III
-- centipede
-- spiderling
-- egg
function make_skull(actor,_origin)
  local thing=add(_things,inherit({
    origin=_origin,
    resolved={},
    seed=7+rnd(),
    -- grid cells
    cells={}
    -- perf test
    -- yangle=rnd()
  },actor))

  -- custom init function?
  if(thing.init) thing:init()

  grid_register(thing)
  
  --play spawn sfx
  sfx(actor.spawnsfx or 40)

  return thing
end

-- spider
function make_spider()
  local spawn_angle=_spawn_angle
  add(_things,inherit({
    origin=v_clone(_spawn_origin),
    zangle=_spawn_angle,
    light_t=time(),
    hit=function(_ENV,pos)
      if(dead) return
      hp-=1
      hit_ttl=5
      if hp<0 then
        dead=true
        make_goo(origin)
        -- unregister
        grid_unregister(_ENV)
        _spiders[_ENV]=nil
      end
    end,
    update=function(_ENV)
      for thing in pairs(_grid[origin[1]>>21|origin[3]\32].things) do
        if thing.is_jewel and not thing.dead then
          local dir,len=v_dir(origin,thing.origin)
          if len<radius then
            thing:pickup(true)
            do_async(function()
              wait_async(3)
              -- spit an egg
              local angle,force=spawn_angle+rnd"0.02"-0.01,8+rnd"4"
              make_egg(v_clone(origin),{-force*cos(angle),force*rnd(),force*sin(angle)})
            end)
          end
        end
      end

      -- todo: move to deck borders
      -- todo: rotate if HP < 50% ??
      grid_register(_ENV)
      -- register for jewel attractor
      _spiders[_ENV]=origin
    end
  },_spider_template))
end

-- squid
-- type 1: 3 blocks
-- type 2: 4 blocks
function make_squid(type)
  -- wait for a free slot
  reserve_async(5)

  local _origin,_velocity,_dx,_dz,_angle,_dead=v_clone(_spawn_origin),{-cos(_spawn_angle)/16,0,sin(_spawn_angle)/16},32000,32000,0
  -- spill skulls every x seconds
  local spill=do_async(function()
    wait_async(60)
    while not _plyr.dead do
      -- don't spawn while outside
      if _dx<256 and _dz<256 then
        reserve_async(5)
        for t in all(split"_skull1_template,_skull1_template,_skull1_template,_skull2_template,_skull1_template") do
          make_skull(_ENV[t],{_origin[1],64+rnd"16",_origin[3]})
          wait_async(2+rnd"2")
        end
        -- wait 10s
        wait_async(300)
      end
      yield()
    end
  end)

  local squid=make_skull(inherit({
    ai=spill,
    think=function(_ENV)
      dead=_dead
      _angle+=0.005
      -- keep "move" as the main driving force
      forces=v_add(forces,_velocity,30)
    end,
    post_think=function(_ENV)
      _origin,_dx,_dz=origin,abs(origin[1]-512),abs(origin[3]-512)
      -- remove squid if out of sight
      if(_dx>400 or _dz>400) _dead=true
    end
  },_squid_core),_origin)

  local squid_parts={
    -- type 1 (1 jewel)
[[_squid_jewel;light_ttl,15,a_offset,0.0,r_offset,8,y_offset,24,cost,5
_squid_hood;light_ttl,15,a_offset,0.3333,r_offset,8,y_offset,24
_squid_hood;light_ttl,15,a_offset,0.6667,r_offset,8,y_offset,24
_squid_tentacle;light_ttl,15,a_offset,0.0,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;light_ttl,15,a_offset,0.0,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;light_ttl,15,a_offset,0.0,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;light_ttl,15,a_offset,0.0,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2
_squid_tentacle;light_ttl,15,a_offset,0.3333,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;light_ttl,15,a_offset,0.3333,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;light_ttl,15,a_offset,0.3333,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;light_ttl,15,a_offset,0.3333,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2
_squid_tentacle;light_ttl,15,a_offset,0.6667,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;light_ttl,15,a_offset,0.6667,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;light_ttl,15,a_offset,0.6667,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;light_ttl,15,a_offset,0.6667,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2]],
    -- type 2 (2 jewels)
[[_squid_jewel;a_offset,0.0,r_offset,8,y_offset,24
_squid_hood;a_offset,0.25,r_offset,8,y_offset,24
_squid_jewel;a_offset,0.5,r_offset,8,y_offset,24
_squid_hood;a_offset,0.75,r_offset,8,y_offset,24
_squid_tentacle;a_offset,0.0,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;a_offset,0.0,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;a_offset,0.0,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;a_offset,0.0,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2
_squid_tentacle;a_offset,0.25,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;a_offset,0.25,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;a_offset,0.25,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;a_offset,0.25,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2
_squid_tentacle;a_offset,0.5,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;a_offset,0.5,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;a_offset,0.5,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;a_offset,0.5,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2
_squid_tentacle;a_offset,0.75,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;a_offset,0.75,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;a_offset,0.75,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;a_offset,0.75,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2]]}

  split2d(squid_parts[type],function(base_template,properties)
    add(_things,inherit(with_properties(properties,{
      light_t=time(),
      hit=function(_ENV,pos,bullet) 
        if(dead) return
        if jewel then
          hp-=1
          hit_ttl=5
          -- feedback
          make_particle(_lgib_template,pos,{u,-3*bullet.velocity[2],v})
          sfx"56"
          if hp<=0 then
            make_jewel(origin,{u,3,v},16)
            -- avoid reentrancy
            jewel=nil
            ent=_entities.squid2
            if(type==1) _dead=true
            -- "downgrade" squid!!
            type=1
          end
        end
      end,
      update=function(_ENV)
        if _dead then
          if(dead) return
          dead=true     
          make_blood(origin) 
          grid_unregister(_ENV)
          _total_things-=cost or 0   
          sfx"39"
        end
        zangle=_angle+a_offset
        -- store u/v angle
        local cc,ss,offset=cos(zangle),-sin(zangle),r_offset
        if is_tentacle then
          yangle=-cos(time()/8+scale)*swirl
          offset+=sin(time()/4+scale)*swirl
        else
          u,v=cc,ss
          zangle+=0.5
        end
        origin=v_add(_origin,{offset*cc,y_offset,offset*ss})
        if(not is_tentacle) grid_register(_ENV)
      end    
    }),_ENV[base_template]))
  end)
end

-- centipede
function make_worm()  
  reserve_async(10)

  local _origin,t_offset,seg_delta,segments,prev_angles,prev,head=v_clone(_spawn_origin),rnd(),4,{},{},{}
  _origin={512,-64,512}

  for i=1,20 do
    add(segments,add(_things,inherit({
      hit=function(_ENV,pos,bullet)
        -- tail? (no jewels)
        if(not jewel) return
        -- avoid reentrancy
        if(touched) return
        make_blood(pos,v_add(bullet.velocity,head.velocity))
        make_jewel(origin,head.velocity)
        -- change sprite (no jewels)
        touched,ent,hit_ttl=true,_entities.worm2,5
        sfx"56"
      end
    },_ENV["_worm_seg_template"..i] or _worm_seg_template)))
  end

  local function make_dirt(_ENV)
    make_blood(v_add(origin,{1-rnd(),1,1-rnd()},8),{0,3*rnd(),0})
  end

  head=make_skull(inherit({
    die=function(_ENV)
      sfx"-1"
      music"54"
      -- clean segment
      do_async(function()
        while #segments>0 do
          local _ENV=deli(segments,1)
          grid_unregister(_ENV)
          dead=true
          make_blood(origin,{0,0,0})
          wait_async(3)
        end
      end)
    end,
    init=function(_ENV)
      ai=do_async(function()
        target=v_clone(_origin,96)
        wait_async(60)
    
        for i=1,6 do
          local a,r=atan2(origin[1],origin[3])+rnd"0.05",96+rnd"32"
          target={512+r*cos(a),16+rnd"48",512-r*sin(a)}
          wait_async(60+rnd"10")
          target=v_clone(_plyr.eye_pos)
          wait_async(60)
        end
    
        target=v_clone(_plyr.eye_pos,128)
        wait_async(90)
        -- go away
        target=v_clone(_plyr.eye_pos,-96)
        wait_async(90)
        _total_things-=10
        -- wait until all segments are underground
        while true do
          for _ENV in all(segments) do
            if origin[2]>0 then
              goto above_ground
            else
              dead=true
              grid_unregister(_ENV)
            end
          end
          break
    ::above_ground::
          yield()
        end
        dead=true
        grid_unregister(_ENV)
      end)
    end,
    think=function(_ENV)
      -- call parent
      _skull_core.think(_ENV)
      -- make body wobbles
      forces=v_add(forces,{0,4*cos(time()/4+seed),0})
      -- record last y
      prev_y=origin[2]
    end,
    post_think=function(_ENV)
      local curr_y,dirt=origin[2]
      if sgn(curr_y)!=sgn(prev_y) then
        make_dirt(_ENV)
        dirt=true
      end
      prev_y=curr_y
      add(prev,{v_clone(origin),zangle,yangle,dirt},1)
      if(#prev>20*seg_delta) deli(prev)
      for i=1,#prev,seg_delta do
        local _ENV,dirt=segments[i\seg_delta+1]
        -- can happen when centipede is dying
        if _ENV then
          origin,zangle,yangle,dirt=unpack(prev[i])
          grid_register(_ENV)          
          if(dirt) make_dirt(_ENV)
        end
      end
    end
  },_worm_head_template),_origin)
end

function make_jewel(_origin,_velocity)
  add(_things,inherit({    
    origin=v_clone(_origin),
    velocity=v_clone(_velocity),
    pickup=function(_ENV,spider)
      if(dead) return
      dead=true
      grid_unregister(_ENV)
      -- no feedback when gobbed by spider
      if(spider) return
      _total_jewels+=1 
      sfx"57"      
    end,
    update=function(_ENV)
      ttl-=1
      -- blink when going to disapear
      if ttl<30 then
        no_render=(ttl%2)==0
      end
      if ttl<0 then
        dead=true
        return
      end
      -- friction
      if on_ground then
        velocity[1]*=0.9
        velocity[3]*=0.9
      end
      -- gravity
      velocity[2]-=0.8

      -- pulled by player or spiders?
      local force,min_dist,min_dir,min_other=_plyr.attract_power,32000,{0,0,0},_plyr
      for other,other_origin in pairs(_spiders) do
        local dist_dir,dist=v_dir(origin,other_origin)
        if(dist<min_dist) force,min_dir,min_dist,min_other=2,dist_dir,dist,other
      end
      -- anyone stil alive?
      if not min_other.dead and force!=0 then
        -- update dist if invalid
        if(min_dist==32000) min_dir,min_dist=v_dir(origin,min_other.origin)
        -- boost repulsive force
        if(force<0) force*=8
        velocity=v_add(velocity,min_dir,3*force/mid(min_dist,1,5))
        -- limit x/z velocity
        local vn,vl=v_normz(velocity)
        velocity[1]*=3/vl
        velocity[3]*=3/vl
      end
      origin=v_add(origin,velocity)
      on_ground=nil
      -- on ground?
      if origin[2]<8 then
        origin[2]=8
        velocity[2]=0
        on_ground=true
      end
      grid_register(_ENV)
    end
  },_jewel_template))
end

function make_egg(_origin,_velocity)
  -- spider spawn time
  local ttl=300+rnd"10"
  make_skull(inherit({
    think=function(_ENV)
      -- gravity
      _velocity[2]-=0.8
      forces=v_add(forces,_velocity,8)
      _velocity[1]=0
      _velocity[3]=0
    end,
    post_think=function(_ENV)
      ttl-=1
      if ttl<0 then
        dead=true
        sfx(51)
        grid_unregister(_ENV)
        make_goo(origin)
        -- spiderling
        make_skull(inherit({
          think=function(_ENV)
            -- navigate to target (direct)
            local dir=v_dir(origin,_plyr.origin)
            forces=v_add(forces,dir,8)
            -- ensure spiderlings don't walk on air!
            local avoid,avoid_dist=v_dir(origin,{512,0,512})
            if avoid_dist>96 then
              forces=v_add(forces,avoid,8*avoid_dist/96)
            end
            forces[2]=0
          end
        },_spiderling_template),origin)
        return
      end
    end
  },_egg_template),_origin)
end

-- draw game world
local _hand_y=0
function draw_world()
  cls()

  -- draw mini bsp
  _bsp[0](_cam)

  -- tilt!
  -- screen = gfx
  -- reset palette
  
  local yshift=sin(_cam.tilt)>>3
  memcpy(0xa380,0x6000,0x2000)
  for i=0,63,4 do
    -- 0xbc80 = 0x6000-0xa380
    -- offset = dst -  src
    local off=((((i-31.5)*yshift+0.5)\1)<<6)+0xbc80
    -- copy from y=4 to y=123 
    for src=0xa480+i,0xc240+i,64 do
      poke4(src+off,$src)
    end
  end

  -- hide trick top/bottom 8 pixel rows :)
  memset(0x6000,0,512)
  memset(0x7e00,0,512)

  --[[
  local stats={
    BULLETS=_bullets,
    PARTICLE=_particles,
    THINGS=_things,
    FUTURES=_futures
  }
  local s=""
  for k,v in pairs(stats) do
    s..=k.."# "..#v.."\n"
  end
  print(s..stat(0).."kb",2,2,3)
  ]]

  -- draw player hand (unless player is dead)
  _hand_y=lerp(_hand_y,_plyr.dead and 127 or abs(_plyr.xz_vel*cos(time()/2)*4),0.2)
  -- using poke to avoid true/false for palt
  split2d(scanf([[pal
poke;0x5f0f;0x1f
poke;0x5f00;0x0
clip;0;8;128;112
camera;0;$]],-_hand_y),exec)
  if _plyr.fire_ttl==0 then
    sspr(72,32,64,64,72,64)
  else          
    local r=24+rnd"8"
    split2d(scanf([[poke;0x5f00;0x10
fillp;0xc5a5.8
circfill;96;96;$;8
fillp
circfill;96;96;$;7
circ;96;96;$;9
poke;0x5f00;0x0
sspr;0;64;64;64;72;64]],r,0.9*r,0.9*r),exec)
  end
  clip()
  camera() 

end


-- script commands
function random_spawn_angle() _spawn_angle=rnd() end
function inc_spawn_angle(inc) _spawn_angle+=inc end
function set_spawn(dist,height)       
  _spawn_origin={512+dist*cos(_spawn_angle),height or 0,512-dist*sin(_spawn_angle)}
end

-- gameplay state
function play_state()
  -- clean up stains!
  split2d([[_map_display;1
memcpy;0;0xc500;2048
memcpy;2048;0xc500;2048
memcpy;4096;0xc500;2048
memcpy;6144;0xc500;2048
_map_display;0]],exec)

  -- camera & player & reset misc values
  _plyr,_things,_spiders,_total_jewels,_total_bullets,_total_hits=make_player({512,24,512},0),{},{},0,0,0
  
  -- spatial partitioning grid
  _grid=setmetatable({},{
      __index=function(self,k)
        -- automatic creation of buckets
        -- + array to store things at cell
        local t={
          things={},
          chatter=setmetatable({},{       
            __index=function(self,k)
              self[k]=0
              return 0
            end
          })
        }
        self[k]=t
        return t
      end
    })    

  return
    -- update
    function()
      _plyr:control()
      
      _cam:track(_plyr.eye_pos,_plyr.m,_plyr.angle,_plyr.tilt)
    end,
    -- draw
    function()
      draw_world()   

      -- print(((stat(1)*1000)\10).."%\n"..flr(stat(0)).."KB",2,2,3)
      local s=_total_things.."/60 ⧗:".._time_penalty.."S"
      print(s,64-print(s,0,128)/2,2,7)

      if _show_timer then
        local t=((time()-_start_time)\0.1)/10
        local s=tostr(t)
        if(#tostr(t&0x0.ffff)==1) s..=".0"
        s..="S"
        arizona_print(s,64-print(s,0,128)/2,1,2)
      end

      -- hw palette
      memcpy(0x5f10,0x8000+_hw_pal,16)

      --[[
      palt(0,true)
      local function world_to_map(o)
        return (4*o[1])\32,(4*o[3])\32
      end

      for x=0,31 do
        for y=0,31 do
          local idx,count=x>>16|y,0
          for _ in pairs(_grid[idx].things) do
            count+=1
          end
          rectfill(x*4,y*4,(x+1)*4-1,(y+1)*4-1,count%16)
          for thing in pairs(_grid[idx].things) do
            local x0,y0=world_to_map(thing.origin)
            pset(x0,y0,8)
            if thing.target then
              local x1,y1=world_to_map(thing.target)
              line(x0,y0,x1,y1,5)
            end
          end
        end
      end
      local x0,y0=world_to_map(_plyr.origin)
      spr(7,x0-2,y0-2)      
      local x0,y0=world_to_map(_flying_target)
      spr(23,x0-2,y0-2)
      ]]

      --_map_display(1)
      --spr(0,0,0,16,16)
    end,
    -- init
    function()
      sfx"-1"
      music"32"
      _start_time=time()
      -- must be done *outside* async update loop!!!
      _futures,_total_things,_time_penalty,_time_wait={},0,0
      -- scenario
      local scenario=do_async(function()
        local script=split2d([[
--;wait player
wait_async;15
--;first squids wave
random_spawn_angle
set_spawn;200
wait_async;330
make_squid;2
wait_async;330
inc_spawn_angle;0.25
set_spawn;200
make_squid;1
wait_async;150
inc_spawn_angle;0.25
set_spawn;200
make_squid;1
wait_async;150
inc_spawn_angle;0.25
set_spawn;200
make_squid;1
wait_async;450
inc_spawn_angle;0.25
set_spawn;200
make_squid;2
--;first spider
random_spawn_angle
set_spawn;200;78
make_spider
--; second squid wave
wait_async;300
random_spawn_angle
set_spawn;200
make_squid;1
random_spawn_angle
inc_spawn_angle;0.5
set_spawn;200
make_squid;2
wait_async;450
inc_spawn_angle;-0.25
set_spawn;200
make_squid;1
inc_spawn_angle;0.5
set_spawn;200
make_squid;2
wait_async;450
inc_spawn_angle;0.5
set_spawn;200
make_squid;1
wait_async;150
inc_spawn_angle;0.5
set_spawn;200
make_squid;2
inc_spawn_angle;0.25
set_spawn;200
make_squid;1
wait_async;150
--; first centipede
random_spawn_angle
set_spawn;200;64
make_worm
wait_async;600]],exec) 
    end)

    --[[
    do_async(function()
      while true do
        --local s=make_skull(rnd{_skull1_template,_skull2_template},{512,8+rnd(4),530})
        make_egg({512,24,530},{8*cos(time()/4),0,8*sin(time()/4)})
        --s.update=nop
        wait_async(3)
        for i=0,9 do
        --  make_bullet({400,10,530},0.25,0,0.01)
          wait_async(2)
        end
        wait_async(60)
        if(s) s.dead=true
      end
    end)
    for i=-4,5 do
      for j=-4,5 do
        local s=make_skull(_skull1_template,{512+i*16,12+rnd(4),512+j*16})
        s.update=nop
      end
    end
    ]]       
    -- progression
    do_async(function()
      -- reset values
      _fire_ttl,_shotgun_count,_shotgun_spread=3,10,0.025
      -- level 1
      wait_jewels(10)
      _shotgun_count,_shotgun_spread=20,0.033
      levelup_async(3)
      
      -- level 2
      wait_jewels(70)
      _fire_ttl=2
      levelup_async(5)

      -- level 3
      wait_jewels(150)
      levelup_async(7)
    end)

    do_async(function()
        -- skull 1+2 circle around player
        while not _plyr.dead do      
          local angle,x,y,z=time()/8,unpack(_plyr.origin)
          local r=48*cos(angle)
          _skull_base_template.target={x+r*cos(angle),y+10+rnd"4",z+r*sin(angle)}
          wait_async(10)
        end

        -- if player dead, find a random spot on map
        -- stop creating monsters
        scenario.co=nil
        while true do
          _skull_base_template.target={256+rnd"512",12+rnd"64",256+rnd"512"}
          wait_async(45+rnd"15")
        end
      end)
    end   
end

function gameover_state(obituary)  
  -- remove time spent "waiting"!!
  local hw_pal,play_time,origin,target,selected_tab,clicked=0,time()-_start_time-_time_penalty,_plyr.eye_pos,v_add(_plyr.origin,{0,4,0})
  -- check if new playtime enters leaderboard?
  -- + handle sorting
  local new_best_i=#_local_scores+1
  for i,local_score in ipairs(_local_scores) do
    if play_time>local_score[1] then
      new_best_i=i
      break
    end
  end
  -- record time of play
  add(_local_scores,{play_time,stat(90),stat(91),stat(92)},new_best_i)
  -- max #scores
  if(#_local_scores>5) deli(_local_scores)
  -- save version
  dset(0,1)
  -- number of scores
  dset(1,#_local_scores)
  local mem=0x5e08
  for local_score in all(_local_scores) do
    -- save
    poke4(mem,unpack(local_score))
    -- next 4 * 4bytes
    mem+=16
  end

  -- leaderboard/retry
  local ttl,buttons,over_btn=90,{
    {"rETRY",1,111,cb=function() 
      do_async(function()
        for i=0,15 do
          hw_pal=i<<4
          yield()
        end
        next_state(play_state)
      end)
    end},
    {"sTATS",1,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        -- before: 7618
        local x=1
        split2d(scanf([[⧗ ;_;30;3
$S    ;x;30;0
🐱 ;x;30;3
$;x;30;0
◆ ;_;38;3
$;x;38;0
    ● ;x;38;3
$;x;38;0
    ☉ ;x;38;3
$%;x;38;0]],play_time,obituary,_total_jewels,tostr(_total_bullets,2),flr(_total_bullets==0 and 0 or 1000*(_total_hits/_total_bullets))/10),function(s,_,y,sel)
          -- new line?
          if(_=="_") x=1
          x=arizona_print(s,x,y,sel)
        end)
      end
    },
    {"lOCAL",46,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        for i,local_score in ipairs(_local_scores) do
          local t,y,m,d=unpack(local_score)
          arizona_print(scanf("$.\t$/$/$\t $S",i,y,m,d,t),1,23+i*7,new_best_i==i and 4)
        end
      end},
    {"oNLINE",96,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        arizona_print("tO BE ANNOUNCED...",1,30)
      end
    }
  }
  -- default (stats)
  selected_tab=buttons[2]
  -- get actual size
  for _,btn in pairs(buttons) do
    btn.width=print(btn[1],0,130)
  end
  -- position cursor on retry
  local _,x,y=unpack(buttons[1])
  local mx,my=x+buttons[1].width/2,y+3
  -- death music
  sfx"-1"
  music"36"
  return
    -- update
    function()
      ttl=max(ttl-1)
      origin=v_lerp(origin,target,0.2)
      _cam:track(origin,_plyr.m,_plyr.angle,_plyr.tilt)
      if ttl==0 then
        mx,my=mid(mx+stat(38)/2,0,127),mid(my+stat(39)/2,0,127)
        -- over button?
        over_btn=-1
        for i,btn in pairs(buttons) do
          local _,x,y=unpack(btn)          
          if mx>=x and my>=y and mx<=x+btn.width and my<=y+6 then            
            over_btn=i
            -- click?
            if not clicked and btnp(5) then
              -- avoid reentrancy
              clicked=true
              btn:cb()
            end
            break
          end
        end
      end
    end,
    -- draw
    function()
      draw_world()
      if ttl==0 then
        split2d([[palt;0;false
poke;0x5f54;0x60
memcpy;0x5f00;0x8090;16
spr;0;0;0;16;16
pal
poke;0x5f54;0x00
arizona_print;hIGHSCORES;1;8]],exec)
        -- darken game screen
        -- shift palette
        -- copy in place
        -- reset

        -- draw menu & all
        
        for i,btn in pairs(buttons) do
          local s,x,y=unpack(btn)
          arizona_print(s,x,y,selected_tab==btn and 2 or i==over_btn and 1)
        end
        split2d([[1;24;126;24;4
1;25;126;25;2
1;109;126;109;2
1;108;126;108;4]],line)

        selected_tab:draw()

        -- mouse cursor
        spr(20,mx,my)
      end
      -- hw palette
      memcpy(0x5f10,0x8000+hw_pal,16)
      -- pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

-- pico8 entry points
function _init()
  -- enable custom font
  -- enable tile 0 + extended memory
  -- capture mouse
  -- enable lock
  -- increase tline precision
  -- cartdata
  -- use "screen" as spritesheet source
  -- copy tiles to spritesheet 1
  -- todo: put back tline precision
  split2d([[poke;0x5f58;0x81
poke;0x5f36;9
poke;0x5f2d;0x7
poke;0x5f54;0x60;0x00
memcpy;0x0;0x6000;0x2000
_map_display;1
memcpy;0;0xc500;2048
memcpy;2048;0xc500;2048
memcpy;4096;0xc500;2048
memcpy;6144;0xc500;2048
_map_display;0
cartdata;freds72_daggers]],exec)

  -- local score version
  _local_scores,_local_best_t={}
  if dget(0)==1 then
    -- number of scores    
    local mem=0x5e08
    for i=1,dget(1) do
      -- duration (sec)
      -- timestamp yyyy,mm,dd
      add(_local_scores,{peek4(mem,4)})
      mem+=16
    end    
    _local_best_t=_local_scores[1][1]
  end

  -- exit menu entry
  menuitem(1,"main menu",function()
    -- local version
    load"title.p8"
    -- bbs version
    load"#freds72_daggers_title"
  end)

  menuitem(2,"timer on/off",function()
    _show_timer=not _show_timer
  end)

  -- always needed  
  _cam=inherit{
    origin=split"0,0,0",    
    track=function(_ENV,_origin,_m,_angles,_tilt)
      --
      tilt=_tilt or 0
      m={unpack(_m)}		

      -- inverse view matrix
      m[2],m[5]= m[5], m[2]
      m[3],m[9]= m[9], m[3]
      m[7],m[10]=m[10],m[7]
      
      origin=_origin
      angles=_angles
    end}
    
    -- mini bsp:
    --              0
    --             / \
    --           -1   grid
    --           / \
    --       brush  -2
    --             /   \ 
    --          brush  brush
    split2d([[0;2;0;-1;grid
-1;1;384.0;1;-2
-2;1;640.0;2;3]],function(id,plane_id,plane,left,right)
      _bsp[id]=function(cam)
        local l,r=_bsp[left],_bsp[right]                
        if(cam.origin[plane_id]<=plane) l,r=r,l
        l(cam)
        r(cam)
      end
    end)
    -- layout:
    -- #1: brush id (bsp node id)
    -- repeat:
    -- ##0: cp coord (!!signed!!)
    -- ##1: cp value (!!signed!!)
    -- ##2: u index
    -- ##3: v index
    -- ##4: vertex index
    -- ##5: vertex index
    -- ##6: vertex index
    -- ##7: vertex index
    -- ##8: tex coords
    split2d([[1; 2;0.0;0;2;13;16;19;22;0x0000.1010;1; -2;32.0;0;2;58;55;52;49;0x0014.0404;0; -3;-384.0;0;1;13;22;58;49;0x0010.0404;0; 3;640.0;0;1;19;16;52;55;0x0010.0404;0; -1;-320.0;2;1;49;52;16;13;0x0010.0404;0
2; 2;0.0;0;2;1;4;7;10;0x0000.1010;1; -2;32.0;0;2;46;43;40;37;0x0014.0404;0; -3;-320.0;0;1;1;10;46;37;0x0010.0404;0; 3;704.0;0;1;7;4;40;43;0x0010.0404;0; -1;-384.0;2;1;22;1;37;58;0x0010.0404;0; -1;-384.0;2;1;4;19;55;40;0x0010.0404;0; 1;640.0;2;1;28;7;43;64;0x0010.0404;0; 1;640.0;2;1;10;25;61;46;0x0010.0404;0
3; 2;0.0;0;2;25;28;31;34;0x0000.1010;1; -2;32.0;0;2;70;67;64;61;0x0014.0404;0; -3;-384.0;0;1;25;34;70;61;0x0010.0404;0; 1;704.0;2;1;70;34;31;67;0x0010.0404;0; 3;640.0;0;1;31;28;64;67;0x0010.0404;0
]],function(id,...)
      -- localize
      local planes={...}
      _bsp[id]=function(cam)        
        local m,origin,cx,cy,cz=cam.m,cam.origin,unpack(cam.origin)
        local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]
        -- all brush planes
        for i=1,#planes,10 do
          -- visible?
          local dir=planes[i]
          if sgn(dir)*origin[abs(dir)]>planes[i+1] then              
            local verts,uindex,vindex,outcode,nearclip={},planes[i+2],planes[i+3],0xffff,0  
            for j=1,4 do
              local vi=planes[i+j+3]
              local code,x,y,z=2,_vertices[vi]-cx,_vertices[vi+1]-cy,_vertices[vi+2]-cz
              local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
              if(az>4) code=0
              if(az>192) code|=1
              if(-0.5*ax>az) code|=4
              if(0.5*ax>az) code|=8
              
              local w=32/az 
              verts[j]={ax,ay,az,u=(_vertices[vi+uindex]-320)*0x0.0aaa,v=(_vertices[vi+vindex]-320)*0x0.0aaa,x=63.5+ax*w,y=63.5-ay*w,w=w}
              
              outcode&=code
              nearclip+=code&2
            end
            -- out of screen?
            if outcode==0 then
              if nearclip!=0 then                
                -- near clipping required?
                local res,v0={},verts[#verts]
                local d0=v0[3]-1
                for i,v1 in inext,verts do
                  local side=d0>0
                  if(side) res[#res+1]=v0
                  local d1=v1[3]-1
                  if (d1>0)!=side then
                    -- clip!
                    local t=d0/(d0-d1)
                    local v=v_lerp(v0,v1,t)
                    -- project
                    -- z is clipped to near plane
                    v.x=63.5+(v[1]<<5)
                    v.y=63.5-(v[2]<<5)
                    v.w=32 -- 32/1
                    v.u=lerp(v0.u,v1.u,t)
                    v.v=lerp(v0.v,v1.v,t)
                    res[#res+1]=v
                  end
                  v0,d0=v1,d1
                end
                verts=res
              end
    
              -- texture
              poke4(0x5f38,planes[i+8])
              _map_display(planes[i+9])
              --[[
              color(1)
              local v0=verts[#verts]
              for i=1,#verts do
                local v1=verts[i]
                line(v0.x,v0.y,v1.x,v1.y)
                v0=v1
              end 
              ]]
              mode7(verts,#verts,_ramp_pal+0x1100)  
              --[[
              local mx,my=0,0
              for _,v in inext,verts do
                mx+=v.x
                my+=v.y
              end
              print(id.." / "..((i\9)+1),mx/#verts,my/#verts,8)
              ]]
            end
          end
        end
        _map_display(0)
      end
    end)
  -- attach world draw as a named BSP node
  _bsp.grid=draw_grid
  
  -- load images
  _entities=decompress("pic",0,0,unpack_entities)
  reload()

  -- must be globals
  -- predefined entries (avoids constant gc)
  _blood_ents,_goo_ents,_spark_ents={
    _entities.blood1
  },{
    _entities.goo0,
    _entities.goo1,
    _entities.goo2
  },{
    _entities.spark1,
    _entities.spark2
  }

  _skull_core=inherit({
    hit=function(_ENV,pos,bullet)
      -- avoid reentrancy
      if(dead) return
      hp-=1
      if hp<=0 then
        dead=true
        -- free a spawn slot
        _total_things-=cost or 0
        -- custom death function?
        if die then
          die(_ENV)
        else
          sfx(death_sfx or 52)
        end
        -- drop jewel?
        if jewel then
          make_jewel(origin,velocity)
        end 
        grid_unregister(_ENV)  
        -- custom explosion?
        if blast then
          blast(pos)
        else
          for i=1,3+rnd"2" do
            local vel=vector_in_cone(0.25-bullet.zangle,0,0.2)
            vel[2]=rnd()
            make_particle(rnd()<gibs and _gib_template or _lgib_template,origin,v_scale(vel,1+rnd"2"))
          end
          local vel=vector_in_cone(0.25-bullet.zangle,0,0.01)
          make_particle(_lgib_template,pos,v_scale(vel,-0.5))
        end
      else
        hit_ttl=5
      end
    end,
    apply=function(_ENV,other,force,t)
      if not apply_filter or other[apply_filter] then
        forces[1]+=t*force[1]
        forces[2]+=t*force[2]
        forces[3]+=t*force[3]
      end
      resolved[other]=true
    end,
    -- default think
    think=function(_ENV)
      yangle=lerp(yangle,target_yangle,0.4)
      -- converge toward player
      if target then
        local dir=v_dir(origin,target)
        forces=v_add(forces,dir,seed)--,8+seed*cos(time()/5))
      end
      -- move head up/down
      yangle-=mid(forces[2]/(2*seed),-0.25,0.25)      
    end,
    update=function(_ENV)
      -- some friction
      velocity=v_scale(velocity,0.8)

      -- custom think function
      think(_ENV)

      -- makes the boids behavior a lot more "natural" + saves cpu
      if rnd()>0.25 then
        -- avoid others (noted: limited to a single grid cell)
        -- 21 = (x\32)>>16
        local idx,fx,fy,fz=origin[1]>>21|origin[3]\32,unpack(forces)
        for other in pairs(_grid[idx].things) do
          -- apply inverse force to other (and keep track)
          if not resolved[other] and other!=_ENV then
            local avoid,avoid_dist=v_dir(origin,other.origin)
            if(avoid_dist<4) avoid_dist=1
            -- 4: good separation
            local t=-4/avoid_dist
            local t_self=other.radius*t 
            fx+=t_self*avoid[1]
            fy+=t_self*avoid[2]
            fz+=t_self*avoid[3]
            
            other:apply(_ENV,avoid,-t*radius)
            resolved[other]=true
          end
        end
        forces={fx,fy,fz}

        -- 
        velocity=v_add(velocity,forces,1/16)      
      end

      -- fixed velocity (on x/z)
      if min_velocity>0 then
        local vx,vz=velocity[1],velocity[3]
        local a=atan2(vx,vz)
        local vlen=vx*cos(a)+vz*sin(a)
        velocity[1]*=min_velocity/vlen
        velocity[3]*=min_velocity/vlen      
      end

      -- align direction and sprite direction
      local target_angle=atan2(-velocity[1],velocity[3])
      zangle=lerp(shortest_angle(target_angle,zangle),target_angle,0.2)
      
      -- move & clamp
      origin[1]=mid(origin[1]+velocity[1],0,1024)
      local oy=origin[2]+velocity[2]
      if oy<ground_limit then
        oy=ground_limit
        --yangle+=rnd(1)
      end

      origin[2]=oy
      origin[3]=mid(origin[3]+velocity[3],0,1024)

      -- for centipede
      if(post_think) post_think(_ENV)

      -- reset
      forces,resolved={0,0,0},{}
      grid_register(_ENV)
    end
  })

  -- global templates
  local templates=[[_gib_template;radius,4,zangle,0,yangle,0,ttl,0,scale,1,trail,_gib_trail,ent,blood0,rebound,-1
_lgib_template;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,trail,_gib_trail,ent,blood1,rebound,-1
_gib_trail;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,ent,blood1,rebound,0,@ents,_blood_ents,stain,5
_dagger_hit_template;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,ent,spark1,@ents,_spark_ents,rebound,-1
_skull_template;zangle,0,yangle,0,hit_ttl,0,forces,v_zero,velocity,v_zero,min_velocity,3,chatter,12,ground_limit,4,target_yangle,0,gibs,-1;_skull_core
_egg_template;ent,egg,radius,8,hp,2,zangle,0,@apply,nop,@blast,make_goo,obituary,aCIDIFIED,min_velocity,-1;_skull_template
_goo_gib_template;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,ent,goo0,@ents,_goo_ents
_worm_seg_template;ent,worm1,radius,8,zangle,0,origin,v_zero,@apply,nop,spawnsfx,42,obituary,wORMED,scale,1.5,jewel,1
_worm_seg_template19;ent,worm2,radius,8,zangle,0,origin,v_zero,@apply,nop,obituary,wORMED,scale,1.2
_worm_seg_template20;ent,worm2,radius,8,zangle,0,origin,v_zero,@apply,nop,obituary,wORMED,scale,0.8
_worm_head_template;ent,worm0,radius,12,hp,10,chatter,20,obituary,wORMED,ground_limit,-64,cost,10,gibs,0.5;_skull_template
_jewel_template;ent,jewel,radius,12,zangle,0,ttl,300,@apply,nop,is_jewel,1
_spiderling_template;ent,spiderling0,radius,16,friction,0.5,hp,2,on_ground,1,death_sfx,53,chatter,16,spawnsfx,41,obituary,wEBBED,@blast,make_goo,apply_filter,on_ground;_skull_template
_squid_core;no_render,1,radius,24,origin,v_zero,on_ground,1,is_squid_core,1,min_velocity,0.2,chatter,8,@hit,nop,cost,5,obituary,nAILED,gibs,0.8,apply_filter,is_squid_core;_skull_template
_squid_hood;ent,squid2,radius,12,origin,v_zero,zangle,0,@apply,nop,obituary,nAILED,shadeless,1,o_offset,12
_squid_jewel;jewel,1,hp,10,ent,squid1,radius,8,origin,v_zero,zangle,0,@apply,nop,obituary,nAILED,shadeless,1,o_offset,12
_squid_tentacle;ent,tentacle0,radius,16,origin,v_zero,zangle,0,is_tentacle,1
_skull_base_template;;_skull_template
_skull1_template;ent,skull,radius,8,hp,2,cost,1,obituary,sKULLED,target_yangle,0.1;_skull_base_template
_skull2_template;ent,reaper,radius,10,hp,5,target_ttl,0,jewel,1,cost,1,obituary,iMPALED,min_velocity,3.5,gibs,0.2;_skull_base_template
_spider_template;ent,spider1,radius,16,shadeless,1,hp,25,zangle,0,yangle,0,scale,1.5,@apply,nop,cost,1]]
  split2d(templates,function(name,template,parent)
    _ENV[name]=inherit(with_properties(template),_ENV[parent])
  end)

  -- run game
  next_state(play_state)
end

-- collect all grids touched by (a,b) vector
function collect_grid(a,b,u,v,cb)
  local mapx,mapy=a[1]\32,a[3]\32
  -- check first cell (always)
  local dest_idx,map_idx=b[3]\32|b[1]\32>>16,mapy|mapx>>16
  cb(_grid[map_idx].things)
  -- early exit
  if dest_idx==map_idx then    
    return
  end

  local ddx,ddy,distx,disty,mapdx,mapdy=abs(1/u),abs(1/v)
  if u<0 then
    -- -1>>16
    mapdx,distx=0xffff.ffff,(a[1]/32-mapx)*ddx
  else
    -- 1>>16
    mapdx,distx=0x0.0001,(mapx+1-a[1]/32)*ddx
  end
  
  if v<0 then
    mapdy,disty=-1,(a[3]/32-mapy)*ddy
  else
    mapdy,disty=1,(mapy+1-a[3]/32)*ddy
  end
  while dest_idx!=map_idx do
    -- printh(mapx.."/"..mapy.." -> "..dest_mapx.."/"..dest_mapy.." ["..mapdx.." "..mapdy.."]")
    if distx<disty then
      distx+=ddx
      map_idx+=mapdx
    else
      disty+=ddy
      map_idx+=mapdy
    end
    cb(_grid[map_idx].things)
  end
end

function _update()
  -- any futures?
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
  
  _plyr:update()
  --
  if _slow_mo%2==0 then
    -- draw on tiles setup
    split2d([[_map_display;1
poke;0x5f54;0x00;0x60
poke;0x5f5e;0b11110110]],exec)  
    -- physic must run *before* general updates
    for _,_ENV in inext,_things do
      if(physic) physic(_ENV)
    end
    for i=#_things,1,-1 do
      local _ENV=_things[i]
      if dead then
        -- kill ai coroutine (if any)
        if(ai) ai.co=nil
        -- note: assumes thing is already unregistered
        deli(_things,i)
      else
        -- common timers
        if(hit_ttl) hit_ttl=max(hit_ttl-1)
        if(update) update(_ENV)
      end
    end
    -- revert
    split2d([[poke;0x5f5e;0xff
poke;0x5f54;0x60;0x00
_map_display;0]],exec)
  end

  _update_state()
end

-- unpack assets
function unpack_entities()
  local entities,names={},split"skull,reaper,blood0,blood1,blood2,dagger0,dagger1,dagger2,hand0,hand1,hand2,goo0,goo1,goo2,egg,spiderling0,spiderling1,worm0,worm1,jewel,worm2,tentacle0,tentacle1,squid0,squid1,squid2,spider0,spider1,spark0,spark1,spark2"
  unpack_array(function()
    local id=mpeek()
    if id!=0 then
      local sprites,angles={},mpeek()
      entities[names[id]]={  
        sprites=sprites,   
        yangles=angles&0xf,
        zangles=angles\16,        
        frames=unpack_frames(sprites)
      }
    end
  end)
  return entities
end
