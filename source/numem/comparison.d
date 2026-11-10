/**
    Comparison helpers.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module numem.comparison;

/**
	Compares 2 types for equality, circumventing DRuntime's
	opEquals implementation.

    The left and right-hand side of the comparison must be nogc.

	Params:
		lhs = The left hand side of the comparison
		rhs = The right hand side of the comparison

	Returns:
		$(D true) if the 2 values are considered equal,
		$(D false) otherwise.
*/
bool nu_equals(LHS, RHS)(ref LHS lhs, ref RHS rhs) @nogc nothrow {

    // NOTE:    DRuntime's opEquals implementation is not nogc
    //          as such we need to check whether we can do an equals comparison
    //          in a nogc context.
    //          Otherwise, we try calling opEquals directly, if that fails we try
    //          the `is` operator, and finally if that fails we assert at compile-time.
    static if (is(typeof(() @nogc { return LHS.init == RHS.init; }))) {
        return lhs == rhs;
    } else static if (is(typeof(() @nogc { return LHS.init.opEquals(RHS.init); }))) {
        return lhs.opEquals(rhs);
    } else static if (is(typeof(() @nogc { return LHS.init is RHS.init; }))) {
        return lhs is rhs;
    } else static assert(0, LHS.stringof~".opEquals("~RHS.stringof~") is not @nogc!");
}