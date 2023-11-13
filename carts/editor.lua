
-- to validate archive presence
local _magic_number=0x8764.1359

local _hw_palette=split"128,130,133,5,134,137,7,136,8,138,139,3,131,129,6,0"
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
    level=1
}

local _grid={}
local _grid_size=14

-- color palette
local _palette={}

-- game entities
local default_angles=0x88
-- note: new entities must be added at the end
local _entities={
    {id=1,text="sKULL",angles=default_angles,sort=1},
    {id=2,text="rEAPER",angles=default_angles},
    -- animation
    {id=3,text="bLOOD0",angles=0},
    {id=4,text="bLOOD1",angles=0},
    {id=5,text="bLOOD2",angles=0},
    {id=6,text="dAGGER0",angles=default_angles},
    {id=7,text="dAGGER1",angles=default_angles},
    {id=8,text="dAGGER2",angles=0x08,sort=2},
    -- green goo
    {id=12,text="gOOO0",angles=0},
    {id=13,text="gOOO1",angles=0},
    {id=14,text="gOOO2",angles=0},
    -- egg
    {id=15,text="eGG",angles=0x44},
    -- spider0
    {id=16,text="sPIDERLING0",angles=default_angles},
    {id=17,text="sPIDERLING1",angles=default_angles},
    -- worm head+segment
    {id=18,text="wORM0",angles=default_angles},
    {id=19,text="wORM1",angles=default_angles},
    -- jewel
    {id=20,text="jEWEL",angles=0x44},
    -- worm segment without jewel
    {id=21,text="wORM2",angles=default_angles},
    -- squid tentacles
    {id=22,text="tENTACLE0",angles=default_angles},
    {id=23,text="tENTACLE1",angles=default_angles,no_export=true},
    -- squid base
    {id=24,text="sQUID0",angles=0x08,no_export=true},
    -- no jewel face
    {id=25,text="sQUID1",angles=0x08,bottom=24},
    -- face with jewel
    {id=26,text="sQUID2",angles=0x08,bottom=24},
    -- spider "face"
    {id=27,text="sPIDER0",angles=0x08,no_export=true},
    -- spider "top"
    {id=28,text="sPIDER1",angles=0x08,bottom=27},
    -- sparks
    {id=29,text="sPARK0",angles=0},
    {id=30,text="sPARK1",angles=0},
    {id=31,text="sPARK2",angles=0},
    -- ooze mine
    {id=32,text="mINE",angles=default_angles}
}
-- keep some slack in case some more entities mush be pushed before
local _entities_by_id,sort_min={},10
for _,ent in pairs(_entities) do
    _entities_by_id[ent.id]=ent
    ent.sort=ent.sort or sort_min
    sort_min+=1
end

local _current_entity

