module tests.ut.rc;
import numem.rc;
import numem.lifetime : nogc_delete;

@("Rc!int")
unittest {
    Rc!int a = 24;
    assert(a == 24);
    
    a.release();
    assert(a == 0);
}

@("Arc!int")
unittest {
    Arc!int a = 24;
    assert(a == 24);
    
    nogc_delete(a);
    assert(a == 0);
}
