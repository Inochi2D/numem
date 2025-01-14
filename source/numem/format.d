/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Numem string formatting
*/
module numem.format;

import numem.string;
import numem.text.ascii;
import numem.conv;
import numem.collections;
import numem.core.traits;
import numem.text.uni;

private {
    nstring _formatSingle(T)(T element) {
        static if(isStringable!T) {

            return nstring(element.toString());
        } else static if (isSomeSafeString!T) {

            return nstring(element);
        } else static if (isSomeCString!T) {

            return nstring(element[0..cstrlen(element)]);
        } else static if (isBasicType!T) {

            return toString!T(element);
        } else {

            return nstring(T.stringof);
        }
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
            if (isIntegral(fmtslice[])) {
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

@("Unicode: safe string")
unittest {
    assert("{0}".format("Hello, world!"w) == "Hello, world!");
}

@("Unicode: unsafe string")
unittest {

    const(dchar)* cdstr = "UTF-32";
    assert("{0}".format(cdstr) == "UTF-32");

    const(wchar)* cwstr = "UTF-16";
    assert("{0}".format(cwstr) == "UTF-16");
}