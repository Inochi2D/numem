/**
    Additional Memory Handling.

    Functions that build on the numem hooks to implement higher level memory
    managment functionality.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen, Guillaume Piolat
*/
module numem.core.memory;
import numem.core.hooks;
import numem.core.traits;
import numem.core.traits : AllocSize, isPointer;
import numem.lifetime;

/**
    System pointer size.
*/
enum size_t ALIGN_PTR_SIZE = (void*).sizeof;

/**
    Allocates enough memory to contain Type T.
    
    Returns:
        Newly allocated memory or $(D null) on failure.
        To avoid a memory leak, free the memory with $(D nu_free).
    
    Notes:
        Given the implementation of $(D nu_malloc) and $(D nu_free) may be
        independent of the libc allocator, memory allocated with
        $(D nu_malloc) should $(B always) be freed with $(D nu_free)!
*/
ref void[AllocSize!T] nu_mallocT(T)() @nogc nothrow @trusted {
    return nu_malloc(AllocSize!T)[0..AllocSize!T];
}

/**
    Gets the storage space used by $(D object).

    Params:
        object = The object to get the storage space of.
    
    Returns:
        The storage of the provided object; cast to a static
        void array reference.
*/
ref void[AllocSize!T] nu_storageT(T)(ref T object) @nogc nothrow @trusted {
    static if (AllocSize!T == T.sizeof)
        return object;
    else {
        return (cast(void*)object)[0..AllocSize!T];
    }
}

/**
    Resizes a slice to be of the given size and alignment.
    If the slice is not yet allocated, it will be.

    When creating a slice with complex types you may wish to chain the resize
    operation with $(D numem.lifetime.nogc_initialize).

    Set $(D length) to $(D 0) to free the buffer.

    Params:
        buffer =    The buffer to resize.
        length =    The length of the buffer (in elements.)
        alignment = The alignment of the buffer (in bytes.)

    Notes:
        $(UL
            $(LI
                Resizing the buffer to be smaller than it was originally will
                cause the elements to be deleted; if, and only if the type
                is an aggregate value type (aka. $(D struct) or $(D union))
                and said type has an elaborate destructor.  
            )
            $(LI
                Class pointers will NOT be deleted, this must be done
                manually.
            )
            $(LI
                The memory allocated by nu_resize will NOT be initialized,
                you must chain it with $(D numem.lifetime.nogc_initialize)
                if the types rely on interior pointers.
            )
        )

    Threadsafety:
        The underlying data will, if possible be updated atomically, however
        this does $(B NOT) prevent you from accessing stale references
        elsewhere. If you wish to access a slice across threads, you should
        use synchronisation primitives such as a mutex.

    Returns:
        The resized buffer.
*/
ref T[] nu_resize(T)(ref T[] buffer, size_t length, int alignment = 1) @nogc {
    static if (hasElaborateDestructor!T && !isHeapAllocated!T) {
        import numem.lifetime : nogc_delete;

        if (length < buffer.length) {

            static if (isRefcounted!T) {
                foreach(i; length..buffer.length) {
                    buffer[i].nu_release();
                }
            } else {

                // Handle destructor invocation.
                nogc_delete!(T, false)(buffer[length..buffer.length]);
            }

            // Handle buffer deletion.
            if (length == 0) {
                if (buffer.length > 0)
                    nu_aligned_free(cast(void*)buffer.ptr, alignment);
                
                buffer = null;
                return buffer;
            }
        }

    } else {

        // No destructors, just free normally.
        if (length == 0) {
            if (buffer.length > 0)
                nu_aligned_free(cast(void*)buffer.ptr, alignment);
            
            buffer = null;
            return buffer;
        }
    }
    
    T* ptr = cast(T*)nu_aligned_realloc(cast(void*)buffer.ptr, T.sizeof * length, alignment);
    buffer = ptr !is null ? ptr[0..length] : null;
    return buffer;
}

/**
    Allocates and initializes a new slice.

    Params:
        count = The number of elements to allocate.

    Returns:
        The allocated array or a zero-length array on
        error.
*/
T[] nu_malloca(T)(size_t count) {
    T[] tmp;
    tmp = tmp.nu_resize(count);
    nogc_initialize(tmp[0..count]);
    return tmp;
}

