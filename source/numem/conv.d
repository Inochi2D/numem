/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    Utilities for converting between some basic types
*/
module numem.conv;
import core.stdc.stdlib;
import std.traits;
import numem.all;

@nogc:

/**
    Convert nstring to signed integer
*/
T toInt(T)(nstring str) if (isIntegral!T) {
    static if (isSigned!T) {
        return cast(T)strtoll(str.ptr, null, 10);
    } else {
        return cast(T)strtoull(str.ptr, null, 10);
    }
}

/**
    Convert string slice to signed integer
*/
T toInt(T)(string str) if (isIntegral!T) {
    return toInt!T(nstring(str));
}

/**
    Convert nstring to unsigned integer
*/
T toInt(T)(nstring str, int base) if (isIntegral!T) {
    static if (isSigned!T) {
        return cast(T)strtoll(str.ptr, null, base);
    } else {
        return cast(T)strtoull(str.ptr, null, base);
    }
}

/**
    Convert string slice to unsigned integer
*/
T toInt(T)(string str, int base) if (isIntegral!T) {
    return toInt!T(nstring(str), base);
}

/**
    Convert nstring to float
*/
T toFloat(T)(nstring str) nothrow if (isFloatingPoint!T) {
    return cast(T)atof(str.toCString());
}

/**
    Convert string slice to float
*/
T toFloat(T)(string str) nothrow if (isFloatingPoint!T)  {
    return cast(T)strtof(str.ptr, str.ptr+str.length);
}

/**
    Converts an integer type into a hex string
*/
nstring toHexString(T, bool upper=false)(T num, bool pad=false) if (isIntegral!T && isUnsigned!T) {
    const string hexStr = upper ? "0123456789ABCDEF" : "0123456789abcdef";
    nstring str;

    ptrdiff_t i = T.sizeof*2;
    while(num > 0) {
        str ~= hexStr[num % 16];
        i--;
        num /= 16;
    }

    str.reverse();

    // Add padding
    if (pad) {
        nstring padding;
        while(i-- > 0)
            padding ~= '0';

        padding ~= str;
        return padding;
    }

    // No padding
    return str;
}

@("conv: toHexString")
unittest {
    nstring hexstr = 0xDEADBEEF.toHexString();
    assert(hexstr == "deadbeef", hexstr[]);
}

/**
    Convert signed integers to nstring
*/
nstring toString(T)(T item) if (isIntegral!T && !is(T == enum)) {
    static if (isSigned!T) {
        return "%lli".cformat(item);
    } else {
        return "%llu".cformat(item);
    }
}


/**
    Convert floating point numbers to nstring
*/
nstring toString(T)(T item) if (isFloatingPoint!T) {
    return "%g".cformat(item);
}

/**
    Convert bool to nstring
*/
nstring toString(T)(T item) if (is(T == bool)) {
    return item ? nstring("true") : nstring("false");
}

/**
    Convert enum to nstring
*/
nstring toString(T)(T item) if (is(T == enum)) {
    static foreach(member; EnumMembers!T) {
        if (item == member) 
            return nstring(member.stringof);
    }

    return nstring(T.stringof);
}

/**
    Allows types to implement a toNString function
*/
nstring toString(T)(T item) if (__traits(hasMember, T, "toNString")) {
    return item.toNString();
}

@("toString")
unittest {
    assert((32u).toString() == "32");
    assert((12.0f).toString() == "12");
    assert((42.1).toString() == "42.1");
    assert((true).toString() == "true");
    assert((false).toString() == "false");
}

@("toString w/ enum")
unittest {
    enum TestEnum {
        a,
        b,
        longerName
    }
    
    assert(TestEnum.a.toString() == "a");
    assert(TestEnum.b.toString() == "b");
    assert(TestEnum.longerName.toString() == "longerName");
}