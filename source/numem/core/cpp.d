module numem.core.cpp;
import numem.core.traits;
import numem.core.lifetime;

/**
    Allocates a new C++ type on the heap using its default constructor.

    Notes:
        $(D doXCtor) is used to specify whether to also call any D mangled
        constructors defined for the C++ type.

    Params:
        args = The arguments to pass to the type's constructor.
    
    Returns:
        A newly allocated and instantiated C++ object using the
        C++ Runtime.
*/
Ref!T _nu_cpp_new(T, bool doXCtor, Args...)(auto ref Args args) @nogc if (isCPP!T) {
    static if (isClasslike!T) {
        Ref!T result = cast(Ref!T)__cpp_new(__traits(classInstanceSize, T));

        static if (doXCtor)
            emplace(result, forward!args);
    } else {
        Ref!T result = cast(Ref!T)__cpp_new(T.sizeof);

        static if (doXCtor)
            emplace(*result, forward!args);
    }
    return result;
}

/**
    Deletes a C++ object on the heap.

    Notes:
        $(D doXDtor) is used to specify whether to also call any D mangled
        destructors defined for the C++ type.

    Params:
        ptr = The object to delete.
*/
void _nu_cpp_delete(T, bool doXDtor)(ref T ptr) @nogc if (isCPP!T) {
    if (ptr is null)
        return;
    
    static if (doXDtor)
        destruct!(T, false)(ptr);
    
    __cpp_delete(cast(void*)ptr);
    ptr = null;
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