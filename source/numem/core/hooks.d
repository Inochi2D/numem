/**
    Numem Core Hooks.

    This file contains all the core hooks numem calls internally to handle memory.
    Given that some platforms may not have a C standard library, these hooks allow you
    to override how numem handles memory for such platforms from an external library.

    In this case, most of the hooks presented here will need to be implemented to cover
    all of the used internal hooks within numem.

    Hooks which are prefixed $(D nuopt_) are optional and may be omitted, they are
    usually for language-specific interoperability.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.hooks;
import core.attribute : weak;

/**
    Allocates $(D bytes) worth of memory.

    Params:
        bytes = How many bytes to allocate.
    
    Returns:
        Newly allocated memory or $(D null) on failure.
        To avoid a memory leak, free the memory with $(D nu_free).
    
    Notes:
        Given the implementation of $(D nu_malloc) and $(D nu_free) may be
        independent of the libc allocator, memory allocated with
        $(D nu_malloc) should $(B always) be freed with $(D nu_free)!
*/
export
extern(C)
void* nu_malloc(size_t bytes) @nogc nothrow @system pure @weak {
    pragma(mangle, "malloc")
    static extern extern(C) void* malloc(size_t) @nogc nothrow @system pure;

    return malloc(bytes);
}

/**
    Reallocates memory prior allocated with $(D nu_malloc) or
    $(D nu_alignedalloc).

    This function may re-allocate the memory if resizing the allocation
    to the new size is not possible.

    Params:
        data    = Pointer to prior allocated memory.
        newSize = New size of the allocation, in bytes.

    Returns:
        The address of the reallocated memory or $(D null) on failure.
        To avoid a memory leak, free the memory with $(D nu_free).
    
    Notes:
        Given the implementation of $(D nu_realloc) and $(D nu_free) may be
        independent of the libc allocator, memory allocated with
        $(D nu_realloc) should $(B always) be freed with $(D nu_free)!
*/
export
extern(C)
void* nu_realloc(void* data, size_t newSize) @nogc nothrow @system pure @weak {
    pragma(mangle, "realloc")
    static extern extern(C) void* realloc(void*, size_t) @nogc nothrow @system pure;

    return realloc(data, newSize);
}

/**
    Frees allocated memory.

    Params:
        data = Pointer to start of memory prior allocated.

    Notes:
        Given the implementation of the allocators and $(D nu_free) may be
        independent of the libc allocator, memory allocated with
        numem functions should $(B always) be freed with $(D nu_free)!
*/
export
extern(C)
void nu_free(void* data) @nogc nothrow @system pure @weak {
    pragma(mangle, "free")
    static extern extern(C) void free(void*) @nogc nothrow @system pure;

    return free(data);
}

/**
    Copies $(D bytes) worth of data from $(D src) into $(D dst).
    
    $(D src) and $(D dst) needs to be allocated and within range,
    additionally the source and destination may not overlap.

    Params:
        dst =   Destination of the memory copy operation.
        src =   Source of the memory copy operation
        bytes = The amount of bytes to copy.
*/
export
extern(C)
void* nu_memcpy(return scope void* dst, scope const void* src, size_t bytes) @nogc nothrow @system pure @weak {
    pragma(mangle, "memcpy")
    static extern extern(C) void* memcpy(return scope void*, scope const void*, size_t) @nogc nothrow @system pure;

    return memcpy(dst, src, bytes);
}

/**
    Moves $(D bytes) worth of data from $(D src) into $(D dst).
    
    $(D src) and $(D dst) needs to be allocated and within range.

    Params:
        dst =   Destination of the memory copy operation.
        src =   Source of the memory copy operation
        bytes = The amount of bytes to copy.
    
    Returns:
        Pointer to $(D dst)
*/
export
extern(C)
void* nu_memmove(return scope void* dst, scope const void* src, size_t bytes) @nogc nothrow @system pure @weak {
    pragma(mangle, "memmove")
    static extern extern(C) void* memmove(return scope void*, scope const void*, size_t) @nogc nothrow @system pure;

    return memmove(dst, src, bytes);
}

/**
    Fills $(D dst) with $(D bytes) amount of $(D value)s.

    Params:
        dst =   Destination of the memory copy operation.
        value = The byte to repeatedly copy to the memory starting at $(D dst)
        bytes = The amount of bytes to write.
    
    Returns:
        Pointer to $(D dst)
*/
export
extern(C)
void* nu_memset(return scope void* dst, ubyte value, size_t bytes) @nogc nothrow @system pure @weak {
    pragma(mangle, "memset")
    static extern extern(C) void* memset(return scope void*, int, size_t) @nogc nothrow @system pure;

    return memset(dst, value, bytes);
}

