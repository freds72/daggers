-- string/value replacement function
-- credits: @heraclum
function scanf(st,...)
  local s=""
  for i,p in inext,split(st,"$") do
      s..=select(i,"",...)..p
  end
  return s
end

-- split a 2d table:
-- each line is \n separated
-- section in ; separated
-- name credits: @krystman
function split2d(config,cb)
  for line in all(split(config,"\n")) do
    cb(unpack(split(line,";")))
  end
end
