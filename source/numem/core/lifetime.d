/**
    Numem Internal Lifetime Handling.

    This module implements the neccesary functionality to instantiate
    complex D types, including handling of copy constructors,
    destructors, moving, and copying.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.core.lifetime;
import numem.core.hooks;
import numem.core.traits;
import numem.core.exception;
import numem.core.memory;
import numem.casting;
import numem.lifetime : nogc_construct, nogc_initialize, nogc_delete;

// Deletion function signature.
private extern (D) alias fp_t = void function (Object) @nogc nothrow;

// Helper which creates a destructor function that
// D likes.
private template xdtor(T) {
    void xdtor(ref T obj) {
        obj.__xdtor();
    }
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
        nu_memcpy(cast(void*)chunk, cast(void*)initSym.ptr, initSym.length);
    } else static if (__traits(isZeroInit, T)) {

        nu_memset(cast(void*)&chunk, 0, T.sizeof);
    } else static if (__traits(isScalar, T) || 
        (T.sizeof <= 16 && !hasElaborateAssign!T && __traits(compiles, () { T chunk; chunk = T.init; }))) {

        // To avoid triggering postblits/move constructors we need to do a memcpy here as well.
        // If the user wants to postblit after initialization, they should call the relevant postblit function.
        T tmp = T.init;
        nu_memcpy(cast(void*)&chunk, &tmp, T.sizeof);
    } else static if (__traits(isStaticArray, T)) {

        foreach(i; 0..T.length)
            initializeAt(chunk[i]);
    } else {

        const void[] initSym = __traits(initSymbol, T);
        nu_memcpy(cast(void*)&chunk, initSym.ptr, initSym.length);
    }
}

/**
    Initializes the memory at the specified chunk, but ensures no 
    context pointers are wiped.
*/
void initializeAtNoCtx(T)(scope ref T chunk) @nogc nothrow @trusted {
    static if (__traits(isZeroInit, T)) {

        nu_memset(cast(void*)&chunk, 0, T.sizeof);
    } else static if (__traits(isScalar, T) || 
        (T.sizeof <= 16 && !hasElaborateAssign!T && __traits(compiles, () { T chunk; chunk = T.init; }))) {

        // To avoid triggering postblits/move constructors we need to do a memcpy here as well.
        // If the user wants to postblit after initialization, they should call the relevant postblit function.
        T tmp = T.init;
        nu_memcpy(cast(void*)&chunk, &tmp, T.sizeof);
    } else static if (__traits(isStaticArray, T)) {

        foreach(i; 0..T.length)
            initializeAt(chunk[i]);
    } else {

        const void[] initSym = __traits(initSymbol, T);
        nu_memcpy(cast(void*)&chunk, initSym.ptr, initSym.length);
    }
}

/**
    Destroy element with a destructor.
*/
@trusted
void destruct(T, bool reInit=true)(ref T obj_) @nogc {
    alias RealT = Unref!T;

    // Handle custom destruction functions.
    alias destroyWith = nu_getdestroywith!RealT;
    static if (is(typeof(destroyWith))) {
        destroyWith(obj_);
    } else {
        static if (isHeapAllocated!T) {
            if (obj_ !is null) {
                static if (__traits(getLinkage, RealT) == "D") {
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
                        static if (__traits(hasMember, RealT, "__xdtor")) {
                            assumeNoGC(&obj_.__xdtor);
                        } else static if (__traits(hasMember, RealT, "__dtor")) {
                            assumeNoGC(&obj_.__dtor);
                        }
                    }
                } else static if (__traits(getLinkage, Unref!T) == "C++") {

                    // C++ and Objective-C types may have D destructors declared
                    // with extern(D), in that case, just call those.

                    static if (__traits(hasMember, RealT, "__xdtor")) {
                        assumeNoGC(&xdtor!T, obj_);
                    }
                } else static if (__traits(hasMember, RealT, "__xdtor")) {
                    
                    // Item is liekly a struct, we can destruct it directly.
                    assumeNoGC(&xdtor!T, obj_);
                }
            }
        } else {

            // Item is a struct, we can destruct it directly.
            static if (__traits(hasMember, RealT, "__xdtor")) {
                assumeNoGC(&obj_.__xdtor);
            } else static if (__traits(hasMember, RealT, "__dtor")) {
                assumeNoGC(&obj_.__dtor);
            }
        }
    }

    static if (reInit)
        initializeAt(obj_);
}

