local math = require[[math]]
local io = require[[io]]
local util = require[[util]]
local qc = require[[quickcheck]]
local ieee = require[[ieee]]
local real = require[[real]]

local fma = terralib.intrinsic("llvm.fma.f64", {double, double, double} -> double);
local fabs = terralib.intrinsic("llvm.fabs.f64", {double} -> double);

terra min(a : double, b : double) : double
    if a < b then
        return a
    else
        return b
    end
end

terra max(a : double, b : double) : double
    if a < b then
        return b
    else
        return a
    end
end

terra minmax(a : double, b : double) : {double, double}
    return min(a, b), max(a, b);
end

terra amin(a : double, b : double) : double
    if fabs(a) < fabs(b) then
        return a
    else
        return b
    end
end

terra amax(a : double, b : double) : double
    if fabs(a) >= fabs(b) then
        return a
    else
        return b
    end
end

terra aminmax(a : double, b : double) : {double, double}
    return amin(a, b), amax(a, b);
end

terra sign(x : double) : double
    return [double](x > 0) - [double](x < 0);
end

terra ord_two_sum(a : double, b : double) : {double, double}
    var x = a + b;
    return x, b - (x - a);
end

terra ord_two_diff(a : double, b : double) : {double, double}
    var x = a - b;
    return x, (a - x) - b;
end

terra two_sum(a : double, b : double) : {double, double}
    var x = a + b;
    var bVirt = x - a;
    var aVirt = x - bVirt;
    return x, (b - bVirt) + (a - aVirt);
end

terra singleton(a : double) : double[1]
    return array(a);
end

local merge_expansions
merge_expansions = terralib.memoize(function(M, N)
    if M > N then
        return terra(a : double[M], b : double[N]) : double[M + N]
            return [merge_expansions(N, M)](b, a);
        end
    elseif N == 0 then
        return terra(a : double[M], b : double[0]) : double[M]
            return a;
        end
    elseif M == 1 and N == 1 then
        return terra(a : double[1], b : double[1]) : double[2]
            var r : double[2];
            r[0] = amin(a[0], b[0]);
            r[1] = amax(a[0], b[0]);
            return r;
        end
    elseif M == 1 and N == 2 then
        return terra(a : double[1], b : double[2]) : double[3]
            var r : double[3];
            r[0] = amin(a[0], b[0]);
            r[1] = amin(amax(a[0], b[0]), b[1]);
            r[2] = amax(a[0], b[1]);
            return r;
        end
    elseif M == 2 and N == 2 then
        return terra(a : double[2], b : double[2]) : double[4]
            var r : double[4];
            var t0 : double, t3 : double;
            r[0], t0 = aminmax(a[0], b[0]);
            t3, r[3] = aminmax(a[1], b[1]);
            r[1], r[2] = aminmax(t0, t3);
            return r;
        end
    elseif M == 1 and N == 3 then
        return terra(a : double[1], b : double[3]) : double[4]
            var r : double[4];
            var t0 : double, t3 : double;
            r[0], t0 = aminmax(a[0], b[0]);
            t3, r[3] = aminmax(a[0], b[2]);
            r[1] = amin(t0, b[1]);
            r[2] = amax(t3, b[2]);
        end
    else
        return terra(a : double[M], b : double[N]) : double[M + N]
            var r : double[M + N];
            var ai = 0;
            var bi = 0;
            var ri = 0;
            while ai < M and bi < N do
                if a[ai] < b[bi] then
                    r[ri] = a[ai];
                    ai = ai + 1;
                    ri = ri + 1;
                else
                    r[ri] = b[bi];
                    bi = bi + 1;
                    ri = ri + 1;
                end
            end
            while ai < M do
                r[ri] = a[ai];
                ai = ai + 1;
                ri = ri + 1;
            end
            while bi < N do
                r[ri] = b[bi];
                bi = bi + 1;
                ri = ri + 1;
            end
            return r;
        end
    end
end)

local expansion_neg = terralib.memoize(function(N)
    return terra(a : double[N]) : double[N]
        var r : double[N];
        for i = 0, N do
            r[i] = -a[i];
        end
        return r;
    end
end)

local grow_expansion = terralib.memoize(function(N)
    return terra(a : double[N], b : double) : double[N + 1]
        var r : double[N + 1];
        for i = 0, N do
            b, r[i] = two_sum(b, a[i])
        end
        r[N] = b;
        return r;
    end
end)

local uncons = terralib.memoize(function(N)
    return terra(a : double[N]) : {double, double[N - 1]}
        var r : double[N - 1];
        for i = 1, N do
            r[i] = a[i];
        end
        return a[0], r;
    end
end)

