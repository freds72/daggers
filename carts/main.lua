local _plyr,_cam,_things,_grid,_futures
local _entities,_particles,_bullets,_blood_ents,_goo_ents
-- stats
local _total_jewels,_total_bullets,_total_hits,_start_time=0,0,0

-- debug
local _god_mode=true

local _ground={
  -- middle chunk
  {
    n={0,1,0},
    split"256,0,192",
    split"256,0,832",
    split"768,0,832",
    split"768,0,192"
  },
  -- left
  {
    n={0,1,0},
    split"192,0,256",
    split"192,0,768",
    split"256,0,768",
    split"256,0,256"
  },
  -- right
  {
    n={0,1,0},
    split"768,0,256",
    split"768,0,768",
    split"832,0,768",
    split"832,0,256"
  }
}
local _sides={
  {
    n={-1,0,0},
    split"256,0,256",
    split"256,0,192",
    split"256,-32,192",
    split"256,-32,256",
  },
  {
    n={1,0,0},
    split"768,0,192",
    split"768,0,256",
    split"768,-32,256",
    split"768,-32,192",
  },
  {
    n={-1,0,0},
    split"256,0,832",
    split"256,0,768",
    split"256,-32,768",
    split"256,-32,832",
  },
  {
    n={1,0,0},
    split"768,0,768",
    split"768,0,832",
    split"768,-32,832",
    split"768,-32,768",
  },
  {
    n={0,0,1},
    split"768,0,832",
    split"256,0,832",
    split"256,-32,832",
    split"768,-32,832",
  },
  {
    n={0,0,-1},
    split"256,0,192",
    split"768,0,192",
    split"768,-32,192",
    split"256,-32,192",
  },
  -- ears (left)
  {
    n={-1,0,0},
    split"192,0,768",
    split"192,0,256",
    split"192,-32,256",
    split"192,-32,768",
  },
  {
    n={0,0,1},
    split"256,0,768",
    split"192,0,768",
    split"192,-32,768",
    split"256,-32,768",
  },
  {
    n={0,0,-1},
    split"192,0,256",
    split"256,0,256",
    split"256,-32,256",
    split"192,-32,256",
  },
  -- ears (right)
  {
    n={1,0,0},
    split"832,0,256",
    split"832,0,768",
    split"832,-32,768",
    split"832,-32,256",
  },
  {
    n={0,0,1},
    split"832,0,768",
    split"768,0,768",
    split"768,-32,768",
    split"832,-32,768",
  },
  {
    n={0,0,-1},
    split"768,0,256",
    split"832,0,256",
    split"832,-32,256",
    split"768,-32,256",
  }  
}
  
local _ground_extents={
  split"256,768,192,832",
  split"192,256,256,768",
  split"768,832,256,768"
}

function nop() end
function with_properties(props,dst)
  dst=dst or {}
  local props=split(props)
  for i=1,#props,2 do
    local k,v=props[i],props[i+1]
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    -- note: assumes that function never returns a falsey value
    if v=="nop" then v=nop
    elseif k=="ent" then 
      v=_entities[v] 
    else
      local fn=_ENV[v]
      v=type(fn)=="function" and fn() or v 
    end
    dst[k]=v
  end
  return dst
end

-- split a 2d table:
-- each line is \n separated
-- section in ; separated
function split2d(config,cb)
  for line in all(split(config,"\n")) do
    cb(unpack(split(line,";")))
  end
end

-- grid helpers
function world_to_grid(p)
  return (p[1]\32)>>16|(p[3]\32)
end

-- adds thing in the collision grid
function grid_register(thing)
  local grid,_ENV=_grid,thing
  -- need half-radius
  local r,x,z=radius>>1,origin[1],origin[3]
  -- \32(=5) + >>16
  local x0,x1,z0,z1=(x-r)>>21,(x+r)>>21,(z-r)\32,(z+r)\32
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
    -- cache grid coords
    grid_x0=x0
    grid_x1=x1
    grid_z0=z0
    grid_z1=z1

    -- noise emitter?
    if chatter then
      -- \64(=6) + >>16
      local cell=grid[x>>22|(z\64)]
      cell.chatter[chatter]+=1
      -- for fast unregister
      chatter_cell=cell
    end
  end
end

-- removes thing from the collision grid
function grid_unregister(_ENV)
  for idx,cell in pairs(cells) do
    cell.things[_ENV]=nil
    cells[idx]=nil
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
local _chatter_ranges={
  split"0x0000.0000,0x0001.0000,0x0000.0001,0x0001.0001",
  split"0x0000.0000,0x0001.0000,0x0002.0000,0x0003.0000,0x0000.0001,0x0003.0001,0x0000.0002,0x0003.0002,0x0000.0003,0x0001.0003,0x0002.0003,0x0003.0003",
  split"0x0001.0000,0x0002.0000,0x0003.0000,0x0004.0000,0x0000.0001,0x0005.0001,0x0000.0002,0x0005.0002,0x0000.0003,0x0005.0003,0x0000.0004,0x0005.0004,0x0001.0005,0x0002.0005,0x0003.0005,0x0004.0005"
}