/**
    Frees a slice.

    Params:
        slice = The slice to free.
*/
void nu_freea(T)(ref T[] slice) {
    static if (isRefcounted!T) {
        foreach(i; 0..slice.length) {
            nu_release(slice[i]);
        }
    } else {
        nogc_delete(slice[0..$]);
    }

    nu_free(cast(void*)slice.ptr);
    slice = null;
}

/**
    Creates a shallow duplicate of the given buffer.

    Params:
        buffer = Buffer to duplicate.

    Memorysafety:
        This function copies data out of the string into a new
        memory allocation; as such it has to be freed.
        It is otherwise safe, in that it won't modify
        the original memory provided.

    Returns:
        Duplicated slice, must be freed with $(D nu_resize)
*/
inout(T)[] nu_dup(T)(inout(T)[] buffer) @nogc @trusted {
    T[] buf;

    buf.nu_resize(buffer.length);
    nu_memcpy(cast(void*)buf.ptr, cast(void*)buffer.ptr, buf.length*T.sizeof);
    return cast(inout(T)[])buf;
}

/**
    Creates a shallow immutable duplicate of the given buffer.

    Params:
        buffer = Buffer to duplicate.

    Memorysafety:
        This function copies data out of the slice into a new
        memory allocation; as such it has to be freed.
        It is otherwise safe, in that it won't modify
        the original memory provided.

    Returns:
        Duplicated slice, must be freed with $(D nu_resize)
*/
immutable(T)[] nu_idup(T)(inout(T)[] buffer) @nogc @trusted {
    return cast(immutable(T)[])nu_dup(buffer);
}

/**
    Gets the retain function for type T and calls it.
*/
T nu_retain(T)(auto ref T value) @nogc @trusted
if (isRefcounted!T) {
    static if (isObjectiveC!T) {
        return cast(T)value.retain();
    } else static if(isCOMClass!T) {
        value.AddRef();
        return cast(T)value;
    } else {
        static foreach(rcName; rcRetainNames) {
            static if (!is(__found) && __traits(hasMember, T, rcName)) {
                static if (is(ReturnType!(typeof(__traits(getMember, value, rcName))) : T))
                    return __traits(getMember, value, rcName)();
                else {
                    __traits(getMember, value, rcName)();
                    return cast(T)value;
                }

                enum __found = true;
            }
        }
    }
}

/**
    Calls the $(D release) function of reference counted type
    $(D T).

    Params:
        value = The value to reduce the reference count of.
    
    Returns:
        If possible, the new state of $(D value).
*/
T nu_release(T)(auto ref T value) @nogc @trusted
if (isRefcounted!T) {
    static if (isObjectiveC!T) {
        return cast(T)value.release();
    } else static if(isCOMClass!T) {
        value.Release();
        return cast(T)value;
    } else {
        static foreach(rcName; rcReleaseNames) {
            static if (!is(__found) && __traits(hasMember, T, rcName)) {
                static if (is(ReturnType!(typeof(__traits(getMember, value, rcName))) : T))
                    return __traits(getMember, value, rcName)();
                else {
                    __traits(getMember, value, rcName)();
                    return cast(T)value;
                }

                enum __found = true;
            }
        }
    }
}

/**
    Appends a null terminator at the end of the string,
    resizes the memory allocation if need be.

    Params:
        text = string to add a null-terminator to, in-place

    Memorysafety:
        This function is not memory safe, in that if you attempt
        to use it on string literals it may lead to memory corruption
        or crashes. This is meant to be used internally. It may reallocate
        the underlying memory of the provided string, as such all prior
        string references should be assumed to be invalid.

    Returns:
        Slice of the null-terminated string, the null terminator is hidden.
*/
inout(T)[] nu_terminate(T)(ref inout(T)[] text) @nogc @system
if (is(T == char) || is(T == wchar) || is(T == dchar)) {
    
    // Early escape, empty string.
    if (text.length == 0)
        return text;

    // Early escape out, already terminated.
    if (text[$-1] == '\0')
        return text[0..$-1];

    size_t termOffset = text.length;

    // Resize by 1, add null terminator.
    // Sometimes this won't be needed, if extra memory was
    // already allocated.
    text.nu_resize(text.length+1);
    (cast(T*)text.ptr)[termOffset] = '\0';
    text = text[0..$-1];

    // Return length _without_ null terminator by slicing it out.
    // The memory allocation is otherwise still the same.
    return text;
}

