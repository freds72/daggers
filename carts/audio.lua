---enemy chatter
--play sfx only if sfx is not already playing, or playback is almost complete
function do_chatter(idx)
  --loop audio channels
  for i = 0, 3 do
    local cur_sfx = stat(46 + i)

    --loop chatter sfx variants
    for j = 0, 2 do
      if
        --chatter in progress
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

  --playback random chatter variant
  sfx(idx + flr(rnd"3"))
end

