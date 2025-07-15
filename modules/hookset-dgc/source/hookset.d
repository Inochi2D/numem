/*
    Copyright (c) 2023-2025, Kitsunebi Games
    Copyright (c) 2023-2025, Inochi2D Project
    
    Distributed under the Boost Software License, Version 1.0.
    (See accompanying LICENSE file or copy at
    https://www.boost.org/LICENSE_1_0.txt)
*/
module hookset;

// We lie here.
private {
    extern(C) extern void* gc_malloc(size_t, uint, const scope TypeInfo) pure nothrow @nogc;
    extern(C) extern void* gc_realloc(void*, size_t, uint, const scope TypeInfo) pure nothrow @nogc;
    extern(C) extern void  gc_free(void*) pure nothrow @nogc;
    extern(C) extern void _d_assert_msg(string msg, string file, uint line) nothrow @nogc;
}

export extern(C) @nogc nothrow @system:

void* nu_malloc(size_t bytes) pure {
    return gc_malloc(bytes, 0, null);
}

void* nu_realloc(void* data, size_t newSize) pure {
    return gc_realloc(data, newSize, 0, null);
}

void nu_free(void* data) pure {
    gc_free(data);
}

void* nu_memcpy(return scope void* dst, scope const void* src, size_t bytes) pure {
    dst[0..bytes] = src[0..bytes];
    return dst;
}

void* nu_memmove(return scope void* dst, scope const void* src, size_t bytes) pure {
    auto tmp = nu_malloc(bytes);
    tmp[0..bytes] = src[0..bytes];
    dst[0..bytes] = tmp[0..bytes];
    nu_free(tmp);

    return dst;
}

void* nu_memset(return scope void* dst, ubyte value, size_t bytes) pure {
    (cast(ubyte*)dst)[0..bytes] = value;
    return dst;
}

void nu_fatal(const(char)[] msg) {
    _d_assert_msg(cast(string)msg, null, 0);
}