/**
    Gets whether 2 memory ranges are overlapping.

    Params:
        a =         Start address of first range.
        aLength =   Length of first range, in bytes.
        b =         Start address of second range.
        bLength =   Length of second range, in bytes.

    Returns:
        $(D true) if range $(D a) and $(D b) overlaps, $(D false) otherwise.
        It is assumed that start points at $(D null) and lengths of $(D 0) never
        overlap.

    Examples:
        ---
        int[] arr1 = [1, 2, 3, 4];
        int[] arr2 = arr1[1..$-1];

        size_t arr1len = arr1.length*int.sizeof;
        size_t arr2len = arr2.length*int.sizeof;

        // Test all iterations that are supported.
        assert(nu_is_overlapping(arr1.ptr, arr1len, arr2.ptr, arr2len));
        assert(!nu_is_overlapping(arr1.ptr, arr1len, arr2.ptr, 0));
        assert(!nu_is_overlapping(arr1.ptr, 0, arr2.ptr, arr2len));
        assert(!nu_is_overlapping(null, arr1len, arr2.ptr, arr2len));
        assert(!nu_is_overlapping(arr1.ptr, arr1len, null, arr2len));
        ---

*/
export
extern(C)
bool nu_is_overlapping(void* a, size_t aLength, void* b, size_t bLength) @nogc nothrow {
    
    // Early exit, null don't overlap.
    if (a is null || b is null)
        return false;

    // Early exit, no length.
    if (aLength == 0 || bLength == 0)
        return false;
    
    void* aEnd = a+aLength;
    void* bEnd = b+bLength;

    // Overlap occurs if src is within [dst..dstEnd]
    // or dst is within [src..srcEnd]
    if (a >= b && a < bEnd)
        return true;

    if (b >= a && b < aEnd)
        return true;

    return false;
}

/**
    Gets the amount of bytes to allocate when requesting a specific amount of memory
    with a given alignment.

    Params:
        request =   How many bytes to allocate
        alignment = The alignment of the requested allocation,
                    in bytes.

    Returns:
        $(D request) aligned to $(D alignment), taking in to account
        pointer alignment requirements.
*/
export
extern(C)
size_t nu_aligned_size(size_t request, size_t alignment) nothrow @nogc @safe pure {
    return request + alignment - 1 + ALIGN_PTR_SIZE * 2;
}

/**
    Realigns $(D ptr) to the next increment of $(D alignment)

    Params:
        ptr =       A pointer
        alignment = The alignment to adjust the pointer to.
    
    Returns:
        The next aligned pointer.
*/
export
extern(C)
void* nu_realign(void* ptr, size_t alignment) nothrow @nogc @trusted pure {
    return ptr+(cast(size_t)ptr % alignment);
}

/**
    Gets whether $(D ptr) is aligned to $(D alignment)

    Params:
        ptr =       A pointer
        alignment = The alignment to compare the pointer to.

    Returns:
        Whether $(D ptr) is aligned to $(D alignment) 
*/
export
extern(C)
bool nu_is_aligned(void* ptr, size_t alignment) nothrow @nogc @trusted pure {
    return (cast(size_t)ptr & (alignment-1)) == 0;
}

/**
    Allocates memory with a given alignment.

    Params:
        size =      The size of the allocation, in bytes.
        alignment = The alignment of the allocation, in bytes.
    
    Returns:
        A new aligned pointer, $(D null) on failure.

    See_Also:
        $(D nu_aligned_realloc)
        $(D nu_aligned_free)
*/
export
extern(C)
void* nu_aligned_alloc(size_t size, size_t alignment) nothrow @nogc pure {
    assert(alignment != 0);

    // Shortcut for tight alignment.
    if (alignment == 1)
        return nu_malloc(size);

    size_t request = nu_aligned_size(size, alignment);
    void* raw = nu_malloc(request);

    return __nu_store_aligned_ptr(raw, size, alignment);   
}

