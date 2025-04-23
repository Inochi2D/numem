/**
    Numem Traits
    
    Copyright:
        Copyright © 2005-2009, The D Language Foundation.
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:    
        $(HTTP digitalmars.com, Walter Bright),
        Tomasz Stachowiak (isExpressions),
        $(HTTP erdani.org, Andrei Alexandrescu),
        Shin Fujishiro,
        $(HTTP octarineparrot.com, Robert Clipsham),
        $(HTTP klickverbot.at, David Nadlinger),
        Kenji Hara,
        Shoichi Kato
        Luna Nielsen
*/
module numem.core.traits;
import numem.core.meta;

/**
    Gets a sequence over all of the fields in type $(D T).

    If $(D T) is a type with no fields, returns a sequence containing the input.
*/
template Fields(T) {
    static if(is(T == struct) || is(T == union))
        alias Fields = typeof(T.tupleof[0..$-__traits(isNested, T)]);
    else static if (is(T == class) || is(T == interface))
        alias Fields = typeof(T.tupleof);
    else
        alias Fields = AliasSeq!T;
}

/**
    Gets the base element type of type $(D T).
*/
template BaseElemOf(T) {
    static if(is(OriginalType!T == E[N], E, size_t N))
        alias BaseElemOf = BaseElemOf!E;
    else
        alias BaseElemOf = T;
}

/**
    Gets the original type of $(D T).
*/
template OriginalType(T) {
    template Impl(T) {
        static if(is(T U == enum)) alias Impl = OriginalType!U;
        else                       alias Impl = T;
    }

    alias OriginalType = ModifyTypePreservingTQ!(Impl, T);
}

/**
    Modifies type $(D T) to follow the predicate specified by $(D Modifier).
*/
template ModifyTypePreservingTQ(alias Modifier, T) {
         static if (is(T U ==          immutable U)) alias ModifyTypePreservingTQ =          immutable Modifier!U;
    else static if (is(T U == shared inout const U)) alias ModifyTypePreservingTQ = shared inout const Modifier!U;
    else static if (is(T U == shared inout       U)) alias ModifyTypePreservingTQ = shared inout       Modifier!U;
    else static if (is(T U == shared       const U)) alias ModifyTypePreservingTQ = shared       const Modifier!U;
    else static if (is(T U == shared             U)) alias ModifyTypePreservingTQ = shared             Modifier!U;
    else static if (is(T U ==        inout const U)) alias ModifyTypePreservingTQ =        inout const Modifier!U;
    else static if (is(T U ==        inout       U)) alias ModifyTypePreservingTQ =              inout Modifier!U;
    else static if (is(T U ==              const U)) alias ModifyTypePreservingTQ =              const Modifier!U;
    else                                             alias ModifyTypePreservingTQ =                    Modifier!T;
}

/**
    Removes const type qualifiers from $(D T).
*/
alias Unconst(T : const U, U) = U;

/**
    Removes shared type qualifiers from $(D T).
*/
alias Unshared(T : shared U, U) = U;

/**
    Removes all qualifiers from type T.
*/
template Unqual(T : const U, U) {
    static if(is(U == shared V, V))
        alias Unqual = V;
    else
        alias Unqual = U;
}

/**
    Gets the reference type version of type $(D T).
*/
template Ref(T) {
    static if (is(T == class) || isHeapAllocated!T)
        alias Ref = T;
    else
        alias Ref = T*;
}

/**
    Gets the reference type version of type $(D T).
*/
template Unref(T) {
    static if (!isClasslike!T && isHeapAllocated!T)
        alias Unref = typeof(*T.init);
    else
        alias Unref = T;
}

/**
    Gets the amount of bytes needed to allocate an instance of type $(D T).
*/
template AllocSize(T) {
    static if (is(T == class))
        enum AllocSize = __traits(classInstanceSize, T);
    else 
        enum AllocSize = T.sizeof;
}

/**
    Gets the alignment of type $(D T) in bytes.
*/
template AllocAlign(T) {
    static if(is(T == class))
        enum AllocAlign = __traits(classInstanceAlignment, T);
    else
        enum AllocAlign = T.alignof;
}

private struct __DummyStruct { }

/**
    Returns the rvalue equivalent of T.
*/
@property T rvalueOf(T)(T val) { return val; }

