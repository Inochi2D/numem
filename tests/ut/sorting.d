module tests.ut.sorting;
import numem.sorting;

@("nu_usort")
unittest {
    int[] t = [4, 2, 3, 5, 1];
    nu_sort!((a, b) => a < b)(t);
    assert(t == [1, 2, 3, 4, 5]);
}