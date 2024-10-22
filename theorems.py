from z3 import *

Prec = Float32() # FPSort(8, 16)

def fma(a, b, c):
    return fpFMA(RNE(), a, b, c)

def two_sum(a, b):
    x = a + b
    bVirt = x - a
    y = b - bVirt
    return (x, y)

def fmma(a, b, c, d):
    ab = a * b
    abVirt = fpFMA(RNE(), a, b, -ab)
    return fpFMA(RNE(), c, d, ab) + abVirt

def thm_two_sum(F):
    s = Solver()
    a = FP('a', F)
    b = FP('b', F)
    (x, y) = two_sum(a, b)
    s.add(Not(fpToReal(a) + fpToReal(b) == fpToReal(x) + fpToReal(y)))
    print(s.check())
    m = s.model()
    print(m)
    exit()
    return s.check() == unsat

for p in range(3, 10):
    e = 5
    F = FPSort(e, p)
    print(p, thm_two_sum(F))

'''
s = Solver()
a = FP('a', Prec)
b = FP('b', Prec)
c = FP('c', Prec)
d = FP('d', Prec)
s.add(1 <= a, a < 2)
s.add(1 <= c, c < 2)
s.add(1 <= b, b < 65536)
s.add(fmma(a, b, c, d) == 0)
result = s.check()
while result == sat:
    m = s.model()
    ma = float(eval(str(m[a])))
    mb = float(eval(str(m[b])))
    mc = float(eval(str(m[c])))
    md = float(eval(str(m[d])))
    print(ma, mb, mc, md)
    s.add(a != ma, b != mb, c != mc, d != md)
    result = s.check()
'''
