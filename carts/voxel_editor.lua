
-- to validate archive presence
local _magic_number=0x8764.1359

-- editor state
_editor_state={
    -- to be used to lookup in palette
    selected_color=4,
    layer=0,
    offset={0,0,0},
    -- 1: pen
    -- 2: selection
    -- 3: fill
    edit_mode=1,
    level=1,
    pen_radius=1
}

local _grid={}
local _grid_size=14

-- color palette
local _palette={}

-- game entities
local default_angles=0x88
-- note: new entities must be added at the end
local _entities={
    {text="sKULL",angles=default_angles},
    {text="rEAPER",angles=default_angles},
    -- animation
    {text="bLOOD0",angles=0},
    {text="bLOOD1",angles=0},
    {text="bLOOD2",angles=0},
    {text="dAGGER0",angles=default_angles},
    {text="dAGGER1",angles=default_angles},
    {text="dAGGER2",angles=default_angles},
    -- resting hand
    {text="hAND0",angles=0},
    {text="hAND1",angles=0x08},
    {text="hAND2",angles=0x08},
    -- green goo
    {text="gOOO0",angles=0},
    {text="gOOO1",angles=0},
    {text="gOOO2",angles=0},
    -- egg
    {text="eGG",angles=default_angles},
    -- spider0
    {text="sPIDER0",angles=default_angles},
    {text="sPIDER1",angles=default_angles},
    -- worm head+segment
    {text="wORM0",angles=default_angles},
    {text="wORM1",angles=default_angles},
    -- jewel
    {text="jEWEL",angles=default_angles},
    -- worm segment without jewel
    {text="wORM2",angles=default_angles},
}
local _current_entity

-- draw cube help
local cube={
    {0,0,0},
    {1,0,0},
    {1,1,0},
    {0,1,0},
    {0,0,1},
    {1,0,1},
    {1,1,1},
    {0,1,1},
    faces={
        -- x
            [0x0.0002]={k=-1,1,4,8,5},
            [0x0.0001]={k=1,3,2,6,7},
        -- y
            [0x0.02]={k=-1,1,5,6,2},
            [0x0.01]={k=1,4,3,7,8},
        -- z
            [0x02]={k=-1,1,2,3,4},
            [0x01]={k=1,6,5,8,7},
    }
}

-- binary string functions @zep
function str_esc(s)
    local out=""
    for i=1,#s do
     local c  = sub(s,i,i)
     local nc = ord(s,i+1)
     local pr = (nc and nc>=48 and nc<=57) and "00" or ""
     local v=c
     if(c=="\"") v="\\\""
     if(c=="\\") v="\\\\"
     if(ord(c)==0) v="\\"..pr.."0"
     if(ord(c)==10) v="\\n"
     if(ord(c)==13) v="\\r"
     out..= v
    end
    return out
end

-- unscape binary string
-- credits: @heraclum
function str_unesc(s)
    local i,out=1,""
    while i<=#s do
        local c,v=s[i]
        v=c
        if c=="\\" then
            i+=1
            c=s[i]
            if c=="\"" or c=="\\" then
                v=c
            elseif c=="0" then
                v="\0"
                if (s[i+1]=="0" and s[i+2]=="0") i+=2
            elseif c=="n" then v="\n"
            elseif c=="r" then v="\r"
            end
        end
        out..=v
        i+=1
    end
    return out
end

function get_majors(cam)
    local fwd=cam.fwd
    local majord,majori=-32000,1
    for i=1,3 do
        local d=abs(fwd[i])
        if d>majord then
            majori,majord=i,d
        end
    end

    local minord,minori=-32000,1
    for i=1,3 do
        if i!=majori then
            local d=abs(fwd[i])
            if d>minord then
                minori,minord=i,d
            end
        end
    end
    local last={
        {-1,3,2},
        {3,-1,1},
        {2,1,-1}
    }
    return majori,minori,last[majori][minori]
end

