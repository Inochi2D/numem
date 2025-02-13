module atomic.dummy;
import atomic;

static if (ATOMIC_USE_DUMMY):

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
export
extern(C)
bool nu_atomic_supported() @nogc nothrow {
    return false;
}

/**
    Inserts a memory acquire barrier.
*/
export
extern(C)
void nu_atomic_barrier_acquire() @nogc nothrow {
    return;
}

/**
    Inserts a memory release barrier.
*/
export
extern(C)
void nu_atomic_barrier_release() @nogc nothrow {
    return;
}

/**
    Loads a 32 bit value atomically.
*/
export
extern(C)
inout(uint) nu_atomic_load_32(ref inout(uint) src) @nogc nothrow {
    return src;
}

/**
    Stores a 32 bit value atomically.
*/
export
extern(C)
void nu_atomic_store_32(ref uint dst, uint value) @nogc nothrow {
    dst = value;
}

/**
    Adds a 32 bit value atomically.
*/
export
extern(C)
extern uint nu_atomic_add_32(ref uint dst, uint value) @nogc nothrow {
    uint oldval = dst;
    dst += value;
    return oldval;
}

/**
    Subtracts a 32 bit value atomically.
*/
export
extern(C)
extern uint nu_atomic_sub_32(ref uint dst, uint value) @nogc nothrow {
    uint oldval = dst;
    dst -= value;
    return oldval;
}

/**
    Loads a pointer value atomically.
*/
export
extern(C)
extern inout(void)* nu_atomic_load_ptr(inout(void)** src) @nogc nothrow {
    return *src;
}

/**
    Stores a pointer value atomically.
*/
export
extern(C)
extern void nu_atomic_store_ptr(void** dst, void* value) @nogc nothrow {
    *dst = value;
}

/**
    Compares variable at $(D dst) and swaps it if it contains $(D oldvalue).
*/
export
extern(C)
extern bool nu_atomic_cmpxhg_ptr(void** dst, void* oldvalue, void* value) @nogc nothrow {
    if (*dst is oldvalue) {
        *dst = value;
        return true;
    }

    return false;
}