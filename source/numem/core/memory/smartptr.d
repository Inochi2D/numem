/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module numem.core.memory.smartptr;
import core.atomic : atomicFetchAdd, atomicFetchSub, atomicStore, atomicLoad;
import std.traits;
import numem.core;

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

            if (ref_) {

                // Free and atomically store null in the pointer.
                static if (is(T == class)) {

                    // Store reference in variable as casting makes it an rvalue
                    // rvalues can't be sent to ref parameters.
                    T refT = cast(T)ref_;
                    nogc_delete!T(refT);
                } else {
                    nogc_delete!(T*)(ref_);
                }
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
@trusted
shared_ptr!T shared_new(T, Args...)(Args args) nothrow @nogc {
    static if (is(T == class)) {
        T item = nogc_new!T(args);
        return shared_ptr!T(cast(T*)item);
    } else {
        T* item = nogc_new!T(args);
        return shared_ptr!T(item);
    }
}


/**
    Allocates a new unique pointer.
*/
@trusted
unique_ptr!T unique_new(T, Args...)(Args args) nothrow @nogc {
    static if (is(T == class)) {
        T item = nogc_new!T(args);
        return unique_ptr!T(cast(T*)item);
    } else {
        T* item = nogc_new!T(args);
        return unique_ptr!T(item);
    }
}


/**
    Unique non-copyable smart pointer
*/
struct unique_ptr(T) {
nothrow @nogc:

// Special interop public section
public:

    /// Actual value type of the pointer.
    static if (is(T == class)) {
        alias VT = T;
    } else {
        alias VT = T*;
    }

    // Allows accessing members of the unique_ptr
    alias getAtomic this;

private:
    refcountmg_t!(T)* rc;

    // Creation constructor
    this(T* ref_) {
        rc = nogc_new!(refcountmg_t!T);
        rc.ref_ = ref_;
        rc.strongRefs = 1;
        rc.weakRefs = 0;
    }

public:

    /**
        Moves unique_ptr to this instance.

        This is a reuse of copy-constructors, and is unique to unique_ptr.
    */
    @trusted
    this(ref unique_ptr!T other) {

        // Free our own refcount if need be
        if (this.rc) {
            this.reset();
        }

        // atomically moves the reference from this unique_ptr to the other unique_ptr reference
        // after this is done, rc is set to null to make this unique_ptr invalid.
        atomicStore(this.rc, other.rc);
        other.clear();
    }

    /**
        Moves unique_ptr to this instance.

        This is a reuse of copy-constructors, and is unique to unique_ptr.
    */
    @trusted
    this(ref const(unique_ptr!T) other) {
        this(*(cast(unique_ptr!(T)*)&other));
    }

    // Destructor
    ~this() {

        // This *should not* be needed, but just in case to prevent finalized stale pointers from doing shenanigans.
        if (rc) {
            rc.free();
            rc = null;
        }
    }


    /**
        - This function is incredibly unsafe, but is there as a backdoor if need be.

        Creates a unique_ptr reference from a existing reference
    */
    @system
    static unique_ptr!T fromPtr(VT ptr) {
        return unique_ptr!T(cast(T*)ptr);
    }

    /**
        Gets the value of the unique pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT getAtomic() {
        return rc ? cast(VT)atomicLoad(rc.ref_) : null;
    }

    /**
        Gets the value of the unique pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT get() {
        return rc ? cast(VT)rc.ref_ : null;
    }

    /**
        Makes a weak borrow of the unique pointer,
        weak borrows do not affect whether the object can be deleted by ref count reaching 0.

        weak refs will return null if the ref count reaches 0 of their parent shared pointer.
    */
    @trusted
    weak_ptr!T borrow() {
        return weak_ptr!T(rc);
    }

    /**
        Moves the unique pointer to the specified other pointer
    */
    @trusted
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
    @trusted
    void reset() {
        if (rc) {
            rc.free();
            rc = null;
        }
    }

    /**
        Clears the contents of the unique_ptr

        This is an unsafe operation and can lead to memory leaks if used improperly.
    */
    @system
    void clear() {
        if (rc) {
            atomicStore(this.rc, null);
        }
    }

    /**
        Gets the amount of strong references to the object
    */
    @trusted
    size_t getRefCount() {
        if (rc) {
            return atomicLoad(rc.strongRefs);
        }
        return 0;
    }

    /**
        Gets the amount of weak references to the object
    */
    @trusted
    size_t getBorrowCount() {
        if (rc) {
            return atomicLoad(rc.weakRefs);
        }
        return 0;
    }
}

/**
    A shared pointer
*/
struct shared_ptr(T) {
nothrow @nogc:

// Special interop public section
public:

    /// Actual value type of the pointer.
    static if (is(T == class)) {
        alias VT = T;
    } else {
        alias VT = T*;
    }

    // Allows accessing members of the unique_ptr
    alias getAtomic this;

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
        - This function is incredibly unsafe, but is there as a backdoor if need be.

        Creates a shared_ptr reference from a existing reference
    */
    @system
    static shared_ptr!T fromPtr(VT ptr) {
        return shared_ptr!T(cast(T*)ptr);
    }

    /**
        Gets the value of the shared pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT getAtomic() {
        return rc ? cast(VT)atomicLoad(rc.ref_) : null;
    }

    /**
        Gets the value of the shared pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT get() {
        return rc ? cast(VT)rc.ref_ : null;
    }

    /**
        Gets the value of the shared pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT opCast() {
        return rc ? cast(VT)rc.ref_ : null;
    }

    /**
        Makes a weak borrow of the shared pointer,
        weak borrows do not affect whether the object can be deleted by ref count reaching 0.

        weak refs will return null if the ref count reaches 0 of their parent shared pointer.
    */
    @trusted
    weak_ptr!T borrow() {
        return weak_ptr!T(rc);
    }

    /**
        Makes a strong copy of the shared pointer.
    */
    @trusted
    shared_ptr!T copy() {
        return shared_ptr!T(this);
    }

    /**
        Resets the shared_ptr, emptying its contents.
    */
    @trusted
    void reset() {
        if (rc) {
            rc.subRef!false;
            rc = null;
        }
    }

    /**
        Clears the contents of the shared_ptr

        This is an unsafe operation and can lead to memory leaks if used improperly.
    */
    @system
    void clear() {
        if (rc) {
            atomicStore(this.rc, null);
        }
    }

    /**
        Releases a reference
    */
    @system
    void release() {
        if (rc) {
            rc.subRef!false();
        }
    }

    /**
        Adds a reference
    */
    @system
    void retain() {
        if (rc) {
            rc.addRef!false();
        }
    }

    /**
        Gets the amount of strong references to the object
    */
    @trusted
    size_t getRefCount() {
        if (rc) {
            return atomicLoad(rc.strongRefs);
        }
        return 0;
    }

    /**
        Gets the amount of weak references to the object
    */
    @trusted
    size_t getBorrowCount() {
        if (rc) {
            return atomicLoad(rc.weakRefs);
        }
        return 0;
    }
}

/**
    A weak borrowed pointer from a shared_ptr
*/
struct weak_ptr(T) {
nothrow @nogc:

// Special interop public section
public:

    /// Actual value type of the pointer.
    static if (is(T == class)) {
        alias VT = T;
    } else {
        alias VT = T*;
    }

    // Allows accessing members of the unique_ptr
    alias getAtomic this;

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

    /**
        Gets the value of the weak pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT getAtomic() {
        return rc ? cast(VT)atomicLoad(rc.ref_) : null;
    }

    /**
        Gets the value of the weak pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT get() {
        return rc ? cast(VT)rc.ref_ : null;
    }

    /**
        Gets the value of the weak pointer

        Returns null if the item is no longer valid.
    */
    @trusted
    VT opCast() {
        return rc ? cast(VT)rc.ref_ : null;
    }
    

    /**
        Clears the contents of the weak_ptr
    */
    @trusted
    void clear() {
        if (rc) {
            this.rc.subRef!true;
            rc = null;
        }
    }

    /**
        Gets the amount of strong references to the object
    */
    @trusted
    size_t getRefCount() {
        if (rc) {
            return atomicLoad(rc.strongRefs);
        }
        return 0;
    }

    /**
        Gets the amount of weak references to the object
    */
    @trusted
    size_t getBorrowCount() {
        if (rc) {
            return atomicLoad(rc.weakRefs);
        }
        return 0;
    }
}

// Tests whether a shared pointer can be created.
@("shared_ptr: instantiation")
unittest {
    class A { }
    shared_ptr!A p = shared_new!A();
    assert(p.get);
}

// Tests whether a unique pointer can be created.
@("unique_ptr: instantiation")
unittest {
    class A { }
    unique_ptr!A p = unique_new!A();

    assert(p.get);
}

// Tests whether the subtype of a unique pointer can properly be aliased
// and the contents be accessed without .get()
@("unique_ptr: aliasing")
unittest {
    struct A {
        bool b() { return true; }
    }

    unique_ptr!A vp = unique_new!A();
    assert(vp.b() == true, "Expected vp.b() to return true!");
}

// Tests whether unqiue_ptr can be moved via assignment.
@("unique_ptr:move")
unittest {
    struct A { int b; }

    // Assignment via creation
    unique_ptr!A first = unique_new!A();
    assert(first.get(), "Expected first to return non-null value!");

    // Move via creation
    unique_ptr!A second = first;
    assert(!first.get(), "Expected first to return null value!");
    assert(second.get(), "Expected second to return non-null value!");

    // Move via assignment.
    first = second;
    assert(first.get(), "Expected first to return non-null value!");
    assert(!second.get(), "Expected second to return null value!");
}

@("unique_ptr: move to array")
unittest {
    import numem.collections.vector;
    struct A { int b; }

    vector!(unique_ptr!A) uniques;
    uniques ~= unique_new!A();
    uniques ~= unique_new!A();
    uniques ~= unique_new!A();
    uniques ~= unique_new!A();

    auto yoink = uniques[0];
    assert((yoink.get()) && (!uniques[0].get()), "Move failed!");
}



@("nogc_new: struct copy-construct")
unittest {
    struct A {
        int x;
    }

    A a = A(128);
    auto b = nogc_new!A(a);
    b.x = 42;
    
    assert(a.x == 128);
    assert(b.x == 42);
}

@("nogc_new: struct construct")
unittest {
    struct A { int a; }

    auto aa = nogc_new!A(128);
    auto ab = nogc_new!A;

    assert(aa && aa.a == 128);
    assert(ab);
}

@("nogc_new: class construct")
unittest {
    class A { int a; @nogc this(int a) { this.a = a; }}
    class B { int a; @nogc this(int a) { this.a = a; } @nogc this() { this.a = 512; }}

    auto a = nogc_new!A(42);
    assert(a && a.a == 42);


    // This should fail to compile because A has no empty constructor
    assert(!__traits(compiles, { return nogc_new!A; }));

    // However, type B *does* have a default constructor.
    assert(__traits(compiles, { return nogc_new!B; }));
}

@("nogc_delete: free & null")
unittest {
    struct A { int a; }
    class B { int b; @nogc this(int b) { this.b = b; } }

    // Struct
    auto taa = nogc_new!A(42);
    auto tab = A(42);

    // Class
    auto tba = nogc_new!B(42);

    // Basic type
    auto tca = nogc_new!int(42);

    assert(tab.a == 42); // If this fails the D compiler is broken.
    assert(taa && taa.a == 42);
    assert(tba && tba.b == 42);
    assert(tca && *tca == 42);

    nogc_delete(taa);
    nogc_delete(tba);
    nogc_delete(tca);

    assert(!taa);
    assert(!tba);
    assert(!tca);
}