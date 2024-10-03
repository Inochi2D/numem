/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module numem.core.memory;
import numem.core.memory.alloc;
import numem.core.trace;
import std.traits;

public import numem.core.memory.smartptr;

version(Have_tinyd_rt) {
    private __gshared
    auto __gc_new(T, Args...)(Args args) {
        return new T(args);
    }
} else {
    import core.lifetime : copyEmplace, emplace;
}

private {
    // NOTE: D's implementation of emplace makes it ambiguous what emplace to call in certain instances
    // These functions forward to the correct D core functions for emplacing.

    // Case: Is a class
    T __impl_nogc_emplace(T, Args...)(void[] chunk, Args args) if(is(T == class)) {
        return emplace!(T, Args)(chunk, args);
    }

    // Case: Is struct or basic pointer.
    T* __impl_nogc_emplace(T, Args...)(T* chunk, Args args) if(!is(T == class)) {
        return emplace!(T, Args)(chunk, args);
    }

    enum isAggregateStackType(T) = 
        is(T == struct) || is(T == union);
}

nothrow @nogc:

//
//          MANUAL MEMORY MANAGMENT
//
private {

    version(minimal_rt) {

        // The type of the destructor caller
        alias _impl_mrt_dfunctype = nothrow @nogc @system void function(void*);

        // Generic destructor call
        void _impl_destructorCall(T)(void* instance) nothrow @nogc {
            import std.traits : BaseTypeTuple;

            // Scope for base class destructor
            static foreach(item; BaseClassesTuple!T) {
                {
                    static if (!is(item == Object) && !is(item == T)) {
                        static if (__traits(hasMember, item, "__xdtor")) {
                            auto dtorptr = &item.init.__xdtor;
                            dtorptr.ptr = instance;
                            dtorptr();
                        } else static if (__traits(hasMember, item, "__dtor")) {
                            auto dtorptr = &item.init.__dtor;
                            dtorptr.ptr = instance;
                            dtorptr();
                        }
                    }
                }
            }

            // Scope for self destructor
            {
                static if (__traits(hasMember, T, "__xdtor")) {
                    auto dtorptr = &T.init.__xdtor;
                    dtorptr.ptr = instance;
                    dtorptr();
                } else static if (__traits(hasMember, T, "__dtor")) {
                    auto dtorptr = &T.init.__dtor;
                    dtorptr.ptr = instance;
                    dtorptr();
                }
            }
        }

        // Structure for storing the destructor reference.
        struct _impl_destructorStruct {
            _impl_mrt_dfunctype destruct;
        }
    }
}

extern(C):

/**
    UDA which allows initializing an empty struct, even when copying is disabled.
*/
struct AllowInitEmpty;

/**
    Constructs a type, this allows initializing types on the stack instead of heap.
*/
T nogc_construct(T, Args...)(Args args) if (is(T == struct) || is(T == class) || is (T == union)) {
    static if (is(T == class)) {
        return (assumeNothrowNoGC(&__gc_new!(T, Args)))(args);
    } else {
        static if (hasUDA!(T, AllowInitEmpty) && args.length == 0) {
            return T.init;
        } else {
            return T(args);
        }
    }
}

/**
    Allocates a new struct on the heap.
    Immediately exits the application if out of memory.
*/
T* nogc_new(T, Args...)(Args args) if (is(T == struct) || is(T == union)) {

    version(Have_tinyd_rt) {
        return (assumeNothrowNoGC(&__gc_new!(T, Args)))(args);
    } else {
        void* rawMemory = malloc(T.sizeof);
        if (!rawMemory) {
            exit(-1);
        }

        T* obj = cast(T*)rawMemory;
        static if (hasUDA!(T, AllowInitEmpty) && args.length == 0) {
            nogc_emplace!T(obj);
        } static if (args.length == 1 && is(typeof(args[0]) == T)) {
            nogc_copyemplace(obj, args[0]);
        } else {
            nogc_emplace!T(obj, args);
        }

        // Tracing
        debug(trace) dbg_alloc(obj);

        return obj;
    }
}

/**
    Allocates a new class on the heap.
    Immediately exits the application if out of memory.
*/
T nogc_new(T, Args...)(Args args) if (is(T == class)) {

    alias emplaceFunc = typeof(&emplace!T);

    version(Have_tinyd_rt) {
        return (assumeNothrowNoGC(&__gc_new!(T, Args)))(args);
    } else version(minimal_rt) {
        immutable(size_t) destructorObjSize = _impl_destructorStruct.sizeof;
        immutable(size_t) classObjSize = __traits(classInstanceSize, T);
        immutable size_t allocSize = classObjSize + destructorObjSize;

        void* rawMemory = malloc(allocSize);
        if (!rawMemory) {
            exit(-1);
        }

        // Allocate class destructor list
        nogc_emplace!classDestructorList(rawMemory[0..destructorObjSize], &_impl_destructorCall!T);

        // Allocate class
        T obj = nogc_emplace!T(rawMemory[destructorObjSize .. allocSize], args);

        // Tracing
        debug(trace) dbg_alloc(obj);
        
        return obj;
    } else {
        immutable size_t allocSize = __traits(classInstanceSize, T);
        void* rawMemory = malloc(allocSize);
        if (!rawMemory) {
            exit(-1);
        }

        return nogc_emplace!T(rawMemory[0 .. allocSize], args);
    }
}

/**
    Allocates a new basic type on the heap.
    Immediately exits the application if out of memory.
*/
T* nogc_new(T)(T value = T.init) if (isBasicType!T) {
    T* rawMemory = cast(T*)malloc(T.sizeof);
    if (!rawMemory) {
        exit(-1);
    }

    // Tracing
    debug(trace) dbg_alloc(rawMemory);

    *rawMemory = value;
    return rawMemory;
}

/**
    Destroys and frees the memory.

    For structs this will call the struct's destructor if it has any.
*/
void nogc_delete(T)(ref T obj_)  {

    // Tracing
    debug(trace) dbg_dealloc(obj_);
    
    destruct(obj_);
}

auto nogc_copyemplace(T)(T* target, ref T source) {
    alias t = typeof(&copyEmplace!(T, T));
    return assumeNothrowNoGC!t(&copyEmplace!(T, T))(source, *target);
}

/**
    nogc emplace function
*/
auto nogc_emplace(T, Args...)(T* chunk, Args args) {
    alias t = typeof(&__impl_nogc_emplace!(T, Args));
    return assumeNothrowNoGC!t(&__impl_nogc_emplace!(T, Args))(chunk, args);
}

/**
    nogc emplace function
*/
auto nogc_emplace(T, Args...)(void[] chunk, Args args) if (is(T == class)) {
    alias t = typeof(&__impl_nogc_emplace!(T, Args));
    return assumeNothrowNoGC!t(&__impl_nogc_emplace!(T, Args))(chunk, args);
}