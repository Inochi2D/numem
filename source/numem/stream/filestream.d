module numem.stream.filestream;
import numem.stream;
import numem.mem.vector;

import core.stdc.stdio;

/**
    A file stream.
    
    NOTES
        * The file handle is owned by the stream
*/
class FileStream : Stream {
nothrow @nogc:
private:
    size_t fLength_ = 0;
    size_t fPosition_ = 0;
    FILE* file;

public:
    ~this() {
        this.close();
    }

    this(FILE* fileptr) {
        this.file = fileptr;

        // Find length of file
        fseek(file, 0, SEEK_END);
        fLength_ = cast(ptrdiff_t)ftell(file)+1;

        // Seek back to start of file to begin rw operation
        fseek(file, 0, SEEK_SET);
    }

override:

    bool canRead() { return true; }
    bool canWrite() { return true; }
    bool canSeek() { return true; }
    bool canTimeout() { return false; }
    ptrdiff_t length() { return fLength_; }
    ptrdiff_t tell() { return cast(ptrdiff_t)ftell(file); }
    int readTimeout() { return 0; }
    int writeTimeout() { return 0; }

    bool flush() {
        int err = fflush(file);
        return err == 0;
    }

    long seek(ptrdiff_t offset, SeekOrigin origin = SeekOrigin.start) {
        return fseek(file, cast(int)offset, origin);
    }

    void close() {
        fclose(file);
    }

    ptrdiff_t read(ref ubyte[] buffer) {
        fPosition_ += buffer.length;
        return fread(buffer.ptr, 1, buffer.length, file);
    }

    ptrdiff_t read(ref vector!ubyte buffer, int offset, int count) {
        if (buffer.capacity-offset < count) return -1;

        fPosition_ += buffer.size;
        return fread(buffer.data+offset, 1, count, file);
    }

    ptrdiff_t write(ubyte[] buffer) {

        // NOTE: Write and calculate the position delta
        // said delta is used to recalculate the length
        size_t written = fwrite(buffer.ptr, 1, buffer.length, file);
        ptrdiff_t deltaWrite = (cast(ptrdiff_t)fPosition_-cast(ptrdiff_t)fLength_)+written;
        if (deltaWrite > 0) {
            fLength_ += deltaWrite;
        }

        return written; // TODO: implement
    }

    ptrdiff_t write(ref vector!ubyte buffer, int offset, int count) {

        // NOTE: Write and calculate the position delta
        // said delta is used to recalculate the length
        size_t written = fwrite(buffer.data+offset, 1, count, file);
        ptrdiff_t deltaWrite = (cast(ptrdiff_t)fPosition_-cast(ptrdiff_t)fLength_)+written;
        if (deltaWrite > 0) {
            fLength_ += deltaWrite;
        }

        return written;
    }
}