/**
    Reallocates memory with a given alignment.

    Params:
        ptr =       Pointer to prior allocation made with $(D nu_aligned_alloc)
        size =      The size of the allocation, in bytes.
        alignment = The alignment of the allocation, in bytes.
    
    Returns:
        The address of the pointer after the reallocation, $(D null) on failure.

    Notes:
        The alignment provided $(B HAS) to match the original alignment of $(D ptr)

    See_Also:
        $(D nu_aligned_alloc)
        $(D nu_aligned_free)
*/
export
extern(C)
void* nu_aligned_realloc(void* ptr, size_t size, size_t alignment) nothrow @nogc pure {
    return __nu_aligned_realloc!true(ptr, size, alignment);
}

/**
    Reallocates memory with a given alignment.

    Params:
        ptr =       Pointer to prior allocation made with $(D nu_aligned_alloc)
        size =      The size of the allocation, in bytes.
        alignment = The alignment of the allocation, in bytes.
    
    Returns:
        The address of the pointer after the reallocation, $(D null) on failure.

    Notes:
        The alignment provided $(B HAS) to match the original alignment of $(D ptr)

    See_Also:
        $(D nu_aligned_alloc)
        $(D nu_aligned_free)
*/
export
extern(C)
void* nu_aligned_realloc_destructive(void* ptr, size_t size, size_t alignment) nothrow @nogc pure {
    return __nu_aligned_realloc!false(ptr, size, alignment);
}

/**
    Frees aligned memory.

    Params:
        ptr =       Pointer to prior allocation made with $(D nu_aligned_alloc)
        alignment = The alignment of the allocation, in bytes.

    See_Also:
        $(D nu_aligned_alloc)
        $(D nu_aligned_realloc)
*/
export
extern(C)
void nu_aligned_free(void* ptr, size_t alignment) nothrow @nogc pure {
    
    // Handle null case.
    if (!ptr)
        return;
    
    // Handle unaligned memory.
    if (alignment == 1)
        return nu_free(ptr);

    assert(alignment != 0);
    assert(nu_is_aligned(ptr, alignment));

    void** rawLocation = cast(void**)(ptr - ALIGN_PTR_SIZE);
    nu_free(*rawLocation);
}

private
void* __nu_store_aligned_ptr(void* ptr, size_t size, size_t alignment) nothrow @nogc pure {
    
    // Handle null case.
    if (!ptr)
        return null;

    void* start = ptr + ALIGN_PTR_SIZE * 2;
    void* aligned = nu_realign(start, alignment);

    // Update the location.
    void** rawLocation = cast(void**)(aligned - ALIGN_PTR_SIZE);
    nu_atomic_store_ptr(cast(void**)rawLocation, ptr);

    // Update the size.
    size_t* sizeLocation = cast(size_t*)(aligned - 2 * ALIGN_PTR_SIZE);
    nu_atomic_store_ptr(cast(void**)sizeLocation, cast(void*)size);

    assert(nu_is_aligned(aligned, alignment));
    return aligned;
}

private
void* __nu_aligned_realloc(bool preserveIfResized)(void* aligned, size_t size, size_t alignment) nothrow @nogc pure {

    // Use normal realloc if there's no alignment.
    if (alignment == 1)
        return nu_realloc(aligned, size);
    
    // Create if doesn't exist.
    if (aligned is null)
        return nu_aligned_alloc(size, alignment);

    assert(alignment != 0);
    assert(nu_is_aligned(aligned, alignment));
    
    size_t prevSize = *cast(size_t*)(aligned - ALIGN_PTR_SIZE * 2);
    size_t prevRequest = nu_aligned_size(prevSize, alignment);
    size_t request = nu_aligned_size(size, alignment);

    // Ensure alignment matches.
    assert(prevRequest - request == prevSize - size);

    // Heuristic: if a requested size is within 50% to 100% of what is already allocated
    //            then exit with the same pointer
    if ((prevRequest < request * 4) && (request <= prevRequest))
        return aligned;

    void* newptr = nu_malloc(request);
    if (request > 0 && newptr is null)
        return null;
    
    void* newAligned = __nu_store_aligned_ptr(newptr, size, alignment);
    
    static if (preserveIfResized) {
        size_t minSize = size < prevSize ? size : prevSize;
        nu_memcpy(newAligned, aligned, minSize);
    }
    nu_aligned_free(aligned, alignment);

    assert(nu_is_aligned(newAligned, alignment));
    return newAligned;
}