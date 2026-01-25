module tests.ut.rc;
import numem.rc;
import numem.lifetime : nogc_delete;

@("Rc!int")
unittest {
    __gshared size_t rct_objects = 1;
    static struct RCT1 {
        int v;
        alias v this;

        ~this() @nogc { rct_objects--; }
        this(ref return scope inout(typeof(this)) rhs) @nogc { rct_objects++; v = rhs.v; }
        this(int value) @nogc {
            rct_objects++;
            v = value;
        }
    }

    Rc!RCT1 a = RCT1(42);
    assert(rct_objects == 1);
    assert(a.v == 42);
    
    a.release();
    assert(rct_objects == 0);
}