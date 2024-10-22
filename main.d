module main;

import std.stdio;
import std.format;
import std.random;
import std.datetime.stopwatch;
import std.bigint;

import operations;

void testAddArray(string name, I128 delegate(long[]) fn)
{
    assert(fn([]) == I128(0, 0), name);
    assert(fn([42]) == I128(42, 0), name);
    assert(fn([1, 2, 3]) == I128(6, 0), name);
    assert(fn([1, -2, 3, -4]) == I128(-2, -1), name);
    assert(fn([long.min, -1]) == I128(long.max, -1), name);
}

unittest
{
    testAddArray("simple", ns => addArrayI64_simple(ns.ptr, ns.length));
}

unittest
{
    testAddArray("aligned", ns => addArrayI64_aligned(ns.ptr, ns.length));
}

unittest
{
    testAddArray("unroll", ns => addArrayI64_unroll(ns.ptr, ns.length));
}

unittest
{
    testAddArray("unrollmore", ns => addArrayI64_unrollmore(ns.ptr, ns.length));
}

I128 addArrayI64_bigint(long[] numbers)
{
    BigInt result = 0;
    foreach (n; numbers)
    {
        result += n;
    }
    return I128(0, 0);
}

void main()
{
    long[] ns1 = [1, 2];
    long[] ns2 = [3, 4];
    writeln(dotpArrayI64_simple(ns1.ptr, ns2.ptr, ns1.length));

    benchmarkFreq("freq", n => freq(n));

    benchmarkAddArrayI64("simple", ns => addArrayI64_simple(ns.ptr, ns.length));
    benchmarkAddArrayI64("aligned", ns => addArrayI64_aligned(ns.ptr, ns.length));
    benchmarkAddArrayI64("unroll", ns => addArrayI64_unroll(ns.ptr, ns.length));
    benchmarkAddArrayI64("unrollmore", ns => addArrayI64_unrollmore(ns.ptr, ns.length));
    benchmarkAddArrayI64("bigint", ns => addArrayI64_bigint(ns));

    benchmarkDotpArrayI64("simple", (ns1, ns2) => dotpArrayI64_simple(ns1.ptr, ns2.ptr, ns1.length));
    benchmarkDotpArrayI64("unroll", (ns1, ns2) => dotpArrayI64_unroll(ns1.ptr, ns2.ptr, ns1.length));
    benchmarkDotpArrayI64("chain", (ns1, ns2) => dotpArrayI64_chain(ns1.ptr, ns2.ptr, ns1.length));
}

long[] rndNumbers(size_t count)
{
    Random rng;
    auto numbers = new long[count];
    foreach (ref num; numbers)
    {
        num = uniform!long(rng);
    }
    return numbers;
}

void benchmarkFreq(string name, ulong delegate(ulong) fn)
{
    ulong count = 100000;
    auto watch = StopWatch(AutoStart.no);
    fn(count);
    int iterations = 0;
    watch.start();
    while (watch.peek.total!"msecs" < 250)
    {
        fn(count);
        iterations += 1;
    }
    watch.stop();
    writeln(name, ": ", (watch.peek / iterations).total!"usecs", "μ (", iterations, ")");
}

void benchmarkAddArrayI64(string name, I128 delegate(long[]) fn)
{
    auto numbers = rndNumbers(100000);
    auto watch = StopWatch(AutoStart.no);
    fn(numbers);
    int iterations = 0;
    watch.start();
    while (watch.peek.total!"msecs" < 250)
    {
        fn(numbers);
        iterations += 1;
    }
    watch.stop();
    writeln(name, ": ", (watch.peek / iterations).total!"usecs", "μ (", iterations, ")");
}

void benchmarkDotpArrayI64(string name, I192 delegate(long[], long[]) fn)
{
    auto numbers1 = rndNumbers(100000);
    auto numbers2 = rndNumbers(numbers1.length);
    auto watch = StopWatch(AutoStart.no);
    fn(numbers1, numbers2);
    int iterations = 0;
    watch.start();
    while (watch.peek.total!"msecs" < 250)
    {
        fn(numbers1, numbers2);
        iterations += 1;
    }
    watch.stop();
    writeln(name, ": ", (watch.peek / iterations).total!"usecs", "μ (", iterations, ")");
}
