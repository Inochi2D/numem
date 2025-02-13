/**
    Atomics Hooks
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.atomic;

// Allow disabling atomics.
// This replaces atomics operations with dummies that are non-atomic.
// much like hookset-libc does when it can't find an implementation.
version(NUMEM_NO_ATOMICS) {
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
} else:

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