-- globals
local _entities={}
local _hw_pal=0

local title_img="◝◝ヲ○◝◝♥テ█➡️け◝k○◝◝ュ█?◝やᶠュユ゜😐8,!◝ュx{ᶠるD、@²⁸RB¹D➡️◝を□り¹!H⁸XI¥(おら³…\0▮ᶜ⁴♥◜ラᵉ…⁙²ᶜ⁸J	ᵇ\"っ…こ⁶$\0▮◝レᶜx	っ³ヨnミ⁘HHrB゜ョ😐J 、\0¹O◝ャ³き○◝◝◝◝ョIqユり◝◜う、\rを♪`dの$\0◝◜ニ■Q³」3ょ\0…ヒ%サ/◝ル(さ😐⬅️mけ▶ノ▒')n³U…♥◝ヨ!‖$5ユ★ミ⁴ョ8⁴わのaA⁸♪ᶠ◝る🐱へ▥{れSト\0•まめ[R♪-ねRを♥◝x⁶5rふ□)⁷t$む マLヤD✽D▤Rを゜ュゃHア\"★#HtH☉░フ█m▮BBろq8★U♥◜キけゃ\n、ゃ³웃‖ら…⁸Oら▤¥I²っ☉FXDつ⁙◝1➡️けをS▤4W「Jうリら8K■⁷!Zᵇ□A\"-Oュ&•░⁴!¹$も웃!9まムノおBH8◀ハヌテ+웃'ヲaヲY5➡️²➡️E-²Zf♪ハ¥くア★■³🐱pけょ!V7ユjG■ nRᶜ⬆️░➡️アぬか³⌂웃Qi\"⁵ᵉ\"く9?S█Mり⁴'	▮▮[□'S?8!ᵉ⁷□Hq$➡️bZ░9?3☉²(ゆ⁴\n^⁴■\r#ワ░☉⁸!,	て。@N◆L(け□ᵉ⁴4♥4Kᵉ▮~t⁴8カ□「🐱²D⁸ᵉᵉ😐K⁸🐱😐³さニ⁸そキ?う\n(BI⁸★@$☉を⁙⧗◀□Bる□る⁸xろネDp!ン。2ノナノ⌂▮のT)っ)&,😐L▮◀A4A,8AャらH!$I□D⬇️I&…く…ん5&DKb\"Dね$$A	D◀゜くて$DE➡️わ¹★N□⌂ア\\Eぬᵉ¹ 6ぬA☉たオ?そA▮ \"$▤の4JS▶■⁸j웃➡️8,▮P)イ⁸|r▒PD★⌂4!!\"C⬇️BらK⁸▮…¹B	ᵉ🐱「せメ\rっB⁙D…⁴さ░D█4%\"■ け q²すそQ□XsGオ◀	⁸☉□カ	Rn□A⁷も…8▮(웃`░ろ▒ろ□➡️)Oテ웃░\r¹⁘⁸□ヘ░@りaH♪⁸⁷‖\"¥るC▶🐱@ひvZ⁴I	!ゃ¹$★∧⁴く⁶)▮!■⁙⬆️R %@「u⁴▒¹っJ`,)4□²	▮%、ら⬆️░ナ🐱ノ⁸yけ,⌂なく$なさHB「ん⁵ナ☉H▒$HI.⁴⁴の=の⁴░D'⁸FへA■Q*▮('□$\0웃ᵇA、り「うり%2I ぬ🐱🅾️🐱j★B□Wナ◀ᵉケT⁸I,E✽ノ░ね¹	*K☉\n゛!\0!\0□⁴¥さ²A)く:カ¹\"\"I\0B⁸░ナ X★…▒■E✽²\n웃ˇ$G■⁴▮u□⬆️I⁸II⁘Ta⁶★⁵'□BX	ら$]²L➡️■eX-、\"9のH そ…²つA$☉4★Dれふ⁴ᶜ¹ゅ-➡️*りEキ\"り□A▒$A\"ゅKH…く(☉のてへY²D	□⁘ケ!ケしEノ	☉⁸░XDiV⁴⁸ ▮さヒ▮QT♪◀M\0e$🐱ᵇら▮ぬTBDQ	D⬇️█⁴	y\"▮@➡️゜⬆️★웃!#▒aPhU¹イI□ B。@✽★とˇろし,の9□えさひ ★\"\0◀□くAI%★■*ワ★%HLr9(p★し⁙▒⁴🐱➡️➡️‖!⁘(Bワ■■$BI,へ□Wミ□Q%…ロ$カ゜RD■%G█s$#ま☉⬅️さH…k□゜ケ★$くᶠi>░□⁸⁷メJ🐱ゃ⁵●\"$☉\"○…ぬp➡️=★⁴;$Kっ➡️ョれDぬ………H◝t²DXお░…ユネ■◝🅾️¹Q*N ?ユB@あG\\@Qカ!8░○ヌ웃⁸▤っHかヲMDる□I■	l★□F…Oュ★⁴っCI‖゜ンノ**Z🐱⁷‖!#▥g◜tD っKそ◝カB ∧□ \"W2$は◝N☉$M░T○マ,⁸Kろ□そへ⁵◝シ	`D★ Y゜ッきN★P✽,⁷◜ア░웃@ら?レっXTpA@$■?レ⬆️%.ᶠ◜⁴⁷@ム…◝ケX\"⁴\" 웃◝ゆ\"りと⌂XU◝ソRケX웃%?ワ•$ねB³◝♪D%ˇ⁴5゜ャさ⬆️	Eh	%○ミ▮☉キ$(▮゜ャオ[\n⬅️!ᶠョへ¹bm³K!P◝タ#r▒0H○メ…★1H4!-★○メD⌂S\"゜ャt⁸Bし✽ね‖'◜ゃ\"$░…⬆️オ○ミの%E∧p)$★H◝ス=∧$🐱X█かン$Z█☉⬆️D∧りF□O◜6け➡️ …◝オ=⁸★U웃Q⁶■\"かャ□☉rかッらろM▮N\0さX0かッムGき⁷◜☉⁸Aる\"I9IE■!◝た*c◝q`の「Aチ⁴H²(◝サT◝シ⁴ 웃ろ⁶░うリ'U⁶NミNsNく²I\"hうろたケ$⧗Dたろ★せ⁵ サゃ8Y░¥l@yしな&mぬ◀ゅっqヲへ➡️れイe…ナん⁶Mウ🐱q|ラ&ツN2TEネ▤❎#웃8ひ⌂Kゅス🅾️9★O-「ゅBpH✽(░え.キソ¥Y\" ;おL\n▒。Mᵇ⁴ヌヨカZAeヒ⁘Cテ🐱ヒ4,なね。⁴へ、^◀⁷Rkて)¥rm∧‖L⌂つ<?゛Eつe⁙⬇️ン⬆️3▮$W3た{ほ\\sイ🅾️.も*\"Hナz~[🐱qま웃りョミj(Yo▮MᵉR,#█tちお_▶🅾️4の^⁷ュろ⬇️▥-…pS★❎∧◀■R'い]i⁸N🐱。¹⁸ニ⬅️$Aホョuxほ✽さNᵇ*▥RIク!る*R9★りツナ9「NE⧗Hヌかンひカ★(マr▮🐱ヨまuり⁙⬅️ちm▶の‖⁶Jハdの[Hう゜あ!イˇ★'⁶*Y⁸…は☉⬆️★js⁴な'、ミちyg、n.のHC⬅️jdHしH$⬇️█Y■d∧E⬅️R[$⬅️✽チFク⬅️、Y/$/,もAwIxな¥pコRAy⧗ $'\r★ 🐱¥pNg⁙M9フUれお、⁸チ░]るシ■$U➡️1ウ	⁙い🅾️ん³웃xQ\nヌシ□ゅけH,🅾️g2 ⬅️キQわけそホ³⁷も²ヲ¹くpu@わ9✽カ7$★🅾️て;…ね;✽?ュQヲR@}@レ:█Qゃ$@C◝aッh⁘⌂🅾️て!(レ0!ャHきき゜セ!ヲh!!ヲ$0:…-Dノ⬇️ヨ;➡️!カヨャXp1゛QᵉAヲ\"▮BQaン゛っ◜ノZ;ぬロ@♥`C▥◀□れ⌂$?ャカル□=♥ナᶠわ,O$	ᶠョpひ~W ミ…?*=Jか♪◀⁸yᵇᶠくわ゜➡️🅾️$⁸vノi\0!ゃb~to@ᶠ!くx⁷ホGゃᵉム…y⁙み。゜🅾️ᶠ|\0XZ?cヨオ{ J4✽゜😐▒◝こ³⁷ヤGr▮Qチ▒\np∧◆セ?◜゜あCケ♥ ホ)ンっせ◝CCみ\n!ツ░;⁘t⌂▮ュ$S◝q!ンさ=LzSさせミ#らᶠル…ュ$(♥zᵉあ。 ヨ、³ロ…░♥ら⁘ヒ゜ちCめ⁸u\"え\"◆□カ◜っ…Bれョヒ²C⬆️♥웃ゃヌ(ヨ-◀゜◜8⁴=ぬ♥iホマ(ン⁘○レナ▮オヒる゛せヌx⬆️モE⁘○ヤけ¥゛さ=Oケン⁘w\"🅾️¹ケ?ゆ@オュ,!マ~フゃOdᵉ:¹くア'█\rGニろ⁸~	ョか\"◆わ<り9²Cはルぬノレ?ユおしこレ@⁷⁵?⁸{aゃヲ'◜3ルナ゜⬆️웃	ᵉaャhNᶠわ?レか⌂(◝ネG'ゃ◝っュ➡️ら?て□•█cリO◜せマ◆チ\0\0CB`んヘか◝Oセ?8~Gヒか◝ろ?リ'⁷ラか◝ょ?ョ゜◝セ?リかュら"

