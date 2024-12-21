/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    Numem "Universal" utilities
*/
module numem.text.uni;
import numem.text.ascii;

@nogc nothrow:

/**
    Gets whether the character is a universal alpha or numeric.

    Standards: 
        Conforms to ISO/IEC 9899:1999(E) Appendix D of the C99 Standard.
        Additionally accepts digits.
*/
bool isUniAlphaNumeric(char c) {
    return 
        (c >= 'a' && c <= 'z') || 
        (c >= 'A' && c <= 'Z') || 
        (c >= '0' && c <= '9') || 
        c == '_';
}

/**
    Gets whether the character is a C universal alpha character.
    
    Standards: 
        Conforms to ISO/IEC 9899:1999(E) Appendix D of the C99 Standard.
*/
bool isUniAlpha(char c) {
    return 
        (c >= 'a' && c <= 'z') || 
        (c >= 'A' && c <= 'Z') || 
        c == '_';
}

/**
    Gets whether the given string is a universal C identifier.

    Standards: 
        Conforms to ISO/IEC 9899:1999(E) Appendix D of the C99 Standard.
*/
bool isUniIdentifier(inout(char)[] iden) {
    if (iden.length == 0)
        return false;
    
    if (!iden[0].isUniAlpha())
        return false;

    foreach(i; 1..iden.length) {
    
        if (!iden[i].isUniAlphaNumeric())
            return false;
    }

    return true;
}