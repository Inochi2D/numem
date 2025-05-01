module ut.lifetime;
import numem.lifetime;

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
@nogc
unittest {
    TestClass a = nogc_new!TestClass(12);
    assert(a.func1() == 12);

    // also free.
    nogc_delete(a);
}

@("Construct subclass")
@nogc
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

    // also free.
    nogc_delete(a);
}

@("Construct struct")
@nogc
unittest {
    TestStruct* a = nogc_new!TestStruct(12);
    assert(a.value == 12);

    // also free.
    nogc_delete(a);
}

@("Free struct")
@nogc
unittest {
    TestStruct a = TestStruct(12);
    assert(a.value == 12);

    // also free.
    nogc_delete(a);
}

@("Construct class (Slice list)")
@nogc
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

@("nogc_zeroinit")
unittest {
    uint var1 = 42;
    uint[8] var2 = [1, 2, 3, 4, 5, 6, 7, 8];

    // Single var ref.
    nogc_zeroinit(var1);
    assert(var1 == 0);

    // Var range
    nogc_zeroinit(var2);
    foreach(i, value; var2) {
        assert(value == 0);
    }
}

@("nogc_initialize")
unittest {
    import numem.casting : reinterpret_cast;

    // Pointers should be initialized to null.
    void* ptr = cast(void*)0xDEADBEEF;
    assert(nogc_initialize(ptr) is null);

    // NOTE: non-finite floats, even if the same bit pattern will never be equal.
    // as such we reinterpret it to a uint to convert it to a bit pattern.
    float f = 42.0;    
    uint f_bitpattern = reinterpret_cast!uint(float.init);
    assert(reinterpret_cast!uint(nogc_initialize(f)) == f_bitpattern);

    // Basic scalars.
    ubyte u8 = ubyte.max;
    byte i8 = byte.max;
    ushort u16 = ushort.max;
    short i16 = short.max;
    uint u32 = uint.max;
    int i32 = int.max;
    ulong u64 = ulong.max;
    long i64 = long.max;
    assert(nogc_initialize(u8) == 0);
    assert(nogc_initialize(i8) == 0);
    assert(nogc_initialize(u16) == 0);
    assert(nogc_initialize(i16) == 0);
    assert(nogc_initialize(u32) == 0);
    assert(nogc_initialize(i32) == 0);
    assert(nogc_initialize(u64) == 0);
    assert(nogc_initialize(i64) == 0);

    // Class references
    TestClass tclass = reinterpret_cast!TestClass(cast(void*)0xDEADBEEF);
    assert(cast(void*)nogc_initialize(tclass) is null);

    // Create new un-constructed class, allocated on the stack.
    import numem.core.traits : AllocSize;
    ubyte[AllocSize!TestClass] allocSpace;
    auto klass = nogc_initialize!TestClass(cast(void[])allocSpace);
    
    // Attempt to use the class.
    // NOTE: In this case due to the simplicitly of the class, the constructor
    // is not neccesary to run; but eg. NuRefCounted *would* need it.
    klass.value = 42;
    assert(&klass.func1 !is null);
    assert(klass.func1() == 42);

    // Initializing struct should blit its initial state back in.
    TestStruct strukt = TestStruct(1000);
    assert(strukt.value == 1000);
    assert(nogc_initialize(strukt).value == 0);
}

// Test creating destroy-with
@nu_destroywith!((ref value) { value.i = 42; })
struct ValueT {
    int i = 0;
}

@("nu_destroywith")
unittest {
    ValueT myvalue;
    
    nogc_delete(myvalue);
    assert(myvalue.i == 42);
}

extern(C++)
class TestCPPClass {
@nogc:
    int value;

    this(int value) { this.value = value; }
    ~this() { }
}

@("C++ ctor-dtor")
unittest {
    TestCPPClass myClass = nogc_new!TestCPPClass(42);

    assert(myClass.value == 42);
    nogc_delete(myClass);
}

extern(C++)
struct TestCPPStruct {
@nogc:
    int value;
}

@("C++ ctor-dtor")
unittest {
    TestCPPStruct* myStruct = nogc_new!TestCPPStruct(42);

    assert(myStruct.value == 42);
    nogc_delete(myStruct);
}

@("basic types")
unittest {
    import numem.core.memory : nu_dup;

    string myString = "Hello, world!".nu_dup();
    nogc_delete(myString);
}