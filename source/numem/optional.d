/**
    Numem Optional type

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.optional;
import numem.lifetime;
import numem.core.traits;
import numem.core.hooks;

/**
    A struct which wraps a value and whether said value is "valid".

    Example:
        ---
        Option!int positiveOnly(int value) @nogc nothrow {
            return value >= 0 ? some(value) : none!int();
        }

        auto rval = positiveOnly(4);
        if (rval) {
            writeln("Value is positive!");
        } else {
            writeln("Value is negative!");
        }
        ---
*/
struct Option(T) {
private:
@nogc:
    static if (isHeapAllocated!T) {
        T value_ = T.init;
    } else {
        bool state_ = false;
        T value_ = T.init;
    }

    // Constructors
    this(Y)(Y value) nothrow {
        static if (isHeapAllocated!T) {
            this.value_ = cast(T)cast(void*)value;
        } else static if (is(Y == T)) {
            this.value_ = value;
            this.state_ = true;
        } else {
            this.state_ = false;
        }
    }

public:
    alias hasValue this; // Allows using optional in if statements.
    @disable this();

    /**
        Wraps $(D value) in an optional type.

        Params:
            value = The value to wrap.

        Returns:
            The wrapped value.
    */
    static Option!T some(T value) @trusted nothrow {
        return Option!T(value);
    }

    /**
        Creates a new empty value.

        Returns:
            The wrapped value.
    */
    static Option!T none() {
        return Option!T(null);
    }

    /**
        Whether this instance contains a valid value.
    */
    @property bool hasValue() @trusted pure nothrow {
        static if (isHeapAllocated!T)
            return value_ !is null;
        else 
            return state_;
    }

    /**
        Destroys the contained value.
    */
    void reset() @trusted nothrow {
        static if (isHeapAllocated!T) {
            static if (hasAnyDestructor!T)
                nogc_trydelete(this.value_);
            else {
                nu_free(this.value_);
            }
            this.value_ = null;

        } else {
            nogc_initialize(value_);
            state_ = false;
        }
    }

    /**
        Gets the value stored within the Optional.

        Returns:
            The value stored within the Optional,
            throws a $(D NuException) if the Optional is invalid.
    */
    T get() @trusted {
        if (!hasValue)
            nu_fatal("No value contained within optional!");
        
        return value_;
    }

    /**
        Gets the value stored within the Optional if valid,
        otherwise returns the given value.

        Params:
            value = The value to return if the optional is invalid.

        Returns:
            The value stored within the Optional,
            $(D value) otherwise.
    */
    T getOr(T value = T.init) @trusted nothrow {
        return hasValue ? value_ : value;
    }
}

/**
    Wraps value in an Optional type.

    Params:
        value = The value to wrap
    
    Returns:
        The value wrapped in an optional type.
        $(D null) values will be seen as invalid.
*/
auto ref Option!T some(T)(auto ref T value) @trusted @nogc nothrow {
    return Option!(T).some(value);
}

/**
    Creates a "none" optional value type.
    
    Returns:
        An optional wrapped "none" type.
*/
Option!T none(T)() @trusted @nogc nothrow {
    return Option!(T).none();
}

/**
    A type which wraps a value and a potential error.
*/
struct Result(T) {
private:
@nogc:
    string error_ = "Generic error";
    T value_;

public:
    alias isOK this; // Allows using Result in if statements.

    /**
        Whether the result is successful.
    */
    @property bool isOK() @trusted nothrow pure => error_.length == 0;

    /**
        The error stored within the Result.
    */
    @property string error() => error_;

    /**
        Creates an "ok" value.

        Params:
            value = The value to set
        
        Returns:
            A new result.
    */
    static typeof(this) makeOk(T value) @trusted nothrow {
        return typeof(this)(value_: value, error_: null);
    }

    /**
        Creates an error value.

        Params:
            message = An UTF-8 encoded error message.
        
        Returns:
            A new result.
    */
    static typeof(this) makeError(string message) @trusted nothrow {
        return typeof(this)(error_: message);
    }

    /**
        Gets the value stored within the Result.

        Returns:
            The value stored within the Result,
            otherwise the application will crash with a fatal error.
    */
    T get() @trusted nothrow {
        if (error_.length > 0)
            nu_fatal(error_);
        
        return value_;
    }

    /**
        Gets the value stored within the Result if non-error,
        otherwise returns the given value.

        Params:
            value = The value to return if the Result is an error.

        Returns:
            The value stored within the Result,
            $(D value) otherwise.
    */
    T getOr(T value = T.init) @trusted nothrow {
        return isOK ? value_ : value;
    }
}

/**
    Wraps a value into a $(D Result).

    Params:
        value = The value to wrap
    
    Returns:
        The value wrapped into a $(D Result)
*/
auto ref Result!T ok(T)(auto ref T value) @trusted @nogc nothrow {
    return Result!(T).makeOk(value);
}

/**
    Creates an error result.
    
    Params:
        message = The error message of the Result.

    Returns:
        A wrapped error.
*/
Result!T error(T)(string message) @trusted @nogc nothrow {
    return Result!(T).makeError(message);
}