/**
    Numem Lifetime Handling.

    This module implements wrappers around $(D numem.core.lifetime) to provide
    an easy way to instantiate various D types and slices of D types.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen

    See_Also:
        $(D numem.core.memory.nu_resize)
        $(D numem.core.memory.nu_dup)
        $(D numem.core.memory.nu_idup)
*/
module numem.lifetime;
import numem.core.exception;
import numem.core.traits;
import numem.core.lifetime;
import numem.core.hooks;
import numem.core.memory;
import numem.casting;
import numem.heap;

// Utilities that are useful in the same regard from core.
public import numem.core.memory : nu_dup, nu_idup, nu_resize, nu_malloca, nu_freea;
public import numem.core.lifetime : nu_destroywith, nu_autoreleasewith;

@nogc:

/**
    Creates a new auto release pool spanning the current scope.

    Returns:
        A stack allocated object with copying and moving disabled.
*/
auto autoreleasepool_scope() {
    static
    struct nu_arpool_stackctx {
    @nogc:
    private:
        void* ctx;
    
    public:
        ~this() { nu_autoreleasepool_pop(ctx); }
        this(void* ctx) { this.ctx = ctx; }

        @disable this(this);
    }

    return nu_arpool_stackctx(nu_autoreleasepool_push());
}

/**
    Creates a scoped auto release pool.

    Params:
        scope_ = The scope in which the auto release pool acts.
*/
void autoreleasepool(void delegate() scope @nogc scope_) @trusted {
    void* ctx = nu_autoreleasepool_push();
    scope_();
    nu_autoreleasepool_pop(ctx);
}

/**
    Constructs the given object.

    Attempting to construct a non-initialized $(D object) is undefined behaviour.
*/
void nogc_construct(T, Args...)(ref T object, Args args) @trusted {
    static if (isPointer!T)
        emplace(*object, args);
    else
        emplace(object, args);
}

/**
    Allocates a new instance of $(D T).
*/
Ref!T nogc_new(T, Args...)(auto ref Args args) @trusted {
    if (Ref!T newobject = cast(Ref!T)nu_malloc(AllocSize!T)) {
        try {
            nogc_construct(newobject, args);
            return newobject;

        } catch(Exception ex) {
            nu_free(cast(void*)newobject);
            throw ex;
        }
    }
    return null;
}

/**
    Attempts to allocate a new instance of $(D T).

    Params:
        args = The arguments to pass to the type's constructor.
    
    Returns: 
        A reference to the instantiated object or $(D null) if allocation
        failed.
*/
Ref!T nogc_trynew(T, Args...)(auto ref Args args) @trusted nothrow {
    if (Ref!T newobject = cast(Ref!T)nu_malloc(AllocSize!T)) {
        try {
            nogc_construct(newobject, args);
            return newobject;

        } catch(Exception ex) {

            nu_free(cast(void*)newobject);
            if (ex) 
                assumeNoThrowNoGC((Exception ex) { nogc_delete(ex); }, ex);
            return null;
        }
    }
    return null;
}

/** 
    Allocates a new instance of $(D T) on the specified heap.

    Params:
        heap = The heap to allocate the instance on.
        args = The arguments to pass to the type's constructor.
*/
Ref!T nogc_new(T, Args...)(NuHeap heap, auto ref Args args) @trusted {
    if (Ref!T newobject = cast(Ref!T)heap.alloc(AllocSize!T)) {
        try {
            nogc_construct(newobject, args);
        } catch(Exception ex) {
            nu_free(cast(void*)newobject);
            throw ex;
        }
    }
    return null;
}

/**
    Attempts to allocate a new instance of $(D T) on the specified heap.

    Params:
        heap = The heap to allocate the instance on.
        args = The arguments to pass to the type's constructor.
    
    Returns: 
        A reference to the instantiated object or $(D null) if allocation
        failed.
*/
Ref!T nogc_trynew(T, Args...)(NuHeap heap, auto ref Args args) @trusted nothrow {
    if (Ref!T newobject = cast(Ref!T)heap.alloc(AllocSize!T)) {
        try {
            nogc_construct(newobject, args);
            return newobject;

        } catch(Exception ex) {
            
            nu_free(cast(void*)newobject);
            if (ex) 
                assumeNoThrowNoGC((Exception ex) { nogc_delete(ex); }, ex);
            return null;
        }
    }
    return null;
}

