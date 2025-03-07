module hookset;
import ldc.intrinsics;
import walloc;

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
    return llvm_memcpy(dst, src, bytes);
}

void* nu_memmove(void* dst, void* src, size_t bytes) {
    return llvm_memmove(dst, src, bytes);
}

void* nu_memset(void* dst, ubyte value, size_t bytes) {
    return llvm_memset(dst, value, bytes);
}