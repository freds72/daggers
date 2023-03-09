-- plain color polygon rasterization
function polyfill(p,np,c)
	color(c)
	local miny,maxy,mini=32000,-32000
	-- find extent
	for i=1,np do
		local y=p[i].y
		if (y<miny) mini,miny=i,y
		if (y>maxy) maxy=y
	end

	--data for left & right edges:
	local lj,rj,ly,ry,lx,ldx,rx,rdx=mini,mini,miny-1,miny-1
	--step through scanlines.
	if(maxy>127) maxy=127
	if(miny<0) miny=-1
	for y=1+miny&-1,maxy do
		--maybe update to next vert
		while ly<y do
			local v0=p[lj]
			lj+=1
			if (lj>np) lj=1
			local v1=p[lj]
			local y0,y1=v0.y,v1.y
			ly=y1&-1
			lx=v0.x
			ldx=(v1.x-lx)/(y1-y0)
			--sub-pixel correction
			lx+=(y-y0)*ldx
		end   
		while ry<y do
			local v0=p[rj]
			rj-=1
			if (rj<1) rj=np
			local v1=p[rj]
			local y0,y1=v0.y,v1.y
			ry=y1&-1
			rx=v0.x
			rdx=(v1.x-rx)/(y1-y0)
			--sub-pixel correction
			rx+=(y-y0)*rdx
		end
		-- no overdraw but a bit more costly
		local x0,x1=rx\1,lx\1-1
		if x1>=x0 then
			rectfill(x0,y,x1,y)
		end
		lx+=ldx
		rx+=rdx
	end
end

function polyline(p,np,c)
	local v0=p[np]
	color(c)
	for i=1,np do
		local v1=p[i]
		local dx,dy=abs(v0.x-v1.x),abs(v0.y-v1.y)
		--fillp(dx>dy and ▥ or ▤)
		line(v0.x,v0.y,v1.x,v1.y)
		v0=v1
	end
end

function polyset(p,np,c)
	color(c)
	for i=1,np do
		local v1=p[i]
		pset(v1.x,v1.y)
	end
end