/**
    Finalizes $(D obj_) by calling its destructor (if any).

    If $(D doFree) is $(D true), memory associated with obj_ will additionally be freed 
    after finalizers have run; otherwise the object is reset to its original state.

    Params:
        obj_ = Instance to destroy and deallocate.
*/
void nogc_delete(T, bool doFree=true)(ref T obj_) @trusted {
    static if (isHeapAllocated!T) {

        // Ensure type is not null.
        if (reinterpret_cast!(void*)(obj_) !is null) {

            destruct!(T, !doFree)(obj_);

            // Free memory if need be.
            static if (doFree)
                nu_free(cast(void*)obj_);

            obj_ = null;
        }
    } else {
        destruct!(T, !doFree)(obj_);
    }
}

/**
    Attempts to finalize $(D obj_) by calling its destructor (if any).

    If $(D doFree) is $(D true), memory associated with obj_ will additionally be freed 
    after finalizers have run; otherwise the object is reset to its original state.

    Params:
        obj_ = Instance to destroy and deallocate.

    Returns:
        Whether the operation succeeded.
*/
bool nogc_trydelete(T, bool doFree=true)(ref T obj_) @trusted nothrow {
    try {
        nogc_delete(obj_);
        return true;
    
    } catch (Exception ex) {
        if (ex) 
            assumeNoThrowNoGC((Exception ex) { nogc_delete(ex); }, ex);
        return false;
        
    }
}

/**
    Deallocates the specified instance of $(D T) from the specified heap.
    Finalizes $(D obj_) by calling its destructor (if any).

    If $(D doFree) is $(D true), memory associated with obj_ will additionally be freed 
    after finalizers have run; otherwise the object is reset to its original state.

    Params:
        heap = The heap to allocate the instance on.
        obj_ = Instance to destroy and deallocate.
*/
void nogc_delete(T, bool doFree=true)(NuHeap heap, ref T obj_) @trusted {
    static if (isHeapAllocated!T) {
        if (reinterpret_cast!(void*)(obj_) !is null) {

            destruct!(T, !doFree)(obj_);

            // Free memory if need be.
            static if (doFree)
                heap.free(cast(void*)obj_);

            obj_ = null;
        }
    }
}

/**
    Attempts to deallocate the specified instance of $(D T) from the specified heap.
    Finalizes $(D obj_) by calling its destructor (if any).

    If $(D doFree) is $(D true), memory associated with obj_ will additionally be freed 
    after finalizers have run; otherwise the object is reset to its original state.

    Params:
        heap = The heap to allocate the instance on.
        obj_ = Instance to destroy and deallocate.

    Returns:
        Whether the operation succeeded.
*/
bool nogc_trydelete(T, bool doFree=true)(NuHeap heap, ref T obj_) @trusted nothrow {
    static if (isHeapAllocated!T) {
        try {

            nogc_delete(heap, obj_);
            return true;
        } catch (Exception ex) {

            if (ex)
                assumeNoThrowNoGC((Exception ex) { nogc_delete(ex); }, ex);
            return false;
        }
    }
}

/**
    Finalizes the objects referenced by $(D objects) by calling the
    destructors of its members (if any).

    If $(D doFree) is $(D true), memory associated with each object
    will additionally be freed after finalizers have run; otherwise the object 
    is reset to its original state.
*/
void nogc_delete(T, bool doFree=true)(T[] objects) @trusted {
    foreach(i; 0..objects.length)
        nogc_delete!(T, doFree)(objects[i]);
}

/**
    Attempts to finalize the objects referenced by $(D objects) by calling the
    destructors of its members (if any).

    If $(D doFree) is $(D true), memory associated with each object
    will additionally be freed after finalizers have run; otherwise the object 
    is reset to its original state.

    Params:
        objects = The objects to try to delete.

    Returns:
        Whether the operation succeeded.
*/
bool nogc_trydelete(T, bool doFree=true)(T[] objects) @trusted {
    size_t failed = 0;
    foreach(i; 0..objects.length)
        failed += nogc_trydelete!(T, doFree)(objects[i]);
    
    return failed != 0;
}

