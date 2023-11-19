-- basic window library for editors
local window={
  -- default props
  rect={
    x=0,
    y=0,
    w=128,
    h=128}
}
-- message handler
function window:onmessage(msg)
    -- inactive window
    if(self.hide) return
    local fn=self[msg.name]
    if(fn) fn(self,msg)
    if(msg.handled) return
    -- cascade to child
    if #self>0 then
        for i=1,#self do
            local child=self[i]
            child:onmessage(msg)
            if(msg.handled) break
        end
    end
end
function window:add(child)    
    local win=add(self,child)
    win.parent=self
    return win
end

function window:send(msg)
    -- send a message to top of hierarchy
    local curr=self
    while curr.parent do
        curr=curr.parent
    end
    curr:onmessage(msg)
end
-- show/hide
function window:show(flag)
    self.hide=not flag
end

-- create window
function is_window(class)
    return setmetatable(class,{__index=window})
end

-- main window: handles cursor layer
function main_window(params,is_transparent)
    local cursor=params.cursor or 0
    local mx,my,mstate,kstate=stat(32),stat(33),{},{}

    -- known cursors
    local cursors={
        pointer={0,0},
        hand={1,-3},
        aim={2,-3,-3}
    }
    local cursor=cursors.pointer

    local win=is_window({
        mousemove=function(self,msg)            
            mx,my=msg.mx,msg.my     
            -- handle clicks (mouse up)
            for _,k in pairs{"lmb","rmb","mmb"} do
                if mstate[k] and not msg[k] then
                    msg[k.."p"]=true
                end
                -- refresh state
                mstate[k]=msg[k]                
            end
        end,
        cursor=function(self,msg)
            if(not msg.cursor) cursor=nil return
            cursor=cursors[msg.cursor] or cursors.pointer
            msg.handled=true
        end,
        dialog=function(self,is_transparent)
            local prev_update,prev_draw=_update,_draw
            local win=main_window(params,is_transparent)
            win.close=function()
                -- restore previous window
                local d=_draw
                _update,_draw=prev_update,function()
                    d()
                    _draw=prev_draw
                end
            end
            if is_transparent then
              -- finish current update/draw cycle
              local d=_draw
              _draw=function()
                  prev_draw(true)
                  memcpy(0xa000,0x6000,0x2000)
                  _draw=d
              end
            end       
            return win
        end
    })
    -- take over update and draw
    _update=function()
      win:onmessage({
        name="update"
      })

      -- capture keys
      local keys={}
      while stat(30) do
          local k=stat(31)
          keys[k]=true
      end
      
      -- hotkeys
      local shortcuts={
          ["セ"]="undo",
          ["る"]="copy",
          ["コ"]="paste",
      }
      for k,cmd in pairs(shortcuts) do
          if kstate[k] and not keys[k] then            
              win:onmessage({
                  name=cmd
              })
          end
      end
      kstate=keys

      win:onmessage({
          name="mousemove",
          mx=stat(32),
          my=stat(33),
          lmb=stat(34)&1!=0,
          rmb=stat(34)&2!=0,
          mmb=stat(34)&4!=0,
          wheel=stat(36),
          mdx=stat(38),
          mdy=stat(39),
          btn=btn()
      })     

      -- drag&drop?
      if stat(120) then
        win:onmessage({
          name="ondrop",
          address=0x800
        })
      end
    end
    _draw=function(no_cursor)
      if is_transparent then
          memcpy(0x6000,0xa000,0x2000)
          -- cheap greyout
          fillp(0xa5a5.8)
          rectfill(0,0,127,127,0)
          fillp()
      else
          cls(params.background or 0)
      end      

      -- base draw
      win:onmessage({            
          name="draw"
      })
      -- items drawn on top of all others
      win:onmessage({
          name="overlay"
      })
      if not no_cursor then
          -- display cursor
          if cursor then
              spr(cursor[1],mx+cursor[2],my+(cursor[3] or 0))    
          end
          -- reset cursor each frame
          cursor=cursors.pointer
      end
      -- palette?
      if(params.pal) pal(params.pal,1)
    end
    return win
end

