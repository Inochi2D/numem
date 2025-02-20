/**
    Numem Core Hooks.

    This file contains all the core hooks numem calls internally to handle memory.
    Given that some platforms may not have a C standard library, these hooks allow you
    to override how numem handles memory for such platforms from an external library.

    In this case, most of the hooks presented here will need to be implemented to cover
    all of the used internal hooks within numem.

    Hooks which are prefixed $(D nuopt_) are optional and may be omitted, they are
    usually for language-specific interoperability.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.hooks;

/**
    Allocates $(D bytes) worth of memory.

    Params:
        bytes = How many bytes to allocate.
    
    Returns:
        Newly allocated memory or $(D null) on failure.
        To avoid a memory leak, free the memory with $(D nu_free).
    
    Notes:
        Given the implementation of $(D nu_malloc) and $(D nu_free) may be
        independent of the libc allocator, memory allocated with
        $(D nu_malloc) should $(B always) be freed with $(D nu_free)!
*/
extern(C)
extern void* nu_malloc(size_t bytes) @nogc nothrow @system;

/**
    Reallocates memory prior allocated with $(D nu_malloc) or
    $(D nu_alignedalloc).

    This function may re-allocate the memory if resizing the allocation
    to the new size is not possible.

    Params:
        data    = Pointer to prior allocated memory.
        newSize = New size of the allocation, in bytes.

    Returns:
        The address of the reallocated memory or $(D null) on failure.
        To avoid a memory leak, free the memory with $(D nu_free).
    
    Notes:
        Given the implementation of $(D nu_realloc) and $(D nu_free) may be
        independent of the libc allocator, memory allocated with
        $(D nu_realloc) should $(B always) be freed with $(D nu_free)!
*/
extern(C)
extern void* nu_realloc(void* data, size_t newSize) @nogc nothrow @system;

/**
    Frees allocated memory.

    Params:
        data = Pointer to start of memory prior allocated.

    Notes:
        Given the implementation of the allocators and $(D nu_free) may be
        independent of the libc allocator, memory allocated with
        numem functions should $(B always) be freed with $(D nu_free)!
*/
extern(C)
extern void nu_free(void* data) @nogc nothrow @system;

/**
    Copies $(D bytes) worth of data from $(D src) into $(D dst).
    
    $(D src) and $(D dst) needs to be allocated and within range,
    additionally the source and destination may not overlap.

    Params:
        dst =   Destination of the memory copy operation.
        src =   Source of the memory copy operation
        bytes = The amount of bytes to copy.
*/
extern(C)
extern void* nu_memcpy(return scope void* dst, return scope void* src, size_t bytes) @nogc nothrow @system;

/**
    Moves $(D bytes) worth of data from $(D src) into $(D dst).
    
    $(D src) and $(D dst) needs to be allocated and within range.

    Params:
        dst =   Destination of the memory copy operation.
        src =   Source of the memory copy operation
        bytes = The amount of bytes to copy.
    
    Returns:
        Pointer to $(D dst)
*/
extern(C)
extern void* nu_memmove(void* dst, void* src, size_t bytes) @nogc nothrow @system;

/**
    Fills $(D dst) with $(D bytes) amount of $(D value)s.

    Params:
        dst =   Destination of the memory copy operation.
        value = The byte to repeatedly copy to the memory starting at $(D dst)
        bytes = The amount of bytes to write.
    
    Returns:
        Pointer to $(D dst)
*/
extern(C)
extern void* nu_memset(void* dst, ubyte value, size_t bytes) @nogc nothrow @system;

/**
    Called internally by numem if a fatal error occured.

    This function $(B should) exit the application and if possible,
    print an error. But it $(B may) not print an error.

    Params:
        errMsg = A D string containing the error in question.
    
    Returns:
        Never returns, the application should crash at this point.
*/
extern(C)
extern void nu_fatal(const(char)[] errMsg) @nogc nothrow @system;


/**
    Hooks for handling auto release pools.

    These $(I optional) pool callback functions allows implementers of
    numem to hook into the auto release pool system.

    Push should push a new context onto an internal stack, while pop should
    release an element from the stack.

    These functions are mainly useful for Objective-C interoperability.

    See_Also:
        $(LINK2 https://clang.llvm.org/docs/AutomaticReferenceCounting.html#autoreleasepool, ARC Documentation)
*/
extern(C)
__gshared void* function() @nogc nothrow @system nuopt_autoreleasepool_push = null;

/// ditto
extern(C)
__gshared void function(void*) @nogc nothrow @system nuopt_autoreleasepool_pop = null;