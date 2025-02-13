/*
    Copyright (c) 2023-2025, Kitsunebi Games
    Copyright (c) 2023-2025, Inochi2D Project
    
    Distributed under the Boost Software License, Version 1.0.
    (See accompanying LICENSE file or copy at
    https://www.boost.org/LICENSE_1_0.txt)
*/
module hookset;
public import atomic;

private {

    extern(C) extern void* malloc(size_t) nothrow @nogc;
    extern(C) extern void* realloc(void*, size_t) nothrow @nogc;
    extern(C) extern void free(void*) nothrow @nogc;
    extern(C) extern void* memcpy(return scope void*, return scope void*, size_t) nothrow @nogc;
    extern(C) extern void* memmove(return scope void*, return scope void*, size_t) nothrow @nogc;
    extern(C) extern void* memset(void*, int, size_t) nothrow @nogc;

    extern(C) extern void abort() nothrow @nogc;
}

export extern(C) @nogc nothrow @system:

void* nu_malloc(size_t bytes) {
    return malloc(bytes);
}

void* nu_realloc(void* data, size_t newSize) {
    return realloc(data, newSize);
}

void nu_free(void* data) {
    free(data);
}

void* nu_memcpy(return scope void* dst, return scope void* src, size_t bytes) {
    return memcpy(dst, src, bytes);
}

void* nu_memmove(void* dst, void* src, size_t bytes) {
    return memmove(dst, src, bytes);
}

void* nu_memset(void* dst, ubyte value, size_t bytes) {
    return memset(dst, value, bytes);
}

void nu_fatal(const(char)[] msg) {
    abort();
}