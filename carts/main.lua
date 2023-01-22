-- maths & cam
function lerp(a,b,t)
	return a*(1-t)+b*t
end

function make_v(a,b)
	return {
		b[1]-a[1],
		b[2]-a[2],
		b[3]-a[3]}
end
function v_clone(v)
	return {v[1],v[2],v[3]}
end
function v_dot(a,b)
	return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end
-- returns scaled down dot, safe for overflow
function v_dotsign(a,b)
  local x0,y0,z0=a[1],a[2],a[3]
  local x1,y1,z1=b[1],b[2],b[3]
	return x0*x1+y0*y1+z0*z1
end

function v_scale(v,scale)
    return {
        v[1]*scale,
        v[2]*scale,
        v[3]*scale
    }
end
function v_add(v,dv,scale)
	scale=scale or 1
	return {
		v[1]+scale*dv[1],
		v[2]+scale*dv[2],
		v[3]+scale*dv[3]}
end
function v_lerp(a,b,t,uv)
  local ax,ay,az,u,v=a[1],a[2],a[3],a.u,a.v
	return {
    ax+(b[1]-ax)*t,
    ay+(b[2]-ay)*t,
    az+(b[3]-az)*t,
    u=uv and u+(b.u-u)*t,
    v=uv and v+(b.v-v)*t
  }
end

function v_cross(a,b)
	local ax,ay,az=a[1],a[2],a[3]
	local bx,by,bz=b[1],b[2],b[3]
	return {ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx}
end

-- safe for overflow len
-- faster than sqrt variant (23.5+14 vs. 27.5)
-- credits: https://www.lexaloffle.com/bbs/?tid=49827
function v_len(v)
  local x,y,z=v[1],v[2],v[3]
  local ax=atan2(x,y)
  local d2=x*cos(ax)+y*sin(ax)
  local az=atan2(d2,z)
  return d2*cos(az)+z*sin(az)
end 

function v_normz(v)
  local d=v_len(v)
	return {v[1]/d,v[2]/d,v[3]/d},d
end

-- matrix functions
-- matrix vector multiply
function m_x_v(m,v)
	local x,y,z=v[1],v[2],v[3]
	return {m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]}
end

function make_m_from_euler(x,y,z)
		local a,b = cos(x),-sin(x)
		local c,d = cos(y),-sin(y)
		local e,f = cos(z),-sin(z)
  
    -- yxz order
  local ce,cf,de,df=c*e,c*f,d*e,d*f
	 return {
	  ce+df*b,a*f,cf*b-de,0,
	  de*b-cf,a*e,df+ce*b,0,
	  a*d,-b,a*c,0,
	  0,0,0,1}
end

function make_m_look_at(up,fwd)
	local right=v_normz(v_cross(up,fwd))
	fwd=v_cross(right,up)
	return {
		right[1],right[2],right[3],0,
		up[1],up[2],up[3],0,
		fwd[1],fwd[2],fwd[3],0,
		0,0,0,1
	}
end

-- returns basis vectors from matrix
function m_right(m)
	return {m[1],m[2],m[3]}
end
function m_up(m)
	return {m[5],m[6],m[7]}
end
function m_fwd(m)
	return {m[9],m[10],m[11]}
end
function m_set_pos(m,v)
	m[13]=v[1]
	m[14]=v[2]
	m[15]=v[3]
end

-- optimized 4x4 matrix mulitply
function m_x_m(a,b)
	local a11,a12,a13,a21,a22,a23,a31,a32,a33=a[1],a[5],a[9],a[2],a[6],a[10],a[3],a[7],a[11]
	local b11,b12,b13,b14,b21,b22,b23,b24,b31,b32,b33,b34=b[1],b[5],b[9],b[13],b[2],b[6],b[10],b[14],b[3],b[7],b[11],b[15]

	return {
			a11*b11+a12*b21+a13*b31,a21*b11+a22*b21+a23*b31,a31*b11+a32*b21+a33*b31,0,
			a11*b12+a12*b22+a13*b32,a21*b12+a22*b22+a23*b32,a31*b12+a32*b22+a33*b32,0,
			a11*b13+a12*b23+a13*b33,a21*b13+a22*b23+a23*b33,a31*b13+a32*b23+a33*b33,0,
			a11*b14+a12*b24+a13*b34+a[13],a21*b14+a22*b24+a23*b34+a[14],a31*b14+a32*b24+a33*b34+a[15],1
		}
end

