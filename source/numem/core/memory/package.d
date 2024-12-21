/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module numem.core.memory;
import numem.core.memory.lifetime;
import numem.core.hooks;
import numem.core.heap;
import numem.core.traits;

public import numem.core.memory.smartptr;
debug(trace) import numem.core.trace;
import numem.core.casting;

/**
    UDA which allows initializing an empty struct, even when copying is disabled.
*/
deprecated("This UDA is no longer in use by numem.")
struct AllowInitEmpty;

/**
    Constructs the given object.

    Attempting to construct a non-initialized `object` is undefined behaviour.
*/
void nogc_construct(T, Args...)(ref T object, Args args) {
    static if (isPointer!T)
        emplace(*object, args);
    else
        emplace(object, args);

}

/**
    Allocates a new instance of `T`.
*/
Ref!T nogc_new(T, Args...)(auto ref Args args) {
    Ref!T newobject = cast(Ref!T)nuAlloc(AllocSize!T);
    if (!newobject)
        nuAbort();

    nogc_construct(newobject, args);

    // Tracing
    debug(trace)
        dbg_alloc(newobject);
    
    return newobject;
}

/** 
    Allocates a new instance of `T` on the specified heap.

    Params:
        heap = The heap to allocate the instance on.
        args = The arguments to pass to the type's constructor.
    Returns: 
        A reference to the instantiated object or `null` if allocation
        failed.
*/
Ref!T nogc_new(T, Args...)(NuHeap heap, auto ref Args args) {
    if (Ref!T newobject = cast(Ref!T)heap.alloc(AllocSize!T)) {
        nogc_construct(newobject, args);

        // Tracing
        debug(trace)
            dbg_alloc(newobject);
    }
    return null;
}

/**
    Deallocates the specified instance of `T` from the specified heap.
    Finalizes `obj_` by calling its destructor (if any).

    If `doFree` is `true`, memory associated with obj_ will additionally be freed 
    after finalizers have run; otherwise the object is reset to its original state.

    Params:
        heap = The heap to allocate the instance on.
        obj_ = Instance to destroy and deallocate.
*/
void nogc_delete(T, bool doFree=true)(NuHeap heap, ref T obj_) if (isHeapAllocated!T) {
    if (reinterpret_cast!(void*)(obj_) !is null) {
        debug(trace) 
            dbg_dealloc(obj_);

        destruct!(T, !doFree)(obj_);

        // Free memory if need be.
        static if (doFree)
            heap.free(cast(void*)obj_);

        obj_ = null;
    }
}

/**
    Finalizes `obj_` by calling its destructor (if any).

    If `doFree` is `true`, memory associated with obj_ will additionally be freed 
    after finalizers have run; otherwise the object is reset to its original state.

    Params:
        obj_ = Instance to destroy and deallocate.
*/
void nogc_delete(T, bool doFree=true)(ref T obj_)  {

    // Basic types do not need to be traced.
    debug(trace) {
        static if(!isBasicType!T) {
            dbg_dealloc(obj_);
        }
    }
    
    static if (isHeapAllocated!T) {

        // Ensure type is not null.
        if (reinterpret_cast!(void*)(obj_) !is null) {

            destruct!(T, !doFree)(obj_);

            // Free memory if need be.
            static if (doFree)
                nuFree(cast(void*)obj_);

            obj_ = null;
        }
    } else {
        destruct!(T, !doFree)(obj_);
    }
}

/**
    Finalizes the objects referenced by `objects` by calling the
    destructors of its members (if any).

    If `doFree` is `true`, memory associated with each object
    will additionally be freed after finalizers have run; otherwise the object 
    is reset to its original state.
*/
void nogc_delete(T, bool doFree=true)(T[] objects) {
    foreach(i; 0..objects.length)
        nogc_delete!(T, doFree)(objects[i]);
}

/**
    Initializes the object at `element`, filling it out with
    its default state.
*/
void nogc_initialize(T)(ref T element) {
    initializeAt(element);
}

/**
    Initializes the objects at `elements`, filling them out with
    their default state.
*/
void nogc_initialize(T)(T[] elements) {
    foreach(i; 0..elements.length)
        initializeAt(elements[i]);
}

/**
    Zero-fills an object
*/
void nogc_zeroinit(T)(ref T element) {
    nuMemset(&element, 0, element.sizeof);
}

/**
    Zero-fills an object
*/
void nogc_zeroinit(T)(T[] elements) {
    nuMemset(elements.ptr, 0, elements.length*T.sizeof);
}

/**
    Allocates a new class on the heap.
    Immediately exits the application if out of memory.
*/
void nogc_emplace(T, Args...)(ref auto T dest, Args args)  {
    emplace!(T, T, Args)(dest, args);
}

/**
    Moves elements in `src` to `dst` via destructive copy.
    
    If an element in `src` is not a valid object,
    then accessing the moved element in `to` will be undefined behaviour.

    After the move operation, the original memory locations in `from` will be
    reset to their base initialized state before any constructors are run.
*/
void nogc_move(T)(T[] dst, T[] src) {
    foreach(i; 0..src.length)
        __move(src[i], dst[i]);
}

/**
    Copies `src` to `dst` via a blit operation.

    Postblits and copy constructors will be called subsequently.
*/
void nogc_copy(T)(T[] dst, T[] src) {
    foreach(i; 0..src.length)
        __copy(src[i], dst[i]);
}

/**
    Moves `from` to `to` via a destructive copy.
    
    If `from` is not a valid object, then accessing `to` will be undefined
    behaviour.

    After the move operation, the original memory location of `from` will be
    reset to its base initialized state before any constructors are run.

    Params: 
        from = The source of the move operation.
        to = The destination of the move operation.
*/
void moveTo(T)(ref T from, ref T to) {
    __move(from, to);
}

/**
    Moves `from` to return value.
    
    Useful for moving stack allocated structs.

    Params: 
        from = The source of the move operation.
    
    Returns: 
        The moved value, `from` will be reset to its initial state.
*/
T move(T)(scope ref return T from) {
    return __move(from);
}

/**
    Copies `from` to `to` via a blit operation.

    Postblits and copy constructors will be called subsequently.

    Params: 
        from = The source of the copy operation.
        to = The destination of the copy operation.
*/
void copyTo(T)(ref T from, ref T to) {
    __copy(from, to);
}