/**
    Initializes the object at the memory in $(D dst), filling it out with
    its default state.

    This variant will also initialize class instances on the stack which
    can then be constructed with $(D nogc_construct). However you may
    still need to $(D nogc_delete) these instances, with $(D doFree) set 
    to false.

    Params:
        dst = A memory range allocated, big enough to store $(D T)
    
    Returns:
        A reference to the initialized element, or $(D T.init) if it failed.
*/
T nogc_initialize(T)(void[] dst) @trusted {
    if (dst.length < AllocSize!T)
        return T.init;

    T tmp = cast(T)dst.ptr;
    initializeAt(tmp);
    return tmp;
}

/**
    Initializes the object at $(D element), filling it out with
    its default state.

    Params:
        element = A reference to the allocated memory to initialize.
    
    Returns:
        A reference to the initialized element.
*/
ref T nogc_initialize(T)(ref T element) @trusted {
    initializeAtNoCtx(element);
    return element;
}

/**
    Initializes the objects at $(D elements), filling them out with
    their default state.

    Params:
        elements = A slice of the elements to initialize
    
    Returns:
        The slice with now initialized contents.
*/
T[] nogc_initialize(T)(T[] elements) @trusted {
    foreach(i; 0..elements.length)
        initializeAtNoCtx(elements[i]);
    
    return elements;
}

/**
    Zero-fills an object
*/
void nogc_zeroinit(T)(ref T element) @trusted nothrow pure {
    nu_memset(&element, 0, element.sizeof);
}

/**
    Zero-fills an object
*/
void nogc_zeroinit(T)(T[] elements) @trusted nothrow pure {
    nu_memset(elements.ptr, 0, elements.length*T.sizeof);
}

/**
    Allocates a new class on the heap.
    Immediately exits the application if out of memory.
*/
void nogc_emplace(T, Args...)(auto ref T dest, Args args) @trusted {
    emplace!(T, T, Args)(dest, args);
}

/**
    Moves elements in $(D src) to $(D dst) via destructive copy.
    
    If an element in $(D src) is not a valid object,
    then accessing the moved element in $(D to) will be undefined behaviour.

    After the move operation, the original memory locations in $(D from) will be
    reset to their base initialized state before any constructors are run.
*/
void nogc_move(T)(T[] dst, T[] src) @trusted {
    import nulib.math : min;
    size_t toTx = min(dst.length, src.length);

    foreach(i; 0..toTx)
        __move(src[i], dst[i]);
}

/**
    Copies $(D src) to $(D dst) via a blit operation.

    Postblits and copy constructors will be called subsequently.
*/
void nogc_copy(T)(T[] dst, T[] src) @trusted {
    import nulib.math : min;
    size_t toTx = min(dst.length, src.length);

    foreach(i; 0..toTx)
        __copy(src[i], dst[i]);
}

/**
    Moves $(D from) to $(D to) via a destructive copy.
    
    If $(D from) is not a valid object, then accessing $(D to) will be undefined
    behaviour.

    After the move operation, the original memory location of $(D from) will be
    reset to its base initialized state before any constructors are run.

    Params: 
        from = The source of the move operation.
        to = The destination of the move operation.
*/
void moveTo(T)(ref T from, ref T to) @trusted {
    __move(from, to);
}

/**
    Moves $(D from).
    
    Useful for moving stack allocated structs.

    Params: 
        from = The source of the move operation.
    
    Returns: 
        The moved value, $(D from) will be reset to its initial state.
*/
T move(T)(scope ref return T from) @trusted {
    return __move(from);
}

/**
    Copies $(D from) to $(D to) via a blit operation.

    Postblits and copy constructors will be called subsequently.

    Params: 
        from = The source of the copy operation.
        to = The destination of the copy operation.
*/
void copyTo(T)(ref T from, ref T to) @trusted {
    __copy(from, to);
}