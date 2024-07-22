module numem.unicode.utf16;
import numem.unicode;
import numem.mem.string;
import numem.mem.vector;

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
    Decodes a single utf-16 character
*/
codepoint decode(wchar[2] chr, ref size_t read) {
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
    Decodes a utf-16 string
*/
UnicodeSequence decode(nwstring str) {
    UnicodeSequence code;

    size_t i = 0;
    while(i < str.size()) {
        wchar[2] txt;

        // Validate length, add FFFD if invalid.
        size_t clen = str[i].getLength();
        if (clen >= i+str.size() || clen == 0) {
            code ~= unicodeReplacementCharacter;
            i++;
        }

        txt[0..clen] = str[i..i+clen];
        code ~= txt.decode(clen);
        i += clen;
    }

    return code;
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
nwstring encode(UnicodeSlice slice) {
    nwstring out_;

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
nwstring encode(UnicodeSequence sequence) {
    return encode(sequence[0..$]);
}

@("UTF-16 encode")
unittest {
    codepoint[8] seq1 = [0x3053, 0x3093, 0x306b, 0x3061, 0x306f, 0x4e16, 0x754c, 0xff01];
    codepoint[8] seq2 = [0x3053, unicodeReplacementCharacter, 0x306b, 0x3061, 0x306f, 0x4e16, 0x754c, 0xff01];
    assert(encode(seq1) == "こんにちは世界！"w);
    assert(encode(seq2) == "こ\uFFFDにちは世界！"w);
}