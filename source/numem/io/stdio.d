/**
    helpers for console output
*/
module numem.io.stdio;
import numem.string;
import numem.core.hooks;

/**
    A hook which writes to the standard output.
*/
@weak
extern(C)
void nuWrite(nstring str) @nogc {
    
    import core.stdc.stdio : putchar;
    foreach(i; 0..str.length)
        putchar(str[i]);
}

/**
    The newline representation of the target platform.
*/
version(Windows) enum string NEWLINE = "\r\n";
else enum string NEWLINE = "\r";

/**
    A constant shared newline representation for the platform.
*/
__gshared const(char)* endl = NEWLINE;

/**
    Writes to standard output
*/
void write(Args...)(Args args) @nogc {

    import numem.conv : toString;
    static foreach(arg; args) {
        static if (is(typeof(arg) == nstring)) {
            nuWrite(arg);
        } else static if (is(typeof(arg) == string)) {
            nuWrite(nstring(arg));
        } else {

            // Recursively convert to nstring.
            write(arg.toString());
        }
    }
}

/**
    Writes to standard output

    Adds a newline at the end of the line
*/
void writeln(Args...)(Args args) @nogc {
    write(args);
    nuWrite(nstring(endl));
}


/**
    Writes to standard output with formatting.

    Adds a newline at the end of the line
*/
void writefln(Args...)(nstring fmt, Args args) @nogc {

    import numem.format : format;
    writeln(format(fmt.ptr, args));
}