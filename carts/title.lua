-- globals
local _entities={}

local title_img="◝◝ヲ○◝◝♥や²うめ◝◝ネり◝ョヘ○フ█ュaりaᶠ◝ネれス~□ ヌ\0▮B★▮\n$◆◜0∧⁸	\n@BるHカDロ\0、█\0█`$?ワ…t█▤▮`BPHY◀D✽「1 \0♥◝そcらN@゜⬅️wXけBC★▮◝ムbQ\0ナ\0\n○◝ス。³◝◝◝◝◝マ3◆チ◝◝I◝き◝◜セラ○□エら◝◜qオLセ○░チ@つセ◝ュC█さHた◝😐⬇️⌂Y▶こ◝ホゅ➡️\n○マL,Hえ゜ョウ\"@Cロル\0ョょENᶠ◜f$☉ᶠク…*t~░)🅾️Oョす\"HCリd…かの~d⁘c⧗◝1☉そcレヒ,🅾️ャら2~つま⁵NOュ&⁘SヲオさフQカPかろつ@ノ◝ᶜC゜ん0)9XおQ▮かもな\nr○⁶!◆ヌHEのs(|ᵇ$ョハpS⧗レ8!◆ヌHI#▥゜▤,⧗ワ➡️り🅾️ᶠアわ1ュI	$s#レ⁵?웃'⁶9=)そ♥ワd★ょ8ˇャ🐱I?✽✽こ⬇️。⁘を?ょ$∧ゃ⬆️○▮のOマW⁷⁷⁶)😐○★BI」!ュ∧ゃ?キう▤⁘ひcュ★□Yfち◜ゃ%'ロqF1カゃ◜セ%へMiョ∧ょ?れこの▤んョ#Uあつャ-の○せ&1そんョdあセ2◝し★⧗◝¹hナナノ◝りdあょ?リゃ	◝。¥⁘ノ◝れ#웃⁴◝イ$'◜³これ⬇️◝ᶜ⧗い$ぬ◜ウ*?ユえ⁘す?ヨっマI◆ュVI◝☉ノケp○ヌの;★X○'(Oュ19けうかヲけᵉノ▤ョエᶠュ2Nっr○ネ…*ᵇ$んマ@p○ヌ★tS⬇️◝、…Xq$んヒXr○ネ★tᵉOュˇ■‖&Bcネ\"さ◝ク$ヘ「◝ゅ🐱BC░「ヘニ1◝すGPナ◝ょQ!aア◆◝ナゃ:⁶?ラスHhr⬇️ラNᶠョ2?⁙◝4@♥\0ヒGゃカOュゃヲ゜ッ*▮ヘ●➡️ソx○マ웃ヨ◝けりᶠJ$Tッけかンさ|○ヘのE★~0$Oろせ◜⬇️ネ◝L!◝ュヲ|○マ█◝ケ○ホ>?レ$のOり□I$レ1◝けIヨ◝ちIᶠり:★~'◜こネ◝\\◀。ろ★N)9,◆ョ)ヲ゜ャ$⬅️ᵉK$モI⬅️#◝Z|○メヌD⁸AさDN⁙た'◜ひュᶠョキB⁙$Hえせ)◝まッ◆ョのD⧗お$E=Oョゃン゜ャカax웃、。せ◜ノュエ◜HHX☉えI⁷◜ルュエ◜ ☉AソI゜ュ\"~g◝4✽N◆◜➡️?C◝★u⁙⬆️▮◝ト$ョO◝\0ル◝ツ⬇️レ?ャれユ?ワCワこ◝😐😐\0²⧗◝t?⧗◝|➡️\nv!◝ひ◜エ◜⁷◝ユᶠル◝◝a◜か◝ヘこ◝¹◝◜cル♥ヌ○◝…ョAヲかつPXxb🐱るるるるれ゜★~…ュエキ9D█▤⁴♥²▮▮▮▮▮▮…ッれル!ンかすきA\0▮ミ\0ぬ███ま⁷んモᶠサ◆ろ`BC∧ナうき~Pフ⁷⬆️○⁴?sハヒゅ゜ウ⁸⁸⁵¹E♥Gルcワ=➡️れ/'rよ⁸XXAら⁵:★○+ゃャか9L□、▮ヘQく¹¹(²C⬇️ッ;?z?◝う○Gせラ○◝0◜◆ら◜h◝◜'\0◜◆っ◜ヘ◝ャGュ~♥ャG◝z?ユかね◝🐱◆◜g◜3ヲ?ヨQ◝へ◆ュgル○ノナ゜ヲヲ⁷◜S◜?リ○ネ\0\0\0³◝9◝😐◝◝)◝⬆️◝◝」ッN_の○◝tョエナ◝◜セャし?d◝◜ゃャせ⁷ユか◝ク?░ム◜⧗◝ンせルか゜ゅ○◝,◜⧗ヨ?ひ◝◜)ョせヘ○た◝ヲ◝Sワ?ユせ◝C◝□○'◜4◝チ○ネOュ⁷◜さョエョI◝⬆️◝◝」ッ4?C◝ャせメ\n~♥◝ロエスノョ◆◝マかみホッか◝ク?sヨ?⧗◝ン⁷ラ~んラ○◝ᶜ◜エナ◝ᶠ◝Gュ○♥ッ○ラ?ユ゜ヲOュg◜s◝!◝😐◝オ○'◜⧗◝Y◝ョ⧗◝➡️◝ョc◝た◝ョ⁙◝ニ◝ュ⧗◝ヲg◝ヨᶠ◝ハ゜◜エ◝ム゜ッᶠ◝リかカ◝◝ワ`"

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