-- px9 decompress

-- x0,y0 where to draw to
-- src   compressed data address
-- vget  read function (x,y)
-- vset  write function (x,y,v)

function px9_decomp(x0,y0,src,vget,vset)
  local isaddr = type(src) == "number"
  local idx = isaddr and src or 1

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
			cache+=(isaddr and @idx or ord(src,idx))>>cache_bits
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
    local r_scale=-sin(0.625+cam.angles[1]/2)*atan2(0,cy)
    for i,obj in inext,array do
      local origin=obj.origin  
      local oy=origin[2]
      local x,y,z=origin[1]-cx,oy-cy,origin[3]-cz
      local ax,az=m1*x-m5*cy+m9*z,m3*x-m7*cy+m11*z
      
      -- draw shadows (y=0)
      if not obj.shadeless then
        local ay=m2*x-m6*cy+m10*z
        if az>8 and az<128 and 0.5*ax<az and -0.5*ax<az and 0.5*ay<az and -0.5*ay<az then
          -- thing offset+cam offset              
          local w=fov/az
          local a,r=atan2(az,-cy),obj.radius*w>>1
          local x0,y0,ry=63.5+ax*w,63.5-ay*w,-r*sin(a)
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
    if(pal0!=pal1) memcpy(0x5f00,0xc180+(pal1<<4),16) palt(15,true) pal0=pal1   
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

function btn_x(btn)
  local x=btn.x or 2    
  if(type(x)=="function") x=x(btn)
  return x
end
function btn_static(btn)
  local s=btn.static
  if(type(s)=="function") s=s(btn)
  return s
end