local expansion_sum
expansion_sum = terralib.memoize(function(M, N)
    if M > N then
        return terra(a : double[M], b : double[N]) : double[M + N]
            return [expansion_sum(N, M)](b, a);
        end
    elseif M == 0 then
        return terra(a : double[0], b : double[N]) : double[N]
            return b;
        end
    elseif M <= 2 then
        return terra(a : double[M], b : double[N]) : double[M + N]
            var a0, as = [uncons(M)](a);
            return [expansion_sum(M - 1, N + 1)](as, [grow_expansion(N)](b, a0));
        end
    else
        return terra(a : double[M], b : double[N]) : double[M + N]
            var c = [merge_expansions(M, N)](a, b);
            var r : double[M + N];
            var q : double;
            q, r[0] = ord_two_sum(c[1], c[0]);
            for i = 2, M + N do
                q, r[i - 1] = two_sum(q, c[i]);
            end
            r[M + N - 1] = q;
            return r;
        end
    end
end)

local expansion_diff = terralib.memoize(function(M, N)
    return terra(a : double[M], b : double[N]) : double[M + N]
        return [expansion_sum(M, N)](a, [expansion_neg(N)](b));
    end
end)

local many_sum
many_sum = terralib.memoize(function(N)
    if N <= 1 then
        return terra(a : double[N]) : double[N]
            return a;
        end
    elseif N == 2 then
        return terra(a : double[2]) : double[2]
            var r : double[2];
            r[1], r[0] = two_sum(a[0], a[1]);
            return r;
        end
    else
        local N1 = math.floor(N / 2)
        local N2 = N - N1
        return terra(a : double[N]) : double[N]
            var b : double[N1];
            var c : double[N2];
            for i = 0, N1 do
                b[i] = a[i];
            end
            for i = 0, N2 do
                c[i] = a[N1 + i];
            end
            return [expansion_sum(N1, N2)]([many_sum(N1)](b), [many_sum(N2)](c));
        end
    end
end)

local Array = terralib.memoize(function(T, N)
    local struct Array
    {
        values : T[N]
    }
    return Array
end)
--[[
expansion_sum(2, 2):disas()
merge_expansions(2, 2):disas()
--]]
--many_sum(4):disas()
terra test_expansion(a : &double, b : &double) : Array(double, 4)
    return [Array(double, 4)] { values = [expansion_sum(2, 2)](arrayof(double, a[0], a[1]), arrayof(double, b[0], b[1])) };
end
util.disp(test_expansion(terralib.new(double[2], {0, 5465465}), terralib.new(double[2], {0, 1231893168465457993})))

terra test_merge(a : &double, b : &double) : Array(double, 4)
    return [Array(double, 4)] { values = [merge_expansions(2, 2)](arrayof(double, a[0], a[1]), arrayof(double, b[0], b[1])) };
end

terra test_sum(a : &double) : Array(double, 4)
    return [Array(double, 4)] { values = [many_sum(4)](arrayof(double, a[0], a[1], a[2], a[3])) };
end
util.disp(test_sum(terralib.new(double[4], {1e100, 0.1, 1 / 3, -1e100})))
util.disp(test_merge(terralib.new(double[2], {0, 1}), terralib.new(double[2], {0, -1})))

terra two_prod(a : double, b : double) : {double, double}
    var x = a * b;
    return x, fma(a, b, -x);
end

local scale_expansion = terralib.memoize(function(N)
    return terra(a : double[N], b : double) : double[N * 2]
        var r : double[N * 2];
        var q : double;
        q, r[0] = two_prod(a[0], b);
        for i = 1, N do
            var t, u = two_prod(a[i], b);
            q, r[i * 2 - 1] = two_sum(q, u);
            q, r[i * 2] = ord_two_sum(t, q);
        end
        r[N * 2 - 1] = q;
        return r;
    end
end)

-- expansion_prod

local terra fmma(a : double, b : double, c : double, d : double) : double
    var x, y = two_prod(a, b);
    return fma(c, d, x) + y;
end

