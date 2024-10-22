local mpfr = terralib.includecstring[[
    #include <stdio.h>
    #include <mpfr.h>
]]
local prim = terralib.linkllvm[[prim.bc]]

terralib.linklibrary[[/lib/libgmp.so]]
terralib.linklibrary[[/lib/libmpfr.so]]

terra addo(a : uint64, b : uint64) : {uint64, bool}
    var r = a + b;
    return r, r > a;
end

terra addc(a : uint64, b : uint64, c : bool) : {uint64, bool}
    var r, rc = addo(a, b);
    var s, sc = addo(r, [uint64](c));
    return s, rc or sc;
end
addc:disas()

terra add2(a : uint64[2], b : uint64[2])
    var c : bool, r : uint64[2];
    r[0], c = addc(a[0], b[0], false);
    r[1], c = addc(a[1], b[1], c);
    return r;
end
add2:disas()
--local addc = prim:extern("adc_u64", {uint64, uint64, uint64, &uint64} -> uint64)

local fma_f = terralib.intrinsic("llvm.fma.f32", {float, float, float} -> float)
local fma_f0 = terralib.intrinsic("llvm.fma.f32", {vector(float, 0), vector(float, 0), vector(float, 0)} -> vector(float, 0))
local fma_f1 = terralib.intrinsic("llvm.fma.f32", {vector(float, 1), vector(float, 1), vector(float, 1)} -> vector(float, 1))
local fma_f2 = terralib.intrinsic("llvm.fma.f32", {vector(float, 2), vector(float, 2), vector(float, 2)} -> vector(float, 2))
local fma_f4 = terralib.intrinsic("llvm.fma.f32", {vector(float, 4), vector(float, 4), vector(float, 4)} -> vector(float, 4))
local fma_f8 = terralib.intrinsic("llvm.fma.f32", {vector(float, 8), vector(float, 8), vector(float, 8)} -> vector(float, 8))
local fma_f16 = terralib.intrinsic("llvm.fma.f32", {vector(float, 16), vector(float, 16), vector(float, 16)} -> vector(float, 16))

local fma = terralib.memoize(function(n)
    return terralib.intrinsic("llvm.fma.f32", {vector(float, n), vector(float, n), vector(float, n)} -> vector(float, n))
end)

local function twoprod(N)
    return terra (x : vector(float, N), y : vector(float, N))
        var z = x * y;
        return z, [fma(N)](x, y, -z);
    end
end
twoprod(4):disas()

-- forget integers, Shewchuck approach?

terra foo(x : vector(float, 4))
    return [twoprod(4)](x, x);
end

local mpq = mpfr.__mpfr_struct
terra test()
    var x : mpq;
    mpfr.mpfr_init2(&x, 4096);
    mpfr.mpfr_const_pi(&x, mpfr.MPFR_RNDN);
    mpfr.mpfr_dump(&x);
end

test()

--[[
terra addc(a : uint64, b : uint64, cin : uint64, cout : &uint64)
    var r1, cout1 = addo(a, b);
    var r, cout2 = addo(r1, cin);
    @cout = [uint64](cout1 or cout2);
    return r;
end
--]]

--[[
terra addc0(a : uint64, b : uint64, cout : &uint64)
    return addc(a, b, 0, cout);
end

terra add2(a : uint64[2], b : uint64[2])
    var carry : uint64;
    var r : uint64[2];
    r[0] = addc0(a[0], b[0], &carry);
    r[1] = addc(a[1], b[1], carry, &carry);
    return r
end

terra add3(a : uint64[3], b : uint64[3])
    var carry : uint64;
    var r : uint64[3];
    r[0] = addc0(a[0], b[0], &carry);
    r[1] = addc(a[1], b[1], carry, &carry);
    r[2] = addc(a[2], b[2], carry, &carry);
    return r[2]
end

terra add4(a : uint64[4], b : uint64[4])
    var c0 : uint64, c1 : uint64, c2 : uint64, c3 : uint64;
    var r : uint64[4];
    r[0] = addc0(a[0], b[0], &c0);
    r[1] = addc(a[1], b[1], c0, &c1);
    r[2] = addc(a[2], b[2], c1, &c2);
    r[3] = addc(a[3], b[3], c2, &c3);
    return r
end

terra meh(a : uint64[3], b : uint64[3])
    var c : uint64;
    var r0 = addc0(a[0], b[0], &c);
    var r1 = addc(a[1], b[1], c, &c);
    var r2 = addc(a[2], b[2], c, &c);
    return r2;
end

print(addc)
addc:disas()
add2:disas()
add3:disas()
terralib.saveobj("test.ll", {addc = addc, add2 = add2})
terralib.saveobj("test.s", {add2 = add2})
-- compile __builtin_addc from C to bitcode, link it and hope for inlining
--]]
