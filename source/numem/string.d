/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.string;
import numem.vector;
import numem;

/**
    Basic string type.

    This string type uses a vector as backing,
    it also automatically adds null-terminators for C interopability.
*/
struct basic_string(T) if (is(T == char) || is(T == dchar) || is(T == wchar)) {
nothrow @nogc:
private:
    vector!(T) vec_;

    void append_(const(T)[] span) {

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
        (cast(T*)vec_.data)[0..span.length] = span[0..$];
        (cast(T*)vec_.data)[this.size()] = '\0';
    }

public:

    ~this() {
        if (this.vec_.data()) {
            nogc_delete(this.vec_);
        }
    }

    /**
        Creates a string with specified text
    */
    this(const(T)[] text) {
        this.set_(text);
    }

    /**
        Makes a copy of a string
    */
    this(ref return scope basic_string!T rhs) {
        this.vec_ = rhs.vec_;
    }

    /**
        Gets the length of the string
    */
    pragma(inline, true)
    size_t size() {
        size_t sz = this.vec_.size();
        return sz > 0 ? sz-1 : sz;
    }

    /**
        Gets the length of the string
    */
    size_t length() {
        return size();
    }

    /**
        Gets the capacity of the string
    */
    size_t capacity() {
        return this.vec_.capacity();
    }

    /**
        Resizes string
    */
    void resize(size_t length) {
        vec_.resize(length+1);
        (cast(T*)vec_.data)[length] = '\0';
    }

    /**
        Reserves space in the string for more characters.
    */
    void reserve(size_t capacity) {
        vec_.reserve(capacity);
    }

    /**
        Clears string
    */
    void clear() {
        this.resize(0);
    }

    /**
        Whether the string is empty.
    */
    bool empty() {
        return size > 0;
    }

    /**
        Shrinks string storage to fit contents
    */
    void shrinkToFit() {
        vec_.shrinkToFit();
    }

    /**
        Returns C string
    */
    const(T)* toCString() {
        return cast(const(T)*)this.vec_.data();
    }

    /**
        Returns a D string from the numemstring
    */
    immutable(T)[] toDString() {
        return cast(immutable(T)[])(this.vec_.data()[0..this.size()]);
    }

    /**
        Casts nstring to C string
    */
    const(T)* opCast()() {
        return toCString();
    }

    /**
        Casts nstring to D string
    */
    immutable(T)[] opCast()() {
        return toDString();
    }

    /**
        Set content of string
    */
    ref auto opAssign(T)(const(T)[] value) {
        this.set_(value);
        return this;
    }

    /**
        Appends value to string
    */
    ref auto opOpAssign(string op = "~", T)(const(T)[] value) {
        this.append_(value);
        return this;
    }

    /**
        Override for $ operator
    */
    size_t opDollar() {
        return vec_.size();
    }

    /**
        Slicing operator

        D slices are short lived and may end up pointing to invalid memory if their string is modified.
    */
    const(T)[] opSlice(size_t start, size_t end) @system {
        return cast(const(T)[])this.vec_[start..end];
    }

    /**
        Allows slicing the string to the full vector
    */
    const(T)[] opIndex() {
        return cast(const(T)[])this.vec_[];
    }

    /**
        Allows slicing the string to get a substring.
    */
    const(T)[] opIndex(size_t[2] slice) {
        return cast(const(T)[])this.vec_[slice[0]..slice[1]];
    }

    /**
        Allows getting a character from the string.
    */
    ref const(T) opIndex(size_t index) {
        return cast(const(T))(this.vec_.data()[index]);
    }

    static if (is(T == char)) {
        string toString() {
            return toDString();
        }
    }
}

alias nstring = basic_string!char;
alias nwstring = basic_string!wchar;
alias ndstring = basic_string!dchar;