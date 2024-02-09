/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module numem.io.file;
import numem.mem.string;
import numem.mem;
import numem.stream.filestream;

import c = core.stdc.stdio;

/**
    Opens a file stream from the specified file path
*/
FileStream open(nstring filename, scope const(char)* mode) {
    return nogc_new!FileStream(c.fopen(filename.toCString, mode));
}