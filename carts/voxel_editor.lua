
-- editor state
_editor_state={
    selected_color=4,
    layer=0,
    offset={0,0,0},
    -- 1: pen
    -- 2: selection
    -- 3: fill
    edit_mode=1,
    level=1
}

_grid={}
_sprite_grid={}
_grid_size=8

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
        {
            [1]={1,4,8,5},
            [-1]={3,2,6,7}
        },
        -- y
        {
            [1]={1,5,6,2},
            [-1]={4,3,7,8}
        },
        -- z
        {
            [1]={1,2,3,4},
            [-1]={6,5,8,7}
        }
    }
}

function draw_cube(cam,o,idx,c,cache,mask)
    local ox,oy,oz=o[1],o[2],o[3]
    local colors=cube.colors[c]
    local verts={}
    local m,scale=cam.m,64*cam.fov
    -- get visible faces (face index + face direction)
    fillp(((ox+oy)&1)*0xffff)
    for maski,k in pairs(mask) do
        -- 
        local side=cube.faces[maski][k]
        local col=colors[maski][k]
        -- check adjacent blocks
        local adj={ox,oy,oz}
        adj[maski]-=k
        local adj_i=adj[maski]
        local adj_idx=adj[1]>>16|adj[2]>>8|adj[3]
        -- outside: draw faces
        -- or not next to block
        if adj_i<0 or adj_i>=8 or (not _grid[adj_idx]) then
            for i,vert in pairs(side) do
                local idx=idx+vert.idx
                local v=cache[idx]
                if not v then
                    local x,y,z=vert[1]+ox,vert[2]+oy,vert[3]+oz
                    x,y,z=m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]
                    local w=scale/z
                    v={x=64+x*w,y=70-y*w}
                    cache[idx]=v
                end
                verts[i]=v
            end
            --polyline(verts,4,maski+k+1)
            polyfill(verts,4,col)
        end
    end
end

function draw_sprite(cam,o,s)
    local ox,oy,oz=o[1],o[2],o[3]
    local m,scale=cam.m,64*cam.fov

    -- position in middle of tile
    local x,y,w=cam:project({ox+0.5,oy+0.5,oz})
    if w then
        w*=-64
        local sx,sy=x-w/2,y-w
        sspr((s&15)<<3,(s\16)<<3,8,8,sx,sy,w+sx%1,w+sy%1)
    end
end

function draw_block(cam,o,cache,mask)
    local ox,oy,oz=o[1],o[2],o[3]
    local idx=ox>>16|oy>>8|oz
    local id=_grid[idx] or _sprite_grid[idx]
    -- nothing at cell
    if(not id) return        
    if id<16 then 
        -- solid block
        draw_cube(cam,o,idx,id,cache,mask) 
    else
        -- sprite 
        draw_sprite(cam,o,id)
    end
end

-- voxel functions
function init_traversal(ray,maxs,t0,t1)
    local function get_bounds(d)
        local o,dir=ray.origin[d],ray.dir[d]
        local tmin = -o / dir
        local tmax = (maxs - o) / dir 
        if dir < 0 then
            tmin,tmax=tmax,tmin
        end    
        return tmin,tmax
    end
    
    local tmin,tmax=-32000,32000
    for i=1,3 do
        local tstart,tend = get_bounds(i)
        -- out?
        if(tstart>t1 or tend<t0) return
        if (tstart > tmin) tmin = tstart
        if (tend < tmax) tmax = tend
    end
    return true,max(tmin,t0),min(tmax,t1)
end

