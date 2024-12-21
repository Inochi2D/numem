/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Numem math functions.
*/
module numem.math;

public import numem.core.bitop;

nothrow @nogc:

/**
    Returns the larger of the 2 given scalar values.
*/
T max(T)(T lhs, T rhs) if (__traits(isScalar, T)) {
    return lhs > rhs ? lhs : rhs;
}

/**
    Returns the smaller of the 2 given scalar values.
*/
T min(T)(T lhs, T rhs) if (__traits(isScalar, T)) {
    return lhs < rhs ? lhs : rhs;
}

/**
    Clamps scalar value into the given range.
*/
T clamp(T)(T value, T min_, T max_) if (__traits(isScalar, T))  {
    return min(max(value, min_), max_);
}