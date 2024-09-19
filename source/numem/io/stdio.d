/**
    helpers for console output
*/
module numem.io.stdio;

version(NoC) {
    // If there's no C this should be disabled.
} else {

    import numem.string;
    import numem.conv;
    import core.stdc.stdio : printf, puts;

    /**
        Writes to standard output
    */
    void write(Args...)(Args args) {
        static foreach(arg; args) {
            static if (is(typeof(arg) == nstring)) {
                puts(arg.toCString);
            } else static if (is(typeof(arg) == string)) {
                printf("%.*s", cast(int)arg.length, arg.ptr);
            } else {
                puts(arg.toString().toCString());
            }
        }
    }

    /**
        Writes to standard output

        Adds a newline at the end of the line
    */
    void writeln(Args...)(Args args) {
        write(args);
        puts("\n");
    }

    // TODO: writefln
}