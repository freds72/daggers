
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
_sprite_by_id={}
_grid_size=8

-- records non-empty slices per dimension x per-coordinates
-- if _grid_occupancy[3][25] --> at least 1 cube on slice z=25
_grid_occupancy={{},{},{}}

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

local dither_pat={[0]=0b1111111111111111,0b0111111111111111,0b0111111111011111,0b0101111111011111,0b0101111101011111,0b0101101101011111,0b0101101101011110,0b0101101001011110,0b0101101001011010,0b0001101001011010,0b0001101001001010,0b0000101001001010,0b0000101000001010,0b0000001000001010,0b0000001000001000,0b0000000000000000}
function draw_cube(cam,o,idx,c,cache,mask)
    local ox,oy,oz=o[1],o[2],o[3]
    local colors=cube.colors[c]
    local verts={}
    local m,fov=cam.m,cam.fov
    -- get visible faces (face index + face direction)
    --fillp(((ox+oy)&1)*0xffff)

    --[[
    local extents={}
    --fillp()
    for i=1,3 do
        extents[i]={lo=max(cam.lookat[i]\1-4),hi=max(7,cam.lookat[i]\1+4)}
    end
    for i=1,2 do
        if extents[i].lo==o[i]\1 then
            fillp(dither_pat[15-flr(16*(cam.lookat[i]%1))]|0b0.100)
        end
        if extents[i].hi==o[i]\1 then
            fillp(dither_pat[flr(16*(cam.lookat[i]%1))]|0b0.100)
        end
    end
    ]]

    for i=0,2 do
        -- 
        local maski=i+1
        local side=cube.faces[mask&(0x0.00ff<<(8*i))]
        if side then            
            --local col=colors[maski][k]
            -- check adjacent blocks
            local adj={ox,oy,oz}
            -- todo: create a complement index base on face mask
            adj[maski]+=side.k
            local adj_i=adj[maski]
            local adj_idx=adj[1]>>16|adj[2]>>8|adj[3]
            -- outside: draw faces
            -- or not next to block
            if adj_i<0 or adj_i>=8 or (not _grid[adj_idx]) then
                local outcode,clipcode=0xffff,0
                for i=1,4 do
                    local vert=side[i]
                    local idx=idx+vert.idx
                    local v=cache[idx]
                    if not v then
                        local x,y,z,code=vert[1]+ox,vert[2]+oy,vert[3]+oz,0
                        --x=mid(x,extents[1].lo,extents[1].hi)
                        --y=mid(y,extents[2].lo,extents[2].hi)
                        --z=mid(z,extents[3].lo,extents[3].hi)
                        local ax,ay,az=m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]
                        
                        -- todo: arrghhh!!
                    if az>-0.1 then code=2 end
                    if fov*ax>-az then code+=4
                    elseif fov*ax<az then code+=8 end
                    if fov*ay>-az then code+=16
                    elseif fov*ay<az then code+=32 end
                    local w=fov/az
                    v={ax,ay,az,x=64+64*ax*w,y=70-64*ay*w,outcode=code}
                    cache[idx]=v
                    end
                    verts[i]=v
                    outcode&=v.outcode
                    clipcode+=v.outcode&2
                end
                --polyline(verts,4,maski+k+1)
                -- polyfill(verts,4,maski+k+1)
                if outcode==0 then 
                    local np=4
                    if(clipcode>0) verts,np=cam:z_poly_clip(verts,4)
                    if(np>2) polyfill(verts,np,i+1)
                end
            end
        end
    end
    --fillp()    
end


function draw_sprite(cam,o,s,shadow)
    local ox,oy,oz=o[1],o[2],o[3]
    -- position in middle of tile
    local x,y,w=cam:project({ox+0.5,oy+0.5,oz})
    if w then
        w*=-64
        -- convert between sprite id and real image
        s=_sprite_by_id[s]
        local sx,sy=x-w/2,y-w
        if shadow then
            local ref=v_add({ox+0.5,oy+0.5,oz},cam.pos,-1)
            local dx,dy=ref[1],ref[2]
            local zangle=atan2(dx,dy)
            local len=dx*cos(zangle)+dy*sin(zangle)
            local yangle=atan2(len,ref[3])
            local h=-w*sin(yangle)
            ovalfill(sx,y-h/2,sx+w,y+h/2,1)
        end        
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
    if(btn(4)) flip()
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

