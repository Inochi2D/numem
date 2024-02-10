/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.io.file;
import numem.mem.string;
import numem.mem;
import numem.mem.ptr;
import numem.stream.filestream;

import c = core.stdc.stdio;

@nogc nothrow:
public:

/**
    Opens a file stream from the specified file path
*/
FileStream openFile(nstring filename, scope const(char)* mode) {
    return nogc_new!FileStream(c.fopen(filename.toCString, mode));
}

/**
    Opens a file stream from the specified file path as a shared pointer
*/
shared_ptr!FileStream openFileShared(nstring filename, scope const(char)* mode) {
    return shared_new!FileStream(c.fopen(filename.toCString, mode));
}

/**
    Opens a file stream from the specified file path as a unique pointer
*/
unique_ptr!FileStream openFileOwned(nstring filename, scope const(char)* mode) {
    return unique_new!FileStream(c.fopen(filename.toCString, mode));
}

/**
    Checks whether a file exists at the specified path
*/
bool exists(nstring str) {
    version(Posix) {
        import uni = core.sys.posix.unistd;
        return uni.access(str.toCString, F_OK) == 0;
    } else version(Windows) {
        import win = core.sys.windows.core;
        
        nwstring tstr;

        // Find out how many characters there is to convert to UTF-16
        size_t reqLength = win.MultiByteToWideChar(win.CP_UTF8, 0, str.toCString, -1, null, 0);
        tstr.resize(reqLength);

        // Convert to UTF-16
        win.MultiByteToWideChar(win.CP_UTF8, 0, str.toCString, -1, cast(wchar*)tstr.toCString, cast(int)tstr.length);

        bool exists = win.GetFileAttributesW(tstr.toCString) != win.INVALID_FILE_ATTRIBUTES;
        
        // Free memory from the temporary string
        nogc_delete(tstr);
        return exists;
    } else {
        auto f = c.fopen(str.toCString, "r");
        if (f) {
            c.fclose(f);
        }
        return f !is null;
    }
}