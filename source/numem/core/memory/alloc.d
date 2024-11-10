module numem.core.memory.alloc;
public import core.stdc.stdlib : free, malloc, exit;
import std.traits;

@nogc nothrow:

// Deletion function signature.
private extern (D) alias fp_t = void function (Object);

/**
    Destroy element with a destructor.
*/
@trusted
void destruct(T)(ref T obj_) {

    static if (isPointer!T || is(T == class)) {
        if (obj_ !is null) {
            auto cInfo = cast(ClassInfo)typeid(obj_);
            if (cInfo) {
                auto c = cInfo;

                // Call destructors in order of most specific
                // to least-specific
                do {
                    if (c.destructor)
                        (cast(fp_t)c.destructor)(cast(Object)obj_);
                } while((c = c.base) !is null);
                
            } else {

                // Item is a struct, we can destruct it directly.
                static if (__traits(hasMember, T, "__dtor")) {
                    assumeNothrowNoGC!(typeof(&obj_.__dtor))(&obj_.__dtor)();
                } else static if (__traits(hasMember, T, "__xdtor")) {
                    assumeNothrowNoGC!(typeof(&obj_.__xdtor))(&obj_.__xdtor)();
                }
            }

            free(cast(void*)obj_);
            obj_ = null;
        }
    } else {

        // Item is a struct, we can destruct it.
        static if (__traits(hasMember, T, "__dtor")) {
            assumeNothrowNoGC!(typeof(&obj_.__dtor))(&obj_.__dtor)();
        } else static if (__traits(hasMember, T, "__xdtor")) {
            assumeNothrowNoGC!(typeof(&obj_.__xdtor))(&obj_.__xdtor)();
        }
    }
}

/**
    Forces a function to assume that it's nogc compatible.
*/
auto assumeNoGC(T) (T t) {
    static if (isFunctionPointer!T || isDelegate!T) {
        enum attrs = functionAttributes!T | FunctionAttribute.nogc;
        return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
    } else static assert(false);
}

/**
    Forces a function to assume that it's nothrow nogc compatible.
*/
auto assumeNothrowNoGC(T) (T t) {
    static if (isFunctionPointer!T || isDelegate!T) {
        enum attrs = functionAttributes!T | FunctionAttribute.nogc | FunctionAttribute.nothrow_;
        return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
    } else static assert(false);
}