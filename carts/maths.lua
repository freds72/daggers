
-- maths & cam
function lerp(a,b,t)
	return a*(1-t)+b*t
end

-- return shortest angle to target
function shortest_angle(target,angle)
	local d=target-angle
	if d>0.5 then
		angle+=1
	elseif d<-0.5 then
		angle-=1
	end
	return angle
end

-- 2d vector
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
function v_lerp(a,b,t)
	local ax,ay,az=a[1],a[2],a[3]
	return {
    	ax+(b[1]-ax)*t,
    	ay+(b[2]-ay)*t,
    	az+(b[3]-az)*t
	}
end

-- safe for overflow len
-- faster than sqrt variant (23.5+14 vs. 27.5)
-- credits: https://www.lexaloffle.com/bbs/?tid=49827
function v_len(a,b)
  local x,y,z=b[1]-a[1],b[2]-a[2],b[3]-a[3]
  local ax=atan2(x,y)
  local d2=x*cos(ax)+y*sin(ax)
  local az=atan2(d2,z)
  return d2*cos(az)+z*sin(az)
end 

-- normalized direction 
-- same as v_len without building a vector
-- function v_dir(a,b)
-- 	local x,y,z,d=b[1]-a[1],b[2]-a[2],b[3]-a[3],v_len(a,b)
-- 	return {x/d,y/d,z/d},d
-- end

function v_dir(a,b)
	local x,y,z=b[1]-a[1],b[2]-a[2],b[3]-a[3]
	local d=abs(x)+abs(y)+abs(z)
	return {x/d,y/d,z/d},d
end

function v_normz(v)
	local d=v_len({0,0,0},v)
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
