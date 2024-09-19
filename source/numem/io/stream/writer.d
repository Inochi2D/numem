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
    void write(T)(T val) if (isNumeric!T) {
        auto toWrite = val.toEndian(endian);
        stream.write(toWrite);
    }

    /// Ditto
    @trusted
    void write(T)(T val) if (isSomeNString!T) {
        stream.write(cast(ubyte[])val.toDString());
    }

    /// Ditto
    @trusted
    void write(T)(T val) if (is(T : string)) {
        stream.write(cast(ubyte[])val);
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