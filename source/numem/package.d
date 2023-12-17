module numem;
import std.conv : emplace;
import core.stdc.stdlib : free, exit, malloc;
import std.traits;

extern(C):
nothrow @nogc:

//
//          MANUAL MEMORY MANAGMENT
//
private {
    // Based on code from dplug:core
    // which is released under the Boost license.

    auto assumeNoGC(T) (T t) {
        static if (isFunctionPointer!T || isDelegate!T)
        {
            enum attrs = functionAttributes!T | FunctionAttribute.nogc;
            return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
        }
        else
            static assert(false);
    }

    auto assumeNothrowNoGC(T) (T t) {
        static if (isFunctionPointer!T || isDelegate!T)
        {
            enum attrs = functionAttributes!T | FunctionAttribute.nogc | FunctionAttribute.nothrow_;
            return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
        }
        else
            static assert(false);
    }
}

/**
    Allocates a new struct on the heap.
    Immediately exits the application if out of memory.
*/
T* nogc_new(T, Args...)(Args args) if (is(T == struct)) {
    void* rawMemory = malloc(T.sizeof);
    if (!rawMemory) {
        exit(-1);
    }

    T* obj = cast(T*)rawMemory;
    emplace!T(obj, args);

    return obj;
}

/**
    Allocates a new class on the heap.
    Immediately exits the application if out of memory.
*/
T nogc_new(T, Args...)(Args args) if (is(T == class)) {
    immutable size_t allocSize = __traits(classInstanceSize, T);
    void* rawMemory = malloc(allocSize);
    if (!rawMemory) {
        exit(-1);
    }

    T obj = emplace!T(rawMemory[0 .. allocSize], args);
    return obj;
}

/**
    Destroys and frees the memory.

    For structs this will call the struct's destructor if it has any.
*/
void nogc_delete(T)(ref T obj_)  {
    static if (isPointer!T || is(T == class)) {
        if (obj_) {
        
            static if (is(T == class) || is(T == struct)) {

                // Try to call elaborate destructor first before attempting __dtor
                static if (__traits(hasMember, T, "__xdtor")) {
                    assumeNothrowNoGC(&obj_.__xdtor)();
                } else static if (__traits(hasMember, T, "__dtor")) {
                    assumeNothrowNoGC(&obj_.__dtor)();
                }
            }

            free(cast(void*)obj_);
        }
    } else static if (is(T == struct)) {

        // Try to call elaborate destructor first before attempting __dtor
        static if (__traits(hasMember, T, "__xdtor")) {
            assumeNothrowNoGC(&obj_.__xdtor)();
        } else static if (__traits(hasMember, T, "__dtor")) {
            assumeNothrowNoGC(&obj_.__dtor)();
        }
    }
}