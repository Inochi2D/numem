/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Numem Hooks.

    This file contains all the core hooks numem calls internally to handle memory.
    Given that some platforms may not have a C standard library, these hooks allow you
    to override how numem handles memory for such platforms from an external library.

    In this case, all of the hooks presented here will need to be implemented to cover
    all of the used internal hooks within numem.

    Various extra hooks are provided in other files throughout numem, but are optional.
*/
module numem.core.hooks;
public import core.attribute : weak;
import numem.core.utils;

/**
    Allocates `bytes` worth of memory.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib alloc.
*/
@weak
export
extern(C)
void* nuAlloc(size_t bytes) @nogc nothrow {

    import core.stdc.stdlib : malloc;
    return malloc(bytes);
}

/**
    Reallocates memory at `data` to be `bytes` worth of memory.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib realloc.
*/
@weak
export
extern(C)
void* nuRealloc(void* data, size_t newSize) @nogc nothrow {

    import core.stdc.stdlib : realloc;
    return realloc(data, newSize);
}

/**
    Frees the memory at `data`.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib alloc.
*/
@weak
export
extern(C)
void nuFree(void* data) @nogc nothrow {

    import core.stdc.stdlib : free;
    free(data);
}

/**
    Copies `bytes` worth of data from `src` into `dst`.
    Memory needs to be allocated and within range.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib memcpy.
*/
@weak
export
extern(C)
void* nuMemcpy(return scope void* dst, return scope void* src, size_t bytes) @nogc nothrow {

    import core.stdc.string : memcpy;
    return memcpy(dst, src, bytes);
}

/**
    Copies `bytes` worth of data from `src` into `dst`.
    Memory needs to be allocated and within range.

    This calls `nuMemcpy(inout(void)* dst, inout(void)* src, size_t bytes)`
    internally.
*/
extern(D)
void* nuCopy(T)(inout(T)[] dst, inout(T)[] src) @nogc nothrow {

    assert(dst.length >= src.length, "Destination is shorter than source!");
    return nuMemcpy(dst.ptr, src.ptr, T.sizeof*src.length);
}

/**
    Moves `bytes` worth of data from `src` into `dst`.
    Memory needs to be allocated and within range.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib memmove.
*/
@weak
export
extern(C)
void* nuMemmove(void* dst, void* src, size_t bytes) @nogc nothrow {

    import core.stdc.string : memmove;
    return memmove(dst, src, bytes);
}

/**
    Fills `dst` with `value` for `bytes` bytes.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib memset.
*/
extern(C)
export
void* nuMemset(void* dst, ubyte value, size_t bytes) @nogc nothrow {

    import core.stdc.string : memset;
    return memset(dst, value, bytes);
}

/**
    Hook which forcefully quits or crashes the application due to an invalid state.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib abort.
*/
@weak
export
extern(C)
void nuAbort() @nogc nothrow {

    import core.stdc.stdlib : abort;
    abort();
}