local robust_dotp = terralib.memoize(function(N)
    if N == 0 then
        return terra(a : double[0], b : double[0]) : double
            return 0;
        end
    elseif N == 1 then
        return terra(a : double[1], b : double[1]) : double
            return a[0] * b[0];
        end
    elseif N == 2 then
        return terra(a : double[2], b : double[2]) : double
            var x, y = two_prod(a[0], b[0]);
            return fma(a[1], b[1], x) + y;
        end
    elseif N == 3 then
        return terra(a : double[3], b : double[3]) : double
            var x, y = two_prod(a[0], b[0]);
            -- x + y = a0 * b0
            var w = fma(a[1], b[1], x) + y;
            -- w = a0 * b0 + a1 * b1 + err(a0 * b0 + a1 * b1) ?
            var z = fma(a[1], b[1], x);
            -- z = a1 * b1 + x + err(ab1 + x)
            var xVirt = fma(-a[1], b[1], z);
            -- xVirt = -ab1 + z + err(-ab1 + z) = x + err(ab1 + x) + err(-ab1 + z)
            var abVirt = z - xVirt
            -- abVirt = ab1 - err(-ab1 + z)
            var xRnd = x - xVirt;
            -- xRnd = -(err(ab1 + x) + err(-ab1 + z))
            var abRnd = fma(a[1], b[1], -abVirt)
            -- abRnd = ab1 - abVirt = err(-ab1 + z)
            return xRnd;
        end
    else
        error("robust_dotp")
    end
end)

struct P2
{
    x : double;
    y : double;
}

terra orient(p : P2, q : P2, r : P2)
    var a = [expansion_diff(1, 1)](singleton(p.x), singleton(r.x));
    var b = [expansion_diff(1, 1)](singleton(q.y), singleton(r.y));
    return (p.x - r.x) * (q.y - r.y) - (p.y - r.y) * (q.x - r.x);
end
-- orient:disas()

local F8 = ieee.Float(8)
terra foo()
    var x = F8.from_double(7);
    var y = F8.from_double(11);
    var z = x * x + y;
    return z:to_double();
end
--util.disp(foo())
--util.disp(ieee.mpfr)

local F = ieee.Float(300)
local terra q(x : double)
    return F.from_double(x)
end
terra fmma_exact(a : double, b : double, c : double, d : double) : double
    return (F.from_double(a) * F.from_double(b) + F.from_double(c) * F.from_double(d)):to_double();
end

terra fmma_naive(a : double, b : double, c : double, d : double) : double
    return a * b + c * d;
end

local ld = qc.logdouble(-100, 100)
qc.check(100, qc.multiple(ld, ld, ld, ld), function(a, b, c, d)
    d = a * b / -c
    return fmma(a, b, c, d) == fmma_exact(a, b, c, d)
end)

local function investigate(a, b, c, d)
    -- d = a * b / -c
    util.disp({a, b, c, d})
    util.disp(fmma(a, b, c, d))
    util.disp(fmma_exact(a, b, c, d))
    util.disp(fmma(a, b, c, d) - fmma_exact(a, b, c, d))
end
print('FMMA')
investigate(2.6861733687372837e-154, 9.73791703805069e-193, 2.16451021042347e-30, 9.73791703805069e-193)
investigate(2.6861733687372837e-154, 9.73791703805069e-193, 2.16451021042347e-30, 1.370727473111642e-308)
investigate(1.2066119173339176, -3.14666497011279e-309, 1.9315486251240335, 1.965678421660994e-309)
investigate(1.7587077876245154, -7.499127197751695e-309, 1.5806244935972351, 8.344026969402005e-309)

