/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Numem system hooks.
*/
module numem.core.system;
import numem.core.hooks;

/**
    Hook which gets the page-size of the system in bytes.

    Must not be less than 1.
    Returns: 
        Page size in bytes or 1 if unknown.
*/
@weak
export
extern(C)
uint sysGetPageSize() {
    version(Windows) {
        import core.sys.windows.core : GetSystemInfo, SYSTEM_INFO;

        SYSTEM_INFO info;
        GetSystemInfo(&info);
        return cast(uint)info.dwPageSize;
    } else version(Posix) {
        
        import core.sys.posix.unistd : sysconf, _SC_PAGESIZE;
        long pgSize = sysconf(_SC_PAGESIZE);
        return cast(uint)(pgSize > 0 ? pgSize : 1);
    } else {
        return 1u;
    }
}