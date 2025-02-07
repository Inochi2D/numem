/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.collections.vector;
import numem.core.hooks;
import numem.core.memory.lifetime;
import numem.core.memory.smartptr;
import numem.core;
import numem.core.exception;
import core.atomic : atomicFetchAdd, atomicFetchSub, atomicStore, atomicLoad;
import std.math.rounding : quantize, ceil;
import std.traits;

/// Gets whether the specified type is some variety of the vector type
enum isSomeVector(T) = is(T : VectorImpl!U, U...);

/// Gets whether the specified type is some weak variety of the vector type
enum isSomeWeakVector(T) = is(T : VectorImpl!(U, false), U);

/// Gets whether the type can be indexed like a range
enum isRangeIndexable(T) = isSomeVector!T || is(inout(T) == inout(U)[], U);

/// Gets whether the type can be indexed like a range, and if so whether the range element
/// matches type U
enum isCompatibleRange(T, U) = 
    (isSomeVector!T && is(Unqual!T.valueType : Unqual!U)) || 
    (is(T == X[], X) && is(Unqual!X : Unqual!U));


/**
    C++ style vector
*/
struct VectorImpl(T, bool ownsMemory=false) {
@nogc:
private:
    alias selfType = VectorImpl!(T, ownsMemory);

    enum VECTOR_ALIGN = 32;

    T* memory = null;
    size_t capacity_ = 0;
    size_t size_ = 0;

    // Internal resize function
    pragma(inline, true)
    void resize_(size_t size, bool shrinkToFit=false) {
        if (shrinkToFit && memory && capacity_ > size_) {
            static if (ownsMemory) {
                if (size < size_)
                    this.deleteRange(size, size_);
            }

            memory = cast(T*)nuRealloc(cast(void*)memory, size*T.sizeof);
            capacity_ = size;
            size_ = size;
            return;
        }

        if (size >= capacity_) 
            this.reserve_(size);

        size_ = size;
    }

    pragma(inline, true)
    void reserve_(size_t capacity) {
        if (capacity >= capacity_) {

            // Capacity before extension.
            size_t before = capacity_;

            // Quantize to vector alignment
            capacity_ = capacity + (capacity%VECTOR_ALIGN);

            // Reallocate the malloc'd portion if there is anything to realloc.
            if (memory) memory = cast(T*) nuRealloc(cast(void*)memory, capacity_*T.sizeof);
            else memory = cast(T*) nuAlloc(capacity_*T.sizeof);

            // Initialize newly allocated memory, else if T has postblit or move constructors,
            // those slots will be mistaken for live objects and their destructor called during
            // a opOpAssign operation.
            // But, we need to do this without triggering the postblit or move-constructor here,
            // or the same problem happen!
            for (size_t n = before; n < capacity_; n++) 
                initializeAtNoCtx(memory[n]);
        }
    }

    pragma(inline, true)
    void assign(T[] src) {
        this.resize_(src.length);
        this.copy(this.memory, src.ptr, src.length);
    }

    pragma(inline, true)
    void copy(T* dst, T* src, size_t length) {
        nogc_copy(dst[0..length], src[0..length]);
    }

    // Gets whether src overlaps with the memory in the vector.
    bool doSourceOverlap(T* src, size_t length = 0) {
        return src+length >= memory && src < memory+size_;
    }

    pragma(inline, true)
    void move(T* dst, T* src, size_t length) {
        nuMemmove(dst, src, T.sizeof*length);
    }

    pragma(inline, true)
    void deleteRange(size_t start, size_t end) {
        static if (ownsMemory)
            nogc_delete(this.memory[start..end]);
    }

    void deleteAll() {
        this.deleteRange(0, size_);
    }

public:

    /// Gets the type of the values stored in the vector.
    alias valueType = T;

    /// Destructor
    @trusted
    ~this() {
        if (this.memory) {
            this.deleteAll();

            // Free the pointer
            nuFree(this.memory);
        }

        this.memory = null;
        this.size_ = 0;
        this.capacity_ = 0;
    }

    /// Constructor
    @trusted
    this(size_t size) {
        this.resize_(size);
    }

    /// Constructor
    @trusted
    this(T[] data) {
        this.assign(data);
    }

