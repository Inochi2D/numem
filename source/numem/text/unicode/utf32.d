/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.text.unicode.utf32;
import numem.text.unicode;
import numem.string;
import numem.io.endian;

@nogc nothrow:

/**
    Validates a UTF32 codepoint
*/
bool validate(dchar c) {
    return validate(c);
}

/**
    Validates a UTF32 string
*/
bool validate(ndstring str) {
    return validate(str[]);
}

/**
    Validates a UTF32 string
*/
bool validate(inout(dchar)[] str) {
    ndstring tmp = str;

    // Handle endianess.
    codepoint bom = getBOM(str);
    if (bom != 0 && getEndianFromBOM(bom) != NATIVE_ENDIAN) {
        tmp = toMachineOrder(str);
    }

    foreach(dchar c; tmp) {
        if (!validate(c)) 
            return false;
    }

    return true;
}

/**
    Gets the BOM
*/
codepoint getBOM(inout(dchar)[] str) {
    if (str.length == 0)
        return 0;
    
    // This is UTF32.
    if (isBOM(str[0]))
        return str[0];

    return 0;
}

/**
    Returns a string which is [str] converted to machine order.

    If the string has no BOM it is assumed it's already in
    machine order.
*/
ndstring toMachineOrder(inout(dchar)[] str) {
    
    // Empty string early escape.
    if (str.length == 0) 
        return ndstring.init;

    codepoint bom = getBOM(str);
    Endianess endian = getEndianFromBOM(bom);
    if (bom != 0 && endian != NATIVE_ENDIAN) {

        // Flip all the bytes around
        ndstring tmp;
        foreach(i, ref const(dchar) c; str) {
            tmp ~= c.toEndianReinterpret(endian);
        }

        return tmp;
    }

    return ndstring(str);
}

/**
    Decodes a single UTF-32 character
*/
codepoint decode(dchar c) {
    if (!validate(c))
        return unicodeReplacementCharacter;
    return c;
}

/**
    Decodes a single UTF-32 string
*/
ndstring decode(inout(dchar)[] str, bool stripBOM) {
    ndstring tmp;
    size_t start = 0;

    // Handle BOM
    if (getBOM(str) != 0) {
        tmp = toMachineOrder(str);
        start = stripBOM ? 1 : 0;
    }

    foreach(ref c; str[start..$]) {
        tmp ~= cast(wchar)decode(c);
    }

    return tmp;
}

/**
    Encodes a UTF-32 string.

    Since UnicodeSequence is already technically
    UTF-32 this doesn't do much other than
    throw the data into a nwstring.
*/
ndstring encode(UnicodeSequence sequence) {
    return ndstring(cast(dchar[])sequence[0..$]);
}