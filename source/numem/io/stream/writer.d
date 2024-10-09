/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.io.stream.writer;
import numem.io.stream;
import numem.io.endian;
import numem.string;
import numem.collections.vector;
import std.traits;

/**
    A stream writer.

    Allows easy writing to a stream.
*/
class StreamWriter(Endianess endian) {
@nogc nothrow:
private:
    Stream stream;

public:

    /// Constructor
    this(Stream stream) {
        this.stream = stream;
    }

    /**
        Writes value to the stream
    */
    @trusted
    void write(T)(T val) if (isBasicType!T) {
        static if (T.sizeof > 1) {
            auto toWrite = val.toEndian(endian);
            stream.write(toWrite);
        } else {
            ubyte[1] tmp = [cast(ubyte)val];

            stream.write(tmp[]);
        }
    }

    /// Ditto
    @trusted
    void write(T)(T val) if (isSomeSafeString!T) {
        stream.write(cast(ubyte[])val[0..$]);
    }

    /// Ditto
    @trusted
    void write(T)(T val) if (isSomeVector!T) {
        foreach(element; val) {
            this.write!(T.valueType)(element);
        }
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

@("Writing test")
unittest {
    import numem.io.stream.memstream : MemoryStream;
    alias TestWriter = StreamWriter!(Endianess.littleEndian);

    ubyte[100] buffer;
    TestWriter writer = new TestWriter(new MemoryStream(buffer.ptr, buffer.length));
    foreach_reverse(i; 0..100) {
        writer.write!ubyte(cast(ubyte)(i+1));
    }

    assert(buffer[0] == 100);
    assert(buffer[99] == 1);
}