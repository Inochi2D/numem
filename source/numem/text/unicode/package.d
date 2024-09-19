/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.unicode;
import numem.collections.vector;

@nogc nothrow:

/**
    A unicode codepoint
*/
alias codepoint = uint;

/**
    Validates whether the codepoint is within spec
*/
bool validate(codepoint code) {
    return code <= 0x10FFFF && !hasSurrogatePairs(code);
}

/**
    Gets whether the codepoint mistakenly has surrogate pairs encoded within it.
*/
bool hasSurrogatePairs(codepoint code) {
    return (code >= 0x0000D800 && code <= 0x0000DFFF);
}

/**
    Validates whether the codepoint is within spec
*/
__gshared codepoint unicodeReplacementCharacter = 0xFFFD;

/**
    A unicode codepoint sequence
*/
alias UnicodeSequence = vector!codepoint;

/**
    A unicode codepoint sequence
*/
alias UnicodeSlice = codepoint[];

/**
    A unicode grapheme
*/
struct Grapheme {
private:
    size_t state;

public:

    /**
        Byte offset
    */
    size_t offset;

    /**
        Cluster of codepoints, memory beloning to the original UnicodeSequence
    */
    codepoint[] cluster;
}

/**
    A sequence of graphemes
*/
alias GraphemeSequence = weak_vector!Grapheme;