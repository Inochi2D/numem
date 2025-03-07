/**
    LDC atomic intrinsics.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:    Luna Nielsen
*/
module atomic.ldc;
version(LDC):

import ldc.intrinsics;

//
//  HOOK IMPLEMENTATION.
//

extern(C)
export
bool nu_atomic_supported() @nogc nothrow {
    return true;
}

/**
    Inserts a memory acquire barrier.
*/
extern(C)
export
void nu_atomic_barrier_acquire() @nogc nothrow {
    llvm_memory_fence(AtomicOrdering.Acquire, SynchronizationScope.CrossThread);
}

/**
    Inserts a memory release barrier.
*/
extern(C)
export
void nu_atomic_barrier_release() @nogc nothrow {
    llvm_memory_fence(AtomicOrdering.Release, SynchronizationScope.CrossThread);
}

/**
    Loads a 32 bit value atomically.
*/
extern(C)
export
inout(uint) nu_atomic_load_32(ref inout(uint) src) @nogc nothrow {
    return llvm_atomic_load!(inout(uint))(cast(shared(inout(uint)*))&src);
}

/**
    Stores a 32 bit value atomically.
*/
extern(C)
export
void nu_atomic_store_32(ref uint dst, uint value) @nogc nothrow {
    llvm_atomic_store!(uint)(value, cast(shared(uint*))&dst);
}

/**
    Adds a 32 bit value atomically.
*/
extern(C)
export
uint nu_atomic_add_32(ref uint dst, uint value) @nogc nothrow {
    return llvm_atomic_rmw_add!(uint)(cast(shared(uint*))&dst, value);
}

/**
    Subtracts a 32 bit value atomically.
*/
extern(C)
export
uint nu_atomic_sub_32(ref uint dst, uint value) @nogc nothrow {
    return llvm_atomic_rmw_sub!(uint)(cast(shared(uint*))&dst, value);
}

/**
    Loads a pointer value atomically.
*/
extern(C)
export
inout(void)* nu_atomic_load_ptr(inout(void)** src) @nogc nothrow {
    return llvm_atomic_load!(inout(void)*)(cast(shared(inout(void)**))src);
}

/**
    Stores a pointer value atomically.
*/
extern(C)
export
void nu_atomic_store_ptr(void** dst, void* value) @nogc nothrow {
    llvm_atomic_store!(void*)(value, cast(shared(void**))dst);
}

/**
    Compares variable at $(D dst) and swaps it if it contains $(D oldvalue).
*/
extern(C)
export
bool nu_atomic_cmpxhg_ptr(void** dst, void* oldvalue, void* value) @nogc nothrow {
    return llvm_atomic_cmp_xchg!(void*)(cast(shared(void**))dst, oldvalue, value).exchanged;
}