--[[
1.2399611473083496 -1.1850108489532102e-39 1.5725194215774536 9.344040328918242e-40
1.0 -0.0 1.0625152587890625 -0.0
1.0000038146972656 0.0 1.062515377998352 0.0
1.5130908489227295 3.4441113656175354e-41 1.814073920249939 -2.872661851865875e-41
1.5130906105041504 -3.4441113656175354e-41 1.8140867948532104 2.872661851865875e-41
1.7890651226043701 -1.0089348943138683e-43 1.0042634010314941 1.793662034335766e-43
1.7890644073486328 1.0089348943138683e-43 1.0042635202407837 -1.793662034335766e-43
1.9765625 9.248569864543793e-44 1.0042301416397095 -1.807675018979014e-43
1.978515625 -9.248569864543793e-44 1.0120426416397095 1.807675018979014e-43
1.7769107818603516 1.0369608636003646e-43 1.004228949546814 -1.821688003622262e-43
1.7690982818603516 -1.0369608636003646e-43 1.0042288303375244 1.821688003622262e-43
1.0391845703125 8.96831017167883e-44 1.0231376886367798 -9.10844001811131e-44
1.0118921995162964 -5.605193857299268e-45 1.438517689704895 4.203895392974451e-45
1.0118920803070068 5.605193857299268e-45 1.438522458076477 -4.203895392974451e-45
1.0079389810562134 -5.878189218925172e-39 1.007676362991333 5.879722239445143e-39
1.3508391380310059 5.882856944109838e-39 1.263236165046692 -6.290821169924115e-39
1.348122477531433 5.878910887634299e-39 1.3484503030776978 -5.877481563200688e-39
1.3481223583221436 5.878909486335835e-39 1.34843111038208 -5.877562838511619e-39
1.348122239112854 -5.878909486335835e-39 1.3484477996826172 5.877489970991474e-39
1.3481234312057495 -5.878910887634299e-39 1.3483028411865234 5.878128963091206e-39
1.492187738418579 1.2051166793193427e-43 1.9102622270584106 -9.388699710976274e-44
1.2041077613830566 -5.881783549486165e-39 1.0637162923812866 6.658073471454363e-39
1.204115390777588 -5.881782148187701e-39 1.0636725425720215 6.658388763608836e-39
1.8516182899475098 6.612166933763082e-39 1.8262330293655396 -6.704078100038147e-39
1.1583292484283447 5.969307250269429e-39 1.8583284616470337 -3.7207753266230413e-39
1.1953234672546387 -6.2462710891463e-39 1.2696589231491089 5.880567222419131e-39
1.377349615097046 5.879265416145773e-39 1.0019845962524414 -8.08176468523909e-39
1.377320408821106 -5.879266817444238e-39 1.0019655227661133 8.081749270955983e-39
1.6494866609573364 -5.878196225417493e-39 1.6494146585464478 5.878452663036465e-39
1.6494868993759155 5.878196225417493e-39 1.649418830871582 -5.878438650051822e-39
1.2947845458984375 26513.791015625 1.618273377418518 -21213.75
--]]

--[[
investigate(0x1.f17c5494495f4p+78, 0x1.2a06584b05578p-29, 0x1.1a617d1e0ea00p-4, 0x1.8ae775af41900p+22)
investigate(0x1.713053ee63160p-39, 0x1.ea3c2f479dd20p+72, 0x1.a2c92867964b0p+45, 0x1.adc34941ecce0p-47)
investigate(0x1.8bc77d07fca7ap+81, 0x1.c6a7c62b86caap-84, 0x1.a7e0cfdc6f8f4p+78, 0x1.fc709d3bfa1a0p-89)
investigate(0x1.f17c5494495f4p+78, 0x1.2a06584b05578p-29, 0x1.1a617d1e0ea00p-4, 0x1.8ae775af41900p+22)
investigate(0x1.76ee7dccf2f22p-76, 0x1.b41e7b67feed0p-6, 0x1.14bd11b1aaf54p+47, 0x1.0a006facbcd18p+3)
--]]

terra det(x0 : double, y0 : double, x1 : double, y1 : double, x2 : double, y2 : double) : double
    return fmma(x0 - x2, y0 - y2, x1 - x2, y1 - y2);
end

terra det_exact(x0 : double, y0 : double, x1 : double, y1 : double, x2 : double, y2 : double) : double
    return
        ((F.from_double(x0) - F.from_double(x2)) * (F.from_double(y0) - F.from_double(y2)) +
         (F.from_double(x1) - F.from_double(x2)) * (F.from_double(y1) - F.from_double(y2))):to_double();
end

qc.check(10, qc.multiple(ld, ld, ld, ld, ld), function(y0, x1, y1, x2, y2)
    local terra last()
        return ((q(x1) - q(x2)) * (q(y1) - q(y2)) / (q(y0) - q(y2)) + q(x2)):to_double();
    end
    local x0 = last()
    return det(x0, y0, x1, y1, x2, y2) == det_exact(x0, y0, x1, y1, x2, y2)
end)
local function investigate(y0, x1, y1, x2, y2)
    local terra last()
        return ((q(x1) - q(x2)) * (q(y1) - q(y2)) / (q(y0) - q(y2)) + q(x2)):to_double();
    end
    local x0 = last()
    util.disp({x0, y0, x1, y1, x2, y2})
    util.disp(det(x0, y0, x1, y1, x2, y2))
    util.disp(det_exact(x0, y0, x1, y1, x2, y2))
end
print('DET')
--investigate(0x1.332ef30a370e8p-91, 0x1.ae186220bbc34p+14, 0x1.d317927505624p+62, 0x1.1aecfb336872ep-26, 0x1.04dc00a91d400p-42)
--investigate(0x1.7912b59e22f44p+8, 0x1.5d7709423295ep-43, 0x1.bc5587c344decp+2, 0x1.34f68e7a133d0p-87, 0x1.3a68476b6b124p-28)
--det:disas()
-- gradient descent to find tricky inputs?
