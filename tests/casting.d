module tests.casting;
import numem.casting;

private class Test {
    T opCast(T)() {
        static if (is(T : int))
            return 42;
        else static if (is(T : void*))
            return reinterpret_cast!T(this);
        else static if (is(Test : T))
            return reinterpret_cast!T(this);
        else
            static assert(0, "Can't cast to type "~T.stringof~"!");
    }
}

@("reinterpret_cast: opCast")
unittest {
    import numem.lifetime;

    Test a = nogc_new!Test();
    assert(cast(int)a == 42);
    assert(cast(void*)a);
    assert(cast(Object)a);
}

@("const_cast: const to non-const")
unittest {
    const(char)* myString = "Hello, world!";
    char* myStringMut = const_cast!(char*)(myString);
    myString = const_cast!(const(char)*)(myStringMut);
}