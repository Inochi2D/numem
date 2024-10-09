/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module numem.text.unicode.utf16;
import numem.text.unicode.utf32;
import numem.text.unicode;
import numem.collections.vector;
import numem.string;
import numem.io.endian;

nothrow @nogc:

private {

    // Surrogate mask
    enum ushort utf16_smask = 0b11111100_00000000;
    
    // Data mask
    enum ushort utf16_dmask = cast(ushort)(~utf16_smask);

    /// Leading surrogate
    enum wchar utf16_lead  = 0b11011000_00000000;

    /// Trailing surrogate
    enum wchar utf16_trail = 0b11011100_00000000;
}

/**
    Validates whether the given character is a valid UTF-16 sequence
*/
bool validate(wchar[2] c) {
    return 
        ((c[0] >= 0 && c[0] <= 0xD7FF) || (c[0] >= 0xE000 && c[0] <= 0xFFFF)) ||
        ((c[0] & utf16_smask) == utf16_lead && ((c[1] & utf16_smask) == utf16_trail));
}

/**
    Validates whether the given nwstring is a valid UTF-16 string.

    This function assumes that the string is in machine-native
    endianess.
*/
bool validate(nwstring str) {
    return validate(str[]);
}


/**
    Validates whether the given nwstring is a valid UTF-16 string.

    This function assumes that the string is in machine-native
    endianess.
*/
bool validate(inout(wchar)[] str) {
    nwstring tmp = str;

    // Handle endianess.
    codepoint bom = getBOM(str);
    if (bom != 0 && getEndianFromBOM(bom) != NATIVE_ENDIAN) {
        tmp = toMachineOrder(str);
    }

    size_t i = 0;
    while(i < tmp.length) {
        wchar[2] txt;

        // Validate length
        size_t clen = getLength(tmp[i]);
        if (clen >= i+tmp.length) return false;
        if (clen == 0) return false;

        txt[0..clen] = tmp[i..i+clen];
        if (!validate(txt)) return false;

        i += clen;
    }

    return true;
}

/**
    Gets the BOM of the nwstring if it has one.

    Otherwise returns a NUL character.
*/
codepoint getBOM(inout(wchar)[] str) {
    if (str.length == 0) 
        return 0;

    union tmp {
        wchar c;
        ubyte[2] bytes;
    }
    tmp tmp_;
    tmp_.c = str[0];

    if (isBOM(cast(codepoint)tmp_.c)) {
        return cast(codepoint)tmp_.c;
    }

    return 0;
}

/**
    Gets the BOM of the nwstring if it has one.

    Otherwise returns a NUL character.
*/
codepoint getBOM(nwstring str) {
    return getBOM(str[]);
}

/**
    Gets how many utf-16 units are in the specified character
*/
size_t getLength(wchar c) {
    if ((c >= 0 && c <= 0xD7FF) || (c >= 0xE000 && c <= 0xFFFF)) return 1;
    if ((c & utf16_smask) == utf16_lead) return 2;
    return 0;
}

@("UTF-16 char len")
unittest {
    assert('a'.getLength == 1);
    assert('あ'.getLength == 1);
    assert(utf16_trail.getLength() == 0); // Malformed leading byte
}

/**
    Gets how many utf-16 units are in the specified codepoint

    Returns 0 if the codepoint can't be represented.
*/
size_t getUTF16Length(codepoint code) {
    if (code <= 0xD7FF || (code >= 0xE000 && code <= 0xFFFF)) return 1;
    else if (code >= 0x010000 && code <= 0x10FFFF) return 2;
    return 0;
}

@("UTF-16 codepoint len")
unittest {
    assert(0xF4.getUTF16Length == 1);
    assert(0x10FFFF.getUTF16Length == 2);
    assert(0x11FFFF.getUTF16Length == 0);
}

/**
    Returns a string which is [str] converted to machine order.

    If the string has no BOM the specified fallback endian will be used.
*/
nwstring toMachineOrder(inout(wchar)[] str, Endianess fallbackEndian = NATIVE_ENDIAN) {

    if (str.length == 0)
        return nwstring.init;

    codepoint bom = getBOM(str);
    Endianess endian = getEndianFromBOM(bom);
    if (bom == 0)
        endian = fallbackEndian;
    
    if (endian != NATIVE_ENDIAN) {

        // Flip all the bytes around.
        nwstring tmp;
        foreach(i, ref const(wchar) c; str) {
            tmp ~= c.toEndianReinterpret(endian);
        }
        return tmp;
    }

    // Already local order.
    return nwstring(str);
}

/**
    Returns a string which is [str] converted to machine order.

    If the string has no BOM it is assumed it's already in
    machine order.
*/
nwstring toMachineOrder(nwstring str) {
    return toMachineOrder(str[]);
}

