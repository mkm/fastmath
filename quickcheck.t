local math = require[[math]]
local util = require[[util]]

local quickcheck = {}

local function pack(...)
    return {...}
end

function quickcheck.double(a, b)
    return function()
        local x = math.random()
        return (1 - x) * a + x * b
    end
end

function quickcheck.logdouble(a, b)
    return function()
        local x = math.random()
        local y = math.random(a, b)
        return x * 2 ^ y
    end
end

function quickcheck.multiple(...)
    local gens = {...}
    return function()
        local args = {}
        for i, gen in ipairs(gens) do
            args[i] = gen()
        end
        return unpack(args)
    end
end

function quickcheck.check(samples, gen, fn)
    for i = 1, samples do
        local values = pack(gen())
        if not fn(unpack(values)) then
            util.disp(values)
        end
    end
end

return quickcheck