/**
    Runs constructor for the memory at dst
*/
void emplace(T, UT, Args...)(ref UT dst, auto ref Args args) @nogc {
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

        static if (is(typeof(dst.__ctor(forward!fargs)))) {
            dst.__ctor(forward!args);
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
        chunk.__ctor(forward!args);
    } else {
        static assert(!(Args.length == 1 && is(Args[0] : T)),
            "Can't emplace a " ~ T.stringof ~ " because the postblit is disabled.");

        static assert(0, 
            "No constructor for " ~ T.stringof ~ " found matching arguments "~fargs.stringof~"!");
    }
}

/// ditto
void emplace(UT, Args...)(auto ref UT dst, auto ref Args args) @nogc {
    emplace!(UT, UT, Args)(dst, forward!args);
}

/**
    Copies source to target.
*/
void __copy(S, T)(ref S source, ref T target) @nogc {
    static if (is(T == struct)) {
        static if (!__traits(hasCopyConstructor, T))
            __blit(target, source);
        
        static if (hasElaborateCopyConstructor!T)
            __copy_postblit(source, target);
    } else static if (is(T == E[n], E, size_t n)) {
        
        // Some kind of array or range.
        static if (hasElaborateCopyConstructor!E) {
            size_t i;
            try {
                for(i = 0; i < n; i++)
                    __copy(source[i], target[i]);
            } catch(Exception ex) {
                while(i--) {
                    auto ref_ = const_cast!(Unconst!(E)*)(&target[i]);
                    destruct(ref_);
                    nu_free(cast(void*)ref_);
                }
                throw e;
            }
        } else static if (!__traits(hasCopyConstructor, T))
            __blit(target, source);
    } else {
        *(const_cast!(Unconst!(T)*)(&target)) = *const_cast!(Unconst!(T)*)(&source);
    }
}

/**
    Moves $(D source) to $(D target), via destructive copy if neccesary.

    $(D source) will be reset to its init state after the move.
*/
void __move(S, T)(ref S source, ref T target) @nogc @trusted {
    static if (is(T == struct) && hasElaborateDestructor!T) {
        if(&source is &target)
            return;

        destruct!(T, false)(target);
    }

    return __moveImpl(source, target);
}

/// ditto
T __move(T)(ref return scope T source) @nogc @trusted {
    T target = void;
    __moveImpl(source, target);
    return target;
}

private
pragma(inline, true)
void __moveImpl(S, T)(ref S source, ref T target) @nogc @trusted {
    static if(is(T == struct)) {
        assert(&source !is &target, "Source and target must not be identical");
        __blit(target, source);
        
        static if (hasElaborateMove!T)
            __move_postblit(target, source);

        // If the source defines a destructor or a postblit the type needs to be
        // obliterated to avoid double frees and undue aliasing.
        static if (hasElaborateDestructor!T || hasElaborateCopyConstructor!T) {
            initializeAtNoCtx(source);
        }
    } else static if (is(T == E[n], E, size_t n)) {
        static if (!hasElaborateMove!T && 
                   !hasElaborateDestructor!T && 
                   !hasElaborateCopyConstructor!T) {
            
            assert(source.ptr !is target.ptr, "Source and target must not be identical");
            __blit(target, source);
            initializeAt(source);
        } else {
            foreach(i; 0..source.length) {
                __move(source[i], target[i]);
            }
        }
    } else {
        target = source;
        initializeAt(source);
    }
}

/**
    Blits instance $(D from) to location $(D to).

    Effectively this acts as a simple memory copy, 
    a postblit needs to be run after to finalize the object.
*/
pragma(inline, true)
void __blit(T)(ref T to, ref T from) @nogc nothrow {
    nu_memcpy(const_cast!(Unqual!T*)(&to), const_cast!(Unqual!T*)(&from), AllocSize!T);
}

