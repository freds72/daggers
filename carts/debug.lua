-- misc helpers
function v_tostr(v)
    return "{"..v[1]..", "..v[2]..", "..v[3].."}"
end

local _stack,_names={},{}
function bench_start(name)
    add(_stack,name)
    _names[name]=stat(1)
end

function bench_end()
    local name=deli(_stack)
    _names[name]=stat(1)-_names[name]
end

function bench_print(x,y,c)
    for k,v in pairs(_names) do
        print(k..": "..flr(100*v).."%",x,y,c)
        y+=7
    end
end