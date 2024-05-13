module numem.mem.utils;
import std.traits;

// Based on code from dplug:core
// which is released under the Boost license.

/**
    Forces a function to assume that it's nogc compatible.
*/
auto assumeNoGC(T) (T t) {
    static if (isFunctionPointer!T || isDelegate!T) {
        enum attrs = functionAttributes!T | FunctionAttribute.nogc;
        return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
    } else static assert(false);
}

/**
    Forces a function to assume that it's nothrow nogc compatible.
*/
auto assumeNothrowNoGC(T) (T t) {
    static if (isFunctionPointer!T || isDelegate!T) {
        enum attrs = functionAttributes!T | FunctionAttribute.nogc | FunctionAttribute.nothrow_;
        return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
    } else static assert(false);
}