function collect_blocks(cam,visible_blocks)    
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

    local extents={}
    for i=1,3 do
        extents[i]={lo=max(cam.lookat[i]\1-4),hi=max(7,cam.lookat[i]\1+3)}
    end

    local cam_minor,cam_last=cam.pos[minori]\1,cam.pos[lasti]\1

    local last0,last1=extents[lasti].lo,extents[lasti].hi
    local last_fix=cam_last
    local lastc=last_fix
    if lastc<last0 then
        lastc,last_fix=last0-1
    elseif lastc>last1 then
        lastc,last_fix=last1+1
    end   
    local last_shift=(3-lasti)<<3
    local last_mask=0xff>>last_shift
    local draw_last=function(face_mask,idx)
        for last=last0,lastc-1 do        
            local idx=idx|last>>>last_shift
            local id=_grid[idx] or _sprite_grid[idx]
            if id then
                add(visible_blocks,id)
                add(visible_blocks,face_mask|(0x01.0101&last_mask))            
                add(visible_blocks,idx)
            end
        end
        -- flip side
        for last=last1,lastc+1,-1 do        
            local idx=idx|last>>>last_shift
            local id=_grid[idx] or _sprite_grid[idx]
            if id then
                add(visible_blocks,id)
                add(visible_blocks,face_mask|(0x02.0202&last_mask))            
                add(visible_blocks,idx)
            end
        end
        if last_fix then
            local idx=idx|lastc>>>last_shift
            local id=_grid[idx] or _sprite_grid[idx]
            if id then
                add(visible_blocks,id)
                add(visible_blocks,face_mask)            
                add(visible_blocks,idx)
            end
        end
    end     

    local minor0,minor1=extents[minori].lo,extents[minori].hi
    local minor_fix=cam.pos[minori]\1
    local minorc=minor_fix
    if minorc<minor0 then
        minorc,minor_fix=minor0-1
    elseif minorc>minor1 then
        minorc,minor_fix=minor1+1
    end   
    local minor_shift=(3-minori)<<3
    local minor_mask=0xff>>minor_shift
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
        draw_minor(0x01.0101&major_mask,major>>>major_shift)
    end
    -- flip side
    for major=major1,majorc+1,-1 do        
        draw_minor(0x02.0202&major_mask,major>>>major_shift)
    end
    if major_fix then
        draw_minor(0,majorc>>>major_shift)
    end
end

