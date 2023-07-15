function mode7(p,np,light)
  local miny,maxy,mini=32000,-32000
  -- find extent
  for i=1,np do
    local y=p[i].y
    if (y<miny) mini,miny=i,y
    if (y>maxy) maxy=y
  end

  --data for left & right edges:
  local lj,rj,ly,ry,lx,ldx,rx,rdx,lu,ldu,lv,ldv,ru,rdu,rv,rdv,lw,ldw,rw,rdw=mini,mini,miny-1,miny-1
  local maxlight,pal0=light\0.066666
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
      -- make sure w gets enough precision
      local y0,y1,w1=v0.y,v1.y,v1.w
      local dy=y1-y0
      ly=y1&-1
      lx=v0.x
      lw=v0.w
      lu=v0.u*lw
      lv=v0.v*lw
      ldx=(v1.x-lx)/dy
      ldu=(v1.u*w1-lu)/dy
      ldv=(v1.v*w1-lv)/dy
      ldw=(w1-lw)/dy
      --sub-pixel correction
      local dy=y-y0
      lx+=dy*ldx
      lu+=dy*ldu
      lv+=dy*ldv
      lw+=dy*ldw
    end   
    while ry<y do
      local v0=p[rj]
      rj-=1
      if (rj<1) rj=np
      local v1=p[rj]
      local y0,y1,w1=v0.y,v1.y,v1.w
      local dy=y1-y0
      ry=y1&-1
      rx=v0.x
      rw=v0.w
      ru=v0.u*rw
      rv=v0.v*rw
      rdx=(v1.x-rx)/dy
      rdu=(v1.u*w1-ru)/dy
      rdv=(v1.v*w1-rv)/dy
      rdw=(w1-rw)/dy
      --sub-pixel correction
      local dy=y-y0
      rx+=dy*rdx
      ru+=dy*rdu
      rv+=dy*rdv
      rw+=dy*rdw
    end
    
    -- rectfill(rx,y,lx,y,8/rw)
    if rw>0.15 then
      local ddx=lx-rx
      local ddu,ddv=(lu-ru)/ddx,(lv-rv)/ddx
      local pal1=rw>0.9375 and maxlight or (light*rw)\0.0625
      if(pal0!=pal1) memcpy(0x5f00,0x8000|pal1<<4,16) pal0=pal1
      local pix=1-rx&0x0.ffff
      tline(rx,y,lx\1-1,y,(ru+pix*ddu)/rw,(rv+pix*ddv)/rw,ddu/rw,ddv/rw)
    end

    lx+=ldx
    lu+=ldu
    lv+=ldv
    lw+=ldw
    rx+=rdx
    ru+=rdu
    rv+=rdv
    rw+=rdw
  end 
end