-- px9 decompress

-- x0,y0 where to draw to
-- src   compressed data address
-- vget  read function (x,y)
-- vset  write function (x,y,v)

function px9_decomp(x0,y0,src,vget,vset)
  local idx=1
	local function vlist_val(l, val)
		-- find position and move
		-- to head of the list

--[ 2-3x faster than block below
		local v,i=l[1],1
		while v!=val do
			i+=1
			v,l[i]=l[i],v
		end
		l[1]=val
--]]

--[[ 7 tokens smaller than above
		for i,v in ipairs(l) do
			if v==val then
				add(l,deli(l,i),1)
				return
			end
		end
--]]
	end

	-- bit cache is between 8 and
	-- 15 bits long with the next
	-- bits in these positions:
	--   0b0000.12345678...
	-- (1 is the next bit in the
	--   stream, 2 is the next bit
	--   after that, etc.
	--  0 is a literal zero)
	local cache,cache_bits=0,0
	function getval(bits)
		if cache_bits<8 then
			-- cache next 8 bits
			cache_bits+=8      
			cache+=ord(src,idx)>>cache_bits
			idx+=1
		end

		-- shift requested bits up
		-- into the integer slots
		cache<<=bits
		local val=cache&0xffff
		-- remove the integer bits
		cache^^=val
		cache_bits-=bits
		return val
	end

	-- get number plus n
	function gnp(n)
		local bits=0
		repeat
			bits+=1
			local vv=getval(bits)
			n+=vv
		until vv<(1<<bits)-1
		return n
	end

	-- header

	local
		w,h_1,      -- w,h-1
		eb,el,pr,
		x,y,
		splen,
		predict
		=
		gnp"1",gnp"0",
		gnp"1",{},{},
		0,0,
		0
		--,nil

	for i=1,gnp"1" do
		add(el,getval(eb))
	end
	for y=y0,y0+h_1 do
		for x=x0,x0+w-1 do
			splen-=1

			if(splen<1) then
				splen,predict=gnp"1",not predict
			end

			local a=y>y0 and vget(x,y-1) or 0

			-- create vlist if needed
			local l=pr[a] or {unpack(el)}
			pr[a]=l

			-- grab index from stream
			-- iff predicted, always 1

			local v=l[predict and 1 or gnp"2"]

			-- update predictions
			vlist_val(l, v)
			vlist_val(el, v)

			-- set
			vset(x,y,v)
		end
	end
end


