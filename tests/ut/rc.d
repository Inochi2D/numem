module tests.ut.rc;
import numem.rc;

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
    
    a.release();
    assert(a == 0);
}
