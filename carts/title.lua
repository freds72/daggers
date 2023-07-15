-- globals
local _entities,_sprites={},{}

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

function menu_state(buttons,default)
  local skulls,ent,sprites={},_entities.skull,_sprites
  -- leaderboard/retry
  local over_btn,clicked
  
  -- get actual size
  clip(0,0,0,0)
  for _,btn in pairs(buttons) do
    btn.width=print(btn[1])
  end
  clip()
  -- position cursor on "default"
  default=default or 1
  active_btn=buttons[default]
  local _,x,y=unpack(active_btn)
  local mx,my=x+active_btn.width/2,y+3

  return
    -- update
    function()
      mx,my=mid(mx+stat(38)/2,0,127),mid(my+stat(39)/2,0,127)
      -- over button?
      over_btn=-1
      for i,btn in pairs(buttons) do
        local _,x,y=unpack(btn)          
        if mx>=x and my>=y and mx<=x+btn.width and my<=y+6 then            
          over_btn=i
          -- click?
          if not clicked and btnp(5) then
            active_btn=btn
            btn:cb()
            -- todo: fix
            clicked=nil
          end
          break
        end
      end

      -- skull background
      if #skulls<40 then
        local s=add(skulls,{
          origin={38+rnd(48),140,0.5+rnd()/2},
          velocity={(1-rnd(2))/12,-rnd(0.8)-0.2,0},
          zangle=rnd(),
          yangle=rnd(),
          yangle_vel=rnd()/64
        })
        -- sort key        
        s.key=10+8*s.origin[3]
      end      

      for i=#skulls,1,-1 do
        local s=skulls[i]
        s.origin=v_add(s.origin,s.velocity)
        if s.origin[2]<-16 then
          deli(skulls,i)          
        else
          s.yangle+=s.yangle_vel
        end
      end
    end,  
    function()
      -- background
      cls()  
      pal()
      local r0=16-abs(2*cos(time()/4))+0x0.0001
      fillp(0xa5a5)
      ovalfill(0,128-r0,127,128+r0,1)
      fillp()
      ovalfill(r0/3,128-r0*0.95,127-r0/3,128+r0*0.95,1)
      ovalfill(r0/2,128-r0*0.75,127-r0/2,128+r0*0.75,2)
      rsort(skulls)
      for i=1,#skulls do
        local s=skulls[i]
        local yangle=(8*(s.yangle&0x0.ffff))\1
        local yflip=false
        if(yangle>4) yflip=true yangle=4-(yangle%4) 
        local frame=ent.frames[5*yangle+flr(5*s.zangle)+1]
        local mem,base=0x0,frame.base
        for i=0,frame.height-1 do
          poke4(mem,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
          mem+=64
          base+=4
        end
        memcpy(0x5f00,0x8000|flr(16*s.origin[3])<<4,16) palt(15,true)
        sspr(frame.xmin,0,frame.width,frame.height,s.origin[1]-frame.width/2,s.origin[2]-frame.height/2,frame.width,frame.height,false,yflip)
      end
      pal()
      
      -- draw menu & all
      for i,btn in pairs(buttons) do
        local s,x,y=unpack(btn)        
        arizona_print(s,x,y,i==over_btn and 1)
      end
      if(active_btn.draw) active_btn:draw()

      -- mouse cursor
      spr(20,mx,my)
      -- hw palette
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

-- main menu buttons
local _starting
local _main_buttons={
  {"pLAY",1,48,cb=function()      
    -- avoid reentrancy
    if(_starting) return
    _starting=true
    music(-1,250)
    -- todo: fade to black
    do_async(function()
      wait_async(10)
      next_state(play_state)
      -- load("daggers.p8")
    end)
  end},
  {"lEADERBOARD",1,64,
    cb=function(self) 
      leaderboard_state()
    end},
  {"eDITOR",1,74,
    cb=function(self) 
      load("editor.p8")
    end},
  {"cREDITS",1,84,
    cb=function(self) 
      credits_state()
    end}
}

function delayed_print(text,centered)
  local startx,endx={},{}
  for i,s in ipairs(text) do
    startx[i]=128+i*32
    -- either centered or left aligned
    endx[i]=centered and (64-print(s,0,128)/2) or 1
  end          
  return function(print)
    for i,s in ipairs(text) do
      startx[i]=lerp(startx[i],endx[i],0.5)
      print(s,startx[i],i)
    end          
  end
end

-- leaderboard
function leaderboard_state()
  -- local score version
  local local_scores={}
  if dget(0)==1 then
    -- number of scores    
    local mem=0x5e08
    for i=1,dget(1) do
      -- duration (seconds)
      -- timestamp yyyy,mm,dd
      local t,y,m,d=peek4(mem,4)
      add(local_scores,scanf("$. $/$/$\t $S",i,y,m,d,t))
      mem+=16
    end    
  end

  local delay_print=delayed_print(local_scores)

  next_state(menu_state,{
    {"bACK",1,111,
    cb=function() 
      -- back to main menu
      next_state(menu_state, _main_buttons)
    end,
    draw=function()
      split2d([[1;24;126;24;4
      1;25;126;25;2
      1;109;126;109;2
      1;108;126;108;4]],line)   
      arizona_print("lOCAL hIGHSCORES",1,16,2)
      delay_print(function(s,x,i)
        arizona_print(s,x,23+i*7)
      end)
    end}
  })
end

-- credits
function credits_state()
  local delay_print=delayed_print({"cODE & GFX: fREDS72","mUSIC & SFX: rIDGEK", "","tHANKS TO:","sORATH","aRTYOM bRULLOV","..."},true)
  next_state(menu_state,{
    {"bACK",1,111,
    cb=function() 
      -- back to main menu
      next_state(menu_state, _main_buttons)
    end,
    draw=function()
      split2d([[1;24;126;24;4
      1;25;126;25;2
      1;109;126;109;2
      1;108;126;108;4]],line)   
      arizona_print("cREDITS",1,16,2)
      delay_print(function(s,x,i)
        arizona_print(s,x,23+i*7)
      end)        
    end}
  })
end

function play_state()
  local cam=setmetatable({
    origin=v_zero(),    
    track=function(_ENV,_origin,_m,angles,_tilt)
      --
      tilt=_tilt or 0
      m={unpack(_m)}		

      -- inverse view matrix
      m[2],m[5]= m[5], m[2]
      m[3],m[9]= m[9], m[3]
      m[7],m[10]=m[10],m[7]
      
      origin=_origin
    end},{__index=_ENV})

  -- start above floor
  local angle,dangle=v_zero(),v_zero()
  local tilt=0
  local velocity=v_zero()
  local origin=split"512,0,512"
  local eye_pos=v_add(origin,split"0,24,0")

  local plane={
    {256,0,256},
    {256,0,768},
    {768,0,768},
    {768,0,256},
  }
  return
    -- update
    function()
      -- move
      local dx,dz,a=0,0,angle[2]
      if(btn(0,1)) dx=3
      if(btn(1,1)) dx=-3
      if(btn(2,1)) dz=3
      if(btn(3,1)) dz=-3

      dangle=v_add(dangle,{stat(39),stat(38),0})
      tilt+=dx/40
      local c,s=cos(a),-sin(a)
      velocity=v_add(velocity,{s*dz-c*dx,0,c*dz+s*dx},0.35)
      origin=v_add(origin,velocity)
      eye_pos=v_add(origin,{0,24,0})

      -- damping      
      dangle=v_scale(dangle,0.6)
      tilt*=0.6
      if(abs(tilt)<=0.0001) tilt=0
      velocity[1]*=0.7
      velocity[3]*=0.7
      angle=v_add(angle,dangle,1/1024)
      
      local m=make_m_from_euler(unpack(angle))        

      cam:track(eye_pos,m,angle,tilt)
    end,
    -- draw
    function()
      cls()
      local m,cx,cy,cz=cam.m,unpack(cam.origin)
      local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]
      local verts,outcode,nearclip={},0xffff,0  
      for i,v0 in inext,plane do
        local code,x,y,z=2,v0[1]-cx,v0[2]-cy,v0[3]-cz
        local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
        if(az>8) code=0
        if(az>384) code|=1
        if(-ax>az) code|=4
        if(ax>az) code|=8
        
        local w=64/az 
        verts[i]={ax,ay,az,u=v0[1],v=v0[3],x=63.5+ax*w,y=63.5-ay*w,w=w}
        
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

        -- texture
        poke4(0x5f38,0x3c00.0404)   
        tline(17)   
        mode7(verts,#verts,1)        
      end

      -- tilt!
      -- screen = gfx
      -- reset palette
      --memcpy(0x5f00,0x4300,16)
      pal()
      palt(0,false)
      local yshift=sin(tilt)>>4
      poke(0x5f54,0x60)
      for i=0,127,16 do
        sspr(i,0,16,128,i,(i-64)*yshift+0.5)
      end
      -- reset
      poke(0x5f54,0x00)

      -- hide trick top/bottom 8 pixel rows :)
      memset(0x6000,0,512)
      memset(0x7e00,0,512)

      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

