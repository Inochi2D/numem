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
        static if (StringCharSize!T > 1) {
            auto data = val.toEndian(endian);
            stream.write((cast(ubyte*)data.ptr)[0..data.length*StringCharSize!T]);
        } else {
            stream.write(cast(ubyte[])val[0..$]);
        }
    }

    /// Ditto
    @trusted
    void write(T)(T val) if (isSomeVector!T) {
        static if (T.valueType.sizeof == 1) {
            stream.write(cast(ubyte[])val[0..$]);
        } else {
            foreach(element; val) {
                this.write!(T.valueType)(element);
            }
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

@("RW: Little Endian")
unittest {
    import numem.io.stream.memstream : MemoryStream;
    import numem.io.stream.reader : StreamReader;
    alias TestReader = StreamReader!(Endianess.littleEndian);
    alias TestWriter = StreamWriter!(Endianess.littleEndian);

    ubyte[8] buffer;
    auto stream = new MemoryStream(buffer.ptr, buffer.length);
    auto writer = new TestWriter(stream);
    auto reader = new TestReader(stream);

    enum MAGIC = 0xFF00FF0F;

    writer.write!ulong(MAGIC);
    stream.seek(0);

    ulong val;
    reader.read!ulong(val);
    
    assert(val == MAGIC);
}

@("RW: Big Endian")
unittest {
    import numem.io.stream.memstream : MemoryStream;
    import numem.io.stream.reader : StreamReader;
    alias TestReader = StreamReader!(Endianess.bigEndian);
    alias TestWriter = StreamWriter!(Endianess.bigEndian);

    ubyte[8] buffer;
    auto stream = new MemoryStream(buffer.ptr, buffer.length);
    auto writer = new TestWriter(stream);
    auto reader = new TestReader(stream);

    enum MAGIC = 0xFF00FF0F;

    writer.write!ulong(MAGIC);
    stream.seek(0);

    ulong val;
    reader.read!ulong(val);
    assert(val == MAGIC);
}

@("RW: UTF-32")
unittest {
    import numem.io.stream.memstream : MemoryStream;
    import numem.io.stream.reader : StreamReader;
    alias TestReader = StreamReader!(Endianess.bigEndian);
    alias TestWriter = StreamWriter!(Endianess.bigEndian);

    ubyte[128] buffer;
    auto stream = new MemoryStream(buffer.ptr, buffer.length);
    auto writer = new TestWriter(stream);
    auto reader = new TestReader(stream);

    enum MAGIC = "Hello, world!"d;
    ndstring val = ndstring(MAGIC.length);

    writer.write(MAGIC);
    stream.seek(0);

    reader.read(val);
    assert(val == MAGIC);
}