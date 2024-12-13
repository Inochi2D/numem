/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Lifetime handling in numem.
*/
module numem.core.memory.lifetime;
import numem.core.utils;
import numem.core.hooks;
import numem.core.trace;
import core.lifetime : forward;
import core.internal.traits;

// Deletion function signature.
private extern (D) alias fp_t = void function (Object) @nogc nothrow;

/**
    Destroy element with a destructor.
*/
@trusted
void destruct(T, bool doFree=true)(ref T obj_) @nogc nothrow {

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

            static if (doFree) {
                nuFree(cast(void*)obj_);
                obj_ = null;
            }
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
    Gets the amount of bytes needed to allocate an instance of type `T`.
*/
template nuAllocSize(T) {
    static if (is(T == class))
        enum nuAllocSize = __traits(classInstanceSize, T);
    else 
        enum nuAllocSize = T.sizeof;
}

/**
    Initializes the memory at the specified chunk.
*/
void initializeAt(T)(scope ref T chunk) @nogc nothrow @trusted {
    static if (is(T == class)) {

        // NOTE: class counts as a pointer, so its normal init symbol
        // in general circumstances is null, we don't want this, so class check
        // should be first! Otherwise the chunk = T.init will mess us up.
        const void[] initSym = __traits(initSymbol, T);
        nuMemcpy(cast(void*)chunk, initSym.ptr, initSym.length);
    } else static if (__traits(isZeroInit, T)) {
        nuMemset(cast(void*)&chunk, 0, T.sizeof);
    } else static if (__traits(isScalar, T) || 
        (T.sizeof <= 16 && !hasElaborateAssign!T && __traits(compiles, () { T chunk; chunk = T.init; }))) {
        chunk = T.init;
    } else static if (__traits(isStaticArray, T)) {
        foreach(i; 0..T.length)
            initializeAt(chunk[i]);
    } else {
        const void[] initSym = __traits(initSymbol, T);
        nuMemcpy(cast(void*)&chunk, initSym.ptr, initSym.length);
    }
}

/**
    Runs constructor for the memory at dst
*/
void emplace(T, UT, Args...)(ref UT dst, auto ref Args args) @nogc nothrow {
    enum isConstructibleOther =
        (!is(T == struct) && Args.length == 1) ||                        // Primitives, enums, arrays.
        (Args.length == 1 && is(typeof({T t = forward!(args[0]); }))) || // Conversions
        is(typeof(T(forward!args)));                                     // General constructors.

    static if (is(T == class)) {

        static assert(!__traits(isAbstractClass, T), 
            T.stringof ~ " is abstract and can't be emplaced.");

        // NOTE: Since we need to handle inner-classes
        // we need to initialize here instead of next to the ctor.
        initializeAt(dst);
        
        static if (isInnerClass!T) {
            static assert(Args.length > 0,
                "Initializing an inner class requires a pointer to the outer class");
            
            static assert(is(Args[0] : typeof(T.outer)),
                "The first argument must be a pointer to the outer class");
            
            chunk.outer = args[0];
            alias fargs = args[1..$];
            alias fargsT = Args[1..$];

        } else {
            alias fargs = args;
            alias fargsT = Args;
        }
        import core.stdc.stdio : printf;

        static if (is(typeof(dst.__ctor(forward!fargs)))) {
            assumeNothrowNoGC((T chunk, fargsT args) {
                chunk.__ctor(forward!args);
            })(dst, fargs);
        } else {
            static assert(fargs.length == 0 && !is(typeof(&T.__ctor)),
                "No constructor for " ~ T.stringof ~ " found matching arguments "~fargsT.stringof~"!");
        }

    } else static if (args.length == 0) {

        static assert(is(typeof({static T i;})),
            "Cannot emplace a " ~ T.stringof ~ ", its constructor is marked with @disable.");
        initializeAt(dst);
    } else static if (isConstructibleOther) {

        // Handler struct which forwards construction
        // to the payload.
        static struct S {
            T payload;
            this()(auto ref Args args) {
                static if (__traits(compiles, payload = forward!args))
                    payload = forward!args;
                else
                    payload = T(forward!args);
            }
        }

        if (__ctfe) {
            static if (__traits(compiles, dst = T(forward!args)))
                dst = T(forward!args);
            else static if(args.length == 1 && __traits(compiles, dst = forward!(args[0])))
                dst = forward!(args[0]);
            else static assert(0,
                "Can't emplace " ~ T.stringof ~ " at compile-time using " ~ Args.stringof ~ ".");
        } else {
            S* p = cast(S*)cast(void*)&dst;
            static if (UT.sizeof > 0)
                initializeAt(*p);
            
            p.__ctor(forward!args);
        }
    } else static if (is(typeof(dst.__ctor(forward!args)))) {
        
        initializeAt(dst);
        assumeNothrowNoGC((T chunk, Args args) {
            chunk.__ctor(forward!args);
        })(dst, args);
    } else {
        static assert(!(Args.length == 1 && is(Args[0] : T)),
            "Can't emplace a " ~ T.stringof ~ " because the postblit is disabled.");

        static assert(0, 
            "No constructor for " ~ T.stringof ~ " found matching arguments "~fargs.stringof~"!");
    }
}

/// 
void emplace(UT, Args...)(auto ref UT dst, auto ref Args args) @nogc nothrow {
    emplace!(UT, UT, Args)(dst, forward!args);
}

/**
    Gets the reference type version of type T.
*/
template RefT(T) {
    static if (is(T == class) || isPointer!T)
        alias RefT = T;
    else
        alias RefT = T*;
}

/**
    Gets whether `T` supports moving.
*/
enum IsMovable(T) =
    is(T == struct) ||
    (__traits(isStaticArray, T) && hasElaborateMove!(T.init[0]));

/**
    Blits instance `from` to location `to`.
*/
void __blit(T, bool copy)(ref T to, ref T from) {
    nuMemcpy(to, from, nuAllocSize!T);
    static if (copy) __copy_postblit(to, from);
    else __move_postblit(to, from);
}

/**
    Runs copy postblit operations for `dst`.

    If `dst` has a copy constructor it will be run,
    otherwise if it has a `this(this)` postblit that will be run.

    If no form of postblit is available, this function will be NO-OP.
*/
pragma(inline, true)
void __copy_postblit(T)(ref T dst, ref T src) @nogc nothrow {
    static if (__traits(hasCopyConstructor, T)) {
        dst.__ctor(src);
    } else static if(__traits(hasPostblit, T)) {
        dst.__xpostblit();
    }
}

/**
    Ported from D runtime, this function is released under the boost license.

    Recursively calls the `opPostMove` callbacks of a struct and its members if
    they're defined.

    When moving a struct instance, the compiler emits a call to this function
    after blitting the instance and before releasing the original instance's
    memory.

    Params:
        newLocation = reference to struct instance being moved into
        oldLocation = reference to the original instance

    __move_postblit will do nothing if the type does not support elaborate moves.
*/
pragma(inline, true)
void __move_postblit(T)(ref T newLocation, ref T oldLocation) {
    static if (is(T == struct)) {

        // Call __most_postblit for all members which have move semantics.
        static foreach(i, M; typeof(T.tupleof)) {
            static if (hasElaborateMove!T) {
                __move_postblit(newLocation.tupleof[i], oldLocation.tupleof[i]);
            }
        }

        static if (__traits(hasMember, T, "opPostMove")) {
            static assert(is(typeof(T.init.opPostMove(lvalueOf!T))) &&
                          !is(typeof(T.init.opPostMove(rvalueOf!T))),
                "`" ~ T.stringof ~ ".opPostMove` must take exactly one argument of type `" ~ T.stringof ~ "` by reference");
        
            newLocation.opPostMove(oldLocation);
        }
    } else static if (__traits(isStaticArray, T)) {
        static if (T.length && hasElaborateMove!(typeof(newLocation[0]))) {
            foreach(i; 0..T.length)
                __move_postblit(newLocation[i], oldLocation[i]);
        }
    }
}