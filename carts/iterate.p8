pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
local cam=8
function _update()
 local dy=0
 if(btnp(2)) dy=-1
 if(btnp(3)) dy=1
 cam+=dy 
end

function _draw()
 cls()
	local i0,i1=0,7
	local cam=cam
	local di=1
	local ic=cam
	if cam<i0 then
		ic=i0-1
		cam=nil
	elseif cam>i1 then
	 ic=i1+1
	 cam=nil
 end
	--local i01=mid(cam,i0,i1)
		
	for i=i0,ic-1,di do
 	print(">> "..i)
	end
	if(cam) color(8)print("** "..cam)color(7)
	for i=i1,ic+1,-di do
 	print("<< "..i)
	end
end