/**
    Runs postblit operations for a copy operation.
*/
pragma(inline, true)
void __copy_postblit(S, T)(ref S source, ref T target) @nogc nothrow {
    static if (__traits(hasPostblit, T)) {
        dst.__xpostblit();
    } else static if (__traits(hasCopyConstructor, T)) {

        // https://issues.dlang.org/show_bug.cgi?id=22766
        initializeAt(target);

        // Copy context pointer if needed.
        static if (__traits(isNested, T))
            *(cast(void**)&target.tupleof[$-1]) = cast(void*) source.tupleof[$-1];
        
        // Invoke copy ctor.
        target.__ctor(source);
    }
}

/**
    Ported from D runtime, this function is released under the boost license.

    Recursively calls the $(D opPostMove) callbacks of a struct and its members if
    they're defined.

    When moving a struct instance, the compiler emits a call to this function
    after blitting the instance and before releasing the original instance's
    memory.

    Params:
        newLocation = reference to struct instance being moved into
        oldLocation = reference to the original instance

    Notes:
        $(D __move_postblit) will do nothing if the type does not support elaborate moves.
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

/**
    Forwards function arguments while keeping $(D out), $(D ref), and $(D lazy) on
    the parameters.

    Params:
        args = a parameter list or an $(REF AliasSeq,std,meta).
    
    Returns:
        An $(D AliasSeq) of $(D args) with $(D out), $(D ref), and $(D lazy) saved.
*/
template forward(args...)
{
    import core.internal.traits : AliasSeq;
    import numem.object;

    template fwd(alias arg)
    {
        // by ref || lazy || const/immutable
        static if (__traits(isRef,  arg) ||
                   __traits(isOut,  arg) ||
                   __traits(isLazy, arg) ||
                   !is(typeof(__move(arg))))
            alias fwd = arg;
        // (r)value
        else
            @property auto fwd()
            {
                version (DigitalMars) { /* @@BUG 23890@@ */ } else pragma(inline, true);
                return __move(arg);
            }
    }

    alias Result = AliasSeq!();
    static foreach (arg; args)
        Result = AliasSeq!(Result, fwd!arg);
    static if (Result.length == 1)
        alias forward = Result[0];
    else
        alias forward = Result;
}

/**
    UDA which allows specifying which functions numem should call when
    destroying an object with $(D destruct).
*/
struct nu_destroywith(alias handlerFunc) {
private:
    alias Handler = handlerFunc;
}

/**
    UDA which allows specifying which functions numem should call when
    autoreleasing an object with $(D nu_autorelease).
*/
struct nu_autoreleasewith(alias handlerFunc) {
private:
    alias Handler = handlerFunc;
}

/**
    Adds the given item to the topmost auto release pool.

    Params:
        item =  The item to automatically be destroyed when the pool
                goes out of scope.
    
    Returns:
        $(D true) if the item was successfully added to the pool,
        $(D false) otherwise.
*/
bool nu_autorelease(T)(T item) @trusted @nogc {
    static if (isValidObjectiveC!T) {
        item.autorelease();
    } else {
        alias autoreleaseWith = nu_getautoreleasewith!T;
        
        if (nu_arpool_stack.length > 0) {
            nu_arpool_stack[$-1].push(
                nu_arpool_element(
                    cast(void*)item,
                    (void* obj) {
                        T obj_ = cast(T)obj;
                        static if (is(typeof(autoreleaseWith))) {
                            autoreleaseWith(obj_);
                        } else {
                            nogc_delete!(T)(obj_);
                        }
                    }
                )
            );
            return true;
        }
        return false;
    }
}

/**
    Pushes an auto release pool onto the pool stack.

    Returns:
        A context pointer, meaning is arbitrary.

    Memorysafety:
        $(D nu_autoreleasepool_push) and $(D nu_autoreleasepool_pop) are internal
        API and are not safely used outside of the helpers.
    
    See_Also:
        $(D numem.lifetime.autoreleasepool_scope), 
        $(D numem.lifetime.autoreleasepool)
*/
void* nu_autoreleasepool_push() @system @nogc {
    nu_arpool_stack.nu_resize(nu_arpool_stack.length+1);
    nogc_construct(nu_arpool_stack[$-1]);

    if (nuopt_autoreleasepool_push)
        nu_arpool_stack[$-1].fctx = nuopt_autoreleasepool_push();

    
    return cast(void*)&nu_arpool_stack[$-1];
}