/**
    Returns the rvalue equivalent of $(D T).

    Can only be used at compile time for type checking.
*/
@property T rvalueOf(T)(inout __DummyStruct = __DummyStruct.init);

/**
    Returns the lvalue equivalent of $(D T).

    Can only be used at compile time for type checking.
*/
@property ref T lvalueOf(T)(inout __DummyStruct = __DummyStruct.init);

/**
    Gets whether $(D T) supports moving.
*/
enum isMovable(T) =
    (is(T == struct) || is(T == union)) ||
    (__traits(isStaticArray, T) && hasElaborateMove!(T.init[0]));

/**
    Gets whether $(D T) is an aggregate type (i.e. a type which contains other types)
*/
enum isAggregateType(T) =
    is(T == class) || is(T == interface) ||
    is(T == struct) || is(T == union);

/**
    Gets whether $(D T) is a class-like (i.e. class or interface)
*/
enum isClasslike(T) =
    is(T == class) || is(T == interface);

/**
    Gets whether $(D T) is a struct-like (i.e. struct or union)
*/
enum isStructLike(T) =
    is(T == struct) || is(T == union);

/**
    Gets whether the provided type is a scalar type.
*/
enum isScalarType(T) = __traits(isScalar, T) && is(T : real);

/**
    Gets whether the provided type is a basic type.
*/
enum isBasicType(T) = isScalarType!T || is(immutable T == immutable void);

/**
    Gets whether $(D T) is a pointer type.
*/
enum isPointer(T) =
    is(T == U*, U) && !isClasslike!T;

/**
    Gets whether $(D T) is heap allocated.
*/
enum isHeapAllocated(T) =
    is(T == class) || is(T == U*, U);

/**
    Gets whether type $(D T) is an array.
*/
enum isArray(T) = is(T == E[n], E, size_t n);

/**
    Gets whether type T is a floating point type.
*/
enum isFloatingPoint(T) = __traits(isFloating, T);

/**
    Gets whether type T is a integral point type.
*/
enum isIntegral(T) = __traits(isIntegral, T);

/**
    Gets whether type T is a numeric type.
*/
enum isNumeric(T) = 
    __traits(isFloating, T) && 
    __traits(isIntegral, T);

template FtoI(T) {
    static if (is(T == double))
        alias FtoI = ulong;
    else static if (is(T == float))
        alias FtoI = uint;
    else
        alias FtoI = size_t;
}

/**
    Gets whether $(D Lhs) can be assigned to $(D Rhs).
*/
template isAssignable(Lhs, Rhs = Lhs) {
    enum isAssignable = 
        __traits(compiles, lvalueOf!Lhs = rvalueOf!Rhs) && 
        __traits(compiles, lvalueOf!Lhs = lvalueOf!Rhs);
}

/**
    Gets whether $(D Lhs) can be assigned to $(D Rhs) or $(D Rhs) can be assigned to $(D Lhs).
*/
enum isAnyAssignable(Lhs, Rhs = Lhs) =
    isAssignable!(Lhs, Rhs) || isAssignable!(Rhs, Lhs);

/**
    Gets whether the unqualified versions of $(D Lhs) and $(D Rhs) are in
    any way compatible in any direction.
*/
enum isAnyCompatible(Lhs, Rhs) =
    is(Unqual!Lhs : Unqual!Rhs) || is(Unqual!Rhs : Unqual!Lhs);


/**
    Gets whether $(D symbol) has the user defined attribute $(D attrib).
*/
template hasUDA(alias symbol, alias attrib) {
    enum hasUDA = anySatisfy!(isDesiredAttr!attrib, __traits(getAttributes, symbol));
}

/**
    Gets a sequence of all of the attributes within attrib.
*/
template getUDAs(alias symbol, alias attrib) {
    alias getUDAs = Filter!(isDesiredAttr!attrib, __traits(getAttributes, symbol));
}

private
template isDesiredAttr(alias attribute) {
    // Taken from phobos.

    template isDesiredAttr(alias toCheck) {
        static if (is(typeof(attribute)) && !__traits(isTemplate, attribute)) {
            static if (__traits(compiles, toCheck == attribute))
                enum isDesiredAttr = toCheck == attribute;
            else
                enum isDesiredAttr = false;
        } else static if (is(typeof(toCheck))) {
            static if (__traits(isTemplate, attribute))
                enum isDesiredAttr = isInstanceOf!(attribute, typeof(toCheck));
            else
                enum isDesiredAttr = is(typeof(toCheck) == attribute);
        } else static if (__traits(isTemplate, attribute))
            enum isDesiredAttr = isInstanceOf!(attribute, toCheck);
        else
            enum isDesiredAttr = is(toCheck == attribute);
    }
}

