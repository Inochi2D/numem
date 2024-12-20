/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    Numem traits collection.
*/
module numem.core.traits;
import numem.core.meta;
import std.traits;

/**
    Gets a sequence over all of the fields in type `T`.

    If `T` is a type with no fields, returns a sequence containing the input.
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
    Gets the base element type of type `T`.
*/
template BaseElemOf(T) {
    static if(is(OriginalType!T == E[N], E, size_t N))
        alias BaseElemOf = BaseElemOf!E;
    else
        alias BaseElemOf = T;
}

/**
    Gets the original type of `T`.
*/
template OriginalType(T) {
    template Impl(T) {
        static if(is(T U == enum)) alias Impl = OriginalType!U;
        else                       alias Impl = T;
    }

    alias OriginalType = ModifyTypePreservingTQ!(Impl, T);
}

/**
    Modifies type `T` to follow the predicate specified by `Modifier`.
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
    Removes const type qualifiers from `T`.
*/
alias Unconst(T : const U, U) = U;

/**
    Removes shared type qualifiers from `T`.
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
    Gets the reference type version of type `T`.
*/
template Ref(T) {
    static if (is(T == class) || isHeapAllocated!T)
        alias Ref = T;
    else
        alias Ref = T*;
}

/**
    Gets the amount of bytes needed to allocate an instance of type `T`.
*/
template AllocSize(T) {
    static if (is(T == class))
        enum AllocSize = __traits(classInstanceSize, T);
    else 
        enum AllocSize = T.sizeof;
}

/**
    Gets the alignment of type `T` in bytes.
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
@property T rvalueOf(T)(T val) => val;

/**
    Returns the rvalue equivalent of `T`.

    Can only be used at compile time for type checking.
*/
@property T rvalueOf(T)(inout(__DummyStruct) = __DummyStruct.init);

/**
    Returns the lvalue equivalent of `T`.

    Can only be used at compile time for type checking.
*/
@property ref T lvalueOf(T)(inout __DummyStruct = __DummyStruct.init);

/**
    Gets whether `T` supports moving.
*/
enum isMovable(T) =
    (is(T == struct) || is(T == union)) ||
    (__traits(isStaticArray, T) && hasElaborateMove!(T.init[0]));

/**
    Gets whether `T` is an aggregate type (i.e. a type which contains other types)
*/
enum isAggregateType(T) =
    is(T == class) || is(T == interface) ||
    is(T == struct) || is(T == union);

/**
    Gets whether `T` is a class-like (i.e. class or interface)
*/
enum isClasslike(T) =
    is(T == class) || is(T == interface);

/**
    Gets whether the provided type is a scalar type.
*/
enum isScalarType(T) = __traits(isScalar, T) && is(T : real);

/**
    Gets whether the provided type is a basic type.
*/
enum isBasicType(T) = isScalarType!T || is(immutable T == immutable void);

/**
    Gets whether `T` is a pointer type.
*/
enum isPointer(T) =
    is(T == U*, U) && !isClasslike!T;

/**
    Gets whether `T` is heap allocated.
*/
enum isHeapAllocated(T) =
    is(T == class) || is(T == U*, U);

/**
    Gets whether type `T` is an array.
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
    Gets whether `Lhs` can be assigned to `Rhs`.
*/
template isAssignable(Lhs, Rhs = Lhs) {
    enum isAssignable = 
        __traits(compiles, lvalueOf!Lhs = rvalueOf!Rhs) && 
        __traits(compiles, lvalueOf!Lhs = lvalueOf!Rhs);
}

/**
    Gets whether `Lhs` can be assigned to `Rhs` or `Rhs` can be assigned to `Lhs`.
*/
enum isAnyAssignable(Lhs, Rhs = Lhs) =
    isAssignable!(Lhs, Rhs) || isAssignable!(Rhs, Lhs);

/**
    Gets whether the unqualified versions of `Lhs` and `Rhs` are in
    any way compatible in any direction.
*/
enum isAnyCompatible(Lhs, Rhs) =
    is(Unqual!Lhs : Unqual!Rhs) || is(Unqual!Rhs : Unqual!Lhs);

/**
    Gets whether `symbol` has the user defined attribute `attrib`.
*/
template hasUDA(alias symbol, alias attrib) {

    enum isAttr(T) = is(T == attrib);
    enum hasUDA = anySatisfy!(isAttr, __traits(getAttributes, symbol));
}

/**
    Gets a sequence of all of the attributes within attrib.
*/
template getUDAs(alias symbol, alias attrib) {

    enum isAttr(T) = is(T == attrib);
    alias getUDAs = Filter!(isAttr, __traits(getAttributes, symbol));
}

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
    Gets whether `T` or any of its children has an elaborate move.
*/
template hasElaborateMove(T) {
    static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateMove = T.sizeof && hasElaborateMove!(BaseElemOf!T);
    else static if (is(T == struct))
        enum hasElaborateMove = (is(typeof(S.init.opPostMove(lvalueOf!T))) &&
                                !is(typeof(S.init.opPostMove(rvalueOf!T)))) ||
                                anySatisfy!(.hasElaborateMove, Fields!T);
    else
        enum hasElaborateMove = false;

}

/**
    Gets whether type `T` has elaborate assign semantics
    (i.e. is `opAssign` declared for the type)
*/
template hasElaborateAssign(T) {
    static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateAssign = T.sizeof && hasElaborateAssign!(BaseElemOf!T);
    else static if (is(T == struct))
        enum hasElaborateAssign = (is(typeof(S.init.opPostMove(opAssign!T))) &&
                                !is(typeof(S.init.opPostMove(opAssign!T)))) ||
                                anySatisfy!(.hasElaborateAssign, Fields!T);
    else
        enum hasElaborateAssign = false;

}

/**
    Gets whether type `T` has elaborate copy constructor semantics
    (i.e. is a copy constructor or postblit constructor declared.)
*/
template hasElaborateCopyConstructor(T) {
    static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateCopyConstructor = T.sizeof && hasElaborateCopyConstructor!(BaseElemOf!T);
    else static if (is(T == struct))
        enum hasElaborateCopyConstructor = __traits(hasCopyConstructor, T) || __traits(hasPostblit, T);
    else
        enum hasElaborateCopyConstructor = false;
}

/**
    Gets whether type `T` has elaborate destructor semantics (is ~this() declared).
*/
template hasElaborateDestructor(T) {
    static if (__traits(isStaticArray, T)) 
        enum bool hasElaborateDestructor = T.sizeof && hasElaborateDestructor!(BaseElemOf!T);
    else static if (isAggregateType!T)
        enum hasElaborateDestructor = __traits(hasMember, T, "__dtor") ||
                                      anySatisfy!(.hasElaborateDestructor, Fields!T);
    else
        enum hasElaborateDestructor = false;
}