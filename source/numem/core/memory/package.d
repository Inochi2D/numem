/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module numem.core.memory;
import numem.core.memory.lifetime;
import numem.core.hooks;
import std.traits;

public import numem.core.memory.smartptr;
debug(trace) import numem.core.trace;

/**
    UDA which allows initializing an empty struct, even when copying is disabled.
*/
struct AllowInitEmpty;

/**
    Allocates a new instance of type T.
*/
RefT!T nogc_new(T, Args...)(Args args) {
    RefT!T newobject = cast(RefT!T)nuAlloc(nuAllocSize!T);
    if (!newobject)
        nuAbort();

    static if (is(T == class) || isPointer!T)
        emplace(newobject, args);
    else
        emplace(*newobject, args);
    

    // Tracing
    debug(trace)
        dbg_alloc(newobject);
    
    return newobject;
}

/**
    Destroys and frees the memory.

    For structs this will call the struct's destructor if it has any.
*/
void nogc_delete(T, bool doFree=true)(ref T obj_)  {
    
    destruct!(T, doFree)(obj_);

    // Tracing
    debug(trace)
        dbg_dealloc(obj_);
}

/**
    Initializes the object at `element`, filling it out with
    its default state.
*/
void nogc_initialize(T)(ref T element) {
    initializeAt(element);
}

/**
    Zero-fills an object
*/
void nogc_zeroinit(T)(ref T element) {
    nuMemset(&element, 0, element.sizeof);
}

/**
    Creates an object with all of its bytes set to 0.
*/
T nogc_zeroinit(T)() {
    T element;
    nuMemset(&element, 0, element.sizeof);
    return element;
}

/**
    Allocates a new class on the heap.
    Immediately exits the application if out of memory.
*/
void nogc_emplace(T, Args...)(ref auto T dest, Args args)  {
    emplace!(T, T, Args)(dest, args);
}