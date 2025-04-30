module ut.core.memory;
import numem.core.memory;

@("nu_resize")
unittest {
    uint[] arr;

    assert(arr.nu_resize(5).ptr);
    assert(!arr.nu_resize(0).ptr);
}

@("nu_dup")
unittest {
    const(char)[] str1 = "Hello, world!".nu_dup();
    immutable(char)[] str2 = "Hello, world!".nu_idup();
    assert(str1 == "Hello, world!");
    assert(str2 == "Hello, world!");

    assert(!str1.nu_resize(0).ptr);
    assert(!str2.nu_resize(0).ptr);
}

@("nu_terminate")
unittest {
    string str1 = "Hello, world!".nu_idup();
    str1.nu_terminate();
    assert(str1.ptr[str1.length] == '\0');
    assert(!str1.nu_resize(0).ptr);
}

@("nu_is_overlapping")
unittest {
    int[] arr1 = [1, 2, 3, 4];
    int[] arr2 = arr1[1..$-1];

    size_t arr1len = arr1.length*int.sizeof;
    size_t arr2len = arr2.length*int.sizeof;

    // Test all iterations that are supported.
    assert(nu_is_overlapping(arr1.ptr, arr1len, arr2.ptr, arr2len));
    assert(!nu_is_overlapping(arr1.ptr, arr1len, arr2.ptr, 0));
    assert(!nu_is_overlapping(arr1.ptr, 0, arr2.ptr, arr2len));
    assert(!nu_is_overlapping(null, arr1len, arr2.ptr, arr2len));
    assert(!nu_is_overlapping(arr1.ptr, arr1len, null, arr2len));
}