function collect_blocks(grid,cam,majori,minori,lasti,extents,visible_blocks)    
    local last_shift=(3-lasti)<<3
    local last_mask,last0,last1=0xff>>last_shift,extents[lasti].lo,extents[lasti].hi    
    local last_fix=cam.pos[lasti]\1
    local lastc=last_fix
    if lastc<last0 then
        lastc,last_fix=last0-1
    elseif lastc>last1 then
        lastc,last_fix=last1+1
    end   
    local draw_last=function(face_mask,idx)
        for last=last0,lastc-1 do        
            local idx=idx|last>>>last_shift
            local id=grid[idx]
            if id then
                add(visible_blocks,id)
                add(visible_blocks,face_mask|(0x01.0101&last_mask))            
                add(visible_blocks,idx)
            end
        end
        -- flip side
        for last=last1,lastc+1,-1 do        
            local idx=idx|last>>>last_shift
            local id=grid[idx]
            if id then
                add(visible_blocks,id)
                add(visible_blocks,face_mask|(0x02.0202&last_mask))            
                add(visible_blocks,idx)
            end
        end
        if last_fix then
            local idx=idx|lastc>>>last_shift
            local id=grid[idx]
            if id then
                add(visible_blocks,id)
                add(visible_blocks,face_mask)            
                add(visible_blocks,idx)
            end
        end
    end     

    local minor_shift=(3-minori)<<3
    local minor_mask,minor0,minor1=0xff>>minor_shift,extents[minori].lo,extents[minori].hi
    local minor_fix=cam.pos[minori]\1
    local minorc=minor_fix
    if minorc<minor0 then
        minorc,minor_fix=minor0-1
    elseif minorc>minor1 then
        minorc,minor_fix=minor1+1
    end   
    local draw_minor=function(face_mask,idx)
        for minor=minor0,minorc-1 do        
            draw_last(face_mask|(0x01.0101&minor_mask),idx|minor>>>minor_shift)
        end
        -- flip side
        for minor=minor1,minorc+1,-1 do        
            draw_last(face_mask|(0x02.0202&minor_mask),idx|minor>>>minor_shift)
        end
        -- camera fix?
        if minor_fix then
            draw_last(face_mask,idx|minorc>>>minor_shift)
        end
    end 

    --[[
    local draw_minor=function(mask,idx)
        for idx=minor0|idx,minor1|idx,1>>minor_shift do
            for idx=last0|idx,last1|idx,1>>last_shift do
                local id=grid[idx]
                if id then
                    local ox,oy,oz=(idx&0x0.00ff)<<16,(idx&0x0.ff)<<8,idx&0xff
                    local x,y,z=ox+0.5,oy+0.5,oz+0.5
                    local ax,ay,az=m1*x+m5*y+m9*z+m13,m2*x+m6*y+m10*z+m14,m3*x+m7*y+m11*z+m15
                    if az<-1 then
                        -- a tiny bit of perspective
                        local w=fov/az
                        local x0,y0,r=xcenter+scale*ax*w,ycenter-scale*ay*w,-scale*w/4
                        --rectfill(x0,y0,ceil(x0),ceil(y0),_palette[id])
                        --circfill(x0,y0,r+0.5,_palette[id])
                        if layer then
                            local active_layer=idx&0xff
                            if layer==active_layer then
                                rectfill(x0-r,y0-r,ceil(x0+r),ceil(y0+r),_palette[id])
                            elseif layer>active_layer then
                                rect(x0-r,y0-r,ceil(x0+r),ceil(y0+r),_palette[id])
                            end
                        else
                            rectfill(x0-r,y0-r,ceil(x0+r),ceil(y0+r),_palette[id])
                        end
                    end
                end
            end
        end
    end    
    ]]

    -- main render loop
    local major0,major1=extents[majori].lo,extents[majori].hi
    local major_fix=cam.pos[majori]\1
    local majorc=major_fix
    if majorc<major0 then
        majorc,major_fix=major0-1
	elseif majorc>major1 then
		majorc,major_fix=major1+1
    end    
    local major_shift=(3-majori)<<3
    local major_mask=0xff>>major_shift

    for major=major0,majorc-1 do        
        draw_minor(0x01.0101&major_mask,major>>major_shift)
    end
    -- flip side
    for major=major1,majorc+1,-1 do        
        draw_minor(0x02.0202&major_mask,major>>major_shift)
    end
    if major_fix then
        draw_minor(0,majorc>>major_shift)
    end
end

