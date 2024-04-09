/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.io.stream.reader;
import numem.io.stream;
import numem.io.endian;
import numem.mem.string;
import numem.mem.vector;
import std.traits;

/**
    A stream writer.

    Allows easy writing to a stream.
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
    int read(T)(ref T val) if (isNumeric!T) {
        ubyte[T.sizeof] buf;
        if (stream.read(buf) == T.sizeof) {
            val = buf.fromEndian(endian);
            return T.sizeof;
        }

        return -1;
    }

    /// Ditto
    @trusted
    int read(T)(ref T val, size_t length) if (isSomeNString!T) {
        if (length > val.size()) return -1;

        // Size of a single unit
        enum S_CHAR_SIZE = T.valueType.sizeof;
        vector!ubyte tmp = vector!ubyte(length*S_CHAR_SIZE);

        // Attempt reading data
        int r = stream.read(tmp, 0, length);
        if (r == -1) return -1;

        // "Convert" the data via type punning.
        val.adata[0..length] = (cast(T.valueType*)tmp.adata)[0..length];
    }

    /// Ditto
    @trusted
    int read(T)(ref T val, size_t length) if (isSomeVector!T) {
        if (length > val.size()) return -1;
        int r = 0;

        static if (is(T.valueType == ubyte)) {
            r += stream.read(val, 0, length);
        } else {
            T tmp;
            foreach(i; 0..length) {
                int ir = this.read!(T.valueType)(tmp);
                if (ir == -1) return -1;

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