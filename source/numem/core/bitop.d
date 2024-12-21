/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Numem bit operation functions.
*/
module numem.core.bitop;
import numem.core.traits;
import numem.core.casting;

/**
    Inverts the binary representation of T.
*/
pragma(inline, true)
T invert(T)(T value) if (__traits(isScalar, T)) {
    return value ^ T.max;
}

pragma(inline, true)
ref auto T toBits(T)(ref auto T t) if (isIntegral!T) {
    return t;
}

pragma(inline, true)
ref auto FtoI!T toBits(T)(ref auto T t) if (is(T == double)) {
    return reinterpret_cast!(FtoI!T)(t);
}

/**
    Scans bits in reverse, looking for the first bit which is set.
*/
FtoI!T bsr(T)(inout(T) v) pure if (isNumeric!T) {
    alias FT = FtoI!T;

    import core.bitop : bsr;
    version(LDC) {
        if (!__ctfe) {
            import core.builtins : llvm_ctlz;
            return llvm_ctlz!FT(v.toBits!T);
        } else
            pragma(inline, false);
    } else
        static assert(0, "Not implemented yet, sorry.");
}