function polytex(p,np,texture)
	local miny,maxy,mini=32000,-32000
	-- find extent
	for i=1,np do
		local pi=p[i]
		local y=pi.y
		if y<miny then
			mini,miny=i,y
		end
		if y>maxy then
			maxy=y
		end
	end

	--data for left & right edges:
	local lj,rj,ly,ry,lx,lu,lv,lw,ldx,ldu,ldv,ldw,rx,ru,rv,rw,rdx,rdu,rdv,rdw=mini,mini,miny,miny
	if maxy>=128 then
		maxy=128-1
	end
	if miny<0 then
		miny=-1
	end
	for y=flr(miny)+1,maxy do
		--maybe update to next vert
		while ly<y do
			local v0=p[lj]
			lj=lj+1
			if lj>np then lj=1 end
			local v1=p[lj]
			local p0,p1=v0,v1
			local y0,y1=p0.y,p1.y
			local dy=y1-y0
			ly=flr(y1)
			lx=p0.x
			lw=p0.w
			lu=p0.u*lw
			lv=p0.v*lw
			ldx=(p1.x-lx)/dy
			local w1=p1.w
			ldu=(p1.u * w1 - lu)/dy
			ldv=(p1.v * w1 - lv)/dy
			ldw=(w1-lw)/dy
			--sub-pixel correction
			local cy=y-y0
			lx=lx+cy*ldx
			lu=lu+cy*ldu
			lv=lv+cy*ldv
			lw=lw+cy*ldw
		end   
		while ry<y do
			local v0=p[rj]
			rj=rj-1
			if rj<1 then rj=np end
			local v1=p[rj]
			local p0,p1=v0,v1
			local y0,y1=p0.y,p1.y
			local dy=y1-y0
			ry=flr(y1)
			rx=p0.x
			rw=p0.w
			ru=p0.u*rw 
			rv=p0.v*rw 
			rdx=(p1.x-rx)/dy
			local w1=p1.w
			rdu=(p1.u*w1 - ru)/dy
			rdv=(p1.v*w1 - rv)/dy
			rdw=(w1-rw)/dy
			--sub-pixel correction
			local cy=y-y0
			rx=rx+cy*rdx
			ru=ru+cy*rdu
			rv=rv+cy*rdv
			rw=rw+cy*rdw
		end
	
        do
            local dx=lx-rx
            local du,dv,dw=(lu-ru)/dx,(lv-rv)/dx,(lw-rw)/dx
            -- todo: faster to clip polygon?
            local x0,x1,u,v,w=rx,lx,ru,rv,rw
            if x0<0 then
                u=u-x0*du v=v-x0*dv w=w-x0*dw x0=0
            end
            if x1>128 then
                x1=128
            end    
            -- sub-pix shift
            local sa=1-rx%1
            local ru,rv,rw=ru+sa*du,rv+sa*dv,rw+sa*dw
                
            for i=flr(rx),flr(lx)-1 do
                local u,v=ru/rw,rv/rw
                local c=sget(u,v)
                if(c!=0)pset(i,y,c)
                ru+=du 
                rv+=dv 
                rw+=dw	
            end
        end

		lx=lx+ldx
		lu=lu+ldu
		lv=lv+ldv
		lw=lw+ldw
		rx=rx+rdx
		ru=ru+rdu
		rv=rv+rdv
		rw=rw+rdw
  end
end

-- camera
function make_cam(fov)
    local up={0,1,0}  
    fov = cos(fov/2)
    return {
        origin={0,0,0},    
        track=function(self,dist)

            local m=make_m_from_euler(0,time()/4,0)
			local pos=v_scale(m_fwd(m),dist)

            -- inverse view matrix
            m[2],m[5]=m[5],m[2]
            m[3],m[9]=m[9],m[3]
            m[7],m[10]=m[10],m[7]
            --
			self.m=m_x_m(m,{
				1,0,0,0,
				0,1,0,0,
				0,0,1,0,
				-pos[1],-pos[2],-pos[3],1
			})
            self.origin=pos
        end,
        project=function(self,v)
            local m,code,x,y,z=self.m,0,v[1],v[2],v[3]
            local ax,ay,az=m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]
    
            local w=fov/az
            local a={ax,ay,az,x=64+64*ax*w,y=64-64*ay*w,u=v.u,v=v.v,w=w}
            return a
        end
    }
end

function _init()
    _cam = make_cam(0.05)
end

function _update()
    _cam:track(5)
end

function _draw()
    cls()

    for i=8,0,-1 do
        local u0=8*(i\2)
        local poly={
            {-1,-1,i*0.125,u=8+u0,v=0},
            {1,-1,i*0.125,u=16+u0,v=0},
            {1,1,i*0.125,u=16+u0,v=8},
            {-1,1,i*0.125,u=8+u0,v=8}
        }
        local p={}
        for k,v in pairs(poly) do
            p[k]=_cam:project(v)
        end

        polytex(p,4)
    end

end