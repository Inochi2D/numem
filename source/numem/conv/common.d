/*
    Copyright © 2024, Kitsunebi Games EMV
    Distributed under the Boost Software License, Version 1.0, 
    see LICENSE file.

    Based on Ryu by Ulf Adams, released under both the Apache and Boost License.
    See: https://github.com/ulfjack/ryu/blob/master/LICENSE-Boost
    
    Authors: Ulf Adams, Luna Nielsen 
*/
module numem.conv.common;
import numem.core.casting;

/**
    Returns the number of decimal digits in v, which must not contain more than 9 digits.
*/
pragma(inline, true)
uint decimalLength9(inout(uint) v) {
    assert(v < 1_000_000_000);

    if (v >= 100_000_000) { return 9; }
    if (v >= 10_000_000) { return 8; }
    if (v >= 1_000_000) { return 7; }
    if (v >= 100_000) { return 6; }
    if (v >= 10_000) { return 5; }
    if (v >= 1000) { return 4; }
    if (v >= 100) { return 3; }
    if (v >= 10) { return 2; }
    return 1;
}

/**
    Returns e == 0 ? 1 : [log_2(5^e)]; requires 0 <= e <= 3528.
*/
pragma(inline, true)
int log2pow5(inout(int) e) {
    assert(e >= 0 && e <= 3528);

    return cast(int)(((cast(uint) e) * 1_217_359) >> 19);
}

/**
    Returns e == 0 ? 1 : ceil(log_2(5^e)); requires 0 <= e <= 3528.
*/
pragma(inline, true)
int log2pow5_ceil(inout(int) e) {
    return log2pow5(e)+1;
}

/**
    Returns floor(log_10(2^e)); requires 0 <= e <= 1650.
*/
pragma(inline, true)
uint log10pow2(inout(int) e) {
    assert(e >= 0 && e <= 1650);

    return ((cast(uint) e) * 78_913) >> 18;
}

/**
    Returns floor(log_10(5^e)); requires 0 <= e <= 2620.
*/
pragma(inline, true)
uint log10pow5(inout(int) e) {
    assert(e >= 0 && e <= 2620);

    return ((cast(uint) e) * 732_923) >> 20;
}

/**
    Errorcode type
*/
alias errcode_t = uint;

/**
    Success.
*/
enum errcode_t SUCCESS = 0u;

/**
    Input too short
*/
enum errcode_t ERR_TOO_SHORT = 1u;

/**
    Input too short
*/
enum errcode_t ERR_TOO_LONG = 2u;

/**
    Input is malformed.
*/
enum errcode_t ERR_MALFORMED = 3u;