-- entry points
function _init()
  -- custom font
  ?"\^@56000800⁴⁸⁶\0\0¹\0\0\0\0\0\0\0\0\0\0\0 \0²\0\0\0\0¹■■■■\0\0\0▮¹■■▒■ ■■■」!■\0\0\0▮■■▮\0■!■■■■!■\0\0²\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0⁷⁷⁷⁷⁷\0\0\0\0⁷⁷⁷\0\0\0\0\0⁷⁵⁷\0\0\0\0\0⁵²⁵\0\0\0\0\0⁵\0⁵\0\0\0\0\0⁵⁵⁵\0\0\0\0⁴⁶⁷⁶⁴\0\0\0¹³⁷³¹\0\0\0⁷¹¹¹\0\0\0\0\0⁴⁴⁴⁷\0\0\0⁵⁷²⁷²\0\0\0\0\0²\0\0\0\0\0\0\0\0¹²\0\0\0\0\0\0³³\0\0\0⁵⁵\0\0\0\0\0\0²⁵²\0\0\0\0\0\0\0\0\0\0\0\0\0²²²²\0²\0\0\n⁵\0\0\0\0\0\0\n゜\n゜⁸\0\0\0⁷³⁶⁷²\0\0\0⁵⁴²¹⁵\0\0\0\0⁴²◀\t◀\0\0²¹\0\0\0\0\0\0²¹¹¹¹²\0\0²⁴⁴⁴⁴²\0\0⁵²⁷²⁵\0\0\0\0²⁷²\0\0\0\0\0\0\0²¹\0\0\0\0\0⁷\0\0\0\0\0\0\0\0\0²\0\0\0⁴²²²¹\0\0\0⁶\t\rᵇ⁶\0\0\0²³²²⁷\0\0\0⁷ᶜ⁶¹ᶠ\0\0\0⁷ᶜ⁶⁸ᶠ\0\0\0⁵⁵ᶠ⁴⁴\0\0\0ᶠ¹⁶ᶜ⁷\0\0\0⁴²⁷\t⁶\0\0\0ᶠ⁸⁴²²\0\0\0⁶\t⁶\t⁶\0\0\0⁶\tᵉ⁴²\0\0\0\0²\0²\0\0\0\0\0²\0²¹\0\0\0⁴²¹²⁴\0\0\0\0⁷\0⁷\0\0\0\0¹²⁴²¹\0\0\0²⁵⁴²\0²\0\0²⁵⁵¹⁶\0\0\0\0⁶⁸ᵇ⁶\0\0\0¹⁵\t\t⁶\0\0\0\0⁶¹¹⁶\0\0\0⁸\n\t\t⁶\0\0\0\0ᵉ\t⁵ᵉ\0\0\0ᶜ²ᵉ³²¹\0\0\0ᵉ\t\r\n⁴\0\0¹⁵ᵇ\t\t⁴\0\0²\0³²²⁷\0\0\0ᶜ⁸⁸\t⁶\0\0¹\t⁵ᵇ\t⁴\0\0¹¹¹¹⁶\0\0\0\0\n▶‖‖\0\0\0\0⁶\t\t\t\0\0\0\0⁶\t\t⁶\0\0\0\0⁶\t\t⁵¹\0\0\0⁶\t\t\n⁸\0\0\0\rᵇ¹¹\0\0\0\0ᵉ³⁸ᶠ\0\0\0\0²ᵉ³²ᶜ\0\0\0\t\t\t⁶\0\0\0\0\t\t⁵³\0\0\0\0‖‖‖ᵇ\0\0\0\0\t⁶⁴\t\0\0\0\0\t\tᵇ⁴³\0\0\0⁷⁴²⁷\0\0\0³¹¹¹¹³\0\0¹¹³²²\0\0\0⁶⁴⁴⁴⁴⁶\0\0²⁵\0\0\0\0\0\0\0\0\0\0⁷\0\0\0²⁴\0\0\0\0\0\0⁶\tᵇ\r\t\t\0\0⁶\t⁵ᵇ\t⁷\0\0⁶\t¹¹\t⁶\0\0³⁵\t\t\t⁷\0\0⁶¹⁵³\t⁶\0\0⁶¹⁵³¹¹\0\0⁶¹¹\r\t⁶\0\0⁵⁵⁵⁷⁵⁵\0\0⁷²²²²⁷\0\0ᵉ⁸⁸⁸\t⁶\0\0\t\t⁵ᵇ\t\t\0\0²¹¹¹\t⁷\0\0\n▶‖‖‖‖\0\0\nᵇ\r\t\t\t\0\0⁶\t\t\t\t⁶\0\0⁶\t\t\r¹¹\0\0⁶\t\t\t\r\n\0\0⁶\t\t⁵ᵇ\t\0\0ᵉ³⁶⁸⁸⁷\0\0ᶜ³²²²²\0\0\t\t\t\t\t⁶\0\0\t\t\t\t⁵³\0\0‖‖‖‖▶\r\0\0\t\t\t⁶\t\t\0\0\t\t\tᵇ⁴³\0\0⁷⁴²¹¹⁷\0\0⁶²³²⁶\0\0\0²²²²²\0\0\0³²⁶²³\0\0\0\0²‖ᶜ\0\0\0\0\0²⁵²\0\0\0\0○○○○○\0\0\0U*U*U\0\0\0、>*⁘、\0\0\0>ccw>\0\0\0■D■D■\0\0\0⁴<、゛▮\0\0\0⁸*>、、⁸\0\0006>>、⁸\0\0\0、\"*\"、\0\0\0、、>、⁘\0\0\0、>○*:\0\0\0>gcg>\0\0\0○]○A○\0\0\0008⁸⁸ᵉᵉ\0\0\0>ckc>\0\0\0⁸、>、⁸\0\0\0\0\0U\0\0\0\0\0>scs>\0\0\0⁸、○>\"\0\0\0「$JZ$「\0\0>wcc>\0\0\0\0⁵R \0\0\0\0\0■*D\0\0\0\0>kwk>\0\0\0○\0○\0○\0\0\0UUUUU\0\0\0ᵉ⁴゛-&\0\0\0■!!%²\0\0\0ᶜ゛  、\0\0\0⁸゛⁸$¥\0\0\0N⁴>E&\0\0\0\"_□□\n\0\0\0゛⁸<■⁶\0\0\0▮ᶜ²ᶜ▮\0\0\0\"z\"\"□\0\0\0゛ \0²<\0\0\0⁸<▮²ᶜ\0\0\0²²²\"、\0\0\0⁸>⁸ᶜ⁸\0\0\0□?□²、\0\0\0<▮~⁴8\0\0\0²⁷2²2\0\0\0ᶠ²ᵉ▮、\0\0\0>@@ 「\0\0\0>▮⁸⁸▮\0\0\0⁸8⁴²<\0\0\0002⁷□x「\0\0\0zB²\nr\0\0\0\t>Kmf\0\0\0¥'\"s2\0\0\0<JIIF\0\0\0□:□:¥\0\0\0#b\"\"、\0\0\0ᶜ\0⁸*M\0\0\0\0ᶜ□!@\0\0\0}y■=]\0\0\0><⁸゛.\0\0\0⁶$~&▮\0\0\0$N⁴F<\0\0\0\n<ZF0\0\0\0゛⁴゛D8\0\0\0⁘>$⁸⁸\0\0\0:VR0⁸\0\0\0⁴、⁴゛⁶\0\0\0⁸²> 、\0\0\0\"\"& 「\0\0\0>「$r0\0\0\0⁴6,&d\0\0\0>「$B0\0\0\0¥'\"#□\0\0\0ᵉd、(x\0\0\0⁴²⁶+」\0\0\0\0\0ᵉ▮⁸\0\0\0\0\n゜□⁴\0\0\0\0⁴ᶠ‖\r\0\0\0\0⁴ᶜ⁶ᵉ\0\0\0> ⁘⁴²\0\0\0000⁸ᵉ⁸⁸\0\0\0⁸>\" 「\0\0\0>⁸⁸⁸>\0\0\0▮~「⁘□\0\0\0⁴>$\"2\0\0\0⁸>⁸>⁸\0\0\0<$\"▮⁸\0\0\0⁴|□▮⁸\0\0\0>   >\0\0\0$~$ ▮\0\0\0⁶ &▮ᶜ\0\0\0> ▮「&\0\0\0⁴>$⁴8\0\0\0\"$ ▮ᶜ\0\0\0>\"-0ᶜ\0\0\0、⁸>⁸⁴\0\0\0** ▮ᶜ\0\0\0、\0>⁸⁴\0\0\0⁴⁴、$⁴\0\0\0⁸>⁸⁸⁴\0\0\0\0、\0\0>\0\0\0> (▮,\0\0\0⁸>0^⁸\0\0\0   ▮ᵉ\0\0\0▮$$DB\0\0\0²゛²²、\0\0\0>  ▮ᶜ\0\0\0ᶜ□!@\0\0\0\0⁸>⁸**\0\0\0> ⁘⁸▮\0\0\0<\0>\0゛\0\0\0⁸⁴$B~\0\0\0@(▮h⁶\0\0\0゛⁴゛⁴<\0\0\0⁴>$⁴⁴\0\0\0、▮▮▮>\0\0\0゛▮゛▮゛\0\0\0>\0> 「\0\0\0$$$ ▮\0\0\0⁘⁘⁘T2\0\0\0²²\"□ᵉ\0\0\0>\"\"\">\0\0\0>\" ▮ᶜ\0\0\0> < 「\0\0\0⁶  ▮ᵉ\0\0\0\0‖▮⁸⁶\0\0\0\0⁴゛⁘⁴\0\0\0\0\0ᶜ⁸゛\0\0\0\0、「▮、\0\0\0⁸⁴c▮⁸\0\0\0⁸▮c⁴⁸\0\0\0"
  -- enable custom font
  -- enable tile 0 + extended memory
  -- capture mouse
  -- enable lock
  -- cartdata
  split2d([[poke;0x5f58;0x81
poke;0x5f36;0x18
poke;0x5f2d;0x7
cartdata;freds72_daggers]],exec)

  -- capture gradient
  local mem=0x8000
  for i=15,0,-1 do
    for j=0,15 do
      poke(mem,sget(i+32,j+16))
      mem+=1
    end
  end
  -- hit palette
  for i=0,3 do
    for j=0,15 do
      poke(mem,sget(31-i,j+16))
      mem+=1
    end
  end

  -- generate 
  -- todo: generate assets if not there
  --
  -- load background assets
  decompress("pic",0,0,function()
      -- drop array size
      mpeek2()
      local id,angles=mpeek(),mpeek()
      _entities.skull={        
        frames=unpack_frames(_sprites)
      }
  end)
  reload()

  -- background music
  music(8)

  -- init game
  next_state(menu_state, _main_buttons)
end

function _update()
  update_asyncs()
  _update_state()
end


