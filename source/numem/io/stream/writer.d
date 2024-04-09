/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.io.stream.writer;
import numem.io.stream;
import numem.io.endian;
import numem.mem.string;
import numem.mem.vector;
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
    void write(T)(T val) if (isNumeric!T) {
        auto toWrite = val.toEndian(endian);
        stream.write(toWrite);
    }

    /// Ditto
    @trusted
    void write(T)(T val) if (isSomeNString!T) {

        // Size of a single unit
        enum S_CHAR_SIZE = T.valueType.sizeof;

        // Some char array ptr
        auto t = val.adata();
        ubyte[] dataToWrite = (cast(ubyte*)t)[0..val.size()*S_CHAR_SIZE];
        stream.write(dataToWrite);
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