/**
    Gets whether $(D T) is an instance of template $(D S).

    Returns:
        $(D true) if $(D T) is an instance of template $(D S),
        $(D false) otherwise.
*/
enum bool isInstanceOf(alias S, T) = is(T == S!Args, Args...);
template isInstanceOf(alias S, alias T) {
    enum impl(alias T : S!Args, Args...) = true;
    enum impl(alias T) = false;
    enum isInstanceOf = impl!T;
} /// ditto

/**
    Gets whether $(D T) is an Objective-C class or protocol.

    Additionally, said class or protocol needs to have the
    $(D retain) and $(D release) methods.
*/
enum isObjectiveC(T) =
    isClasslike!T && __traits(getLinkage, T) == "Objective-C";

/**
    Gets whether $(D T) is a *valid* NSObject derived
    Objective-C class or protocol.

    Said class or protocol needs to have the
    $(D retain), $(D release) and $(D autorelease) methods.

    See_Also:
        $(LINK2 https://github.com/Inochi2D/objective-d, Objective-D)
*/
enum isValidObjectiveC(T) =
    isClasslike!T && __traits(getLinkage, T) == "Objective-C" &&
    is(typeof(T.retain)) && is(typeof(T.release)) && is(typeof(T.autorelease));

/**
    Gets whether T is an inner class in a nested class layout.
*/
template isInnerClass(T) if(is(T == class)) {
    static if (is(typeof(T.outer))) {
        template hasOuterMember(T...) {
            static if (T.length == 0)
                enum hasOuterMember = false;
            else
                enum hasOuterMember = T[0] == "outer" || hasOuterMember!(T[1..$]);
        }

        enum isInnerClass = __traits(isSame, typeof(T.outer), __traits(parent, T)) && !hasOuterMember!(__traits(allMembers, T));
    } else enum isInnerClass = false;
}

/**
    Gets whether $(D T) or any of its children has an elaborate move.
*/
template hasElaborateMove(T) {
    static if (isObjectiveC!T)
        enum hasElaborateDestructor = false;
    else static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateMove = T.sizeof && hasElaborateMove!(BaseElemOf!T);
    else static if (is(T == struct))
        enum hasElaborateMove = (is(typeof(S.init.opPostMove(lvalueOf!T))) &&
                                !is(typeof(S.init.opPostMove(rvalueOf!T)))) ||
                                anySatisfy!(.hasElaborateMove, Fields!T);
    else
        enum hasElaborateMove = false;

}

/**
    Gets whether type $(D T) has elaborate assign semantics
    (i.e. is $(D opAssign) declared for the type)
*/
template hasElaborateAssign(T) {
    static if (isObjectiveC!T)
        enum hasElaborateDestructor = false;
    else static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateAssign = T.sizeof && hasElaborateAssign!(BaseElemOf!T);
    else static if (is(T == struct))
        enum hasElaborateAssign = (is(typeof(S.init.opPostMove(opAssign!T))) &&
                                !is(typeof(S.init.opPostMove(opAssign!T)))) ||
                                anySatisfy!(.hasElaborateAssign, Fields!T);
    else
        enum hasElaborateAssign = false;

}

/**
    Gets whether type $(D T) has elaborate copy constructor semantics
    (i.e. is a copy constructor or postblit constructor declared.)
*/
template hasElaborateCopyConstructor(T) {
    static if (isObjectiveC!T)
        enum hasElaborateDestructor = false;
    else static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateCopyConstructor = T.sizeof && hasElaborateCopyConstructor!(BaseElemOf!T);
    else static if (is(T == struct))
        enum hasElaborateCopyConstructor = __traits(hasCopyConstructor, T) || __traits(hasPostblit, T);
    else
        enum hasElaborateCopyConstructor = false;
}

