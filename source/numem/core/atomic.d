module numem.core.atomic;
import numem.core.attributes : weak;

extern(C):

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
extern bool nu_atomic_supported() @nogc nothrow;

/**
    Inserts a memory acquire barrier.
*/
extern void nu_atomic_barrier_acquire() @nogc nothrow;

/**
    Inserts a memory release barrier.
*/
extern void nu_atomic_barrier_release() @nogc nothrow;

/**
    Loads a 32 bit value atomically.
*/
extern inout(uint) nu_atomic_load_32(ref inout(uint) src) @nogc nothrow;

/**
    Stores a 32 bit value atomically.
*/
extern void nu_atomic_store_32(ref uint dst, uint value) @nogc nothrow;

/**
    Adds a 32 bit value atomically.
*/
extern uint nu_atomic_add_32(ref uint dst, uint value) @nogc nothrow;

/**
    Subtracts a 32 bit value atomically.
*/
extern uint nu_atomic_sub_32(ref uint dst, uint value) @nogc nothrow;

/**
    Loads a pointer value atomically.
*/
extern inout(void)* nu_atomic_load_ptr(inout(void)** src) @nogc nothrow;

/**
    Stores a pointer value atomically.
*/
extern void nu_atomic_store_ptr(void** dst, void* value) @nogc nothrow;

/**
    Compares variable at $(D dst) and swaps it if it contains $(D oldvalue).
*/
extern bool nu_atomic_cmpxhg_ptr(void** dst, void* oldvalue, void* value) @nogc nothrow;