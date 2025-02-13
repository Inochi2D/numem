/**
    Numem casting helpers
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.casting;
import numem.core.traits;

nothrow @nogc:

/**
    Safely casts between $(D T) and $(D U).
*/
auto ref T dynamic_cast(T, U)(auto ref U from) @trusted if(is(T : U)) {
    return cast(T)from;
}

/**
    Allows casting one type to another given that the types have the same
    size, reinterpreting the data.

    This will NOT call opCast of aggregate types!
*/
pragma(inline, true)
auto ref T reinterpret_cast(T, U)(auto ref U from) @trusted if (T.sizeof == U.sizeof) {
    union tmp { U from; T to; }
    return tmp(from).to;
}

/**
    Allows casting between qualified versions of the input type.
    The unqualified version of the types need to be implicitly 
    convertible in at least one direction.

    Example:
        $(D_CODE
            const(char)* myString = "Hello, world!";
            char* myStringMut = const_cast!(char*)(myString);
        )
*/
pragma(inline, true)
auto ref T const_cast(T, U)(auto ref U from) @trusted if (isAnyCompatible!(T, U)) {
    return reinterpret_cast!(T, U)(from);
}