/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.string;
import numem.core.hooks;
import numem.collections.vector;
import numem.core;
import std.string;
import std.traits;
import core.stdcpp.string;
import std.traits : Unqual, hasFunctionAttributes;

// Objective-C support
version(Have_objective_d) import foundation.nsstring : NSString;

/// Gets whether the provided type is some type of string.
enum isSomeString(T) =
    isSomeSafeString!T ||
    isSomeCString!T;

/**
    Gets whether the provided type is some type of string
    which is length denoted and therefore "safe"
*/
enum isSomeSafeString(T) =
    isSomeNString!T ||
    isSomeDString!T;


/// Gets whether the provided type is some type of nstring.
enum isSomeNString(T) = 
    is(inout(T) == inout(basic_string!C), C) && isSomeChar!C;

/// Gets whether the provided type is some type of null terminated C string.
enum isSomeCString(T) =
    is(T == C*, C) && isSomeChar!C;

/// Gets whether the provided type is some type of D string slice.
enum isSomeDString(T) =
    is(immutable(T) == immutable(C[]), C) && isSomeChar!C;

/// Gets whether the provided type is a character
enum isSomeChar(T) =
    is(T : char) || is(T : wchar) || is(T : dchar);

/**
    Gets whether [T] is convertible to any form of [nstring]
*/
enum isStringable(T) = 
    __traits(hasMember, T, "toString") &&
    isSomeString!(ReturnType!(T.toString)) &&
    hasFunctionAttributes!(T.toString, "@nogc");

/**
    Gets the size of the element in a string-ish type in bytes.
*/
enum StringCharSize(T) =
    StringCharType!T.sizeof;

/**
    Gets the type of the element in a string-ish type.
*/
template StringCharType(T) {
    static if (isSomeString!T) {
        static if(isSomeNString!T)
            alias StringCharType = Unqual!(T.valueType);
        else
            alias StringCharType = Unqual!(typeof(T.init[0].init));
    } else {
        alias StringCharType = void;
    }
}

/**
    Basic string type.

    This string type uses a vector as backing,
    it also automatically adds null-terminators for C interopability.
*/
struct basic_string(T) if (is(T == char) || is(T == dchar) || is(T == wchar)) {
nothrow @nogc:
private:
    alias selfType = basic_string!T;
    weak_vector!T vec_;

    void append_(const(T)[] span) {
        if (span.length == 0) return;

        // If size of string is > 0, then it should have the null terminator.
        size_t baseSize = size();

        // First resize vector to fit the new span + null terminator.
        vec_.resize(baseSize+span.length+1);

        // append text, then add null terminator after.
        (cast(T*)vec_.data)[baseSize..baseSize+span.length] = span[0..$];
        (cast(T*)vec_.data)[this.size()] = '\0';
    }

    void set_(const(T)[] span) {
        vec_.resize(span.length+1);
        vec_.tryReplaceRange(span[0..$], 0);
        vec_[this.size()] = '\0';
    }

public:

    /// Gets the type of character stored in the string.
    alias valueType = T;

    /// Destructor
    @trusted
    ~this() {
        if (this.ptr) {
            nogc_delete(this.vec_);
        }
    }

    /**
        Creates a string with a predefined length.

        The contents are undefined.
    */
    @trusted
    this(size_t length) {
        this.resize(length);
    }

    /**
        Creates a string from a C string

        This is considered unsafe.
    */
    @system
    this(inout(T)* text) {
        this.set_(text.fromStringz());
    }

    /**
        Creates a string with specified text
    */
    @trusted
    this(const(T)[] text) {
        this.set_(text);
    }

    /**
        Creates a string from a slice of strings.
    */
    @trusted
    this(const(T)[][] text) {
        foreach(i; 0..text.length) {
            this.append_(text[i]);
        }
    }

    version(Have_objective_d)
    static if (is(T == char)) {

        /**
            Creates a string from an Objective-C NSString.

            This will release 1 reference from the NSString.
        */
        this(NSString str) {
            this.set_(str.toString());
            str.release();
        }

        /**
            To Objective-C NSString
        */
        NSString toNSString() {
            return NSString.create(ptr);
        }
    }

    /**
        Creates a string from a string with a different
        encoding.
    */
    this(T)(ref auto T rhs) if (isSomeSafeString!T) {
        import numem.text.unicode : decode, encode;
        this = encode!selfType(decode!T(rhs, true));
    }

    /**
        Creates a string from a slice of strings with a different
        encoding.
    */
    this(T)(ref auto T[] rhs) if (isSomeSafeString!T) {
        foreach(i; 0..rhs.length) {
            import numem.text.unicode : decode, encode;
            this = encode!selfType(decode!T(rhs[i], true));
        }
    }