/**
    Pops an auto release pool from the pool stack.

    Params:
        ctx = A context pointer.

    Memorysafety:
        $(D nu_autoreleasepool_push) and $(D nu_autoreleasepool_pop) are internal
        API and are not safely used outside of the helpers.
    
    See_Also:
        $(D numem.lifetime.autoreleasepool_scope), 
        $(D numem.lifetime.autoreleasepool)
*/
void nu_autoreleasepool_pop(void* ctx) @system @nogc {
    if (nu_arpool_stack.length > 0) {
        assert(ctx == &nu_arpool_stack[$-1], "Misaligned auto release pool sequence!");

        nu_arpool_stack.nu_resize(cast(ptrdiff_t)nu_arpool_stack.length-1);
        if (nuopt_autoreleasepool_pop)
            nuopt_autoreleasepool_pop(ctx);
    }
}


//
//          INTERNAL
//

private:
import numem.object : NuRefCounted;

// auto-release pool stack.
__gshared nu_arpool_ctx[] nu_arpool_stack;

// Handler function type.
alias nu_arpool_handler_t = void function(void*) @nogc;

// Handlers within an auto-release pool context.
struct nu_arpool_element {
    void* ptr;
    nu_arpool_handler_t handler;
}

// An autorelease pool context.
struct nu_arpool_ctx {
@nogc:
    nu_arpool_element[] queue;
    void* fctx;

    ~this() {
        foreach_reverse(ref item; queue) {
            item.handler(item.ptr);
            nogc_initialize(item);
        }
        queue.nu_resize(0);
    }

    void push(nu_arpool_element element) {
        queue.nu_resize(queue.length+1);
        queue[$-1] = element;
    }
}

// DESTROY UDA

template nu_getdestroywith(T, A...) {
    static if (A.length == 0) {
        alias attrs = __traits(getAttributes, Unref!T);

        static if (attrs.length > 0)
            alias nu_getdestroywith = nu_getdestroywith!(T, attrs);
        else
            alias nu_getdestroywith = void;
    } else static if (A.length == 1) {
        static if (nu_isdestroywith!(T, A[0]))
            alias nu_getdestroywith = A[0].Handler;
        else
            alias nu_getdestroywith = void;
    } else static if (nu_isdestroywith!(T, A[0]))
            alias nu_getdestroywith = A[0].Handler;
        else
            alias nu_getdestroywith = nu_getdestroywith!(T, A[1 .. $]);
}

enum nu_isdestroywith(T, alias H) = 
    __traits(identifier, H) == __traits(identifier, nu_destroywith) &&
    is(typeof(H.Handler)) && 
    is(typeof((H.Handler(lvalueOf!T))));

// AUTORELEASE UDA

template nu_getautoreleasewith(T, A...) {
    static if (A.length == 0) {
        alias attrs = __traits(getAttributes, T);

        static if (attrs.length > 0)
            alias nu_getautoreleasewith = nu_getautoreleasewith!(T, attrs);
        else
            alias nu_getautoreleasewith = void;
    } else static if (A.length == 1) {
        static if (nu_isautoreleasewith!(T, A[0]))
            alias nu_getautoreleasewith = A[0].Handler;
        else
            alias nu_getautoreleasewith = void;
    } else static if (nu_isautoreleasewith!(T, A[0]))
            alias nu_getautoreleasewith = A[0].Handler;
        else
            alias nu_getautoreleasewith = nu_getautoreleasewith!(T, A[1 .. $]);
}

enum nu_isautoreleasewith(T, alias H) = 
    __traits(identifier, H) == __traits(identifier, nu_autoreleasewith) &&
    is(typeof(H.Handler)) && 
    is(typeof((H.Handler(lvalueOf!T))));