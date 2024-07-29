/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.mem.string;
import numem.mem.vector;
import numem.mem.internal;
import numem.mem;

/// Gets whether the provided type is some type of nstring.
enum isSomeNString(T) = 
    is(T == nstring) || is (T == nwstring) || is(T == ndstring);

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

    /// Gets the type of character stored in the string.
    alias valueType = T;

    /// Destructor
    @trusted
    ~this() {
        if (this.vec_.data()) {
            nogc_delete(this.vec_);
        }
    }

    /**
        Creates a string with specified text
    */
    @trusted
    this(const(T)[] text) {
        this.set_(text);
    }

    // Handle creation from C string
    version(NoC) { }
    else {
        static if (is(T == char)) {

            /**
                Creates a string with specified text
            */
            @system
            this(ref const(char)* text) {
                import core.stdc.string : strlen;
                size_t len = strlen(text);
                this.set_(text[0..len]);
            }
        }
    }

    /**
        Makes a copy of a string
    */
    @trusted
    this(ref return scope basic_string!T rhs) {
        this.vec_ = rhs.vec_;
    }

    /**
        Makes a copy of a string
    */
    @trusted
    this(ref return scope inout(basic_string!T) rhs) inout {
        this.vec_ = rhs.vec_;
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
    inout(T)* toCStringi() inout {
        return cast(inout(T)*)this.vec_.idata();
    }

    /**
        Returns C string
    */
    @trusted
    const(T)* toCString() {
        return cast(const(T)*)this.vec_.data();
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
        Casts nstring to C string
    */
    @trusted
    const(T)* opCast()() {
        return toCString();
    }

    /**
        Casts nstring to D string
    */
    @trusted
    immutable(T)[] opCast()() {
        return toDString();
    }

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
        return this.appendCString(cString);
    }

    /**
        Appends a zero-terminated C string to string
    */
    @system
    ref auto appendCString(const(T)* cString) {
        const(T)[] s = numem.mem.internal.fromStringz(cString);
        if (s != null)
            this.append_(s);
        return this;
    }

    /**
        Override for $ operator
    */
    @trusted
    size_t opDollar() {
        return vec_.size();
    }

    /**
        Slicing operator

        D slices are short lived and may end up pointing to invalid memory if their string is modified.
    */
    @trusted
    const(T)[] opSlice(size_t start, size_t end) {
        return cast(const(T)[])this.vec_[start..end];
    }

    /**
        Allows slicing the string to the full vector
    */
    @trusted
    const(T)[] opIndex() {
        return cast(const(T)[])this.vec_[];
    }

    /**
        Allows slicing the string to get a substring.
    */
    @trusted
    const(T)[] opIndex(size_t[2] slice) {
        return cast(const(T)[])this.vec_[slice[0]..slice[1]];
    }

    /**
        Allows getting a character from the string.
    */
    @trusted
    ref const(T) opIndex(size_t index) {
        return cast(const(T))(this.vec_.data()[index]);
    }

    /**
        Tests equality between nstrings
    */
    @trusted
    bool opEquals(R)(R other) if(is(R == basic_string!T)) {
        return this.length == other.length && this[0..$] == other[0..$];
    }

    /**
        Tests equality between nstrings
    */
    @trusted
    bool opEquals(R)(R other) if(is(R == immutable(T)[])) {
        return this.size == other.length && this[0..$-1] == other[0..$];
    }

    /**
        Allows comparing strings
    */
    @trusted
    int opCmp(S)(ref inout S s) inout if (is(S : basic_string!T)) {
        import core.stdc.string : strncmp;
        if (this.size() < s.size()) return -1;
        if (this.size() > s.size()) return 1;
        return strncmp(this.toCStringi(), s.toCStringi(), this.size());
    }

    /**
        To D string
    */
    alias toString = toDString;
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
    nstring s;
    s ~= cast(string)null;
    s ~= "";
    s.appendCString("a zero-terminated string".ptr);
    assert(s.toDString() == "a zero-terminated string");

    nwstring ws;
    ws.appendCString("hey"w.ptr);
    assert(ws.length == 3);

    ndstring wd;
    wd.appendCString("ho"d.ptr);
    assert(wd.toDString() == "ho"d);
}

@("nstring: string in map")
unittest {
    import numem.mem.map : map;
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