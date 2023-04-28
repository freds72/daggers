-- asset loading
-- data unpacking functions
function mpeek2()
	return mpeek()|mpeek()<<8
end
-- unpack a fixed 16:16 value or 4 bytes
function mpeek4()
	return mpeek2()|mpeek()>>>16|mpeek()>>8
end

-- unpack an array of bytes
function unpack_array(fn)
	for i=1,mpeek2() do
		fn(i)
	end
end

function unpack_frames(sprites)
  local frames={}
  unpack_array(function()
    -- recover sign (empty picetures)
    local height=(mpeek()<<8)>>8
    local frame=add(frames,{
      xmin=mpeek(),
      width=mpeek(),
      ymin=mpeek(),   
      height=height,
      base=#sprites+1
    })
    for i=1,height*4 do
      add(sprites,mpeek4())
    end
  end)
  return frames
end