/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Debug tracing module
*/
module numem.core.trace;
import numem.core.traits;
import core.stdc.stdio;

pragma(inline, true)
void dbg_alloc(T)(ref T item) if (isHeapAllocated!T) {
    debug(trace) printf("Allocated "~T.stringof~" @ %p\n", cast(void*)item);
}

pragma(inline, true)
void dbg_alloc(T)(ref T item) if (!isHeapAllocated!T) {
    debug(trace) printf("Allocated "~T.stringof~" (on stack)\n");
}

pragma(inline, true)
void dbg_dealloc(T)(ref T item) if (isHeapAllocated!T) {
    debug(trace) printf("Deallocated "~T.stringof~" @ %p\n", cast(void*)item);
}

pragma(inline, true)
void dbg_dealloc(T)(ref T item) if (!isHeapAllocated!T) {
    debug(trace) printf("Deallocated "~T.stringof~" (on stack)\n");
}