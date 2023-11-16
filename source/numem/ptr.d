/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.ptr;
import core.atomic : atomicFetchAdd, atomicFetchSub, atomicStore, atomicLoad;
import std.traits;
import core.stdc.stdlib : free, exit, malloc;
import std.conv : emplace;


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
nothrow @nogc
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
nothrow @nogc
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
void nogc_delete(T)(T obj_) nothrow @nogc {

    // If type is a pointer (to eg a struct) or a class
    static if (isPointer!T || is(T == class)) {
        if (obj_) {
            static if (__traits(hasMember, T, "__xdtor")) {
                assumeNothrowNoGC(&obj_.__xdtor)();
            }
            if (obj_) free(cast(void*)obj_);
        }

    // Otherwise it's *probably* stack allocated, in which case we don't want to call free.
    } else {
        
        // Try to call elaborate destructor first before attempting __dtor
        static if (__traits(hasMember, T, "__xdtor")) {
            assumeNothrowNoGC(&obj_.__xdtor)();
        } else static if (__traits(hasMember, T, "__dtor")) {
            assumeNothrowNoGC(&obj_.__dtor)();
        }
    }
}

//
//          SMART POINTERS
//

private {
    struct refcountmg_t(T) {
     nothrow @nogc:
        T* ref_;
        size_t strongRefs;
        size_t weakRefs;
    
        void addRef(bool weak)() {
            static if (weak) {
                atomicFetchAdd(weakRefs, 1);
            } else {
                atomicFetchAdd(strongRefs, 1);
            }
        }

        void subRef(bool weak)() {
            static if (weak) {
                if (atomicFetchSub(weakRefs, 1) == 0) {
                    debug {
                        // Debug assert to catch bugs
                        assert(0, "More weak references were subtracted than possible!");
                    } else {

                        // Fallback to not wrap around, even though it's technically not needed.
                        atomicStore(weakRefs, 0);
                    }
                }
            } else {
                size_t oldSize = atomicFetchSub(strongRefs, 1);
                
                // We just subtracted the refcount to 0
                if (oldSize == 1) {

                    // Free and atomically store null in the pointer.
                    static if (is(T == class)) {
                        nogc_delete!T(cast(T)ref_);
                    } else {
                        nogc_delete!T(ref_);
                    }
                    atomicStore(ref_, null);
                }
            }
        }
    }
}

/**
    Allocates a new shared pointer.
*/
shared_ptr!T shared_new(T, Args...)(Args args) nothrow @nogc {
    static if (is(T == struct)) {
        T* item = nogc_new!T(args);
        return shared_ptr!T(item);
    } else {
        T item = nogc_new!T(args);
        return shared_ptr!T(cast(T*)item);
    }
}

/**
    A shared pointer
*/
struct shared_ptr(T) {
nothrow @nogc:
private:
    refcountmg_t!(T)* rc;

    // Creation constructor
    this(T* ref_) {
        rc = nogc_new!(refcountmg_t!T);
        rc.ref_ = ref_;
        rc.strongRefs = 1;
        rc.weakRefs = 0;
    }

    /// Copy constructor
    this(shared_ptr!T other) {
        this.rc = other.rc;
        this.rc.addRef!false;
    }

public:
    ~this() {

        // This *should not* be needed, but just in case to prevent finalized stale pointers from doing shenanigans.
        if (rc) {
            rc.subRef!false;
            rc = null;
        }
    }


    /**
        Gets the value of the shared pointer

        Returns null if the item is no longer valid.
    */
    T* getAtomic() {
        return rc ? atomicLoad(rc.ref_) : null;
    }

    /**
        Gets the value of the shared pointer

        Returns null if the item is no longer valid.
    */
    T* get() {
        return rc ? rc.ref_ : null;
    }

    /**
        Gets the value of the shared pointer

        Returns null if the item is no longer valid.
    */
    T* opCast() {
        return rc ? rc.ref_ : null;
    }

    /**
        Makes a weak borrow of the shared pointer,
        weak borrows do not affect whether the object can be deleted by ref count reaching 0.

        weak refs will return null if the ref count reaches 0 of their parent shared pointer.
    */
    weak_ptr!T borrow() {
        return weak_ptr!T(rc);
    }

    /**
        Makes a strong copy of the shared pointer.
    */
    shared_ptr!T copy() {
        return shared_ptr!T(this);
    }
}

/**
    A weak borrowed pointer from a shared_ptr
*/
struct weak_ptr(T) {
nothrow @nogc:
private:
    refcountmg_t!(T)* rc;

    // Internal constructor
    this(refcountmg_t!(T)* rc) {
        this.rc = rc;
        this.rc.addRef!true;
    }

public:
    @disable this();

    ~this() {
        if (rc) {
            this.rc.subRef!true;
            rc = null;
        }
    }

    /**
        Gets the value of the weak pointer

        Returns null if the item is no longer valid.
    */
    T* get() {
        return rc ? rc.ref_ : null;
    }

    /**
        Gets the value of the weak pointer

        Returns null if the item is no longer valid.
    */
    T* opCast() {
        return rc ? rc.ref_ : null;
    }
}