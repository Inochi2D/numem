module tests.lifetime;
import numem.lifetime;

@nogc:

class TestClass {
@nogc:
    int value;

    this(int value) {
        this.value = value;
    }

    int func1() { return value; }
}

class SubClass : TestClass {
@nogc:
    int value2;

    this(int value, int value2) {
        super(value);
        this.value2 = value2;
    }

    override
    int func1() { return value2; }
}

struct TestStruct {
    int value;
}

@("Construct class")
unittest {
    TestClass a = nogc_new!TestClass(12);
    assert(a.func1() == 12);
}

@("Construct subclass")
unittest {
    TestClass klass1 = nogc_new!SubClass(1, 2);
    assert(klass1.func1() == 2);
    assert(cast(SubClass)klass1);
}

@("Construct class (nothrow)")
nothrow @nogc
unittest {
    import numem.core.exception : assumeNoThrow;

    TestClass a = assumeNoThrow(() => nogc_new!TestClass(12));
    assert(a.value == 12);
}

@("Construct struct")
unittest {
    TestStruct* a = nogc_new!TestStruct(12);
    assert(a.value == 12);
}

@("Construct class (Slice list)")
unittest {
    TestClass[] classList;
    classList.nu_resize(5).nogc_initialize();

    foreach(i; 0..classList.length) {
        classList[i] = nogc_new!TestClass(cast(int)i);
    }

    foreach(i; 0..classList.length) {
        assert(classList[i].value == i);
    }
}