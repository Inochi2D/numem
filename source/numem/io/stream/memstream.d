/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.io.stream.memstream;
import numem.io.stream;
import numem.collections.vector;

/**
    A memory stream.
    
    NOTES
        * The memory is *NOT* owned by the stream.
*/
class MemoryStream : Stream {
nothrow @nogc:
private:
    size_t fLength_ = 0;
    size_t fPosition_ = 0;
    ubyte* data;

public:

    /**
        Creates a stream into a vector
    */
    @trusted
    this(ref vector!(ubyte) memory) {
        fLength_ = memory.size();
        data = memory.adata();
    }

    /**
        Creates a stream into a slice
    */
    @trusted
    this(ref void[] slice) {
        fLength_ = slice.length;
        data = cast(ubyte*)slice.ptr;
    }

    /**
        Creates a stream into a pointer
    */
    @system
    this(void* ptr, size_t length) {
        fLength_ = length;
        data = cast(ubyte*)ptr;
    }

override:

    bool canRead() { return true; }
    bool canWrite() { return true; }
    bool canSeek() { return true; }
    bool canTimeout() { return false; }
    ptrdiff_t length() { return fLength_; }
    ptrdiff_t tell() { return fPosition_; }
    int readTimeout() { return 0; }
    int writeTimeout() { return 0; }

    // Flushing a memory stream doesn't make sense, so always return true.
    bool flush() { return true; }

    long seek(ptrdiff_t offset, SeekOrigin origin = SeekOrigin.start) {

        ptrdiff_t newPosition = 0;
        final switch(origin) {
            case SeekOrigin.start:
                newPosition = offset;
                break;
            case SeekOrigin.relative:
                newPosition = fPosition_ + offset;
                break;
            case SeekOrigin.end:
                newPosition = fLength_ - (offset+1);
                break;
        }
        if (newPosition < 0 || newPosition >= fLength_) return -1;

        fPosition_ = newPosition;
        return fPosition_;
    }

    // Does nothing
    void close() { }

    ptrdiff_t read(ref ubyte[] buffer) {
        ptrdiff_t toRead = buffer.length;

        // Limit read to bounds
        if (fPosition_+buffer.length > fLength_) 
            toRead = cast(ptrdiff_t)fLength_-(fPosition_+buffer.length);
        
        // EOF
        if (fPosition_ == fLength_) return 0;

        // Past EOF
        if (toRead <= 0) return -1;

        // Read in to buffer
        buffer[0..toRead] = data[fPosition_..fPosition_+toRead];

        fPosition_ += toRead;
        return toRead;
    }

    ptrdiff_t read(ref vector!ubyte buffer, size_t offset, size_t count) {
        ptrdiff_t toRead = count;

        // Out of range for destination
        if (offset+count > buffer.length) return -2;

        // Limit read to bounds
        if (fPosition_+count > fLength_) 
            toRead = cast(ptrdiff_t)fLength_-(fPosition_+count);
        
        // EOF
        if (fPosition_ == fLength_) return 0;

        // Past EOF
        if (toRead <= 0) return -1;

        // Read in to buffer
        buffer.adata[offset..offset+toRead] = data[fPosition_..fPosition_+toRead];

        fPosition_ += toRead;
        return toRead;
    }

    ptrdiff_t write(ubyte[] buffer) {
        ptrdiff_t toWrite = buffer.length;

        // Limit read to bounds
        if (fPosition_+buffer.length > fLength_) 
            toWrite = cast(ptrdiff_t)fLength_-(fPosition_+buffer.length);
        
        // EOF
        if (fPosition_ == fLength_) return 0;

        // Past EOF
        if (toWrite <= 0) return -1;

        // Read in to buffer
        data[fPosition_..fPosition_+toWrite] = buffer[0..toWrite];

        fPosition_ += toWrite;
        return toWrite;
    }

    ptrdiff_t write(ref vector!ubyte buffer, int offset, int count) {
        ptrdiff_t toWrite = count;

        // Out of range for source
        if (offset+count > buffer.length) return -2;

        // Limit read to bounds
        if (fPosition_+count > fLength_) 
            toWrite = cast(ptrdiff_t)fLength_-(fPosition_+count);
        
        // EOF
        if (fPosition_ == fLength_) return 0;

        // Past EOF
        if (toWrite <= 0) return -1;

        // Read in to buffer
        data[fPosition_..fPosition_+toWrite] = buffer[offset..offset+toWrite];

        fPosition_ += toWrite;
        return toWrite;
    }
}