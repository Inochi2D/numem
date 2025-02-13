/**
    Numem meta templates.

    Most of these are taken directly from the D runtime.
    
    Copyright:
        Copyright © 2005-2009, The D Language Foundation.
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        $(HTTP digitalmars.com, Walter Bright),
        $(HTTP klickverbot.at, David Nadlinger)
        Luna Nielsen
*/
module numem.core.meta;

/**
    Equivalent to D runtime's AliasSeq.
*/
alias AliasSeq(AliasList...) = AliasList;

/**
    A template which gets whether all the inputs satisfy the condition
    outlined in $(D F).
*/
template allSatisfy(alias F, T...) {
    static foreach(U; T) {
        static if (!is(typeof(allSatisfy) == bool) && !F!(U))
            enum allSatisfy = false;
    }

    static if (!is(typeof(allSatisfy) == bool))
        enum allSatisfy = true;
}

/**
    A template which gets whether any of the inputs satisfy the 
    condition outlined in $(D F).
*/
template anySatisfy(alias F, T...) {
    static foreach(U; T) {
        static if (!is(typeof(anySatisfy) == bool) && F!(U))
            enum anySatisfy = false;
    }

    static if (!is(typeof(anySatisfy) == bool))
        enum anySatisfy = false;
}

/**
    Returns a sequence of F!(T[0]), F!(T[1]), ..., F!(T[$-1])
*/
template staticMap(alias F, T...) {
    static if (T.length == 0)
        alias staticMap = AliasSeq!();
    else static if (T.length == 1)
        alias staticMap = AliasSeq!(F!(T[0]));
    else static if (T.length == 2)
        alias staticMap = AliasSeq!(F!(T[0]), F!(T[1]));
    else static if (T.length == 3)
        alias staticMap = AliasSeq!(F!(T[0]), F!(T[1]), F!(T[2]));
    else static if (T.length == 4)
        alias staticMap = AliasSeq!(F!(T[0]), F!(T[1]), F!(T[2]), F!(T[3]));
    else static if (T.length == 5)
        alias staticMap = AliasSeq!(F!(T[0]), F!(T[1]), F!(T[2]), F!(T[3]), F!(T[4]));
    else static if (T.length == 6)
        alias staticMap = AliasSeq!(F!(T[0]), F!(T[1]), F!(T[2]), F!(T[3]), F!(T[4]), F!(T[5]));
    else static if (T.length == 7)
        alias staticMap = AliasSeq!(F!(T[0]), F!(T[1]), F!(T[2]), F!(T[3]), F!(T[4]), F!(T[5]), F!(T[6]));
    else static if (T.length == 8)
        alias staticMap = AliasSeq!(F!(T[0]), F!(T[1]), F!(T[2]), F!(T[3]), F!(T[4]), F!(T[5]), F!(T[6]), F!(T[7]));
    else {
        alias staticMap =
            AliasSeq!(
                staticMap!(F, T[ 0  .. $/2]),
                staticMap!(F, T[$/2 ..  $ ]));
    }
}

/**
    Returns a sequence containing the provided sequence after filtering by $(D F).
*/
template Filter(alias F, T...) {
    static if (T.length == 0)
        alias Filter = AliasSeq!();
    else static if (T.length == 1) {

        // LHS
        static if (F!(T[0]))
            alias Filter = AliasSeq!(T[0]);
        else
            alias Filter = AliasSeq!();
    } else static if (T.length == 2) {

        // LHS
        static if (F!(T[0]))
            alias Filter = AliasSeq!(T[0]);
        else
            alias Filter = AliasSeq!();

        // RHS
        static if (F!(T[1]))
            alias Filter = AliasSeq!(T[1]);
        else
            alias Filter = AliasSeq!();
    } else alias Filter = AliasSeq!(
        Filter!(F, T[0 .. $/2]),
        Filter!(F, T[$/2..$])
    );
}