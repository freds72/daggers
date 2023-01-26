local voxel_size=8

function init_traversal(ray,mins,maxs,t0,t1)
    local function get_bounds(d)
        local o,dir=ray.origin[d],ray.dir[d]
        local tmin = (mins[d] - o) / dir
        local tmax = (maxs[d] - o) / dir 
        if dir < 0 then
            tmin,tmax=tmax,tmin
        end        
        return tmin,tmax
    end
    
    local tmin,tmax = get_bounds(1)
    -- out?
    if(tmin>t1 or tmax<t0) printh("x out") return
    pset(ray.origin[1]+ray.dir[1]*tmin,ray.origin[2],2)
    pset(ray.origin[1]+ray.dir[1]*tmax,ray.origin[2],8)

    local tymin,tymax = get_bounds(2)
    -- out?
    if(tymin>t1 or tymax<t0) printh("y out") return
    pset(ray.origin[1],ray.origin[2]+ray.dir[2]*tymin,2)
    pset(ray.origin[1],ray.origin[2]+ray.dir[2]*tymax,8)

    if (tymin > tmin) tmin = tymin
    if (tymax < tmax) tmax = tymax


    local tzmin,tzmax = get_bounds(3)
    if(tzmin>t1 or tzmax<t0) printh("z out") return

    if (tzmin > tmin) tmin = tzmin
    if (tzmax < tmax) tmax = tzmax
    return true,max(tmin,t0),min(tmax,t1)
end

function voxel_traversal(ray,mins,maxs)
    local in_grid,tmin,tmax = init_traversal(ray, mins,maxs, 0, ray.len)
    if (not in_grid) return

    local ray_start = v_add(ray.origin,ray.dir,tmin)
    local ray_end = v_add(ray.origin,ray.dir,tmax)

    pset(ray_start[1],ray_start[2],8)
    pset(ray_end[1],ray_end[2],12)

    local function get_step(d)
        local curr_i = max(0,(ray_start[d] - mins[d]) \ voxel_size)
        local end_i = max(0,(ray_end[d] - mins[d]) \ voxel_size)
        local step = 0
        local tdelta = tmax
        local tmax_d = tmax
        if ray.dir[d] > 0.0 then
            step = 1
            tdelta = voxel_size / ray.dir[d]
            tmax_d = tmin + (mins[d] + (curr_i+1)* voxel_size - ray_start[d]) / ray.dir[d]
        elseif ray.dir[d] < 0.0 then
            step = -1
            tdelta = voxel_size / -ray.dir[d]
            tmax_d = tmin + (mins[d] + curr_i * voxel_size - ray_start[d]) / ray.dir[d]
        end
        return curr_i,end_i,step,tdelta,tmax_d
    end
    
    local i0,i1,stepx,tdeltax,tmaxx = get_step(1)
    local j0,j1,stepy,tdeltay,tmaxy = get_step(2)
    local k0,k1,stepz,tdeltaz,tmaxz = get_step(3)

    local x0,y0=mins[1]+i0*voxel_size,mins[2]+j0*voxel_size
    rect(x0,y0,x0+voxel_size-1,y0+voxel_size-1,1)        

    local x0,y0=mins[1]+i1*voxel_size,mins[2]+j1*voxel_size
    rect(x0,y0,x0+voxel_size-1,y0+voxel_size-1,12)        

    local n=0
    printh("("..i0.." "..j0..") -> ("..i1.." "..j1..")")
    while i0!=i1 or j0!=j1 or k0!=k1 do
        local hit
        if tmaxx < tmaxy and tmaxx < tmaxz then            
            -- x-axis traversal.
            i0 += stepx
            tmaxx += tdeltax

            printh("i:"..i0..", "..j0.." ["..n.."]")
            local x0,y0=mins[1]+i0*voxel_size,mins[2]+j0*voxel_size                  
            -- line(x0,y0,x0,y0+7,stepx==1 and 8 or 2)
            rectfill(x0,y0,x0+voxel_size-1,y0+voxel_size-1,6)    
            print(n,x0+2,y0+2,0)  

            local i=i0+(stepx==1 and 0 or 1)
            local x0,y0=mins[1]+i*voxel_size,mins[2]+j0*voxel_size    
            line(x0,y0,x0,y0+7,rnd(15))
            pset(x0-stepx,y0+4)
            n+=1
        elseif tmaxy < tmaxz then
            -- y-axis traversal.
            j0 += stepy
            tmaxy += tdeltay
            printh("j:"..i0..", "..j0.." ["..n.."]")

            local x0,y0=mins[1]+i0*voxel_size,mins[2]+j0*voxel_size                  
            rectfill(x0,y0,x0+voxel_size-1,y0+voxel_size-1,7)        
            print(n,x0+2,y0+2,0)    

            local j=j0+(stepy==1 and 0 or 1)
            local x0,y0=mins[1]+i0*voxel_size,mins[2]+j*voxel_size  
            line(x0,y0,x0+7,y0,rnd(15))
            pset(x0+4,y0-stepy)
            n+=1
        else
            -- z-axis traversal.
            k0 += stepz
            tmaxz += tdeltaz
        end
        --local x0,y0=mins[1]+i0*voxel_size,mins[2]+j0*voxel_size
        --rectfill(x0,y0,x0+voxel_size-1,y0+voxel_size-1,6)        
        --printh(i0.." "..j0.." "..k0)
        --flip()
    end
end

local v={
    {0,0,17},
    {5,0,17}}
local mode=0
   
function _init()
    poke(0x5f2d,1)
end

function _update()
    if btnp(4) then
        mode=(mode+1)%2
    end 

    local x,y=stat(32),stat(33)
    local p=v[mode+1]
    p[1]=x
    p[2]=y
end

function _draw()
    cls()

    -- 
    for i=16,112,8 do
        for j=16,112,8 do
        pset(i,j,1)
        end
    end

    local s=v[mode+1]
    local e=v[(mode+1)%2+1]
    local d=make_v(s,e)
    local n,l=v_normz(d)
    voxel_traversal({
        origin=s,
        dir=n,
        len=l},
        {16,16,16},{112,112,112})

    local x0,y0=unpack(v[1])
    local x1,y1=unpack(v[2])

    line(x0,y0,x1,y1,5)
    local x0,y0=unpack(v[mode+1])
    pset(x0,y0,8)

end