/**
    Decodes a single utf-16 character,

    Character is assumed to be in the same
    endianness as the system!
*/
codepoint decode(wchar[2] chr, ref size_t read) {
    // Handle endianness
    read = chr[0].getLength();
    
    switch(read) {
        default:
            read = 1;
            return unicodeReplacementCharacter;
        
        case 1: 
            return cast(codepoint)chr[0];
        
        case 2:
            codepoint code = 
                ((chr[0] & utf16_dmask) + 0x400) +
                ((chr[1] & utf16_dmask) + 0x37) +
                0x10000;
            return code;
    }
}

/**
    Decodes a single utf-16 character from a 
    nwstring.
*/
codepoint decodeOne(nwstring str, size_t offset = 0) {
    if (str.length == 0) 
        return unicodeReplacementCharacter;

    // Gets the string in the current machine order.
    str = str.toMachineOrder();

    // Get length of first character.
    size_t read = getLength(str[0]);
    size_t i;
    while(i < offset++) {

        // We're out of characters to read.
        if (read > str.length)
            return unicodeReplacementCharacter;

        read = getLength(str[read]);
    }
    
    // Decode to UTF-32 to avoid duplication
    // of effort.
    wchar[2] tmp;
    tmp[0..read] = str[0..read];
    return decode(tmp, read);
}

/**
    Decodes a UTF-16 string.

    This function will automatically detect BOMs
    and handle endianness where applicable.
*/
UnicodeSequence decode(inout(wchar)[] str, bool stripBOM = false) {
    UnicodeSequence code;

    // Gets the string in the current machine order.
    nwstring tmp = str.toMachineOrder();
    size_t i = 0;

    // Strip BOM if there is one.
    if (stripBOM && getBOM(tmp)) {
        i++;
    }

    while(i < tmp.length) {
        wchar[2] txt;

        // Validate length, add FFFD if invalid.
        size_t clen = tmp[i].getLength();
        if (clen >= i+tmp.length || clen == 0) {
            code ~= unicodeReplacementCharacter;
            i++;
        }

        txt[0..clen] = tmp[i..i+clen];
        code ~= txt.decode(clen);
        i += clen;
    }

    return code;
}

/**
    Decodes a UTF-16 string.

    This function will automatically detect BOMs
    and handle endianness where applicable.
*/
UnicodeSequence decode(nwstring str, bool stripBOM = false) {
    return decode(str[], stripBOM);
}

@("UTF-16 decode string")
unittest {
    codepoint[8] seq1 = [0x3053, 0x3093, 0x306b, 0x3061, 0x306f, 0x4e16, 0x754c, 0xff01];
    codepoint[8] seq2 = [0x3053, unicodeReplacementCharacter, 0x306b, 0x3061, 0x306f, 0x4e16, 0x754c, 0xff01];
    assert(decode(nwstring("こんにちは世界！"w))[0..$] == seq1);
    assert(decode(nwstring("こ\uFFFDにちは世界！"w))[0..$] == seq2);
}

/**
    Encodes a unicode sequence to UTF-16
*/
nwstring encode(UnicodeSlice slice, bool addBOM = false) {
    nwstring out_;

    // Add BOM if requested.
    if (addBOM && slice.length > 0 && slice[0] != UNICODE_BOM) {
        out_ ~= cast(wchar)UNICODE_BOM;
    }

    size_t i = 0;
    while(i < slice.length) {
        wchar[2] txt;

        size_t clen = slice[i].getUTF16Length();
        if (clen == 1) {
            txt[0] = cast(wchar)slice[i];
            out_ ~= txt[0];
        } if (clen == 2) {
            codepoint c = slice[i] - 0x10000;
            
            txt[0] = cast(wchar)((c >> 10) + 0xD800);
            txt[1] = cast(wchar)((c << 10) + 0xDC00);
            out_ ~= cast(wstring)txt[0..$];
        } else {
            i++;
            continue;
        }        

        i++;
    }

    return out_;
}

/**
    Encodes a series of unicode codepoints to UTF-16
*/
nwstring encode(UnicodeSequence sequence, bool addBOM = false) {
    return encode(sequence[0..$], addBOM);
}

@("UTF-16 encode")
unittest {
    codepoint[8] seq1 = [0x3053, 0x3093, 0x306b, 0x3061, 0x306f, 0x4e16, 0x754c, 0xff01];
    codepoint[8] seq2 = [0x3053, unicodeReplacementCharacter, 0x306b, 0x3061, 0x306f, 0x4e16, 0x754c, 0xff01];
    assert(encode(seq1) == "こんにちは世界！"w);
    assert(encode(seq2) == "こ\uFFFDにちは世界！"w);
}