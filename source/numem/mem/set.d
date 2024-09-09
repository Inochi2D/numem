/**
    This code is taken from dplug:core and has been modified to work with numem primitives.

    This module implements an associative array.
    @nogc associative array, replacement for std::map and std::set.

    Difference with Phobos is that the .init are valid and it uses a B-Tree underneath
    which makes it faster.

    Copyright: Guillaume Piolat 2015-2024.
    Copyright: Copyright (C) 2008- by Steven Schveighoffer. Other code
    Copyright: 2010- Andrei Alexandrescu. All rights reserved by the respective holders.
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Authors: Steven Schveighoffer, $(HTTP erdani.com, Andrei Alexandrescu), Guillaume Piolat
*/
module numem.mem.set;
import numem.mem.internal.btree;
import numem.mem;
import std.functional : binaryFun;



/**
    Set, designed to replace std::set usage.
    O(log(n)) insertion, removal, and search time.
    `Set` is designed to operate even without initialization through `makeSet`.
*/
@AllowInitEmpty
struct SetImpl(K, alias less = "a < b", bool allowDuplicates = false, bool ownsMemory = false) {
public:
@nogc:

    @trusted
    this(int dummy) {
    }

    @disable this(this);

    @trusted
    ~this() {
    }

    /// Insert an element in the container. 
    /// If allowDuplicates is false, this can fail and return `false` 
    /// if the already contains an element with equivalent key. 
    /// Returns: `true` if the insertion took place.
    @trusted
    bool insert(K key) {
        ubyte whatever = 0;
        return _tree.insert(key, whatever);
    }

    /// Removes an element from the container.
    /// Returns: `true` if the removal took place.
    @trusted
    bool remove(K key) {

        // Delete memory if this map owns it.
        static if (ownsMemory) {
            if (key in _tree) {
                nogc_delete(_tree[key]);
            }
        }

        return _tree.remove(key) != 0;
    }

    /// Removes all elements from the set.
    @trusted
    void clearContents() {
        nogc_delete(_tree);
        // _tree reset to .init, still valid
    }

    /// Returns: `true` if the element is present.
    @trusted
    bool opBinaryRight(string op)(K key) inout if (op == "in") {
        return (key in _tree) !is null;
    }

    /// Returns: `true` if the element is present.
    @trusted
    bool opIndex(K key) const {
        return (key in _tree) !is null;
    }

    /// Returns: `true` if the element is present.
    @trusted
    bool contains(K key) const {
        return (key in _tree) !is null;
    }

    /// Returns: Number of elements in the set.
    @trusted
    size_t length() const {
        return _tree.length();
    }

    /// Returns: `ttue` is the set has no element.
    @trusted
    bool empty() const {
        return _tree.empty();
    }

    // Iterate by value only

    /// Fetch a forward range on all keys.
    @trusted
    auto byKey() {
        return _tree.byKey();
    }

    /// ditto
    @trusted
    auto byKey() const {
        return _tree.byKey();
    }

    // default opSlice is like byKey for sets, since the value is a fake value.
    alias opSlice = byKey;

private:

    // dummy type
    alias V = ubyte;

    alias InternalTree = BTree!(K, V, less, allowDuplicates, false);
    InternalTree _tree;

}

/**
    A set which does NOT own the memory of its elements
*/
alias weak_set(K) = SetImpl!(K, "a < b", false, false);

/**
    A set which owns the memory of its elements
*/
alias set(K) = SetImpl!(K, "a < b", false, true);

@("set: instantiation")
unittest {
    // It should be possible to use most function of an uninitialized Set
    // All except functions returning a range will work.
    set!(string) set;

    assert(set.length == 0);
    assert(set.empty);
    set.clearContents();
    assert(!set.contains("toto"));

    auto range = set[];
    assert(range.empty);
    foreach (e; range) {
    }

    // Finally create the internal state
    set.insert("titi");
    assert(set.contains("titi"));
}

@("set: insertion, deletion and testing")
unittest {
    set!(string) keywords = nogc_construct!(set!string)();

    assert(keywords.insert("public"));
    assert(keywords.insert("private"));
    assert(!keywords.insert("private"));

    assert(keywords.remove("public"));
    assert(!keywords.remove("non-existent"));

    assert(keywords.contains("private"));
    assert(!keywords.contains("public"));
}
