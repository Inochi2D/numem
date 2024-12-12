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

@nogc nothrow:

/**
    Allocates `bytes` worth of memory.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib alloc.
*/
@weak
extern(C)
void* nuAlloc(size_t bytes) {
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
extern(C)
void* nuRealloc(void* data, size_t newSize) {
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
extern(C)
void nuFree(void* data) {
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
extern(C)
void* nuMemcpy(inout(void)* dst, inout(void)* src, size_t bytes) {
    import core.stdc.string : memcpy;
    return memcpy(cast(void*)dst, cast(void*)src, bytes);
}

/**
    Moves `bytes` worth of data from `src` into `dst`.
    Memory needs to be allocated and within range.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib memmove.
*/
@weak
extern(C)
void* nuMemmove(void* dst, void* src, size_t bytes) {
    import core.stdc.string : memmove;
    return memmove(dst, src, bytes);
}

/**
    Fills `dst` with `value` for `bytes` bytes.
    
    NOTE: External libraries may override this
    implementation.
    
    By default calls C stdlib memset.
*/
void* nuMemset(void* dst, ubyte value, size_t bytes) {
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
extern(C)
void nuAbort() {
    import core.stdc.stdlib : abort;
    abort();
}