-- draw cube help
local cube={
    split"0,0,0",
    split"1,0,0",
    split"1,1,0",
    split"0,1,0",
    split"0,0,1",
    split"1,0,1",
    split"1,1,1",
    split"0,1,1",
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

    local extents
    local majori,minori,lasti=get_majors(cam)
    local major_mask=0xff>>((3-majori)<<3)
    -- 
    if not cam.extents then
        extents={}
        for i=1,3 do
            extents[i]={lo=0,hi=_grid_size}
        end
    else
        extents=cam.extents
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
                            -- some perspective
                            local w=mode and -0.1 or 3/az
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
            self.fwd=m_fwd(m)
            self.right=m_right(m)
            self.up=m_up(m)

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
        project3d=function(self,v)
            local v=m_x_v(self.m,v)
            local x,y,z=v[1],v[2],v[3]
            if(z>-1) return
            local w=32/z
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
    local rotation_mode,ghost_dirty
    local layer={3,3,3}
    local cam=make_cam(63.5,63.5,64,2)
    local quads={
        -- x major
        {        
            split"0,0,0",
            split"0,1,0",
            split"0,1,1",
            split"0,0,1"
        },
        -- y major
        {        
            split"0,0,0",
            split"1,0,0",
            split"1,0,1",
            split"0,0,1"
        },
        -- z major
        {        
            split"0,0,0",
            split"1,0,0",
            split"1,1,0",
            split"0,1,0"
        }
    }
    -- facing direction
    local arrow={
        split"0.25,0.5,0",
        split"0.25,1,0",
        split"0,1,0",
        split"0.5,1.5,0",
        split"1,1,0",
        split"0.75,1,0",
        split"0.75,0.5,0",
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
                p1[minori]=_grid_size+1
                local l=cam.fwd[lasti]>0 and 0 or _grid_size+1
                p0[lasti]=l
                p1[lasti]=l
                local x0,y0,w0=cam:project(p0)    
                local x1,y1,w1=cam:project(p1)
                if(w1 and w0) dline(x0,y0,x1,y1,11)
            end
            
            -- cube
            for mask,face in pairs(cube.faces) do
                local dir=masks[mask]
                if dir then
                    local pts={}
                    for i=1,4 do
                        pts[i]=v_scale(face[i],_grid_size+1)
                    end
                    cam:polyline(pts,0x66)
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
                            p=v_scale(p,_grid_size/2+1)
                            pts[i]=v_add(p,{_grid_size/4,2,mask==0x2 and 0 or _grid_size+1})
                        end
                        cam:polyline(pts,0x66)
                    end
                    
                end
            end

            if not rotation_mode and current_voxel then
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
                draw_grid(_grid,cam,1,layer[majori])
            end
            fillp()
            

            -- draw cursor if any
            if current_voxel then
                local pts={}
                for i,p in pairs(quads[majori]) do
                    p=v_add(current_voxel.origin,p)
                    p[majori]=major_layer
                    p[minori]=mid(p[minori],0,_grid_size+1)
                    p[lasti]=mid(p[lasti],0,_grid_size+1)
                    pts[i]=p
                end
                cam:polyline(pts,7)  
            end
             
            clip() 
            if current_voxel then
                local x,y,z=unpack(current_voxel.origin)
                print("X:"..x,0,103,1)
                print("Y:"..y,0,109,1)
                print("LAYER:"..z,0,115,1)                
            end
        end,
        mousemove=function(self,msg)
            local prev_mode=rotation_mode
            if msg.mmb then
                dyangle+=msg.mdy
                dzangle-=msg.mdx
                rotation_mode,current_voxel=true
            elseif msg.btn&0xf!=0 then
                local b=msg.btn
                local dx,dy=b\2%2-b%2,b\8%2-b\4%2
                dyangle-=2*dy
                dzangle+=2*dx
                rotation_mode,current_voxel=true
            else
                rotation_mode=nil
            end
            if rotation_mode then
                -- hide cursor
                self:send({
                    name="cursor"
                })
            end
            yangle=mid(yangle+dyangle/512,-0.5,0)
            zangle+=dzangle/512

            -- friction
            dyangle=dyangle*0.7
            dzangle=dzangle*0.7
            
            local xy=(_grid_size+1)/2
            local center={xy,xy,xy}
            cam:control(center,yangle,zangle,1.5*_grid_size)
            local majori,minori,lasti=get_majors(cam)
            local prev_layer=layer[majori]
            layer[majori]=mid(prev_layer+msg.wheel*sgn(cam.fwd[majori]),0,_grid_size)
            local major_layer=layer[majori]
            -- selection
            if not rotation_mode then
                -- previous mode?
                if ghost_dirty or prev_mode or prev_layer!=major_layer then
                    -- capture 
                    holdframe()
                    cls()
                    draw_grid(_grid,cam,3,layer[majori])
                    -- copy to memory
                    memcpy(0x8000,0x6000,64*128)
                    ghost_dirty=nil
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
                if ti==mid(ti,0,_grid_size+1) and tj==mid(tj,0,_grid_size+1) then
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
                        local idx=o[1]>>16|o[2]>>8|o[3]
    
                        if (_grid[idx] or 0)!=col then
                            -- previous state for undo
                            add(undo_stack,{idx=idx,col=_grid[idx] or 0})
                            -- keep undo stack limited
                            if(#undo_stack>250) deli(undo_stack,1)                            
                            apply(idx,col)
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
            printh(str_esc(grid_tostr(_grid)),"@clip")
        end,
        paste=function(self,msg)
            _grid=grid_fromstr(str_unesc(stat(4)))
            ghost_dirty=true
            -- todo: undo
        end,
        load=function(self,msg)            
            _grid={}
            ghost_dirty=true
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
    for k,ent in pairs(_entities_by_id) do
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
    -- number of (actual) entries
    poke(count_mem,n)
    return mem
end

function unpack_archive()
    -- check magic number
    local mem=0x0
    if($mem!=_magic_number) printh("archive: invalid magic number") return
    mem+=4
    local version,n=@mem,@(mem+1)
    assert(version==1,"unknown/invalid version: "..version)
    mem+=2
    for i=1,n do
        -- read entity identifier
        local id=@mem
        mem+=1
        -- read data
        local len=peek2(mem)
        mem+=2
        -- drop "obsolete" entries
        if(_entities_by_id[id]) _entities_by_id[id].data=chr(peek(mem,len))
        mem+=len
    end    
end

function collect_frames(ent,cb)
    local trans_color,zmin,zmax=15,32000,-32000
    local grid,frames=grid_fromstr(ent.data),{}
    local ymax,extents=31,{
        {lo=0,hi=_grid_size},
        {lo=0,hi=_grid_size},
        {lo=0,hi=_grid_size}}
    if ent.bottom then
        -- find linked
        local linked=_entities_by_id[ent.bottom]
        if linked.data then
            local other_grid=grid_fromstr(linked.data)
            for idx,v in pairs(grid) do
                other_grid[idx+_grid_size+1]=v
            end
            extents[3].hi=2*_grid_size
            ymax=63
            grid=other_grid
        end
    end
    local cam=make_cam(15.5,ymax/2,16,1)

    -- find middle of voxel entity
    for k=extents[3].lo,extents[3].hi do
        -- find at least one non empty voxel            
        for i=extents[1].lo,extents[1].hi do                
            local done
            for j=extents[2].lo,extents[2].hi do
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
        for y=start,finish,dir do            
            --local mem=0x6000+i*64
            --if $(mem)|$(mem+4)|$(mem+8)|$(mem+12)!=0xffff then
            --    return mid(i-dir,start,finish)
            --end
            for x=0,31 do
                if(pget(x,y)!=trans_color) return mid(y-1,start,finish)
            end
        end
        return finish        
    end
    -- find first column with non-null pixels
    local function find_first_column(start,finish,dir)
        for x=start,finish,dir do
            for y=0,ymax do
                if(pget(x,y)!=trans_color) return mid(x-1,start,finish)
            end
        end
        return finish
    end
            
    local xy,zoffset,count,zangles,yangles,angles=(_grid_size+1)/2,(zmax+zmin+1)/2,0,{},{},ent.angles
    local zsteps,ysteps=angles&0xf,angles\16
    if zsteps!=0 then
        for i=0,0.5,0.5/zsteps do
            add(zangles,i)
        end
    else
        -- single frame
        zangles={0.25}
    end
    if ysteps!=0 then
        for i=0,0.5,0.5/ysteps do
            add(yangles,i)
        end
    else
        -- single frame
        yangles={0.25}
    end    
    for _,y in inext,yangles do
        for i,z in inext,zangles do
            -- assumes color 15 is not used :)
            cls(15)
            cam:control({xy,xy,zoffset},-y,z,2*_grid_size)
            clip(0,0,32,ymax)
            cam.extents=extents
            draw_grid(grid,cam,nil,true)            
            cam.extents=nil
            clip()
            -- find ymin,ymax
            local ymin,ymax=find_first_row(0,ymax,1),find_first_row(ymax,0,-1)
            local frame=add(frames,{
                ymin=ymin,ymax=ymax,
                -- x extent
                xmin=find_first_column(0,31,1),
                xmax=find_first_column(31,0,-1)
            })
            -- capture image in array
            for j=ymin,ymax do
                local mem=0x6000+j*64
                for mem=mem,mem+12,4 do
                    add(frame,$mem)
                end
            end
            -- flip()
            if(cb) cb(count,count/(#yangles*#zangles))
            count+=1
        end
    end 
    return frames,count
end

-- export entities for game engine
function pack_sprites()
    -- save carts
    local mem,cart_id,sorted_entities=0x0,0,{}
    local function pack_bytes(b,width)
        width=width or 1
        for i=0,width-1 do
            poke(mem,(b>><(i*8))) mem+=1
            -- end of cart?
            if mem==0x4300 then
                cstore(0x0,0x0,mem,"freds72_daggers_pic_"..cart_id..".p8")
                mem=0
                cart_id+=1
            end
        end
    end
    -- need number of valid entities :/
    for ent in all(_entities) do
        if ent.data and not ent.no_export then
            local insert_i=#sorted_entities+1
            -- basic insertion sort
            for i,other_ent in inext,sorted_entities do          
              if(other_ent.sort>ent.sort) insert_i=i break
            end
            -- thing offset+cam offset
            add(sorted_entities,ent,insert_i)
        end
    end
    -- number of entities
    pack_bytes(#sorted_entities,2)
    local i=0
    for i,ent in inext,sorted_entities do
        if ent.data and not ent.no_export then
            holdframe()
            local frames,count=collect_frames(ent,function(count,ratio)
                if(count%2!=0) return
                cls()
                fillp()
                rectfill(0,0,127,7,8)
                print("gENERATING aSSETS ["..flr(100*(i/#sorted_entities)).."%]",1,1,7)
                rectfill(0,9,128*ratio,10,9)
                -- print(_entities[i].text..": "..flr(100*count/40).."%",2,i*6+4,7)
                flip()
                pal(_hw_palette,1)
                holdframe()
            end)
            -- save entity identifier
            pack_bytes(ent.id)
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
            i+=1
        end
    end
    -- any remaining data?
    if mem!=0 then
        cstore(0x0,0x0,mem,"freds72_daggers_pic_"..cart_id..".p8")
    end        
    reload()
    cls()
    -- deactivate holdframe
    flip()   
end

function _init()  
    -- custom font
    -- source: https://somepx.itch.io/humble-fonts-tiny-ii
    ?"\^@56000800⁴⁸⁶\0\0¹\0\0\0\0\0\0\0 \0\0\0 \0²\0\0\0\0■■■■■\0\0\0▮¹■■▒■ ■■■」!■\0\0\0▮■■▮\0■!■■■■!■\0\0²\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0⁷⁷⁷⁷⁷\0\0\0\0⁷⁷⁷\0\0\0\0\0⁷⁵⁷\0\0\0\0\0⁵²⁵\0\0\0\0\0⁵\0⁵\0\0\0\0\0⁵⁵⁵\0\0\0\0⁴⁶⁷⁶⁴\0\0\0¹³⁷³¹\0\0\0⁷¹¹¹\0\0\0\0\0⁴⁴⁴⁷\0\0\0⁵⁷²⁷²\0\0\0\0\0\0\0‖\0\0\0\0\0\0¹²\0\0\0\0\0\0³³\0\0\0⁵⁵\0\0\0\0\0\0²⁵²\0\0\0\0\0\0\0\0\0\0\0\0\0²²²²\0²\0\0\n⁵\0\0\0\0\0\0\n゜\n゜⁸\0\0\0⁷³⁶⁷²\0\0\0⁵⁴²¹⁵\0\0\0\0⁴²◀\t◀\0\0²¹\0\0\0\0\0\0²¹¹¹¹²\0\0²⁴⁴⁴⁴²\0\0⁵²⁷²⁵\0\0\0\0²⁷²\0\0\0\0\0\0\0²¹\0\0\0\0\0⁷\0\0\0\0\0\0\0\0\0²\0\0\0⁴²²²¹\0\0\0⁶\t\rᵇ⁶\0\0\0²³²²⁷\0\0\0⁷ᶜ⁶¹ᶠ\0\0\0⁷ᶜ⁶⁸ᶠ\0\0\0⁵⁵ᶠ⁴⁴\0\0\0ᶠ¹⁶ᶜ⁷\0\0\0⁴²⁷\t⁶\0\0\0ᶠ⁸⁴²²\0\0\0⁶\t⁶\t⁶\0\0\0⁶\tᵉ⁴²\0\0\0\0²\0²\0\0\0\0\0²\0²¹\0\0\0⁴²¹²⁴\0\0\0\0⁷\0⁷\0\0\0\0¹²⁴²¹\0\0\0²⁵⁴²\0²\0\0²⁵⁵¹⁶\0\0\0\0⁶⁸ᵇ⁶\0\0\0¹⁵\t\t⁶\0\0\0\0⁶¹¹⁶\0\0\0⁸\n\t\t⁶\0\0\0\0ᵉ\t⁵ᵉ\0\0\0ᶜ²ᵉ³²¹\0\0\0ᵉ\t\r\n⁴\0\0¹⁵ᵇ\t\t⁴\0\0²\0³²²⁷\0\0\0ᶜ⁸⁸\t⁶\0\0¹\t⁵ᵇ\t⁴\0\0¹¹¹¹⁶\0\0\0\0\n▶‖‖\0\0\0\0⁶\t\t\t\0\0\0\0⁶\t\t⁶\0\0\0\0⁶\t\t⁵¹\0\0\0⁶\t\t\n⁸\0\0\0\rᵇ¹¹\0\0\0\0ᵉ³⁸ᶠ\0\0\0\0²ᵉ³²ᶜ\0\0\0\t\t\t⁶\0\0\0\0\t\t⁵³\0\0\0\0‖‖‖ᵇ\0\0\0\0\t⁶⁴\t\0\0\0\0\t\tᵇ⁴³\0\0\0⁷⁴²⁷\0\0\0³¹¹¹¹³\0\0¹¹³²²\0\0\0⁶⁴⁴⁴⁴⁶\0\0²⁵\0\0\0\0\0\0\0\0\0\0⁷\0\0\0²⁴\0\0\0\0\0\0⁶\tᵇ\r\t\t\0\0⁶\t⁵ᵇ\t⁷\0\0⁶\t¹¹\t⁶\0\0³⁵\t\t\t⁷\0\0⁶¹⁵³\t⁶\0\0⁶¹⁵³¹¹\0\0⁶¹¹\r\t⁶\0\0⁵⁵⁵⁷⁵⁵\0\0⁷²²²²⁷\0\0ᵉ⁸⁸⁸\t⁶\0\0\t\t⁵ᵇ\t\t\0\0²¹¹¹\t⁷\0\0\n▶‖‖‖‖\0\0\nᵇ\r\t\t\t\0\0⁶\t\t\t\t⁶\0\0⁶\t\t\r¹¹\0\0⁶\t\t\t\r\n\0\0⁶\t\t⁵ᵇ\t\0\0ᵉ³⁶⁸⁸⁷\0\0ᶜ³²²²²\0\0\t\t\t\t\t⁶\0\0\t\t\t\t⁵³\0\0‖‖‖‖▶\r\0\0\t\t\t⁶\t\t\0\0\t\t\tᵇ⁴³\0\0⁷⁴²¹¹⁷\0\0⁶²³²⁶\0\0\0²²²²²\0\0\0³²⁶²³\0\0\0\0²‖ᶜ\0\0\0\0\0²⁵²\0\0\0\0○○○○○\0\0\0U*U*U\0\0\0<~j4、\0\0\0>ccw>\0\0\0■D■D■\0\0\0⁴<、゛▮\0\0\0⁸*>、、⁸\0\0006>>、⁸\0\0\0、\"*\"、\0\0\0、、>、⁘\0\0\0、>○*:\0\0\0>gcg>\0\0\0○]○A○\0\0\0008⁸⁸ᵉᵉ\0\0\0>ckc>\0\0\0⁸、>、⁸\0\0\0\0\0U\0\0\0\0\0>scs>\0\0\0⁸、○>\"\0\0\0「$JZ$「\0\0>wcc>\0\0\0\0⁵R \0\0\0\0\0■*D\0\0\0\0>kwk>\0\0\0○\0○\0○\0\0\0UUUUU\0\0\0⁸、>\\Hp\0\0\0▮ |:□\0\0「$タししタ\0\0⁸、>⁸\">\0\0\0000JF.\0\0\0\0゛zz~x\0\0、\">>>>\0\0⁴ᶜ、、ᶜ⁴\0\0⁸>、⁸\">\0\0「<~~<「\0\0\0*\0*\0*\0\0\0>\"\"\">\0\0⁸>⁸ᶜ⁸\0\0\0□?□²、\0\0\0<▮~⁴8\0\0\0²⁷2²2\0\0\0ᶠ²ᵉ▮、\0\0\0>@@ 「\0\0\0>▮⁸⁸▮\0\0\0⁸8⁴²<\0\0\0002⁷□x「\0\0\0zB²\nr\0\0\0\t>Kmf\0\0\0¥'\"s2\0\0\0<JIIF\0\0\0□:□:¥\0\0\0#b\"\"、\0\0\0ᶜ\0⁸*M\0\0\0\0ᶜ□!@\0\0\0}y■=]\0\0\0><⁸゛.\0\0\0⁶$~&▮\0\0\0$N⁴F<\0\0\0\n<ZF0\0\0\0゛⁴゛D8\0\0\0⁘>$⁸⁸\0\0\0:VR0⁸\0\0\0⁴、⁴゛⁶\0\0\0⁸²> 、\0\0\0\"\"& 「\0\0\0>「$r0\0\0\0⁴6,&d\0\0\0>「$B0\0\0\0¥'\"#□\0\0\0ᵉd、(x\0\0\0⁴²⁶+」\0\0\0\0\0ᵉ▮⁸\0\0\0\0\n゜□⁴\0\0\0\0⁴ᶠ‖\r\0\0\0\0⁴ᶜ⁶ᵉ\0\0\0> ⁘⁴²\0\0\0000⁸ᵉ⁸⁸\0\0\0⁸>\" 「\0\0\0>⁸⁸⁸>\0\0\0▮~「⁘□\0\0\0⁴>$\"2\0\0\0⁸>⁸>⁸\0\0\0<$\"▮⁸\0\0\0⁴|□▮⁸\0\0\0>   >\0\0\0$~$ ▮\0\0\0⁶ &▮ᶜ\0\0\0> ▮「&\0\0\0⁴>$⁴8\0\0\0\"$ ▮ᶜ\0\0\0>\"-0ᶜ\0\0\0、⁸>⁸⁴\0\0\0** ▮ᶜ\0\0\0、\0>⁸⁴\0\0\0⁴⁴、$⁴\0\0\0⁸>⁸⁸⁴\0\0\0\0、\0\0>\0\0\0> (▮,\0\0\0⁸>0^⁸\0\0\0   ▮ᵉ\0\0\0▮$$DB\0\0\0²゛²²、\0\0\0>  ▮ᶜ\0\0\0ᶜ□!@\0\0\0\0⁸>⁸**\0\0\0> ⁘⁸▮\0\0\0<\0>\0゛\0\0\0⁸⁴$B~\0\0\0@(▮h⁶\0\0\0゛⁴゛⁴<\0\0\0⁴>$⁴⁴\0\0\0、▮▮▮>\0\0\0゛▮゛▮゛\0\0\0>\0> 「\0\0\0$$$ ▮\0\0\0⁘⁘⁘T2\0\0\0²²\"□ᵉ\0\0\0>\"\"\">\0\0\0>\" ▮ᶜ\0\0\0> < 「\0\0\0⁶  ▮ᵉ\0\0\0\0‖▮⁸⁶\0\0\0\0⁴゛⁘⁴\0\0\0\0\0ᶜ⁸゛\0\0\0\0、「▮、\0\0\0⁸⁴c▮⁸\0\0\0⁸▮c⁴⁸\0\0\0"

    -- reset screen rebasing
    -- enable custom font
    -- enable tile 0 + extended memory
    -- capture mouse
    -- enable lock
    -- cartdata
    -- integrated fill colors
  exec[[poke;0x5f58;0x81
poke;0x5f36;0x8
poke;0x5f2d;0x5
poke;0x5f34;1
cartdata;freds72_daggers]]

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
    
    -- reload previous archive (if any)
    reload(0x0,0x0,0x4300,"freds72_daggers_assets.p8")
    unpack_archive()

    -- restore sprites & ramps
    local _reload=reload
    reload=function(...)
        _reload(...)
        local data="▮■¹\0\0▮\0\0\0▮\0\0\0\0\0\0Uuᶜ\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0qw‖\0\0q¹\0\0q¹\0\0\0\0\0◝◝\n\0\0\0\0\0\0\0\0\0¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0qw¹\0▮q■\0▮\0▮\0\0\0\0\0wW⁷\0\0\0\0\0\0\0\0\0□\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0qu▶\0qqW¹q\0p¹\0\0\0\0よ∧\n\0\0\0\0\0\0\0\0\0#\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0QQw¹Qww¹▮\0▮\0\0\0\0\0コ웃ᵇ\0\0\0\0\0\0\0\0\0004\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0▮▮‖\0▮uW¹\0q¹\0\0\0\0\0ネ(\r\0\0\0\0\0\0\0\0\0E\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0¹\0\0q‖\0\0▮\0\0\0\0\0\0\"ヌᵉ\0\0\0\0\0\0\0\0\0&\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0▮¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0W\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0(\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0웃\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0む\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0ょ\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0チ\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0メ\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0゛\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0に\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0■\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\"■\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0003\"■¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0D33\"¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0UED3□\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0ffUE4#□\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0wwgfUD3□\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0☉(\"■¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0▥▥▥☉\"¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0ちちむょメ¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0めょアツ゛\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0アツツモ¹\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0メモ■\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0゛■\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0◝ᵉ\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
        poke(0x0,ord(data,1,#data))  
    end    
    reload()

    -- integrated fillp palette
    for i=0,15 do
        _palette[i]=i|i<<4|0x1000
        _palette[15+i]=i|sget(57,i)<<4|0x1000.a5a5
    end
    
    if stat(6)=="generate" then
        -- "commit" generation
        exec[[pack_sprites
dset;63;0
load;freds72_daggers_title.p8
load;freds72_daggers_title_mini.p8
load;#freds72_daggers_title]]
    end

    -- clear screen cache
    memset(0x8000,0,0x2000)

    -- create ui and callbacks
    _main=main_window({cursor=0,pal=_hw_palette})

    -- main editor
    _main:add(make_voxel_editor(),0,8,127,119)

    -- controls 
    _main:add(make_color_picker(_palette,binding(_editor_state,"selected_color")))

    local left_panel=_main:add(make_vpanel(true))
    left_panel:add(make_button("MODELS\152",binding(function()
        local dialog=_main:dialog()
        dialog:add(is_window{
            draw=function()
                print("SELECT MODEL",32,0,6)
            end
        })
        local left_panel=dialog:add(make_vpanel(true))
        left_panel:add(make_button("BACK\138",binding(function() dialog:close() end)))
        local lists={
            [0]=dialog:add(make_vlist(0,8)),
            dialog:add(make_vlist(64,8))}
        for i,ent in inext,_entities do
            local list=lists[i\16]
            list:add(make_button(ent.text,binding(function(e)
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
    end)))

    left_panel:add(make_button("UNDO\158",binding(function() _main:send({name="undo"}) end)),8)
    left_panel:add(make_button("COPY\159",binding(function() _main:send({name="copy"}) end)))

    local right_panel=_main:add(make_vpanel())

    -- preview images
    right_panel:add(make_button("\156 PREVIEW",binding(function()
        _current_entity.data=grid_tostr(_grid)
        local frames,count=collect_frames(_current_entity,function(count,ratio)
            cls()
            rectfill(0,1,128*ratio,2,0x99)
            flip()
        end)

        local dyangle,dzangle,yangle,zangle,zmax,ymax,zoom,gif_ttl,gif_mode=0,0,0.25,0,_current_entity.angles\16,_current_entity.angles&0xf,1,0
        local dialog=_main:dialog()
        local left_panel,right_panel=dialog:add(make_vpanel(true)),dialog:add(make_vpanel())
        left_panel:add(make_button("BACK\138",binding(function() dialog:close() end)))
        local preview_conf={
            grid=true
        }
        left_panel:add(make_radio_button("GRID ON/OFF\164",true,bool_binding(preview_conf,"grid")),8)
    
        right_panel:add(make_button("\163GIF",binding(function() 
            if(gif_mode) return
            gif_ttl=8*30+1
            gif_mode=true
        end)))

        dialog:add(is_window{
            update=function()
                gif_ttl=max(gif_ttl-1)
                left_panel:show(not gif_mode) 
                right_panel:show(not gif_mode) 
            end,
            draw=function(self)
                -- 3d points
                if preview_conf.grid then
                    local cam=make_cam(63.5,63.5,1)
                    cam:control({0,0,0},-yangle,zangle,1/zoom)
                    for i=-5,5 do
                        for j=-5,5 do
                            local x,y,w=cam:project3d({i,j,-1})
                            if w then
                                pset(x,y,mid(-w/4,1,4))
                            end
                        end
                    end
                end

                local side,flip=0
                if ymax!=0 then
                    local step=1/(ymax<<1)
                    side=((zangle+step/2)&0x0.ffff)\step
                    if(side>ymax) side=ymax-(side%ymax) flip=true
                end
            
                -- up/down angle
                local yside=0
                if zmax!=0 then
                    local step=1/(zmax<<1)
                    yside=((step/2+yangle)&0x0.ffff)\step
                    if(yside>zmax) yside=zmax-(yside%zmax)
                end
                
                --printh("y:"..yangle.." z: "..zangle.." => "..side.." / "..tostr(flip))
                local base,frame=1,frames[(ymax+1)*yside+side+1]
                local w,h=frame.xmax-frame.xmin+1,frame.ymax-frame.ymin+1
                if h>0 then
                    for i=32,32+((h-1)<<6),64 do
                        poke4(i,frame[base],frame[base+1],frame[base+2],frame[base+3])
                        base+=4
                    end
                    palt(15,true)
                    palt(0,false)
                    -- copy to middle of spritesheet   
                    local sx,sy=64-zoom*w/2,64-zoom*h/2
                    sspr(64+frame.xmin,0,w,h,sx,sy,w*zoom+(sx&0x0.ffff),h*zoom+(sy&0x0.ffff),flip)
                    palt()
                end
                if not gif_mode then
                    local s=_current_entity.text.." PREVIEW"
                    ?s,64-print(s,0,512)/2,120,6
                end
                if(gif_mode) ?"#DEMIDAGGERS",2,122,8
                if(gif_ttl==0 and gif_mode) gif_mode=nil extcmd("video") 
            end,
            mousemove=function(self,msg)
                if gif_ttl>0 then
                    zangle+=1/(8*30)
                    -- hide cursor
                    self:send({
                        name="cursor"
                    })
                else
                    local rotating
                    if msg.mmb then
                        dzangle-=msg.mdx
                        dyangle+=msg.mdy
                        rotating=true
                    elseif msg.btn&0xf!=0 then
                        local b=msg.btn
                        local dx,dy=b\2%2-b%2,b\8%2-b\4%2
                        dyangle-=2*dy
                        dzangle+=2*dx
                        rotating=true
                    else
                        zoom=mid(zoom+msg.wheel/4,0.25,8)
                    end
                    if rotating then
                        -- hide cursor
                        self:send({
                            name="cursor"
                        })
                    end
                        
                    zangle+=dzangle/1024
                    if(zmax>0) yangle=mid(yangle+dyangle/1024,0.01,0.49)
                    --zangle=mid(zangle+dzangle/256,0,zmax)
                    -- friction
                    dyangle=dyangle*0.7
                    dzangle=dzangle*0.7
                end
            end
        })
    end)))

    right_panel:add(make_button("\161PLAY",binding(function()
        -- commit latest changes
        if(_current_entity) _current_entity.data=grid_tostr(_grid)
        -- 
        exec[[pack_sprites
load;freds72_daggers_title.p8
load;freds72_daggers_title_mini.p8
load;#freds72_daggers_title_mini]]            
    end)),8)
    right_panel:add(make_button("\138TO TITLE",binding(function()
        cstore(0x0,0x0,pack_archive(),"freds72_daggers_assets.p8")
        exec[[load;freds72_daggers_title.p8
load;freds72_daggers_title_mini.p8
load;#freds72_daggers_title_mini]]            
    end)))

    right_panel:add(make_button("\162SAVE",binding(function() 
        cstore(0x0,0x0,pack_archive(),"freds72_daggers_assets.p8")
        reload()    
    end)),8)
    right_panel:add(make_button("\157EXPORT",binding(function() 
        printh(str_esc(chr(peek(0,pack_archive()))),"freds72_daggers_asssets")
        reload()
    end)))

    local function reload_entity()
        -- load "default" model
        _current_entity=_entities[1]    
        _main:send({
            name="load",
            data=_current_entity.data
        })
    end

    _main.ondrop=function(self,msg)        
        exec[[serial;0x800;0x0;0x4300
unpack_archive
reload
reload_entity]]
    end

    -- default model
    reload_entity()
end