/**
    Called internally by numem if a fatal error occured.

    This function $(B should) exit the application and if possible,
    print an error. But it $(B may) not print an error.

    Params:
        errMsg = A D string containing the error in question.
    
    Returns:
        Never returns, the application should crash at this point.
*/
export
extern(C)
void nu_fatal(const(char)[] errMsg) @nogc nothrow @system pure @weak {
    pragma(mangle, "printf")
    static extern extern(C) void printf(const(char)*, ...) @nogc nothrow @system pure;
    pragma(mangle, "abort")
    static extern extern(C) void abort() @nogc nothrow @system pure;

    printf("%.*s", cast(int)errMsg.length, errMsg.ptr);
    abort();
}

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
bool nu_atomic_supported() @nogc nothrow @system pure @weak {
    version(LDC) {
        return true;
    } else return false;
}

/**
    Inserts a memory acquire barrier.
*/
export
extern(C)
void nu_atomic_barrier_acquire() @nogc nothrow @system pure @weak {
    version(LDC) {
        import ldc.intrinsics;    
        llvm_memory_fence(AtomicOrdering.Acquire, SynchronizationScope.CrossThread);
    }
}

/**
    Inserts a memory release barrier.
*/
export
extern(C)
void nu_atomic_barrier_release() @nogc nothrow @system pure @weak {
    version(LDC) {
        import ldc.intrinsics;    
        llvm_memory_fence(AtomicOrdering.Release, SynchronizationScope.CrossThread);
    }
}

/**
    Loads a 32 bit value atomically.
*/
export
extern(C)
inout(uint) nu_atomic_load_32(ref inout(uint) src) @nogc nothrow @system pure @weak {
    version(LDC) {
        import ldc.intrinsics;    
        return llvm_atomic_load!(inout(uint))(cast(shared(inout(uint)*))&src);
    } else return src;
}

/**
    Stores a 32 bit value atomically.
*/
export
extern(C)
void nu_atomic_store_32(ref uint dst, uint value) @nogc nothrow @system pure @weak {
    version(LDC) {
        import ldc.intrinsics;    
        llvm_atomic_store!(uint)(value, cast(shared(uint*))&dst);
    } else {
        dst = value;
    }
}

/**
    Adds a 32 bit value atomically.
*/
export
extern(C)
extern uint nu_atomic_add_32(ref uint dst, uint value) @nogc nothrow @system pure @weak {
    version(LDC) {
        
        import ldc.intrinsics;    
        return llvm_atomic_rmw_add!(uint)(cast(shared(uint*))&dst, value);
    } else {
        uint oldval = dst;
        dst += value;
        return oldval;
    }
}

/**
    Subtracts a 32 bit value atomically.
*/
export
extern(C)
extern uint nu_atomic_sub_32(ref uint dst, uint value) @nogc nothrow @system pure @weak {
    version(LDC) {
        
        import ldc.intrinsics;    
        return llvm_atomic_rmw_sub!(uint)(cast(shared(uint*))&dst, value);
    } else {
        uint oldval = dst;
        dst -= value;
        return oldval;
    }
}

/**
    Loads a pointer value atomically.
*/
export
extern(C)
extern inout(void)* nu_atomic_load_ptr(inout(void)** src) @nogc nothrow @system pure @weak {
    version(LDC) {
        
        import ldc.intrinsics;    
        return llvm_atomic_load!(inout(void)*)(cast(shared(inout(void)**))src);
    } else {
        return *src;
    }
}

/**
    Stores a pointer value atomically.
*/
export
extern(C)
extern void nu_atomic_store_ptr(void** dst, void* value) @nogc nothrow @system pure @weak {
    version(LDC) {
        
        import ldc.intrinsics;    
        llvm_atomic_store!(void*)(value, cast(shared(void**))dst);
    } else {
        *dst = value;
    }
}

/**
    Compares variable at $(D dst) and swaps it if it contains $(D oldvalue).
*/
export
extern(C)
extern bool nu_atomic_cmpxhg_ptr(void** dst, void* oldvalue, void* value) @nogc nothrow @system pure @weak {
    version(LDC) {
        
        import ldc.intrinsics;
        return llvm_atomic_cmp_xchg!(void*)(cast(shared(void**))dst, oldvalue, value).exchanged;
    } else {
        if (*dst is oldvalue) {
            *dst = value;
            return true;
        }

        return false;
    }
}

/**
    Hooks for handling auto release pools.

    These $(I optional) pool callback functions allows implementers of
    numem to hook into the auto release pool system.

    Push should push a new context onto an internal stack, while pop should
    release an element from the stack.

    These functions are mainly useful for Objective-C interoperability.

    See_Also:
        $(LINK2 https://clang.llvm.org/docs/AutomaticReferenceCounting.html#autoreleasepool, ARC Documentation)
*/
extern(C)
__gshared void* function() @nogc nothrow @system nuopt_autoreleasepool_push = null;

/// ditto
extern(C)
__gshared void function(void*) @nogc nothrow @system nuopt_autoreleasepool_pop = null;