    /// Constructor
    @trusted
    this(ref T[] data) {
        this.assign(data);
    }

    /**
        Makes a copy of a vector

        Allows weak_vector <-> vector copies.
    */
    @trusted
    this(T)(ref T rhs) if(!is(T == selfType) && isSomeVector!T)  {
        if (rhs.memory) {
            this.assign(rhs[]);
        }
    }

    /**
        Makes a copy of a vector
    */
    @trusted
    this(ref selfType rhs) {
        if (rhs.memory) {

            // NOTE: We need to turn these into pointers because
            // The D compiler otherwise thinks its supposed
            // to free the operands.
            auto self = (cast(selfType*)&this);
            auto other = (cast(selfType*)&rhs);

            this.resize_(rhs.size_);
            this.copy(self.memory, other.memory, rhs.size_);
        }
    }

    /**
        Makes a copy of a vector
    */
    @trusted
    this(ref return scope inout(selfType) rhs) inout {
        if (rhs.memory) {

            // NOTE: We need to turn these into pointers because
            // The D compiler otherwise thinks its supposed
            // to free the operands.
            auto self = (cast(selfType*)&this);
            auto other = (cast(selfType*)&rhs);

            self.resize_(rhs.size_);
            other.copy(self.memory, other.memory, other.size_);
        }
    }

    /**
        Gets the C data pointer
    */
    @trusted
    inout(T)* data() inout {
        return memory;
    }
    alias ptr = data; ///ditto

    /**
        Gets the C data pointer atomically
    */
    @trusted
    T* adata() {
        return atomicLoad(memory);
    }

    /**
        Gets a slice in to the vector
    */
    @trusted
    T[] toSlice() {
        return memory[0..size_];
    }

    /**
        Gets a slice in to the vector
    */
    @trusted
    T[] toSliceAtomic() {
        return atomicLoad(memory)[0..size_];
    }

    /**
        Shrink vector to fit
    */
    @trusted
    void shrinkToFit() {
        if (capacity_ > size_) {
            this.resize_(size_, true);
        }
    }

    /**
        Resize the vector
    */
    @trusted
    void resize(size_t newSize) {
        this.resize_(newSize);
    }

    /**
        Reserves space for the vector
    */
    @trusted
    void reserve(size_t newCapacity) {
        this.reserve_(newCapacity);
    }

    /**
        Gets whether the vector is empty.
    */
    @trusted
    bool empty() inout {
        return size_ == 0;
    }

    /**
        Gets the amount of elements in the vector
    */
    @trusted
    size_t size() inout {
        return size_;
    }
    alias length = size; ///ditto

    /**
        Gets the capacity of the vector
    */
    @trusted
    size_t capacity() inout {
        return capacity_;
    }

    /**
        Returns the memory usage of the vector in bytes.
    */
    @trusted
    size_t usage() inout {
        return capacity_*T.sizeof;
    }

    /**
        Clears all elements in the vector
    */
    @trusted
    void clear() {
        
        // Delete elements in the array.
        this.deleteAll();
        this.size_ = 0;
    }

    /**
        Erases element at position
    */
    @trusted
    void remove(size_t position) {
        if (position < size_) {

            static if (ownsMemory) 
                nogc_delete(memory[position]);

            // Move memory region around so that the deleted element is overwritten.
            this.move(memory+position, memory+position+1, (size_-1));
         
            size_--;
        }
    }

    /**
        Erases element at position [start, end)
        End is NOT included in that range.
    */
    @trusted
    void remove(size_t start, size_t end) {
        assert(start <= end && end <= size_);

        static if (ownsMemory && !isBasicType!T)
            this.deleteRange(start, end);

        // Copy over old elements
        size_t span = end-start;
        this.move(memory+start, memory+end, span);

        size_ -= span;
    }

    /**
        Inserts elements into the vector
    */
    @trusted
    void insert(U)(size_t offset, auto ref U item) if (is(U : T)) {

        // Simplify by reusing implementation for ranged inserts.
        const U[1] itm = item;
        this.insert(offset, cast(T[])itm[]);
    }

