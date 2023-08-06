---chatter
--play enemy chatter sfx on channels 0-2
--
--@param chatter { idx: 0-63, dist: 0-2 }
-- lowest enemy chatter sfx idx
--
--@returns void
function do_chatter(chatter)
  local
    variant,
    idx,
    dist
    =
    flr(rnd"4"),
    unpack(chatter)

  --loop audio channels
  for i = 0, 2 do
    --loop chatter sfx variants
    for j = 0, 3 do
      local cur_sfx = stat(46 + i)

      if
        --any non-chatter sfx in progress
        cur_sfx > 24
        --variant of this chatter idx in progress
        or cur_sfx == idx + j
      then
        return
      end
    end
  end

  local offset = (idx + variant) * 68

  --copy dampened sfx
  --start from 0xf120 to account for sfx idx 0-7 in offset value
  memcpy(0x3200 + offset, 0xf120 + 0x440 * dist + offset, 68)

  --playback random chatter variant
  sfx(idx + variant)
end
