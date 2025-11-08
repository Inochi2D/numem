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