local util = {}

function util.eval(q)
    local terra run()
        return [q];
    end
    return run()
end

util.bitcast = terralib.memoize(function(T)
    if (T:ispointer()) then
        T = T.type
    end
    local From = T.parameters[1]
    local To = T.returntype
    if terralib.sizeof(From) ~= terralib.sizeof(To) then
        error('Incompatible sizes for bitcasting')
    end
    local struct Convert
    {
        union
        {
            from : From;
            to : To;
        }
    }

    local terra bitcast(x : From) : To
        return (Convert {from = x}).to;
    end
    return bitcast
end)

terra get_double(x : double) : double
    return x;
end

terra get_int64(x : int64) : double
    return x;
end

local display

local function display_terra(value)
    local t = terralib.typeof(value)
    if t == double then
        io.write(get_double(value))
    elseif t == int64 then
        io.write(get_int64(value))
    elseif t:isarray() then
        io.write('[')
        for i = 0, t.N - 1 do
            if i ~= 0 then
                io.write(', ')
            end
            display(value[i])
        end
        io.write(']')
    elseif t:isstruct() then
        io.write(t.name)
        io.write('{')
        local first = true
        for _, entry in pairs(t.entries) do
            if not first then
                io.write(', ')
            end
            if entry.field then
                io.write(entry.field)
                io.write(' = ')
                display(value[entry.field])
            else
                io.write(entry[1])
                io.write(' = ')
                display(value[entry[1]])
            end
            first = false
        end
        io.write('}')
    else
        io.write('$' .. tostring(t))
    end
end

function display(value)
    local t = terralib.type(value)
    if t == 'number' then
        io.write(string.format('%.13a', value))
    elseif t == 'string' then
        io.write('"')
        io.write(value)
        io.write('"')
    elseif t == 'table' then
        io.write('{')
        local first = true
        local is_list = true
        local last_index = 0
        for k, v in pairs(value) do
            if not first then
                io.write(', ')
            end
            if is_list and k == last_index + 1 then
                last_index = last_index + 1
            else
                is_list = false
                display(k)
                io.write(' = ')
            end
            display(v)
            first = false
        end
        io.write('}')
    elseif t == 'cdata' then
        display_terra(value)
    else
        io.write(tostring(value))
    end
end

function util.disp(value)
    display(value)
    print()
end

return util