-- modes:
-- 1: fast
-- 2: layered
-- 3: render (normal)
function draw_grid(grid,cam,mode,layer)
    local visible_blocks,force_adj={}
    local m,fov,xcenter,ycenter,scale=cam.m,cam.fov,cam.xcenter,cam.ycenter,cam.scale

    local extents={}
    local majori,minori,lasti=get_majors(cam)
    local major_mask=0xff>>((3-majori)<<3)
    -- 
    for i=1,3 do
        extents[i]={lo=0,hi=_grid_size}
    end
    -- draw only 1 slice
    if mode==2 then
        extents[majori].lo=layer
        extents[majori].hi=layer
        force_adj=true
    elseif mode==3 then
        if cam.pos[majori]>layer then
            extents[majori].hi=layer-1
        else
            extents[majori].lo=layer+1
        end
        -- nothing to draw?
        if(extents[majori].hi-extents[majori].lo<0) return
    end

    -- viz blocks
    collect_blocks(grid,cam,majori,minori,lasti,extents,visible_blocks)

    local masks={0x0.00ff,0x0.ff,0xff}
    local m1,m5,m9,m13,m2,m6,m10,m14,m3,m7,m11,m15=m[1],m[5],m[9],m[13],m[2],m[6],m[10],m[14],m[3],m[7],m[11],m[15]
    local cache,verts,faces={},{},cube.faces

    if mode==1 then
        for i=1,#visible_blocks,3 do
            local id,idx=visible_blocks[i],visible_blocks[i+2]
    
            local ox,oy,oz=(idx&0x0.00ff)<<16,(idx&0x0.ff)<<8,idx&0xff
            local x,y,z=ox+0.5,oy+0.5,oz+0.5
            local ax,ay,az=m1*x+m5*y+m9*z+m13,m2*x+m6*y+m10*z+m14,m3*x+m7*y+m11*z+m15
            if az<-1 then
                -- a tiny bit of perspective
                local w=-0.1--fov/az
                local x0,y0,r=xcenter+scale*ax*w,ycenter-scale*ay*w,ceil(-scale*w/4)+0.5
                --rectfill(x0,y0,ceil(x0),ceil(y0),_palette[id])
                --circfill(x0,y0,r+0.5,_palette[id])
                
                rectfill(x0-r,y0-r,ceil(x0+r),ceil(y0+r),_palette[id])
            end 
        end      
        return
    end
    -- render in order
    local polydraw=function(p,np,c,side)
        polyfill(p,np,c)
        if(mode==2 and side&major_mask!=0) polyline(p,np,sget(57,c&0xf))            
    end
    for i=1,#visible_blocks,3 do
        local id,current_mask,idx=visible_blocks[i],visible_blocks[i+1],visible_blocks[i+2]
        -- convert to coord offsets
        local ox,oy,oz=(idx&0x0.00ff)<<16,(idx&0x0.ff)<<8,idx\1
        -- printh("mask: "..tostr(visible_blocks[i],1).." idx: "..tostr(idx,1))
        -- solid block
        local adj={ox,oy,oz}

        for maski,mask in pairs(masks) do
            local active_side=current_mask&mask
            local side=faces[active_side]
            if side then            
                -- check adjacent blocks
                -- todo: create a complement index base on face mask
                local backup=adj[maski]
                local adj_i=backup+side.k
                adj[maski]=adj_i
                local adj_idx=adj[1]>>16|adj[2]>>8|adj[3]
                adj[maski]=backup
                -- outside: draw faces
                -- or not next to block
                if adj_i<0 or adj_i>=_grid_size or force_adj or (not grid[adj_idx]) then
                    for i=1,4 do
                        local vert=side[i]
                        local idx=idx+vert.idx
                        local v=cache[idx]
                        if not v then
                            local x,y,z,code=vert[1]+ox,vert[2]+oy,vert[3]+oz,0
                            local ax,ay,az=m1*x+m5*y+m9*z+m13,m2*x+m6*y+m10*z+m14,m3*x+m7*y+m11*z+m15
                            
                            local w=-0.1--fov/az
                            v={ax,ay,az,x=xcenter+scale*ax*w,y=ycenter-scale*ay*w}
                            cache[idx]=v
                        end
                        verts[i]=v
                    end
                    polydraw(verts,4,_palette[id],active_side)                            
                end
            end
        end      
    end
end

