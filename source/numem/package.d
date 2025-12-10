/**
    Numem
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem;

public import numem.core.exception;
public import numem.core.hooks;
public import numem.core.math;
public import numem.casting;
public import numem.lifetime;
public import numem.object;
public import numem.optional;

/**
    Container for numem version.
*/
struct nu_version {
@nogc:
public:
    uint major;     /// Major
    uint minor;     /// Minor
    uint patch;     /// Patch
}

/**
    Numem version
*/
private
const __gshared nu_version __nu_version = nu_version(1, 0, 0);

/**
    Gets the current version of numem.

    Returns:
        The current version of numem as 3 tightly packed 32-bit
        unsigned integers.
*/
export
extern(C)
nu_version nu_get_version() @nogc nothrow @safe pure {
    return __nu_version;
}