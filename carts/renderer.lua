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
            [-1]={2,3,7,6}
        },
        -- y
        {
            [1]={1,2,6,5},
            [-1]={3,4,8,7}
        },
        -- z
        {
            [1]={1,2,3,4},
            [-1]={5,6,7,8}
        }
    }
}

function draw_cube(cam,o,c,cache,mask)
    local ox,oy,oz=o[1],o[2],o[3]
    local idx=ox>>16|oy>>8|oz
    if(not _grid[idx]) return
    local verts={}
    local m,scale=cam.m,64*cam.fov
    -- get visible faces (face index + face direction)
    for maski,k in pairs(mask) do
        -- 
        local sides=cube.faces[maski][k]
        -- check adjacent blocks
        local adj={ox,oy,oz}
        adj[maski]-=k
        local adj_i=adj[maski]
        local adj_idx=adj[1]>>16|adj[2]>>8|adj[3]
        -- outside: draw faces
        -- or not next to block
        if adj_i<0 or adj_i>=8 or (not _grid[adj_idx]) then
            for i,vi in pairs(sides) do
                local vert=cube[vi]
                local idx=idx+vert.idx
                local v=cache[idx]
                if not v then
                    local x,y,z=vert[1]+ox,vert[2]+oy,vert[3]+oz
                    x,y,z=m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]
                    local w=scale/z
                    v={x=64+x*w,y=64-y*w}
                    cache[idx]=v
                end
                verts[i]=v
            end
            --polyline(verts,4,maski+k+1)
            polyfill(verts,4,maski+k+1)
        end
    end
    if(btn(5)) flip()
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
                    local x,y,w=_cam:project({i0+i,j0+j,k0+k})
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

function make_cam(x0,y0,scale,fov)
	local yangle,zangle=-0.25,0
	local dyangle,dzangle=0,0
    local focal=cos(fov/2)
	return {
        fov=focal,
		pos={0,0,0},
		control=function(self,lookat,dist)
			if(btn(0)) dzangle-=1
			if(btn(1)) dzangle+=1
			if(btn(2)) dyangle+=1
			if(btn(3)) dyangle-=1
			yangle+=dyangle/228--+0.01
			zangle+=dzangle/228--+0.005
			-- friction
			dyangle=dyangle*0.8
			dzangle=dzangle*0.8
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
		end
	}
end

function _init()
    -- mouse
    poke(0x5f2d,1)

    _cam=make_cam(64,64,64,0.25)
    -- voxel grid    
    _grid={}
    srand(42)
    for i=0,7 do
        for j=0,7 do
            for k=0,7 do
                if(rnd()>0.125) _grid[i>>16|j>>8|k]=true
            end
        end
    end
    -- init keys for cube points
    for i=1,#cube do
        local p=cube[i]
        p.idx=p[1]>>16|p[2]>>8|p[3]
    end
end

local _layer=0
local _raytrace
local _lmb
local _color=0
function _update()
    _cam:control({4,4,4},8)

    local ti,tj=-(stat(32)-64)/(64*_cam.fov),(stat(33)-64)/(64*_cam.fov)
    local fwd,right,up=_cam.fwd,_cam.right,_cam.up
    local target=v_add(_cam.pos,fwd,-1)
    target=v_add(target,right,ti)
    target=v_add(target,up,tj)
    --local origin=v_clone(_cam.pos)
    
    local d=make_v(_cam.pos,target)
    local n,l=v_normz(d)
    local ray={
        origin=_cam.pos,
        target=target,
        dir=n,
        len=16}    

    local wheel=stat(36)
    _layer=mid(_layer+wheel\1,0,7)

    local grid={}
    for i=0,7 do
        for j=0,7 do
            grid[i>>16|j>>8|_layer]=true
        end
    end

    _current_voxel=voxel_traversal(ray,8,grid)
        
    local lmb=stat(34)&1==1
    if _current_voxel then
        local o=_current_voxel.origin
        local idx=o[1]>>16|o[2]>>8|o[3]
        if lmb or (not lmb and _lmb) then
            -- click!
            _grid[idx]=true
        end
    end
    _lmb=lmb

    if btnp(5) then
        --_raytrace=not _raytrace
    end
end

function draw_grid(cam)    
    local fwd=cam.fwd
    local majord,majori=-32000,1
    for i=1,3 do
        local d=abs(_cam.fwd[i])
        if d>majord then
            majori,majord=i,d
        end
    end

    local minord,minori=-32000,1
    for i=1,3 do
        if i!=majori then
            local d=abs(_cam.fwd[i])
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
                draw_cube(cam,o,5,cache,face_mask)
            end    
            if fix then        
                if last0>=0 and last0<8 and last1>=0 and last1<8 then                
                    face_mask[lasti]=face_sign   
                    for last=last0,last1,dlast do
                        o[lasti]=last        
                        draw_cube(cam,o,5,cache,face_mask)
                    end   
                end         
                o[lasti]=fix       
                face_mask[lasti]=nil
                draw_cube(cam,o,5,cache,face_mask)
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
end

function _draw()
    cls()
    
    local axes={"x","y","z"}    
    local x0,y0,w0=_cam:project({0,0,0})    
    for i,axis in pairs(axes) do
        local pos={0,0,0}
        pos[i]=9
        local x,y,w=_cam:project(pos)
        if(w) print(axis,x,y,7) 
        if(w and w0) line(x0,y0,x,y,6)
    end

    --[[
    local cache={}
    local k=_layer
    for i=0,8 do
        for j=0,8 do
            local idx=i>>16|j>>8|k
            if _grid[idx] then
                draw_cube(_cam,{i,j,k},4,cache)
            end
        end
    end
    ]]
    draw_grid(_cam)

    -- draw selection
    if _current_voxel then
        fillp(0xa5a5.8)
        --draw_cube(_cam,_current_voxel.origin,7)
        fillp()
    end

    -- banner
    rectfill(0,0,127,6,8)    
    local txt="-"
    if _current_voxel then
        local o=_current_voxel.origin
        txt=o[1].." "..o[2].." "..o[3]        
    end
    print("\18:"..txt,1,1,7)
    -- colors
    for i=0,15 do
        local x=i*4+63
        rectfill(x,2,x+2,4,i)
        if i==_color then
            rect(x-1,1,x+3,5,7)
        end
    end

    -- 
    if _raytrace then
        local fwd,right,up=_cam.fwd,_cam.right,_cam.up
        local target=v_add(_cam.pos,fwd,-1)
        local fov=64*_cam.fov
        for i=0,127 do
            local ti=-(i-64)/fov
            for j=0,127 do
                local tj=(j-64)/fov
                local target={
                    target[1]+right[1]*ti+up[1]*tj,
                    target[2]+right[2]*ti+up[2]*tj,
                    target[3]+right[3]*ti+up[3]*tj}
                local d=make_v(_cam.pos,target)
                local n,l=v_normz(d)
                local ray={
                    origin=_cam.pos,
                    dir=n,
                    len=16}    
                local hit=voxel_traversal(ray,8,_grid)
                if hit then
                    pset(i,j,2+hit.side)
                end
            end
        end
    end

    local mx,my=stat(32),stat(33)
    spr(0,mx,my)
end