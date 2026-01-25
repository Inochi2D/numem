/**
    Numem Rc Type
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:    Luna Nielsen
*/
module numem.rc;
import numem.core.lifetime;
import numem.core.hooks;
import numem.core.traits;
import numem.lifetime;

/**
    A semi-automatically reference counted value container.
*/
struct Rc(T) {
private:
@nogc:
    alias RCT = __rc!T;
    RCT* rc;

    pragma(inline, true)
    void __retain() @trusted {
        if (rc) {
            nu_atomic_add_32(rc.refs, 1);
        }
    }

    pragma(inline, true)
    void __release() @trusted {
        if (rc) {
            if (nu_atomic_sub_32(rc.refs, 1) == 1) {
                nogc_trydelete(rc.value);
                nu_free(rc);

            }
        }
        this.rc = null;
    }

public:
    alias value this;

    /**
        Whether the RC value is valid.
    */
    @property bool isValid() inout nothrow @safe => rc !is null;

    /**
        The value stored in the rc type.
    */
    @property ref inout(T) value() inout nothrow @safe => cast(inout(T))rc.value;

    /// Destructor
    ~this() {
        this.__release();
    }

    /**
        Creates an reference counted object using given $(D value),
        if value is given by reference, it is moved to the Rc.

        Params:
            value = The value.
    */
    this(in inout(T) value) @trusted {
        RCT* rc = cast(RCT*)nu_malloc(RCT.sizeof);
        rc.value = cast(T)value;
        rc.refs = 1;

        nu_atomic_store_ptr(cast(void**)&this.rc, rc);
    }

    /**
        Copy constructor
    */
    this(ref return scope inout(typeof(this)) rhs) @trusted {
        this.rc = cast(RCT*)rhs.rc;
        this.__retain();
    }

    /**
        Retains a reference to the stored value.
    */
    auto ref retain()() @trusted {
        this.__retain();
        return this;
    }

    /**
        Releases a reference to the stored value.
        This invalidates the Rc instance.
    */
    auto ref release()() @trusted {
        this.__release();
        return this;
    }

    /**
        Implements implicit cast for RC value validity.
    */
    T opCast(T : bool)() inout nothrow @safe => isValid();

    /**
        Implements base cast
    */
    ref T opCast(T : typeof(this))() inout nothrow {
        return *(cast(T*)(cast(void**)&rc.value));
    }
}

//
//          IMPLEMENTATION DETAILS
//
private:

struct __rc(T) {
private:
@nogc:
    uint refs;
    T value;
}