/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.io.stream.reader;
import numem.io.stream;
import numem.io.endian;
import numem.string;
import numem.collections.vector;
import std.traits;

/**
    A stream reader.

    Allows easy reading from a stream.
*/
class StreamReader(Endianess endian) {
@nogc nothrow:
private:
    Stream stream;

public:

    /// Constructor
    this(Stream stream) {
        this.stream = stream;
    }

    /**
        Reads a value from the stream in to the specified variable.

        Returns the amount of bytes read if successful.
        Returns -1 otherwise.

        Failed reads may result in partial reads.
    */
    @trusted
    int read(T)(ref T val) if (isBasicType!T) {
        ubyte[T.sizeof] buf;
        
        // Need to slice it
        ubyte[] tmp = buf[0..$];
        if (stream.read(tmp) == T.sizeof) {
            val = tmp.fromEndian!T(endian);
            return T.sizeof;
        }

        return -1;
    }

    /// Ditto
    @trusted
    int read(T)(ref T val, size_t length) if (isSomeSafeString!T && StringCharSize!T == 1) {
        if (length > val.length)
            return -1;

        alias type = StringCharType!(T)*;

        // TODO: Handle encoding schemes other than UTF8

        // Size of a single unit
        vector!ubyte tmp = vector!ubyte(length*StringCharSize!T);

        // Attempt reading data
        int r = cast(int)stream.read(tmp, 0, length);
        if (r < 0) 
            return r;


        // "Convert" the data via type punning.
        (cast(type)val.ptr)[0..length] = (cast(type)tmp.ptr)[0..length];
        return r;
    }

    /// Ditto
    @trusted
    int read(T)(ref T val, size_t length) if (isSomeVector!T) {
        if (length > val.length) 
            return -1;
        
        int r = 0;

        static if (is(T.valueType == ubyte)) {
            r += stream.read(val, 0, length);
        } else {
            T.valueType tmp;
            foreach(i; 0..length) {
                int ir = this.read!(T.valueType)(tmp);
                if (ir < 0) 
                    return ir;

                r += ir;
                val[i] = tmp;
            }
        }
        return r;
    }

    /**
        Gets the stream instance for this reader.
    */
    @safe
    final
    ref Stream getStream() {
        return stream;
    }
}

@("Stream reader (memory buffer)")
unittest {
    import numem.io.stream.memstream : MemoryStream;
    alias TestReader = StreamReader!(Endianess.littleEndian);

    ubyte[128] buffer;
    Stream stream = new MemoryStream(buffer.ptr, buffer.length);
    TestReader reader = new TestReader(stream);

    // Dummy read destinations
    uint dst;
    nstring testStr = nstring(23);
    vector!ubyte buff2 = vector!ubyte(5);

    assert(reader.read(dst) == 4);
    assert(reader.read(testStr, testStr.length) == testStr.length);
    assert(reader.read(buff2, buff2.length) == buff2.length);
}