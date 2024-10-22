from z3 import *

flt = Function('flt', RealSort(), BoolSort())
add = Function('add', RealSort(), RealSort(), RealSort())
mul = Function('mul', RealSort(), RealSort(), RealSort())
fma = Function('fma', RealSort(), RealSort(), RealSort(), RealSort())
ε = Real('ε')

def axioms(s):
    s.add(0 < ε, ε * 16 < 1)
    s.add(ε * 32 == 1)

def Flt(s, name):
    x = Real(name)
    s.add(flt(x))
    return x

def sign(x):
    return If(x < 0, -1, If(x > 0, 1, 0))

def fadd(s, a, b):
    r = a + b
    rf = add(a, b)
    rnd = Abs(rf - r)
    s.add(flt(rf))
    s.add(flt(rf - r))
    s.add(flt(r - rf))
    s.add(flt(r) == (r == rf))
    s.add(rnd <= Abs(a))
    s.add(rnd <= Abs(b))
    s.add(rnd <= Abs(ε * rf))
    s.add(Abs(rf) <= 2 * Abs(a))
    s.add(Abs(rf) <= 2 * Abs(b))
    s.add(Or(Abs(a) <= 2 * Abs(b), Abs(a) <= 2 * Abs(rf)))
    s.add(Or(Abs(b) <= 2 * Abs(a), Abs(b) <= 2 * Abs(rf)))
    s.add(Implies(And(Abs(r) <= Abs(a), Abs(r) <= Abs(b)), r == rf))
    s.add(Implies(And(a / 2 <= -b, -b <= a * 2), r == rf))
    return rf

def fsub(s, a, b):
    return fadd(s, a, -b)

def fmul(s, a, b):
    r = a * b
    rf = mul(a, b)
    rnd = Abs(rf - r)
    s.add(sign(rf) == sign(r))
    s.add(flt(rf))
    s.add(flt(rf - r))
    s.add(flt(r - rf))
    s.add(flt(r) == (r == rf))
    s.add(rnd <= Abs(ε * rf))
    return rf

def ffma(s, a, b, c):
    r = a * b + c
    rf = fma(a, b, c)
    rnd = Abs(rf - r)
    s.add(flt(rf))
    s.add(flt(rf - r))
    s.add(flt(r - rf))
    s.add(flt(r) == (r == rf))
    s.add(rnd <= Abs(a * b))
    s.add(rnd <= Abs(c))
    s.add(rnd <= Abs(ε * rf))
    s.add(Abs(rf) <= 2 * Abs(a * b))
    s.add(Abs(rf) <= 2 * Abs(c))
    return rf

def ord_two_sum(s, a, b):
    x = fadd(s, a, b)
    bVirt = fsub(s, x, a)
    y = fsub(s, b, bVirt)
    return (x, y)

def two_sum(s, a, b):
    x = fadd(s, a, b)
    bVirt = fsub(s, x, a)
    aVirt = fsub(s, x, bVirt)
    bRnd = fsub(s, b, bVirt)
    aRnd = fsub(s, a, aVirt)
    y = fadd(s, aRnd, bRnd)
    return (x, y)

def two_prod(s, a, b):
    x = fmul(s, a, b)
    y = ffma(s, a, b, -x)
    return (x, y)

def ffmma(s, a, b, c, d):
    (x, y) = two_prod(s, a, b)
    return fadd(s, ffma(s, c, d, x), y)

def thm_add_deterministic():
    s = Solver()
    axioms(s)
    a = Flt(s, 'a')
    b = Flt(s, 'b')
    s.add(Not(fadd(s, a, b) == fadd(s, a, b)))
    return s.check() == unsat

def thm_mul_deterministic():
    s = Solver()
    axioms(s)
    a = Flt(s, 'a')
    b = Flt(s, 'b')
    s.add(Not(fmul(s, a, b) == fmul(s, a, b)))
    return s.check() == unsat

def thm_ord_two_sum():
    s = Solver()
    axioms(s)
    a = Flt(s, 'a')
    b = Flt(s, 'b')
    s.add(Abs(a) >= Abs(b))
    (x, y) = ord_two_sum(s, a, b)
    s.add(Not(And(a + b == x + y, Or(x == 0, Abs(x) > Abs(y)))))
    return s.check() == unsat

def thm_two_sum():
    s = Solver()
    axioms(s)
    a = Flt(s, 'a')
    b = Flt(s, 'b')
    (x, y) = two_sum(s, a, b)
    s.add(Not(And(a + b == x + y, Or(x == 0, Abs(x) > Abs(y)))))
    return s.check() == unsat

def thm_two_prod():
    s = Solver()
    axioms(s)
    a = Flt(s, 'a')
    b = Flt(s, 'b')
    (x, y) = two_prod(s, a, b)
    s.add(Not(a * b == x + y))
    return s.check() == unsat

def thm_fmma():
    s = Solver()
    axioms(s)
    a = Flt(s, 'a')
    b = Flt(s, 'b')
    c = Flt(s, 'c')
    d = Flt(s, 'd')
    s.add(Not(sign(ffmma(s, a, b, c, d)) == sign(a * b + c * d)))
    s.add(IsInt(a))
    s.add(IsInt(b))
    s.check()
    m = s.model()
    print(m)
    print("mul(a, b) =", m.eval(mul(a, b)))
    print("fma(a, b, -mul(a, b)) =", m.eval(fma(a, b, -mul(a, b))))
    print("fma(c, d, mul(a, b)) =", m.eval(fma(c, d, mul(a, b))))
    print("fmma(a, b, c, d) =", m.eval(ffmma(s, a, b, c, d)))
    print("a * b + c * d =", m.eval(a * b + c * d))
    return s.check() == unsat

print("Theorem add-deterministic:", thm_add_deterministic())
print("Theorem mul-deterministic:", thm_mul_deterministic())
print("Theorem ord-two-sum:", thm_ord_two_sum())
print("Theorem two-sum:", thm_two_sum())
print("Theorem two-prod:", thm_two_prod())
print("Theorem fmma:", thm_fmma())
