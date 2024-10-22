local mpfr_raw = terralib.includec[[mpfr.h]]

terralib.linklibrary[[/lib/libgmp.so]]
terralib.linklibrary[[/lib/libmpfr.so]]

local ieee = {}

local mpfr = {}
for name, def in pairs(mpfr_raw) do
    if name:sub(1, 5) == 'mpfr_' or name:sub(1, 5) == 'MPFR_' then
        mpfr[name:sub(6)] = def
    end
end
mpfr.reg = mpfr_raw.__mpfr_struct

ieee.mpfr = mpfr

ieee.Float = terralib.memoize(function(prec)
    local N = mpfr.custom_get_size(prec)
    local struct Float
    {
        exponent : mpfr.exp_t;
        mantissa : uint8[N];
        kind : int8;
    }

    terra Float.methods.nan()
        var x : Float;
        mpfr.custom_init(&x.mantissa, prec);
        x.exponent = 0;
        x.kind = mpfr.NAN_KIND;
        return x;
    end

    terra Float.methods.reg(self : &Float)
        var r : mpfr.reg;
        mpfr.custom_init_set(&r, self.kind, self.exponent, prec, &self.mantissa[0]);
        return r;
    end

    terra Float.methods.upd(self : &Float, r : &mpfr.reg)
        self.exponent = mpfr.custom_get_exp(r);
        self.kind = mpfr.custom_get_kind(r);
    end

    terra Float.methods.from_double(x : double)
        var y = Float.nan();
        var yr = y:reg();
        mpfr.set_d(&yr, x, mpfr.RNDN);
        y:upd(&yr);
        return y;
    end

    terra Float.methods.to_double(self : &Float)
        var r = self:reg();
        return mpfr.get_d(&r, mpfr.RNDN);
    end

    for _, binop in ipairs({'add', 'sub', 'mul', 'div'}) do
        Float.metamethods['__' .. binop] = terra(x : Float, y : Float)
            var z = Float.nan();
            var xr = x:reg();
            var yr = y:reg();
            var zr = z:reg();
            [mpfr[binop]](&zr, &xr, &yr, mpfr.RNDN);
            z:upd(&zr);
            return z;
        end
    end

    terra Float.methods.fma(x : Float, y : Float, z : Float)
        var w = Float.nan();
        var xr = x:reg();
        var yr = y:reg();
        var zr = z:reg();
        var wr = w:reg();
        mpfr.fma(&wr, &xr, &yr, &zr, mpfr.RNDN);
        w:upd(&wr);
        return w;
    end

    return Float
end)

return ieee
