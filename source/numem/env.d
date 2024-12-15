/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    Numem Environment handling
*/
module numem.env;
import numem.string;
import numem.text.unicode;
import numem.core.memory;
import numem.core.hooks;

@nogc:

/**
    Interface to system environment.
*/
struct Environment {
@nogc:
public:

    /**
        Returns the value at the given key.

        Returns an empty nstring if key was not found.
    */
    static ref auto opIndex(const(char)* key) {
        return nuGetEnvironmentVariable(nstring(key));
    }

    /**
        Sets the value at the given key.
    */
    static bool opIndexAssign(string value, const(char)* key) {
        return nuSetEnvironmentVariable(nstring(key), nstring(value));
    }

    /**
        Appends to the value at the given key.
    */
    static bool opIndexOpAssign(string op = "~")(string value, const(char)* key) {
        auto tmp = get(key);
        tmp ~= value;
        return nuSetEnvironmentVariable(nstring(key), tmp);
    }
}

@("Environment: Get and Set")
unittest {
    auto envA = Environment["A"];
    assert(envA.empty());

    assert(Environment["A"] = "Hello, world!"); // We return whether setting succeeded.
    envA = Environment["A"];
    assert(envA == "Hello, world!");
}

/**
    Hook which fetches the specified environment variable.
*/
@weak
extern(C)
nstring nuGetEnvironmentVariable(nstring key) @nogc {
    version(Windows) {
        import core.sys.windows.winbase : GetEnvironmentVariableW;
        auto utf16k = key.toUTF16;

        // Try getting the size of the env var.
        // if this fails, the env var is probably empty.
        uint bufSize = GetEnvironmentVariableW(cast(wchar*)utf16k.ptr, null, 0);
        if (bufSize == 0)
            return nstring.init;
        
        // Windows includes the null terminator, but n*string does too
        // so to not have 2 null terminators, subtract 1.
        nwstring envstr = nwstring(bufSize-1);
        bufSize = GetEnvironmentVariableW(cast(wchar*)utf16k.ptr, cast(wchar*)envstr.ptr, cast(uint)envstr.length+1);

        nogc_delete(utf16k);
        return envstr.toUTF8;
    } else version(Posix) {

        import core.sys.posix.stdlib : getenv;
        return nstring(getenv(key.ptr));
    } else {
        return nstring(null);
    }
}

/**
    Hook which sets the specified environment variable.
*/
@weak
extern(C)
bool nuSetEnvironmentVariable(nstring key, nstring value) @nogc {
    version(Windows) {

        import core.sys.windows.winbase : SetEnvironmentVariableW;
        auto utf16k = key.toUTF16();
        auto utf16v = value.toUTF16();
        return SetEnvironmentVariableW(cast(wchar*)utf16k.ptr, cast(wchar*)utf16v.ptr);
    } else version(Posix) {

        import core.sys.posix.stdlib : setenv;
        return setenv(key.ptr, value.ptr, 1) == 0;
    } else {
        return false;
    }
}