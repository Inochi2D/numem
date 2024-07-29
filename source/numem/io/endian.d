/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.io.endian;
import numem.mem;
import numem.mem.vector;
import std.traits : isNumeric;

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
ubyte[T.sizeof] toEndian(T)(T value, Endianess endianness) if (isNumeric!T) {

    // Get bytes from value
    ubyte[T.sizeof] output;
    output = (cast(ubyte*)&value)[0..T.sizeof];

    // Swap endianness if neccesary
    if (endianness != NATIVE_ENDIAN) {
        ubyte[T.sizeof] tmp;
        static foreach (i; 0..T.sizeof) {
            tmp[i] = output[(T.sizeof-1)-i];
        }
        output = tmp;
    }

    return output;
}

/**
    Gets a value from a different endianness.

    Is no-op if provided endianness is the same as the system's
*/
T fromEndian(T)(ubyte[T.sizeof] value, Endianess endianness) if (isNumeric!T) {
    ubyte[] toSwap = value;
    if (endianness != NATIVE_ENDIAN) toSwap.swapEndian();
    return *(cast(T*)toSwap.ptr);
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
void swapEndianInPlace(ref vector!ubyte arr, Endianess endianness) {
    
    // Make sure to only swap if endianness doesn't match
    if (endianness != NATIVE_ENDIAN) arr.swapEndian();
}

@("swapEndianInPlace: swap w/ non-evenly divisible size")
unittest {
    // Swap 3 elements
    vector!ubyte vec = vector!ubyte(cast(ubyte[])[1, 2, 3]);
    vec.swapEndianInPlace(ALT_ENDIAN);
    assert(vec[0..3] == cast(ubyte[])[3, 2, 1], "Endianness swap failed!");

    nogc_delete(vec);
}

@("swapEndianInPlace: swap endian w/ evenly divisible size")
unittest {
    // Swap 4 elements.
    vector!ubyte vec = vector!ubyte(cast(ubyte[])[1, 2, 3, 4]);
    vec.swapEndianInPlace(ALT_ENDIAN);
    assert(vec[0..4] == cast(ubyte[])[4, 3, 2, 1], "Endianness swap failed!");

    nogc_delete(vec);
}