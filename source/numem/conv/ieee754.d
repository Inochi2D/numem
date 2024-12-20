/*
    Copyright © 2024, Kitsunebi Games EMV
    Distributed under the Boost Software License, Version 1.0, 
    see LICENSE file.

    Based on Ryu by Ulf Adams, released under both the Apache and Boost License.
    See: https://github.com/ulfjack/ryu/blob/master/LICENSE-Boost
    
    Authors: Luna Nielsen
*/
module numem.conv.ieee754;
import numem.conv.common;

/**
    A table of all two-digit numbers. This is used to speed up decimal digit
    generation by copying pairs of digits into the final output.
*/
static const char[200] __RYU_DIGIT_TABLE = [
    '0','0','0','1','0','2','0','3','0','4','0','5','0','6','0','7','0','8','0','9',
    '1','0','1','1','1','2','1','3','1','4','1','5','1','6','1','7','1','8','1','9',
    '2','0','2','1','2','2','2','3','2','4','2','5','2','6','2','7','2','8','2','9',
    '3','0','3','1','3','2','3','3','3','4','3','5','3','6','3','7','3','8','3','9',
    '4','0','4','1','4','2','4','3','4','4','4','5','4','6','4','7','4','8','4','9',
    '5','0','5','1','5','2','5','3','5','4','5','5','5','6','5','7','5','8','5','9',
    '6','0','6','1','6','2','6','3','6','4','6','5','6','6','6','7','6','8','6','9',
    '7','0','7','1','7','2','7','3','7','4','7','5','7','6','7','7','7','8','7','9',
    '8','0','8','1','8','2','8','3','8','4','8','5','8','6','8','7','8','8','8','9',
    '9','0','9','1','9','2','9','3','9','4','9','5','9','6','9','7','9','8','9','9'
];

/**
    Float parsing information
*/
struct fparse_t {  // @suppress(dscanner.style.phobos_naming_convention)
@nogc nothrow:
    ulong m10;
    ulong e10;
    size_t radixIdx;
    size_t expIdx;

    uint digits;
    uint expDigits;

    bool signed;
    bool expSigned;
}

errcode_t parseFArgs(string buffer, ref fparse_t out_) @nogc nothrow {
    size_t len = buffer.length;
    if (len == 0)
        return ERR_TOO_SHORT;

    out_.m10 = 0;
    out_.e10 = 0;
    out_.signed = false;
    out_.digits = 0;
    out_.radixIdx = len;
    out_.expIdx = len;
    out_.expSigned = false;
    out_.expDigits = 0;
    uint i = 0;

    // Check for negative.
    if (buffer[i] == '-') {
        out_.signed = true;
        i++;
    }

    // Base-10
    for(; i < buffer.length; i++) {
        char c = buffer[i];

        // Handle radix index
        if (c == '.') {
            if (out_.radixIdx != len)
                return ERR_MALFORMED;

            out_.radixIdx = i;
            continue;
        }

        // Handle non-numercs
        if (c < '0' || c > '9')
            break;

        if (out_.digits >= 9)
            return ERR_TOO_LONG;

        out_.m10 = 10 * out_.m10 + (c - '0');
        if (out_.m10 != 0)
            out_.digits++; 
    }

    // Exponent
    if (i < len && ((buffer[i] == 'e') || (buffer[i] == 'E'))) {
        out_.expIdx = i;
        i++;

        if (i < len && ((buffer[i] == '-') || (buffer[i] == '+'))) {
            out_.expSigned = buffer[i] == '-';
            i++;
        }

        for(; i < buffer.length; i++) {
            char c = buffer[i];

            // Handle non-numercs
            if (c < '0' || c > '9')
                return ERR_MALFORMED;

            // NOTE: Should return -/+ infinity in text.
            if (out_.expDigits > 3)
                return SUCCESS;

            out_.e10 = 10 * out_.e10 + (c - '0');
            if (out_.e10 != 0)
                out_.expDigits++;
        }
    }

    if (i < len)
        return ERR_MALFORMED;
    
    if (out_.expSigned)
        out_.e10 = -out_.e10;
    
    return SUCCESS;
}

// pragma(inline, true)
// uint floor_log2(inout(uint) value) {
// }