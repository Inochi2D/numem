/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.collections.vector;
import numem.core.memory.smartptr;
import numem.core;
import core.stdc.stdlib : malloc, realloc, free;
import core.stdc.string : memcpy, memmove;
import core.atomic : atomicFetchAdd, atomicFetchSub, atomicStore, atomicLoad;
import std.math.rounding : quantize, ceil;
import std.traits;

/// Gets whether the specified type is some variety of the vector type
enum isSomeVector(T) = is(T : VectorImpl!U, U...);

/// Gets whether the specified type is some weak variety of the vector type
enum isSomeWeakVector(T) = is(T : VectorImpl!(U, false), U);

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
    void resize_(size_t size) {
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
            capacity_ = cast(size_t)quantize!(ceil, double)(cast(double)capacity+1, cast(double)VECTOR_ALIGN);

            // Reallocate the malloc'd portion if there is anything to realloc.
            if (memory) memory = cast(T*) realloc(cast(void*)memory, capacity_*T.sizeof);
            else memory = cast(T*)malloc(capacity_*T.sizeof);

            // Initialize newly allocated memory, else if T has postblit or move constructors,
            // those slots will be mistaken for live objects and their destructor called during
            // a opOpAssign operation.
            // But, we need to do this without triggering the postblit or move-constructor here,
            // or the same problem happen!
            for (size_t n = before; n < capacity_; ++n) {

                T tmp = T.init;
                memcpy(memory + n, &tmp, T.sizeof);
            }
        }
    }

    pragma(inline, true)
    void _memcpy(T* dst, T* src, size_t length) {

        static if(__traits(hasPostblit, T)) {   
            
            memcpy(dst, src, T.sizeof*length); 
            foreach(i; 0..length) {
                dst[i].__xpostblit();
            }
        } else static if (__traits(hasCopyConstructor, T)) {

            // Initializer
            T tmp = T.init;
            foreach(i; 0..length) {

                // Copy over initializer
                memcpy(dst + i, &tmp, T.sizeof);

                // Call copy constructor
                dst[i].__ctor(src[i]);
            }

        } else {

            memcpy(dst, src, T.sizeof*length);
        }
    }

