/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.core.utils;
import std.traits;

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