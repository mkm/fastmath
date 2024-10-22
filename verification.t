local util = require[[util]]

local minpd = terralib.intrinsic("llvm.x86.sse2.min.pd", {vector(double, 2), vector(double, 2)} -> vector(double, 2))
local maxpd = terralib.intrinsic("llvm.x86.sse2.max.pd", {vector(double, 2), vector(double, 2)} -> vector(double, 2))

local contra = false

struct Range
{
    bound : vector(double, 2);
}

local bitcast_i2d = util.bitcast(vector(uint64, 2) -> vector(double, 2))
local bitcast_d2i = util.bitcast(vector(double, 2) -> vector(uint64, 2))

local terra mk_double(sign : int, exponent : int, mantissa : uint64)
    var bits = mantissa;
    bits = bits or ([uint64](exponent + 1023) << 52);
    if sign == 1 then
        bits = bits or (1ULL << 63)
    end
    return [util.bitcast(uint64 -> double)](bits);
end

local min_double = mk_double(0, -1023, 1)
local max_double = mk_double(0, 1023, 0xFFFFFFFFFFFFF)

local terra sign(a : double)
    var bits = [util.bitcast(double -> uint64)](a);
    return [int](bits >> 63);
end

local terra exponent(a : double)
    var bits = [util.bitcast(double -> uint64)](a);
    return [int]((bits >> 52) and 0x7FF) - 1023;
end

local terra next_double(a : double)
    var bits = [util.bitcast(double -> uint64)](a);
    if bits == 0x8000000000000000ULL then
        bits = 0
    else
        bits = bits + 1
    end
    return [util.bitcast(uint64 -> double)](bits);
end

local terra prev_double(a : double)
    var bits = [util.bitcast(double -> uint64)](a);
    if bits == 0 then
        bits = 0x8000000000000000ULL
    else
        bits = bits - 1
    end
    return [util.bitcast(uint64 -> double)](bits);
end

local terra hflip(a : vector(double, 2))
    var s = vector(0.0, -0.0);
    return bitcast_i2d(bitcast_d2i(a) ^ bitcast_d2i(s));
end

local hadj
if contra then
    hadj = hflip
else
    terra hadj(a : vector(double, 2))
        return a
    end
end

local terra range(lo : double, hi : double) : Range
    return Range {bound = hadj(vector(lo, hi))};
end

local terra point(a : double) : Range
    return range(a, a);
end

terra Range.metamethods.__apply(a : Range, i : int)
    if i == 0 then
        return hadj(a.bound)[0]
    else
        return hadj(a.bound)[1];
    end
end

local terra is_point(a : Range)
    return a(0) == a(1);
end

local terra is_local(a : Range)
    return exponent(a(0)) == exponent(a(1));
end

local terra bounds(a : Range) : {double, double}
    return a(0), a(1);
end

terra Range.metamethods.__and(a : Range, b : Range)
    return Range {bound = hadj(hflip(maxpd(hflip(hadj(a.bound)), hflip(hadj(b.bound)))))};
end

terra Range.metamethods.__or(a : Range, b : Range)
    return Range {bound = hadj(hflip(minpd(hflip(hadj(a.bound)), hflip(hadj(b.bound)))))};
end

terra Range.metamethods.__add(a : Range, b : Range)
    return Range {bound = a.bound + b.bound};
end

terra Range.metamethods.__unm(a : Range)
    return Range {bound = -a.bound};
end

terra Range.metamethods.__sub(a : Range, b : Range)
    return Range {bound = a.bound - b.bound};
end

terra Range.metamethods.__mul(a : Range, b : Range)
    var p = vector(a(0), a(0), a(1), a(1)) * vector(b(0), b(1), b(0), b(1));
    return (point(p[0]) or point(p[1])) or (point(p[2]) or point(p[3]));
end

terra Range.metamethods.__le(a : Range, b : Range)
    return a(1) <= b(0);
end

terra Range.metamethods.__lt(a : Range, b : Range)
    return a(1) < b(0);
end

terra Range.metamethods.__gt(a : Range, b : Range)
    return b < a;
end

local terra test(a : Range, b : Range) : Range
    return a + b;
end

local terra logsplit(a : Range) : {Range, Range}
    var e0 = exponent(a(0));
    var e1 = exponent(a(1));
    var em : int;
    if e0 + 1 == e1 then
        em = e1;
    else
        em = (e0 + e1) / 2;
    end
    var mid = mk_double(sign(a(0)), em, 0);
    return range(a(0), prev_double(mid)), range(mid, a(1));
end

local terra count_cubes(a : Range, b : Range) : int
    var r = test(a, b);
    if is_point(r) or r(1) - r(0) < 0.000001 then
        return 1;
    elseif r < point(0) then
        return 1;
    elseif r > point(0) then
        return 1;
    else
        var aMid = 0.5 * (a(0) + a(1));
        var bMid = 0.5 * (b(0) + b(1));
        return
            count_cubes(range(a(0), aMid), range(b(0), bMid)) +
            count_cubes(range(a(0), aMid), range(bMid, b(1))) +
            count_cubes(range(aMid, a(1)), range(b(0), bMid)) +
            count_cubes(range(aMid, a(1)), range(bMid, b(1)));
    end
end

local terra count_segments(a : Range, b : Range, c : Range, d : Range)
end

-- print(util.eval(`count_cubes(range(1, 2), range(-2, -1))))

-- bisect on exponent, then generate constraints on mantissas?
-- enumerate exponent on one node, then propagate intervals
-- split based on nature of addition; a << b, a < b, a = b, a > b, a >> b
-- maybe case for fairly close numbers (Sterbenz lemma)
-- enumerate differences in exponent
