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
	local i01=mid(cam,i0,i1)
	local i10=i01+1
	-- outside range?
	if i01!=cam then
		if cam<i0 then
 	 i1=i1
  	i10=i0  
  else
	  i01=i0
		 i01=i1+1
		 i10=i1+1
		end	 
	 cam=nil
	end

	for i=i0,i01-1,di do
 	print(">> "..i)
	end
	if(cam) color(8)print("** "..cam)color(7)
	for i=i1,i10,-di do
 	print("<< "..i)
	end
end




