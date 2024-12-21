/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Basic hashing
*/
module numem.core.hash;
import numem.math;

/**
    A simple 32-bit hash code
*/
alias hashcode_t = uint;

//
//          CRC 32
//

private {
    __gshared hashcode_t[256] crcTable;
    __gshared bool crcTableReady;
    void crc32_compute() {
        crcTable[0] = 0;
        hashcode_t crc = 1;

        foreach(tableIdx; 0..crcTable.length) {
            crc = cast(hashcode_t)tableIdx;

            // Bit indices
            foreach(_; 0..8) {
                if (crc & 1)
                    crc = cast(hashcode_t)(0xEDB88320L ^ (crc >> 1));
                else
                    crc = crc >> 1;
            }

            crcTable[tableIdx] = crc;
        }

        crcTableReady = true;
    }
}

/**
    Returns a CRC32 hash for the given data.
*/
hashcode_t crc32()(ref auto void[] data) {
    if (!crcTableReady)
        crc32_compute();

    hashcode_t crc = 0xFFFFFFFFu;
    ubyte[] dataBytes = cast(ubyte[]) data;

    foreach(i; 0..data.length) {
        size_t lookupIdx = (crc ^ dataBytes[i]) & 0xFF;
        crc = (crc >> 8) ^ crcTable[lookupIdx];
    }

    // Invert all the bits and return
    return crc ^ 0xFFFFFFFF;
}

/**
    Basic hashing algorithm for ascii text.

    Any `char` outside of the printable range gets clamped to be within
    the printable ascii range.
*/
hashcode_t asciiHash(const(char)[] text) {
    import numem.text.ascii : isUniAlphaNumeric;

    // Clamp within printable range.
    hashcode_t hash = clamp(cast(hashcode_t)text[0], 32, 125);

    foreach(i; 1..text.length) {
        char ch = cast(char)clamp(text[i], 32, 125);
        
        hash = hash * 31 + ch;
    }
    return hash;
}


//
//          Cryptographic Helpers
//

/**
    Validates a hash one byte at a time in a manner which should be
    secure against timing attacks.
*/
bool slowEq(ubyte[] lhs, ubyte[] rhs) {
    ptrdiff_t diff = lhs.length ^ rhs.length;
    size_t mlen = min(lhs.length, rhs.length);

    for(size_t i = 0; i < mlen; i++)
        diff |= lhs[i] ^ rhs[i];
    
    return diff == 0;
}