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