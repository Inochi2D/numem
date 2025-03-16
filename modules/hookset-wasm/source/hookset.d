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

void* nu_memcpy(return scope void* dst, scope const void* src, size_t bytes) pure {
    llvm_memcpy(dst, src, bytes);
    return dst;
}

void* nu_memmove(return scope void* dst, scope const void* src, size_t bytes) pure {
    llvm_memmove(dst, src, bytes);
    return dst;
}

void* nu_memset(return scope void* dst, ubyte value, size_t bytes) pure {
    llvm_memset(dst, value, bytes);
    return dst;
}

void nu_fatal(const(char)[] msg) {
    llvm_trap();
}