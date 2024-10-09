module numem.text.encoding;
import numem.string;
import numem.text.ascii;
import numem.text.unicode;
import numem.text.unicode.utf8;
import numem.text.unicode.utf16;

/**
    Currently supported encodings
*/
enum Encoding {

    /**
        Unknown encoding
    */
    unknown,

    /**
        ASCII
    */
    ascii,
    
    /**
        UTF-8
    */
    utf8,

    /**
        UTF-16
    */
    utf16,

    /**
        UTF-16 w/ BOM
    */
    utf16LE,

    /**
        UTF-16 w/ BOM
    */
    utf16BE,

    /**
    
    */
    utf32
}

/**
    Gets the encoding of a run of text.
*/
Encoding getEncoding(T)(auto ref T str) @nogc if (isSomeString!T) {
    static if (StringCharSize!T == 1) {
        nstring nstr = str;

        foreach(char c; str[]) {
            if (!isASCII(c)) {
                if (validate(nstr))
                    return Encoding.utf8;
                else
                    return Encoding.unknown;
            }
        }
        return Encoding.ascii;

    } else static if (StringCharSize!T == 2) {
        
        nwstring nstr = str;
        auto bom = getBOM(nstr);
        if (bom != 0) {
            return bom == 0x0000FEFF ? 
                Encoding.utf16BE : 
                Encoding.utf16LE;
        } else if (validate(nstr)) {

            return Encoding.utf16;
        }
        return Encoding.unknown;

    } else static if (StringCharSize!T == 4) {

        return validate(str) ? 
            Encoding.utf32 : 
            Encoding.unknown;
    } else {

        return Encoding.unknown;
    }
} 

@("Get encoding")
unittest {
    import std.stdio : writeln;

    assert("Hello, world!".getEncoding() == Encoding.ascii);
    assert("あえおう".getEncoding() == Encoding.utf8);

    assert("Hello, world!"w.getEncoding() == Encoding.utf16);
    assert("\uFEFFHello, world!"w.getEncoding() == Encoding.utf16BE);
    assert("\uFFFEHello, world!"w.getEncoding() == Encoding.utf16LE);
}