    /**
        Makes a copy of a string
    */
    @trusted
    this(ref return scope inout(selfType) rhs) inout {
        if (rhs.size > 0) {

            // NOTE: We need to turn these into pointers because
            // The D compiler otherwise thinks its supposed
            // to free the operands.
            selfType* self = (cast(selfType*)&this);
            selfType* other = (cast(selfType*)&rhs);
            (*self).set_((*other)[]);
        }
    }

    /**
        Gets the length of the string
    */
    @trusted
    pragma(inline, true)
    size_t size() inout {
        size_t sz = this.vec_.size();
        return sz > 0 ? sz-1 : sz;
    }

    /**
        Gets the length of the string
    */
    @trusted
    size_t length() inout {
        return size();
    }

    /**
        Gets the length of the string including null-terminator
    */
    @trusted
    size_t realLength() inout {
        return this.vec_.size();
    }

    /**
        Gets the capacity of the string
    */
    @trusted
    size_t capacity() inout {
        return this.vec_.capacity();
    }

    /**
        Resizes string
    */
    @trusted
    void resize(size_t length) {
        vec_.resize(length+1);
        (cast(T*)vec_.data)[length] = '\0';
    }

    /**
        Reserves space in the string for more characters.
    */
    @trusted
    void reserve(size_t capacity) {
        vec_.reserve(capacity);
    }

    /**
        Clears string
    */
    @trusted
    void clear() {
        this.resize(0);
    }

    /**
        Whether the string is empty.
    */
    @trusted
    bool empty() inout {
        return size == 0;
    }

    /**
        Shrinks string storage to fit contents
    */
    @trusted
    void shrinkToFit() {
        vec_.shrinkToFit();
    }

    /**
        Returns C string
    */
    immutable(T)* toCString() immutable {
        return this.vec_.data();
    }

    /**
        Returns C string
    */
    @trusted
    const(T)* toCString() const {
        return this.vec_.data();
    }

    /**
        Returns pointer to string data.
    */
    alias ptr = toCString;

    /**
        Returns a D string from the numemstring
    */
    @trusted
    immutable(T)[] toDString() {
        return cast(immutable(T)[])(this.vec_.data()[0..this.size()]);
    }

    /**
        To D string
    */
    alias toString = toDString;

    /**
        Set content of string
    */
    @trusted
    ref auto opAssign(T)(const(T)[] value) {
        this.set_(value);
        return this;
    }

    /**
        Appends value to string
    */
    @trusted
    ref auto opOpAssign(string op = "~", T)(const(T)[] value) {
        this.append_(value);
        return this;
    }

    /**
        Appends single character to string
    */
    @trusted
    ref auto opOpAssign(string op = "~")(T ch) {
        const(T)[] asSlice = (&ch)[0..1];
        this.append_(asSlice);
        return this;
    }

    /**
        Appends another nstring to string
    */
    @trusted
    ref auto opOpAssign(string op = "~")(basic_string!T s) {
        this.append_(s[]);
        return this;
    }

    /**
        Appends a zero-terminated C string to string
    */
    @system
    ref auto opOpAssign(string op = "~")(const(T)* cString) {
        return this.opOpAssign(cString.fromStringz());
    }

    /**
        Override for $ operator
    */
    @trusted
    size_t opDollar() {
        return this.size();
    }

    /**
        Reverses the string, this function is NOT unicode aware.
    */
    @trusted
    void reverse() {
        foreach(i; 0..this.size()/2) {
            size_t j = this.size()-i-1;
        
            T c = vec_.data[i];

            // Swap
            vec_.data[i] = vec_.data[j];
            vec_.data[j] = c;
        }
    }

    /**
        Slicing operator

        D slices are short lived and may end up pointing to invalid memory if their string is modified.
    */
    @trusted
    inout(T)[] opSlice(size_t start, size_t end) inout {
        return cast(inout(T)[])this.vec_[start..end];
    }

    /**
        Allows slicing the string to the full vector
    */
    @trusted
    inout(T)[] opIndex() inout {
        return cast(inout(T)[])this.vec_[0..this.size()];
    }

    /**
        Allows slicing the string to get a substring.
    */
    @trusted
    inout(T)[] opIndex(size_t[2] slice) inout {
        return cast(inout(T)[])this.vec_[slice[0]..slice[1]];
    }

    /**
        Allows getting a character from the string.
    */
    @trusted
    ref inout(T) opIndex(size_t index) inout {
        return cast(inout(T))(this.vec_.data()[index]);
    }

    /**
        Tests equality between strings
    */
    @trusted
    bool opEquals(R)(ref auto inout R other) inout if (isSomeString!R) {
        static if (isSomeCString!R)
            size_t len = cstrlen(other);
        else
            size_t len = other.length;
        
        return this.length == len && this[0..len] == other[0..len];
    }

