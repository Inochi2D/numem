/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    Numem Exception support
*/
module numem.core.exception;
import numem.string;
import numem.core;

import core.stdc.stdio;
import numem.core.trace;

@nogc:

/**
    An exception which can be thrown from numem
*/
class NuException : Exception {
@nogc:
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
    this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__) {
        this(nstring(msg), nextInChain, file, line);
    }

    /**
        Constructs a nogc exception
    */
    this(nstring msg, string file = __FILE__, size_t line = __LINE__) {
        this(msg, null, file, line);
    }

    /**
        Constructs a nogc exception
    */
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        this(nstring(msg), null, file, line);
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
    @trusted
    void free() {
        NuException ex = this;
        nogc_delete(ex);
    }
}

/**
    nogc range exception.
*/
class NuRangeException : NuException {
@nogc:
public:
    import numem.format : format;

    /**
        Constructor
    */
    this(nstring str, string file = __FILE__, size_t line = __LINE__) {
        super(str, file, line);
    }

    /**
        Creates an index-out-of-range exception
    */
    static NuRangeException indexOutOfRange(size_t index, string file = __FILE__, size_t line = __LINE__) {
        return nogc_new!NuRangeException("Index {0} is out of range!".format(index), file, line);
    }

    /**
        Creates a slice index-out-of-range exception
    */
    static NuRangeException sliceOutOfRange(size_t start, size_t end, string file = __FILE__, size_t line = __LINE__) {
        return nogc_new!NuRangeException("Slice {0}..{1} is out of range!".format(start, end), file, line);
    }

    /**
        Creates a slice length mismatch exception
    */
    static NuRangeException sliceLengthMismatch(size_t slice1, size_t slice2, string file = __FILE__, size_t line = __LINE__) {
        return nogc_new!NuRangeException("Length of slices are mismatched! ({0} vs {1})".format(slice1, slice2), file, line);
    }
}

/**
    Enforces the truthiness of [in_]

    If it evaluates to false, throws a [NuException].
*/
void enforce(T)(T in_, string err) {
    if (!in_) {
        throw nogc_new!NuException(nstring(err));
    }
}


/**
    Enforces the truthiness of [in_]

    If it evaluates to false, throws a [NuException].
*/
void enforce(T)(T in_, nstring err) {
    if (!in_) {
        throw nogc_new!NuException(err);
    }
}


/**
    Enforces the truthiness of [in_]

    If it evaluates to false, throws a [NuException].
*/
void enforce(T)(T in_, lazy NuException t) {
    if (!in_) {
        throw t;
    }
}

@("NuException: catching")
unittest {
    auto str = nstring("Ooops!");
    try {
        enforce(false, str);
    } catch(NuException ex) {
        assert(ex.message() == str.toDString());

        ex.free();
    }
}