module numem.core.random;
import numem.core;
import std.traits;

/**
    Base class of all random number generators
*/
abstract
class RandomBase {
@nogc nothrow:

    /**
        Resets the random number generator to its initial state.
    */
    abstract void reset();

    /**
        Gets the next value in the random stream
    */
    abstract size_t next();

    /**
        Gets the next value in the random stream
    */
    abstract double nextUniform();

    /**
        Gets the next bytes in the random stream
    */
    abstract void next(ref ubyte[] destination);
}

/**
    A psuedo-random number generator
*/
class Random : RandomBase {
@nogc nothrow:
private:

    enum mtWordSize = (size_t.sizeof*8);
    static if (mtWordSize == 32) {
        enum mtRecurrence = 624;
        enum mtMiddleWord = 397;
        enum mtSeperationPoint = 31;
        enum mtMagicNumber = 1_812_433_253;
        enum mtTwistCoefficient = 0x9908B0DF;

        enum mtU = 11;
        enum mtD = 0xFFFFFFFF;
        enum mtS = 7;
        enum mtB = 0x9D2C5680;
        enum mtT = 15;
        enum mtC = 0xEFC60000;
        enum mtL = 18;

    } else {
        enum mtRecurrence = 312;
        enum mtMiddleWord = 156;
        enum mtSeperationPoint = 31;
        enum mtMagicNumber = 6_364_136_223_846_793_005;
        enum mtTwistCoefficient = 0xB5026F5AA96619E9;

        enum mtU = 29;
        enum mtD = 0x5555555555555555;
        enum mtS = 17;
        enum mtB = 0x71D67FFFEDA60000;
        enum mtT = 37;
        enum mtC = 0xFFF7EEE000000000;
        enum mtL = 43;
    }

    enum mtUpperMask = (size_t.max << mtSeperationPoint);
    enum mtLowerMask = (size_t.max >> (mtWordSize-mtSeperationPoint));

    
    size_t[mtRecurrence] state;
    size_t idx;
    size_t seed;

    /// Resets the mersenne twister algorithm.
    void initialize() {
        state[0] = seed;

        // NOTE: Local seed iteration.
        //       This is to allow calling reset()
        size_t nseed = seed;
        foreach(i; 1..state.length) {
            nseed = mtMagicNumber * (nseed ^ (nseed >> (mtWordSize-2))) + i;
            state[i] = nseed;
        }

        idx = 0;
    }
public:

    /**
        Constructs a random number generator with a set seed.
    */
    this(size_t seed) {
        this.seed = seed;
        this.initialize();
    }

    /**
        Constructs a random number generator with a set seed.
    */
    override
    void reset() {
        this.initialize();
    }

    /**
        Gets the next value in the random stream
    */
    override
    size_t next() {
        
        // Get current index and at the opposite end of the circular buffer.
        ptrdiff_t k = idx;
        ptrdiff_t j = k - (mtRecurrence-1);
        if (j < 0) 
            j += mtRecurrence;

        size_t x = (state[k] & mtUpperMask) | (state[j] & mtLowerMask);
        
        
        size_t xA = x >> 1;
        if (x & 1) xA ^= mtTwistCoefficient;

        // Point to state recurrange - magic number
        // modulo if need be.
        j = k - (mtRecurrence-mtMiddleWord);
        if (j < 0)
            j += mtRecurrence;

        // Compute and set next state value
        x = state[j] ^ xA;
        state[k++] = x;

        // Wrap around
        if (k >= mtRecurrence)
            k = 0;
        idx = k;

        // Tempering algorithm
        size_t  y = x ^ (x >> mtU);
                y = y ^ ((y << mtS) & mtB);
                y = y ^ ((y << mtT) & mtC);

        return y ^ (y >> 1);
    }

    /**
        Gets the next value in the random stream
    */
    override
    double nextUniform() {
        size_t nrandom = this.next();
        return cast(double)nrandom/cast(double)size_t.max;
    }

    /**
        Gets the next bytes in the random stream
    */
    override
    void next(ref ubyte[] destination) {

        // State of random number generator
        union tmp {
            ubyte[size_t.sizeof] buffer;
            size_t nrandom;
        }
        tmp _tmp;

        // Algorithm for filling buffer
        size_t i = 0;
        while (i < destination.length) {
            _tmp.nrandom = next();

            // Figre out how many bytes to copy over
            size_t count = size_t.sizeof;
            if (i+size_t.sizeof > destination.length)
                count = (i+size_t.sizeof) - destination.length;

            // Write to destination
            destination[i..i+count] = _tmp.buffer[0..count]; 
            i += count;
        }
    }
}

@("Random")
unittest {
    // Mersenne Twister is deterministic, so this should always give the same result
    // (on 64-bit systems)
    static if (size_t.sizeof == 8) {
        const ubyte[128] verification = [
            155, 16, 179, 137, 163, 208, 254, 167, 182, 56, 19, 183, 127, 46, 
            4, 165, 24, 95, 218, 132, 62, 197, 42, 151, 145, 200, 45, 143, 88, 
            166, 19, 52, 93, 142, 195, 160, 49, 12, 35, 123, 216, 164, 13, 106, 
            204, 45, 231, 157, 109, 165, 89, 86, 236, 142, 4, 245, 84, 188, 235, 
            162, 184, 89, 247, 17, 72, 92, 160, 219, 113, 83, 43, 44, 180, 191, 
            109, 53, 245, 47, 125, 196, 234, 11, 19, 92, 185, 161, 167, 76, 114, 
            113, 255, 64, 83, 191, 254, 194, 169, 61, 243, 22, 54, 232, 196, 110, 
            82, 208, 110, 80, 6, 188, 68, 101, 60, 116, 47, 210, 79, 186, 138, 122, 
            205, 191, 62, 59, 194, 137, 117, 5
        ];

        ubyte[128] buffer;
        ubyte[] dest = buffer[0..$];

        Random random = nogc_new!Random(42);
        random.next(dest);
        
        assert(dest == verification[0..$]);
    }

    // Test skipped on 32 bit.
}

@("Random (seed reset)")
unittest {

    ubyte[128] buffer1;
    ubyte[] dest1 = buffer1[0..$];

    ubyte[128] buffer2;
    ubyte[] dest2 = buffer2[0..$];

    Random random = nogc_new!Random(42);

    // These should not match
    random.next(dest1);
    random.next(dest2);
    assert(dest1 != dest2, "Randomness is diminished?");


    // These should not match
    random.reset();
    random.next(dest1);
    random.reset();
    random.next(dest2);

    assert(dest1 == dest2, "Randomness is not deterministic?");
}

// TODO: optional crypto rng?