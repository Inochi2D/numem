/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.internal;

const(T)[] fromStringz(T)(return scope const(T)* cString) @nogc @system pure nothrow {
    import core.stdc.string: strlen;

    static if (is(T == char))
        import core.stdc.string : cstrlen = strlen;
    else static if (is(T == wchar) || is(T == dchar)) {
        static size_t cstrlen(scope const T* s) {
            const(T)* p = s;
            while (*p)
                ++p;
            return p - s;
        }
    }
    else
        static assert(0);

    return cString ? cString[0 .. cstrlen(cString)] : null;
}