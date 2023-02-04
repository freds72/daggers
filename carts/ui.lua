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
function main_window(cursor)
    cursor=cursor or 0
    local mx,my
    local mstate={}

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
    end
    _draw=function()
        cls()
        win:onmessage({
            name="draw"
        })
        win:onmessage({
            name="overlay"
        })
        -- display cursor
        if cursor then
            spr(cursor[1],mx+cursor[2],my+(cursor[3] or 0))    
        end
        -- reset cursor each frame
        cursor=cursors.pointer
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
function make_button(s,binding)
    local frames=0
    return is_button({
        draw=function(self)
            pal(7,frames>0 and 15 or 2)
            local r=self.rect 
            spr(s,r.x,r.y)
            pal()
            frames=max(frames-1)
        end,
        clicked=function(self,msg)              
            binding:set(true)
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
function make_color_picker(c,binding)  
    return is_button({
        draw=function(self)   
            local r=self.rect
            rectfill(r.x,r.y,r.x+r.w,r.y+r.h,c)  
        end,
        overlay=function(self)
            if binding:get()==c then
                local r=self.rect
                rect(r.x-1,r.y-1,r.x+r.w+1,r.y+r.h+1,7)
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
                rect(r.x-1,r.y-1,r.x+r.w+1,r.y+r.h+1,7)
            end
        end,
        clicked=function(self,msg)              
            binding:set(c)
        end
    })
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
-- no-op binding
_nop_binding={}
function _nop_binding:set() end
function _nop_binding:get() end