-- generic active/over class
-- generic active/over class
function is_button(class)    
  return setmetatable(class,
      {__index=is_window({
          mousemove=function(self,msg)
              local r=self.rect
              local focus=msg.mx>=r.x and msg.mx<r.x+r.w and msg.my>=r.y and msg.my<r.y+r.h
              self:onmessage(inherit({
                  name="mouseover",
                  focus=focus
              },msg))
              if focus then
                  self:send(inherit({
                      name="cursor",
                      cursor="hand"
                  },msg))
              end
              if focus and msg.lmbp then
									sfx"3"
                  self:onmessage(inherit({
                      name="clicked"
                  },msg))
              end
          end
      })})
end

-- vertical list of sliding controls
function make_vpanel(isleft,islocked)
  local last_y=0
  return is_window{
    add=function(self,c,vpadding)     
      last_y+=vpadding or 0
      local txt=c.txt
      local hiddenx=isleft and -print(sub(txt,1,#txt-1),0,512) or 128-print(txt[1],0,512)
      local visiblex=isleft and 1 or 127-c.rect.w   
      c.rect.x=isleft and -c.rect.w or 128
      c.rect.y=last_y

      -- animation properties
      c.anim={
        visiblex=visiblex,
        hiddenx=hiddenx,
        targetx=islocked and visiblex or hiddenx,
        ttl=0
      }
      add(self,c)
      last_y+=c.rect.h
    end,
    update=function(self)
      for c in all(self) do
        local anim,r=c.anim,c.rect
        r.x=lerp(r.x,anim.targetx,0.3)
        if(abs(r.x-anim.targetx)<0.5) r.x=anim.targetx
      end
    end,
    mousemove=function(self,msg)
      for c in all(self) do
        local anim,r=c.anim,c.rect
        anim.targetx=islocked and anim.visiblex or anim.hiddenx
        if msg.mx>r.x and msg.mx<r.x+r.w and msg.my>r.y and msg.my<r.y+r.h then
          anim.ttl+=1
          if(anim.ttl>15) anim.targetx=anim.visiblex
        else
          anim.ttl=max(anim.ttl-1)
        end
      end
    end
  }
end

function make_vlist(x,y)
  local last_y=y
  return is_window{
    add=function(self,c,vpadding)     
      last_y+=vpadding or 0
      c.rect.x=x
      c.rect.y=last_y
      add(self,c)
      last_y+=c.rect.h
    end
  }
end

function make_color_picker(palette,binding)
  return is_button{
    rect={
      x=0,
      y=122,
      h=4,
      w=128
    },
    clicked=function(self,msg)
      binding:set(msg.mx\4)
    end,
    draw=function()
      rect(0,122,128,127,1)
      for i=0,31 do
        local x,y=i*4,123
        rectfill(x,y,x+3,126,palette and palette[i] or i)
      end
      local x,y=binding:get()*4,123
      rect(x-1,y-1,x+4,127,0x77)
    end
  }
end

function make_button(txt,binding)
  local ttl,focus=0
  return is_button{
    rect={
      h=8,
      w=print(txt,0,512)
    },
    txt=txt,
    mouseover=function(self,msg)
      focus=msg.focus
    end,
    draw=function(self,msg)
      local r=self.rect
      arizona_print(txt,r.x,r.y,ttl>0 and 2 or focus and 1 or 0)
    end,
    update=function(self)
      ttl=max(ttl-1)
    end,
    clicked=function(self)
      ttl=3
      binding:set()
    end
  }
end

function make_radio_button(txt,value,binding)
  local focus
  return is_button{
    rect={
      h=8,
      w=print(txt,0,512)
    },
    txt=txt,
    mouseover=function(self,msg)
      focus=msg.focus
    end,
    draw=function(self)
      local r=self.rect
      arizona_print(txt,r.x,r.y,binding:get()==value and 2 or focus and 1 or 0)
    end,
    clicked=function(self)
      binding:set(value)
    end
  }
end

-- data binding
-- env+prop: get/set value
-- env: call function on set()
function binding(env,prop)
  return {
      set=function(self,value)
          if(prop) env[prop]=value return
          env(value)
      end,
      get=function(self)
          if(prop) return env[prop]
      end
  }
end

function read_binding(env,prop)
  return {
      set=function()
          -- nope
      end,
      get=function(self)
          if(prop) return env[prop]
          return env()
      end
  }
end

function bool_binding(env,prop)
  return {
    set=function(self)
      env[prop]=not env[prop]
    end,
    get=function(self)
      return env[prop]
    end
  }
end

-- no-op binding
_nop_binding={}
function _nop_binding:set() end
function _nop_binding:get() end
