/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Numem casting helpers
*/
module numem.core.casting;

nothrow @nogc:

/**
    Removes all qualifiers from type T.
*/
template Unqual(T : const U, U) {
    static if(is(U == shared V, V))
        alias Unqual = V;
    else
        alias Unqual = U;
}

/**
    Safely casts between `T` and `U`.
*/
T dynamic_cast(T, U)(auto ref U from) if(is(T : U)) {
    return cast(T)from;
}

/**
    Allows casting one type to another given that the types have the same
    size, reinterpreting the data.

    This will NOT call opCast of aggregate types!
*/
pragma(inline, true)
T reinterpret_cast(T, U)(auto ref U from) if (T.sizeof == U.sizeof) {
    union tmp { U from; T to; }
    return tmp(from).to;
}

@("reinterpret_cast: opCast")
unittest {
    import numem.core.memory;
    static
    class Test {
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

    Test a = nogc_new!Test();
    assert(cast(int)a == 42);
    assert(cast(void*)a);
    assert(cast(Object)a);
}

/**
    Allows casting between qualified versions of the input type.
    The unqualified version of the types need to be implicitly 
    convertible in at least one direction.

    Example
    ```d
        const(char)* myString = "Hello, world!";
        char* myStringMut = const_cast!(char*)(myString);
    ```
*/
pragma(inline, true)
T const_cast(T, U)(auto ref U from) if (is(Unqual!T : Unqual!U) || is(Unqual!U : Unqual!T)) {
    return reinterpret_cast!(T, U)(from);
}

@("const_cast: const to non-const")
unittest {
    const(char)* myString = "Hello, world!";
    char* myStringMut = const_cast!(char*)(myString);
    myString = const_cast!(const(char)*)(myStringMut);
}