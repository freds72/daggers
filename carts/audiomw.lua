---dampen sfx
--set dampen effect level of sfx
--
--warning: permanently mutates sfx runtime ram
--
--@param idx {0-63} sfx idx
--@param damp {0-2} dampen level
function sfx_damp(idx, damp)
  --sfx address
  local addr = 0x3200 + idx * 68 + 64
  --sfx effect byte
  local byte = @(addr)

  --set editormode + noiz + buzz
  local new_byte = byte & 0b111
  --set detune
  new_byte += (byte \ 8 % 3) * 8
  --set reverb
  new_byte += (byte \ 24 % 3) * 24
  --set dampen
  new_byte += damp * 72

  poke(addr, new_byte)
end

---modify volume of sfx
--
-- @param idx {0-63} start of sfx range to remove
-- @param v {-7-7} volume to increment/decrement by
function sfx_volume(idx, v)
  local sfx_addr = 0x3200 + idx * 68

  --loop through all notes
  for note_num = 0, 31 do
    local note_addr = sfx_addr + note_num * 2
    --get note from ram
    local note = %note_addr
    --get volume bits
    local volume = (note & 0xe00) >>> 9
    --calculate new volume
    local newvolume = volume > 0 and mid(1, volume + v, 7) or 0

    --insert new note
    poke2(note_addr, note & 0xf1ff | (newvolume << 9))
  end
end

--loop dampen levels
for damp = 0, 2 do
  --loop sfx
  for i = 0, 63 do
    --set dampen level
    sfx_damp(i, damp)
    --atennuate volume
    sfx_volume(i, -damp)
  end

  --copy sfx bank
  memcpy(0xcd00 + 0x1100 * damp, 0x3200, 0x1100)
end

--load next cart
load("daggers.p8")