function make_player(_origin,_a)
    local angle,on_ground,dead={0,_a,0}
    return inherit(with_properties("tilt,0,radius,24,attract_power,0,dangle,v_zero,velocity,v_zero,fire_ttl,0,fire_released,1,fire_frames,0,dblclick_ttl,0,fire,0",{
      -- start above floor
      origin=v_add(_origin,{0,1,0}), 
      eye_pos=v_add(_origin,{0,25,0}), 
      m=make_m_from_euler(angle),
      control=function(_ENV)
        if(dead) return
        -- move
        local dx,dz,a,jmp=0,0,angle[2],0
        if(btn(0,1)) dx=3
        if(btn(1,1)) dx=-3
        if(btn(2,1)) dz=3
        if(btn(3,1)) dz=-3
        if(on_ground and btnp(4)) jmp=12 on_ground=false

        -- straffing = faster!

        -- restore attrack power
        attract_power=min(attract_power+0.2,1)

        -- double-click detector
        dblclick_ttl=max(dblclick_ttl-1)
        if btn(5) then
          if fire_released then
            fire_released=false
          end
          fire_frames+=1
          -- regular fire      
          if dblclick_ttl==0 and fire_ttl<=0 then
            sfx(48)
            fire_ttl,fire=3,1
          end
          -- 
          attract_power=0
        elseif not fire_released then
          if dblclick_ttl>0  then
            -- double click timer still active?
            fire_ttl,fire=0,2
            dblclick_ttl=0				
            sfx(49)
            -- shotgun (repulsive!)
            attract_power=-1
          elseif fire_frames<4 then
           -- candidate for double click?
           dblclick_ttl=8
          end           
          fire_released,fire_frames=true,0
        end

        dangle=v_add(dangle,{stat(39),stat(38),0})
        tilt+=dx/40
        local c,s=cos(a),-sin(a)
        velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx},0.35)                 
      end,
      update=function(_ENV)
        -- damping      
        dangle=v_scale(dangle,0.6)
        tilt*=0.6
        if(abs(tilt)<=0.0001) tilt=0
        velocity[1]*=0.7
        --velocity[2]*=0.9
        velocity[3]*=0.7
        -- gravity
        velocity[2]-=0.8
        
        -- avoid overflow!
        fire_ttl=max(fire_ttl-1)

        angle=v_add(angle,dangle,1/1024)
  
        -- check next position
        local vn,vl=v_dir({0,0,0},velocity)      
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
              else
                dying=true
              end
            end
            -- use corrected velocity + stays within grid
            origin={mid(x,0,1024),y,mid(z,0,1024)}
            velocity=new_vel
        end

        eye_pos=v_add(origin,{0,24,0})

        -- check collisions
        local x,z=origin[1],origin[3]
        if not dead then   
          local a=atan2(prev_pos[1]-x,prev_pos[3]-z)
          -- 
          collect_grid(prev_pos,origin,cos(a),-sin(a),function(grid_cell)
            -- avoid reentrancy
            if not dead then
              for thing in pairs(grid_cell) do
                if thing!=_ENV and not thing.dead then
                  -- special handling for crawling enemies
                  local dist=v_len(thing.on_ground and origin or eye_pos,thing.origin)
                  -- todo: use thing radius!!
                  if dist<16 then
                    if thing.pickup then
                      thing:pickup()
                    else
                      if not _god_mode then
                        -- avoid reentrancy
                        dead=true
                        next_state(gameover_state,thing.ent.obituary)
                      end
                      break
                    end
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
        -- todo: 
        -- check active noises (channels)

        -- refresh angles
        m=make_m_from_euler(unpack(angle))    

        -- normal fire
        if fire==1 then          
          _total_bullets+=0x0.0001
          make_bullet(v_add(origin,{0,18,0}),angle[2],angle[1],0.02)
        elseif fire==2 then
          -- shotgun
          _total_bullets+=0x0.000a
          local o=v_add(origin,{0,18,0})
          for i=1,10 do
            make_bullet(o,angle[2],angle[1],0.025)
          end
        end
        fire=nil          
      end
    }))
end

function make_bullet(origin,zangle,yangle,spread)
  local zangle,yscale=0.25-zangle+(1-rnd(2))*spread,yangle+(1-rnd(2))*spread
  local u,v,s=cos(zangle),-sin(zangle),cos(yscale)
  -- local o=v_add(origin,v_add(v_scale(m_up(m),1-rnd(2)),m_right(m),1-rnd(2)))
  _bullets[#_bullets+1]={
    origin=v_clone(origin),
    -- must be a unit vector  
    velocity={s*u,sin(yscale),s*v},
    -- fixed zangle
    zangle=zangle,
    yangle=rnd(),
    -- precomputed for collision detection
    u=u,
    v=v,
    shadeless=true,
    ttl=time()+3+rnd(2),
    ent=rnd{_entities.dagger0,_entities.dagger1}
  }
end

function make_particle(origin,fwd)
  _particles[#_particles+1]={
    origin=origin,
    velocity=fwd,
    shadeless=true,
    ttl=time()+0.25+rnd()/5
  }
end

-- transform & clip polygon
function draw_poly(poly,uindex,vindex,light)
    if(v_dot(_cam.origin,poly.n)<=poly.cp) return

    local m,cx,cy,cz=_cam.m,unpack(_cam.origin)
    local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]
    local verts,outcode,nearclip={},0xffff,0  
    -- to cam space + clipping flags
    for i,v0 in ipairs(poly) do
        local code,x,y,z=2,v0[1]-cx,v0[2]-cy,v0[3]-cz
        local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
        if(az>8) code=0
        if(az>384) code|=1
        if(-ax>az) code|=4
        if(ax>az) code|=8
        
        local w=64/az 
        verts[i]={ax,ay,az,u=v0[uindex]>>4,v=v0[vindex]>>4,x=63.5+ax*w,y=63.5-ay*w,w=w}

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
            v.x=63.5+(v[1]<<3)
            v.y=63.5-(v[2]<<3)
            v.w=8 -- 64/8
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
        --[[
        -- light circle
        local d=7+(1/rw)
        if d<64 then
        local xmax=64*sqrt(64-d*d)
        local xmin=64-xmax
        xmax=64+xmax
        --rectfill(-x+64,y,64+x,y,3)
        --]]
        local ddu,ddv=(lu-ru)/(lx-rx),(lv-rv)/(lx-rx)
        local pal1=rw>0.9375 and maxlight or (light*rw)\0.0625
        if(pal0!=pal1) memcpy(0x5f00,0x8000|pal1<<4,16) pal0=pal1	-- color shift now to free up a variable
        -- refresh actual extent
        -- ddx=lx-rx--((lx+0x1.ffff)&-1)-(rx&-1)
        -- ddu,ddv=(lu-ru)/ddx,(lv-rv)/ddx
        local pix=1-rx&0x0.ffff
        tline(rx,y,lx\1-1,y,(ru+pix*ddu)/rw,(rv+pix*ddv)/rw,ddu/rw,ddv/rw)
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

