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
      if
        --music playing
        stat"57"
        --chatter variant in progress
        or stat(46 + i) == idx + j
      then
        return
      end
    end
  end

  local offset = (idx + variant) * 68

  --copy dampened sfx
  memcpy(0x3200 + offset, 0xcd00 + 0x1100 * dist + offset, 68)

  --playback random chatter variant
  sfx(idx + variant)
end