    /**
        Inserts elements into the vector
    */
    @trusted
    void insert(U)(size_t offset, auto ref U items) if (isCompatibleRange!(U, T)) {
        if (offset >= size_) {
            this.pushBack(items);
            return;
        }

        size_t toCopy = items.length;
        size_t toShift = size_-offset;

        this.resize_(size_+toCopy);
        this.move(memory+offset+toCopy, memory+offset, toShift);
        this.copy(memory+offset, cast(T*)items.ptr, toCopy);
    }

    /**
        Pops the backmost element of the vector
    */
    @trusted
    void popBack() {
        this.remove(size_-1);
    }

    /**
        Pops the backmost element of the vector
    */
    @trusted
    void popFront() {
        this.remove(0);
    }

    /**
        Pushes an element to the back of the vector
    */
    @trusted
    ref auto typeof(this) pushBack()(ref auto T item) {

        this.resize(size_+1);
        this.memory[size_-1] = item;
        return this;
    }

    /**
        Pushes an element to the back of the vector
    */
    @trusted
    ref auto typeof(this) pushBack(U)(ref auto U items) if (isCompatibleRange!(U, T)) {
        size_t cSize = size_;

        this.resize(size_+items.length);
        this.copy(memory+cSize, cast(T*)items.ptr, items.length);
        return this;
    }

    /**
        Pushes an element to the front of the vector
    */
    @trusted
    ref auto typeof(this) pushFront()(ref auto T value) {
        size_t cSize = size_;

        this.resize(size_+1);
        if (cSize > 0)
            this.move(&this.memory[1], this.memory, cSize);

        this.memory[0] = value;
        return this;
    }

    /**
        Pushes an element to the front of the vector
    */
    @trusted
    ref auto typeof(this) pushFront(U)(ref auto U items) if (isCompatibleRange!(U, T))  {
        size_t cSize = size_;

        this.resize(size_+value.size_);
        if (cSize > 0) 
            this.move(memory+value.size_, memory, cSize);

        this.copy(memory, cast(T*)items.ptr, items.length);
        return this;
    }

    /**
        Appends 2 vectors together, creating a new vector.
    */
    @trusted
    vector!T opBinary(string op: "~", U)(ref auto U items) if (isCompatibleRange!(U, T)) {
        vector!T output;
        output ~= this;
        output ~= items;
        return output;
    }

    /**
        Add value to vector
    */
    @trusted
    ref auto typeof(this) opOpAssign(string op = "~")(ref auto T value) {
        return this.pushBack(value);
    }

    /**
        Add vector items to vector
    */
    @trusted
    ref auto typeof(this) opOpAssign(string op = "~", U)(ref auto U items) if (isCompatibleRange!(U, T)) {
        return this.pushBack(items);
    }

    /**
        Add slice to vector
    */
    @trusted
    ref auto opOpAssign(string op = "~")(T[] other) {
        size_t cSize = size_;

        this.resize_(size_ + other.length);
        this.copy(this.memory+cSize, other.ptr, other.length);
        return this;
    }

    /**
        Override for $ operator
    */
    @trusted
    size_t opDollar() nothrow const {
        return size_;
    }

    /**
        Slicing operator

        D slices are short lived and may end up pointing to invalid memory if their string is modified.
    */
    @trusted
    inout(T)[] opSlice(size_t dim = 0)(size_t start, size_t end) inout {
        return memory[start..end];
    }

    /**
        Allows slicing the string to the full vector
    */
    @trusted
    T[] opIndex() nothrow {
        return memory[0..size_];
    }

    /**
        Allows slicing the vector to get a sub vector.
    */
    @trusted
    T[] opIndex(size_t[2] slice) {
        return memory[slice[0]..slice[1]];
    }

    /**
        Allows getting an item from the vector.
    */
    @trusted
    ref inout(T) opIndex(size_t index) inout {
        return memory[index];
    }

    /**
        Allows assigning a range of values to the vector.
    */
    @trusted
    void opAssign(T)(in inout(T)[] values) {
        this.resize(values.length);
        this.copy(memory, cast(T*)values.ptr, values.length);
    }

    /**
        Allows assigning a range of values to the vector.
    */
    @trusted
    void opIndexAssign(in T value, size_t index) {
        this.copy(cast(T*)&memory[index], cast(T*)&value, 1);
    }

