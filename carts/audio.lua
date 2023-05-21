---enemy chatter
--play sfx only if sfx is not already playing, or playback is almost complete
function do_chatter(idx)
  --loop audio channels
  for i = 0, 3 do
    --loop chatter sfx variants
    for j = 0, 2 do
      if
        --chatter in progress
        stat(46 + i) == idx + j
        --playback not significantly complete
        and stat(50 + i) < 16
      then
        return
      end
    end
  end

  --playback random chatter variant
  sfx(idx + flr(rnd"3"))
end