function draw_things(things,cam,fov,lightshift)
  local lightshift=lightshift or 1
  local m,cx,cy,cz=cam.m,unpack(cam.origin)
  local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]

  local cache={}

  local function project_array(array)
    for i,obj in inext,array do
      local origin=obj.origin  
      local oy=origin[2]
      local x,y,z=origin[1]-cx,oy-cy,origin[3]-cz
      local ax,az=m1*x-m5*cy+m9*z,m3*x-m7*cy+m11*z
      
      -- draw shadows (y=0)
      if not obj.shadeless then
        local ay=m2*x-m6*cy+m10*z
        if az>8 and az<128 and 0.5*ax<az and -0.5*ax<az and -0.5*ax<az and 0.5*ay<az and -0.5*ay<az then
          -- thing offset+cam offset              
          local w,a=fov/az,atan2(x,z)
          local a,r=atan2(x*cos(a)+z*sin(a),cy),obj.radius*w>>1
          local x0,y0,ry=63.5+ax*w,63.5-ay*w,r*sin(a)
          ovalfill(x0-r,y0+ry,x0+r,y0-ry)
        end
      end
  
      -- 
      ax+=m5*oy
      az+=m7*oy
      local ay=m2*x+m6*y+m10*z
      if az>8 and az<192 and 0.5*ax<az and -0.5*ax<az and 0.5*ay<az and -0.5*ay<az then
        local w=fov/az
        cache[#cache+1]={key=w,thing=obj,x=63.5+ax*w,y=63.5-ay*w}      
      end
    end
  end
  -- 
  -- render shadows (& collect)
  poke(0x5f5e, 0b11111110)
  color(1)
  project_array(things)
  poke(0x5f5e, 0xff)
  
  rsort(cache)

  -- default transparency
  palt(15,true)
  palt(0,false)
  -- render
  local pal0
  for _,item in inext,cache do        
    local thing=item.thing
    local pal1=min(15,(lightshift*item.key)<<4)\1
    if(pal0!=pal1) memcpy(0x5f00,0x8000|pal1<<4,16) palt(15,true) pal0=pal1   
    -- draw things
    local w0,entity,origin=item.key,thing.ent,thing.origin
    -- zangle (horizontal)
    local dx,dz,yangles,side,xflip,yflip=cx-origin[1],cz-origin[3],entity.yangles,0
    local zangle=atan2(dx,-dz)
    if yangles!=0 then
      local step=1/(yangles<<1)
      side=((zangle-thing.zangle+0.5+step/2)&0x0.ffff)\step
      if(side>yangles) side=yangles-(side%yangles) xflip=true
    end

    -- up/down angle
    local zangles,yside=entity.zangles,0
    if zangles!=0 then
      local yangle,step=thing.yangle or 0,1/(zangles<<1)
      yside=((atan2(dx*cos(-zangle)+dz*sin(-zangle),-cy+origin[2])-0.25+step/2+yangle)&0x0.ffff)\step
      if(yside>zangles) yside=zangles-(yside%zangles) yflip=true
    end
    -- copy to spr
    -- skip top+top rotation
    local frame,sprites=entity.frames[(yangles+1)*yside+side+1],entity.sprites
    local base,w,h=frame.base,frame.width,frame.height
    for i=0,(h-1)<<6,64 do
      poke4(i,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
      base+=4
    end
    w0*=(thing.scale or 1)
    local sx,sy=item.x-w*w0/2,item.y-h*w0/2
    local sw,sh=w*w0+(sx&0x0.ffff),h*w0+(sy&0x0.ffff)
    --
    sspr(frame.xmin,0,w,h,sx,sy,sw,sh,xflip,yflip)    
  end
end

function menu_state(buttons,default)
  local skulls,ent={},_entities.skull
  -- leaderboard/retry
  local over_btn,clicked
  
  -- get actual size
  clip(0,0,0,0)
  for _,btn in pairs(buttons) do
    btn.width=print(btn[1])
    btn.x=-btn.width-2
  end
  clip()
  -- position cursor on "default"
  default=default or 1
  active_btn=buttons[default]
  local _,y=unpack(active_btn)
  local mx,my=1+active_btn.width/2,y+3

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

  return
    -- update
    function()
      mx,my=mid(mx+stat(38)/2,0,127),mid(my+stat(39)/2,0,127)
      -- over button?
      over_btn=-1
      for i,btn in pairs(buttons) do
        local x,_,y=1,unpack(btn)          
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
      cam:track({0,128,-64},make_m_from_euler(0,0,0)) 

      if #skulls<40 then
        local s=add(skulls,{
          ent=_entities.skull,
          origin={-12+rnd(24),0,-6+rnd(12)},--0.5+rnd()/2},
          velocity={(1-rnd(2))/12,rnd(0.8)+0.2,0},
          zangle=rnd(),
          yangle=rnd(),
          yangle_vel=rnd()/64,
          shadeless=true
        })
        -- sort key        
        s.key=10+8*s.origin[3]
      end      

      for i=#skulls,1,-1 do
        local s=skulls[i]
        s.origin=v_add(s.origin,s.velocity)
        if s.origin[2]>200 then
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

      -- 
      draw_things(skulls,cam,64,0.8)

      pal()
      
      -- draw menu & all
      for i,btn in pairs(buttons) do
        btn.x=lerp(btn.x,2,0.4)
        local s,y=unpack(btn)        
        arizona_print(s,btn.x,y,i==over_btn and 1)
      end
      if(active_btn.draw) active_btn:draw()

      -- mouse cursor
      spr(20,mx,my)
      -- hw palette
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end,
    function() reload() end
end

-- main menu buttons
local _starting
local _main_buttons={
  {"pLAY",48,cb=function()      
    -- avoid reentrancy
    if(_starting) return
    _starting=true
    music(-1,250)
    -- todo: fade to black
    do_async(function()
      wait_async(10)
      next_state(play_state)
    end)
  end},
  {"lEADERBOARD",64,
    cb=function(self) 
      leaderboard_state()
    end},
  {"eDITOR",74,
    cb=function(self) 
      load("editor_mini.p8")
      load("editor.p8")
    end},
  {"cREDITS",84,
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
      startx[i]=lerp(startx[i],endx[i],0.4)
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
    {"bACK",111,
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
  local delay_print=delayed_print({"cODE & GFX: fREDS72","mUSIC & SFX: rIDGEK", "fONT: LITHIFY BY SOMEPEX","","tHANKS TO:","sORATH","aRTYOM bRULLOV","..."},true)
  next_state(menu_state,{
    {"bACK",111,
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
  local fov=64
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
  local a=rnd()
  local angle,dangle={0,a-0.25+rnd(0.1),0},v_zero()
  local tilt=0
  local velocity=v_zero()
  local origin={192*cos(a),0,192*sin(a)}
  local eye_pos=v_add(origin,split"0,24,0")
  local launching

  local plane={
    {0,0,0},
    {0,0,8},
    {8,0,8},
    {8,0,0},
  }
  local function draw_radius(r,light)
    local r2=r*r
    memcpy(0x5f00,0x8000|(light\0.0625)*16,16)
    for y=0,63 do
      local yy=31.5-y
      local d=r2-yy*yy
      if d>=0 then
        local x=sqrt(d)
        sspr(32-x,32+y,2*x,1,96-x,32+y)
      end
    end
  end

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

      -- player close to dagger?
      if not launching and v_len(origin,{0,0,0})<16 then
        -- avoid reentrancy
        launching=true
        do_async(function()
          -- todo: fade to red? black?
          for i=1,24 do
            fov=lerp(fov,32,0.3)
            yield()
          end
          load("daggers_mini.p8")
          load("daggers.p8")
        end)
      end
    end,
    -- draw
    function()
      cls()
      local m,cx,cy,cz=cam.m,unpack(cam.origin)
      local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]
      local verts,outcode,nearclip={},0xffff,0  
      local r0=-4*16
      for i,v0 in inext,plane do
        local code,x,y,z=2,r0+16*v0[1]-cx,v0[2]-cy,r0+16*v0[3]-cz
        local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
        if(az>8) code=0
        if(az>384) code|=1
        if(-ax>az) code|=4
        if(ax>az) code|=8
        
        local w=fov/az 
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
              v.x=63.5+fov*v[1]/8
              v.y=63.5-fov*v[2]/8
              v.w=fov/8
              v.u=lerp(v0.u,v1.u,t)
              v.v=lerp(v0.v,v1.v,t)
              res[#res+1]=v
            end
            v0,d0=v1,d1
          end
          verts=res
        end

        -- texture
        poke4(0x5f38,0x3800.0808)   

        -- light effect
        poke(0x5F55,0x00)
        local r=abs(cos(time()/8))
        draw_radius(32-r*r,0.5)
        r+=0.2
        draw_radius(32-r*r,0.7)
        r+=0.6
        draw_radius(32-r*r,0.99)
        poke(0x5F55,0x60) 

        mode7(verts,#verts,1)        
      end

      draw_things({
        {
          ent=_entities.dagger,
          origin={0,24+3*cos(time()/4),0},
          yangle=0,
          zangle=0,
          radius=12
        }
      },cam,fov)

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

      --[[
      local s="HUM...cURSED?"
      print(s,64-print(s,0,130)/2,2,6)
      
      local s="cOMING SOON ON PICO8..."
      print(s,64-print(s,0,130)/2,122,8)
      ]]

      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

function title_state()
  cls()
  -- going to take a while..don't refresh
  holdframe()
  px9_decomp(0,0,title_img,pget,pset)

  local ttl,launching=900
  return
    -- update
    function()
      ttl-=1
      if not launching and ttl<0 or btnp()&0x30!=0 then
        launching=true
        do_async(function()
          -- todo: fade to black
          next_state(menu_state, _main_buttons)
        end)
      end
    end,
    -- draw
    function()
      -- apply 
      pal({[0]=0, 130, 2, 8, 136, 128, 7},1)
    end
end

-- entry points
function _init()
  -- generate assets if not there
  if reload(0x6000,0x0,0x1,"pic_0.p8")==0 then
    load("editor_mini.p8","","generate")
    load("editor.p8","","generate")
  end

  -- custom font
  -- source: https://somepx.itch.io/humble-fonts-tiny-ii
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

  -- load background assets
  decompress("pic",0,0,function()
    local names={
      [1]="skull",
      [7]="dagger"
    }
    -- drop array size
    for i=1,mpeek2() do
      local id,sprites,angles=mpeek(),{},mpeek()    
      local ent={  
        sprites=sprites,   
        yangles=angles&0xf,
        zangles=angles\16,        
        frames=unpack_frames(sprites)
      }
      local name=names[id]
      if name then
        _entities[name]=ent
      end
    end
  end)
  reload()

  -- background music
  music(8)
  
  -- init game
  next_state(title_state)
end

function _update()
  update_asyncs()
  _update_state()
end


