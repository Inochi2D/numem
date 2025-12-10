module tests.ut.optional;
import numem.optional;
import numem.lifetime;

@("option: some")
unittest {

    // Test stack value
    auto value1 = some(42);
    assert(value1);
    assert(value1.get() == 42, "value1 did not contain expected value.");

    // Test heap value (null)
    auto value2 = some!(int*)(null);
    assert(!value2);

    // Test heap value (valid)
    auto value3 = some(nogc_new!int(42));
    assert(value3);
    assert(*value3.get() == 42, "optTest3 did not contain expected value.");
    value3.reset();
    assert(!value3, "optTest3 was not cleaned up correctly.");
}

@("option: none")
unittest {
    assert(!(none!(int)()));
    assert(!(none!(void*)()));
}

@("result: ok")
unittest {
    assert((() { return ok(42); })());
}

@("result: error")
unittest {
    assert(!(() { return error!int("Not valid!"); })());
}