    /**
        Allows comparing strings
    */
    @trusted
    int opCmp(S)(ref inout S s) inout if (is(S : basic_string!T)) {
        import core.stdc.string : strncmp;
        if (this.size() < s.size()) return -1;
        if (this.size() > s.size()) return 1;
        return strncmp(this.toCString(), s.toCString(), this.size());
    }

    /**
        Makes a copy of the string as a C string which is not owned
        by any numem object.

        You are responsible for freeing the resulting string.
    */
    @system
    const(T)* copyToUnowned() {
        import core.stdc.string : memcpy;
        import core.stdc.stdlib : malloc;
        size_t buflen = T.sizeof * this.realLength;

        const(T)* str = cast(const(T)*)nuAlloc(buflen);
        nuMemcpy(cast(void*)str, cast(void*)this.ptr, buflen);
        return str;
    }
}

alias nstring = basic_string!char;
alias nwstring = basic_string!wchar;
alias ndstring = basic_string!dchar;

@("nstring: char append")
unittest {
    // appending a char
    nstring s;
    nwstring ws;
    ndstring ds;
    s  ~= 'c';
    ws ~= '\u4567';
    ds ~= '\U0000ABCD';
    assert(s.toDString() == "c" 
       && ws.toDString() == "\u4567"w 
       && ds.toDString() == "\U0000ABCD"d);

    // Not working yet: append to itself
    //s ~= s;
    //assert(s.toDString() == "cc");
}

@("nstring: append")
unittest {
    const(char)* cstr1 = "a zero-terminated string";
    const(wchar)* cstr2 = "hey";
    const(dchar)* cstr3 = "ho";

    nstring s;
    s ~= cast(string)null;
    s ~= "";
    s ~= cstr1;
    assert(s.toDString() == "a zero-terminated string");

    nwstring ws;
    ws ~= cstr2;
    assert(ws.length == 3);

    ndstring wd;
    wd ~= cstr3;
    assert(wd.toDString() == "ho"d);
}

@("nstring: string in map")
unittest {
    import numem.collections.map : map;
    map!(nstring, int) kv;
    kv[nstring("uwu")] = 42;

    assert(kv[nstring("uwu")] == 42);
}

@("nstring: length")
unittest {
    nstring str = "Test string";
    assert(str.size() == 11);
    assert(str.length() == 11);
    assert(str.realLength() == 12);
}

@("nstring: emptiness")
unittest {
    nstring str;

    assert(str.empty());

    // Should add null terminator.
    str.clear();
    assert(str.empty);
    assert(str.realLength == 1 && str[0] == '\0');
}

//
//      C and D string handling utilities
//

@nogc pure nothrow {

    /**
        Gets a slice from a C string
    */
    inout(T)[] fromStringz(T)(inout(T)* cString) if (isSomeChar!T)  {
        return cString ? cString[0 .. cstrlen!T(cString)] : null;
    }

    /**
        Gets the length of a C-style string
    */
    size_t cstrlen(T)(inout(T)* s) if (isSomeChar!T)  {
        const(T)* p = s;
        while (*p)
            ++p;
        
        return p - s;
    }
}

@("string: cstrlen")
unittest {
    const(char)* cstr1 = "A";
    const(char)* cstr2 = "ABCD";
    assert(cstrlen(cstr1) == 1);
    assert(cstrlen(cstr2) == 4);
}

@("string: vector-of-strings")
unittest {
    vector!nstring strings;
    strings ~= nstring("a");
    strings ~= nstring("b");

    vector!nstring copy = strings;
    nogc_delete(copy);

    assert(strings[0] == "a");
    assert(strings[1] == "b");

    assert(copy.size() == 0);
}

@("string: map-of-strings")
unittest {
    import numem.collections.map;
    map!(uint, nstring) strings;
    strings[0] = nstring("a");
    strings[1] = nstring("b");

    assert(strings[0] == "a");
    assert(strings[1] == "b");
}

version(unittest) {
    struct MyStruct {
    @nogc:
        nstring str;
    }
}

@("string: struct-with-strings")
unittest {
    import std.stdio : writeln;

    vector!MyStruct struct_;
    struct_ ~= MyStruct(nstring("a"));
    struct_ ~= MyStruct(nstring("b"));

    vector!MyStruct copy = struct_;
    nogc_delete(copy);

    assert(struct_[0].str == "a");
    assert(struct_[1].str == "b");

    assert(copy.size() == 0);
}

@("string: encoding-conversion")
unittest {
    nwstring wstr = "Hello, world!"w;
    nstring str = wstr;

    assert(str == "Hello, world!");
}