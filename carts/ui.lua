-- basic window library for editors
local window={}
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
function window:add(child,x,y,w,h)    
    local win=add(self,child)
    -- assign dimensions
    win.rect={x=x,y=y,w=w or 8,h=h or 8}
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
function main_window(params,is_dialog)
    local cursor=params.cursor or 0
    local mx,my
    local mstate={}
    local kstate={}

    -- known cursors
    local cursors={
        pointer={0,0},
        hand={1,-3},
        aim={2,-3,-3}
    }
    local cursor=cursors.pointer

    -- mouse
    poke(0x5f2d,1)

    local win=is_window({
        mousemove=function(self,msg)            
            mx,my=msg.mx,msg.my     
            -- handle clicks (mouse up)
            for _,k in pairs({"lmb","rmb","mmb"}) do
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
        dialog=function(self,dlg_params,x,y,w,h)
            local prev_update,prev_draw=_update,_draw
            local border=dlg_params.border
            local win=main_window(params,true)
            local mm=win.mousemove
            win.close=function()
                -- restore previous window
                local d=_draw
                _update,_draw=prev_update,function()
                    d()
                    _draw=prev_draw
                end
            end
            win.mousemove=function(self,msg)
                -- base function
                mm(self,msg)
                -- 
                if msg.lmbp and (msg.mx<x or msg.my<y or msg.mx>x+w or msg.my>y+h) then
                    has_dialog=false
                    self:close()
                end
            end
            win.overlay=function()
                if border then
                    rect(x,y,x+w,y+w,border)
                end        
            end
            -- finish current update/draw cycle
            local d=_draw
            _draw=function()
                prev_draw(true)
                memcpy(0x8000,0x6000,0x2000)
                _draw=d
            end
            return win
        end
    })
    -- take over update and draw
    _update=function()
        win:onmessage({
            name="mousemove",
            mx=stat(32),
            my=stat(33),
            lmb=stat(34)&1!=0,
            rmb=stat(34)&2!=0,
            mmb=stat(34)&4!=0,
            wheel=stat(36),
            mdx=stat(38),
            mdy=stat(39)
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

        -- drag&drop?
        if stat(120) then
            win:onmessage({
                name="ondrop",
                address=0x800
            })
        end
    end
    _draw=function(no_cursor)
        if is_dialog then
            memcpy(0x6000,0x8000,0x2000)
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
function is_button(class)    
    return setmetatable(class,
        {__index=is_window({
            mousemove=function(self,msg)
                local r=self.rect
                local focus=msg.mx>=r.x and msg.mx<=r.x+r.w and msg.my>=r.y and msg.my<=r.y+r.h
                self:onmessage({
                    name="mouseover",
                    focus=focus
                })
                if focus then
                    self:send({
                        name="cursor",
                        cursor="hand"
                    })
                end
                if focus and msg.lmbp then
                    self:onmessage({
                        name="clicked"
                    })
                end
            end
        })})
end

-- button constructor
-- default param is sprite id
-- alternate: {text="text to display", color="text color"}
function make_button(s,binding)
    -- icon button
    local t=1
    if type(s)=="table" then
        t=2
    end
    local frames=0
    return is_button({
        draw=function(self)
            pal(7,frames>0 and 15 or 2)
            local r=self.rect 
            if t==1 then
                spr(s,r.x,r.y)
            else
                print(s.text,r.x,r.y,s.color)
            end
            pal()
            frames=max(frames-1)
        end,
        clicked=function(self,msg)              
            binding:set(s)
            frames=3
        end        
    })
end

function make_radio_button(s,value,binding)
    return is_button({
        draw=function(self)
            pal(7,binding:get()==value and 15 or 2)
            local r=self.rect 
            spr(s,r.x,r.y)
            pal()
        end,
        clicked=function(self,msg)              
            binding:set(value)
        end        
    })
end

-- color picker
-- params:
-- color
-- or
-- {color=c,palette=table}
function make_color_picker(params,binding)  
    local c,palette
    if type(params)=="table" then
        c=params.color
        palette=params.palette
    else
        c=params
    end
    return is_button({
        draw=function(self)   
            local r=self.rect
            color(palette and palette[c] or c)
            rectfill(r.x,r.y,r.x+r.w-1,r.y+r.h-1)  
        end,
        overlay=function(self)
            if binding:get()==c then
                local r=self.rect
                fillp()
                rect(r.x+1,r.y+1,r.x+r.w-2,r.y+r.h-2,0)
                rect(r.x,r.y,r.x+r.w-1,r.y+r.h-1,7)
            end
        end,
        clicked=function(self,msg)              
            binding:set(c)
        end
    })
end

-- takes a sprite and code
function make_sprite_picker(c,s,binding)
    local sx,sy=(s%16)*8,(s\16)*8
    return is_button({
        draw=function(self)   
            local r=self.rect
            sspr(sx,sy,8,8,r.x,r.y,r.w,r.h)
            --rectfill(r.x,r.y,r.x+r.w,r.y+r.h,c)  
        end,
        overlay=function(self)
            if binding:get()==c then
                local r=self.rect
                fillp(0xa5a5.8)
                rect(r.x,r.y,r.x+r.w-1,r.y+r.h-1,7)
                fillp()
            end
        end,
        clicked=function(self,msg)              
            binding:set(c)
        end
    })
end

function make_list(width,w,h,binding)
    w=w or 8
    h=h or 8
    -- number of items per row
    local n=width\w
    assert(n>0,"Invalid width: "..w)
    local win=is_window({
        add=function(self,child)
            local r=self.rect
            -- assign rect in grid
            child.rect={x=r.x+(#self%n)*w,y=r.y+(#self\n)*h,w=w,h=h}
            child.parent=self
            return add(self,child)
        end,
        mousemove=function(self,msg)        
            local r=self.rect
            local focus=msg.mx>=r.x and msg.mx<=r.x+r.w and msg.my>=r.y and msg.my<=r.y+r.h
            if focus and msg.wheel!=0 then
                local i0=binding:get()
                -- focus to next "row"
                binding:set(i0-msg.wheel*n)
                msg.handled=true
            end
        end,
        onmessage=function(self,msg)
            -- inactive window
            if(self.hide) return
            local fn=self[msg.name]
            if(fn) fn(self,msg)
            if(msg.handled) return
            -- cascade to child
            if #self>0 then
                local r=self.rect
                -- ensure selected item is visible
                local i0,my=binding:get(),msg.my
                -- how many items vertically
                local nh=r.h\h
                local yoffset=(i0\n)*h                
                if(msg.my) msg.my+=yoffset
                camera(0,yoffset)
                -- todo: draw all that fits horizontally AND vertically
                local start=(i0\n)*n
                for i=start+1,min(start+max(nh,n),#self) do
                    local child=self[i]
                    child:onmessage(msg)
                    if(msg.handled) break
                end
                camera()
                msg.my=my
            end
        end
    })
    return win
end

-- static banner (optional text & color via binding)
function make_static(c,binding)
    return is_window({
        draw=function(self,msg)  
            local r=self.rect 
            rectfill(r.x,r.y,r.x+r.w,r.y+r.h,c)
            if binding then
                local txt,c=binding:get()
                print(txt,r.x+1,r.y+1,c or 0)
            end
        end
    })
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

-- binding with a range
function bounded_binding(env,prop,lower,upper)
    return {
        set=function(self,value)
            env[prop]=mid(value,lower,upper)
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