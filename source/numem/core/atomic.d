module numem.core.atomic;
import numem.core.attributes : weak;

@weak export:

/**
    Gets the status of atomics support in the current
    numem configuration.

    Notes:
        If atomics are not supported, these functions will
        act as non-atomic alternatives.

    Returns:
        Whether atomics are supported by the loaded
        hookset.
*/
extern(C)
bool nu_atomic_supported() @nogc nothrow {
    return false;
}

/**
    Inserts a memory acquire barrier.
*/
extern(C)
void nu_atomic_barrier_acquire() @nogc nothrow {
    return;
}

/**
    Inserts a memory release barrier.
*/
extern(C)
void nu_atomic_barrier_release() @nogc nothrow {
    return;
}

/**
    Loads a 32 bit value atomically.
*/
extern(C)
inout(uint) nu_atomic_load_32(ref inout(uint) src) @nogc nothrow {
    return src;
}

/**
    Stores a 32 bit value atomically.
*/
extern(C)
void nu_atomic_store_32(ref uint dst, uint value) @nogc nothrow {
    dst = value;
}

/**
    Adds a 32 bit value atomically.
*/
extern(C)
extern uint nu_atomic_add_32(ref uint dst, uint value) @nogc nothrow {
    uint oldval = dst;
    dst += value;
    return oldval;
}

/**
    Subtracts a 32 bit value atomically.
*/
extern(C)
extern uint nu_atomic_sub_32(ref uint dst, uint value) @nogc nothrow {
    uint oldval = dst;
    dst -= value;
    return oldval;
}

/**
    Loads a pointer value atomically.
*/
extern(C)
extern inout(void)* nu_atomic_load_ptr(inout(void)** src) @nogc nothrow {
    return *src;
}

/**
    Stores a pointer value atomically.
*/
extern(C)
extern void nu_atomic_store_ptr(void** dst, void* value) @nogc nothrow {
    *dst = value;
}

/**
    Compares variable at $(D dst) and swaps it if it contains $(D oldvalue).
*/
extern(C)
extern bool nu_atomic_cmpxhg_ptr(void** dst, void* oldvalue, void* value) @nogc nothrow {
    if (*dst is oldvalue) {
        *dst = value;
        return true;
    }

    return false;
}