module numem.string;
import numem.vector;
import numem;

/**
    Basic string type.

    This string type uses a vector as backing,
    it also automatically adds null-terminators for C interopability.
*/
struct basic_string(T) if (is(T == char) || is(T == dchar) || is(T == wchar)) {
private:
    vector!(T) vec_;

    void append_(immutable(T)[] charSpan) {

        // If size of string is > 0, then it should have the null terminator.
        size_t baseSize = vec_.size();
        if (baseSize > 0) baseSize--;

        // First resize vector to fit the new span + null terminator.
        vec_.resize(baseSize+charSpan.length+1);

        // append text, then add null terminator after.
        (cast(T*)vec_.data)[baseSize..baseSize+charSpan.length] = charSpan[0..$];
        (cast(T*)vec_.data)[vec_.size] = '\0';
    }

    void set_(immutable(T)[] charSpan) {
        vec_.resize(charSpan.length);
        (cast(T*)vec_.data)[0..charSpan.length] = charSpan[0..$];
    }

public:

    ~this() {
        nogc_delete(vec_);
    }

    /**
        Creates a string with specified text
    */
    this(immutable(T)[] text) {
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
        Casts nstring to C string
    */
    immutable(T)[] opCast()() {
        return toDString();
    }

    /**
        Set content of string
    */
    auto opAssign(T)(immutable(T)[] value) {
        this.set_(value);
        return this;
    }

    /**
        Appends value to string
    */
    auto opOpAssign(string op = "~", T)(immutable(T)[] value) {
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
        Allows slicing the string to get a substring.
    */
    immutable(T)[] opIndex(size_t[2] slice) {
        return cast(immutable(T)[])(this.vec_.data()[slice[0]..slice[1]]);
    }

    /**
        Allows getting a character from the string.
    */
    ref immutable(T) opIndex(size_t index) {
        return cast(immutable(T))(this.vec_.data()[index]);
    }
}

alias nstring = basic_string!char;
alias nwstring = basic_string!wchar;
alias ndstring = basic_string!dchar;