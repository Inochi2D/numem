/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Debug tracing module
*/
module numem.core.trace;
import core.stdc.stdio;

pragma(inline, true)
void dbg_alloc(T)(T item) if (is(T == class)) {
    debug(trace) printf("Allocated "~T.stringof~" @ %p\n", cast(void*)item);
}

pragma(inline, true)
void dbg_alloc(T)(T* item) if (is(T == struct)) {
    debug(trace) printf("Allocated "~T.stringof~" @ %p\n", cast(void*)item);
}

pragma(inline, true)
void dbg_alloc(T)(T* item) if (!is(T == struct) && !is(T == class)) {
    debug(trace) printf("Allocated "~T.stringof~" @ %p\n", cast(void*)item);
}

pragma(inline, true)
void dbg_dealloc(T)(ref T item) if (is(T == class)) {
    debug(trace) printf("Freed "~T.stringof~" @ %p\n", cast(void*)item);
}

pragma(inline, true)
void dbg_dealloc(T)(ref T item) if (!is(T == class)) {
    debug(trace) printf("Freed "~T.stringof~"\n");
}