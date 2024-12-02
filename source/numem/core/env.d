/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    Numem environment managment support
*/
module numem.core.env;
import numem.string;
import numem.text.unicode;
import numem.core.memory;

version(Windows) import core.sys.windows.winbase : GetEnvironmentVariableW, SetEnvironmentVariableW;
else import core.sys.posix.stdlib : setenv, getenv;

@nogc:

/**
    Interface to system environment.
*/
struct Environment {
@nogc:
private:
    static nstring get(const(char)* key) {
        version(Windows) {
            auto utf16k = key.toUTF16;

            // Try getting the size of the env var.
            // if this fails, the env var is probably empty.
            uint bufSize = GetEnvironmentVariableW(utf16k.ptr, null, 0);
            if (bufSize == 0)
                return nstring.init;
            
            // Windows includes the null terminator, but n*string does too
            // so to not have 2 null terminators, subtract 1.
            nwstring envstr = nwstring(bufSize-1);
            bufSize = GetEnvironmentVariableW(utf16k.ptr, envstr.ptr, envstr.length+1);

            nogc_delete(utf16k);
            return envstr.toUTF8;
        } else {
            return nstring(getenv(key));
        }
    }

    static bool set(const(char)* key, nstring value) {
        version(Windows) {
            auto utf16k = key.toUTF16();
            auto utf16v = value.toUTF16();
            return SetEnvironmentVariableW(utf16k.ptr, utf16v.ptr);
        } else {
            return setenv(key, value.ptr, 1) == 0;
        }
    }

public:

    /**
        Returns the value at the given key.

        Returns an empty nstring if key was not found.
    */
    static ref auto opIndex(const(char)* key) {
        return get(key);
    }

    /**
        Sets the value at the given key.
    */
    static void opIndexAssign(string value, const(char)* key) {
        set(key, nstring(value));
    }

    /**
        Appends to the value at the given key.
    */
    static void opIndexOpAssign(string op = "~")(string value, const(char)* key) {
        auto tmp = get(key);
        tmp ~= value;
        set(key, tmp);
    }
}

@("Environment: Get and Set")
unittest {
    auto envA = Environment["A"];
    assert(envA.empty());

    Environment["A"] = "Hello, world!";
    envA = Environment["A"];
    assert(envA == "Hello, world!");
}