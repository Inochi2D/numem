/**
    Sorting utilities.

    Copyright:
        Copyright © 2026, Kitsunebi Games
        Copyright © 2026, Inochi2D Project
        Copyright © 2008-2026, Andrei Alexandrescu

    License:
        $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).

    Authors: 
        Andrei Alexandrescu
        Luna Nielsen
*/
module numem.sorting;
import numem.core.memory;

/**
    Sorts the given range using the given predicate function
    using the stable timsort algorithm.

    Params:
        range = The range to sort.
*/
pragma(inline, true)
void nu_sort(alias pred, R)(R range) @nogc nothrow {
    TimSortImpl!(pred, R).sort(range, null);
}




//
//              IMPLEMENTATION DETAILS
//
private:




//
//              TIM-SORT IMPLEMENTATION
//
template TimSortImpl(alias pred, R) {
@nogc nothrow:
    import numem.core.math : nu_min;
    import numem.core.traits;
    import numem.lifetime;

    enum hasLvalueElements(X) = is(lvalueOf!(ElementType!X));

    alias T = ElementType!R;

    bool less()(auto ref T a, auto ref T b) {
        return pred(a, b);
    }

    bool greater()(auto ref T a, auto ref T b) {
        return pred(b, a);
    }

    bool greaterEqual()(auto ref T a, auto ref T b) {
        return !less(a, b);
    }

    bool lessEqual()(auto ref T a, auto ref T b) {
        return !less(b, a);
    }

    enum minimalMerge = 128;
    enum minimalGallop = 7;
    enum minimalStorage = 256;
    enum stackSize = 40;

    struct Slice {
        size_t base, length;
    }

    void sort()(R range, T[] temp) {
        if (range.length <= minimalMerge) {
            binaryInsertionSort(range);
            return;
        }

        immutable minRun = minRunLength(range.length);
        immutable minTemp = nu_min(range.length / 2, minimalStorage);
        size_t minGallop = minimalGallop;
        Slice[stackSize] stack = void;
        size_t stackLen = 0;

        // Allocate temporary memory if not provided by user
        if (temp.length < minTemp) {
            temp = nu_malloca!T(minTemp);
        }

        for (size_t i = 0; i < range.length;) {
            // Find length of first run in list
            size_t runLen = firstRun(range[i .. range.length]);

            // If run has less than minRun elements, extend using insertion sort
            if (runLen < minRun) {
                // Do not run farther than the length of the range
                immutable force = range.length - i > minRun ? minRun : range.length - i;
                binaryInsertionSort(range[i .. i + force], runLen);
                runLen = force;
            }

            // Push run onto stack
            stack[stackLen++] = Slice(i, runLen);
            i += runLen;

            // Collapse stack so that (e1 > e2 + e3 && e2 > e3)
            // STACK is | ... e1 e2 e3 >
            while (stackLen > 1) {
                immutable run4 = stackLen - 1;
                immutable run3 = stackLen - 2;
                immutable run2 = stackLen - 3;
                immutable run1 = stackLen - 4;

                if ((stackLen > 2 && stack[run2].length <= stack[run3].length + stack[run4].length) ||
                        (stackLen > 3 && stack[run1].length <= stack[run3].length + stack[run2].length)) {
                    immutable at = stack[run2].length < stack[run4].length ? run2 : run3;
                    mergeAt(range, stack[0 .. stackLen], at, minGallop, temp);
                } else if (stack[run3].length > stack[run4].length)
                    break;
                else
                    mergeAt(range, stack[0 .. stackLen], run3, minGallop, temp);

                stackLen -= 1;
            }
        }

        // Force collapse stack until there is only one run left
        while (stackLen > 1) {
            immutable run3 = stackLen - 1;
            immutable run2 = stackLen - 2;
            immutable run1 = stackLen - 3;
            immutable at = stackLen >= 3 && stack[run1].length <= stack[run3].length
                ? run1 : run2;
            mergeAt(range, stack[0 .. stackLen], at, minGallop, temp);
            --stackLen;
        }
    }

    // Calculates optimal value for minRun:
    // take first 6 bits of n and add 1 if any lower bits are set
    size_t minRunLength()(size_t n) {
        immutable shift = bsr(n) - 5;
        auto result = (n >> shift) + !!(n & ~((1 << shift) - 1));
        return result;
    }

    int bsr(T)(T v) {
        import ldc.intrinsics : llvm_ctlz;

        return cast(int)(typeof(v).sizeof * 8 - 1 - llvm_ctlz(v, true));
    }

    // Returns length of first run in range
    size_t firstRun()(R range) {
        if (range.length < 2)
            return range.length;

        size_t i = 2;
        if (lessEqual(range[0], range[1])) {
            while (i < range.length && lessEqual(range[i - 1], range[i]))
                ++i;
        } else {
            while (i < range.length && greater(range[i - 1], range[i]))
                ++i;
            nu_reverse(range[0 .. i]);
        }
        return i;
    }

    ElementType!R moveAt(R range, size_t offset) {
        return range[offset].move();
    }

    // A binary insertion sort for building runs up to minRun length
    void binaryInsertionSort()(R range, size_t sortedLen = 1) {
        for (; sortedLen < range.length; ++sortedLen) {
            T item = moveAt(range, sortedLen);
            size_t lower = 0;
            size_t upper = sortedLen;
            while (upper != lower) {
                size_t center = (lower + upper) / 2;
                if (less(item, range[center]))
                    upper = center;
                else
                    lower = center + 1;
            }
            //Currently (DMD 2.061) moveAll+retro is slightly less
            //efficient then stright 'for' loop
            //11 instructions vs 7 in the innermost loop [checked on Win32]
            //moveAll(retro(range[lower .. sortedLen]),
            //            retro(range[lower+1 .. sortedLen+1]));
            for (upper = sortedLen; upper > lower; upper--) {
                static if (hasLvalueElements!R)
                    range[upper - 1].moveTo(range[upper]);
                else
                    range[upper] = moveAt(range, upper - 1);
            }

            static if (hasLvalueElements!R)
                item.moveTo(range[lower]);
            else
                range[lower] = item.move();
        }
    }

    // Merge two runs in stack (at, at + 1)
    void mergeAt()(R range, Slice[] stack, immutable size_t at, ref size_t minGallop, ref T[] temp) {
        immutable base = stack[at].base;
        immutable mid = stack[at].length;
        immutable len = stack[at + 1].length + mid;

        // Pop run from stack
        stack[at] = Slice(base, len);
        if (stack.length - at == 3)
            stack[$ - 2] = stack[$ - 1];

        // Merge runs (at, at + 1)
        return merge(range[base .. base + len], mid, minGallop, temp);
    }

    // Merge two runs in a range. Mid is the starting index of the second run.
    // minGallop and temp are references; The calling function must receive the updated values.
    void merge()(R range, size_t mid, ref size_t minGallop, ref T[] temp) {
        assert(mid < range.length, "mid must be less than the length of the"
                ~ " range");

        // Reduce range of elements
        immutable firstElement = gallopForwardUpper(range[0 .. mid], range[mid]);
        immutable lastElement = gallopReverseLower(range[mid .. range.length], range[mid - 1]) + mid;
        range = range[firstElement .. lastElement];
        mid -= firstElement;

        if (mid == 0 || mid == range.length)
            return;

        // Call function which will copy smaller run into temporary memory
        if (mid <= range.length / 2) {
            temp = ensureCapacity(mid, temp);
            minGallop = mergeLo(range, mid, minGallop, temp);
        } else {
            temp = ensureCapacity(range.length - mid, temp);
            minGallop = mergeHi(range, mid, minGallop, temp);
        }
    }

    // Enlarge size of temporary memory if needed
    T[] ensureCapacity()(size_t minCapacity, T[] temp) {
        if (temp.length < minCapacity) {
            size_t newSize = 1 << (bsr(minCapacity) + 1);
            //Test for overflow
            if (newSize < minCapacity)
                newSize = minCapacity;

            temp = temp.nu_resize(newSize);
        }
        return temp;
    }

    // Merge front to back. Returns new value of minGallop.
    // temp must be large enough to store range[0 .. mid]
    size_t mergeLo()(R range, immutable size_t mid, size_t minGallop, T[] temp) {

        // Copy run into temporary memory
        temp = temp[0 .. mid];
        nogc_copy(temp, range[0 .. mid]);

        // Move first element into place
        moveEntry(range, mid, range, 0);

        size_t i = 1, lef = 0, rig = mid + 1;
        size_t count_lef, count_rig;
        immutable lef_end = temp.length - 1;

        if (lef < lef_end && rig < range.length)
            outer: while (true) {
                count_lef = 0;
                count_rig = 0;

                // Linear merge
                while ((count_lef | count_rig) < minGallop) {
                    if (lessEqual(temp[lef], range[rig])) {
                        moveEntry(temp, lef++, range, i++);
                        if (lef >= lef_end)
                            break outer;
                        ++count_lef;
                        count_rig = 0;
                    } else {
                        moveEntry(range, rig++, range, i++);
                        if (rig >= range.length)
                            break outer;
                        count_lef = 0;
                        ++count_rig;
                    }
                }

                // Gallop merge
                do {
                    count_lef = gallopForwardUpper(temp[lef .. $], range[rig]);
                    foreach (j; 0 .. count_lef)
                        moveEntry(temp, lef++, range, i++);
                    if (lef >= temp.length)
                        break outer;

                    count_rig = gallopForwardLower(range[rig .. range.length], temp[lef]);
                    foreach (j; 0 .. count_rig)
                        moveEntry(range, rig++, range, i++);
                    if (rig >= range.length)
                        while (true) {
                            moveEntry(temp, lef++, range, i++);
                            if (lef >= temp.length)
                                break outer;
                        }

                    if (minGallop > 0)
                        --minGallop;
                }
                while (count_lef >= minimalGallop || count_rig >= minimalGallop);

                minGallop += 2;
            }

        // Move remaining elements from right
        while (rig < range.length)
            moveEntry(range, rig++, range, i++);

        // Move remaining elements from left
        while (lef < temp.length)
            moveEntry(temp, lef++, range, i++);

        return minGallop > 0 ? minGallop : 1;
    }

    // Merge back to front. Returns new value of minGallop.
    // temp must be large enough to store range[mid .. range.length]
    size_t mergeHi()(R range, immutable size_t mid, size_t minGallop, T[] temp) {

        // Copy run into temporary memory
        temp = temp[0 .. range.length - mid];
        nogc_copy(temp, range[mid .. range.length]);

        // Move first element into place
        moveEntry(range, mid - 1, range, range.length - 1);

        size_t i = range.length - 2, lef = mid - 2, rig = temp.length - 1;
        size_t count_lef, count_rig;

        outer: while (true) {
            count_lef = 0;
            count_rig = 0;

            // Linear merge
            while ((count_lef | count_rig) < minGallop) {
                if (greaterEqual(temp[rig], range[lef])) {
                    moveEntry(temp, rig, range, i--);
                    if (rig == 1) {
                        // Move remaining elements from left
                        while (true) {
                            moveEntry(range, lef, range, i--);
                            if (lef == 0)
                                break;
                            --lef;
                        }

                        // Move last element into place
                        moveEntry(temp, 0, range, i);

                        break outer;
                    }
                    --rig;
                    count_lef = 0;
                    ++count_rig;
                } else {
                    moveEntry(range, lef, range, i--);
                    if (lef == 0)
                        while (true) {
                            moveEntry(temp, rig, range, i--);
                            if (rig == 0)
                                break outer;
                            --rig;
                        }
                    --lef;
                    ++count_lef;
                    count_rig = 0;
                }
            }

            // Gallop merge
            do {
                count_rig = rig - gallopReverseLower(temp[0 .. rig], range[lef]);
                foreach (j; 0 .. count_rig) {
                    moveEntry(temp, rig, range, i--);
                    if (rig == 0)
                        break outer;
                    --rig;
                }

                count_lef = lef - gallopReverseUpper(range[0 .. lef], temp[rig]);
                foreach (j; 0 .. count_lef) {
                    moveEntry(range, lef, range, i--);
                    if (lef == 0)
                        while (true) {
                            moveEntry(temp, rig, range, i--);
                            if (rig == 0)
                                break outer;
                            --rig;
                        }
                    --lef;
                }

                if (minGallop > 0)
                    --minGallop;
            }
            while (count_lef >= minimalGallop || count_rig >= minimalGallop);

            minGallop += 2;
        }

        return minGallop > 0 ? minGallop : 1;
    }

    // false = forward / lower, true = reverse / upper
    template gallopSearch(bool forwardReverse, bool lowerUpper) {
        // Gallop search on range according to attributes forwardReverse and lowerUpper
        size_t gallopSearch(R)(R range, T value) {
            size_t lower = 0, center = 1, upper = range.length;
            alias gap = center;

            static if (forwardReverse) {
                static if (!lowerUpper)
                    alias comp = lessEqual; // reverse lower
                static if (lowerUpper)
                    alias comp = less; // reverse upper

                // Gallop Search Reverse
                while (gap <= upper) {
                    if (comp(value, range[upper - gap])) {
                        upper -= gap;
                        gap *= 2;
                    } else {
                        lower = upper - gap;
                        break;
                    }
                }

                // Binary Search Reverse
                while (upper != lower) {
                    center = lower + (upper - lower) / 2;
                    if (comp(value, range[center]))
                        upper = center;
                    else
                        lower = center + 1;
                }
            } else {
                static if (!lowerUpper)
                    alias comp = greater; // forward lower
                static if (lowerUpper)
                    alias comp = greaterEqual; // forward upper

                // Gallop Search Forward
                while (lower + gap < upper) {
                    if (comp(value, range[lower + gap])) {
                        lower += gap;
                        gap *= 2;
                    } else {
                        upper = lower + gap;
                        break;
                    }
                }

                // Binary Search Forward
                while (lower != upper) {
                    center = lower + (upper - lower) / 2;
                    if (comp(value, range[center]))
                        lower = center + 1;
                    else
                        upper = center;
                }
            }

            return lower;
        }
    }

    alias gallopForwardLower = gallopSearch!(false, false);
    alias gallopForwardUpper = gallopSearch!(false, true);
    alias gallopReverseLower = gallopSearch!(true, false);
    alias gallopReverseUpper = gallopSearch!(true, true);

    /// Helper method that moves from[fIdx] into to[tIdx] if both are lvalues and
    /// uses a plain assignment if not (necessary for backwards compatibility)
    void moveEntry(X, Y)(ref X from, const size_t fIdx, ref Y to, const size_t tIdx) {
        // This template is instantiated with different combinations of range (R) and temp (T[]).
        // T[] obviously has lvalue-elements, so checking R should be enough here
        static if (hasLvalueElements!R) {
            from[fIdx].moveTo(to[tIdx]);
        } else
            to[tIdx] = from[fIdx];
    }
}
