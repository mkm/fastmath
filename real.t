local ffi = require[[ffi]]
local z3 = require[[z3]]

local real = {}

local Real = {}
real.Real = Real

function Real.mk(term)
    local result = {term = term}
    setmetatable(result, Real)
    return result
end

function Real.new(self, value)
    if type(value) == 'number' then
        value = tostring(value)
    end

    if type(value) == 'string' then
        return Real.mk(z3.mk_numeral(z3.context, value, z3.mk_real_sort(z3.context)))
    elseif type(value) == 'table' and getmetatable(value) == Real then
        return value
    else
        error(value)
    end
end

function Real.__tostring(self)
    if z3.is_algebraic_number(z3.context, self.term) then
        local lo = z3.get_algebraic_number_lower(z3.context, self.term, 30)
        local hi = z3.get_algebraic_number_upper(z3.context, self.term, 30)
        local approx = 0.5 * (z3.get_numeral_double(z3.context, lo) + z3.get_numeral_double(z3.context, hi))
        return '~' .. tostring(approx)
    else
        return ffi.string(z3.get_numeral_string(z3.context, self.term))
    end
end

function Real.__add(a, b)
    return Real.mk(z3.algebraic_add(z3.context, Real(a).term, Real(b).term))
end

function Real.__sub(a, b)
    return Real.mk(z3.algebraic_sub(z3.context, Real(a).term, Real(b).term))
end

function Real.__mul(a, b)
    return Real.mk(z3.algebraic_mul(z3.context, Real(a).term, Real(b).term))
end

function Real.__div(a, b)
    return Real.mk(z3.algebraic_div(z3.context, Real(a).term, Real(b).term))
end

function real.root(r, a)
    return Real.mk(z3.algebraic_root(z3.context, Real(a).term, r))
end

function real.sqrt(a)
    return real.root(2, a)
end

function real.cbrt(a)
    return real.root(3, a)
end

setmetatable(Real, {__call = Real.new})

return real
