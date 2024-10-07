module numem.format;
import numem.string;
import numem.text.ascii;
import numem.conv;
import numem.collections;

import std.traits;

private {
    enum CanConvertToNString(T) =
        __traits(hasMember, T, "toNString") &&
        is(T.toNString : nstring function()) &&
        hasUDA(T.toNString, nogc);

    enum CanConvertToDString(T) =
        __traits(hasMember, T, "toString") &&
        is(T.toNString : string function()) &&
        hasUDA(T.toNString, nogc);

    nstring _formatSingle(T)(T element) {
        static if(CanConvertToNString!T) {

            return element.toNString();
        } else static if(CanConvertToDString!T) {

            return nstring(element.toString());
        } else static if (is(T : string)) {

            return nstring(element);
        } else static if (isBasicType!T) {

            return toString!T(element);
        } else {
            return nstring(T.stringof);
        }
    }

    bool isNumericStr(nstring str) @nogc nothrow {
        foreach(i; 0..str.length) {
            if (!isNumeric(str[i])) 
                return false;
        }
        return true;
    }
}

/**
    Provides C# style formatting.
*/
pragma(inline, true)
nstring format(Args...)(const(char)* fmt, Args args) @nogc nothrow {
    return format(nstring(fmt), args);
}

/**
    Provides C# style formatting.
*/
pragma(inline, true)
nstring format(Args...)(string fmt, Args args) @nogc nothrow {
    return format(nstring(fmt), args);
}

/**
    Interface to snprintf.
*/
@system
nstring cformat(Args...)(const(char)* fmt, Args args) @nogc nothrow {
    import core.stdc.stdio : snprintf;
    nstring out_ = nstring(snprintf(null, 0, fmt, args));
    snprintf(cast(char*)out_.ptr, out_.length+1, fmt, args);
    return out_;
}

/**
    Provides C# style formatting.
*/
@trusted
nstring format(Args...)(nstring fmt, Args args) @nogc {
    vector!nstring formatted = vector!nstring(args.length);

    static foreach(i; 0..args.length) {
        formatted[i] = _formatSingle(args[i]);
    }
    
    size_t i;
    nstring out_;

    mainLoop: do {
        
        // Current index, if backtracking is needed.
        size_t ci = i;

        // Previous character for format escape.
        char pc = i > 1 ? fmt[i-1] : '\0';
        char c = fmt[i];

        if (pc != '\\' && c == '{' && i+2 < fmt.length) {
            while(fmt[i++] != '}') {

                // Was not a format string.
                if (i >= fmt.length) {
                    out_ ~= fmt[ci..$];
                    break mainLoop;
                }
            }

            auto fmtslice = nstring(fmt[ci+1..i-1]);
            if (isNumericStr(fmtslice)) {
                size_t idx = toInt!size_t(fmtslice);
                if (idx < formatted.length) {
                    out_ ~= formatted[idx];
                    continue mainLoop;
                }
            }

            // Fall-through
            i = ci;
        }

        out_ ~= c;
        i++;
    } while(i < fmt.length);

    return out_;
}

@("Basic format")
unittest {
    assert("Hello, {0}".format("world!") == "Hello, world!");
    assert("{0}".format(42) == "42");
    assert("{0}".format(12.5) == "12.5");
}