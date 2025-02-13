/**
    Essential tools for nothrow.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.exception;
import numem.core.memory;
import numem.core.hooks;
import numem.core.traits;
import numem.lifetime : nogc_delete, nogc_new;

/**
    Assumes that a given function or delegate does not throw.

    Params:
        expr =  The expression to execute.
        args =  Arguments to pass to the function.
*/
auto assumeNoThrow(T, Args...)(T expr, Args args) @nogc nothrow if (isSomeFunction!T)  {
    try {
        return expr(args);
    } catch (Exception ex) {
        nu_fatal(ex.msg);
        assert(0);
    }
}

/**
    Assumes that a given function or delegate does not throw.

    Params:
        expr =  The expression to execute.
        args =  Arguments to pass to the function.
*/
auto assumeNoThrowNoGC(T, Args...)(T expr, Args args) @nogc nothrow if (isSomeFunction!T)  {
    try {
        return assumeNoGC(expr, args);
    } catch (Exception ex) {
        nu_fatal(ex.msg);
        assert(0);
    }
}

/**
    Assumes that the provided function does not use
    the D garbage collector.

    Params:
        expr =  The expression to execute.
        args =  Arguments to pass to the function.
*/
auto assumeNoGC(T, Args...)(T expr, Args args) @nogc if (isSomeFunction!T) {
    static if (is(T == function))
        alias ft = @nogc ReturnType!T function(Parameters!T);
    else
        alias ft = @nogc ReturnType!T delegate(Parameters!T);
    
    return (cast(ft)expr)(args);
}

/**
    An exception which can be thrown from numem
*/
class NuException : Exception {
public:
@nogc:

    ~this() {
        // Free message.
        msg.nu_resize(0);

        // Free next-in-chain
        if (Throwable t = this.next()) {
            nogc_delete(t);
        }
    }

    /**
        Constructs a nogc exception
    */
    this(const(char)[] msg, Throwable nextInChain = null, string file = __FILE__, size_t line = __LINE__) {
        super(cast(string)msg.nu_dup(), nextInChain, file, line);
    }

    /**
        Returns the error message
    */
    override
    const(char)[] message() const @safe nothrow {
        return this.msg;
    }

    /**
        Helper function to free this exception
    */
    @trusted
    void free() {
        NuException ex = this;
        nogc_delete(ex);
    }
}

/**
    Enforces the truthiness of $(D in_)

    If it evaluates to false, throws a $(D NuException).
*/
void enforce(T)(T in_, const(char)[] err) @nogc @trusted {
    if (!in_) {
        throw nogc_new!NuException(err);
    }
}

/**
    Enforces the truthiness of $(D in_)

    If it evaluates to false, throws a $(D NuException).
*/
void enforce(T)(T in_, NuException t) @nogc @trusted {
    if (!in_) {
        throw t;
    }
}