public:

    /// Gets the type of character stored in the string.
    alias valueType = T;

    /// Destructor
    @trusted
    ~this() {
        if (this.memory) {
            static if (ownsMemory) {
                
                // Delete elements in the array.
                static if (!isBasicType!T) {
                    foreach_reverse(item; 0..size_) {
                        nogc_delete(this.memory[item]);
                    }
                }
            }

            // Free the pointer
            free(cast(void*)this.memory);
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
        this.resize_(data.length);
        this._memcpy(this.memory, data.ptr, data.length);
    }

    /// Constructor
    @trusted
    this(ref T[] data) {
        this.resize_(data.length);
        this._memcpy(this.memory, data.ptr, data.length);
    }

    /**
        Makes a copy of a vector

        Allows weak_vector <-> vector copies.
    */
    @trusted
    this(T)(ref T rhs) if(!is(T == selfType) && isSomeVector!T)  {
        if (rhs.memory) {
            this.resize_(rhs.size_);
            this._memcpy(this.memory, rhs.memory, rhs.size_);
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
            this._memcpy(self.memory, other.memory, rhs.size_);
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
            other._memcpy(self.memory, other.memory, other.size_);
        }
    }

    /**
        Gets the C data pointer
    */
    @trusted
    T* data() {
        return memory;
    }

    /**
        Gets the C data pointer as an inout pointer
    */
    @trusted
    inout(T)* idata() inout {
        return cast(inout(T)*)memory;
    }

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
            capacity_ = size_;
            if (size_ > 0) memory = cast(T*) realloc(memory, size_);
            else free(memory);
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
        foreach(item; 0..size_) {
            nogc_delete(memory[item]);
        }

        this.size_ = 0;
    }

    /**
        Erases element at position
    */
    @trusted
    void remove(size_t position) {
        if (position < size_) {
            nogc_delete(memory[position]);

            // Move memory region around so that the deleted element is overwritten.
            memmove(memory+position, memory+position+1, size_*(T*).sizeof);
         
            size_--;
        }
    }

    /**
        Erases element at position
    */
    @trusted
    void remove(size_t start, size_t end) {

        // Flip inputs if they are reversed, just in case.
        if (end > start) {
            size_t tmp = start;
            start = end;
            end = tmp;
        }

        if (start < size_ && end < size_) {
            
            // NOTE: the ".." operator is start inclusive, end exclusive.
            foreach(i; start..end+1)
                nogc_delete(memory[i]);

            // Copy over old elements
            size_t span = (end+1)-start;
            // memory[start..start+span] = memory[end..end+span];
            memmove(memory+start, memory+end, span*(T*).sizeof);

            size_ -= span;
        }
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
    auto pushBack(T)(T item) {
        this ~= item;
        return this;
    }

    /**
        Pushes an element to the back of the vector
    */
    @trusted
    auto pushBack(T)(vector!T item) {
        this ~= item;
        return this;
    }

    /**
        Pushes an element to the back of the vector
    */
    @trusted
    auto pushBack(T)(T[] item) {
        this ~= item;
        return this;
    }

    /**
        Pushes an element to the front of the vector
    */
    @trusted
    ref auto pushFront(T)(T value) {
        size_t cSize = size_;

        this.resize(size_+1);
        if (cSize > 0) {
            memmove(&this.memory[1], this.memory, cSize*(T*).sizeof);
        }
        this.memory[0] = value;

        return this;
    }

    /**
        Pushes an element to the front of the vector
    */
    @trusted
    ref auto pushFront(T)(vector!T value) {
        size_t cSize = size_;

        this.resize(size_+value.size_);
        if (cSize > 0) {
            memmove(&this.memory[value.size_], this.memory, cSize*(T*).sizeof);
        }
        this.memory[0..value.size_] = value.memory[0..value.size_];

        return this;
    }

    /**
        Pushes an element to the front of the vector
    */
    @trusted
    ref auto pushFront(T)(T[] value) {
        size_t cSize = size_;

        this.resize(size_+value.length);
        if (cSize > 0) {
            memmove(&this.memory[value.length], this.memory, cSize*(T*).sizeof);
        }
        this.memory[0..value.length] = value.memory[0..value.length];

        return this;
    }

    /**
        Add value to vector
    */
    @trusted
    ref auto opOpAssign(string op = "~")(T value) {
        size_t cSize = size_;

        this.resize_(size_+1);
        this._memcpy(this.memory+cSize, &value, 1);

        return this;
    }

    /**
        Add vector items to vector
    */
    @trusted
    ref auto opOpAssign(string op = "~")(vector!T other) {
        size_t cSize = size_;
        
        this.resize_(size_ + other.size_);
        this._memcpy(this.memory+cSize, other.ptr, other.size_);

        return this;
    }

    /**
        Add slice to vector
    */
    @trusted
    ref auto opOpAssign(string op = "~")(T[] other) {
        size_t cSize = size_;

        this.resize_(size_ + other.length);
        this._memcpy(this.memory+cSize, other.ptr, other.length);
        return this;
    }

    /**
        Override for $ operator
    */
    @trusted
    size_t opDollar() {
        return size_;
    }

    /**
        Slicing operator

        D slices are short lived and may end up pointing to invalid memory if their string is modified.
    */
    @trusted
    T[] opSlice(size_t dim = 0)(size_t start, size_t end) {
        return memory[start..end];
    }

    /**
        Allows slicing the string to the full vector
    */
    @trusted
    T[] opIndex() {
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
    ref T opIndex(size_t index) {
        return memory[index];
    }

    /**
        Allows assigning a range of values to the vector.
    */
    @trusted
    void opAssign(T)(in inout(T)[] values) {
        this.resize(values.length);
        this._memcpy(memory, cast(T*)values.ptr, values.length);
    }

    /**
        Allows assigning a range of values to the vector.
    */
    @trusted
    void opIndexAssign(in T value, size_t index) {
        this._memcpy(cast(T*)&memory[index], cast(T*)&value, 1);
    }

    /**
        Allows assigning a range of values to the vector.
    */
    @trusted
    void opIndexAssign(in T[] values, T[] slice) {
        size_t offset = slice.ptr-this.memory;
        if (offset+slice.length > size_) {
            this.resize_(offset+slice.length);
        }

        this._memcpy(cast(T*)slice.ptr, cast(T*)values.ptr, slice.length);
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
    class A {
    }
    shared_ptr!A a = shared_new!A();
    vector!(shared_ptr!A) v;
    v ~= a; // Used to crash, see Issue #2
}
