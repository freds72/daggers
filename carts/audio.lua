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
    flr(rnd"3"),
    unpack(chatter)

  local offset = (idx + variant) * 68

  --loop audio channels
  for i = 0, 2 do
    local cur_sfx = stat(46 + i)

    --loop chatter sfx variants
    for j = 0, 2 do
      if
        --chatter variant in progress
        cur_sfx == idx + j
        --chatter not significantly complete
        and stat(50 + i) < 16
        --spawn sfx in progress
        or mid(40, cur_sfx, 42) == cur_sfx
      then
        return
      end
    end
  end

  --copy dampened sfx
  memcpy(0x3200 + offset, 0xcd00 + 0x1100 * dist + offset, 68)

  --playback random chatter variant
  sfx(idx + variant)
end