function draw_grid(cam,light)
  local m,cx,cy,cz=cam.m,unpack(cam.origin)
  local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]

  local things={}
  -- particles texture
  poke4(0x5f38,0x0400.0101)

  pal()

  local function project_array(array,type)
    for i,obj in pairs(array) do
      local origin=obj.origin      
      local x,y,z=origin[1]-cx,origin[2]-cy,origin[3]-cz
      local ax,az=m1*x+m9*z,m3*x+m11*z
      
      -- draw shadows (y=0)
      if not obj.shadeless then
        if az>8 and az<384 and 0.5*ax<az and -0.5*ax<az then
          local ay,w=m2*x-m6*cy+m10*z,64/az
          -- thing offset+cam offset              
          local a=atan2(x,z)        
          local a,r=atan2(x*cos(a)+z*sin(a),cy),obj.radius*w>>2
          local x0,y0,ry=63.5+ax*w,63.5-ay*w,r*sin(a)
          ovalfill(x0-r,y0+ry,x0+r,y0-ry)
        end
      end
  
      -- 
      if not obj.no_render then
        ax+=m5*y
        az+=m7*y
        if az>8 and az<384 and 0.5*ax<az and -0.5*ax<az then
          local ay,w=m2*x+m6*y+m10*z,64/az
          things[#things+1]={key=w,type=type,thing=obj,x=63.5+ax*w,y=63.5-ay*w}      
        end
      end
    end
  end
  -- 
  -- render shadows (& collect)
  poke(0x5f5e, 0b11111110)
  color(1)
  project_array(_things,1)
  poke(0x5f5e, 0xff)

  -- collect bullets
  project_array(_bullets,1)
  -- collect particles
  project_array(_particles,3)

  -- radix sort
  rsort(things)

  -- render in order
  local prev_base,prev_sprites,pal0
  for _,item in inext,things do
    local hit_ttl,pal1=item.thing.hit_ttl
    if hit_ttl and hit_ttl>0 then
      pal1=16+(4-hit_ttl)
    else
      pal1=(light*min(15,item.key<<4))\1
    end    
    if(pal0!=pal1) memcpy(0x5f00,0x8000|pal1<<4,16) palt(0,true) pal0=pal1   
    if item.type==1 then
      -- draw things
      local w0,thing=item.key,item.thing
      local entity,origin=thing.ent,thing.origin
      -- zangle (horizontal)
      local dx,dz,yangles,side,flip=cx-origin[1],cz-origin[3],entity.yangles,0
      local zangle=atan2(dx,-dz)
      if yangles!=0 then
        local step=1/(yangles<<1)
        side=((zangle-thing.zangle+0.5+step/2)&0x0.ffff)\step
        if(side>yangles) side=yangles-(side%yangles) flip=true
      end

      -- up/down angle
      -- todo: adjust with height*w/2 ?
      local zangles,yside=entity.zangles,0
      if zangles!=0 then
        local yangle,step=thing.yangle or 0,1/(zangles<<1)
        yside=((atan2(dx*cos(-zangle)+dz*sin(-zangle),-cy+origin[2])-0.25+step/2+yangle)&0x0.ffff)\step
        if(yside>zangles) yside=zangles-(yside%zangles)
      end
      -- copy to spr
      -- skip top+top rotation
      local frame,sprites=entity.frames[(yangles+1)*yside+side+1],entity.sprites
      local mem,base,w,h=0x0,frame.base,frame.width,frame.height
      if prev_base!=base or prev_sprites!=sprites then
        prev_base,prev_sprites=base,sprites
        for i=mem,mem+(h-1)<<6,64 do
          poke4(i,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
          base+=4
        end
      end
      w0*=(thing.scale or 1)
      local sx,sy=item.x-w*w0/2,item.y-h*w0/2
      --
      sspr(frame.xmin,0,w,h,sx,sy,w*w0+(sx&0x0.ffff),h*w0+(sy&0x0.ffff),flip)
      
      --sspr(0,0,32,32,sx,sy,32,32,flip)
      --print(thing.zangle,sx+sw/2,sy-8,9)      
    elseif item.type==2 then
      circfill(item.x,item.y,4*item.key,3)
    elseif item.type==3 then
      local origin=item.thing.prev
      local x,y,z=origin[1]-cx,origin[2]-cy,origin[3]-cz
      -- 
      local ax,az=m1*x+m5*y+m9*z,m3*x+m7*y+m11*z
      if az>8 then
        local ay,w=m2*x+m6*y+m10*z,64/az
        tline(item.x,item.y,63.5+ax*w,63.5-ay*w,0,0,1/8,0)
      end
    end
  end 

  --[[
  for _,thing in pairs(_things) do
    local x,_,z=unpack(thing.origin)
    local x0,y0=128*((x-256)/512),128*((z-256)/512)
    if thing==_plyr then
      spr(7,x0,y0)
    else
      pset(x0,y0,9)
    end
  end
  ]]
end

function inherit(t,env)
  return setmetatable(t,{__index=env or _ENV})
end

-- things
function make_blast(_ents,_origin)  
  add(_things,inherit({
    -- sprite id
    ent=_ents[1],
    origin=_origin,
    update=function(_ENV)
      ttl+=1
      if(ttl>15) dead=true return
      ent=_ents[min(ttl\5+1,#_ents)]
    end
  },_blast_template))
end

function make_blood(_origin)
  make_blast(_blood_ents,_origin)
end

function make_goo(_origin)
  return make_blast(_goo_ents,_origin)
end

-- flying things:
local _flying_target
-- base class for:
-- skull I II III
-- centipede
-- spiderling
function make_skull(actor,_origin)
  local resolved,wobling={},3+rnd(2)
  local thing=add(_things,inherit({
      chatter=actor.chatter or 12,
      origin=_origin,
      seed=rnd(16),
      -- grid cells
      cells={},
      hit=function(_ENV)
        -- avoid reentrancy
        if(dead) return
        hp-=1
        if hp<=0 then
          dead=true
          -- custom death function?
          if die then
            die(_ENV)
          else
            sfx(death_sfx or 52)
          end
          -- draw jewel?
          if jewel then
            make_jewel(origin,velocity)
          end 
          grid_unregister(_ENV)  
          -- custom explosion?
          if blast then blast(origin) else make_blood(origin) end
        else
          hit_ttl=5
        end
      end,
      apply=function(_ENV,other,force,t)
        forces[1]+=t*force[1]
        forces[2]+=t*force[2]
        forces[3]+=t*force[3]
        resolved[other]=true
      end,
      update=function(_ENV)
        hit_ttl=max(hit_ttl-1)
        -- some gravity
        if not on_ground then
          if origin[2]<12 then 
            forces={0,wobling,0}
          elseif origin[2]>80 then
            forces={0,-wobling*2,0}
          end
        end
        -- some friction
        velocity=v_scale(velocity,0.8)

        -- custom think function
        think(_ENV)

        -- avoid others (noted: limited to a single grid cell)
        local idx=world_to_grid(origin)
        
        local fx,fy,fz=forces[1],forces[2],forces[3]
        for other in pairs(_grid[idx].things) do
          -- apply inverse force to other (and keep track)
          if not resolved[other] and other!=_ENV then
            local avoid,avoid_dist=v_dir(origin,other.origin)
            if(avoid_dist<4) avoid_dist=1
            -- todo: tune...
            local t=-32/avoid_dist
            fx+=t*avoid[1]
            fy+=t*avoid[2]
            fz+=t*avoid[3]

            other:apply(_ENV,avoid,-t)
            resolved[other]=true
          end
        end
        -- make sure grounded entities keept on ground
        forces={fx,on_ground and 0 or fy,fz}

        local old_vel=velocity
        velocity=v_add(velocity,forces,1/30)
        -- fixed velocity (on x/z)
        local vx,vz=velocity[1],velocity[3]
        local a=atan2(vx,vz)
        local vlen=vx*cos(a)+vz*sin(a)
        velocity[1]*=3/vlen
        velocity[3]*=3/vlen
        
        -- align direction and sprite direction
        local target_angle=atan2(old_vel[1]-velocity[1],velocity[3]-old_vel[3])
        local shortest=shortest_angle(target_angle,zangle)
        --[[
        if abs(target_angle-shortest)>0.125/2 then
          -- relative change
          shortest=mid(shortest-target_angle,-0.125/2,0.125/2)
          -- preserve length
          local x,z=vel[1],vel[3]
          local len=sqrt(x*x+z*z)
          x,z=old_vel[1],old_vel[3]
          local old_len=sqrt(x*x+z*z)
          x/=old_len
          z/=old_len
          vel[1],vel[3]=len*(x*cos(shortest)+z*sin(shortest)),len*(-x*sin(shortest)+z*cos(shortest))
          shortest+=target_angle
        end
        ]]
        zangle=lerp(shortest,target_angle,0.2)
        
        -- move & clamp
        origin[1]=mid(origin[1]+velocity[1],0,1024)
        origin[2]=max(4,origin[2]+velocity[2])
        origin[3]=mid(origin[3]+velocity[3],0,1024)

        -- for centipede
        if(post_think) post_think(_ENV)

        forces,resolved={0,0,0},{}
        grid_register(_ENV)
      end
    },actor))
  
  grid_register(thing)

  --play spawn sfx
  sfx(actor.spawnsfx or 40)

  return thing
end

-- squid
-- type 1: 3 blocks
-- type 2: 4 blocks
function make_squid(_origin,_velocity)
  local _angle,_dead=0
  -- spill skulls every x seconds
  local spill=do_async(function()
    wait_async(60)
    while not _plyr.dead do
      for t in all(split"_skull1_template,_skull1_template,_skull1_template,_skull2_template,_skull1_template") do
        make_skull(_ENV[t],{_origin[1],64+rnd(16),_origin[3]})
        wait_async(2+rnd(2))
      end
      wait_async(150)
    end
  end)

  local squid=add(_things,inherit({
    update=function(_ENV)
      dead=_dead
      _angle+=0.005
      -- todo: avoid other squids!
      _origin=v_add(_origin,_velocity)      
      origin=_origin
    end
  },_squid_core))
    
  local base_parts=[[_squid_base;angle_offset,0.0,r_offset,8,y_offset,16
_squid_jewel;angle_offset,0.0,r_offset,8,y_offset,38
_squid_base;angle_offset,0.3333,r_offset,8,y_offset,16
_squid_hood;angle_offset,0.3333,r_offset,8,y_offset,38
_squid_base;angle_offset,0.6667,r_offset,8,y_offset,16
_squid_hood;angle_offset,0.6667,r_offset,8,y_offset,38]]
  local tentacle_parts=[[_squid_tentacle;angle_offset,0.0,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;angle_offset,0.0,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;angle_offset,0.0,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;angle_offset,0.0,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2
_squid_tentacle;angle_offset,0.3333,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;angle_offset,0.3333,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;angle_offset,0.3333,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;angle_offset,0.3333,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2
_squid_tentacle;angle_offset,0.6667,scale,1.0,swirl,0.0,radius,8.0,r_offset,12,y_offset,52.0
_squid_tentacle;angle_offset,0.6667,scale,0.8,swirl,0.6667,radius,6.4,r_offset,12,y_offset,60.0
_squid_tentacle;angle_offset,0.6667,scale,0.6,swirl,1.333,radius,4.8,r_offset,12,y_offset,66.4
_squid_tentacle;angle_offset,0.6667,scale,0.4,swirl,2.0,radius,3.2,r_offset,12,y_offset,71.2]]

  local die=function(_ENV)
    if(dead) return
    dead=true 
    make_blood(origin) 
    grid_unregister(_ENV)
  end

  split2d(base_parts,function(base_template,properties)
    add(_things,inherit({
      hit=function(_ENV,pos) 
        if jewel then
          hp-=1
          -- feedback
          make_blood(pos)
          if hp<=0 then
            make_jewel(origin,{u,3,v},16)
            -- avoid reentrancy
            jewel=nil
            ent=_entities.squid2
            -- stop spilling monsters
            spill.co=nil
            _dead=true
          end
        end
      end,
      update=function(_ENV)
        if(_dead) die(_ENV) return
        zangle=_angle+angle_offset
        -- store u/v angle
        u,v=cos(zangle),-sin(zangle)
        zangle+=0.5
        origin=v_add(_origin,{r_offset*u,y_offset,r_offset*v})        
        grid_register(_ENV)
      end    
    },inherit(with_properties(properties),_ENV[base_template])))
  end)
  split2d(tentacle_parts,function(base_template,properties)
    add(_things,inherit({
      update=function(_ENV)
        if(_dead) die(_ENV) return
        local t=time()
        zangle=_angle+angle_offset
        yangle=-cos(t/8+scale)*swirl
        local c,s=cos(zangle),-sin(zangle)
        local offset=r_offset+sin(t/4+scale)*swirl
        origin=v_add(_origin,{offset*c,y_offset,offset*s})
      end      
    },inherit(with_properties(properties),_ENV[base_template])))
  end)
end

-- centipede
function make_worm(_origin)  
  local t_offset,seg_delta,segments,prev_angles,prev,target_ttl,head=rnd(),3,{},{},{},0

  for i=1,20 do
    local seg=add(segments,add(_things,inherit({
      hit=function(_ENV)
        -- avoid reentrancy
        if(touched) return
        make_blood(origin)
        make_jewel(origin,head.velocity)
        touched=true
        -- change sprite (no jewels)
        ent=_entities.worm2
        sfx(56)
      end
    },_worm_seg_template)))
    grid_register(seg)
  end

  head=make_skull(inherit({
    die=function(_ENV)
      music(54)
      -- clean segment
      do_async(function()
        while #segments>0 do
          local seg=deli(segments,1)
          grid_unregister(seg)
          seg.dead=true
          make_blood(seg.origin)
          wait_async(3)
        end
      end)
    end,
    think=function(_ENV)
      target_ttl-=1
      if target_ttl<0 then  
        -- circle
        local a,r=atan2(origin[1]-512,origin[3]-512)+rnd(0.05),96+rnd(32)
        target,target_ttl={512+r*cos(a),16+rnd(48),512-r*sin(a)},60+rnd(10)
      end
      -- navigate to target
      local dir=v_dir(origin,target)
      forces=v_add(forces,dir,8+seed*cos(time()/5))
    end,
    post_think=function(_ENV)
      origin[2]=40+24*sin(t_offset+time()/3)
      add(prev,v_clone(origin),1)
      add(prev_angles,zangle,1)
      if(#prev>20*seg_delta) deli(prev) deli(prev_angles)
      for i=1,#prev,seg_delta do
        local seg=segments[i\seg_delta+1]
        seg.origin=prev[i]
        seg.zangle=prev_angles[i]
        grid_register(seg)
      end
    end
  },_worm_head_template),_origin)
end

function make_jewel(_origin,vel)
  add(_things,inherit({    
    origin=v_clone(_origin),
    pickup=function(_ENV)
      if(dead) return
      dead=true
      _total_jewels+=1
      sfx"57"
      grid_unregister(_ENV)
    end,
    update=function(_ENV)
      ttl-=1
      if ttl<0 then
        dead=true
        return
      end
      -- friction
      if on_ground then
        vel[1]*=0.9
        vel[3]*=0.9
      end
      -- gravity
      vel[2]-=0.8

      -- pulled by player?
      if not _plyr.dead then
        local force=_plyr.attract_power
        if force!=0 then
          local a=atan2(origin[1]-_plyr.origin[1],origin[3]-_plyr.origin[3])
          -- boost repulsive force
          if(force<0) force*=8
          local vx,vz=vel[1]-force*cos(a),vel[3]-force*sin(a)
          if force>0 then
            -- limit attraction velocity
            local a=atan2(vx,vz)
            local len=vx*cos(a)+vz*sin(a)
            if len>3 then
              vx*=3/len
              vz*=3/len
            end
          end
          vel[1],vel[3]=vx,vz
        end
      end
      origin=v_add(origin,vel)
      -- on ground?
      if origin[2]<8 then
        origin[2]=8
        vel[2]=0
        on_ground=true
      end
      grid_register(_ENV)
    end
  },_jewel_template))
end

function make_egg(_origin,vel)
  -- spider spawn time
  local ttl=300+rnd(10)
  -- todo: falling support
  grid_register(add(_things,inherit({
    origin=v_clone(_origin),
    hit=function(_ENV)
      -- avoid reentrancy
      if(dead) return
      hp-=1
      if hp<=0 then
        dead=true
        grid_unregister(_ENV)
        -- todo: make green goo
        make_goo(origin)
      else
        hit_ttl=5
      end
    end,
    update=function(_ENV)
      if(dead) return
      ttl-=1
      if ttl<0 then
        dead=true
        sfx(51)
        grid_unregister(_ENV)
        make_goo(origin)
        -- spiderling
        make_skull(inherit({
            blast=make_goo,
            apply=function(_ENV,other,force,t)
              if other.on_ground then
                forces[1]+=t*force[1]
                forces[3]+=t*force[3]
              end
              resolved[other]=true
            end,
            think=function(_ENV)
              -- navigate to target (direct)
              local dir=v_dir(origin,_plyr.origin)
              forces=v_add(forces,dir,8)
            end
          },_spiderling_template),      
          origin)
      end
    end
  },_egg_template)))
end

-- draw game world
function draw_world()
  cls(0)
              
  poke4(0x5f38,0x0004.0404)
  for _,chunk in pairs(_sides) do
    draw_poly(chunk,1,2,1)
  end

  poke4(0x5f38,0x0000.0404)
  for _,chunk in pairs(_ground) do
    draw_poly(chunk,1,3,1)
  end        

  -- draw things
  draw_grid(_cam,1)      

  -- tilt!
  -- screen = gfx
  -- reset palette
  --memcpy(0x5f00,0x4300,16)
  pal()
  palt(0,false)
  local yshift=sin(_cam.tilt)>>4
  poke(0x5f54,0x60)
  for i=0,127,16 do
    sspr(i,0,16,128,i,(i-64)*yshift+0.5)
  end
  palt(0,true)
  -- reset
  poke(0x5f54,0x00)

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
end

-- gameplay state
function play_state()
  -- camera & player & misc tables
  _plyr=make_player({512,24,512},0)
  _things,_particles,_bullets,_futures={},{},{},{}
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

  -- scenario
  local scenario=do_async(function()
    -- player just spawned
    wait_async(90)
    -- 4 squids
    for i=0,0.75,0.25 do
      local u,v=cos(i),-sin(i)
      local x,z=512+256*u,512-256*v
      make_squid({x,0,z},{-u/16,0,-v/16})
      -- 3s
      wait_async(90)
    end
  end)

  do_async(function()
    -- circle around player
    while not _plyr.dead do
      local angle=time()/8
      local x,y,z=unpack(_plyr.origin)
      local r=48*cos(angle)
      _flying_target={x+r*cos(angle),y+24+rnd(8),z+r*sin(angle)}
      wait_async(10)
    end

    -- if player dead, find a random spot on map
    -- stop creating monsters
    scenario.co=nil
    while true do
      _flying_target={256+rnd(512),12+rnd(64),256+rnd(512)}
      wait_async(45+rnd(15))
    end
  end)
  

  return
    -- update
    function()
      _plyr:control()
      
      _cam:track(_plyr.eye_pos,_plyr.m,_plyr.angle,_plyr.tilt)
    end,
    -- draw
    function()
      draw_world()
      -- todo: draw player hand
      --[[]
      for x=0,31 do
        for y=0,31 do
          local idx,count=x>>16|y,0
          for _ in pairs(_grid[idx].things) do
            count+=1
          end
          rectfill(x*4,y*4,(x+1)*4-1,(y+1)*4-1,count%16)
        end
      end
      spr(7,4*_plyr.origin[1]\32-2,4*_plyr.origin[3]\32-2)      
      ]]

      -- print(((stat(1)*1000)\10).."%\n"..flr(stat(0)).."KB",2,2,3)
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135,0},1)
    end,
    -- init
    function()
      music(32)
      _start_time=time()
    end
end

function gameover_state(obituary)  
  local play_time,origin,target=time()-_start_time,_plyr.eye_pos,v_add(_plyr.origin,{0,8,0})
  -- leaderboard/retry
  local ttl,buttons,selected_tab,over_btn,clicked=90,{
    {"rETRY",1,111,cb=function() 
      -- todo: fade to black
      do_async(function()
        for i=0,15 do
          --memcpy(0x5f00,0x4300|i<<4,16)
          yield()
        end
        next_state(play_state)
      end)
    end},
    {"sTATS",1,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        local x=arizona_print("\147 ",1,30,3)
        x=arizona_print(play_time.."S\t ",x,30)
        x=arizona_print("\130 ",x,30,3)
        x=arizona_print(tostr(obituary),x,30)
        --
        local pct=_total_hits==0 and 0 or 1000*(_total_hits/_total_bullets)
        x=arizona_print("\143 ",1,38,3)
        x=arizona_print(_total_jewels.."\t ",x,38)
        x=arizona_print("\134 ",x,38,3)
        x=arizona_print(tostr(_total_bullets,2).."\t ",x,38)
        x=arizona_print("\136 ",x,38,3)
        x=arizona_print((flr(pct)/10).."%",x,38)
      end
    },
    {"lOCAL",46,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        -- todo: local 
        srand(42)
        for i=1,5 do
          arizona_print(i..". "..flr(rnd(1500)),1,23+i*7)
        end
      end},
    {"oNLINE",96,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        -- todo: online
        srand(42)
        for i=1,5 do
          arizona_print(i..". bOB48 "..flr(rnd(1500)),1,23+i*7)
        end
      end
    }
  }
  -- default (stats)
  selected_tab=buttons[2]
  -- get actual size
  clip(0,0,0,0)
  for _,btn in pairs(buttons) do
    btn.width=print(btn[1])
  end
  clip()
  -- position cursor on retry
  local _,x,y=unpack(buttons[1])
  local mx,my=x+buttons[1].width/2,y+3
  -- death music
  music(8)
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
        -- darken game screen
        palt(0,false)
        poke(0x5f54,0x60)
        -- shift palette
        memcpy(0x5f00,0x8000|9<<4,16)
        spr(0,0,0,16,16)
        pal()
        -- reset
        poke(0x5f54,0x00)
      
        -- draw menu & all
        arizona_print("hIGHSCORES",1,8)
        for i,btn in pairs(buttons) do
          local s,x,y=unpack(btn)
          arizona_print(s,x,y,selected_tab==btn and 2 or i==over_btn and 1)
        end
        line(unpack(split"1,24,126,24,4"))
        line(unpack(split"1,25,126,25,2"))
        line(unpack(split"1,109,126,109,2"))
        line(unpack(split"1,108,126,108,4"))

        selected_tab:draw()

        -- mouse cursor
        spr(20,mx,my)
      end
      -- hw palette
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

-- pico8 entry points
function _init()
  -- enable custom font
  poke(0x5f58,0x81)

  -- enable tile 0 + extended memory
  poke(0x5f36, 0x18)
  -- capture mouse
  -- enable lock
  poke(0x5f2d,0x7)

  -- exit menu entry
  menuitem(1,"main menu",function()
    -- local version
    load("title.p8")
    -- bbs version
    load("#freds72_daggers_title")
  end)

  -- god mode menu entry
  local god_menu_handler
  god_menu_handler=function()
    _god_mode=not _god_mode
    menuitem(2,"god mode "..tostr(_god_mode),god_menu_handler)
    return true
  end
  _god_mode=false
  god_menu_handler()
  _god_mode=false

  -- always needed  
  _cam=inherit{
    origin={0,0,0},    
    track=function(_ENV,_origin,_m,angles,_tilt)
      --
      tilt=_tilt or 0
      m={unpack(_m)}		

      -- inverse view matrix
      m[2],m[5]= m[5], m[2]
      m[3],m[9]= m[9], m[3]
      m[7],m[10]=m[10],m[7]
      
      origin=_origin
    end
  }

  _bullets,_things,_futures={},{},{}
  -- load images
  _entities=decompress("pic",0,0,unpack_entities)
  -- predefined entries (avoids constant gc)
  _blood_ents,_goo_ents={
    _entities.blood0,
    _entities.blood1,
    _entities.blood2
  },{
    _entities.goo0,
    _entities.goo1,
    _entities.goo2
  }
  -- global templates
  local templates=[[_blast_template;zangle,rnd,yangle,0,ttl,0,shadeless,1
_skull_template;zangle,rnd,yangle,0,hit_ttl,0,forces,v_zero,velocity,v_zero
_egg_template;ent,egg,radius,12,hp,2,zangle,0,apply,nop,on_ground,1
_worm_seg_template;ent,worm1,radius,16,zangle,0,origin,v_zero,apply,nop,spawnsfx,42
_worm_head_template;ent,worm0,radius,18,hp,10,apply,nop,chatter,20;_skull_template
_jewel_template;ent,jewel,radius,8,zangle,rnd,ttl,3000,apply,nop
_spiderling_template;ent,spider0,radius,16,friction,0.5,hp,2,on_ground,1,death_sfx,53,chatter,28,spawnsfx,41;_skull_template
_squid_core;no_render,1,radius,48,origin,v_zero,on_ground,1
_squid_base;ent,squid0,radius,32,origin,v_zero,zangle,0,shadeless,1,apply,nop,hit,nop
_squid_hood;ent,squid2,radius,32,origin,v_zero,zangle,0,shadeless,1,apply,nop
_squid_jewel;jewel,1,hp,10,ent,squid1,radius,32,origin,v_zero,zangle,0,shadeless,1,apply,nop
_squid_tentacle;ent,tentacle0,radius,16,origin,v_zero,zangle,0
_skull1_base_template;ent,skull,radius,16,hp,2,chatter,5;_skull_template
_skull2_base_template;ent,reaper,radius,18,hp,5,target_ttl,0,jewel,1,chatter,6;_skull_template]]
  split2d(templates,function(name,template,parent)
    _ENV[name]=inherit(with_properties(template),_ENV[parent])
  end)

  -- scripted skulls
  _skull1_template=inherit({
    think=function(_ENV)
      -- converge toward player
      if _flying_target then
        local dir=v_dir(origin,_flying_target)
        forces=v_add(forces,dir,8+seed*cos(time()/5))
      end
    end
  },_skull1_base_template)

  _skull2_template=inherit({
    think=function(_ENV)      
      target_ttl-=1
      if target_ttl<0 then  
        -- go opposite from where it stands!  
        local a=atan2(origin[1]-512,origin[3]-512)+0.625-rnd(0.25)
        local r=64+rnd(64)
        target={512+r*cos(a),16+rnd(48),512-r*sin(a)}
        target_ttl=90+rnd(10)
      end
      -- navigate to target
      local dir=v_dir(origin,target)
      forces=v_add(forces,dir,8+seed*cos(time()/5))
    end
  },_skull2_base_template)  
  reload()
  
  -- init ground vectors
  for _,chunk in pairs(_sides) do
    chunk.cp=v_dot(chunk[1],chunk.n)
  end
  for _,chunk in pairs(_ground) do
    chunk.cp=v_dot(chunk[1],chunk.n)
  end

  -- run game
  next_state(play_state)
end

-- collect all grids touched by (a,b) vector
function collect_grid(a,b,u,v,cb)
  local mapx,mapy,dest_mapx,dest_mapy,mapdx,mapdy=a[1]\32,a[3]\32,b[1]\32,b[3]\32
  -- check first cell (always)
  cb(_grid[mapx>>16|mapy].things)
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
    disty=(a[3]/32-mapy)*ddy
  else
    mapdy=1
    disty=(mapy+1-a[3]/32)*ddy
  end
  while dest_mapx!=mapx and dest_mapy!=mapy do
    -- printh(mapx.."/"..mapy.." -> "..dest_mapx.."/"..dest_mapy.." ["..mapdx.." "..mapdy.."]")
    if distx<disty then
      distx+=ddx
      mapx+=mapdx
    else
      disty+=ddy
      mapy+=mapdy
    end
    cb(_grid[mapx>>16|mapy].things)
  end  
end

-- ray (a->b) intersection
-- returns distance to target
function ray_sphere_intersect(a,b,dir,len,origin,r)
  -- todo: persist in mins,maxs extent (worth it?)
  -- todo: with grid - may not be worth it...
  local ox,oy,oz=origin[1],origin[2],origin[3]
  local xmin,xmax,ymin,ymax,zmin,zmax,ax,ay,az,bx,by,bz=ox-r,ox+r,oy-r,oy+r,oz-r,oz+r,a[1],a[2],a[3],b[1],b[2],b[3]
  -- 2d SAT check
  if(ax<xmin and bx<xmin or ax>xmax and bx>xmax) return
  if(az<zmin and bz<zmin or az>zmax and bz>zmax) return
  -- 3d check  
  if(ay<ymin and by<ymin or ay>ymax and by>ymax) return

  -- projection on ray
  local dx,dy,dz=dir[1],dir[2],dir[3]
  local t=dx*(ox-ax)+dy*(oy-ay)+dz*(oz-az)
  if t>=-r and t<=len+r then
    -- distance to sphere?
    ox-=t*dx
    oy-=t*dy
    oz-=t*dz
    --assert(dx*dx+dy*dy+dz*dz>=0)
    return ox*ox+oy*oy+oz*oz<r*r,t,{ox,oy,oz}
  end
end

local _checked=0
function _update()
  -- keep world running    
  local t=time()
  -- bullets collisions
  for i=#_bullets,1,-1 do
    _checked+=1
    local b=_bullets[i]
    if b.ttl<t then
      deli(_bullets,i)
    else
      b.yangle+=0.1
      local prev,origin,len,dead=b.origin,v_add(b.origin,b.velocity,10),10
      -- out of bounds?
      local x,z=origin[1],origin[3]
      if x>64 and x<1024 and z>64 and z<1024 then
        local y=origin[2]
        if y<0 then
          -- hit ground?
          -- intersection with ground
          local dy=prev[2]/(prev[2]-y)
          x,z=lerp(prev[1],x,dy),lerp(prev[3],z,dy)
          origin={x,0,z}
          -- adjust length
          len=v_len(prev,origin)
          -- no matter what - we hit the ground!
          dead=true
          make_blood(origin)
          for i=1,rnd(5) do
            local a=b.zangle+(1-rnd(2))/8
            local cc,ss,r=cos(a),-sin(a),2+rnd(2)
            local o={x+r*cc,0,z+r*ss}
            make_particle(o,{cc,1+rnd(),ss})
          end
        end
        -- collect touched grid indices
        local hit_t,hit_thing,hit_pos=32000
        collect_grid(prev,origin,b.u,b.v,function(things)
          -- todo: advanced bullets can traverse enemies
          for thing in pairs(things) do
            -- hitable?
            -- avoid checking the same enemy twice
            if not thing.dead and thing.hit and thing.checked!=_checked then
              thing.checked=_checked
              local hit,t,pos=ray_sphere_intersect(prev,origin,b.velocity,len,thing.origin,thing.radius)
              if hit and t<hit_t then
                hit_thing,hit_t,hit_pos=thing,t,pos
              end
            end
          end
        end)
        -- apply hit on closest thing
        if hit_thing then
          hit_thing:hit(hit_pos)
          dead=true
          _total_hits+=0x0.0001
          -- todo: allow for multiple hits
        end
      else
        dead=true
      end

      if dead then
        -- hit something?
        deli(_bullets,i)
      else
        b.prev,b.origin=prev,origin
      end
    end
  end
  -- effects
  for i=#_particles,1,-1 do
    local p=_particles[i]
    if p.ttl<t then
      deli(_particles,i)
    else
      local velocity=v_scale(p.velocity,0.8)
      -- gravity
      velocity[2]-=0.8
      local origin=v_add(p.origin,velocity,5)
      if origin[2]<0 then
        origin[2]=0
        -- fake rebound
        velocity[2]*=-0.5
      end
      p.prev,p.origin,p.velocity=p.origin,origin,velocity
    end
  end

  _plyr:update()
  --
  for i=#_things,1,-1 do
    local thing=_things[i]
    if thing.dead then
      -- note: assumes thing is already unregistered
      deli(_things,i)
    elseif thing.update then
      thing:update()
    end
  end

  -- any futures?
  update_asyncs()

  _update_state()
end

-- unpack assets
function unpack_entities()
  local entities,names={},split"skull,reaper,blood0,blood1,blood2,dagger0,dagger1,dagger2,hand0,hand1,hand2,goo0,goo1,goo2,egg,spider0,spider1,worm0,worm1,jewel,worm2,tentacle0,tentacle1,squid0,squid1,squid2"
  local obituaries=split"sKULLED,iMPALED,blood0,blood1,blood2,dagger0,dagger1,dagger2,hand0,hand1,hand2,goo0,goo1,goo2,aCIDIFIED,wEBBED,wEBBED,wORMED,wORMED,jewel,wORMED,tentacle0,tentacle1,nAILED,nAILED,nAILED"
  unpack_array(function()
    local id=mpeek()
    if id!=0 then
      local sprites,angles={},mpeek()
      entities[names[id]]={  
        obituary=obituaries[id],
        sprites=sprites,   
        yangles=angles&0xf,
        zangles=angles\16,        
        frames=unpack_frames(sprites)
      }
      printh("restored:"..names[id].." #sprites:"..#sprites)
    end
  end)
  return entities
end
