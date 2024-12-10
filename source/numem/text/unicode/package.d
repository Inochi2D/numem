/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.text.unicode;
import numem.collections.vector;
import numem.io.endian;
import numem.string;

public import numem.text.unicode.utf8;
public import numem.text.unicode.utf16;
public import numem.text.unicode.utf32;

// For encoding dispatch
import utf8 = numem.text.unicode.utf8;
import utf16 = numem.text.unicode.utf16;
import utf32 = numem.text.unicode.utf32;

@nogc nothrow:

/**
    A unicode codepoint
*/
alias codepoint = uint;

/**
    Codepoint for the unicode byte-order-mark
*/
enum codepoint UNICODE_BOM = 0xFEFF;

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
    Gets whether the character is a BOM
*/
bool isBOM(codepoint c) {
    return isLittleEndianBOM(c) || isBigEndianBOM(c); 
}

/**
    Gets whether the byte order mark is little endian
*/
pragma(inline, true)
bool isLittleEndianBOM(codepoint c) {
    return (c == 0xFFFE0000 || c == 0x0000FFFE);
}

/**
    Gets whether the byte order mark is big endian
*/
pragma(inline, true)
bool isBigEndianBOM(codepoint c) {
    return (c == 0xFEFF0000 || c == 0x0000FEFF);
}

/**
    Gets the endianess from a BOM
*/
Endianess getEndianFromBOM(codepoint c) {
    return isBigEndianBOM(c) ? 
        Endianess.bigEndian : 
        Endianess.littleEndian;
}

/**
    Decodes a string
*/
UnicodeSequence decode(T)(ref auto T str, bool stripBOM = false) if (isSomeSafeString!T) {
    static if (StringCharSize!T == 1)
        return utf8.decode(str);
    else static if (StringCharSize!T == 2)
        return utf16.decode(str, stripBOM);
    else static if (StringCharSize!T == 4)
        return utf32.decode(str, stripBOM);
    else
        assert(0, "String type not supported.");
}

/**
    Encodes a string
*/
T encode(T)(ref auto UnicodeSequence seq, bool addBOM = false) if (isSomeNString!T) {
    static if (StringCharSize!T == 1)
        return utf8.encode(seq);
    else static if (StringCharSize!T == 2)
        return utf16.encode(seq, addBOM);
    else static if (StringCharSize!T == 4)
        return utf32.encode(seq, addBOM);
    else
        assert(0, "String type not supported.");
}

/**
    Converts the given string to a UTF-8 string.

    This will always create a copy.
*/
ref auto toUTF8(FromT)(ref auto FromT from) if (isSomeSafeString!FromT) {
    static if (StringCharSize!FromT == 1)
        return nstring(from);
    else
        return encode!nstring(decode(from, true), false);
}

/**
    Converts the given string to a UTF-16 string.

    This will always create a copy.
*/
ref auto toUTF16(FromT)(ref auto FromT from, bool addBOM = false) if (isSomeSafeString!FromT) {
    static if (StringCharSize!FromT == 2)
        return nwstring(from);
    else
        return encode!nwstring(decode(from, true), addBOM);
}

/**
    Converts the given string to a UTF-32 string.

    This will always create a copy.
*/
ref auto toUTF32(FromT)(ref auto FromT from, bool addBOM = false) if (isSomeSafeString!FromT) {
    static if (StringCharSize!FromT == 2)
        return ndstring(from);
    else
        return encode!ndstring(decode(from, true), addBOM);
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