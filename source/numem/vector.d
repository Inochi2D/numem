module numem.vector;
import numem.ptr;
import core.stdc.stdlib : malloc, realloc;
import core.stdc.string : memcpy;
import core.atomic : atomicFetchAdd, atomicFetchSub, atomicStore, atomicLoad;

/**
    C++ style vector
*/
struct vector(T) {
nothrow @nogc:
private:
    enum VECTOR_ALIGN = 32;

    T* memory;
    size_t capacity_;
    size_t size_;

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

            // Quantize to vector alignment
            capacity_ = cast(size_t)quantize!(ceil)(size+1, VECTOR_ALIGN);

            // copy old data to new memory block
            // then free old memory.
            if (oldMemory) realloc(memory, capacity);
            else malloc(memory, size);
        }
    }

public:

    /// Destructor
    ~this() {
        
        // Delete elements in the array.
        foreach(item; 0..size_) {
            nogc_delete(memory[item]);
        }

        // Free the pointer
        free(memory);
    }

    /// Constructor
    this(size_t size) {
        this.resize_(size);
    }

    /**
        Gets the C data pointer
    */
    T* data() {
        return memory;
    }

    /**
        Gets the C data pointer atomically
    */
    T* adata() {
        return atomicLoad(memory);
    }

    /**
        Gets a slice in to the vector
    */
    T[] toSlice() {
        return memory[0..size_];
    }

    /**
        Gets a slice in to the vector
    */
    T[] toSliceAtomic() {
        return atomicLoad(memory)[0..size_];
    }

    /**
        Add value to vector
    */
    auto opOpAssign(string op = "~")(T value) {
        memory[size_] = value;
        this.resize_(size_+1);
        return this;
    }

    /**
        Add vector items to vector
    */
    auto opOpAssign(string op = "~")(vector!T other) {
        size_t cSize = size_;
        this.resize_(size_ + other.size_);
        this.memory[cSize..cSize+other.size_] = other.memory[0..other.size_];
        
        return this;
    }

    /**
        Add slice to vector
    */
    auto opOpAssign(string op = "~")(T[] other) {
        size_t cSize = size_;
        this.resize_(size_ + other.length);
        this.memory[cSize..cSize+other.length] = other.memory[0..other.length];
        
        return this;
    }

    /**
        Shrink vector to fit
    */
    void shrinkToFit() {
        if (capacity_ > size_) {
            capacity_ = size_;
            realloc(memory, size_);
        }
    }

    /**
        Resize the vector
    */
    void resize(size_t newSize) {
        this.resize_(newSize);
    }

    /**
        Reserves space for the vector
    */
    void reserve(size_t newCapacity) {
        this.reserve_(newCapacity);
    }

    /**
        Gets whether the vector is empty.
    */
    bool empty() {
        return size_ == 0;
    }

    /**
        Gets the amount of elements in the vector
    */
    size_t size() {
        return size_;
    }

    /**
        Gets the capacity of the vector
    */
    size_t capacity() {
        return capacity_;
    }

    /**
        Clears all elements in the vector
    */
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
    void remove(size_t position) {
        if (position < size_) {
            nogc_delete(memory[position]);

            // Copy memory region around so that the deleted element is overwritten.
            memory[position..size_-1] = memory[position+1..size_];
         
            size_--;
        }
    }

    /**
        Erases element at position
    */
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
            memory[start..start+span] = memory[end..end+span];

            size_ -= span;
        }
    }

    /**
        Pops the backmost element of the vector
    */
    void popBack() {
        this.remove(size_-1);
    }

    /**
        Pops the backmost element of the vector
    */
    void popFront() {
        this.remove(0);
    }
}