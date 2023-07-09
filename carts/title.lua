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
      load("daggers.p8")
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
      -- todo: credits!
    end}
}

-- leaderboard
function leaderboard_state()
  
  -- local score version
  local local_scores={}
  if dget(0)==1 then
    -- number of scores    
    local mem=0x5e08
    for i=1,dget(1) do
      -- duration (sec)
      -- timestamp yyyy,mm,dd
      add(local_scores,{peek4(mem,4)})
      mem+=16
    end    
  end
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
      for i,local_score in ipairs(local_scores) do
        local t,y,m,d=unpack(local_score)
        arizona_print(scanf("$. $/$/$\t $S",i,y,m,d,t),1,23+i*7)
      end          
    end}
  })
end

-- entry points
function _init()
  -- custom font
  ?"\^@56000800⁴⁸⁶\0\0¹\0\0\0\0\0\0\0\0\0\0\0 \0²\0\0\0\0¹■■■■\0\0\0▮¹■■▒■ ■■■」!■\0\0\0▮■■▮\0■!■■■■!■\0\0²\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0⁷⁷⁷⁷⁷\0\0\0\0⁷⁷⁷\0\0\0\0\0⁷⁵⁷\0\0\0\0\0⁵²⁵\0\0\0\0\0⁵\0⁵\0\0\0\0\0⁵⁵⁵\0\0\0\0⁴⁶⁷⁶⁴\0\0\0¹³⁷³¹\0\0\0⁷¹¹¹\0\0\0\0\0⁴⁴⁴⁷\0\0\0⁵⁷²⁷²\0\0\0\0\0²\0\0\0\0\0\0\0\0¹²\0\0\0\0\0\0³³\0\0\0⁵⁵\0\0\0\0\0\0²⁵²\0\0\0\0\0\0\0\0\0\0\0\0\0²²²²\0²\0\0\n⁵\0\0\0\0\0\0\n゜\n゜⁸\0\0\0⁷³⁶⁷²\0\0\0⁵⁴²¹⁵\0\0\0\0⁴²◀\t◀\0\0²¹\0\0\0\0\0\0²¹¹¹¹²\0\0²⁴⁴⁴⁴²\0\0⁵²⁷²⁵\0\0\0\0²⁷²\0\0\0\0\0\0\0²¹\0\0\0\0\0⁷\0\0\0\0\0\0\0\0\0²\0\0\0⁴²²²¹\0\0\0⁶\t\rᵇ⁶\0\0\0²³²²⁷\0\0\0⁷ᶜ⁶¹ᶠ\0\0\0⁷ᶜ⁶⁸ᶠ\0\0\0⁵⁵ᶠ⁴⁴\0\0\0ᶠ¹⁶ᶜ⁷\0\0\0⁴²⁷\t⁶\0\0\0ᶠ⁸⁴²²\0\0\0⁶\t⁶\t⁶\0\0\0⁶\tᵉ⁴²\0\0\0\0²\0²\0\0\0\0\0²\0²¹\0\0\0⁴²¹²⁴\0\0\0\0⁷\0⁷\0\0\0\0¹²⁴²¹\0\0\0²⁵⁴²\0²\0\0²⁵⁵¹⁶\0\0\0\0⁶⁸ᵇ⁶\0\0\0¹⁵\t\t⁶\0\0\0\0⁶¹¹⁶\0\0\0⁸\n\t\t⁶\0\0\0\0ᵉ\t⁵ᵉ\0\0\0ᶜ²ᵉ³²¹\0\0\0ᵉ\t\r\n⁴\0\0¹⁵ᵇ\t\t⁴\0\0²\0³²²⁷\0\0\0ᶜ⁸⁸\t⁶\0\0¹\t⁵ᵇ\t⁴\0\0¹¹¹¹⁶\0\0\0\0\n▶‖‖\0\0\0\0⁶\t\t\t\0\0\0\0⁶\t\t⁶\0\0\0\0⁶\t\t⁵¹\0\0\0⁶\t\t\n⁸\0\0\0\rᵇ¹¹\0\0\0\0ᵉ³⁸ᶠ\0\0\0\0²ᵉ³²ᶜ\0\0\0\t\t\t⁶\0\0\0\0\t\t⁵³\0\0\0\0‖‖‖ᵇ\0\0\0\0\t⁶⁴\t\0\0\0\0\t\tᵇ⁴³\0\0\0⁷⁴²⁷\0\0\0³¹¹¹¹³\0\0¹¹³²²\0\0\0⁶⁴⁴⁴⁴⁶\0\0²⁵\0\0\0\0\0\0\0\0\0\0⁷\0\0\0²⁴\0\0\0\0\0\0⁶\tᵇ\r\t\t\0\0⁶\t⁵ᵇ\t⁷\0\0⁶\t¹¹\t⁶\0\0³⁵\t\t\t⁷\0\0⁶¹⁵³\t⁶\0\0⁶¹⁵³¹¹\0\0⁶¹¹\r\t⁶\0\0⁵⁵⁵⁷⁵⁵\0\0⁷²²²²⁷\0\0ᵉ⁸⁸⁸\t⁶\0\0\t\t⁵ᵇ\t\t\0\0²¹¹¹\t⁷\0\0\n▶‖‖‖‖\0\0\nᵇ\r\t\t\t\0\0⁶\t\t\t\t⁶\0\0⁶\t\t\r¹¹\0\0⁶\t\t\t\r\n\0\0⁶\t\t⁵ᵇ\t\0\0ᵉ³⁶⁸⁸⁷\0\0ᶜ³²²²²\0\0\t\t\t\t\t⁶\0\0\t\t\t\t⁵³\0\0‖‖‖‖▶\r\0\0\t\t\t⁶\t\t\0\0\t\t\tᵇ⁴³\0\0⁷⁴²¹¹⁷\0\0⁶²³²⁶\0\0\0²²²²²\0\0\0³²⁶²³\0\0\0\0²‖ᶜ\0\0\0\0\0²⁵²\0\0\0\0○○○○○\0\0\0U*U*U\0\0\0、>*⁘、\0\0\0>ccw>\0\0\0■D■D■\0\0\0⁴<、゛▮\0\0\0⁸*>、、⁸\0\0006>>、⁸\0\0\0、\"*\"、\0\0\0、、>、⁘\0\0\0、>○*:\0\0\0>gcg>\0\0\0○]○A○\0\0\0008⁸⁸ᵉᵉ\0\0\0>ckc>\0\0\0⁸、>、⁸\0\0\0\0\0U\0\0\0\0\0>scs>\0\0\0⁸、○>\"\0\0\0「$JZ$「\0\0>wcc>\0\0\0\0⁵R \0\0\0\0\0■*D\0\0\0\0>kwk>\0\0\0○\0○\0○\0\0\0UUUUU\0\0\0ᵉ⁴゛-&\0\0\0■!!%²\0\0\0ᶜ゛  、\0\0\0⁸゛⁸$¥\0\0\0N⁴>E&\0\0\0\"_□□\n\0\0\0゛⁸<■⁶\0\0\0▮ᶜ²ᶜ▮\0\0\0\"z\"\"□\0\0\0゛ \0²<\0\0\0⁸<▮²ᶜ\0\0\0²²²\"、\0\0\0⁸>⁸ᶜ⁸\0\0\0□?□²、\0\0\0<▮~⁴8\0\0\0²⁷2²2\0\0\0ᶠ²ᵉ▮、\0\0\0>@@ 「\0\0\0>▮⁸⁸▮\0\0\0⁸8⁴²<\0\0\0002⁷□x「\0\0\0zB²\nr\0\0\0\t>Kmf\0\0\0¥'\"s2\0\0\0<JIIF\0\0\0□:□:¥\0\0\0#b\"\"、\0\0\0ᶜ\0⁸*M\0\0\0\0ᶜ□!@\0\0\0}y■=]\0\0\0><⁸゛.\0\0\0⁶$~&▮\0\0\0$N⁴F<\0\0\0\n<ZF0\0\0\0゛⁴゛D8\0\0\0⁘>$⁸⁸\0\0\0:VR0⁸\0\0\0⁴、⁴゛⁶\0\0\0⁸²> 、\0\0\0\"\"& 「\0\0\0>「$r0\0\0\0⁴6,&d\0\0\0>「$B0\0\0\0¥'\"#□\0\0\0ᵉd、(x\0\0\0⁴²⁶+」\0\0\0\0\0ᵉ▮⁸\0\0\0\0\n゜□⁴\0\0\0\0⁴ᶠ‖\r\0\0\0\0⁴ᶜ⁶ᵉ\0\0\0> ⁘⁴²\0\0\0000⁸ᵉ⁸⁸\0\0\0⁸>\" 「\0\0\0>⁸⁸⁸>\0\0\0▮~「⁘□\0\0\0⁴>$\"2\0\0\0⁸>⁸>⁸\0\0\0<$\"▮⁸\0\0\0⁴|□▮⁸\0\0\0>   >\0\0\0$~$ ▮\0\0\0⁶ &▮ᶜ\0\0\0> ▮「&\0\0\0⁴>$⁴8\0\0\0\"$ ▮ᶜ\0\0\0>\"-0ᶜ\0\0\0、⁸>⁸⁴\0\0\0** ▮ᶜ\0\0\0、\0>⁸⁴\0\0\0⁴⁴、$⁴\0\0\0⁸>⁸⁸⁴\0\0\0\0、\0\0>\0\0\0> (▮,\0\0\0⁸>0^⁸\0\0\0   ▮ᵉ\0\0\0▮$$DB\0\0\0²゛²²、\0\0\0>  ▮ᶜ\0\0\0ᶜ□!@\0\0\0\0⁸>⁸**\0\0\0> ⁘⁸▮\0\0\0<\0>\0゛\0\0\0⁸⁴$B~\0\0\0@(▮h⁶\0\0\0゛⁴゛⁴<\0\0\0⁴>$⁴⁴\0\0\0、▮▮▮>\0\0\0゛▮゛▮゛\0\0\0>\0> 「\0\0\0$$$ ▮\0\0\0⁘⁘⁘T2\0\0\0²²\"□ᵉ\0\0\0>\"\"\">\0\0\0>\" ▮ᶜ\0\0\0> < 「\0\0\0⁶  ▮ᵉ\0\0\0\0‖▮⁸⁶\0\0\0\0⁴゛⁘⁴\0\0\0\0\0ᶜ⁸゛\0\0\0\0、「▮、\0\0\0⁸⁴c▮⁸\0\0\0⁸▮c⁴⁸\0\0\0"
  -- enable custom font
  poke(0x5f58,0x81)

  -- enable tile 0 + extended memory
  poke(0x5f36, 0x18)
  -- capture mouse
  -- enable lock
  poke(0x5f2d,0x7)

  cartdata("freds72_daggers")

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