/**
    Gets whether type $(D T) has elaborate destructor semantics (is ~this() declared).
*/
template hasElaborateDestructor(T) {
    static if (isObjectiveC!T)
        enum hasElaborateDestructor = false;
    else static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateDestructor = T.sizeof && hasElaborateDestructor!(BaseElemOf!T);
    else static if (isAggregateType!T)
        enum hasElaborateDestructor = __traits(hasMember, T, "__dtor") ||
                                      anySatisfy!(.hasElaborateDestructor, Fields!T);
    else
        enum hasElaborateDestructor = false;
}

/**
    Detect whether symbol or type $(D T) is a function, a function pointer or a delegate.

    Params:
        T = The type to check
    Returns:
        A $(D_KEYWORD bool)
 */
enum bool isSomeFunction(alias T) =
    is(T == return) ||
    is(typeof(T) == return) ||
    is(typeof(&T) == return); // @property

/**
    Detect whether $(D T) is a callable object, which can be called with the
    function call operator `$(LPAREN)...$(RPAREN)`.
*/
template isCallable(alias callable) {
    static if (is(typeof(&callable.opCall) == delegate))
        // T is a object which has a member function opCall().
        enum bool isCallable = true;
    else static if (is(typeof(&callable.opCall) V : V*) && is(V == function))
        // T is a type which has a static member function opCall().
        enum bool isCallable = true;
    else static if (is(typeof(&callable.opCall!()) TemplateInstanceType))
    {
        enum bool isCallable = isCallable!TemplateInstanceType;
    }
    else static if (is(typeof(&callable!()) TemplateInstanceType))
    {
        enum bool isCallable = isCallable!TemplateInstanceType;
    }
    else
    {
        enum bool isCallable = isSomeFunction!callable;
    }
}

/**
    Get the function type from a callable object $(D func), or from a function pointer/delegate type.

    Using builtin $(D typeof) on a property function yields the types of the
    property value, not of the property function itself.  Still,
    $(D FunctionTypeOf) is able to obtain function types of properties.

    Note:
        Do not confuse function types with function pointer types; function types are
        usually used for compile-time reflection purposes.
*/
template FunctionTypeOf(alias func)
if (isCallable!func) {
    static if ((is(typeof(& func) Fsym : Fsym*) && is(Fsym == function)) || is(typeof(& func) Fsym == delegate))
    {
        alias FunctionTypeOf = Fsym; // HIT: (nested) function symbol
    }
    else static if (is(typeof(& func.opCall) Fobj == delegate) || is(typeof(& func.opCall!()) Fobj == delegate))
    {
        alias FunctionTypeOf = Fobj; // HIT: callable object
    }
    else static if (
            (is(typeof(& func.opCall) Ftyp : Ftyp*) && is(Ftyp == function)) ||
            (is(typeof(& func.opCall!()) Ftyp : Ftyp*) && is(Ftyp == function))
        )
    {
        alias FunctionTypeOf = Ftyp; // HIT: callable type
    }
    else static if (is(func T) || is(typeof(func) T))
    {
        static if (is(T == function))
            alias FunctionTypeOf = T;    // HIT: function
        else static if (is(T Fptr : Fptr*) && is(Fptr == function))
            alias FunctionTypeOf = Fptr; // HIT: function pointer
        else static if (is(T Fdlg == delegate))
            alias FunctionTypeOf = Fdlg; // HIT: delegate
        else
            static assert(0);
    }
    else
        static assert(0);
}

/**
    Get the type of the return value from a function,
    a pointer to function, a delegate, a struct
    with an opCall, a pointer to a struct with an opCall,
    or a class with an $(D opCall). Please note that $(D_KEYWORD ref)
    is not part of a type, but the attribute of the function.

    Note:
        To reduce template instantiations, consider instead using
        $(D_INLINECODE typeof(() { return func(args); } ())) if the argument types are known or
        $(D_INLINECODE static if (is(typeof(func) Ret == return))) if only that basic test is needed.
*/
template ReturnType(alias func)
if (isCallable!func) {
    static if (is(FunctionTypeOf!func R == return))
        alias ReturnType = R;
    else
        static assert(0, "argument has no return type");
}

/**
    Get, as a tuple, the types of the parameters to a function, a pointer
    to function, a delegate, a struct with an `opCall`, a pointer to a
    struct with an `opCall`, or a class with an `opCall`.
*/
template Parameters(alias func)
if (isCallable!func) {
    static if (is(FunctionTypeOf!func P == function))
        alias Parameters = P;
    else
        static assert(0, "argument has no parameters");
}