/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem;
import std.conv : emplace;
import core.stdc.stdlib : free, exit, malloc;
import std.traits;

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
    version(minimal_rt) {
        immutable(size_t) destructorObjSize = _impl_destructorStruct.sizeof;
        immutable(size_t) classObjSize = __traits(classInstanceSize, T);
        immutable size_t allocSize = classObjSize + destructorObjSize;

        void* rawMemory = malloc(allocSize);
        if (!rawMemory) {
            exit(-1);
        }

        // Allocate class destructor list
        emplace!_impl_destructorStruct(rawMemory[0..destructorObjSize], &_impl_destructorCall!T);

        // Allocate class
        T obj = emplace!T(rawMemory[destructorObjSize .. allocSize], args);
        return obj;

    } else {
        immutable size_t allocSize = __traits(classInstanceSize, T);
        void* rawMemory = malloc(allocSize);
        if (!rawMemory) {
            exit(-1);
        }

        return emplace!T(rawMemory[0 .. allocSize], args);
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

    *rawMemory = value;
    return rawMemory;
}

/**
    Destroys and frees the memory.

    For structs this will call the struct's destructor if it has any.
*/
void nogc_delete(T)(ref T obj_)  {
    
    version(minimal_rt) {
        static if (isPointer!T || is(T == class)) {
            if (obj_) {
            
                static if (is(T == class)) {

                    // Do pointer arithmetic to fetch the class destructor list and call it.
                    void* chunkStart = (cast(void*)obj_)-_impl_destructorStruct.sizeof;
                    auto store = cast(_impl_destructorStruct*)chunkStart;
                    store.destruct(cast(void*)obj_);
                    free(chunkStart);

                } else static if (is(T == struct) || is(T == union)) {

                    // Try to call elaborate destructor first before attempting __dtor
                    static if (__traits(hasMember, T, "__xdtor")) {
                        assumeNothrowNoGC(&obj_.__xdtor)();
                    } else static if (__traits(hasMember, T, "__dtor")) {
                        assumeNothrowNoGC(&obj_.__dtor)();
                    }
                    free(cast(void*)obj_);
                } else {
                    free(cast(void*)obj_);
                }
            }
        } else static if (is(T == struct) || is(T == union)) {

            // Try to call elaborate destructor first before attempting __dtor
            static if (__traits(hasMember, T, "__xdtor")) {
                assumeNothrowNoGC(&obj_.__xdtor)();
            } else static if (__traits(hasMember, T, "__dtor")) {
                assumeNothrowNoGC(&obj_.__dtor)();
            }
        }

    } else {


        // With a normal runtime we can use destroy
        static if (isPointer!T || is(T == class)) {
            static if (is(T == class)) {
                auto objptr_ = obj_;
            } else {
                auto objptr_ = &obj_;
            }
            
            // First create an internal function that calls with the correct parameters
            alias destroyFuncRef = void function(typeof(objptr_));
            destroyFuncRef dfunc = (typeof(objptr_) objptr_) { destroy!false(objptr_); };

            // Then assume it's nothrow nogc
            assumeNothrowNoGC!destroyFuncRef(dfunc)(objptr_);

            // NOTE: We already know it's heap allocated.
            free(cast(void*)objptr_);

        } else static if (is(T == struct) || is(T == union)) {
            auto objptr_ = &obj_;

            // First create an internal function that calls with the correct parameters
            alias destroyFuncRef = void function(typeof(objptr_));
            destroyFuncRef dfunc = (typeof(objptr_) objptr_) { destroy!false(objptr_); };
            
            // Then assume it's nothrow nogc
            assumeNothrowNoGC!destroyFuncRef(dfunc)(objptr_);

            // Free memory
            static if(isPointer!T) free(cast(void*)obj_);
        } else {

            // Free memory
            static if(isPointer!T) free(cast(void*)obj_);
        }
    }
}