local _plyr,_cam

function make_fps_cam()
    local up={0,1,0}
    
    return {
        origin={0,0,0},    
        track=function(self,origin,m,angles)
            local ca,sa=-sin(angles[2]),cos(angles[2])
            self.u=ca
            self.v=sa
      
            --origin=v_add(v_add(origin,m_fwd(m),-24),m_up(m),24)	      
            local m={unpack(m)}		
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
        if(btnp(4)) jmp=6
  
        dangle=v_add(dangle,{stat(39),stat(38),dx/40})
        local c,s=cos(a),-sin(a)
        velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx},1)         
      end,
      update=function(self)
        -- damping      
        angle[3]*=0.8
        dangle=v_scale(dangle,0.6)
        velocity[1]*=0.7
        --velocity[2]*=0.9
        velocity[3]*=0.7
        -- gravity
        velocity[2]-=18
  
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
                
            -- use corrected velocity
            self.origin=new_pos
            velocity=new_vel
        end

        if dead then
          self.eye_pos=v_add(self.origin,{0,2,0})
        else
          self.eye_pos=v_add(self.origin,{0,24,0})
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

function draw_ground()
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
      mode7(verts,#verts)
    end

    
end

function mode7(p,np)
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
      local y0,y1,w1=v0.y,v1.y,v1.w<<4
      local dy=y1-y0
      ly=y1&-1
      lx=v0.x
      lw=v0.w<<4
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
      local y0,y1,w1=v0.y,v1.y,v1.w<<4
      local dy=y1-y0
      ry=y1&-1
      rx=v0.x
      rw=v0.w<<4
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
    do
      local rx,lx,ru,rv,rw=rx,lx,ru,rv,rw
      local ddx=lx-rx--((lx+0x1.ffff)&-1)-(rx&-1)
      local ddu,ddv,ddw=(lu-ru)/ddx,(lv-rv)/ddx,(lw-rw)/ddx
      if(rx<0) ru-=rx*ddu rv-=rx*ddv rw-=rx*ddw rx=0
      local pix=1-rx&0x0.ffff
      ru+=pix*ddu
      rv+=pix*ddv
      rw+=pix*ddw
      
      local u,v=ru/rw,rv/rw
      tline(rx,y,lx\1-1,y,u,v,ddu/rw,ddv/rw)
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

function game_state()
    -- backup previous update/draw
    local u,d=_update,_draw
    _plyr=make_player({0,24,0},0)
    _cam=make_fps_cam()
    
    -- enable tile 0 + extended memory
    poke(0x5f36, 0x18)
    -- capture mouse
    -- enable lock
    poke(0x5f2d,0x7)

    menuitem(1, "back to editor",
        function() 
            -- reset
            menuitem(1) 
            _cam,_plyr=nil
            -- restore update/draw
            poke(0x5f2d,1)
            _update,_draw=u,d
        end
    )
    _update=function()
      _plyr:control()
      _plyr:update()
      -- always track
      _cam:track(_plyr.eye_pos,_plyr.m,_plyr.angle)
    end
    _draw=function()        
        _draw=function()
            cls(0)
            draw_ground()
            
            pal({128, 130, 133, 5, 134, 6, 130, 136, 8, 138, 139, 3, 131, 1, 129,0},1)
        end
    end
end