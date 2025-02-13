/**
    Numem Heaps.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.heap;
import numem.core.hooks;

/**
    A heap represents a destination for placement new operations.
    This allows classes to be instantiated into memory in developer
    specified configurations.
*/
abstract
class NuHeap {
@nogc:

    /** 
        Allocates memory on the heap.
        
        Params:
            bytes = The amount of bytes to allocate from the heap.
        Returns: 
            A pointer to the memory allocated on the heap.
            $(D null) if operation failed.
    */
    abstract void* alloc(size_t bytes);

    /** 
        Attempts to reallocate an existing memory allocation on the heap.

        Params:
            allocation = The original allocation
            bytes = The new size of the allocation, in bytes.
        Returns:
            A pointer to the memory allocated on the heap.
            $(D null) if the operation failed. 
    */
    abstract void* realloc(void* allocation, size_t bytes);

    /** 
        Frees memory from the heap.
        Note: Only memory owned by the heap may be freed by it.

        Params:
            allocation = The allocation to free.
    */
    abstract void free(void* allocation);
}

/**
    A heap which is a simple abstraction over nuAlloc, nuRealloc and nuFree.
*/
class NuMallocHeap : NuHeap {
@nogc:

    /** 
        Allocates memory on the heap.
        
        Params:
            bytes = The amount of bytes to allocate from the heap.
        Returns: 
            A pointer to the memory allocated on the heap.
            $(D null) if operation failed.
    */
    override
    void* alloc(size_t bytes) {
        return nu_malloc(bytes);
    }

    /** 
        Attempts to reallocate an existing memory allocation on the heap.

        Params:
            allocation = The original allocation
            bytes = The new size of the allocation, in bytes.
        Returns:
            A pointer to the memory allocated on the heap.
            $(D null) if the operation failed. 
    */
    override
    void* realloc(void* allocation, size_t bytes) {
        return nu_realloc(allocation, bytes);
    }

    /** 
        Frees memory from the heap.

        Params:
            allocation = The allocation to free.
    */
    override
    void free(void* allocation) {
        return nu_free(allocation);
    }
}