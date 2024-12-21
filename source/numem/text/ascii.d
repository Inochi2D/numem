/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    Numem ascii utility functions
*/
module numem.text.ascii;

@nogc nothrow:

/**
    Gets whether the character is ascii
*/
bool isASCII(char c) {
    return c < 128;
}

/**
    Gets whether the character is a hexidedcimal digit
*/
bool isHex(char c) {
    return 
        (c >= 'a' && c <= 'f') || 
        (c >= 'A' && c <= 'F') || 
        (c >= '0' && c <= '9');
}

/**
    Gets whether the character is numeric.
*/
bool isDigit(char c) {
    return (c >= '0' && c <= '9');
}

/**
    Gets whether the character is alphabetic.
*/
bool isAlpha(char c) {
    return 
        (c >= 'a' && c <= 'z') || 
        (c >= 'A' && c <= 'Z');
}

/**
    Gets whether the character is alpha-numeric.
*/
bool isAlphaNumeric(char c) {
    return 
        (c >= 'a' && c <= 'z') || 
        (c >= 'A' && c <= 'Z') || 
        (c >= '0' && c <= '9');
}

/**
    Gets whether the character is printable
*/
bool isPrintable(char c) {
    return (c >= 32 && c < 126);
}

/**
    Gets whether the character is an ASCII non-printable escape character
*/
bool isEscapeCharacter(char c) {
    return
        (c >= 0 && c <= 31) || 
        (c == 127);
}