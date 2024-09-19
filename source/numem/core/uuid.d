/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

/**
    RFC4122 compliant UUIDs
*/
module numem.core.uuid;
import numem.string;
import numem.io.endian;

enum UUIDVariant {
    invalid,
    ncs,
    rfc4122,
    microsoft,
    reserved
}

/**
    RFC4122 compliant UUIDs
*/
struct UUID {
@nogc nothrow:
private:
    enum VERSION_BITMASK = 0b11110000;
    enum VARIANT_BITMASK = 0b11100000;

    union {
        struct {
            uint time_low;
            ushort time_mid;
            ushort time_hi_and_version;
            ubyte clk_seq_hi_reserved;
            ubyte clk_seq_low;
            ubyte[6] node;
        }
        ubyte[16] data;
        ulong[2] ldata;
    }
    
    this(ulong[2] data) inout {
        this.ldata = data;
    }

public:
    this(ubyte[16] bytes) {
        this.data = bytes;
        this.time_low = ntoh(this.time_low);
        this.time_mid = ntoh(this.time_mid);
        this.time_hi_and_version = ntoh(this.time_hi_and_version);
    }

    this(string str) {
        this(nstring(str));
    }

    this(nstring str) {

    }

    /**
        Special "nil" UUID
    */
    static UUID nil() {
        UUID uuid;
        return uuid;
    }

    /**
        Special "max" UUID
    */
    static UUID max() {
        UUID uuid;
        uuid.ldata[0] = ulong.max;
        uuid.ldata[1] = ulong.max;
        return uuid;
    }

    /**
        Creates a new UUID
    */
    static UUID createRandom() {
        UUID uuid;
        uuid.clk_seq_hi_reserved = 0;//ntoh(uuid.data.clk_seq_hi_reserved);

        return uuid;
    }

    /**
        Gets the version of the UUID structure
    */
    int getVersion() {
        return cast(int)(time_hi_and_version | VERSION_BITMASK);
    }

    /**
        Gets the variant of the UUID structure
    */
    UUIDVariant getVariant() {
        return cast(UUIDVariant)(clk_seq_hi_reserved | VARIANT_BITMASK);
    }

    /**
        Returns byte stream from UUID with data in network order.
    */
    ubyte[16] toBytes() {
        UUID datacopy;
        datacopy.data[0..$] = data[0..$];

        datacopy.time_low = ntoh(this.time_low);
        datacopy.time_mid = ntoh(this.time_mid);
        datacopy.time_hi_and_version = ntoh(this.time_hi_and_version);
        return datacopy.data;
    }


    /**
        Checks equality between 2 UUIDs.
    */
    bool opEquals(const UUID other) const {
        return this.ldata[0] == other.ldata[0] && this.ldata[1] == other.ldata[1];
    }

    /**
        Compares 2 UUIDs lexically.

        Lexical order is NOT temporal!
    */
    int opCmp(const UUID other) const {

        // First check things which are endian dependent.
        if (this.time_low != other.time_low) 
            return this.time_low < other.time_low;

        if (this.time_mid != other.time_mid) 
            return this.time_mid < other.time_mid;

        if (this.time_hi_and_version != other.time_hi_and_version) 
            return this.time_hi_and_version < other.time_hi_and_version;
        
        // Then check all the nodes
        static foreach(i; 0..6) {
            if (this.node[i] < other.node[i]) return -1;
            if (this.node[i] > other.node[i]) return 1;
        }

        // They're the same.
        return 0;
    }
}