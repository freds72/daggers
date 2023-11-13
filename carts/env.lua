-- basic env helpers
local function inherit(t,env)
  return setmetatable(t,{__index=env or _ENV})
end
