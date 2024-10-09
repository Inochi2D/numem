/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.io.endian;
import numem.core;
import numem.collections.vector;
import std.traits : isNumeric, isIntegral, isBasicType;
import std.traits : Unqual;
import std.bitmanip;

@nogc nothrow:

/**
    Endianness
*/
enum Endianess {
    bigEndian = 0,
    littleEndian = 1
}

/// System endianness.
version(BigEndian) enum NATIVE_ENDIAN = Endianess.bigEndian;
else enum NATIVE_ENDIAN = Endianess.littleEndian;

/// Endianness opposite of system endianness
enum Endianess ALT_ENDIAN = cast(Endianess)!NATIVE_ENDIAN;

private {

    // Internal endian swap
    void swapEndian(ref ubyte[] data) {
        ubyte tmp;
        size_t ri = data.length-1;
        foreach(i; 0..data.length/2) {
            tmp = data[i];
            data[i] = data[ri];
            data[ri--] = tmp;
        }
    }

    // Internal endian swap
    void swapEndian(ref vector!ubyte data) {
        ubyte tmp;
        size_t ri = data.size-1;
        foreach(i; 0..data.size/2) {
            tmp = data[i];
            data[i] = data[ri];
            data[ri--] = tmp;
        }
    }
}

/**
    Converts a value to an array of the specified endianness.

    Is no-op if provided endianness is the same as the system's
*/
@trusted
ubyte[T.sizeof] toEndian(T)(T value, Endianess endianness) {
    union tmp {
        Unqual!T value;
        ubyte[T.sizeof] bytes;
    }

    tmp tmp_;
    tmp_.value = value;

    // Swap endianness if neccesary
    if (endianness != NATIVE_ENDIAN) {
        ubyte[] slice = tmp_.bytes[0..$];
        swapEndian(slice);
    }

    return tmp_.bytes;
}

/**
    Flips the bytes in the provided value to be in the specified endianness.

    Is no-op if provided endianness is the same as the system's
*/
@system
T toEndianReinterpret(T)(T in_, Endianess endianness) {
    if (endianness != NATIVE_ENDIAN) {
        union tmp {
            T value;
            ubyte[T.sizeof] bytes;
        }

        tmp tmp_;
        tmp_.bytes = toEndian!T(in_, endianness);
        return tmp_.value;
    }

    return in_;
}

/**
    Gets a value from a different endianness.

    Is no-op if provided endianness is the same as the system's
*/
@trusted
T fromEndian(T)(ubyte[] value, Endianess endianness) if (isBasicType!T) {
    union tmp {
        T value;
        ubyte[T.sizeof] bytes;
    }
    tmp tmp_;
    tmp_.bytes = value;
    ubyte[] slice = tmp_.bytes[0..$];

    if (endianness != NATIVE_ENDIAN) 
        swapEndian(slice);

    return tmp_.value;
}

/**
    Gets a value from a different endianness.

    Is no-op if provided endianness is the same as the system's.

*/
@system
T fromEndianReinterpret(T)(ubyte[] value, Endianess endianness) {
    union tmp {
        T value;
        ubyte[T.sizeof] bytes;
    }
    tmp toConvert;
    toConvert.bytes = value;
    ubyte[] slice = tmp_.bytes[0..$];

    if (endianness != NATIVE_ENDIAN) 
        swapEndian(slice);

    return toConvert.value;
}

@("fromEndian: flip endianness for numeric type")
unittest {

    // Finangle things around
    uint a = 1;
    auto data = a.toEndian(ALT_ENDIAN);
    uint ra = data.fromEndian!uint(NATIVE_ENDIAN);

    assert(ra != a, "Expected flipped endianness to");
}

/**
    Converts endianness of a ubyte vector in place.

    Is no-op if provided endianness is the same as the system's.
*/
@trusted
void swapEndianInPlace(ref vector!ubyte arr, Endianess endianness) {
    
    // Make sure to only swap if endianness doesn't match
    if (endianness != NATIVE_ENDIAN) arr.swapEndian();
}

@("swapEndianInPlace: swap w/ non-evenly divisible size")
unittest {
    // Swap 3 elements
    ubyte[3] arr = cast(ubyte[])[1, 2, 3];
    vector!ubyte vec = vector!ubyte(arr[0..$]);

    vec.swapEndianInPlace(ALT_ENDIAN);
    assert(vec[0..3] == cast(ubyte[])[3, 2, 1], "Endianness swap failed!");

    nogc_delete(vec);
}

@("swapEndianInPlace: swap endian w/ evenly divisible size")
unittest {
    // Swap 4 elements.
    ubyte[4] arr = cast(ubyte[])[1, 2, 3, 4];
    vector!ubyte vec = vector!ubyte(arr[0..$]);

    vec.swapEndianInPlace(ALT_ENDIAN);
    assert(vec[0..4] == cast(ubyte[])[4, 3, 2, 1], "Endianness swap failed!");

    nogc_delete(vec);
}

/**
    Converts values from network order to host order

    Calling this on a converted value flips the operation.
*/
@trusted
T ntoh(T)(T in_) if (isIntegral!T && T.sizeof > 1) {
    return toEndianReinterpret(in_, Endianess.bigEndian);
}