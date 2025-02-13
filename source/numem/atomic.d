/**
    Atomic memory operations.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:    Luna Nielsen

    Standards:
        $(LINK https://llvm.org/docs/Atomics.html#atomic-orderings)
*/
module numem.atomic;
import numem.core.traits;
import numem.core.intrinsics;

/**
    Different levels of atomicity that are exposed by numem.
*/
enum MemoryOrder {
    
    /**
        The weakest level of atomicity that can be used in synchronization primitives, although 
        it does not provide any general synchronization.

        It essentially guarantees that if you take all the operations affecting a specific 
        address, a consistent ordering exists.
    
        Standards:
            This corresponds to the C++/C memory_order_relaxed; 
            see those standards for the exact definition.

    */
    relaxed,
    
    /**
        Acquire provides a barrier of the sort necessary to acquire a lock to access other 
        memory with normal loads and stores.
    
        Standards:
            This corresponds to the C++/C memory_order_acquire.
            It should also be used for C++/C memory_order_consume.
    */
    acquire,
    
    /**
        Release is similar to Acquire, but with a barrier of the sort necessary to release a lock.
    
        Standards:
            This corresponds to the C++/C memory_order_release.
    */
    release,
    
    /**
        Provides both an Acquire and a Release barrier (for fences and operations which both 
        read and write memory).
    
        Standards:
            This corresponds to the C++/C memory_order_acq_rel.
    */
    acquireRelease,
    
    /**
        Provides Acquire semantics for loads and Release semantics for stores.

        Additionally, it guarantees that a total ordering exists between all SequentiallyConsistent operations.
    
        Standards:
            This corresponds to the C++/C memory_order_seq_cst, Java volatile, 
            and the gcc-compatible __sync_* builtins which do not specify otherwise.
    */
    sequential
}

version(LDC) {
    private
    template llvm_atomic_ordering(MemoryOrder ms) {
        static if (ms == MemoryOrder.acq)
            enum llvm_atomic_ordering = AtomicOrdering.Acquire;
        else static if (ms == MemoryOrder.rel)
            enum llvm_atomic_ordering = AtomicOrdering.Release;
        else static if (ms == MemoryOrder.acq_rel)
            enum llvm_atomic_ordering = AtomicOrdering.AcquireRelease;
        else static if (ms == MemoryOrder.seq)
            enum llvm_atomic_ordering = AtomicOrdering.SequentiallyConsistent;
        else static if (ms == MemoryOrder.raw)
        {
            // Note that C/C++ 'relaxed' is not the same as NoAtomic/Unordered,
            // but Monotonic.
            enum llvm_atomic_ordering = AtomicOrdering.Monotonic;
        }
        else
            static assert(0);
    }
}

/**
    Gets the underlying atomic type for type $(D T)
*/
template getAtomicType(T) {
    static if (isPointer!T)
        alias getAtomicType = void*;
    else static if (T.sizeof == ubyte.sizeof)
        alias getAtomicType = ubyte;
    else static if (T.sizeof == ushort.sizeof)
        alias getAtomicType = ushort;
    else static if (T.sizeof == uint.sizeof)
        alias getAtomicType = uint;
    else static if (T.sizeof == ulong.sizeof)
        alias getAtomicType = ulong;
    else
        static assert(false, "Cannot atomically load/store type of size " ~ T.sizeof.stringof);
}

/**
    Loads $(D src) atomically with the specified memory ordering.
*/
inout(T) atomicLoad(MemoryOrder order = MemoryOrder.sequential, T)(ref inout(T) src) pure nothrow @nogc @trusted {
    static assert(order != MemoryOrder.rel && order != MemoryOrder.acq_rel,
                "invalid MemoryOrder for atomicLoad()");

    alias A = getAtomicType!T;

    version(LDC) {
        A result = llvm_atomic_load!A(cast(shared A*) src, llvm_atomic_ordering!(order));
        return *cast(inout(T)*) &result;
    } else {
        assert(0, "Not implemented!");
    }
}

/**
    Stores $(D value) into $(D dst) atomically with the specified memory ordering.
*/
void atomicStore(MemoryOrder order = MemoryOrder.sequential, T)(ref T dst, T value) pure nothrow @nogc @trusted {
    static assert(order != MemoryOrder.acq && order != MemoryOrder.acq_rel,
                "Invalid MemoryOrder for atomicStore()");

    alias A = getAtomicType!T;

    version(LDC) {
        llvm_atomic_store!A(*cast(A*) &value, cast(shared A*) dst, llvm_atomic_ordering!(order));
    } else {
        assert(0, "Not implemented!");
    }
}

/**
    Fetches $(D dst) and adds $(D value) to it atomically.
*/
T atomicFetchAdd(MemoryOrder order = MemoryOrder.seq, T)(ref T dst, T value) pure nothrow @nogc @trusted
if (is(T : ulong)) {
    alias A = getAtomicType!T;

    version(LDC) {
        return llvm_atomic_rmw_add!A(cast(shared A*) dst, value, llvm_atomic_ordering!(order));
    } else {
        assert(0, "Not implemented!");
    }

    
}

/**
    Fetches $(D dst) and subtracts $(D value) from it atomically.
*/
T atomicFetchSub(MemoryOrder order = MemoryOrder.seq, T)(ref T dst, T value) pure nothrow @nogc @trusted
if (is(T : ulong)) {
    alias A = getAtomicType!T;

    version(LDC) {
        return llvm_atomic_rmw_sub!A(cast(shared A*) dst, value, llvm_atomic_ordering!(order));
    } else {
        assert(0, "Not implemented!");
    }
}

/**
    Exchanges $(D value) with $(D dst).

    Params:
        dst =   The destination of the operation.
        value = The value to exchange with.
    
    Returns:
        The previous value of $(D dst)
*/
T atomicExchange(MemoryOrder order = MemoryOrder.seq, bool result = true, T)(ref T dst, T value) pure nothrow @nogc @trusted {
    static assert(order != MemoryOrder.acq, "Invalid MemoryOrder for atomicExchange()");

    alias A = getAtomicType!T;

    version(LDC) {
        A result = llvm_atomic_rmw_xchg!A(cast(shared A*) dst, *cast(A*) &value, llvm_atomic_ordering!(order));
        return *cast(T*) &result;
    } else {
        assert(0, "Not implemented!");
    }
}

/**
    Creates an atomic fence.
*/
void atomicFence(MemoryOrder order = MemoryOrder.seq)() pure nothrow @nogc @trusted {
    version(LDC) {
        llvm_memory_fence(llvm_atomic_ordering!(order));
    } else {
        assert(0, "Not implemented!");
    }
}

/**
    Signals an atomic fence.
*/
void atomicSignalFence(MemoryOrder order = MemoryOrder.seq)() pure nothrow @nogc @trusted {
    version(LDC) {
        llvm_memory_fence(llvm_atomic_ordering!(order), SynchronizationScope.SingleThread);
    } else {
        assert(0, "Not implemented!");
    }
}
 