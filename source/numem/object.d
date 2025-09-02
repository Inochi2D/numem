/**
    Numem Base Classes.
    
    Copyright:
        Copyright © 2000-2011, The D Language Foundation.
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:    Luna Nielsen, Walter Bright, Sean Kelly

    See_Also:
        $(D numem.core.memory.nu_resize)
        $(D numem.core.memory.nu_dup)
        $(D numem.core.memory.nu_idup)
*/
module numem.object;
import numem.lifetime;
import numem.core.exception;
import numem.core.lifetime : nu_autorelease;
import numem.core.traits;
import numem.core.hooks;

/**
    Numem base-class which allows using basic class functions without a garbage
    collector.
*/
class NuObject {
@nogc:
private:

    TypeInfo_Class getClassInfo() {
        return cast(TypeInfo_Class)typeid(this);
    }

public:

    /**
        Gets the name of the class.

        Returns:
            Name of class based on its compile-time generated typeid.
    */
    override
    string toString() {
        return getClassInfo().name;
    }

    /**
        Test whether $(D this) is equal to $(D other).

        Default implementation only checks whether they are stored at the same
        memory address.
    */
    override
    bool opEquals(const Object other) nothrow const {
        return this is other;
    }

    /**
        Compare with another Object $(D other).
        
        Returns:
            $(TABLE
                $(TR $(TD this < obj) $(TD < 0))
                $(TR $(TD this == obj) $(TD 0))
                $(TR $(TD this > obj) $(TD > 0))
            )

        Notes:
            If you are combining this with a compacting garbage collector,
            it will prevent it from functioning properly.
    */
    override
    int opCmp(const Object other) nothrow const {
        return cast(int)cast(void*)this - cast(int)cast(void*)other;
    }

    /**
        Compute a hash for Object.
    */
    override
    size_t toHash() @trusted nothrow {

        // Address of ourselves.
        size_t addr = cast(size_t)cast(void*)this;

        // The bottom log2((void*).alignof) bits of the address will always
        // be 0. Moreover it is likely that each Object is allocated with a
        // separate call to malloc. The alignment of malloc differs from
        // platform to platform, but rather than having special cases for
        // each platform it is safe to use a shift of 4. To minimize
        // collisions in the low bits it is more important for the shift to
        // not be too small than for the shift to not be too big.
        return addr ^ (addr >>> 4);
    }

}

/**
    A reference counted class.

    Reference counted classes in numem are manually reference counted,
    this means that you are responsible for managing synchronising
    $(D retain) and $(D release) calls.

    Threadsafety:
        Threadsafety depends on whether the hookset used supports
        atomic operations; see $(D numem.core.atomic.nu_atomic_supported).
        If unsupported, retain and release will not be threadsafe on their own,
        and should be wrapped in another synchronisation primitive.

    Memorysafety:
        Once the reference count for a class reaches 0, it will be destructed
        and freed automatically. All references to the class after refcount
        reaches 0 will be invalid and should not be used.
        $(D NuRefCounted.release) returns a value which can be used to determine whether
        the destructor was invoked.
*/
@nu_autoreleasewith!((ref obj) { obj.release(); })
class NuRefCounted : NuObject {
@nogc:
private:
    uint refcount = 0;

public:

    /**
        The current reference count of the object.
    */
    final @property uint refs() => nu_atomic_load_32(refcount);

    /**
        Base constructor, all subclasses *have* to invoke this constructor.
        Otherwise the instance will be invalid on instantiation.
    */
    this() @safe {
        refcount = 1;
    }

    /**
        Retains a reference to a valid object.

        Notes:
            The object validity is determined by the refcount.
            Uninitialized refcounted classes will be invalid.
            As such, releasing an invalid object will not
            invoke the destructor of said object.
    */
    final
    NuRefCounted retain() @trusted nothrow {
        if (isValid)
            nu_atomic_add_32(refcount, 1);
        
        return this;
    }

    /**
        Releases a reference from a valid object.

        Notes:
            The object validity is determined by the refcount.
            Uninitialized refcounted classes will be invalid.
            As such, releasing an invalid object will not
            invoke the destructor of said object.

        Returns:
            The class instance release was called on, $(D null) if
            the class was freed.
    */
    final
    NuRefCounted release() @trusted {
        if (isValid) {
            nu_atomic_sub_32(refcount, 1);

            // Handle destruction.
            if (nu_atomic_load_32(refcount) == 0) {
                NuRefCounted self = this;
                nogc_delete(self);
                return null;
            }
        }

        return this;
    }

    /**
        Pushes this refcounted object to the topmost auto release pool.

        Returns:
            The class instance release was called on.
    */
    final
    NuRefCounted autorelease() @trusted {
        nu_autorelease!NuRefCounted(this);
        return this;
    }

    /**
        Returns whether this object is valid.

        Notes:
            The object validity is determined by the refcount.
            Uninitialized refcounted classes will be invalid.
            As such, releasing an invalid object will not
            invoke the destructor of said object.

        Returns:
            Whether the object is valid (has a refcount higher than 0)
    */
    final
    bool isValid() @trusted nothrow {
        return nu_atomic_load_32(refcount) != 0;
    }
}

/**
    Helper function which allows typed chaining of retain calls.

    Params:
        elem = The element to perform the operation on
    
    Returns:
        The element or $(D null) if it was freed as a result
        of the operation.
*/
T retained(T)(T elem) @nogc @trusted if (isRefcounted!T) {
    import numem.core.memory : nu_retain;
    return cast(T)elem.nu_retain();
}

/// ditto
T released(T)(T elem) @nogc @trusted if (isRefcounted!T) {
    import numem.core.memory : nu_release;
    return cast(T)elem.nu_release();
}

/// ditto
T autoreleased(T)(T elem) @nogc @trusted if (is(T : NuRefCounted)) {
    return cast(T)elem.autorelease();
}