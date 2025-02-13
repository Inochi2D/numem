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


@nogc nothrow:

enum AtomicOrdering {
    NotAtomic = 0,
    Unordered = 1,
    Monotonic = 2,
    Consume = 3,
    Acquire = 4,
    Release = 5,
    AcquireRelease = 6,
    SequentiallyConsistent = 7
}
alias DefaultOrdering = AtomicOrdering.SequentiallyConsistent;

enum SynchronizationScope {
    SingleThread = 0,
    CrossThread  = 1,
    Default = CrossThread
}

enum AtomicRmwSizeLimit = size_t.sizeof;

/// Used to introduce happens-before edges between operations.
pragma(LDC_fence)
    void llvm_memory_fence(AtomicOrdering ordering = DefaultOrdering,
                        SynchronizationScope syncScope = SynchronizationScope.Default);

/// Atomically loads and returns a value from memory at ptr.
pragma(LDC_atomic_load)
    T llvm_atomic_load(T)(in shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

/// Atomically stores val in memory at ptr.
pragma(LDC_atomic_store)
    void llvm_atomic_store(T)(T val, shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

///
struct CmpXchgResult(T) {
    T previousValue; ///
    bool exchanged; ///
}

/// Loads a value from memory at ptr and compares it to cmp.
/// If they are equal, it stores val in memory at ptr.
/// This is all performed as single atomic operation.
pragma(LDC_atomic_cmp_xchg)
    CmpXchgResult!T llvm_atomic_cmp_xchg(T)(
        shared T* ptr, T cmp, T val,
        AtomicOrdering successOrdering = DefaultOrdering,
        AtomicOrdering failureOrdering = DefaultOrdering,
        bool weak = false);

/// Atomically sets *ptr = val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "xchg")
    T llvm_atomic_rmw_xchg(T)(shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr += val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "add")
    T llvm_atomic_rmw_add(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr -= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "sub")
    T llvm_atomic_rmw_sub(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr &= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "and")
    T llvm_atomic_rmw_and(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = ~(*ptr & val) and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "nand")
    T llvm_atomic_rmw_nand(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr |= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "or")
    T llvm_atomic_rmw_or(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr ^= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "xor")
    T llvm_atomic_rmw_xor(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr > val ? *ptr : val) using a signed comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "max")
    T llvm_atomic_rmw_max(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr < val ? *ptr : val) using a signed comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "min")
    T llvm_atomic_rmw_min(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr > val ? *ptr : val) using an unsigned comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "umax")
    T llvm_atomic_rmw_umax(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr < val ? *ptr : val) using an unsigned comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "umin")
    T llvm_atomic_rmw_umin(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);