module numem.core.cpp;
import numem.core.traits;
import numem.core.lifetime;

/**
    Allocates a new C++ type on the heap.

    Params:
        args = The arguments to pass to the type's constructor.
    
    Returns:
        A newly allocated and instantiated C++ object using the
        C++ Runtime.
*/
Ref!T cpp_new(T, Args...)(auto ref Args args) if (isCPP!T) {
    static if (isClasslike!T) {
        Ref!T result = cast(Ref!T)__cpp_new(__traits(classInstanceSize, T));
        emplace(result, forward!args);
    } else {
        Ref!T result = cast(Ref!T)__cpp_new(T.sizeof);
        emplace(*result, forward!args);
    }
    return result;
}

/**
    Helper function which allocates a C++ object of
    a given size.
*/
void cpp_delete(T)(Ref!T ptr) if (isCPP!T) {
    if (ptr is null)
        return;
    
    destruct!(T, false)(ptr);
    __cpp_delete(cast(void*)ptr);
}

private extern(C++) @nogc:
version (CppRuntime_Microsoft) {
    version(D_LP64) {
        
        pragma(mangle, "??2@YAPEAX_K@Z")
        void* __cpp_new(size_t bytes);

        pragma(mangle, "??3@YAXPEAX@Z")
        void __cpp_delete(void* ptr);
    } else {
        
        pragma(mangle, "??2@YAPAXI@Z")
        void* __cpp_new(size_t bytes);

        pragma(mangle, "??3@YAXPAX@Z")
        void __cpp_delete(void* ptr);
    }
} else {
    version(D_LP64) {
        
        pragma(mangle, "_Znwm")
        void* __cpp_new(size_t bytes);

        pragma(mangle, "_ZdlPv")
        void __cpp_delete(void* ptr);
    } else {
        
        pragma(mangle, "_Znwj")
        void* __cpp_new(size_t bytes);

        pragma(mangle, "_ZdlPv")
        void __cpp_delete(void* ptr);
    }
}