-- camera
function make_cam(x0,y0,scale,fov)
    local focal=fov
	return {
        fov=focal,
		pos={0,0,0},
        xcenter=x0,
        ycenter=y0,
        scale=scale,
		control=function(self,lookat,yangle,zangle,dist)
			local m=m_x_m(
                make_m_from_euler(0,0,zangle),
                make_m_from_euler(yangle,0,0))
			local pos=v_add(lookat,m_fwd(m),dist)   

            self.lookat=v_clone(lookat)

            -- debug
            self.fwd=m_fwd(m)
            self.up=m_up(m)
            self.right=m_right(m)

			-- inverse view matrix
			-- only invert orientation part
			m[2],m[5]=m[5],m[2]
			m[3],m[9]=m[9],m[3]
			m[7],m[10]=m[10],m[7]		

			self.m=m_x_m(m,{
				1,0,0,0,
				0,1,0,0,
				0,0,1,0,
				-pos[1],-pos[2],-pos[3],1
			})
			
			self.pos=pos
		end,
		project=function(self,v)
            local v=m_x_v(self.m,v)
            local x,y,z=v[1],v[2],v[3]
            if(z>-1) return
            local w=-0.1--focal/z
            return x0+scale*x*w,y0-scale*y*w,w
		end,        
        unproject=function(self,x,y,majori,minori,lasti,layer)
            local w=-scale*0.1---scale*fov
            local xe,ye=(x-x0)/w,-(y-y0)/w
            return xe,ye
        end,
        polyline=function(self,pts,c,l)    
            l=l or line
            local p0=pts[#pts]
            local x0,y0,w0=self:project(p0)    
            for i=1,#pts do
                local p1=pts[i]
                local x1,y1,w1=self:project(p1)
                if(w1 and w0) l(x0,y0,x1,y1,c)
                x0,y0,w0=x1,y1,w1
            end
        end
	}
end

-- custom ui elements
function make_voxel_editor()   
	local yangle,zangle=-0.25,0---0.125,0
	local dyangle,dzangle=0,0
    local offsetx,offsety=0,0
    local rotation_mode
    local layer={3,3,3}
    local cam=make_cam(63.5,63.5+6,64,2)
    local quads={
        -- x major
        {        
            {0,0,0},
            {0,1,0},
            {0,1,1},
            {0,0,1}
        },
        -- y major
        {        
            {0,0,0},
            {1,0,0},
            {1,0,1},
            {0,0,1}
        },
        -- z major
        {        
            {0,0,0},
            {1,0,0},
            {1,1,0},
            {0,1,0}
        }
    }
    -- facing direction
    local arrow={
        {0.25,0.5,0},
        {0.25,1,0},
        {0,1,0},
        {0.5,1.5,0},
        {1,1,0},
        {0.75,1,0},
        {0.75,0.5,0}
    }
    local undo_stack={}
    local function apply(idx,col)
        -- color 0: kill grid cell
        _grid[idx]=col>0 and col or nil
        -- apply the change to the mirror
        local x=(idx&0x0.00ff)<<16
        local flipx=_grid_size-x
        if x!=flipx then
            _grid[(idx&0xff.ff00)|flipx>>16]=_grid[idx]
        end
    end
    return is_window({
        draw=function(self)
            local r=self.rect
            clip(r.x,r.y,r.w,r.h)            
            local majori,minori,lasti=get_majors(cam)
            local major_layer,draw_order=layer[majori],1
            -- adjust such that layer plane is aligned with top
            if(cam.pos[majori]>major_layer) major_layer+=1 draw_order=2
            local masks={}
            for i in pairs{majori,minori,lasti} do
                masks[(cam.fwd[i]>0 and 2 or 1)>>((3-i)<<3)]=i
            end
            local function layer_line(minori,lasti)
                local p0={0,0,0}
                p0[majori]=major_layer
                local p1={0,0,0}
                p1[majori]=major_layer
                p1[minori]=_grid_size
                local l=cam.fwd[lasti]>0 and 0 or _grid_size
                p0[lasti]=l
                p1[lasti]=l
                local x0,y0,w0=cam:project(p0)    
                local x1,y1,w1=cam:project(p1)
                if(w1 and w0) dline(x0,y0,x1,y1,11)
            end
            
            for mask,face in pairs(cube.faces) do
                local dir=masks[mask]
                if dir then
                    local pts={}
                    for i=1,4 do
                        pts[i]=v_scale(face[i],_grid_size)
                    end
                    cam:polyline(pts,6)
                    if dir==minori then
                        layer_line(minori,lasti)
                    elseif dir==lasti then
                        layer_line(lasti,minori)
                    end
                    fillp() 
                    if dir==3 then                        
                        -- arrow
                        local pts={}
                        for i,p in pairs(arrow) do
                            p=v_scale(p,(_grid_size+1)/2)
                            pts[i]=v_add(p,{_grid_size/4,2,mask==0x2 and 0 or _grid_size})
                        end
                        cam:polyline(pts,6)
                    end
                    
                end
            end

            if not rotation_mode then
                local draw_cache=function()
                    -- copy to spritesheet
                    memcpy(0x0,0x8000,64*128)
                    local r=self.rect
                    fillp(0x5f5f.c)
                    sspr(r.x,r.y,r.w,r.h,r.x,r.y)
                    fillp()
                    reload()
                end
                if draw_order==1 then
                    draw_grid(_grid,cam,rotation_mode and 1 or 2,layer[majori])
                    draw_cache()
                else
                    draw_cache()
                    draw_grid(_grid,cam,rotation_mode and 1 or 2,layer[majori])
                end
            else
                draw_grid(_grid,cam,rotation_mode and 1 or 2,layer[majori])
            end
            fillp()
            

            -- draw cursor if any
            if current_voxel then
                local pts={}
                for i,p in pairs(quads[majori]) do
                    p=v_add(current_voxel.origin,p,_editor_state.pen_radius)
                    p[majori]=major_layer
                    p[minori]=mid(p[minori],0,_grid_size+1)
                    p[lasti]=mid(p[lasti],0,_grid_size+1)
                    pts[i]=p
                end
                cam:polyline(pts,7)  
            end
             
            clip() 
            if(current_voxel) print(v_tostr(current_voxel.origin),2,120,8)
        end,
        mousemove=function(self,msg)
            local prev_mode=rotation_mode
            if msg.mmb then
                -- capture mouse
                poke(0x5f2d, 0x5)
                -- hide cursor
                self:send({
                    name="cursor"
                })
                dyangle+=msg.mdy
                dzangle-=msg.mdx
                rotation_mode=true
                current_voxel=nil
            else
                poke(0x5f2d, 0x1)
                rotation_mode=nil
            end

            yangle+=dyangle/512
            zangle+=dzangle/512            
            -- friction
            dyangle=dyangle*0.7
            dzangle=dzangle*0.7
            
            local xy=(_grid_size+1)/2
            local center={xy,xy,xy}
            cam:control(center,yangle,zangle,1.5*_grid_size)
            local majori,minori,lasti=get_majors(cam)
            local prev_layer=layer[majori]
            layer[majori]=mid(prev_layer-msg.wheel*sgn(cam.fwd[majori]),0,_grid_size-1)
            local major_layer=layer[majori]
            -- selection
            if not rotation_mode then
                -- previous mode?
                if prev_mode or prev_layer!=major_layer then
                    -- capture 
                    holdframe()
                    cls()
                    draw_grid(_grid,cam,3,layer[majori])
                    -- copy to memory
                    memcpy(0x8000,0x6000,64*128)
                end

                local offset=layer[majori]
                if(cam.pos[majori]>major_layer) offset=1
                local ti,tj=cam:unproject(msg.mx,msg.my,majori,minori,lasti,major_layer)
                local fwd,right,up=cam.fwd,cam.right,cam.up
                local pos=v_clone(cam.pos)
                pos=v_add(pos,right,ti)
                pos=v_add(pos,up,tj)
                -- intersect with major=layer plane
                local t=(major_layer+offset-pos[majori])/fwd[majori]
                local target=v_add(pos,fwd,t)
                ti,tj=target[minori],target[lasti]

                current_voxel=nil
                if ti==mid(ti,0,_grid_size) and tj==mid(tj,0,_grid_size) then
                    local o={0,0,0}
                    o[majori]=major_layer
                    o[minori]=ti\1
                    o[lasti]=tj\1
                    current_voxel={
                        origin=o
                    }
                end

                if current_voxel then
                    local o=current_voxel.origin
                    local idx=o[1]>>16|o[2]>>8|o[3]
                    idx+=offsetx>>16|offsety>>8
                    self:send({
                        name="cursor",
                        cursor="aim"
                    })
                    if msg.lmb then
                        -- click!
                        local col=_editor_state.selected_color
                        -- anything to do?
                        for x=max(0,o[1]),min(_grid_size+1,o[1]+_editor_state.pen_radius-1) do
                            for y=max(0,o[2]),min(_grid_size+1,o[2]+_editor_state.pen_radius-1) do
                                local idx=x>>16|y>>8|o[3]
            
                                if (_grid[idx] or 0)!=col then
                                    -- previous state for undo
                                    add(undo_stack,{idx=idx,col=_grid[idx] or 0})
                                    -- keep undo stack limited
                                    if(#undo_stack>250) deli(undo_stack,1)                            
                                    apply(idx,col)
                                end
                            end
                        end
                    elseif msg.rmbp then
                        _editor_state.selected_color=_grid[idx] or 0
                    end            
                end
            end
        end,
        undo=function(self,msg)      
            -- nothing to undo 
            if(#undo_stack==0) return
            local prev=undo_stack[#undo_stack]
            undo_stack[#undo_stack]=nil
            apply(prev.idx,prev.col)
        end,
        copy=function(self,msg)
            blah=grid_tostr(_grid)
            local s=str_esc(grid_tostr(_grid))
            printh(s,"@clip")
        end,
        paste=function(self,msg)
            local s=str_unesc(stat(4))
            for i=1,#s do
                assert(blah[i]==s[i],"diff at:"..i.." : "..ord(blah[i]).." / "..ord(s[i]))
            end
            _grid=grid_fromstr(blah)
        end,
        load=function(self,msg)            
            _grid={}
            undo_stack={}  
            if msg.data then         
                _grid=grid_fromstr(msg.data)
            end
        end
    })
end

function grid_tostr(grid)
    local s,size="",0
    for z=0,_grid_size do
        for y=0,_grid_size do
            local checksum,data,idx=0,{},y>>8|z
            -- capture only half of the voxel grid (mirror!)                    
            for x=0,7 do
                local id=grid[idx|x>>16] or 0
                add(data,id)
                checksum+=id
            end
            -- voxels?
            if checksum!=0 then                        
                s..=chr(y<<4|z,unpack(data))
                -- count number of 8 voxels blocks
                size+=1
            end
        end
    end
    -- version + actual len (2 bytes) + data
    return chr(1,size,size>><8)..s
end

function grid_fromstr(data)
    local grid={}
    -- note: version is ignored
    local size=ord(data[2])|ord(data[3])<<8
    for i=0,size-1 do
        local base=4+9*i
        local idx=ord(data[base])    
        -- voxel idx
        idx=(idx&0xf0)>>12|(idx&0xf)
        for x=0,7 do
            local id=ord(data[base+x+1])
            if id!=0 then
                grid[idx|x>>16]=id
                grid[idx|(_grid_size-x)>>16]=id
            end
        end 
    end
    return grid         
end

function pack_archive()
    -- pack current model
    _current_entity.data=grid_tostr(_grid)
    
    --
    local mem=0x0
    -- save magic number
    poke4(mem,_magic_number) mem+=4
    -- save version
    poke(mem,1) mem+=1            
    -- 
    local count_mem=mem
    mem+=1
    local n=0
    for k,ent in pairs(_entities) do
        if ent.data then
            -- save id
            poke(mem,k) mem+=1
            -- data size
            poke2(mem, #ent.data) mem+=2
            -- data bytes 
            poke(mem,ord(ent.data,1,#ent.data)) mem+=#ent.data
            n+=1
        end
    end
    -- number of entries
    poke(count_mem,n)
    cstore(0x0,0x0,mem,"daggers_assets.p8")
    reload()
end

function unpack_archive()
    -- clear up existing data
    memset(0x0,0,0x16)

    -- load any previous cart
    if(reload(0x0,0x0,0x4300,"daggers_assets.p8")==0) return
    -- check magic number
    local mem=0x0
    if($mem!=_magic_number) printh("archive: invalid magic number") return
    mem+=4
    local version,n=@mem,@(mem+1)
    assert(version==1,"unknown/invalid version: "..version)
    mem+=2
    for i=1,n do
        -- read string
        local k=@mem
        mem+=1
        -- read data
        local len=peek2(mem)
        mem+=2
        _entities[k].data=chr(peek(mem,len))
        mem+=len
    end
    reload()
end

function collect_frames(ent,cb)
    local cam=make_cam(15.5,15.5,16,1)
    local grid,frames=grid_fromstr(ent.data),{}
    -- find middle of voxel entity
    local zmin,zmax=32000,-32000
    for k=0,_grid_size do
        -- find at least one non empty voxel            
        for i=0,_grid_size do                
            local done
            for j=0,_grid_size do
                if grid[i>>16|j>>8|k] then
                    zmin=min(zmin,k)
                    zmax=max(zmax,k)
                    done=true
                    break
                end
            end
            if(done) break
        end
    end
    -- find first row with non-null pixels
    local function find_first_row(start,finish,dir)
        for i=start,finish,dir do            
            local mem=0x6000+i*64
            if $(mem)|$(mem+4)|$(mem+8)|$(mem+12)!=0 then
                return mid(i-dir,start,finish)
            end
        end
        return finish        
    end
    -- find first column with non-null pixels
    local function find_first_column(start,finish,dir)
        for x=start,finish,dir do
            for y=0,31 do
                if(pget(x,y)!=0) return mid(x-1,start,finish)
            end
        end
        return finish
    end
            
    local xy,zoffset=(_grid_size+1)/2,(zmax+zmin+1)/2
    local count,zangles,yangles=0,{},{}
    local angles=ent.angles
    if ent.angles&0xf!=0 then
        local step=1/(ent.angles&0xf)

        for i=0,0.5,step/2 do
            add(zangles,i)
        end
    else
        -- single frame
        zangles={0.25}
    end
    if ent.angles\16!=0 then
        local step=1/(ent.angles\16)

        for i=0,0.5,step/2 do
            add(yangles,i)
        end
    else
        -- single frame
        yangles={0.25}
    end    
    for _,y in ipairs(yangles) do
        for i,z in ipairs(zangles) do
            cls()
            cam:control({xy,xy,zoffset},-y,z,2*_grid_size)
            clip(0,0,32,32)
            draw_grid(grid,cam,nil,true)            
            clip()
            -- find ymin,ymax
            local ymin,ymax=find_first_row(0,31,1),find_first_row(31,0,-1)
            local frame=add(frames,{
                ymin=ymin,ymax=ymax,
                -- x extent
                xmin=find_first_column(0,31,1),
                xmax=find_first_column(31,0,-1)
            })
            -- capture image in array
            for j=ymin,ymax do
                local mem=0x6000+j*64
                add(frame,$mem)
                add(frame,$(mem+4))
                add(frame,$(mem+8))
                add(frame,$(mem+12))
            end
            -- flip()
            if(cb) cb(count)
            count+=1
        end
    end 
    return frames,count
end

-- export entities for game engine
function pack_entities()
    -- save carts
    local mem,cart_id=0x0,0
    local function pack_bytes(b,width)
        width=width or 1
        for i=0,width-1 do
            poke(mem,(b>><(i*8))) mem+=1
            -- end of cart?
            if mem==0x4300 then
                cstore(0x0,0x0,mem,"pic_"..cart_id..".p8")
                mem=0
                cart_id+=1
            end
        end
    end

    -- number of entities
    pack_bytes(#_entities,2)
    for i=1,#_entities do
        local ent=_entities[i]
        if ent.data then
            holdframe()
            local frames,count=collect_frames(ent,function(count)
                if(count%2!=0) return
                cls()
                fillp()
                rectfill(0,0,127,8,8)
                print("eXPORTING SPRITES",1,1,0)
                for j=1,i-1 do
                    print(_entities[j].text..": 100%",2,j*6+4,7)
                end
                print(_entities[i].text..": "..flr(100*count/40).."%",2,i*6+4,7)
                flip()
                holdframe()
            end)        
            -- save entity identifier
            pack_bytes(i)
            -- number of z/y angles (packed in 1 byte)
            pack_bytes(ent.angles)
            -- number of frames
            pack_bytes(count,2)
            for j,frame in ipairs(frames) do
                -- height
                -- note: can be negative!!
                pack_bytes(frame.ymax-frame.ymin+1)
                -- pack x min + width
                pack_bytes(frame.xmin)
                pack_bytes(frame.xmax-frame.xmin+1)
                -- pack y min
                pack_bytes(frame.ymin)                
                -- pack pixels
                for _,pixels in ipairs(frame) do
                    pack_bytes(pixels,4)
                end
            end
        else
            -- "invalid entity"
            pack_bytes(0)
        end
    end
    -- any remaining data?
    if mem!=0 then
        cstore(0x0,0x0,mem,"pic_"..cart_id..".p8")
    end        
    reload()
    cls()
    -- deactivate holdframe
    flip()   
end

function _init()  
    -- integrated fill colors
    poke(0x5f34, 1)

    -- reload previous archive (if any)
    unpack_archive()
    
    -- create ui and callbacks
    _main=main_window({cursor=0,pal={128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0}})
    local banner=_main:add(make_static(8),0,0,127,7)
    local pickers=banner:add(make_list(64,8,8,bounded_binding(_editor_state,"selected_color",0,18)),64,0,80,7)

    -- integrated fillp palette
    for i=0,15 do
        _palette[i]=i|i<<4|0x1000
        _palette[15+i]=i|sget(57,i)<<4|0x1000.a5a5
    end
    for i=0,31 do
        pickers:add(make_color_picker({color=i,palette=_palette},binding(_editor_state,"selected_color")))
    end 

    -- +-
    _main:add(make_button(21,binding(function() 
        _editor_state.selected_color=max(0,_editor_state.selected_color-8)        
    end)),60,0,3,4)
    _main:add(make_button(22,binding(function() 
        _editor_state.selected_color=min(#pickers-1,_editor_state.selected_color+8)      
    end)),60,4,3,4)

    -- hamburger menu
    _main:add(make_button(32,binding(function() 
        local dialog=_main:dialog({border=4},0,8,64,64)
        dialog:add(make_static(8),0,8,64,64)

        -- save entities (external cart)
        dialog:add(make_button({text="sAVE",color=2},binding(function(e)
            pack_archive()

            dialog:close()
        end)),2,10,63)
        -- back to menu (to be back assets)
        dialog:add(make_button({text="cLOSE",color=2},binding(function(e)
            --
            pack_archive()

            load("title.p8")
        end)),2,18,63)
        dialog:add(make_static(8,read_binding(function() return "…………………",2 end)),1,25,63)

        -- objects
        local list=dialog:add(make_list(63,62,8,bounded_binding({selected=0},"selected",0,#_entities-1)),2,33,63,40)
        for k,ent in pairs(_entities) do
            list:add(make_button({text=ent.text,color=2},binding(function(e)
                -- save entity?
                if _current_entity!=ent then
                    -- save current
                    if(_current_entity) _current_entity.data=grid_tostr(_grid)
                    -- load selected
                    _current_entity=ent     
                    _main:send({
                        name="load",
                        data=ent.data
                    })
                end
                --
                dialog:close()
            end)))
        end
    end)),1,0,7)

    -- preview images
    _main:add(make_button(33,binding(function()
        -- 
        cls()
        _current_entity.data=grid_tostr(_grid)
        local frames,count=collect_frames(_current_entity)
        cls()
        local x,y,hmax=0,0,0
        for j,frame in ipairs(frames) do            
            local h=frame.ymax-frame.ymin+1
            if h>0 then
                local w=32*ceil((frame.xmax-frame.xmin+1)/32)
                if(h>hmax) hmax=h
                if(x+w>128) printh(x+w) x=0 y+=hmax+1 hmax=0
                rect(x,y,x+w,y+h,1)
                local base,mem=1,0x6000+(x\2)+y*64
                for i=mem,mem+((h-1)<<6),64 do
                    poke4(i,frame[base],frame[base+1],frame[base+2],frame[base+3])
                    base+=4
                end
                x+=w
            end
            flip()
        end        
        -- wait
        while btn()&0x30==0 do
            flip()
        end
    end)),9,0,6)

    -- generate images to disk
    _main:add(make_button(4,binding(function()
        -- commit latest changes
        if(_current_entity) _current_entity.data=grid_tostr(_grid)
        -- 
        pack_entities()
    end)),18,0,6)

    -- pen +- radius
    _main:add(make_button(21,binding(function()
        _editor_state.pen_radius=min(9,_editor_state.pen_radius+1)      
    end)),24,0,3,4)
    _main:add(make_button(22,binding(function() 
        _editor_state.pen_radius=max(1,_editor_state.pen_radius-1)        
    end)),24,4,3,4)
    _main:add(make_static(1,binding(_editor_state,"pen_radius")),28,0,5,7)
        
    -- edit/select/fill
    for i,s in ipairs({19,18,20}) do
        _main:add(make_radio_button(s,i,binding(_editor_state,"edit_mode")),27+i*8,0,6)
    end

    -- main editor
    _main:add(make_voxel_editor(),0,8,127,119)
    
    -- init keys for cube points
    for i=1,#cube do
        local p=cube[i]
        p.idx=p[1]>>16|p[2]>>8|p[3]
    end    

    -- bind verts to face (avoids 1 indirection)
    for _,face in pairs(cube.faces) do
        for i=1,4 do            
            face[i]=cube[face[i]]
        end
    end

    -- load "default" model
    _current_entity=_entities[1]    
    _main:send({
        name="load",
        data=_current_entity.data
    })    
    -- clear grid
    --[[
    _grid={}
    for i=0,_grid_size do
        for j=0,_grid_size do
            for k=0,_grid_size do
                local idx=i>>16|j>>8|k
                _grid[idx]=7
            end
        end
    end
    for i=1,_grid_size-1 do
        for j=1,_grid_size-1 do
            for k=0,_grid_size do
                local idx=i>>16|j>>8|k
                _grid[idx]=nil
            end
        end
    end
    for i=1,_grid_size-1 do
        for j=0,_grid_size do
            for k=1,_grid_size-1 do
                local idx=i>>16|j>>8|k
                _grid[idx]=nil
            end
        end
    end
    for i=0,_grid_size do
        for j=1,_grid_size-1 do
            for k=1,_grid_size-1 do
                local idx=i>>16|j>>8|k
                _grid[idx]=nil
            end
        end
    end
    ]]
end