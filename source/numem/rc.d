/**
    Numem Rc Type
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:    Luna Nielsen
*/
module numem.rc;
import numem.core.hooks;
import numem.lifetime;

/**
    A reference counted container.
*/
struct Rc(T) {
public:
@nogc:
    mixin RcBase!T;

    /**
        Creates an reference counted object using given $(D value).

        Params:
            value = The value.
    */
    this(T value) @trusted {
        this.rc = nogc_new!__rc(1, value);
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
}

/**
    Automatically reference counted value.
*/
struct Arc(T) {
public:
@nogc:
    mixin RcBase!T;

    /// Destructor
    ~this() {
        this.__release();
    }

    /**
        Creates an reference counted object using given $(D value).

        Params:
            value = The value.
    */
    this(T value) @trusted {
        this.rc = nogc_new!__rc(1, value);
    }

    /**
        Copy constructor
    */
    this(ref return scope inout(typeof(this)) rhs) inout @trusted {
        this.rc = rhs.rc;
        (cast(Arc!T)this).__retain();
    }
}

// Base RefCounted.
private mixin template RcBase(T) {
private:
@nogc:
    static struct __rc {
    private:
    @nogc:
        uint refs;
        T value;
    }

    __rc* rc;

    pragma(inline, true)
    void __retain() @trusted nothrow {
        if (rc) {
            nu_atomic_add_32(rc.refs, 1);
        }
    }

    pragma(inline, true)
    void __release() @trusted nothrow {
        if (rc) {
            if (nu_atomic_sub_32(rc.refs, 1) == 1) {
                nogc_delete(rc.value);
                nu_free(rc);
            }
        }
        this.rc = null;
    }

public:
    alias value this;

    /**
        The value stored in the rc type.
    */
    @property T value() @safe => rc ? rc.value : T.init;
}