    /**
        Allows assigning a range of values to the vector.

        For nothrow usage, see [tryReplaceRange]
    */
    @trusted
    void opIndexAssign(in T[] values, T[] slice) {
        size_t offset = slice.ptr-this.memory;

        enforce(
            values.length == slice.length,
            NuRangeException.sliceLengthMismatch(values.length, slice.length)
        );

        enforce(
            offset+slice.length <= size_,
            NuRangeException.sliceOutOfRange(offset, offset+slice.length)
        );

        enforce(
            !this.doSourceOverlap(cast(T*)values.ptr, values.length),
            "Overlapping copies are not allowed!"
        );

        this.copy(cast(T*)slice.ptr, cast(T*)values.ptr, slice.length);
    }

    /**
        Replaces a range within the vector of [values] length,
        at [offset].

        Returns whether this operation succeeded.
    */
    @trusted
    bool tryReplaceRange(U)(ref auto U values, size_t offset) nothrow if (isCompatibleRange!(U, T)) {
        if (offset+values.length > size_)
            return false;
        
        if (this.doSourceOverlap(cast(T*)values.ptr, values.length))
            return false;
        
        this.copy(cast(T*)&memory[offset], cast(T*)values.ptr, values.length);
        return true;
    }

    /**
        Handle struct moves.
    */
    @trusted
    void opPostMove(ref typeof(this) old) nothrow {
        if (old.memory) {
            this.memory = cast(valueType*)old.memory;
            this.size_ = old.size_;
            this.capacity_ = old.capacity_;
        }
    }
}

/**
    A vector which owns the elements put in to it
*/
alias vector(T) = VectorImpl!(T, true);

/**
    A vector which does NOT own the elements put in to it
*/
alias weak_vector(T) = VectorImpl!(T, false);

@("vector: Issue #2")
unittest {
    class A { }
    shared_ptr!A a = shared_new!A();
    vector!(shared_ptr!A) v;
    v ~= a; // Used to crash, see Issue #2
}

@("vector: delete")
unittest {
    vector!int v;
    v ~= [1, 2, 3];
    v.remove(0, 0);
    v.remove(1, 1);
    v.remove(2, 2);
}

@("vector: insert single")
unittest {
    vector!uint v;
    v ~= [1, 2, 4];
    v.insert(2, 3);

    assert(v[] == [1, 2, 3, 4]);
}

@("vector: insert range")
unittest {
    vector!uint v;
    v ~= [1, 2, 5, 6];
    v.insert(2, [3, 4]);

    assert(v[] == [1, 2, 3, 4, 5, 6]);
}

@("vector: append throwable")
unittest {
    static
    struct Test {
    @nogc:
        uint test;
        this(uint test) {
            this.test = test;
        }
    }

    vector!Test v;
    v ~= Test(42);
    assert(v[0].test == 42);
}

@("vector: slice overlap")
unittest {
    try {
        static
        struct Test { }

        vector!(Test*) tests;
        tests ~= nogc_new!Test;
        tests ~= nogc_new!Test;
        tests ~= nogc_new!Test;

        tests[0..1] = tests[1..2];
    } catch(NuException ex) {
        ex.free();
        return;
    }

    assert(0, "An exception should've been thrown!");
}

@("vector: insert pointers")
unittest {
    static struct Test { int a; }

    vector!(Test*) tests;
    tests ~= nogc_new!Test(0);
    tests ~= nogc_new!Test(1);
    tests ~= nogc_new!Test(2);

    tests.insert(1, [nogc_new!Test(24), nogc_new!Test(25), nogc_new!Test(26)]);
    foreach(i; 0..tests.length) {
        foreach(j; 0..tests.length) {
            if (i == j) continue;
            assert(tests[i] !is tests[j]);
        }
    }

    assert(tests[0].a == 0);
    assert(tests[1].a == 24);
    assert(tests[2].a == 25);
    assert(tests[3].a == 26);
    assert(tests[4].a == 1);
    assert(tests[5].a == 2);
}

@("vector: append vectors")
unittest {
    vector!uint veca = [0, 1, 2, 3, 4];
    vector!uint vecb = [0, 1, 2, 3, 4];

    assert((veca~vecb)[] == [0, 1, 2, 3, 4, 0, 1, 2, 3, 4]);
}