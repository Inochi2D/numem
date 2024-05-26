/**
    Numem Exception support
*/
module numem.mem.exception;
import numem.mem.string;
import numem.mem;
import core.stdc.stdio;
import numem.mem.internal.trace;

@nogc:

/**
    An exception which can be thrown from numem
*/
class NuException : Exception {
nothrow @nogc:
private:
    nstring _msg;

public:

    ~this() {
        nogc_delete(_msg);

        // Free next-in-chain
        Throwable t = this.next();
        nogc_delete(t);
    }

    /**
        Constructs a nogc exception
    */
    this(nstring msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__) {
        this._msg = msg;
        super(this._msg.toDString(), nextInChain, file, line);
    }

    /**
        Constructs a nogc exception
    */
    this(nstring msg, string file = __FILE__, size_t line = __LINE__) {
        this(msg, null, file, line);
    }

    /**
        Returns the error message
    */
    override
    @__future const(char)[] message() const @safe nothrow {
        return this.msg;
    }

    /**
        Helper function to free this exception
    */
    void free() {
        NuException ex = this;
        nogc_delete(ex);
    }
}

/**
    Enforces the truthiness of a nstring
*/
void enforce(T)(T in_, nstring err) {
    if (!in_) {
        throw nogc_new!NuException(err);
    }
}

/**
    Enforces the truthiness of a nstring
*/
void enforce(T)(T in_, lazy NuException t) {
    if (!in_) {
        throw t;
    }
}

@("Test catching exceptions")
unittest {
    auto str = nstring("Ooops!");
    try {
        enforce(false, str);
    } catch(NuException ex) {
        assert(ex.message() == str.toDString());

        ex.free();
    }
}