-- voxel traversal on a sqaure grid
-- [0,size[
function voxel_traversal(ray,size,grid)
    local in_grid,tmin,tmax = init_traversal(ray, size, 0, ray.len)
    if (not in_grid) return

    local dir=ray.dir
    local ray_start = v_add(ray.origin,dir,tmin)
    local ray_end = v_add(ray.origin,dir,tmax)

    local function get_step(d)
        local start,dir=ray_start[d],dir[d]
        local curr_i,end_i = max(start\1),max(ray_end[d]\1)
        --[[
        if curr_i<0 and end_i>=size then
            printh("!!!!!!ERROR!!!!!!!!!")
            printh("dim: "..d.." invalid index: "..curr_i.." "..end_i)
            printh("tmin: "..tmin.." tmax:"..tmax)
            printh("start: "..v_tostr(ray_start).." end: "..v_tostr(ray_end))
            printh("o:"..v_tostr(ray.origin).." dir: "..v_tostr(ray.dir))
            stop()
        end
        ]]
        local step = 0
        local tdelta = tmax
        local tmax_d = tmax
        if dir > 0.0 then
            step = 1
            tdelta = 1 / ray.dir[d]
            tmax_d = tmin+(curr_i+1-start)/dir
        elseif dir < 0.0 then
            step = -1
            tdelta = 1 / -ray.dir[d]
            tmax_d = tmin+(curr_i-start)/dir
        end
        return curr_i,end_i,step,tdelta,tmax_d
    end
    
    local i0,i1,stepx,tdeltax,tmaxx = get_step(1)
    local j0,j1,stepy,tdeltay,tmaxy = get_step(2)
    local k0,k1,stepz,tdeltaz,tmaxz = get_step(3)

    -- printh("*******************")
    -- printh(tmin.." --> "..tmax)
    -- printh("i:"..i0..", "..j1.." ["..tdeltax.."]")
    -- printh("j:"..j0..", "..j1.." ["..tdeltay.."]")
    -- printh("k:"..k0..", "..k1.." ["..tdeltaz.."]")

    local dist=0
    local steps={stepx,stepy,stepz}
    while i0!=i1 or j0!=j1 or k0!=k1 do
        local hit        
        if tmaxx < tmaxy and tmaxx < tmaxz then            
            -- x-axis traversal.
            i0 += stepx
            if(i0<0 or i0>=size) return
            tmaxx += tdeltax
            hit=1
        elseif tmaxy < tmaxz then
            -- y-axis traversal.
            j0 += stepy
            if(j0<0 or j0>=size) return
            tmaxy += tdeltay
            hit=2
        else
            -- z-axis traversal.
            k0 += stepz
            if(k0<0 or k0>=size) return
            tmaxz += tdeltaz
            hit=3
        end
        
        --[[
        for i=0,1 do
            for j=0,1 do
                for k=0,1 do                        
                    local x,y,w=cam:project({i0+i,j0+j,k0+k})
                    if(w) pset(x,y,2)
                end
            end
        end
        ]]

        -- something at location?
        local data=grid[i0>>16|j0>>8|k0]  
        --assert(dist<ray.len)  
        if data then
            --local n={0,0,0}
            --n[hit]=-steps[hit]
            --local pos=v_add(ray_start,dir,dist)
            --pos[hit]+=dist*dir[hit]
            -- printh(i0.." "..j0.." "..k0.." dist: "..dist.." side:"..hit)    
            return {
                origin={i0,j0,k0},
                n=n,
                side=hit,
                hit=pos,
                data=data}        
        end
    end
end

function draw_grid(cam,layer)    
    local fwd=cam.fwd
    local majord,majori=-32000,1
    for i=1,3 do
        local d=abs(cam.fwd[i])
        if d>majord then
            majori,majord=i,d
        end
    end

    local minord,minori=-32000,1
    for i=1,3 do
        if i!=majori then
            local d=abs(cam.fwd[i])
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
    local lasti=last[majori][minori]

    local major0,major1=0,7
    if(fwd[majori]<0) major0,major1=major1,major0
    local o,face_mask,cache={},{},{}
    local cam_minor,cam_last=cam.pos[minori]\1,cam.pos[lasti]\1
    face_mask[majori]=sgn(-fwd[majori])
    for major=major0,major1,sgn(fwd[majori]) do
        -- todo: drop sign based iteration, only use left-to-right/middle/right-to-left
        o[majori]=major
        local draw_last=function()
            local last0,last1=0,7
            local dlast=sgn(fwd[lasti])
            local face_sign=sgn(last0-cam_last)
            if(dlast<0) last0,last1,face_sign=last1,last0,sgn(last1-cam_last)   
            local fix
            face_mask[lasti]=face_sign
            for last=last0,last1,dlast do
                if last==cam_last then
                    fix=last
                    -- skip
                    last+=dlast
                    if dlast>0 then
                        last0,last1=last1,last
                    else
                        last0,last1=last1,last
                    end
                    dlast=-dlast
                    face_sign=-face_sign
                    break
                end

                o[lasti]=last                
                --printh("normal: "..last)
                draw_block(cam,o,cache,face_mask)
            end    
            if fix then        
                if last0>=0 and last0<8 and last1>=0 and last1<8 then                
                    face_mask[lasti]=face_sign   
                    for last=last0,last1,dlast do
                        o[lasti]=last        
                        draw_block(cam,o,cache,face_mask)
                    end   
                end         
                o[lasti]=fix       
                face_mask[lasti]=nil
                draw_block(cam,o,cache,face_mask)
            end  
            --if(btn(5)) flip()             
        end
        -- 
        local minor0,minor1=0,7
        local dminor=sgn(fwd[minori])
        local minor_sign=sgn(minor0-cam_minor)
        if(dminor<0) minor0,minor1,minor_sign=minor1,minor0,sgn(minor1-cam_minor)
        local fix
        face_mask[minori]=minor_sign
        for minor=minor0,minor1,dminor do
            if minor==cam_minor then
                fix=minor
                -- skip
                minor+=dminor
                if dminor>0 then
                    minor0,minor1=minor1,minor
                else
                    minor0,minor1=minor1,minor
                end
                dminor=-dminor
                minor_sign=-minor_sign
                -- printh("reverse! ("..minor..") ["..minor0..", "..minor1.."] @"..dminor)
                break
            end        
            o[minori]=minor
            draw_last()
        end

        if fix then 
            if minor0>=0 and minor0<8 and minor1>=0 and minor1<8 then
                face_mask[minori]=minor_sign
                for minor=minor0,minor1,dminor do
                    o[minori]=minor
                    draw_last()
                end            
            end
            o[minori]=fix
            face_mask[minori]=nil
            draw_last()
        end         
    end
    fillp()
end

-- camera
function make_cam(x0,y0,scale,fov)
    local focal=cos(fov/2)
	return {
        fov=focal,
		pos={0,0,0},
		control=function(self,lookat,yangle,zangle,dist)
			local m=m_x_m(
                make_m_from_euler(0,0,zangle),
                make_m_from_euler(yangle,0,0))
			local pos=v_add(lookat,m_fwd(m),dist)            

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
            local w=focal/z
            return x0+scale*x*w,y0-scale*y*w,w
		end,
        unproject=function(self,x,y)
            return -(x-x0)/(scale*focal),(y-y0)/(scale*focal)
        end
	}
end

-- custom ui elements
function make_voxel_editor()   
	local yangle,zangle=-0.25,0
	local dyangle,dzangle=0,0

    local layer=0 
    local cam=make_cam(64,64+6,64,0.20)
    local quad={
        {0,0,0},
        {1,0,0},
        {1,1,0},
        {0,1,0}
    }

    return is_window({
        draw=function(self)
            local r=self.rect
            clip(r.x,r.y,r.w,r.h)
            draw_grid(cam)

            -- draw layer selection

            local pts={}
            for i,p in pairs(quad) do
                p=v_scale(p,_grid_size)
                p[3] = layer
                pts[i]=p
            end
            local xmax,ymax=-32000
            local p0=pts[4]
            local x0,y0,w0=cam:project(p0)    
            for i=1,4 do
                local p1=pts[i]
                local x1,y1,w1=cam:project(p1)
                if(w1 and x1>xmax) xmax,ymax=x1,y1
                if(w1 and w0) line(x0,y0,x1,y1,6)
                x0,y0,w0=x1,y1,w1
            end
            if(ymax) print(layer,xmax+2,ymax-2,7)     
            clip()       
        end,
        mousemove=function(self,msg)
            if msg.mmb then
                poke(0x5f2d, 0x1+0x4)
                -- hide cursor
                self:send({
                    name="cursor"
                })
                dyangle+=msg.mdy
                dzangle-=msg.mdx
            else
                poke(0x5f2d, 0x1)
            end

            yangle+=dyangle/512
            zangle+=dzangle/512            
            -- friction
            dyangle=dyangle*0.7
            dzangle=dzangle*0.7

            layer=mid(layer+msg.wheel,0,256)

            local xyz=_grid_size/2
            cam:control({xyz,xyz,layer},yangle,zangle,_grid_size)
            
            -- selection
            local ti,tj=cam:unproject(msg.mx,msg.my)
            local fwd,right,up=cam.fwd,cam.right,cam.up
            local target=v_add(cam.pos,fwd,-1)
            target=v_add(target,right,ti)
            target=v_add(target,up,tj)
            --local origin=v_clone(cam.pos)
            
            local d=make_v(cam.pos,target)
            local n,l=v_normz(d)
            local ray={
                origin=cam.pos,
                target=target,
                dir=n,
                len=16}    

            local grid={}
            for i=0,7 do
                for j=0,7 do
                    grid[i>>16|j>>8|layer]=true
                end
            end
        
            current_voxel=voxel_traversal(ray,8,grid)
    
            if current_voxel then
                local o=current_voxel.origin
                local idx=o[1]>>16|o[2]>>8|o[3]
                self:send({
                    name="cursor",
                    cursor="aim"
                })
                if msg.lmbp then
                    -- click!
                    local col=_editor_state.selected_color
                    if col==0 then
                        _grid[idx]=nil
                        _sprite_grid[idx]=nil
                    elseif col<16 then                    
                        _grid[idx]=col
                    else
                        _sprite_grid[idx]=col
                    end
                elseif msg.rmbp then
                    _editor_state.selected_color=_grid[idx] or _sprite_grid[idx] or 0
                end            
            end
        end        
    })
end

function _init()
    -- create ui and callbacks
    _main=main_window()
    local banner=_main:add(make_static(8),0,0,127,7)
    local pickers=_main:add(make_static(8),63,0,65,7)
    -- solid color blocks
    for i=0,15 do
        pickers:add(make_color_picker(i,binding(_editor_state,"selected_color")),63+i*4,2,3,3)
    end
    pickers:show(false)
    -- sprite blocks
    local sprite_pickers=_main:add(make_static(8),63,0,65,7)
    for i=0,1 do
        sprite_pickers:add(make_sprite_picker(32+i,32+i,binding(_editor_state,"selected_color")),63+i*4,2,3,3)
    end

    _main:add(make_voxel_editor(),0,8,127,119)
    
    -- save
    _main:add(make_button(16,binding(function() end)),1,0,7)
    -- play
    _main:add(make_button(17,binding(function() end)),9,0)
    -- level id
    _main:add(make_static(2,binding(_editor_state,"level")),15,0,6,7)
    -- +-
    _main:add(make_button(21,binding(function() 
        _editor_state.level=min(9,_editor_state.level+1)      
    end)),22,0,4,4)
    _main:add(make_button(22,binding(function() 
        _editor_state.level=max(1,_editor_state.level-1)        
    end)),22,4,4,4)

    -- edit/select/fill
    for i,s in ipairs({19,18,20}) do
        _main:add(make_radio_button(s,i,binding(_editor_state,"edit_mode")),30+i*8,0)
    end
    
    -- demo voxels
    srand(42)
    for i=0,7 do
        for j=0,7 do
            if(rnd()>0.125) _grid[i>>16|j>>8|0]=11
        end
    end

    -- init keys for cube points
    for i=1,#cube do
        local p=cube[i]
        p.idx=p[1]>>16|p[2]>>8|p[3]
    end    

    -- bind verts to face (avoids 1 indirection)
    for _,sides in pairs(cube.faces) do
        for k,face in pairs(sides) do
            for i,vi in pairs(face) do
                face[i]=cube[vi]
            end
        end
    end

    -- colors (black is out)
    local colors={}
    for base_color=1,15 do
        -- top color
        local side_color_bright=sget(58,base_color)
        local side_color_dark=sget(57,side_color_bright)
        local bottom_color=sget(59,base_color)
        side_color_bright=side_color_bright|side_color_bright<<4
        side_color_dark=side_color_dark|side_color_dark<<4
        colors[base_color]={            
            -- x side
            {
                [-1]=side_color_bright,
                [1]=side_color_bright
            },
            -- y sides
            {
                [-1]=side_color_dark,
                [1]=side_color_dark
            },
            -- z top/bottom
            {
                -- top
                [-1]=base_color|sget(57,base_color)<<4,
                -- bottom
                [1]=bottom_color|bottom_color<<4
            }
        }
    end
    cube.colors=colors
end