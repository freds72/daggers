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
        dist+=1
        if(dist>24) return
    end
end

function make_cam(x0,y0,scale,fov)
	local yangle,zangle=-0.25,0
	local dyangle,dzangle=0,0
    local focal=cos(fov/2)
	return {
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
            if(z>0) return
            local w=focal/z
            return x0+scale*x*w,y0-scale*y*w,w
		end
	}
end

function _init()
    poke(0x5f2d,1)

    _cam=make_cam(64,64,64,0.25)
    -- voxel grid    
    _grid={}
    for i=2,4 do
        for j=2,4 do
            for k=2,4 do
                _grid[i>>16|j>>8|k]=true
            end
        end
    end
    _grid[2>>16|3>>8|5]=true
    _grid[4>>16|3>>8|5]=true
    for y=2,4 do
        _grid[3>>16|y>>8|3]=nil
    end
end

function _update()
    _cam:control({4,4,4},8)

    if btnp(4) then    
        local origin=v_clone(_cam.pos)
        local target=v_add(origin,_cam.fwd,-16)
        
        local d=make_v(origin,target)
        local n,l=v_normz(d)
        _ray={
            origin=origin,
            target=target,
            dir=n,
            len=l}    
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

    for i=0,7 do
        for j=0,7 do
            for k=0,7 do
                local x,y,w=_cam:project({i,j,k})
                if(w) pset(x,y,1)
            end
        end
    end

    if _ray then
        local hit=voxel_traversal(_ray,7,_grid)
        if hit then
            for i=0,1 do
                for j=0,1 do
                    for k=0,1 do                        
                        local x,y,w=_cam:project(v_add(hit.origin,{i,j,k}))
                        if(w) pset(x,y,8)
                    end
                end
            end
        end
        local x0,y0,w0=_cam:project(_ray.origin)
        local x1,y1,w1=_cam:project(_ray.target)
        if(w0 and w1) line(x0,y0,x1,y1,2)
    end

    -- 
    if true then
        local fwd,right,up=_cam.fwd,_cam.right,_cam.up
        local target=v_add(_cam.pos,fwd,sin(0.25/2))
        for i=0,127 do
            local ti=-(i-64)/64
            local target=v_add(target,right,ti)
            for j=0,127 do
                local tj=(j-64)/64
                local target=v_add(target,up,tj)
                local d=make_v(_cam.pos,target)
                local n,l=v_normz(d)
                local ray={
                    origin=_cam.pos,
                    dir=n,
                    len=16}    
                local hit=voxel_traversal(ray,8,_grid)
                if hit then
                    pset(i,j,2+hit.side)
                else
                    --pset(i,j,1)
                end
            end
        end
    end
end