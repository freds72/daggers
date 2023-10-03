
-- trimmed for game purpose
-- maths & cam
local function lerp(a,b,t)
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
function v_zero() return {0,0,0} end

-- clone vector
-- optional: y override
local function v_clone(v,y)
	return {v[1],y or v[2],v[3]}
end

local function v_scale(v,scale)
	return {
		v[1]*scale,
		v[2]*scale,
		v[3]*scale
	}
end
local function v_add(v,dv,scale)
	scale=scale or 1
	return {
		v[1]+scale*dv[1],
		v[2]+scale*dv[2],
		v[3]+scale*dv[3]}
end
local function v_lerp(a,b,t)
	local ax,ay,az=a[1],a[2],a[3]
	return {
    	ax+(b[1]-ax)*t,
    	ay+(b[2]-ay)*t,
    	az+(b[3]-az)*t
	}
end

-- generates a random vector
local function v_rnd(x,y,z,r,a)
  a=a or rnd()
  return {x+r*cos(a),y,z-r*sin(a)}
end

-- safe for overflow len
-- faster than sqrt variant (23.5+14 vs. 27.5)
-- credits: https://www.lexaloffle.com/bbs/?tid=49827
local function v_len(a,b)
  local x,y,z=b[1]-a[1],b[2]-a[2],b[3]-a[3]
  local ax=atan2(x,y)
  local d2=x*cos(ax)+y*sin(ax)
  local az=atan2(d2,z)
  return d2*cos(az)+z*sin(az)
end 

-- normalized direction 
local function v_normz(a)
	local d=v_len({0,0,0},a)
	return {a[1]/d,a[2]/d,a[3]/d},d
end

-- fast direction/norm (abs)
-- same as v_len without building a vector
local function v_dir(a,b)
  local x,y,z=b[1]-a[1],b[2]-a[2],b[3]-a[3]
	local d=abs(x)+abs(y)+abs(z)
	if(d==0) return {0,0,0},d
	return {x/d,y/d,z/d},d
end 

-- matrix functions
local function make_m_from_euler(x,y,z)
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
function m_fwd(m)
	return {m[9],m[10],m[11]}
end