local _skulls={}
function menu_state(buttons,default)
  local ent=_entities.skull
  -- leaderboard/retry
  local over_btn,clicked
  -- reset hw palette offset
  _hw_pal=0
  for btn in all(buttons) do
    local txt=btn[1]
    if(type(txt)=="function") txt=txt(btn)
    btn.width=print(txt,0,512)
    if btn_x(btn)>64 then
      btn._x=130
    else
      btn._x=-btn.width-2
    end
  end
  -- position cursor on "default"
  over_btn=default or 1
  local active_btn,prev_button=buttons[over_btn]
  local _,y=unpack(active_btn)

  local cam=setmetatable({
    origin=v_zero(),    
    track=function(_ENV,_origin,_m)
      --
      angles={0,0,0}
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
      if not stat"57" then
        --play musiciii
        audio_load"musiciii"
        music(0, 1000)
      end
      
      if not _mx then
        _mx,_my=stat(32),stat(33)
      else
        _mx,_my=mid(_mx+stat(38)/2,0,127),mid(_my+stat(39)/2,0,127)
      end

      -- not polling for custom keys?
      if not _active_btn then
        -- keyboard override?
        local keyboard
        if btnp(2) or btnp(0) then
          keyboard=true
          over_btn-=1
          if(over_btn<1) over_btn=#buttons
        elseif btnp(3) or btnp(1) then
          keyboard=true
          over_btn=max(over_btn+1,1)
          if(over_btn>#buttons) over_btn=1
        end
        -- teleport mouse
        if keyboard then
          if(over_btn==-1) over_btn=1
          local btn=buttons[over_btn]
          if btn then
            local _,y=unpack(btn)
            _mx,_my=1+btn.width/2,y+3
          end
        end
      end

      -- over button?
      over_btn=-1
      for i,btn in inext,buttons do
        if not btn_static(btn) then
          local x,_,y=btn_x(btn),unpack(btn)          
          if _mx>=x and _my>=y and _mx<=x+btn.width and _my<=y+6 then            
            over_btn=i
            -- click?
            if not clicked and btnp(5) then
              active_btn=btn
              btn:cb()
              ui_sfx"3"
              -- todo: fix
              clicked=nil
            end
            break
          end
        end
      end
      -- new over?
      if over_btn!=-1 and prev_button!=over_btn then
        ui_sfx"0"
      end
      prev_button=over_btn

      -- skull background        
      cam:track({0,128,-64},make_m_from_euler(0,0,0)) 

      if #_skulls<40 then
        local s=add(_skulls,{
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

      for i=#_skulls,1,-1 do
        local s=_skulls[i]
        s.origin=v_add(s.origin,s.velocity)
        if s.origin[2]>200 then
          deli(_skulls,i)          
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
      fillp(0xc5a5)
      ovalfill(0,128-r0,127,128+r0,1)
      fillp()
      ovalfill(r0/3,128-r0*0.95,127-r0/3,128+r0*0.95,1)
      ovalfill(r0/2,128-r0*0.75,127-r0/2,128+r0*0.75,2)

      if buttons.credits then
        print("+FREDS72+",2,2,1)
        print("+RIDGEK+",90,2,1)        
      end
      -- 
      draw_things(_skulls,cam,64,0.5)

      pal()
      
      -- any background?
      if buttons.draw then
        draw_dialog()
        buttons:draw()
      end

      -- draw menu & all
      for i,btn in inext,buttons do
        btn._x=lerp(btn._x,btn_x(btn),0.4)
        local s,y=unpack(btn)  
        if(type(s)=="function") s=s(btn)
        if btn_static(btn) then
          print(s,btn._x,y,6)
        else
          arizona_print(s,btn._x,y,i==over_btn and 1 or btn.c)
        end
      end
      if(active_btn.draw) active_btn:draw()

      -- mouse cursor
      spr(5,_mx,_my)
      -- hw palette
      memcpy(0x5f10,0xc000+_hw_pal,16)
      -- pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

-- main menu buttons
local _playing
_ng_messages={
  [0]="ONLINE NOT AVAILABLE",
  "ONLINE - CHECKING",
  "ONLINE - CONNECT\161",
  "ONLINE - CONNECTING",
  "ONLINE - CONNECTED",
  [255]="ONLINE - ERROR"
}
_ng_messages_blink={
  [0]="ONLINE NOT AVAILABLE",
  "ONLINE - CHECKING",
  "ONLINE - CONNECT\168",
  "ONLINE - CONNECTING",
  "ONLINE - CONNECTED",
  [255]="ONLINE - ERROR"
}
_main_buttons={
  credits=true,
  {"pLAY",48,cb=function()      
    if(_playing) return
    _playing=true
    music(-1,1000)    
    do_async(function()
      -- fade to black
      for i=0,11 do
        _hw_pal=i<<4
        yield()
      end
      next_state(play_state)
      _playing=false
    end)
  end},
  {"lEADERBOARD",64,
    cb=function(self) 
      leaderboard_state()
    end},
  {"eDITOR",74,
    cb=function(self) 
      -- ensure dev version is loaded first then BBS
      load("freds72_daggers_editor.p8","back to title")
      load("freds72_daggers_editor_mini.p8","back to title")
      load("#freds72_daggers_editor","back to title")
    end},
  {"sETTINGS",84,
    cb=function(self)
      next_state(menu_state,_settings)
    end},
  {"cREDITS",94,
    cb=function(self) 
      credits_state()
    end},
  {msg=function()
      if(dget(43)!=0) return "ONLINE DISABLED"
      return select((2*time())%4<2 and 1 or 2,_ng_messages,_ng_messages_blink)[@0x5f81]
    end,
    function(self)
      return self:msg()    
    end,120,
    x=function(self) 
      return 127-print(self:msg(),0,512)
    end,
    static=function(self)
      return @0x5f81!=2
    end,
    cb=function(self)
      if(@0x5f81!=2) return
      if not self.connecting then
        self.connecting=true
        poke(0x5f80,2)
      end
    end
  }
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

-- commnon "dialog background"
function draw_dialog()
  poke(0x5f54,0x60)
  memcpy(0x5f00,0xc180+5*16,16)
  sspr(0,24,128,84,0,24)
  poke(0x5f54,0x00)
  pal()

  split2d([[1;24;126;24;2
1;25;126;25;1
1;109;126;109;2
1;108;126;108;1]],line)   
end

-- local leaderboard
function leaderboard_state()
  -- local score version
  local scores={}
  if dget(0)==2 then
    -- number of scores    
    local mem=0x5e08
    for i=1,dget(1) do
      -- duration (seconds)
      -- timestamp yyyy,mm,dd
      local t,y,m,d=peek4(mem,4)
      add(scores,scanf("$.\t$/$/$\t\t$S",i,y,m,d,(t<<16)/30))
      mem+=16
    end    
  end

  local delay_print=delayed_print(scores)

  next_state(menu_state,{
    {
      "bACK",111,
      cb=function() 
        -- back to main menu
        next_state(menu_state, _main_buttons)
      end,
      draw=function()
        draw_dialog()
        delay_print(function(s,x,i)
          arizona_print(s,x,23+i*7)
        end)
      end
    },
    {
      "lOCAL",16,
      cb=leaderboard_state,
      c=2
    },
    {
      "oNLINE",16,x=127-print("oNLINE",0,512),
      cb=onlineboard_state
    }
  })
end

-- online leaderboard
function onlineboard_state()
  -- local score version
  local enabled=dget(43)==0
  if enabled then
    -- force refresh
    poke(0x5f83,1)
  end

  next_state(menu_state,{
    {
      "bACK",111,
      cb=function() 
        -- back to main menu
        next_state(menu_state, _main_buttons)
      end,
      draw=function()
        draw_dialog()
        if not enabled then
          print("DISABLED IN SETTINGS",2,28,6)
        else
          local y,mem=30,0x5f91
          for i=1,@0x5f90 do
            local c=@mem&0x80!=0 and 4
            arizona_print((@mem&0x7f)..".\t"..chr(peek(mem+1,16)),1,y,c) y+=7
            arizona_print("\t"..(peek4(mem+17)*65.536).."S",1,y,c) y+=7
            mem+=21
          end
          -- no scores? (yet)
          if @0x5f83==1 then
            print("⧗",120,30,6)
          end
        end
      end
    },
    {
      "lOCAL",16,
      cb=leaderboard_state
    },
    {
      "oNLINE",16,x=127-print("oNLINE",0,512),
      c=2,
      cb=onlineboard_state
    }
  })
end

-- credits
function credits_state()
  local delay_print=delayed_print({
    "cODE & GFX: fREDS72",
    "mUSIC & SFX: rIDGEK",
    "eXTRA GFX: aRTYOM bRULLOV",
    "tITLE aRT: hERACLEUM",
    "fONT: LITHIFY BY SOMEPEX",
    "",
    "sPECIAL tHANKS TO:",
    "sORATH & zEP",
    "mISS mOUSE",
    "eXTRA TESTING: wERXZY",
    "fAMILY & PICO8 dISCORD"},true)
  next_state(menu_state,{
    {"bACK",111,
    cb=function() 
      -- back to main menu
      next_state(menu_state, _main_buttons)
    end,
    draw=function()
      draw_dialog()
      arizona_print("cREDITS",1,16,2)
      delay_print(function(s,x,i)
        arizona_print(s,x,23+i*7)
      end)        
    end}
  })
end

-- credits: https://easings.net/#easeOutElastic
function easeoutelastic(t)
  if(t==0) return 0
  if(t==1) return 1
  local c4=1/3
   return -(2^(-10*t))*sin((t*10-0.75)*c4)+1
 end

function play_state()
  local fov=64
  local cam=setmetatable({
    origin=v_zero(),    
    track=function(_ENV,_origin,_m,_angles,_tilt)
      --
      angles=_angles
      tilt=_tilt or 0
      m={unpack(_m)}		

      -- inverse view matrix
      m[2],m[5]= m[5], m[2]
      m[3],m[9]= m[9], m[3]
      m[7],m[10]=m[10],m[7]
      
      origin=_origin
    end},{__index=_ENV})
  -- set map
  for i=0,7 do
    for j=0,7 do
      mset(i,j+56,136+i+j*16)
    end
  end
  -- start above floor
  local a=rnd()
  local angle,dangle={0,a-0.25+rnd(0.1),0},v_zero()
  local tilt,on_ground,jumpp=0
  local velocity=v_zero()
  local origin={192*cos(a),0,192*sin(a)}
  local eye_pos=v_add(origin,split"0,24,0")
  local distance,launching=32000

  local plane={
    {0,0,0},
    {0,0,8},
    {8,0,8},
    {8,0,0},
  }
  local function draw_radius(r,light)
    local r2=r*r
    memcpy(0x5f00,0xc180+((light\0.0625)<<4),16)
    for y=0,63 do      
      local yy=31.5-y
      local d=r2-yy*yy
      local x=sqrt(d)
      sspr(96-x,y,2*x-(x%1),1,96-x,64+y)
    end
  end
  local keys,jump_key="",_settings[5].ch==" " and "SPACE" or _settings[5].ch
  for i=1,4 do
    keys..=_settings[i].ch
  end
  local message_time,messages=0,{
    "lOOK AROUND WITH MOUSE",
    "mOVE WITH "..keys,
    "jUMP WITH "..jump_key,
    "bEST PLAYED WITH ♪ ON!"
  }
  -- reset pal (to be safe)
  _hw_pal=0
  return
    -- update
    function()
      message_time+=1

      -- move
      local dx,dz,a,jmp,jump_down=0,0,angle[2],0,stat(28,@0xe404)
      if not launching then
        if(stat(28,@0xe402)) dx=1
        if(stat(28,@0xe403)) dx=-1
        if(stat(28,@0xe400)) dz=1
        if(stat(28,@0xe401)) dz=-1
        if(on_ground and jumpp!=jump_down) jmp,on_ground=24
      end
      jumpp=jump_down

      dangle=v_add(dangle,{$0xe410*stat(39),stat(38),0})
      tilt+=0.075*dx
      local c,s=3.5*cos(a),-3.5*sin(a)
      velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx},0.35)
      origin=v_add(origin,velocity)
      if velocity[2]<0 and origin[2]<0 then
        origin[2]=0
        velocity[2]=0
        on_ground=true
      end
      eye_pos=v_add(origin,{0,24,0})

      -- damping      
      dangle=v_scale(dangle,0.6)
      tilt*=0.6
      if(abs(tilt)<=0.0001) tilt=0
      velocity[1]*=0.7
      velocity[3]*=0.7
      -- gravity
      velocity[2]-=0.8
      angle=v_add(angle,dangle,$0xe416/1024)
      -- limit x amplitude
      angle[1]=mid(angle[1],-0.24,0.24)

      local m=make_m_from_euler(unpack(angle))        

      cam:track(eye_pos,m,angle,tilt)

      -- player close to dagger?
      local real_distance=v_len(origin,{0,0,0})
      if real_distance>380 then
        sfx"15"
        next_state(play_state)
        return
      end
      distance=min(distance,real_distance)
      if not launching then
        --play ambient music
        if not stat"57" then
          audio_load("daggercollect", 0x31f8)
          music(62, 1000)
        end

        --play daggercall
        if real_distance < 96 and stat"49" ~= 14 then
          sfx(14, 3)
        end

        if distance<16 then
          -- avoid reentrancy
          launching=true

          do_async(function()
            --play daggercollect
            sfx"-1"
            music"63"

            for i=0,44 do
              fov=lerp(64,32,easeoutelastic(i/45))
              yield()
            end

            -- load dev version first then release then BBS
            for i=0,11 do
              _hw_pal=i<<4
              yield()
            end
            while stat"57" do
              yield()
            end
            cls()
            load("freds72_daggers.p8","back to title")
            load("freds72_daggers_mini.p8","back to title")
            load("#freds72_daggers","back to title")
          end)
        end
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
        for i=0,63 do
          memset(0x1000+32+i*64,0x88,32)
        end
        poke(0x5f55,0x00)
        local r=abs(cos(time()/8))
        draw_radius(32-r*r,0.25)
        r+=1
        draw_radius(32-r*r,0.7)
        r+=1.5
        draw_radius(32-r*r,0.99)
        poke(0x5f55,0x60) 

        mode7(verts,#verts,0xd280)    
      end

      if not launching then
        draw_things({
          {
            ent=_entities.dagger,
            origin={0,24+3*cos(time()/4),0},
            yangle=0,
            zangle=0,
            radius=12
          }
        },cam,fov)
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

      --[[
      local s="HUM...cURSED?"
      print(s,64-print(s,0,130)/2,2,6)
      ]]
      if distance>96 then
        local s=messages[flr(message_time/60)%#messages+1]
        print(s,64-print(s,0,130)/2,122,1)
      end

      --pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
      memcpy(0x5f10,0xc000+_hw_pal,16)
    end
end

function title_state()
  cls()
  -- going to take a while..don't refresh
  holdframe()
  px9_decomp(0,0,title_img,pget,pset)

  local msg_ttl,launching=300
  return
    -- update
    function()
      msg_ttl=max(msg_ttl-1)
      if btnp()&0x30!=0 then
        launching=true

        --fade out music
        music(-1, 1000)

        do_async(function()
          next_state(menu_state, _main_buttons)
        end)
      end
    end,
    -- draw
    function()
      -- apply 
      pal({[0]=0, 130, 2, 8, 136, 128, 7},1)
      if msg_ttl==0 then
        local s="mOUSE CLICK TO CONTINUE"
        print(s,64-print(s,0,130)/2,110,1+abs(flr(2.9*cos(time()/4))))
      end
    end
end

-- entry points
function _init()
  -- custom font
  -- source: https://somepx.itch.io/humble-fonts-tiny-ii
  ?"\^@56000800⁴⁸⁶\0\0¹\0\0\0\0\0\0\0 \0\0\0 \0²\0\0\0\0■■■■■\0\0\0▮¹■■▒■ ■■■」!■\0\0\0▮■■▮\0■!■■■■!■\0\0²\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0⁷⁷⁷⁷⁷\0\0\0\0⁷⁷⁷\0\0\0\0\0⁷⁵⁷\0\0\0\0\0⁵²⁵\0\0\0\0\0⁵\0⁵\0\0\0\0\0⁵⁵⁵\0\0\0\0⁴⁶⁷⁶⁴\0\0\0¹³⁷³¹\0\0\0⁷¹¹¹\0\0\0\0\0⁴⁴⁴⁷\0\0\0⁵⁷²⁷²\0\0\0\0\0\0\0‖\0\0\0\0\0\0¹²\0\0\0\0\0\0³³\0\0\0⁵⁵\0\0\0\0\0\0²⁵²\0\0\0\0\0\0\0\0\0\0\0\0\0²²²²\0²\0\0\n⁵\0\0\0\0\0\0\n゜\n゜⁸\0\0\0⁷³⁶⁷²\0\0\0⁵⁴²¹⁵\0\0\0\0⁴²◀\t◀\0\0²¹\0\0\0\0\0\0²¹¹¹¹²\0\0²⁴⁴⁴⁴²\0\0⁵²⁷²⁵\0\0\0\0²⁷²\0\0\0\0\0\0\0²¹\0\0\0\0\0⁷\0\0\0\0\0\0\0\0\0²\0\0\0⁴²²²¹\0\0\0⁶\t\rᵇ⁶\0\0\0²³²²⁷\0\0\0⁷ᶜ⁶¹ᶠ\0\0\0⁷ᶜ⁶⁸ᶠ\0\0\0⁵⁵ᶠ⁴⁴\0\0\0ᶠ¹⁶ᶜ⁷\0\0\0⁴²⁷\t⁶\0\0\0ᶠ⁸⁴²²\0\0\0⁶\t⁶\t⁶\0\0\0⁶\tᵉ⁴²\0\0\0\0²\0²\0\0\0\0\0²\0²¹\0\0\0⁴²¹²⁴\0\0\0\0⁷\0⁷\0\0\0\0¹²⁴²¹\0\0\0²⁵⁴²\0²\0\0²⁵⁵¹⁶\0\0\0\0⁶⁸ᵇ⁶\0\0\0¹⁵\t\t⁶\0\0\0\0⁶¹¹⁶\0\0\0⁸\n\t\t⁶\0\0\0\0ᵉ\t⁵ᵉ\0\0\0ᶜ²ᵉ³²¹\0\0\0ᵉ\t\r\n⁴\0\0¹⁵ᵇ\t\t⁴\0\0²\0³²²⁷\0\0\0ᶜ⁸⁸\t⁶\0\0¹\t⁵ᵇ\t⁴\0\0¹¹¹¹⁶\0\0\0\0\n▶‖‖\0\0\0\0⁶\t\t\t\0\0\0\0⁶\t\t⁶\0\0\0\0⁶\t\t⁵¹\0\0\0⁶\t\t\n⁸\0\0\0\rᵇ¹¹\0\0\0\0ᵉ³⁸ᶠ\0\0\0\0²ᵉ³²ᶜ\0\0\0\t\t\t⁶\0\0\0\0\t\t⁵³\0\0\0\0‖‖‖ᵇ\0\0\0\0\t⁶⁴\t\0\0\0\0\t\tᵇ⁴³\0\0\0⁷⁴²⁷\0\0\0³¹¹¹¹³\0\0¹¹³²²\0\0\0⁶⁴⁴⁴⁴⁶\0\0²⁵\0\0\0\0\0\0\0\0\0\0⁷\0\0\0²⁴\0\0\0\0\0\0⁶\tᵇ\r\t\t\0\0⁶\t⁵ᵇ\t⁷\0\0⁶\t¹¹\t⁶\0\0³⁵\t\t\t⁷\0\0⁶¹⁵³\t⁶\0\0⁶¹⁵³¹¹\0\0⁶¹¹\r\t⁶\0\0⁵⁵⁵⁷⁵⁵\0\0⁷²²²²⁷\0\0ᵉ⁸⁸⁸\t⁶\0\0\t\t⁵ᵇ\t\t\0\0²¹¹¹\t⁷\0\0\n▶‖‖‖‖\0\0\nᵇ\r\t\t\t\0\0⁶\t\t\t\t⁶\0\0⁶\t\t\r¹¹\0\0⁶\t\t\t\r\n\0\0⁶\t\t⁵ᵇ\t\0\0ᵉ³⁶⁸⁸⁷\0\0ᶜ³²²²²\0\0\t\t\t\t\t⁶\0\0\t\t\t\t⁵³\0\0‖‖‖‖▶\r\0\0\t\t\t⁶\t\t\0\0\t\t\tᵇ⁴³\0\0⁷⁴²¹¹⁷\0\0⁶²³²⁶\0\0\0²²²²²\0\0\0³²⁶²³\0\0\0\0²‖ᶜ\0\0\0\0\0²⁵²\0\0\0\0○○○○○\0\0\0U*U*U\0\0\0<~j4、\0\0\0>ccw>\0\0\0■D■D■\0\0\0⁴<、゛▮\0\0\0⁸*>、、⁸\0\0006>>、⁸\0\0\0、\"*\"、\0\0\0、、>、⁘\0\0\0、>○*:\0\0\0>gcg>\0\0\0○]○A○\0\0\0008⁸⁸ᵉᵉ\0\0\0>ckc>\0\0\0⁸、>、⁸\0\0\0\0\0U\0\0\0\0\0>scs>\0\0\0⁸、○>\"\0\0\0「$JZ$「\0\0>wcc>\0\0\0\0⁵R \0\0\0\0\0■*D\0\0\0\0>kwk>\0\0\0○\0○\0○\0\0\0UUUUU\0\0\0⁸、>\\Hp\0\0\0▮ |:□\0\0「$タししタ\0\0⁸、>⁸\">\0\0\0000JF.\0\0\0\0゛zz~x\0\0、\">>>>\0\0⁴ᶜ、、ᶜ⁴\0\0⁸>、⁸\">\0\0「<~~<「\0\0\0*\0*\0*\0\0\0>\"\"\">\0\0\0 1•ᵉ⁴\0\0⁸>\0**>\0\0\0\0\0\0\0\0\0\0²⁷2²2\0\0\0ᶠ²ᵉ▮、\0\0\0>@@ 「\0\0\0>▮⁸⁸▮\0\0\0⁸8⁴²<\0\0\0002⁷□x「\0\0\0zB²\nr\0\0\0\t>Kmf\0\0\0¥'\"s2\0\0\0<JIIF\0\0\0□:□:¥\0\0\0#b\"\"、\0\0\0ᶜ\0⁸*M\0\0\0\0ᶜ□!@\0\0\0}y■=]\0\0\0><⁸゛.\0\0\0⁶$~&▮\0\0\0$N⁴F<\0\0\0\n<ZF0\0\0\0゛⁴゛D8\0\0\0⁘>$⁸⁸\0\0\0:VR0⁸\0\0\0⁴、⁴゛⁶\0\0\0⁸²> 、\0\0\0\"\"& 「\0\0\0>「$r0\0\0\0⁴6,&d\0\0\0>「$B0\0\0\0¥'\"#□\0\0\0ᵉd、(x\0\0\0⁴²⁶+」\0\0\0\0\0ᵉ▮⁸\0\0\0\0\n゜□⁴\0\0\0\0⁴ᶠ‖\r\0\0\0\0⁴ᶜ⁶ᵉ\0\0\0> ⁘⁴²\0\0\0000⁸ᵉ⁸⁸\0\0\0⁸>\" 「\0\0\0>⁸⁸⁸>\0\0\0▮~「⁘□\0\0\0⁴>$\"2\0\0\0⁸>⁸>⁸\0\0\0<$\"▮⁸\0\0\0⁴|□▮⁸\0\0\0>   >\0\0\0$~$ ▮\0\0\0⁶ &▮ᶜ\0\0\0> ▮「&\0\0\0⁴>$⁴8\0\0\0\"$ ▮ᶜ\0\0\0>\"-0ᶜ\0\0\0、⁸>⁸⁴\0\0\0** ▮ᶜ\0\0\0、\0>⁸⁴\0\0\0⁴⁴、$⁴\0\0\0⁸>⁸⁸⁴\0\0\0\0、\0\0>\0\0\0> (▮,\0\0\0⁸>0^⁸\0\0\0   ▮ᵉ\0\0\0▮$$DB\0\0\0²゛²²、\0\0\0>  ▮ᶜ\0\0\0ᶜ□!@\0\0\0\0⁸>⁸**\0\0\0> ⁘⁸▮\0\0\0<\0>\0゛\0\0\0⁸⁴$B~\0\0\0@(▮h⁶\0\0\0゛⁴゛⁴<\0\0\0⁴>$⁴⁴\0\0\0、▮▮▮>\0\0\0゛▮゛▮゛\0\0\0>\0> 「\0\0\0$$$ ▮\0\0\0⁘⁘⁘T2\0\0\0²²\"□ᵉ\0\0\0>\"\"\">\0\0\0>\" ▮ᶜ\0\0\0> < 「\0\0\0⁶  ▮ᵉ\0\0\0\0‖▮⁸⁶\0\0\0\0⁴゛⁘⁴\0\0\0\0\0ᶜ⁸゛\0\0\0\0、「▮、\0\0\0⁸⁴c▮⁸\0\0\0⁸▮c⁴⁸\0\0\0"
  -- enable custom font
  -- enable tile 0 + extended memory
  -- capture mouse
  -- enable lock
  -- cartdata
  exec[[poke;0x5f58;0x81
poke;0x5f36;0x18
poke;0x5f2d;0x7
reload
cartdata;freds72_daggers]]

  --decompress audio payloads and save to lua ram
  holdframe()

  for _, payload in pairs(audio) do
    px9_decomp(0, 0, payload.addr, pget, pset)
    payload.data = ram_to_tbl(0x6000, payload.ulen)
  end

  --dump audio payloads
  audio_load("noisedata", 0x4300)
	audio_load("victory", 0x4da4)
	audio_load("chatter", 0xfd14)
	audio_load("ui", 0x5090)

  -- generate assets if not there
  if reload(0x6000,0x0,0x1,"freds72_daggers_pic_0.p8")==0 or dget(63)!=0 then
    -- in case player halts generation
    dset(63,1)
    load("freds72_daggers_editor.p8","","generate")
    load("freds72_daggers_editor_mini.p8","","generate")
    load("#freds72_daggers_editor","","generate")
  end

  -- HW palette + fade to black
  local src,dst=0x0,0xc000
  memcpy(dst,src,16*16)
  dst+=0x100
  src+=0x100

  -- hit palette
  -- fade pal + ring pal (normal)
  -- fade pal + ring pal (floor)
  for j=1,552 do
    -- explode byte into 2
    for i=0,7 do
      local b=@src
      poke(dst,b&0xf) dst+=1
      poke(dst,b>>4) dst+=1        
      src+=1
    end
  end
  -- set pal 15 as transparent for hit+upgrade+distance palette
  for j=0,279 do
    local mem=0xc100+16*j+15
    poke(mem,@mem|0x10)
  end
  -- level up: hand palettes
  dst=0xf500
  split2d([[15;15;15;15;15;15;15;15;15
15;7;6;9;8;9;6;7;15
15;10;11;13;14;13;11;10;15]],
  function(...)
    poke(dst,...)
    dst+=select('#',...)
  end)
  -- load background assets
  decompress("freds72_daggers_pic",0,0,function()
    local names={
      [1]="skull",
      [8]="dagger",
      [9]="break"
    }
    -- drop array size
    for i=1,mpeek2() do
      local name,sprites,angles=names[mpeek()],{},mpeek()
      if(name=="break") break
      local ent={  
        sprites=sprites,   
        yangles=angles&0xf,
        zangles=angles\16,        
        frames=unpack_frames(sprites)
      }
      if name then
        _entities[name]=ent
      end
    end
  end)
  reload()

  -- play musicii
  audio_load"musicii"
  music"3"

  reload(0, 0, 0x3100) 
  px9_decomp(0,0,0x1240,sget,sset)
  -- copy tiles to high mem (for shadows/splash)
  local mem=0xe500
  for i=0,64*64-1,64 do
    -- copy the same row twice
    memcpy(mem,i+32,32) mem+=32
    memcpy(mem,i+32,32) mem+=32
  end

  -- restore settings
  local active_poll
  local function print_key(btn)
    local txt=btn.ch
    if txt==" " then
      txt="<SPACE>"
    end
    if _active_btn==btn then
      txt=(time()\0.5)%2==0 and "PRESS KEY" or "           "
    end
    return btn.action.."["..txt.."]"
  end
  local special_keys={
    [80]="⬅️",
    [79]="➡️",
    [82]="⬆️",
    [81]="⬇️"
  }
  local function read_key(btn)
    if(active_poll) active_poll.co=nil
    _active_btn=btn
    active_poll=do_async(function()
      local t=time()
      -- wait until key press or 3s
      while time()<t+3 do
        local k
        for i=0,255 do
          if stat(28,i) then
            k=i
            break
          end
        end
        if k then
          local ch=special_keys[k]
          if ch then
            btn.ch=ch
            btn.stat=k
            ui_sfx"3"
            break
          end
          -- empty key buffer (doesn't really work)
          local gotkey
          while stat(30) do
            local ch=stat(31)      
            local c=ord(ch)
            if c>=0x20 and c<0x80 then
              -- convert to upper case (=small font)
              if(c>0x60 and c<0x7b) ch=chr(c-0x20)
              btn.ch=ch
              gotkey=true
            end
          end
          if(gotkey) btn.stat=k ui_sfx"3" break
        end
        yield()
      end
      -- "eat" bntp :)
      yield()
      _active_btn=nil
    end)
  end
  local function flip_bool(btn)
    btn.value=(btn.value+1)%2
  end

  local function exit_state()
    -- kill any key poll routine
    if(active_poll) active_poll.co=nil
    -- back to main menu
    next_state(menu_state, _main_buttons)        
  end

  local dget_base=26
  local function data_id(btn) return dget_base+2*btn.id end
  local function load_value(btn)
    -- don't override default values if none
    if dget(data_id(btn))!=0 then
      btn.value=dget(data_id(btn)+1)
    end
  end
  local function save_value(btn)
    local id=data_id(btn)
    -- printh(btn[1](btn).." id:"..id)
    dset(id,1)
    dset(id+1,btn.value)
  end
  local function load_key(btn)
    local id=data_id(btn)
    btn.ch=chr(dget(id))
    btn.stat=dget(id+1)
  end
  local function save_key(btn)
    local id=data_id(btn)
    dset(id,ord(btn.ch))
    dset(id+1,btn.stat)
  end
  -- copy settings to 0xe400  
  local function pack_key(btn)
    poke(0xe400+btn.id,btn.stat)
  end
  local function pack_settings()
    for _,btn in inext,_settings do
      if(btn.pack) btn:pack()
    end
  end

  local sensitivity={1,5,10,25,50,75,100,125,150,200}

  _settings={
    {print_key,30,
      action="fORWARD\t\t",
      ch="E",
      stat=8,
      id=0,
      load=load_key,
      save=save_key,
      cb=read_key,
      pack=pack_key
    },
    {print_key,37,
    action="bACKWARD\t\t",
    ch="D",
    stat=7,
    id=1,
    load=load_key,
    save=save_key,
    cb=read_key,
    pack=pack_key
    },
    {print_key,44,
    action="lEFT\t\t\t",
    ch="S",
    stat=22,
    id=2,
    load=load_key,
    save=save_key,
    cb=read_key,
    pack=pack_key
    },
    {print_key,51,
    action="rIGHT\t\t\t",
    ch="F",
    stat=9,
    id=3,
    load=load_key,
    save=save_key,
    cb=read_key,
    pack=pack_key
    },
    {print_key,58,
    action="jUMP\t\t\t",
    ch=" ",
    stat=44,
    id=4,
    load=load_key,
    save=save_key,
    cb=read_key,
    pack=pack_key
    },
    {function(btn)
      return "iNVERT MOUSE\t\t"..(btn.value==1 and "YES" or "NO")
    end,68,
    value=0,
    id=5,
    load=load_value,
    save=save_value,
    cb=flip_bool,
    pack=function(btn)
      poke4(0xe410,btn.value==1 and -1 or 1)
    end
    },
    {function(btn)
      return "sWAP BUTTONS\t\t"..(btn.value==1 and "YES" or "NO")
    end,75,
    value=0,
    id=6,
    load=load_value,
    save=save_value,
    cb=flip_bool,
    pack=function(btn)
      local a,b=4,5
      if(btn.value==1) a,b=b,a
      poke(0xe414,a,b)
    end
    },
    {function(btn)
      return "sENSITIVITY\t\t"..sensitivity[btn.value+1].."X"
    end,82,
    value=3,
    id=7,
    load=load_value,
    save=save_value,
    cb=function(btn)
      btn.value=((btn.value+1)%#sensitivity)
    end,
    pack=function(btn)
      poke4(0xe416,sensitivity[btn.value+1]/100)
    end
    },
    {function(btn)
      return "oNLINE LADDER\t\t"..(btn.value==0 and "YES" or "NO")
    end,88,
    value=0,
    id=8,
    load=load_value,
    save=save_value,
    cb=flip_bool,
    pack=function(btn)
      -- uses standard dget in game
    end
    },
    {function(btn)
      return "bEST TIME GIF\t\t"..(btn.value==0 and "NO" or "YES")
    end,94,
    value=0,
    id=9,
    load=load_value,
    save=save_value,
    cb=flip_bool,
    pack=function(btn)
      -- uses standard dget in game
    end
    },
    {"aCCEPT",111,
    cb=function()
      -- save version
      dset(25,1)
      -- save bindings
      for _,btn in inext,_settings do
        if(btn.save) btn:save()
      end
      -- refresh game settings
      pack_settings()
      exit_state()
    end
    },
    {"bACK",119,
    cb=function() 
      exit_state()
    end
    },
    {"BUILD ".._version,119,
      static=true,
      x=function(self)
        return 128-print(self[1],0,512)
      end
    },
    draw=function()
      arizona_print("cONTROLS & sETTINGS",1,16,2)
    end
  }
  -- restore previous
  local settings_version=dget(25)
  if settings_version==1 then
    for _,btn in inext,_settings do
      if(btn.load) btn:load()
    end
  end
  pack_settings()

  -- enable online if allowed
  poke(0x5f80,0)
  if dget(43)==0 then
    poke(0x5f80,1)
  end

  -- generate distance grid to memory
  local s=""
  for i=-5,5 do
    for j=-5,5 do
      local d=sqrt(i*i+j*j)\1
      if d<6 then
      if(#s!=0) s..=","
      s..=tostr((i>>16)+j,1)..","..max(1,d)
      end
    end  
  end
  poke(0xf71f,ord(s,1,#s))

  -- back to main menu
  menuitem(1,"main menu",function()
    next_state(menu_state, _main_buttons)
  end)

  -- init game
  next_state(title_state)
end

function _update()
  update_asyncs()
  _update_state()
end


