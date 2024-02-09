/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.stream;
import numem.mem.vector;
import core.stdc.stdio : SEEK_CUR, SEEK_END, SEEK_SET;

/**
    The origin of a seek operation
*/
enum SeekOrigin {

    /**
        Seek from beginning of stream
    */
    start = SEEK_SET,

    /**
        Seek relative to the current position in the stream
    */
    relative = SEEK_CUR,

    /**
        Seek relative to the end of the stream
    */
    end = SEEK_END
}

abstract
class Stream {
@nogc nothrow:
    /**
        Whether the stream can be read from.
    */
    abstract bool canRead();

    /**
        Whether the stream can be written to.
    */
    abstract bool canWrite();
    
    /**
        Whether the stream can be seeked.
    */
    abstract bool canSeek();

    /**
        Whether the stream can timeout during operations.
    */
    abstract bool canTimeout();

    /**
        Length of the stream.

        Returns
            * Length of stream, or -1 if the stream length is unknown.
    */
    abstract ptrdiff_t length();

    /**
        Position in stream
    
        Returns
            * Position in stream or -1 if the position in the stream is unknown.
    */
    abstract ptrdiff_t tell();

    /**
        Timeout in milliseconds before a read operation will fail.

        Returns
            * Timeout in milliseconds or 0 if there's no timeout.
    */
    abstract int readTimeout();

    /**
        Timeout in milliseconds before a write operation will fail.

        Returns
            * Timeout in milliseconds or 0 if there's no timeout.
    */
    abstract int writeTimeout();

    /**
        Clears all buffers of the stream and causes data to be written to the underlying device.
    
        Returns
            * true if the flush operation succeeded
            * false if it failed.
    */
    abstract bool flush();

    /**
        Sets the reading position within the stream

        Returns
            * The new position in the stream or -1 if seek operation failed.
    */
    abstract long seek(ptrdiff_t offset, SeekOrigin origin = SeekOrigin.start);

    /**
        Closes the stream.
    */
    abstract void close();

    /**
        Reads bytes from the specified stream in to the specified buffer
        
        Notes
            The position and length to read is specified by the slice of `buffer`.  
            Use slicing operation to specify a range to read to.

        Returns
            * The amount of bytes read
            * 0 if stream has reached EOF
            * -1 if the stream can't be read.
    */
    abstract ptrdiff_t read(ref ubyte[] buffer);

    /**
        Reads bytes from the specified stream in to the specified buffer

        Returns
            * The amount of bytes read
            * 0 if stream has reached EOF
            * -1 if the stream can't be read.
    */
    abstract ptrdiff_t read(ref vector!ubyte buffer, int offset, int count);

    /**
        Writes bytes from the specified buffer in to the stream

        Notes
            The position and length to write is specified by the slice of `buffer`.  
            Use slicing operation to specify a range to write from.

        Returns
            * The amount of bytes written
            * -1 if the stream can't be written to.
    */
    abstract ptrdiff_t write(ubyte[] buffer);

    /**
        Writes bytes from the specified buffer in to the stream

        Returns
            * The amount of bytes written
            * -1 if the stream can't be written to.
    */
    abstract ptrdiff_t write(ref vector!ubyte buffer, int offset, int count);
}