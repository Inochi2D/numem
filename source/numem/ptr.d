/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.ptr;
import core.atomic : atomicFetchAdd, atomicFetchSub, atomicStore, atomicLoad;
import std.traits;
import numem;

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
                    this.free();
                }
            }
        }

        void free() {

            // Free and atomically store null in the pointer.
            static if (is(T == class)) {

                // Store reference in variable as casting makes it an rvalue
                // rvalues can't be sent to ref parameters.
                T refT = cast(T)ref_;
                nogc_delete!T(refT);
            } else {
                nogc_delete!(T*)(ref_);
            }

            // Enforce that strongRefs is set to 0.
            atomicStore(strongRefs, 0);
            atomicStore(ref_, null);
        }
    }
}

/**
    Allocates a new shared pointer.
*/
shared_ptr!T shared_new(T, Args...)(Args args) nothrow @nogc {
    static if (is(T == class)) {
        T item = nogc_new!T(args);
        return shared_ptr!T(cast(T*)item);
    } else {
        T* item = nogc_new!T(args);
        return shared_ptr!T(item);
    }
}

unittest {
    import numem.ptr;
    class A { }
    shared_ptr!A p = shared_new!A();
}


/**
    Allocates a new unique pointer.
*/
unique_ptr!T unique_new(T, Args...)(Args args) nothrow @nogc {
    static if (is(T == class)) {
        T item = nogc_new!T(args);
        return unique_ptr!T(cast(T*)item);
    } else {
        T* item = nogc_new!T(args);
        return unique_ptr!T(item);
    }
}

unittest {
    import numem.ptr;
    class A { }
    unique_ptr!A p = unique_new!A();
}


/**
    Unique non-copyable smart pointer
*/
struct unique_ptr(T) {
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

package(numem):
    void nullify() {
        rc = null;
    }
    
public:

    /// Can't be created as a copy.
    @disable this(this);

    // Destructor
    ~this() {

        // This *should not* be needed, but just in case to prevent finalized stale pointers from doing shenanigans.
        if (rc) {
            rc.free();
            rc = null;
        }
    }

    static if (is(T == struct)) {

        /**
            - This function is incredibly unsafe, but is there as a backdoor if need be.

            Creates a unique_ptr reference from a existing reference
        */
        static unique_ptr!T fromPtr(T* ptr) @system {
            return unique_ptr!T(ptr);
        }
    } else static if (is(T == class)) {

        /**
            - This function is incredibly unsafe, but is there as a backdoor if need be.

            Creates a unique_ptr reference from a existing reference
        */
        static unique_ptr!T fromPtr(T ptr) @system {
            return unique_ptr!T(cast(T*)ptr);
        }
    }

    static if (is(T == class)) {
        /**
            Gets the value of the unique pointer

            Returns null if the item is no longer valid.
        */
        T getAtomic() {
            return rc ? cast(T)atomicLoad(rc.ref_) : null;
        }

        /**
            Gets the value of the unique pointer

            Returns null if the item is no longer valid.
        */
        T get() {
            return rc ? cast(T)rc.ref_ : null;
        }

        /**
            Gets the value of the unique pointer

            Returns null if the item is no longer valid.
        */
        T opCast() {
            return rc ? cast(T)rc.ref_ : null;
        }
    } else {
        /**
            Gets the value of the unique pointer

            Returns null if the item is no longer valid.
        */
        T* getAtomic() {
            return rc ? atomicLoad(rc.ref_) : null;
        }

        /**
            Gets the value of the unique pointer

            Returns null if the item is no longer valid.
        */
        T* get() {
            return rc ? rc.ref_ : null;
        }

        /**
            Gets the value of the unique pointer

            Returns null if the item is no longer valid.
        */
        T* opCast() {
            return rc ? rc.ref_ : null;
        }
    }

    /**
        Makes a weak borrow of the unique pointer,
        weak borrows do not affect whether the object can be deleted by ref count reaching 0.

        weak refs will return null if the ref count reaches 0 of their parent shared pointer.
    */
    weak_ptr!T borrow() {
        return weak_ptr!T(rc);
    }

    /**
        Moves the unique pointer to the specified other pointer
    */
    void moveTo(ref unique_ptr!T other) {

        // First destruct the target unique_ptr if neccessary.
        if (other.getAtomic()) nogc_delete(other);

        // atomically moves the reference from this unique_ptr to the other unique_ptr reference
        // after this is done, rc is set to null to make this unique_ptr invalid.
        atomicStore(other.rc, this.rc);
        atomicStore(this.rc, null);
    }

    /**
        Resets the unique_ptr, emptying its contents.
    */
    void reset() {
        if (rc) {
            rc.free();
            rc = null;
        }
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

    static if (is(T == struct)) {
        
        /**
            - This function is incredibly unsafe, but is there as a backdoor if need be.

            Creates a shared_ptr reference from a existing reference
        */
        static shared_ptr!T fromPtr(T* ptr) @system {
            return shared_ptr!T(ptr);
        }
    } else static if (is(T == class)) {

        /**
            - This function is incredibly unsafe, but is there as a backdoor if need be.

            Creates a shared_ptr reference from a existing reference
        */
        static shared_ptr!T fromPtr(T ptr) @system {
            return shared_ptr!T(cast(T*)ptr);
        }
    }

    static if (is(T == class)) {
        /**
            Gets the value of the shared pointer

            Returns null if the item is no longer valid.
        */
        T getAtomic() {
            return rc ? cast(T)atomicLoad(rc.ref_) : null;
        }

        /**
            Gets the value of the shared pointer

            Returns null if the item is no longer valid.
        */
        T get() {
            return rc ? cast(T)rc.ref_ : null;
        }

        /**
            Gets the value of the shared pointer

            Returns null if the item is no longer valid.
        */
        T opCast() {
            return rc ? cast(T)rc.ref_ : null;
        }
    } else {
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

    /**
        Resets the shared_ptr, emptying its contents.
    */
    void reset() {
        if (rc) {
            rc.subRef!false;
            rc = null;
        }
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
    ~this() {
        if (rc) {
            this.rc.subRef!true;
            rc = null;
        }
    }

    static if (is(T == class)) {
        /**
            Gets the value of the weak pointer

            Returns null if the item is no longer valid.
        */
        T getAtomic() {
            return rc ? cast(T)atomicLoad(rc.ref_) : null;
        }

        /**
            Gets the value of the weak pointer

            Returns null if the item is no longer valid.
        */
        T get() {
            return rc ? cast(T)rc.ref_ : null;
        }

        /**
            Gets the value of the weak pointer

            Returns null if the item is no longer valid.
        */
        T opCast() {
            return rc ? cast(T)rc.ref_ : null;
        }
    } else {
        /**
            Gets the value of the weak pointer

            Returns null if the item is no longer valid.
        */
        T* getAtomic() {
            return rc ? atomicLoad(rc.ref_) : null;
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
}