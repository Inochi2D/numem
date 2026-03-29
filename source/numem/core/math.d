/**
    Numem math helpers.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.math;

/**
    Aligns the given value up to the given alignment.

    Params:
        value =     The value to align, in bytes.
        alignment = The byte alignment, in bytes.
    
    Returns:
        The value aligned to the given alignment.
*/
pragma(inline, true)
T nu_alignup(T)(T value, T alignment) @nogc if (__traits(isIntegral, T)) {
    return alignment > 0 ? value + (alignment - (value % alignment)) : value;
}

/**
    Aligns the given value down the given alignment.

    Params:
        value =     The value to align, in bytes.
        alignment = The byte alignment, in bytes.
    
    Returns:
        The value aligned to the given alignment.
*/
pragma(inline, true)
T nu_aligndown(T)(T value, T alignment) @nogc if (__traits(isIntegral, T)) {
    return alignment > 0 ? value - (value % alignment) : value;
}

/**
    Gets whether $(D value) is aligned to $(D alignment)

    Params:
        value =     Value to check
        alignment = The alignment to compare the pointer to.

    Returns:
        Whether $(D value) is aligned to $(D alignment) 
*/
bool nu_is_aligned(T)(T value, size_t alignment) nothrow @nogc @trusted pure {
    return (cast(size_t)value & (alignment-1)) == 0;
}

/**
    Gets the lowest value between $(D a) and $(D b)

    Params:
        a = The first parameter
        b = The second parameter

    Returns:
        The lowest value of the 2 given.
*/
auto ref T nu_min(T)(auto ref T a, auto ref T b) @nogc nothrow @trusted pure if (is(typeof(() => T.init < T.init))) {
    return (a < b) ? a : b;
}

/**
    Gets the largest value between $(D a) and $(D b)

    Params:
        a = The first parameter
        b = The second parameter

    Returns:
        The largest value of the 2 given.
*/
auto ref T nu_max(T)(auto ref T a, auto ref T b) @nogc nothrow @trusted pure if (is(typeof(() => T.init > T.init))) {
    return (a > b) ? a : b;
}

/**
    Scans the bits in the provided value from the most
    significant bit to the least significant bit, getting
    the offset of the first set bit.

    Params:
        value = The value to scan
    
    Returns:
        The index of the first bit set, value is undefined
        if value is zero.
*/
T nu_bsr(T)(T value) @nogc nothrow @trusted pure
if (__traits(isIntegral, T)) {
    version(LDC) {
        import ldc.intrinsics : llvm_ctlz;
        return cast(int)(value.sizeof * 8 - 1 - llvm_ctlz(value, true));
    } else {
        
        // Slow software implementation.
        uint offset = 0;
        T mask = cast(T)~(T.max >>> 1);
        foreach(i; 0..T.sizeof*8) {
            if (value & mask)
                break;
            
            offset++;
            mask >>>= 1;
        }

        return offset;
    }
}

/**
    Scans the bits in the provided value from the least
    significant bit to the most significant bit, getting
    the offset of the first set bit.

    Params:
        value = The value to scan
    
    Returns:
        The index of the first bit set, value is undefined
        if value is zero.
*/
T nu_bsf(T)(T value) @nogc nothrow @trusted pure
if (__traits(isIntegral, T)) {
    version(LDC) {
        import ldc.intrinsics : llvm_cttz;
        return cast(int)(value.sizeof * 8 - 1 - llvm_cttz(value, true));
    } else {
        
        // Slow software implementation.
        uint offset = 0;
        T mask = 1;
        foreach(i; 0..T.sizeof*8) {
            if (value & mask)
                break;
            
            offset++;
            mask <<= 1;
        }

        return offset;
    }
}