module numem.unicode;
import numem.mem.vector;

/**
    A unicode codepoint
*/
alias codepoint = uint;

/**
    A unicode codepoint sequence
*/
alias UnicodeSequence = vector!codepoint;

/**
    A unicode codepoint sequence
*/
alias UnicodeSlice = codepoint[];

/**
    A unicode grapheme
*/
struct Grapheme {
private:
    size_t state;

public:

    /**
        Byte offset
    */
    size_t offset;

    /**
        Cluster of codepoints, memory beloning to the original UnicodeSequence
    */
    codepoint[] cluster;
}

/**
    A sequence of graphemes
*/
alias GraphemeSequence = weak_vector!Grapheme;