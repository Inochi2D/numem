module ut.core.atomic;
import numem.core.hooks;

@("load: i32")
unittest {
    if (!nu_atomic_supported)
        return;

    uint value = 42;
    assert(nu_atomic_load_32(value) == 42);
}

@("store: i32")
unittest {
    if (!nu_atomic_supported)
        return;

    uint value = 128;
    nu_atomic_store_32(value, 42);
    assert(nu_atomic_load_32(value) == 42);
}

@("add: i32")
unittest {
    if (!nu_atomic_supported)
        return;

    uint value = 41;
    assert(nu_atomic_add_32(value, 1) == 41);
    assert(nu_atomic_load_32(value) == 42);
}

@("sub: i32")
unittest {
    if (!nu_atomic_supported)
        return;

    uint value = 42;
    assert(nu_atomic_sub_32(value, 1) == 42);
    assert(nu_atomic_load_32(value) == 41);
}

@("load: ptr")
unittest {
    if (!nu_atomic_supported)
        return;

    size_t value = 42;
    assert(cast(size_t)nu_atomic_load_ptr(cast(void**)&value) == 42);
}

@("store: ptr")
unittest {
    if (!nu_atomic_supported)
        return;

    size_t value = 128;
    nu_atomic_store_ptr(cast(void**)&value, cast(void*)42);
    assert(cast(size_t)nu_atomic_load_ptr(cast(void**)&value) == 42);
}

@("cmpxhg: ptr")
unittest {
    if (!nu_atomic_supported)
        return;

    size_t value = 128;

    nu_atomic_cmpxhg_ptr(cast(void**)&value, cast(void*)128, cast(void*)42);
    assert(cast(size_t)nu_atomic_load_ptr(cast(void**)&value) == 42);
}

shared static this() {
    import std.stdio : writeln;
    if (!nu_atomic_supported) {
        writeln("Atomics are disabled, skipping tests...");
    }
}