function draw_grid(cam)
    local visible_blocks={}
    local m,fov=cam.m,cam.fov

    -- viz blocks
    collect_blocks(cam,visible_blocks)

    local masks={0x0.00ff,0x0.ff,0xff}
    local grid=_grid
    local m1,m5,m9,m13,m2,m6,m10,m14,m3,m7,m11,m15=m[1],m[5],m[9],m[13],m[2],m[6],m[10],m[14],m[3],m[7],m[11],m[15]
    local cache,verts,faces={},{},cube.faces

    -- render in order
    for i=1,#visible_blocks,3 do
        local id,current_mask,idx=visible_blocks[i],visible_blocks[i+1],visible_blocks[i+2]
        -- convert to coord offsets
        local ox,oy,oz=(idx&0x0.00ff)<<16,(idx&0x0.ff)<<8,idx\1
        -- printh("mask: "..tostr(visible_blocks[i],1).." idx: "..tostr(idx,1))
        if id<16 then 
            -- solid block
            local adj={ox,oy,oz}
            for maski,mask in pairs(masks) do
                -- 
                local side=faces[current_mask&mask]
                if side then            
                    --local col=colors[maski][k]
                    -- check adjacent blocks
                    -- todo: create a complement index base on face mask
                    local backup=adj[maski]
                    local adj_i=adj[maski]+side.k
                    adj[maski]=adj_i
                    local adj_idx=adj[1]>>16|adj[2]>>8|adj[3]
                    adj[maski]=backup
                    -- outside: draw faces
                    -- or not next to block
                    if adj_i<0 or adj_i>=8 or (not grid[adj_idx]) then
                        local outcode,clipcode=0xffff,0
                        for i=1,4 do
                            local vert=side[i]
                            local idx=idx+vert.idx
                            local v=cache[idx]
                            if not v then
                                local x,y,z,code=vert[1]+ox,vert[2]+oy,vert[3]+oz,0
                                --x=mid(x,extents[1].lo,extents[1].hi)
                                --y=mid(y,extents[2].lo,extents[2].hi)
                                --z=mid(z,extents[3].lo,extents[3].hi)
                                local ax,ay,az=m1*x+m5*y+m9*z+m13,m2*x+m6*y+m10*z+m14,m3*x+m7*y+m11*z+m15
                                
                                if az>-0.1 then code=2 end
                                if fov*ax>-az then code+=4
                                elseif fov*ax<az then code+=8 end
                                if fov*ay>-az then code+=16
                                elseif fov*ay<az then code+=32 end
                                local w=fov/az
                                v={ax,ay,az,x=64+64*ax*w,y=70-64*ay*w,outcode=code}
                                cache[idx]=v
                            end
                            verts[i]=v
                            outcode&=v.outcode
                            clipcode+=v.outcode&2
                        end
                        --polyline(verts,4,maski+k+1)
                        -- polyfill(verts,4,maski+k+1)
                        if outcode==0 then 
                            local np=4
                            if(clipcode>0) verts,np=cam:z_poly_clip(verts,4)
                            if(np>2) polyfill(verts,np,i+1)
                        end
                    end
                end
            end
        else
            -- sprite 
            --draw_sprite(cam,o,id)
        end    
    end  
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
            local w=focal/z
            return x0+scale*x*w,y0-scale*y*w,w
		end,
        unproject=function(self,x,y)
            return -(x-x0)/(scale*focal),(y-y0)/(scale*focal)
        end,
        z_poly_clip=function(self,v,nv)
            local res,v0={},v[nv]
            local d0=v0[3]-0.1
            for i=1,nv do
                local side=d0>0
                if side then
                    res[#res+1]=v0
                end
                local v1=v[i]
                local d1=v1[3]-0.1
                -- not same sign?
                if (d1>0)!=side then
                    local nv=v_lerp(v0,v1,d0/(d0-d1))
                    -- project against near plane
                    nv.x=x0+scale*nv[1]*focal/0.1
                    nv.y=y0-scale*nv[2]*focal/0.1
                    res[#res+1]=nv
                end
                v0=v1
                d0=d1
            end
            return res,#res
        end        
	}
end

-- custom ui elements
function make_voxel_editor()   
	local yangle,zangle=-0.25,0---0.125,0
	local dyangle,dzangle=0,0

    local layer=3
    local cam=make_cam(64,64+6,64,0.25)
    local quad={
        {0,0,0},
        {1,0,0},
        {1,1,0},
        {0,1,0}
    }
    local undo_stack={}
    local function apply(idx,col)
        if col==0 then
            _grid[idx]=nil
            _sprite_grid[idx]=nil
        elseif col<16 then                    
            _grid[idx]=col
        else
            _sprite_grid[idx]=col
        end
    end
    return is_window({
        draw=function(self)
            -- todo: layer offset by +0 +1 if camera is under
            local r=self.rect
            clip(r.x,r.y,r.w,r.h)
            draw_grid(cam)

            -- draw layer selection            
            local pts={}
            for i,p in pairs(quad) do
                p=v_scale(p,_grid_size)
                p[3] = layer+1
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
            
            -- draw cursor if any
            if current_voxel then
                local pts={}
                for i,p in pairs(quad) do
                    p=v_add(p,current_voxel.origin)
                    p[3]=layer+1
                    pts[i]=p
                end
                --fillp(0xa5a5.8)
                local p0=pts[4]
                local x0,y0,w0=cam:project(p0)    
                for i=1,4 do
                    local p1=pts[i]
                    local x1,y1,w1=cam:project(p1)
                    if(w1 and x1>xmax) xmax,ymax=x1,y1
                    if(w1 and w0) line(x0,y0,x1,y1,7)
                    x0,y0,w0=x1,y1,w1
                end    
                fillp()
            end            
            clip()       
        end,
        mousemove=function(self,msg)
            local rotation_mode
            if msg.mmb then
                poke(0x5f2d, 0x1+0x4)
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
            end

            yangle+=dyangle/512
            zangle+=dzangle/512            
            -- friction
            dyangle=dyangle*0.7
            dzangle=dzangle*0.7

            layer=mid(layer+msg.wheel,0,_grid_size-1)

            local xyz=_grid_size/2
            --cam:control({xyz,xyz,layer},yangle,zangle,_grid_size*1.2)
            cam:control({xyz,xyz,layer},yangle,zangle,_grid_size)

            -- selection
            if not rotation_mode then
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
                for i=0,_grid_size-1 do
                    for j=0,_grid_size-1 do
                        grid[i>>16|j>>8|layer]=true
                    end
                end
            
                current_voxel=voxel_traversal(ray,_grid_size,grid)
        
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
                        -- previous state for undo
                        add(undo_stack,{idx=idx,col=_grid[idx] or _sprite_grid[idx] or 0})
                        apply(idx,col)
                    elseif msg.rmbp then

                        _editor_state.selected_color=_grid[idx] or _sprite_grid[idx] or 0
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
        save=function(self,msg)
            -- get size        
            local mem,size=0x4,0
            local function poke_coords(idx,col)
                poke4(mem,idx|col<<8)
                mem+=4
            end
            for idx,col in pairs(_grid) do
                size+=1
                poke_coords(idx,col)
            end
            for idx,col in pairs(_sprite_grid) do
                size+=1
                poke_coords(idx,col)
            end
            poke4(0x0,size)
            cstore(0,0,(size+1)*4,msg.filename)
            reload()              
        end,
        load=function(self,msg)            
            _grid={}
            _sprite_grid={}
            undo_stack={}
            reload(0,0,0x4300,msg.filename)
            local mem,size=0x4,peek4(0x0)
            for i=1,size do
                local v=peek4(mem)
                local idx=v&0x00ff.ffff
                local col=(v&0xff00)>>>8
                if col>15 then
                    _sprite_grid[idx]=col
                else
                    _grid[idx]=col
                end
                mem+=4
            end
            reload()
        end
    })
end

function _init()
    -- create ui and callbacks
    _main=main_window()
    local banner=_main:add(make_static(8),0,0,127,7)
    local pickers=banner:add(make_list(64,8,8,bounded_binding(_editor_state,"selected_color",0,18)),64,0,80,7)
    for i=0,15 do
        pickers:add(make_color_picker(i,binding(_editor_state,"selected_color")))
    end   
    -- sprite blocks
    for i=0,3 do
        pickers:add(make_sprite_picker(16+i,32+i,binding(_editor_state,"selected_color")))
        _sprite_by_id[16+i]=32+i
    end
    -- +-
    _main:add(make_button(21,binding(function() 
        _editor_state.selected_color=max(0,_editor_state.selected_color-8)        
    end)),60,0,3,4)
    _main:add(make_button(22,binding(function() 
        _editor_state.selected_color=min(#pickers-1,_editor_state.selected_color+8)      
    end)),60,4,3,4)

    -- load
    _main:add(make_button(17,binding(function() 
        _main:send({
            name="load",
            filename="level_".._editor_state.level..".p8"
        })
    end)),1,0,7)
    -- save
    _main:add(make_button(16,binding(function()
        _main:send({
            name="save",
            filename="level_".._editor_state.level..".p8"
        })
    end)),9,0)
    -- level id
    _main:add(make_static(2,binding(_editor_state,"level")),17,0,6,7)
    -- +-
    _main:add(make_button(21,binding(function()
        _editor_state.level=mid(_editor_state.level+1,1,9)
    end)),25,0,3,4)
    _main:add(make_button(22,binding(function()
        _editor_state.level=mid(_editor_state.level-1,1,9)        
    end)),25,4,3,4)

    -- play
    _main:add(make_button(4,binding(function()
        game_state()
    end)),29,0,6)

    -- edit/select/fill
    for i,s in ipairs({19,18,20}) do
        _main:add(make_radio_button(s,i,binding(_editor_state,"edit_mode")),27+i*8,0,6)
    end

    -- main editor
    _main:add(make_voxel_editor(),0,8,127,119)
    
    -- demo voxels
    srand(42)
    for i=0,4*_grid_size-1 do
        for j=0,4*_grid_size-1 do
            for k=0,7 do
                if(rnd()>0.125) _grid[i>>16|j>>8|k]=11
            end
        end
    end
    --_grid[4>>16|4>>8|0]=11

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